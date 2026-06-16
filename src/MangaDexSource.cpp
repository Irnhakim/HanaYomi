#include "MangaDexSource.h"
#include <QDebug>
#include <QDateTime>

MangaDexSource::MangaDexSource(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
{
}

QNetworkRequest MangaDexSource::createRequest(const QUrl &url)
{
    QNetworkRequest req(url);
    req.setRawHeader("User-Agent", "HanaYomi/1.0.0 (contact@hanayomi.app)");
    return req;
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
    QUrl url(BASE_URL + "/manga");
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

    QNetworkReply *reply = m_nam->get(req);
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
    QUrl url(BASE_URL + "/manga");
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
    QNetworkReply *reply = m_nam->get(req);
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
    QUrl url(BASE_URL + "/manga/" + mangaId);
    QUrlQuery q;
    q.addQueryItem("includes[]", "cover_art");
    q.addQueryItem("includes[]", "author");
    q.addQueryItem("includes[]", "artist");
    url.setQuery(q);

    QNetworkRequest req = createRequest(url);
    QNetworkReply *reply = m_nam->get(req);
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
    QUrl url(BASE_URL + "/manga/" + mangaId + "/feed");
    QUrlQuery q;
    q.addQueryItem("limit",           "96");
    q.addQueryItem("offset",          "0");
    q.addQueryItem("translatedLanguage[]", "en");
    q.addQueryItem("translatedLanguage[]", "id");  // Indonesia
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
// Port dari: MangaDex.pageListParse() → GET /at-home/server/{chapterId}
void MangaDexSource::getPageList(const QString &chapterId)
{
    QUrl url(BASE_URL + "/at-home/server/" + chapterId);
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
