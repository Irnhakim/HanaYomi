#include "MangaDexSource.h"
#include <QDebug>
#include <QDateTime>
#include <QNetworkReply>
#include <QSslError>
#include <QRegularExpression>

MangaDexSource::MangaDexSource(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
    , m_baseUrl("https://api.mangadex.org")
    , m_sourceName("MangaDex")
{
    connect(m_nam, &QNetworkAccessManager::sslErrors, this, [](QNetworkReply *reply, const QList<QSslError> &errors) {
        qDebug() << "Ignoring C++ SSL errors:" << errors;
        reply->ignoreSslErrors();
    });
}

void MangaDexSource::setBaseUrl(const QString &url)
{
    if (m_baseUrl != url) {
        m_baseUrl = url;
        qDebug() << "MangaDexSource base URL set to:" << m_baseUrl;
    }
}

void MangaDexSource::setSourceName(const QString &name)
{
    if (m_sourceName != name) {
        m_sourceName = name;
        qDebug() << "MangaDexSource name set to:" << m_sourceName;
    }
}

#include <QSslConfiguration>
#include <QSslSocket>

QNetworkRequest MangaDexSource::createRequest(const QUrl &url)
{
    QNetworkRequest req(url);
    req.setRawHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");
    
    QSslConfiguration sslConf = QSslConfiguration::defaultConfiguration();
    sslConf.setPeerVerifyMode(QSslSocket::VerifyNone);
    req.setSslConfiguration(sslConf);
    
    return req;
}

QNetworkReply* MangaDexSource::sendGetRequest(const QNetworkRequest &req)
{
    QNetworkReply *reply = m_nam->get(req);
    if (reply) {
        connect(reply, &QNetworkReply::sslErrors, reply, [reply](const QList<QSslError> &errors) {
            qDebug() << "Reply ignoring MangaDex C++ SSL errors:" << errors;
            reply->ignoreSslErrors();
        });
    }
    return reply;
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
// Port dari: MangaDex.popularMangaRequest() → GET /manga?order[rating]=desc
void MangaDexSource::getPopularManga(int page)
{
    if (m_baseUrl != "https://api.mangadex.org") {
        QUrl url(m_baseUrl + "/manga/?m_orderby=views");
        if (page > 1) {
            url = QUrl(m_baseUrl + QString("/manga/page/%1/?m_orderby=views").arg(page));
        }
        QNetworkRequest req = createRequest(url);
        QNetworkReply *reply = sendGetRequest(req);
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            reply->deleteLater();
            if (reply->error() != QNetworkReply::NoError) {
                emit networkError(reply->errorString());
                return;
            }
            QString html = QString::fromUtf8(reply->readAll());
            QVariantList results = parseMadaraCatalog(html);
            emit mangaListReady(results);
        });
        return;
    }

    QUrl url(m_baseUrl + "/manga");
    QUrlQuery q;
    q.addQueryItem("limit",          "20");
    q.addQueryItem("offset",         QString::number((page - 1) * 20));
    q.addQueryItem("order[followedCount]",  "desc");
    q.addQueryItem("includes[]",     "cover_art");
    q.addQueryItem("includes[]",     "author");
    q.addQueryItem("contentRating[]","safe");
    q.addQueryItem("contentRating[]","suggestive");
    url.setQuery(q);

    QNetworkRequest req = createRequest(url);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QNetworkReply *reply = sendGetRequest(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit networkError(reply->errorString());
            return;
        }
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray data   = doc.object()["data"].toArray();
        QVariantList results;
        for (const QJsonValue &v : data) {
            results.append(parseMangaObject(v.toObject()));
        }
        emit mangaListReady(results);
    });
}

// ---- searchManga ----
// Port dari: MangaDex.searchMangaRequest() → GET /manga?title=...
void MangaDexSource::searchManga(const QString &query, int page)
{
    if (m_baseUrl != "https://api.mangadex.org") {
        QUrl url(m_baseUrl);
        QUrlQuery q;
        q.addQueryItem("s", query);
        q.addQueryItem("post_type", "wp-manga");
        url.setQuery(q);
        
        QNetworkRequest req = createRequest(url);
        QNetworkReply *reply = sendGetRequest(req);
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            reply->deleteLater();
            if (reply->error() != QNetworkReply::NoError) {
                emit networkError(reply->errorString());
                return;
            }
            QString html = QString::fromUtf8(reply->readAll());
            QVariantList results = parseMadaraCatalog(html);
            emit mangaListReady(results);
        });
        return;
    }

    QUrl url(m_baseUrl + "/manga");
    QUrlQuery q;
    q.addQueryItem("title",          query);
    q.addQueryItem("limit",          "20");
    q.addQueryItem("offset",         QString::number((page - 1) * 20));
    q.addQueryItem("includes[]",     "cover_art");
    q.addQueryItem("includes[]",     "author");
    q.addQueryItem("contentRating[]","safe");
    q.addQueryItem("contentRating[]","suggestive");
    url.setQuery(q);

    QNetworkRequest req = createRequest(url);
    QNetworkReply *reply = sendGetRequest(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit networkError(reply->errorString());
            return;
        }
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray data   = doc.object()["data"].toArray();
        QVariantList results;
        for (const QJsonValue &v : data) {
            results.append(parseMangaObject(v.toObject()));
        }
        emit mangaListReady(results);
    });
}

// ---- getMangaDetails ----
// Port dari: MangaDex.mangaDetailsParse() → GET /manga/{id}
void MangaDexSource::getMangaDetails(const QString &mangaId)
{
    if (m_baseUrl != "https://api.mangadex.org") {
        QUrl url;
        if (mangaId.startsWith("http")) {
            url = QUrl(mangaId);
        } else {
            url = QUrl(m_baseUrl + "/manga/" + mangaId + "/");
        }
        QNetworkRequest req = createRequest(url);
        QNetworkReply *reply = sendGetRequest(req);
        connect(reply, &QNetworkReply::finished, this, [this, reply, mangaId]() {
            reply->deleteLater();
            if (reply->error() != QNetworkReply::NoError) {
                emit networkError(reply->errorString());
                return;
            }
            QString html = QString::fromUtf8(reply->readAll());
            QVariantMap details = parseMadaraDetails(html, mangaId);
            emit mangaDetailReady(details);
        });
        return;
    }

    QUrl url(m_baseUrl + "/manga/" + mangaId);
    QUrlQuery q;
    q.addQueryItem("includes[]", "cover_art");
    q.addQueryItem("includes[]", "author");
    q.addQueryItem("includes[]", "artist");
    url.setQuery(q);

    QNetworkRequest req = createRequest(url);
    QNetworkReply *reply = sendGetRequest(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit networkError(reply->errorString());
            return;
        }
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonObject data  = doc.object()["data"].toObject();
        emit mangaDetailReady(parseMangaObject(data));
    });
}

// ---- getChapterList ----
// Port dari: MangaDex.chapterListParse() → GET /manga/{id}/feed
void MangaDexSource::getChapterList(const QString &mangaId)
{
    if (m_baseUrl != "https://api.mangadex.org") {
        QString cleanMangaId = mangaId;
        if (mangaId.startsWith("http")) {
            cleanMangaId = mangaId.split("/", QString::SkipEmptyParts).last();
        }
        
        QUrl url(m_baseUrl + "/manga/" + cleanMangaId + "/ajax/chapters/");
        QNetworkRequest req = createRequest(url);
        QNetworkReply *reply = sendGetRequest(req);
        connect(reply, &QNetworkReply::finished, this, [this, reply, cleanMangaId]() {
            reply->deleteLater();
            if (reply->error() == QNetworkReply::NoError) {
                QString html = QString::fromUtf8(reply->readAll());
                QVariantList chapters = parseMadaraChapters(html, cleanMangaId);
                if (!chapters.isEmpty()) {
                    emit chapterListReady(chapters);
                    return;
                }
            }
            
            QUrl mainUrl(m_baseUrl + "/manga/" + cleanMangaId + "/");
            QNetworkRequest mainReq = createRequest(mainUrl);
            QNetworkReply *mainReply = sendGetRequest(mainReq);
            connect(mainReply, &QNetworkReply::finished, this, [this, mainReply, cleanMangaId]() {
                mainReply->deleteLater();
                if (mainReply->error() != QNetworkReply::NoError) {
                    emit networkError(mainReply->errorString());
                    return;
                }
                QString html = QString::fromUtf8(mainReply->readAll());
                QVariantList chapters = parseMadaraChapters(html, cleanMangaId);
                emit chapterListReady(chapters);
            });
        });
        return;
    }

    QUrl url(m_baseUrl + "/manga/" + mangaId + "/feed");
    QUrlQuery q;
    q.addQueryItem("limit",           "96");
    q.addQueryItem("offset",          "0");
    q.addQueryItem("translatedLanguage[]", "en");
    q.addQueryItem("translatedLanguage[]", "id");  // Indonesia
    q.addQueryItem("order[chapter]",  "desc");
    q.addQueryItem("includes[]",      "scanlation_group");
    url.setQuery(q);

    QNetworkRequest req = createRequest(url);
    QNetworkReply *reply = sendGetRequest(req);
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
// Port dari: MangaDex.pageListParse() → GET /at-home/server/{chapterId}
void MangaDexSource::getPageList(const QString &chapterId)
{
    if (m_baseUrl != "https://api.mangadex.org") {
        QUrl url(chapterId);
        QNetworkRequest req = createRequest(url);
        QNetworkReply *reply = sendGetRequest(req);
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            reply->deleteLater();
            if (reply->error() != QNetworkReply::NoError) {
                emit networkError(reply->errorString());
                return;
            }
            QString html = QString::fromUtf8(reply->readAll());
            QVariantList pages = parseMadaraPages(html);
            emit pageListReady(pages);
        });
        return;
    }

    QUrl url(m_baseUrl + "/at-home/server/" + chapterId);
    QNetworkRequest req = createRequest(url);
    QNetworkReply *reply = sendGetRequest(req);
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

// ---- Madara HTML Scraper Helpers ----

QVariantList MangaDexSource::parseMadaraCatalog(const QString &html)
{
    QVariantList results;
    QSet<QString> seenUrls;

    // Pola utama: href ke /manga/slug/ diikuti img dengan src dan alt=judul
    // Cocok untuk Madara/MangaThemesia modern (Kiryuu, BacaKomik, dsb)
    QRegularExpression cardRegex(
        "href=\"([^\"]+/manga/[a-zA-Z0-9\\-]+/)\"[^>]*>[\\s\\S]{0,800}?<img[^>]+src=\"([^\"]+)\"[^>]+alt=\"([^\"]+)\"",
        QRegularExpression::CaseInsensitiveOption
    );
    QRegularExpressionMatchIterator it = cardRegex.globalMatch(html);

    while (it.hasNext() && results.size() < 24) {
        QRegularExpressionMatch match = it.next();
        QString mangaUrl = match.captured(1);
        QString imgUrl   = match.captured(2);
        QString title    = match.captured(3).trimmed();

        if (mangaUrl.contains("/feed/") || mangaUrl.contains("/page/")) continue;
        if (imgUrl.contains("logo") || imgUrl.contains("icon") || imgUrl.contains("banner")) continue;
        bool validImg = imgUrl.contains(".jpg") || imgUrl.contains(".jpeg") ||
                        imgUrl.contains(".png") || imgUrl.contains(".webp") ||
                        imgUrl.contains("uploads") || imgUrl.contains("cover");
        if (!validImg) continue;
        if (title.length() < 2) continue;

        if (!mangaUrl.startsWith("http"))
            mangaUrl = mangaUrl.startsWith("/") ? m_baseUrl + mangaUrl : m_baseUrl + "/" + mangaUrl;

        if (imgUrl.contains(" ")) imgUrl = imgUrl.split(" ")[0].trimmed();
        if (!imgUrl.startsWith("http"))
            imgUrl = imgUrl.startsWith("/") ? m_baseUrl + imgUrl : m_baseUrl + "/" + imgUrl;

        if (seenUrls.contains(mangaUrl)) continue;
        seenUrls.insert(mangaUrl);

        QString mangaId = mangaUrl.split("/", QString::SkipEmptyParts).last();
        QVariantMap m;
        m["id"]           = mangaId;
        m["url"]          = mangaUrl;
        m["title"]        = title;
        m["description"]  = QString("Manga from %1").arg(m_sourceName);
        m["author"]       = "Unknown";
        m["status"]       = 0;
        m["genre"]        = "Manga";
        m["thumbnailUrl"] = imgUrl;
        m["sourceId"]     = m_sourceName.toLower();
        results.append(m);
    }

    // Fallback: pola lama jika site menggunakan struktur berbeda
    if (results.isEmpty()) {
        QSet<QString> seenFallback;
        QRegularExpression itemRegex("<a[^>]+href=\"([^\"]+/manga/[^/]+/?)\"[^>]*>([\\s\\S]*?)</a>");
        QRegularExpressionMatchIterator i2 = itemRegex.globalMatch(html);
        while (i2.hasNext() && results.size() < 24) {
            QRegularExpressionMatch match = i2.next();
            QString mangaUrl = match.captured(1);
            if (!mangaUrl.startsWith("http"))
                mangaUrl = mangaUrl.startsWith("/") ? m_baseUrl + mangaUrl : m_baseUrl + "/" + mangaUrl;
            if (seenFallback.contains(mangaUrl)) continue;
            seenFallback.insert(mangaUrl);

            QString titleText = match.captured(2);
            titleText.remove(QRegularExpression("<[^>]*>"));
            QString title = titleText.trimmed();
            if (title.length() < 2) continue;

            int pos = match.capturedStart(0);
            QString ctx = html.mid(qMax(0, pos - 500), 1200);
            QRegularExpression imgR("<img[^>]+src=\"([^\"]+)\"");
            QRegularExpressionMatch imgM = imgR.match(ctx);
            if (!imgM.hasMatch()) continue;
            QString imgUrl = imgM.captured(1).split(" ")[0].trimmed();
            if (!imgUrl.startsWith("http"))
                imgUrl = imgUrl.startsWith("/") ? m_baseUrl + imgUrl : m_baseUrl + "/" + imgUrl;

            QString mangaId = mangaUrl.split("/", QString::SkipEmptyParts).last();
            QVariantMap m;
            m["id"] = mangaId; m["url"] = mangaUrl; m["title"] = title;
            m["description"] = QString("Manga from %1").arg(m_sourceName);
            m["author"] = "Unknown"; m["status"] = 0; m["genre"] = "Manga";
            m["thumbnailUrl"] = imgUrl; m["sourceId"] = m_sourceName.toLower();
            results.append(m);
        }
    }

    return results;
}


QVariantMap MangaDexSource::parseMadaraDetails(const QString &html, const QString &mangaId)
{
    QVariantMap m;
    
    QString title = m_sourceName + " Manga";
    QRegularExpression titleRegex("<div class=\"post-title\">\\s*<h5>\\s*<a[^>]*>([\\s\\S]*?)</a>\\s*</h5>\\s*</div>|<h1[^>]*>([^<]+)</h1>");
    QRegularExpressionMatch titleMatch = titleRegex.match(html);
    if (titleMatch.hasMatch()) {
        title = titleMatch.captured(1).trimmed();
        if (title.isEmpty()) title = titleMatch.captured(2).trimmed();
    }
    title.remove(QRegularExpression("<[^>]*>"));
    title = title.trimmed();
    
    QString description = "No description available.";
    QRegularExpression descRegex("<div[^>]+(?:class|id)=\"[^\"]*(?:summary__content|description-summary|manga-excerpt|post-content_item)[^\"]*\"[^>]*>([\\s\\S]*?)</div>");
    QRegularExpressionMatch descMatch = descRegex.match(html);
    if (descMatch.hasMatch()) {
        description = descMatch.captured(1).trimmed();
        description.remove(QRegularExpression("<[^>]*>"));
    }
    description = description.trimmed();
    
    QString author = "Unknown";
    QRegularExpression authorRegex("<a[^>]+href=\"[^\"]*/manga-author/[^\"]*\"[^>]*>([^<]+)</a>|<div[^>]+class=\"author-content\"[^>]*>\\s*<a[^>]*>([^<]+)</a>");
    QRegularExpressionMatch authorMatch = authorRegex.match(html);
    if (authorMatch.hasMatch()) {
        author = authorMatch.captured(1).trimmed();
        if (author.isEmpty()) author = authorMatch.captured(2).trimmed();
    }
    
    QStringList genres;
    QRegularExpression genreRegex("<a[^>]+href=\"[^\"]*/manga-genre/[^\"]*\"[^>]*>([^<]+)</a>");
    QRegularExpressionMatchIterator genreIt = genreRegex.globalMatch(html);
    while (genreIt.hasNext()) {
        genres << genreIt.next().captured(1).trimmed();
    }
    
    int status = 0;
    if (html.contains("Ongoing", Qt::CaseInsensitive)) status = 1;
    else if (html.contains("Completed", Qt::CaseInsensitive)) status = 2;
    
    m["id"]           = mangaId;
    m["url"]          = m_baseUrl + "/manga/" + mangaId + "/";
    m["title"]        = title;
    m["description"]  = description;
    m["author"]       = author;
    m["status"]       = status;
    m["genre"]        = genres.isEmpty() ? "Manga" : genres.join(", ");
    m["thumbnailUrl"] = "";
    
    QRegularExpression coverRegex("<div class=\"summary_image\">\\s*<a[^>]*>\\s*<img[^>]+(?:src|data-src|data-lazy-src)=\"([^\"]+)\"");
    QRegularExpressionMatch coverMatch = coverRegex.match(html);
    if (coverMatch.hasMatch()) {
        m["thumbnailUrl"] = coverMatch.captured(1);
    }
    
    m["sourceId"] = m_sourceName.toLower();
    
    return m;
}

QVariantList MangaDexSource::parseMadaraChapters(const QString &html, const QString &mangaId)
{
    QVariantList chapters;
    
    QRegularExpression chapterRegex("<li[^>]*class=\"[^\"]*wp-manga-chapter[^\"]*\"[^>]*>\\s*<a[^>]+href=\"([^\"]+)\"[^>]*>([\\s\\S]*?)</a>");
    QRegularExpressionMatchIterator i = chapterRegex.globalMatch(html);
    
    while (i.hasNext()) {
        QRegularExpressionMatch match = i.next();
        QString chapterUrl = match.captured(1);
        QString chapterTitle = match.captured(2).trimmed();
        chapterTitle.remove(QRegularExpression("<[^>]*>"));
        chapterTitle = chapterTitle.trimmed();
        
        float chapterNum = -1.0f;
        QRegularExpression numRegex("chapter\\s*(\\d+(?:\\.\\d+)?)", QRegularExpression::CaseInsensitiveOption);
        QRegularExpressionMatch numMatch = numRegex.match(chapterUrl);
        if (numMatch.hasMatch()) {
            chapterNum = numMatch.captured(1).toFloat();
        }
        
        QVariantMap c;
        QString chapterId = chapterUrl.split("/", QString::SkipEmptyParts).last();
        c["id"]            = chapterId;
        c["mangaId"]       = mangaId;
        c["url"]           = chapterUrl;
        c["name"]          = chapterTitle;
        c["chapterNumber"] = chapterNum;
        c["scanlator"]     = m_sourceName;
        c["dateUpload"]    = QDateTime::currentDateTime().toSecsSinceEpoch();
        
        chapters.append(c);
    }
    return chapters;
}

QVariantList MangaDexSource::parseMadaraPages(const QString &html)
{
    QVariantList pages;
    
    QRegularExpression imgRegex("<div class=\"page-break[^\"]*\"[^>]*>\\s*<img[^>]+(?:src|data-src|data-lazy-src)=\"([^\"]+)\"|<img[^>]+(?:class|id)=\"[^\"]*(?:wp-manga-chapter-img|chapter-img)[^\"]*\"[^>]+(?:src|data-src|data-lazy-src)=\"([^\"]+)\"");
    QRegularExpressionMatchIterator i = imgRegex.globalMatch(html);
    
    int index = 0;
    while (i.hasNext()) {
        QRegularExpressionMatch match = i.next();
        QString imgUrl = match.captured(1);
        if (imgUrl.isEmpty()) imgUrl = match.captured(2);
        imgUrl = imgUrl.trimmed();
        
        if (!imgUrl.isEmpty()) {
            QVariantMap page;
            page["index"]    = index;
            page["imageUrl"] = imgUrl;
            pages.append(page);
            index++;
        }
    }
    return pages;
}

