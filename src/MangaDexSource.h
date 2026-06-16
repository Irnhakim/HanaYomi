#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QVariantList>
#include <QVariantMap>
#include <QUrl>
#include <QUrlQuery>

// Port dari: source-api/HttpSource.kt + MangaDex extension logic
// Setara dengan kelas "MangaDex" di mihon-extensions-source
class MangaDexSource : public QObject
{
    Q_OBJECT

public:
    explicit MangaDexSource(QObject *parent = nullptr);

    // Setara dengan HttpSource.fetchPopularManga() / getPopularManga()
    Q_INVOKABLE void getPopularManga(int page = 1);

    // Setara dengan HttpSource.fetchSearchManga() / getSearchManga()
    Q_INVOKABLE void searchManga(const QString &query, int page = 1);

    // Setara dengan HttpSource.fetchMangaDetails() — ambil detail + relasi cover art
    Q_INVOKABLE void getMangaDetails(const QString &mangaId);

    // Setara dengan HttpSource.fetchChapterList() — ambil semua bab manga
    Q_INVOKABLE void getChapterList(const QString &mangaId);

    // Setara dengan HttpSource.fetchPageList() — ambil URL gambar per bab
    Q_INVOKABLE void getPageList(const QString &chapterId);

signals:
    // Emitted saat daftar manga (pencarian/popular) siap
    void mangaListReady(QVariantList mangas);

    // Emitted saat detail manga siap
    void mangaDetailReady(QVariantMap manga);

    // Emitted saat daftar bab siap
    void chapterListReady(QVariantList chapters);

    // Emitted saat daftar URL halaman siap
    void pageListReady(QVariantList pages);

    // Emitted jika ada error
    void networkError(QString message);

private:
    QNetworkAccessManager *m_nam;
    const QString BASE_URL = "https://api.mangadex.org";

    // Helper: buat QNetworkRequest dengan User-Agent yang kompatibel
    QNetworkRequest createRequest(const QUrl &url);

    // Helper: parse satu objek manga dari JSON MangaDex → QVariantMap
    QVariantMap parseMangaObject(const QJsonObject &mangaObj);

    // Helper: ambil URL cover art dari relationships[]
    QString extractCoverUrl(const QString &mangaId, const QJsonArray &relationships);
};
