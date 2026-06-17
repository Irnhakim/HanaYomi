({
    getPopularManga: function(page) {
        var baseUrl = "https://www.mangatales.com";
        var html = http.httpGet(baseUrl + "/mangas?page=" + page);
        if (!html) return [];

        var results = [];
        // Regex to match JSON objects representing manga in the React Router payload
        // Format: {"id":...,"title":"...","summary":"...","cover":"..."}
        var regex = /\{"id":(\d+),"title":"([^"]+)","summary":"([^"]*)","is_novel":[a-z]+,"is_oneshot":[a-z]+,"cover":"([^"]*)"/g;
        var match;
        while ((match = regex.exec(html)) !== null) {
            var id = match[1];
            var title = match[2];
            var summary = match[3];
            var cover = match[4];
            
            // Avoid duplicate entries
            var exists = false;
            for (var i = 0; i < results.length; i++) {
                if (results[i].id === id) { exists = true; break; }
            }
            if (exists) continue;

            var coverUrl = cover ? "https://media.mangatales.com/uploads/manga/cover/" + id + "/" + cover : "";
            if (!cover) coverUrl = "https://media.mangatales.com/uploads/manga/cover/" + id + "/cover.png"; // fallback

            results.push({
                "id": id,
                "url": "/mangas/" + id,
                "title": title,
                "thumbnailUrl": coverUrl,
                "author": "",
                "description": summary,
                "status": 0,
                "genre": "",
                "sourceId": "Manga Tales"
            });
        }
        return results;
    },

    searchManga: function(query, page) {
        var baseUrl = "https://www.mangatales.com";
        var html = http.httpGet(baseUrl + "/mangas?search=" + encodeURIComponent(query) + "&page=" + page);
        if (!html) return [];

        var results = [];
        var regex = /\{"id":(\d+),"title":"([^"]+)","summary":"([^"]*)","is_novel":[a-z]+,"is_oneshot":[a-z]+,"cover":"([^"]*)"/g;
        var match;
        while ((match = regex.exec(html)) !== null) {
            var id = match[1];
            var title = match[2];
            var summary = match[3];
            var cover = match[4];
            
            var exists = false;
            for (var i = 0; i < results.length; i++) {
                if (results[i].id === id) { exists = true; break; }
            }
            if (exists) continue;

            var coverUrl = cover ? "https://media.mangatales.com/uploads/manga/cover/" + id + "/" + cover : "";

            results.push({
                "id": id,
                "url": "/mangas/" + id,
                "title": title,
                "thumbnailUrl": coverUrl,
                "author": "",
                "description": summary,
                "status": 0,
                "genre": "",
                "sourceId": "Manga Tales"
            });
        }
        return results;
    },

    getMangaDetails: function(mangaId) {
        var baseUrl = "https://www.mangatales.com";
        var html = http.httpGet(baseUrl + "/mangas/" + mangaId);
        if (!html) return {};

        var titleMatch = html.match(/<h1[^>]*>([^<]+)<\/h1>/);
        var title = titleMatch ? titleMatch[1].trim() : "Manga Tales " + mangaId;
        
        var coverMatch = html.match(/<img[^>]+src="([^"]+)"[^>]*class="[^"]*cover[^"]*"/);
        var coverUrl = coverMatch ? coverMatch[1] : "";

        return {
            "id": mangaId,
            "title": title,
            "thumbnailUrl": coverUrl,
            "author": "",
            "description": "",
            "status": 0,
            "genre": "",
            "sourceId": "Manga Tales"
        };
    },

    getChapterList: function(mangaId) {
        var baseUrl = "https://www.mangatales.com";
        var html = http.httpGet(baseUrl + "/mangas/" + mangaId);
        if (!html) return [];

        var chapters = [];
        // Match chapters from HTML list
        // e.g. <a href="/mangas/1611/chapters/2303">
        var regex = /\/mangas\/(\d+)\/chapters\/(\d+)/g;
        var match;
        var seen = {};
        while ((match = regex.exec(html)) !== null) {
            var chId = match[2];
            if (seen[chId]) continue;
            seen[chId] = true;
            
            chapters.push({
                "id": chId,
                "mangaId": mangaId,
                "url": "/mangas/" + mangaId + "/chapters/" + chId,
                "name": "Chapter " + chId,
                "chapterNumber": parseFloat(chId),
                "scanlator": "",
                "dateUpload": 0
            });
        }
        return chapters;
    },

    getPageList: function(chapterId) {
        var baseUrl = "https://www.mangatales.com";
        var html = http.httpGet(baseUrl + (chapterId.indexOf("http") === 0 ? chapterId : chapterId));
        if (!html) return [];

        var pages = [];
        // Match page image URLs from the reader
        var regex = /https?:\/\/media\.mangatales\.com\/uploads\/[^\s'"]+/g;
        var match;
        var index = 0;
        var seen = {};
        while ((match = regex.exec(html)) !== null) {
            var imgUrl = match[0];
            if (seen[imgUrl]) continue;
            seen[imgUrl] = true;
            pages.push({
                "index": index++,
                "imageUrl": imgUrl
            });
        }
        return pages;
    }
})
