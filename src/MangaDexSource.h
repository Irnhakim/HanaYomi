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

    // Dinamis: set base URL dan nama source aktif dari QML
    Q_INVOKABLE void setBaseUrl(const QString &baseUrl);
    Q_INVOKABLE void setSourceName(const QString &name);
    Q_INVOKABLE void setSourcePackage(const QString &pkg);
    Q_INVOKABLE void setSuwayomiServer(const QString &url);
    Q_INVOKABLE QString getBaseUrl() const { return m_baseUrl; }
    Q_INVOKABLE QString getSourceName() const { return m_sourceName; }
    Q_INVOKABLE QString getSourcePackage() const { return m_sourcePkg; }
    Q_INVOKABLE bool isMangaDexSource() const { return m_baseUrl.contains("mangadex.org"); }
    Q_INVOKABLE void setNsfwEnabled(bool enabled) { m_nsfwEnabled = enabled; }
    Q_INVOKABLE bool isNsfwEnabled() const { return m_nsfwEnabled; }

    // Helper HTTP untuk Scraper JS
    Q_INVOKABLE QString httpGet(const QString &url);
    Q_INVOKABLE QString httpPost(const QString &url, const QString &payload, const QString &contentType = "application/x-www-form-urlencoded");

signals:
    // Emitted saat daftar manga (pencarian/popular) siap
    void mangaListReady(QVariantList mangas);
    void htmlReady(const QString &html);

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
    QString m_baseUrl    = "https://api.mangadex.org";
    QString m_sourceName = "MangaDex";
    QString m_sourcePkg;
    QString m_suwayomiServer;
    bool m_nsfwEnabled   = false;

    // Helper untuk mengeksekusi skrip scraper JS dinamis
    QVariant runScraper(const QString &method, const QVariantList &args);
    bool hasJsScraper();
    QString getScraperPath();

    // Helper: buat QNetworkRequest dengan User-Agent yang kompatibel
    QNetworkRequest createRequest(const QUrl &url);

    // Helper: parse satu objek manga dari JSON MangaDex → QVariantMap
    QVariantMap parseMangaObject(const QJsonObject &mangaObj);

    // Helper: ambil URL cover art dari relationships[]
    QString extractCoverUrl(const QString &mangaId, const QJsonArray &relationships);

    // Helper: parse manga dari format WordPress/Madara (WP-MangaStream compatible)
    QVariantList parseMadaraHtml(const QString &html, const QString &baseUrl);
    QVariantList parseMangaThemeHtml(const QString &html, const QString &baseUrl);
};
