#pragma once

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariantList>
#include <QVariantMap>
#include <QDebug>
#include "models/Manga.h"
#include "models/Chapter.h"
#include "models/HistoryEntry.h"

// Port dari: Mihon data/database (Room + SQLite)
// Menggunakan Qt SQL module sebagai pengganti Room ORM
class DatabaseHelper : public QObject
{
    Q_OBJECT

public:
    explicit DatabaseHelper(QObject *parent = nullptr);
    ~DatabaseHelper();

    bool initialize();

    // ---- Manga (Library) ----
    // Port dari: GetLibraryManga.kt, GetFavorites.kt
    Q_INVOKABLE QVariantList getLibraryManga();
    Q_INVOKABLE bool insertOrUpdateManga(const QVariantMap &mangaMap);
    Q_INVOKABLE bool toggleFavorite(const QString &mangaId, bool favorite);
    Q_INVOKABLE QVariantMap getMangaById(const QString &mangaId);

    // ---- Chapters ----
    // Port dari: domain/chapter interactors
    Q_INVOKABLE QVariantList getChaptersByMangaId(const QString &mangaId);
    Q_INVOKABLE bool insertOrUpdateChapters(const QVariantList &chapters, const QString &mangaId);
    Q_INVOKABLE bool markChapterRead(const QString &chapterId, bool isRead, int lastPage = 0);

    // ---- History ----
    // Port dari: GetHistory.kt, UpsertHistory.kt, RemoveHistory.kt
    Q_INVOKABLE QVariantList getHistory();
    Q_INVOKABLE bool upsertHistory(const QString &chapterId, const QString &mangaId,
                                   const QString &chapterName, float chapterNum,
                                   const QString &mangaTitle, const QString &thumbnailUrl);
    Q_INVOKABLE bool removeHistory(const QString &historyId);

    // ---- Updates ----
    // Port dari: GetUpdates.kt
    Q_INVOKABLE QVariantList getUpdates();

    // ---- Categories & Advanced Filtering ----
    Q_INVOKABLE QVariantList getCategories();
    Q_INVOKABLE bool createCategory(const QString &name);
    Q_INVOKABLE bool deleteCategory(int id);
    Q_INVOKABLE bool setMangaCategories(const QString &mangaId, const QVariantList &categoryIds);
    Q_INVOKABLE QVariantList getMangaCategories(const QString &mangaId);
    Q_INVOKABLE QVariantList getLibraryMangaFiltered(int categoryId, const QString &sortCol, const QString &sortOrder, const QString &filterStatus);
    Q_INVOKABLE bool renameCategory(int id, const QString &newName);
    Q_INVOKABLE int getLibraryCount();
    Q_INVOKABLE int getReadChaptersCount();
    Q_INVOKABLE QVariantList getGenreStats();
    Q_INVOKABLE bool clearHistory();
    Q_INVOKABLE bool clearAllCache();

signals:
    void libraryChanged();
    void historyChanged();

private:
    QSqlDatabase m_db;
    bool createTables();
};
