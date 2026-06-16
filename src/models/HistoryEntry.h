#pragma once
#include <QString>
#include <QDateTime>

// Port dari: tachiyomi/domain/history/model/HistoryWithRelations.kt
struct HistoryEntry {
    long long  id = -1;
    long long  chapterId = -1;
    long long  mangaId = -1;
    QString    mangaTitle;
    float      chapterNumber = -1.0f;
    QString    chapterName;
    QDateTime  readAt;
    long long  readDuration = 0;
    QString    thumbnailUrl;
};
