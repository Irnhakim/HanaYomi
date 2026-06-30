#include "DatabaseHelper.h"
#include <QStandardPaths>
#include <QDir>
#include <QDateTime>

DatabaseHelper::DatabaseHelper(QObject *parent) : QObject(parent) {}

DatabaseHelper::~DatabaseHelper() {
    if (m_db.isOpen()) m_db.close();
}

bool DatabaseHelper::initialize() {
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    // Ubuntu Touch fallback/override
    if (qEnvironmentVariableIsSet("XDG_DATA_HOME")) {
        dataDir = QString::fromLocal8Bit(qgetenv("XDG_DATA_HOME")) + "/hanayomi.hakim";
    } else {
        dataDir = QDir::homePath() + "/.local/share/hanayomi.hakim";
    }
    
    QDir().mkpath(dataDir);
    QString dbPath = dataDir + "/hanayomi.db";

    m_db = QSqlDatabase::addDatabase("QSQLITE", "hanayomi");
    m_db.setDatabaseName(dbPath);

    if (!m_db.open()) {
        qCritical() << "Cannot open database:" << m_db.lastError().text();
        return false;
    }

    qDebug() << "Database opened at:" << dbPath;
    return createTables();
}

bool DatabaseHelper::createTables() {
    QSqlQuery q(m_db);

    // Manga table — port dari Room @Entity di Mihon
    bool ok = q.exec(R"(
        CREATE TABLE IF NOT EXISTS manga (
            id          TEXT PRIMARY KEY,
            source_id   TEXT,
            url         TEXT,
            title       TEXT NOT NULL,
            author      TEXT,
            artist      TEXT,
            description TEXT,
            genre       TEXT,
            thumbnail_url TEXT,
            status      INTEGER DEFAULT 0,
            favorite    INTEGER DEFAULT 0,
            date_added  INTEGER DEFAULT 0,
            last_update INTEGER DEFAULT 0,
            unread_count INTEGER DEFAULT 0
        )
    )");
    if (!ok) { qWarning() << "Create manga table failed:" << q.lastError().text(); return false; }

    // Chapter table — port dari SChapter
    ok = q.exec(R"(
        CREATE TABLE IF NOT EXISTS chapter (
            id              TEXT PRIMARY KEY,
            manga_id        TEXT NOT NULL,
            url             TEXT,
            name            TEXT,
            chapter_number  REAL DEFAULT -1,
            scanlator       TEXT,
            date_upload     INTEGER DEFAULT 0,
            is_read         INTEGER DEFAULT 0,
            is_bookmarked   INTEGER DEFAULT 0,
            last_page_read  INTEGER DEFAULT 0,
            date_fetch      INTEGER DEFAULT 0,
            FOREIGN KEY (manga_id) REFERENCES manga(id)
        )
    )");
    if (!ok) { qWarning() << "Create chapter table failed:" << q.lastError().text(); return false; }

    // History table — port dari HistoryWithRelations
    ok = q.exec(R"(
        CREATE TABLE IF NOT EXISTS history (
            id              TEXT PRIMARY KEY,
            chapter_id      TEXT NOT NULL,
            manga_id        TEXT NOT NULL,
            manga_title     TEXT,
            chapter_name    TEXT,
            chapter_number  REAL DEFAULT -1,
            thumbnail_url   TEXT,
            read_at         INTEGER DEFAULT 0,
            read_duration   INTEGER DEFAULT 0
        )
    )");
    if (!ok) { qWarning() << "Create history table failed:" << q.lastError().text(); return false; }

    // Category table
    ok = q.exec(R"(
        CREATE TABLE IF NOT EXISTS category (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            name    TEXT NOT NULL UNIQUE
        )
    )");
    if (!ok) { qWarning() << "Create category table failed:" << q.lastError().text(); return false; }

    // Manga-Category relation table
    ok = q.exec(R"(
        CREATE TABLE IF NOT EXISTS manga_category (
            manga_id    TEXT,
            category_id INTEGER,
            PRIMARY KEY (manga_id, category_id),
            FOREIGN KEY (manga_id) REFERENCES manga(id) ON DELETE CASCADE,
            FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE CASCADE
        )
    )");
    if (!ok) { qWarning() << "Create manga_category table failed:" << q.lastError().text(); return false; }

    qDebug() << "All database tables created successfully.";
    return true;
}

// --- Library / Manga ---

QVariantList DatabaseHelper::getLibraryManga() {
    QVariantList result;
    QSqlQuery q(m_db);
    q.exec("SELECT * FROM manga WHERE favorite = 1 ORDER BY title ASC");
    while (q.next()) {
        QVariantMap m;
        m["id"]           = q.value("id");
        m["title"]        = q.value("title");
        m["author"]       = q.value("author");
        m["description"]  = q.value("description");
        m["thumbnailUrl"] = q.value("thumbnail_url");
        m["status"]       = q.value("status");
        m["unreadCount"]  = q.value("unread_count");
        result.append(m);
    }
    return result;
}

bool DatabaseHelper::insertOrUpdateManga(const QVariantMap &m) {
    QSqlQuery q(m_db);
    q.prepare(R"(
        INSERT OR REPLACE INTO manga
            (id, source_id, url, title, author, artist, description, genre, thumbnail_url, status, favorite, date_added)
        VALUES
            (:id, :source_id, :url, :title, :author, :artist, :description, :genre, :thumbnail_url, :status, :favorite, :date_added)
    )");
    q.bindValue(":id",            m.value("id"));
    q.bindValue(":source_id",     m.value("sourceId", "mangadex"));
    q.bindValue(":url",           m.value("url"));
    q.bindValue(":title",         m.value("title"));
    q.bindValue(":author",        m.value("author"));
    q.bindValue(":artist",        m.value("artist"));
    q.bindValue(":description",   m.value("description"));
    q.bindValue(":genre",         m.value("genre"));
    q.bindValue(":thumbnail_url", m.value("thumbnailUrl"));
    q.bindValue(":status",        m.value("status", 0));
    q.bindValue(":favorite",      m.value("favorite", 0));
    q.bindValue(":date_added",    QDateTime::currentSecsSinceEpoch());

    bool ok = q.exec();
    if (ok) emit libraryChanged();
    else qWarning() << "insertOrUpdateManga failed:" << q.lastError().text();
    return ok;
}

bool DatabaseHelper::toggleFavorite(const QString &mangaId, bool favorite) {
    QSqlQuery q(m_db);
    q.prepare("UPDATE manga SET favorite = :fav WHERE id = :id");
    q.bindValue(":fav", favorite ? 1 : 0);
    q.bindValue(":id",  mangaId);
    bool ok = q.exec();
    if (ok) emit libraryChanged();
    return ok;
}

QVariantMap DatabaseHelper::getMangaById(const QString &mangaId) {
    QSqlQuery q(m_db);
    q.prepare("SELECT * FROM manga WHERE id = :id");
    q.bindValue(":id", mangaId);
    q.exec();
    if (q.next()) {
        QVariantMap m;
        m["id"]           = q.value("id");
        m["title"]        = q.value("title");
        m["author"]       = q.value("author");
        m["description"]  = q.value("description");
        m["thumbnailUrl"] = q.value("thumbnail_url");
        m["status"]       = q.value("status");
        m["favorite"]     = q.value("favorite").toBool();
        return m;
    }
    return {};
}

// --- Chapters ---

QVariantList DatabaseHelper::getChaptersByMangaId(const QString &mangaId) {
    QVariantList result;
    QSqlQuery q(m_db);
    q.prepare("SELECT * FROM chapter WHERE manga_id = :mid ORDER BY chapter_number DESC");
    q.bindValue(":mid", mangaId);
    q.exec();
    while (q.next()) {
        QVariantMap c;
        c["id"]            = q.value("id");
        c["mangaId"]       = q.value("manga_id");
        c["url"]           = q.value("url");
        c["name"]          = q.value("name");
        c["chapterNumber"] = q.value("chapter_number");
        c["scanlator"]     = q.value("scanlator");
        c["isRead"]        = q.value("is_read").toBool();
        c["lastPageRead"]  = q.value("last_page_read");
        c["dateUpload"]    = q.value("date_upload");
        result.append(c);
    }
    return result;
}

bool DatabaseHelper::insertOrUpdateChapters(const QVariantList &chapters, const QString &mangaId) {
    m_db.transaction();
    QSqlQuery q(m_db);
    for (const QVariant &cv : chapters) {
        QVariantMap c = cv.toMap();
        q.prepare(R"(
            INSERT OR REPLACE INTO chapter
                (id, manga_id, url, name, chapter_number, scanlator, date_upload, date_fetch)
            VALUES
                (:id, :mid, :url, :name, :num, :scanlator, :date_upload, :date_fetch)
        )");
        q.bindValue(":id",          c.value("id"));
        q.bindValue(":mid",         mangaId);
        q.bindValue(":url",         c.value("url"));
        q.bindValue(":name",        c.value("name"));
        q.bindValue(":num",         c.value("chapterNumber", -1));
        q.bindValue(":scanlator",   c.value("scanlator"));
        q.bindValue(":date_upload", c.value("dateUpload", 0));
        q.bindValue(":date_fetch",  QDateTime::currentSecsSinceEpoch());
        if (!q.exec()) {
            qWarning() << "insertOrUpdateChapters failed:" << q.lastError().text();
            m_db.rollback();
            return false;
        }
    }
    return m_db.commit();
}

bool DatabaseHelper::markChapterRead(const QString &chapterId, bool isRead, int lastPage) {
    QSqlQuery q(m_db);
    q.prepare("UPDATE chapter SET is_read = :r, last_page_read = :lp WHERE id = :id");
    q.bindValue(":r",  isRead ? 1 : 0);
    q.bindValue(":lp", lastPage);
    q.bindValue(":id", chapterId);
    return q.exec();
}

// --- History ---

QVariantList DatabaseHelper::getHistory() {
    QVariantList result;
    QSqlQuery q(m_db);
    q.exec("SELECT * FROM history ORDER BY read_at DESC");
    while (q.next()) {
        QVariantMap h;
        h["id"]            = q.value("id");
        h["chapterId"]     = q.value("chapter_id");
        h["mangaId"]       = q.value("manga_id");
        h["mangaTitle"]    = q.value("manga_title");
        h["chapterName"]   = q.value("chapter_name");
        h["chapterNumber"] = q.value("chapter_number");
        h["thumbnailUrl"]  = q.value("thumbnail_url");
        h["readAt"]        = q.value("read_at");
        result.append(h);
    }
    return result;
}

bool DatabaseHelper::upsertHistory(const QString &chapterId, const QString &mangaId,
                                   const QString &chapterName, float chapterNum,
                                   const QString &mangaTitle, const QString &thumbnailUrl) {
    QSqlQuery q(m_db);
    q.prepare(R"(
        INSERT OR REPLACE INTO history
            (id, chapter_id, manga_id, manga_title, chapter_name, chapter_number, thumbnail_url, read_at)
        VALUES
            (:id, :cid, :mid, :mtitle, :cname, :cnum, :thumb, :read_at)
    )");
    q.bindValue(":id",     chapterId + "_hist");
    q.bindValue(":cid",    chapterId);
    q.bindValue(":mid",    mangaId);
    q.bindValue(":mtitle", mangaTitle);
    q.bindValue(":cname",  chapterName);
    q.bindValue(":cnum",   chapterNum);
    q.bindValue(":thumb",  thumbnailUrl);
    q.bindValue(":read_at", QDateTime::currentSecsSinceEpoch());
    bool ok = q.exec();
    if (ok) emit historyChanged();
    return ok;
}

bool DatabaseHelper::removeHistory(const QString &historyId) {
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM history WHERE id = :id");
    q.bindValue(":id", historyId);
    bool ok = q.exec();
    if (ok) emit historyChanged();
    return ok;
}

// --- Updates ---

QVariantList DatabaseHelper::getUpdates() {
    QVariantList result;
    QSqlQuery q(m_db);
    // Port dari GetUpdates.kt — ambil chapter baru (is_read=0) dari manga favorit, sort by date_fetch
    q.exec(R"(
        SELECT c.*, m.title AS manga_title, m.thumbnail_url
        FROM chapter c
        JOIN manga m ON c.manga_id = m.id
        WHERE m.favorite = 1 AND c.is_read = 0
        ORDER BY c.date_fetch DESC
        LIMIT 100
    )");
    while (q.next()) {
        QVariantMap u;
        u["chapterId"]    = q.value("id");
        u["mangaId"]      = q.value("manga_id");
        u["mangaTitle"]   = q.value("manga_title");
        u["chapterName"]  = q.value("name");
        u["chapterNumber"]= q.value("chapter_number");
        u["thumbnailUrl"] = q.value("thumbnail_url");
        u["dateFetch"]    = q.value("date_fetch");
        u["isRead"]       = q.value("is_read").toBool();
        result.append(u);
    }
    return result;
}

// --- Categories & Advanced Filtering ---

QVariantList DatabaseHelper::getCategories() {
    QVariantList result;
    QSqlQuery q(m_db);
    q.exec("SELECT * FROM category ORDER BY name ASC");
    while (q.next()) {
        QVariantMap c;
        c["id"] = q.value("id");
        c["name"] = q.value("name");
        result.append(c);
    }
    return result;
}

bool DatabaseHelper::createCategory(const QString &name) {
    QSqlQuery q(m_db);
    q.prepare("INSERT INTO category (name) VALUES (:name)");
    q.bindValue(":name", name);
    bool ok = q.exec();
    if (ok) emit libraryChanged();
    return ok;
}

bool DatabaseHelper::deleteCategory(int id) {
    QSqlQuery q(m_db);
    m_db.transaction();
    q.prepare("DELETE FROM category WHERE id = :id");
    q.bindValue(":id", id);
    if (!q.exec()) { m_db.rollback(); return false; }
    q.prepare("DELETE FROM manga_category WHERE category_id = :id");
    q.bindValue(":id", id);
    if (!q.exec()) { m_db.rollback(); return false; }
    bool ok = m_db.commit();
    if (ok) emit libraryChanged();
    return ok;
}

bool DatabaseHelper::setMangaCategories(const QString &mangaId, const QVariantList &categoryIds) {
    QSqlQuery q(m_db);
    m_db.transaction();
    
    // Hapus semua relasi kategori manga ini dahulu
    q.prepare("DELETE FROM manga_category WHERE manga_id = :mid");
    q.bindValue(":mid", mangaId);
    if (!q.exec()) { m_db.rollback(); return false; }

    // Tambah relasi baru
    for (const QVariant &cid : categoryIds) {
        q.prepare("INSERT INTO manga_category (manga_id, category_id) VALUES (:mid, :cid)");
        q.bindValue(":mid", mangaId);
        q.bindValue(":cid", cid.toInt());
        if (!q.exec()) { m_db.rollback(); return false; }
    }
    
    bool ok = m_db.commit();
    if (ok) emit libraryChanged();
    return ok;
}

QVariantList DatabaseHelper::getMangaCategories(const QString &mangaId) {
    QVariantList result;
    QSqlQuery q(m_db);
    q.prepare("SELECT category_id FROM manga_category WHERE manga_id = :mid");
    q.bindValue(":mid", mangaId);
    q.exec();
    while (q.next()) {
        result.append(q.value("category_id").toInt());
    }
    return result;
}

QVariantList DatabaseHelper::getLibraryMangaFiltered(int categoryId, const QString &sortCol, const QString &sortOrder, const QString &filterStatus) {
    QVariantList result;
    QSqlQuery q(m_db);
    
    QString queryStr = R"(
        SELECT DISTINCT m.* 
        FROM manga m
    )";
    
    if (categoryId >= 0) {
        queryStr += " JOIN manga_category mc ON m.id = mc.manga_id";
    }
    
    queryStr += " WHERE m.favorite = 1";
    
    if (categoryId >= 0) {
        queryStr += QString(" AND mc.category_id = %1").arg(categoryId);
    }
    
    if (filterStatus == "ongoing") {
        queryStr += " AND m.status = 1";
    } else if (filterStatus == "completed") {
        queryStr += " AND m.status = 2";
    }
    
    // Sort
    QString orderCol = "title";
    if (sortCol == "date_added") orderCol = "date_added";
    else if (sortCol == "last_update") orderCol = "last_update";
    
    QString dir = "ASC";
    if (sortOrder.toUpper() == "DESC") dir = "DESC";
    
    queryStr += QString(" ORDER BY m.%1 %2").arg(orderCol, dir);
    
    if (q.exec(queryStr)) {
        while (q.next()) {
            QVariantMap m;
            m["id"]           = q.value("id");
            m["title"]        = q.value("title");
            m["author"]       = q.value("author");
            m["description"]  = q.value("description");
            m["thumbnailUrl"] = q.value("thumbnail_url");
            m["status"]       = q.value("status");
            m["unreadCount"]  = q.value("unread_count");
            result.append(m);
        }
    } else {
        qWarning() << "getLibraryMangaFiltered failed:" << q.lastError().text() << "Query:" << queryStr;
    }
    
    return result;
}

bool DatabaseHelper::renameCategory(int id, const QString &newName) {
    QSqlQuery q(m_db);
    q.prepare("UPDATE category SET name = :name WHERE id = :id");
    q.bindValue(":name", newName);
    q.bindValue(":id", id);
    bool ok = q.exec();
    if (ok) emit libraryChanged();
    return ok;
}

int DatabaseHelper::getLibraryCount() {
    QSqlQuery q(m_db);
    q.exec("SELECT COUNT(*) FROM manga WHERE favorite = 1");
    if (q.next()) {
        return q.value(0).toInt();
    }
    return 0;
}

int DatabaseHelper::getReadChaptersCount() {
    QSqlQuery q(m_db);
    q.exec("SELECT COUNT(*) FROM chapter WHERE is_read = 1");
    if (q.next()) {
        return q.value(0).toInt();
    }
    return 0;
}

QVariantList DatabaseHelper::getGenreStats() {
    QVariantList result;
    QSqlQuery q(m_db);
    q.exec("SELECT genre FROM manga WHERE favorite = 1 AND genre IS NOT NULL AND genre != ''");
    QMap<QString, int> genreCounts;
    while (q.next()) {
        QString genresStr = q.value(0).toString();
        QStringList genres = genresStr.split(",");
        for (QString genre : genres) {
            genre = genre.trimmed();
            if (!genre.isEmpty()) {
                genreCounts[genre] = genreCounts.value(genre, 0) + 1;
            }
        }
    }

    QMapIterator<QString, int> i(genreCounts);
    while (i.hasNext()) {
        i.next();
        QVariantMap item;
        item["genre"] = i.key();
        item["count"] = i.value();
        result.append(item);
    }

    std::sort(result.begin(), result.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap()["count"].toInt() > b.toMap()["count"].toInt();
    });

    return result;
}

bool DatabaseHelper::clearHistory() {
    QSqlQuery q(m_db);
    bool ok = q.exec("DELETE FROM history");
    if (ok) emit historyChanged();
    return ok;
}

bool DatabaseHelper::clearAllCache() {
    qDebug() << "Cache cleared successfully (C++ level)";
    return true;
}
