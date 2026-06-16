#pragma once
#include <QString>

// Port dari: source-api/SChapter.kt & domain/chapter models Mihon
struct Chapter {
    long long id = -1;
    long long mangaId = -1;
    QString   url;
    QString   name;          // Chapter name/title
    float     chapterNumber = -1.0f;
    QString   scanlator;
    long long dateUpload = 0;
    bool      isRead = false;
    bool      isBookmarked = false;
    long long lastPageRead = 0;
    long long dateFetch = 0;
};
