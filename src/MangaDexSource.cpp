#include "MangaDexSource.h"
#include <QDebug>
#include <QDateTime>
#include <QRegularExpression>
#include <QJSEngine>
#include <QJSValue>
#include <QFile>
#include <QCoreApplication>
#include <QEventLoop>
#include <QNetworkReply>
#include <QQmlEngine>

MangaDexSource::MangaDexSource(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
{
    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);
}

QNetworkRequest MangaDexSource::createRequest(const QUrl &url)
{
    QNetworkRequest req(url);
    req.setRawHeader("User-Agent", "HanaYomi/1.0.0 (contact@hanayomi.app)");
    req.setRawHeader("Accept",
        "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
    req.setRawHeader("Accept-Language", "en-US,en;q=0.9,id;q=0.8");
    req.setRawHeader("Cache-Control",   "no-cache");
    req.setRawHeader("Pragma",          "no-cache");
    if (!m_baseUrl.isEmpty() && !m_baseUrl.contains("mangadex.org")) {
        req.setRawHeader("Referer", m_baseUrl.toUtf8());
        req.setRawHeader("Origin",  m_baseUrl.toUtf8());
    }
    return req;
}

// ---- setBaseUrl / setSourceName ----
void MangaDexSource::setBaseUrl(const QString &baseUrl)
{
    m_baseUrl = baseUrl;
    qDebug() << "MangaDexSource base URL set to:" << m_baseUrl;
}

void MangaDexSource::setSourceName(const QString &name)
{
    m_sourceName = name;
    qDebug() << "MangaDexSource name set to:" << m_sourceName;
}

void MangaDexSource::setSourcePackage(const QString &pkg)
{
    m_sourcePkg = pkg;
    qDebug() << "MangaDexSource package set to:" << m_sourcePkg;
}

bool MangaDexSource::hasJsScraper()
{
    if (m_sourcePkg.isEmpty()) return false;
    QString path = QCoreApplication::applicationDirPath() + "/qml/scrapers/" + m_sourcePkg + ".js";
    return QFile::exists(path);
}

QVariant MangaDexSource::runScraper(const QString &method, const QVariantList &args)
{
    if (m_sourcePkg.isEmpty()) return QVariant();

    QString path = QCoreApplication::applicationDirPath() + "/qml/scrapers/" + m_sourcePkg + ".js";
    QFile file(path);
    if (!file.exists()) {
        qDebug() << "Scraper file does not exist at:" << path;
        return QVariant();
    }

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug() << "Failed to open scraper file at:" << path;
        return QVariant();
    }

    QString jsCode = file.readAll();
    file.close();

    QJSEngine engine;
    QJSValue httpObj = engine.newQObject(this);
    engine.globalObject().setProperty("http", httpObj);

    QJSValue scraperObj = engine.evaluate("(" + jsCode + ")");
    if (scraperObj.isError()) {
        qDebug() << "Error evaluating JS scraper:" << scraperObj.toString();
        emit networkError("Scraper eval error: " + scraperObj.toString());
        return QVariant();
    }

    QJSValue func = scraperObj.property(method);
    if (!func.isCallable()) {
        qDebug() << "Method" << method << "is not callable in scraper" << m_sourcePkg;
        return QVariant();
    }

    QJSValueList jsArgs;
    for (const QVariant &arg : args) {
        jsArgs << engine.toScriptValue(arg);
    }

    QJSValue result = func.callWithInstance(scraperObj, jsArgs);
    if (result.isError()) {
        qDebug() << "Error executing scraper method" << method << ":" << result.toString();
        emit networkError("Scraper exec error: " + result.toString());
        return QVariant();
    }

    return result.toVariant();
}

#include <QSslError>

QString MangaDexSource::httpGet(const QString &urlStr)
{
    QUrl url(urlStr);
    QNetworkRequest req = createRequest(url);
    QNetworkReply *reply = m_nam->get(req);

    connect(reply, &QNetworkReply::sslErrors, reply, [reply](const QList<QSslError> &errors) {
        qDebug() << "Scraper ignoring SSL errors for GET:" << errors;
        reply->ignoreSslErrors();
    });

    QEventLoop loop;
    connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    loop.exec();

    reply->deleteLater();
    if (reply->error() == QNetworkReply::NoError) {
        return QString::fromUtf8(reply->readAll());
    } else {
        qDebug() << "Scraper HTTP GET failed for" << urlStr << ":" << reply->errorString();
        return "";
    }
}

QString MangaDexSource::httpPost(const QString &urlStr, const QString &payload, const QString &contentType)
{
    QUrl url(urlStr);
    QNetworkRequest req = createRequest(url);
    req.setHeader(QNetworkRequest::ContentTypeHeader, contentType);
    QNetworkReply *reply = m_nam->post(req, payload.toUtf8());

    connect(reply, &QNetworkReply::sslErrors, reply, [reply](const QList<QSslError> &errors) {
        qDebug() << "Scraper ignoring SSL errors for POST:" << errors;
        reply->ignoreSslErrors();
    });

    QEventLoop loop;
    connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    loop.exec();

    reply->deleteLater();
    if (reply->error() == QNetworkReply::NoError) {
        return QString::fromUtf8(reply->readAll());
    } else {
        qDebug() << "Scraper HTTP POST failed for" << urlStr << ":" << reply->errorString();
        return "";
    }
}

// ---- Helper: parse cover art URL dari relationships[] ----
// Port dari logika di MangaDex extension — mencari tipe "cover_art" dalam relasi
QString MangaDexSource::extractCoverUrl(const QString &mangaId, const QJsonArray &relationships)
{
    for (const QJsonValue &rel : relationships) {
        QJsonObject r = rel.toObject();
        if (r["type"].toString() == "cover_art") {
            QString fileName = r["attributes"].toObject()["fileName"].toString();
            if (!fileName.isEmpty()) {
                return QString("https://uploads.mangadex.org/covers/%1/%2.512.jpg")
                    .arg(mangaId, fileName);
            }
        }
    }
    return QString();
}

// ---- Helper: parse satu manga object dari JSON API MangaDex ----
QVariantMap MangaDexSource::parseMangaObject(const QJsonObject &obj)
{
    QVariantMap m;
    QString mangaId    = obj["id"].toString();
    QJsonObject attrs  = obj["attributes"].toObject();
    QJsonArray  rels   = obj["relationships"].toArray();

    // Title — prioritas en, lalu ja-ro, lalu apapun yang tersedia
    QString title = attrs["title"].toObject()["en"].toString();
    if (title.isEmpty()) title = attrs["title"].toObject()["ja-ro"].toString();
    if (title.isEmpty()) {
        QJsonObject titles = attrs["title"].toObject();
        if (!titles.isEmpty()) title = titles.begin().value().toString();
    }

    // Description
    QString desc = attrs["description"].toObject()["en"].toString();
    if (desc.isEmpty()) desc = attrs["description"].toObject()["id"].toString(); // fallback Indonesia

    // Author — cari di relationships
    QString author;
    for (const QJsonValue &rel : rels) {
        QJsonObject r = rel.toObject();
        if (r["type"].toString() == "author") {
            author = r["attributes"].toObject()["name"].toString();
            break;
        }
    }

    // Status
    QString statusStr = attrs["status"].toString();
    int status = 0; // UNKNOWN
    if (statusStr == "ongoing")   status = 1;
    else if (statusStr == "completed") status = 2;
    else if (statusStr == "cancelled") status = 5;
    else if (statusStr == "hiatus")    status = 6;

    // Genre/Tags
    QStringList genres;
    QJsonArray tags = attrs["tags"].toArray();
    for (const QJsonValue &tag : tags) {
        QString tagName = tag.toObject()["attributes"].toObject()["name"].toObject()["en"].toString();
        if (!tagName.isEmpty()) genres << tagName;
    }

    m["id"]           = mangaId;
    m["url"]          = QString("/manga/%1").arg(mangaId);
    m["title"]        = title;
    m["description"]  = desc;
    m["author"]       = author;
    m["status"]       = status;
    m["genre"]        = genres.join(", ");
    m["thumbnailUrl"] = extractCoverUrl(mangaId, rels);
    m["sourceId"]     = QString("mangadex");

    return m;
}

// ---- getPopularManga ----
void MangaDexSource::getPopularManga(int page)
{
    if (hasJsScraper()) {
        QVariantList results = runScraper("getPopularManga", {page}).toList();
        emit mangaListReady(results);
        return;
    }

    if (m_baseUrl.contains("mangadex.org")) {
        // ---- MangaDex JSON API ----
        QUrl url(m_baseUrl + "/manga");
        QUrlQuery q;
        q.addQueryItem("limit",               "20");
        q.addQueryItem("offset",              QString::number((page - 1) * 20));
        q.addQueryItem("order[followedCount]", "desc");
        q.addQueryItem("includes[]",          "cover_art");
        q.addQueryItem("includes[]",          "author");
        q.addQueryItem("contentRating[]",     "safe");
        q.addQueryItem("contentRating[]",     "suggestive");
        if (m_nsfwEnabled) {
            q.addQueryItem("contentRating[]", "erotica");
            q.addQueryItem("contentRating[]", "pornographic");
        }
        url.setQuery(q);
        QNetworkRequest req = createRequest(url);
        req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        QNetworkReply *reply = m_nam->get(req);
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            reply->deleteLater();
            if (reply->error() != QNetworkReply::NoError) { emit networkError(reply->errorString()); return; }
            QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
            QJsonArray data   = doc.object()["data"].toArray();
            QVariantList results;
            for (const QJsonValue &v : data) results.append(parseMangaObject(v.toObject()));
            emit mangaListReady(results);
        });
        return;
    }

    // ---- Madara/WP mode: try multiple URL path patterns ----
    // Different sites use different WordPress manga plugin configurations.
    // We try each path in sequence until one returns valid HTML with manga entries.
    static const QStringList MANGA_PATHS = {
        "/manga/", "/manhwa/", "/manhua/",
        "/komik/", "/comics/", "/series/",
        "/catalogue/", "/webtoon/", "/"
    };

    QString capturedBase = m_baseUrl;
    int capturedPage     = page;

    // Use a shared counter/state via QSharedPointer so the lambda chain can coordinate
    QSharedPointer<int> pathIndex(new int(0));
    QSharedPointer<bool> done(new bool(false));

    std::function<void()> tryNextPath = [this, capturedBase, capturedPage, pathIndex, done, &tryNextPath]() {};

    // We need tryNextPath to be copyable for the lambda — use QSharedPointer<std::function>
    auto fnHolder = QSharedPointer<std::function<void()>>::create();
    *fnHolder = [this, capturedBase, capturedPage, pathIndex, done, fnHolder]() {
        if (*done || *pathIndex >= MANGA_PATHS.size()) {
            if (!*done) {
                // All paths exhausted
                emit networkError("No manga listing found at " + capturedBase +
                                  " — site may require login or use unsupported format");
            }
            return;
        }

        QString path = MANGA_PATHS[*pathIndex];
        (*pathIndex)++;

        QUrlQuery q;
        q.addQueryItem("m_orderby", "views");
        // Madara paginates with ?page=N
        if (capturedPage > 1) q.addQueryItem("page", QString::number(capturedPage));
        QUrl url(capturedBase + path);
        url.setQuery(q);

        QNetworkRequest req = createRequest(url);
        QNetworkReply *reply = m_nam->get(req);

        connect(reply, &QNetworkReply::finished, this,
                [this, reply, capturedBase, done, fnHolder]() {
            reply->deleteLater();

            int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            bool httpOk = (reply->error() == QNetworkReply::NoError && statusCode >= 200 && statusCode < 400);

            if (!httpOk) {
                // This path failed — try next
                (*fnHolder)();
                return;
            }

            QString html = QString::fromUtf8(reply->readAll());
            QVariantList results = parseMadaraHtml(html, capturedBase);
            if (results.isEmpty()) results = parseMangaThemeHtml(html, capturedBase);

            if (!results.isEmpty()) {
                *done = true;
                emit mangaListReady(results);
            } else {
                // Page returned 200 but no manga found — try next path
                (*fnHolder)();
            }
        });
    };

    (*fnHolder)();
}

// ---- searchManga ----
void MangaDexSource::searchManga(const QString &query, int page)
{
    if (hasJsScraper()) {
        QVariantList results = runScraper("searchManga", {query, page}).toList();
        emit mangaListReady(results);
        return;
    }

    if (m_baseUrl.contains("mangadex.org")) {
        // ---- MangaDex API ----
        QUrl url(m_baseUrl + "/manga");
        QUrlQuery q;
        q.addQueryItem("title",          query);
        q.addQueryItem("limit",          "20");
        q.addQueryItem("offset",         QString::number((page - 1) * 20));
        q.addQueryItem("includes[]",     "cover_art");
        q.addQueryItem("includes[]",     "author");
        q.addQueryItem("contentRating[]","safe");
        q.addQueryItem("contentRating[]","suggestive");
        if (m_nsfwEnabled) {
            q.addQueryItem("contentRating[]", "erotica");
            q.addQueryItem("contentRating[]", "pornographic");
        }
        url.setQuery(q);
        QNetworkRequest req = createRequest(url);
        QNetworkReply *reply = m_nam->get(req);
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            reply->deleteLater();
            if (reply->error() != QNetworkReply::NoError) { emit networkError(reply->errorString()); return; }
            QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
            QJsonArray data   = doc.object()["data"].toArray();
            QVariantList results;
            for (const QJsonValue &v : data) results.append(parseMangaObject(v.toObject()));
            emit mangaListReady(results);
        });
        return;
    }

    // ---- Madara/WP search: try standard WP search then fall back to /?s= ----
    static const QStringList SEARCH_PATHS = {
        "/?s=%1&post_type=wp-manga",
        "/?s=%1&post_type=manga",
        "/search/?q=%1",
        "/?s=%1"
    };

    QString capturedBase  = m_baseUrl;
    QString capturedQuery = query;
    QSharedPointer<int>  pathIndex(new int(0));
    QSharedPointer<bool> done(new bool(false));

    auto fnHolder = QSharedPointer<std::function<void()>>::create();
    *fnHolder = [this, capturedBase, capturedQuery, pathIndex, done, fnHolder]() {
        if (*done || *pathIndex >= SEARCH_PATHS.size()) {
            if (!*done) emit networkError("Search not supported on " + capturedBase);
            return;
        }

        QString pathTpl = SEARCH_PATHS[(*pathIndex)++];
        QUrl url(capturedBase + pathTpl.arg(QString::fromUtf8(QUrl::toPercentEncoding(capturedQuery))));
        QNetworkRequest req = createRequest(url);
        QNetworkReply *reply = m_nam->get(req);

        connect(reply, &QNetworkReply::finished, this,
                [this, reply, capturedBase, done, fnHolder]() {
            reply->deleteLater();
            int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            bool httpOk = (reply->error() == QNetworkReply::NoError && statusCode >= 200 && statusCode < 400);
            if (!httpOk) { (*fnHolder)(); return; }
            QString html = QString::fromUtf8(reply->readAll());
            QVariantList results = parseMadaraHtml(html, capturedBase);
            if (results.isEmpty()) results = parseMangaThemeHtml(html, capturedBase);
            if (!results.isEmpty()) { *done = true; emit mangaListReady(results); }
            else { (*fnHolder)(); }
        });
    };

    (*fnHolder)();
}

// ---- getMangaDetails ----
void MangaDexSource::getMangaDetails(const QString &mangaId)
{
    if (hasJsScraper()) {
        QVariantMap details = runScraper("getMangaDetails", {mangaId}).toMap();
        emit mangaDetailReady(details);
        return;
    }

    if (!m_baseUrl.contains("mangadex.org")) {
        // Non-MangaDex: mangaId is a full URL slug like "/manga/slug-name"
        QUrl url(m_baseUrl + mangaId);
        QNetworkRequest req = createRequest(url);
        QString capturedBase = m_baseUrl;
        QNetworkReply *reply = m_nam->get(req);
        connect(reply, &QNetworkReply::finished, this, [this, reply, mangaId, capturedBase]() {
            reply->deleteLater();
            if (reply->error() != QNetworkReply::NoError) { emit networkError(reply->errorString()); return; }
            QString html = QString::fromUtf8(reply->readAll());
            // Parse title from <h1> or og:title
            QVariantMap m;
            QRegularExpression ogTitle("<meta property=\"og:title\" content=\"([^\"]+)\"");
            QRegularExpression h1("<h1[^>]*>([^<]+)</h1>");
            auto ogMatch = ogTitle.match(html);
            auto h1Match = h1.match(html);
            m["id"]          = mangaId;
            m["title"]       = ogMatch.hasMatch() ? ogMatch.captured(1).trimmed() : (h1Match.hasMatch() ? h1Match.captured(1).trimmed() : "");
            m["description"] = "";
            m["author"]      = "";
            m["status"]      = 0;
            m["genre"]       = "";
            // og:image for cover
            QRegularExpression ogImg("<meta property=\"og:image\" content=\"([^\"]+)\"");
            auto imgMatch = ogImg.match(html);
            m["thumbnailUrl"] = imgMatch.hasMatch() ? imgMatch.captured(1) : "";
            m["sourceId"]    = m_sourceName;
            emit mangaDetailReady(m);
        });
        return;
    }
    // ---- MangaDex ----
    QUrl url(m_baseUrl + "/manga/" + mangaId);
    QUrlQuery q;
    q.addQueryItem("includes[]", "cover_art");
    q.addQueryItem("includes[]", "author");
    q.addQueryItem("includes[]", "artist");
    url.setQuery(q);
    QNetworkRequest req = createRequest(url);
    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) { emit networkError(reply->errorString()); return; }
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonObject data  = doc.object()["data"].toObject();
        emit mangaDetailReady(parseMangaObject(data));
    });
}

// ---- getChapterList ----
void MangaDexSource::getChapterList(const QString &mangaId)
{
    if (hasJsScraper()) {
        QVariantList chapters = runScraper("getChapterList", {mangaId}).toList();
        emit chapterListReady(chapters);
        return;
    }

    if (!m_baseUrl.contains("mangadex.org")) {
        // Non-MangaDex: try Madara AJAX chapter list
        // Emit empty for now — chapter detail pages needed per-source
        emit chapterListReady(QVariantList());
        return;
    }
    QUrl url(m_baseUrl + "/manga/" + mangaId + "/feed");
    QUrlQuery q;
    q.addQueryItem("limit",           "96");
    q.addQueryItem("offset",          "0");
    q.addQueryItem("translatedLanguage[]", "en");
    q.addQueryItem("translatedLanguage[]", "id");
    q.addQueryItem("order[chapter]",  "desc");
    q.addQueryItem("includes[]",      "scanlation_group");
    url.setQuery(q);

    QNetworkRequest req = createRequest(url);
    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply, mangaId]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit networkError(reply->errorString());
            return;
        }
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray data   = doc.object()["data"].toArray();

        QVariantList chapters;
        for (const QJsonValue &v : data) {
            QJsonObject ch    = v.toObject();
            QJsonObject attrs = ch["attributes"].toObject();

            // Scanlation group
            QString scanlator;
            QJsonArray rels = ch["relationships"].toArray();
            for (const QJsonValue &rel : rels) {
                if (rel.toObject()["type"].toString() == "scanlation_group") {
                    scanlator = rel.toObject()["attributes"].toObject()["name"].toString();
                    break;
                }
            }

            QString chNum = attrs["chapter"].toString();
            QString chTitle = attrs["title"].toString();
            QString displayName = chNum.isEmpty()
                ? (chTitle.isEmpty() ? "Oneshot" : chTitle)
                : ("Chapter " + chNum + (chTitle.isEmpty() ? "" : " - " + chTitle));

            // Parse date
            QString publishAt = attrs["publishAt"].toString();
            QDateTime dt = QDateTime::fromString(publishAt, Qt::ISODate);

            QVariantMap c;
            c["id"]            = ch["id"].toString();
            c["mangaId"]       = mangaId;
            c["url"]           = QString("/chapter/%1").arg(ch["id"].toString());
            c["name"]          = displayName;
            c["chapterNumber"] = chNum.isEmpty() ? -1.0f : chNum.toFloat();
            c["scanlator"]     = scanlator;
            c["dateUpload"]    = dt.isValid() ? dt.toSecsSinceEpoch() : 0;
            chapters.append(c);
        }
        emit chapterListReady(chapters);
    });
}

// ---- getPageList ----
// MangaDex: GET /at-home/server/{chapterId}
// Non-MangaDex: chapterId is a full URL, fetch HTML and extract image URLs
void MangaDexSource::getPageList(const QString &chapterId)
{
    if (hasJsScraper()) {
        QVariantList pages = runScraper("getPageList", {chapterId}).toList();
        emit pageListReady(pages);
        return;
    }

    if (!m_baseUrl.contains("mangadex.org")) {
        // Generic: fetch chapter page and extract image URLs from JSON/TS reader scripts
        QUrl url(chapterId.startsWith("http") ? chapterId : m_baseUrl + chapterId);
        QNetworkRequest req = createRequest(url);
        QNetworkReply *reply = m_nam->get(req);
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            reply->deleteLater();
            if (reply->error() != QNetworkReply::NoError) { emit networkError(reply->errorString()); return; }
            QString html = QString::fromUtf8(reply->readAll());
            QVariantList pages;
            // Try ts_reader.run([{"images":[...]}]) pattern (Madara theme)
            QRegularExpression tsReader("ts_reader\\.run\\(\\{.*?\"images\":\\[([^\\]]+)\\]");
            tsReader.setPatternOptions(QRegularExpression::DotMatchesEverythingOption);
            auto m = tsReader.match(html);
            if (m.hasMatch()) {
                QString imagesStr = "[" + m.captured(1) + "]";
                QJsonDocument doc = QJsonDocument::fromJson(imagesStr.toUtf8());
                QJsonArray arr = doc.array();
                int idx = 0;
                for (const QJsonValue &v : arr) {
                    QVariantMap page;
                    page["index"]    = idx++;
                    page["imageUrl"] = v.toString();
                    pages.append(page);
                }
            } else {
                // Fallback: extract img src from .reading-content or #readerarea
                QRegularExpression imgRx("<img[^>]+(?:src|data-src)=\"(https?://[^\"]+(?:jpg|jpeg|png|webp|gif))\"");
                imgRx.setPatternOptions(QRegularExpression::CaseInsensitiveOption);
                auto it = imgRx.globalMatch(html);
                int idx = 0;
                while (it.hasNext()) {
                    auto match = it.next();
                    QVariantMap page;
                    page["index"]    = idx++;
                    page["imageUrl"] = match.captured(1);
                    pages.append(page);
                }
            }
            emit pageListReady(pages);
        });
        return;
    }
    QUrl url(m_baseUrl + "/at-home/server/" + chapterId);
    QNetworkRequest req = createRequest(url);
    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit networkError(reply->errorString());
            return;
        }
        QJsonDocument doc    = QJsonDocument::fromJson(reply->readAll());
        QJsonObject root     = doc.object();
        QString baseUrl      = root["baseUrl"].toString();
        QJsonObject chapter  = root["chapter"].toObject();
        QString hash         = chapter["hash"].toString();
        QJsonArray dataArr   = chapter["data"].toArray();  // high quality

        QVariantList pages;
        int index = 0;
        for (const QJsonValue &filename : dataArr) {
            QVariantMap page;
            page["index"]    = index;
            page["imageUrl"] = QString("%1/data/%2/%3").arg(baseUrl, hash, filename.toString());
            pages.append(page);
            index++;
        }
        emit pageListReady(pages);
    });
}

// ---- parseMadaraHtml ----
// Parses WordPress Madara theme manga listing HTML
// Matches elements like: <div class="post-title"><h3><a href="...">Title</a></h3></div>
QVariantList MangaDexSource::parseMadaraHtml(const QString &html, const QString &baseUrl)
{
    QVariantList results;

    // Match manga cards: <div class="page-item-detail manga"> ... </div>
    // Look for links and images within the card
    QRegularExpression cardRx(
        "<div[^>]+class=\"[^\"]*post-title[^\"]*\"[^>]*>\\s*<[^>]+>\\s*<a\\s+href=\"([^\"]+)\"[^>]*>([^<]+)</a>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption
    );
    QRegularExpression imgRx(
        "<img[^>]+(?:src|data-src)=\"(https?://[^\"]+(?:jpg|jpeg|png|webp|gif)[^\"]*)\""
        , QRegularExpression::CaseInsensitiveOption
    );

    auto cardIt = cardRx.globalMatch(html);
    // Simple approach: collect all title+link pairs
    QStringList urls, titles;
    while (cardIt.hasNext()) {
        auto m = cardIt.next();
        urls  << m.captured(1).trimmed();
        titles << m.captured(2).trimmed();
    }

    // Collect cover images
    QStringList covers;
    auto imgIt = imgRx.globalMatch(html);
    while (imgIt.hasNext()) {
        auto m = imgIt.next();
        QString src = m.captured(1);
        if (src.contains("cover") || src.contains("manga") || src.contains("thumb")) {
            covers << src;
        }
    }

    for (int i = 0; i < titles.size(); i++) {
        if (titles[i].isEmpty()) continue;
        QVariantMap manga;
        QString url = urls.value(i);
        // Derive slug from URL: strip baseUrl prefix
        QString slug = url;
        slug.remove(0, baseUrl.length());
        if (slug.isEmpty()) slug = url;
        manga["id"]           = slug;
        manga["url"]          = slug;
        manga["title"]        = titles[i];
        manga["thumbnailUrl"] = covers.value(i, "");
        manga["author"]       = "";
        manga["description"]  = "";
        manga["status"]       = 0;
        manga["genre"]        = "";
        manga["sourceId"]     = m_sourceName;
        results.append(manga);
    }
    return results;
}

// ---- parseMangaThemeHtml ----
// Generic fallback parser for other WP manga themes (e.g. Komiku, Kiryuu, Mangakyo)
// Looks for og:image + title patterns or article/post card patterns
QVariantList MangaDexSource::parseMangaThemeHtml(const QString &html, const QString &baseUrl)
{
    QVariantList results;

    // Match <article> or <div class="bs"> post cards with links
    QRegularExpression linkRx(
        "<a\\s+[^>]*href=\"(" + QRegularExpression::escape(baseUrl) + "/[^\"]+)\"[^>]*>\\s*<img[^>]+(?:src|data-src)=\"([^\"]+)\"[^>]*>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption
    );
    QRegularExpression titleRx(
        "<(?:h3|h2|span)[^>]+class=\"[^\"]*title[^\"]*\"[^>]*>\\s*<a[^>]*>([^<]+)</a>",
        QRegularExpression::CaseInsensitiveOption
    );

    QStringList urls, covers;
    auto linkIt = linkRx.globalMatch(html);
    while (linkIt.hasNext()) {
        auto m = linkIt.next();
        urls   << m.captured(1);
        covers << m.captured(2);
    }

    QStringList titles;
    auto titleIt = titleRx.globalMatch(html);
    while (titleIt.hasNext()) titles << titleIt.next().captured(1).trimmed();

    int count = qMin(urls.size(), titles.size());
    for (int i = 0; i < count; i++) {
        if (titles[i].isEmpty()) continue;
        QVariantMap manga;
        QString url = urls[i];
        QString slug = url;
        slug.remove(0, baseUrl.length());
        manga["id"]           = slug.isEmpty() ? url : slug;
        manga["url"]          = slug.isEmpty() ? url : slug;
        manga["title"]        = titles[i];
        manga["thumbnailUrl"] = covers.value(i, "");
        manga["author"]       = "";
        manga["description"]  = "";
        manga["status"]       = 0;
        manga["genre"]        = "";
        manga["sourceId"]     = m_sourceName;
        results.append(manga);
    }
    return results;
}
