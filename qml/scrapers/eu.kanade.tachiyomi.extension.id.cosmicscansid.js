/**
 * CosmicScans.id scraper via Suwayomi backend
 * Source ID: 6559481336553833282
 */
({
    _server: typeof suwayomiServer !== 'undefined' ? suwayomiServer : "https://komik.irnhakim.my.id",
    _sourceId: "6559481336553833282",
    _sourceName: "CosmicScans.id",

    _parseList: function(raw) {
        if (!raw) return [];
        try {
            var data = JSON.parse(raw);
            var list = data.mangaList || data || [];
            if (!Array.isArray(list)) return [];
            var results = [];
            for (var i = 0; i < list.length; i++) {
                var m = list[i];
                var thumb = m.thumbnailUrl || "";
                if (thumb && thumb.indexOf("http") !== 0) thumb = this._server + thumb;
                results.push({
                    "id": String(m.id || ""),
                    "url": m.url || "",
                    "title": m.title || "",
                    "thumbnailUrl": thumb,
                    "author": m.author || "",
                    "description": m.description || "",
                    "status": m.status === "ONGOING" ? 1 : (m.status === "COMPLETED" ? 2 : 0),
                    "genre": Array.isArray(m.genre) ? m.genre.join(", ") : (m.genre || ""),
                    "sourceId": "CosmicScans.id"
                });
            }
            return results;
        } catch (e) { return []; }
    },

    getPopularManga: function(page) {
        return this._parseList(http.httpGet(this._server + "/api/v1/source/" + this._sourceId + "/popular/" + page));
    },

    searchManga: function(query, page) {
        return this._parseList(http.httpGet(this._server + "/api/v1/source/" + this._sourceId + "/search?searchTerm=" + encodeURIComponent(query) + "&pageNum=" + page));
    },

    getMangaDetails: function(mangaId) {
        var raw = http.httpGet(this._server + "/api/v1/manga/" + mangaId + "?onlineFetch=true");
        if (!raw) return {};
        try {
            var m = JSON.parse(raw);
            var thumb = m.thumbnailUrl || "";
            if (thumb && thumb.indexOf("http") !== 0) thumb = this._server + thumb;
            return {
                "id": String(m.id || mangaId),
                "title": m.title || "",
                "thumbnailUrl": thumb,
                "author": m.author || m.artist || "",
                "description": m.description || "",
                "status": m.status === "ONGOING" ? 1 : (m.status === "COMPLETED" ? 2 : 0),
                "genre": Array.isArray(m.genre) ? m.genre.join(", ") : (m.genre || ""),
                "sourceId": "CosmicScans.id"
            };
        } catch (e) { return {}; }
    },

    getChapterList: function(mangaId) {
        var raw = http.httpGet(this._server + "/api/v1/manga/" + mangaId + "/chapters?onlineFetch=true");
        if (!raw) return [];
        try {
            var data = JSON.parse(raw);
            var list = Array.isArray(data) ? data : (data.chapters || []);
            var chapters = [];
            for (var i = 0; i < list.length; i++) {
                var ch = list[i];
                chapters.push({
                    "id": String(mangaId) + ":" + String(ch.index || i),
                    "mangaId": String(mangaId),
                    "url": ch.url || "",
                    "name": ch.name || ("Chapter " + ch.chapterNumber),
                    "chapterNumber": ch.chapterNumber || -1.0,
                    "scanlator": ch.scanlator || "CosmicScans.id",
                    "dateUpload": ch.uploadDate ? Math.floor(ch.uploadDate / 1000) : 0
                });
            }
            return chapters;
        } catch (e) { return []; }
    },

    getPageList: function(chapterId) {
        var parts = chapterId.split(":");
        if (parts.length < 2) return [];
        var mangaId = parts[0];
        var chapterIndex = parts[1];
        var raw = http.httpGet(this._server + "/api/v1/manga/" + mangaId + "/chapter/" + chapterIndex);
        if (!raw) return [];
        try {
            var ch = JSON.parse(raw);
            var pageCount = ch.pageCount || 0;
            if (pageCount <= 0) {
                raw = http.httpGet(this._server + "/api/v1/manga/" + mangaId + "/chapter/" + chapterIndex + "?onlineFetch=true");
                ch = JSON.parse(raw);
                pageCount = ch.pageCount || 0;
            }
            var pages = [];
            for (var i = 0; i < pageCount; i++) {
                pages.push({
                    "index": i,
                    "imageUrl": this._server + "/api/v1/manga/" + mangaId + "/chapter/" + chapterIndex + "/page/" + i
                });
            }
            return pages;
        } catch (e) { return []; }
    }
})
