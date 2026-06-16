#pragma once
#include <QString>
#include <QStringList>

// Port dari: tachiyomi/domain/manga/model/Manga.kt & source-api SManga.kt
struct Manga {
    long long id = -1;
    long long sourceId = -1;
    QString  url;
    QString  title;
    QString  author;
    QString  artist;
    QString  description;
    QStringList genre;
    QString  thumbnailUrl;
    int      status = 0;   // 0=UNKNOWN, 1=ONGOING, 2=COMPLETED, 3=LICENSED
    bool     favorite = false;
    long long dateAdded = 0;
    long long lastUpdate = 0;
    int      unreadCount = 0;
    int      chapterCount = 0;

    // status helpers — port dari SManga companion object
    static constexpr int UNKNOWN            = 0;
    static constexpr int ONGOING            = 1;
    static constexpr int COMPLETED          = 2;
    static constexpr int LICENSED           = 3;
    static constexpr int PUBLISHING_FINISHED= 4;
    static constexpr int CANCELLED          = 5;
    static constexpr int ON_HIATUS          = 6;

    QString statusString() const {
        switch (status) {
            case ONGOING:             return "Ongoing";
            case COMPLETED:           return "Completed";
            case LICENSED:            return "Licensed";
            case PUBLISHING_FINISHED: return "Finished";
            case CANCELLED:           return "Cancelled";
            case ON_HIATUS:           return "On Hiatus";
            default:                  return "Unknown";
        }
    }
};
