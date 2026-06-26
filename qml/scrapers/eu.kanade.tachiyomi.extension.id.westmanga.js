/**
 * West Manga scraper via Suwayomi backend
 * Source ID di Suwayomi: 8883916630998758688
 *
 * Cara kerja:
 *   - Semua request diteruskan ke Suwayomi server yang sudah menjalankan
 *     APK extension West Manga asli (dengan header signing yang benar).
 *   - HanaYomi tinggal menggunakan hasilnya.
 *
 * API Suwayomi yang digunakan:
 *   GET /api/v1/source/{srcId}/popular/{page}   → mangaList[]
 *   GET /api/v1/source/{srcId}/latest/{page}    → mangaList[]
 *   GET /api/v1/source/{srcId}/search?searchTerm=X&pageNum=N → mangaList[]
 *   GET /api/v1/manga/{id}?onlineFetch=true     → manga detail
 *   GET /api/v1/manga/{id}/chapters             → chapter list
 *   GET /api/v1/manga/{mangaId}/chapter/{index}/page/{pageIdx} → image redirect
 */
({
    // ─── Konfigurasi ────────────────────────────────────────────────
    _server: typeof suwayomiServer !== 'undefined' ? suwayomiServer : "https://komik.irnhakim.my.id",
    _sourceId: "8883916630998758688",

    // ─── Helper ─────────────────────────────────────────────────────
    _parseList: function(raw) {
        if (!raw) return [];
        try {
            var data = JSON.parse(raw);
            var list = data.mangaList || data || [];
            if (!Array.isArray(list)) return [];
            var results = [];
            for (var i = 0; i < list.length; i++) {
                var m = list[i];
                // thumbnailUrl dari Suwayomi adalah path relatif — ubah jadi absolut
                var thumb = m.thumbnailUrl || "";
                if (thumb && thumb.indexOf("http") !== 0) {
                    thumb = this._server + thumb;
                }
                results.push({
                    "id": String(m.id || ""),
                    "url": m.url || "",
                    "title": m.title || "",
                    "thumbnailUrl": thumb,
                    "author": m.author || "",
                    "description": m.description || "",
                    "status": m.status === "ONGOING" ? 1 : (m.status === "COMPLETED" ? 2 : 0),
                    "genre": Array.isArray(m.genre) ? m.genre.join(", ") : (m.genre || ""),
                    "sourceId": "WestManga"
                });
            }
            return results;
        } catch (e) {
            return [];
        }
    },

    // ─── getPopularManga ─────────────────────────────────────────────
    getPopularManga: function(page) {
        var url = this._server + "/api/v1/source/" + this._sourceId + "/popular/" + page;
        var raw = http.httpGet(url);
        return this._parseList(raw);
    },

    // ─── searchManga ─────────────────────────────────────────────────
    searchManga: function(query, page) {
        var url = this._server + "/api/v1/source/" + this._sourceId + "/search"
                + "?searchTerm=" + encodeURIComponent(query)
                + "&pageNum=" + page;
        var raw = http.httpGet(url);
        return this._parseList(raw);
    },

    // ─── getMangaDetails ─────────────────────────────────────────────
    // mangaId di sini adalah Suwayomi internal ID (number string)
    getMangaDetails: function(mangaId) {
        var url = this._server + "/api/v1/manga/" + mangaId + "?onlineFetch=true";
        var raw = http.httpGet(url);
        if (!raw) return {};
        try {
            var m = JSON.parse(raw);
            var thumb = m.thumbnailUrl || "";
            if (thumb && thumb.indexOf("http") !== 0) {
                thumb = this._server + thumb;
            }
            return {
                "id": String(m.id || mangaId),
                "title": m.title || "",
                "thumbnailUrl": thumb,
                "author": m.author || m.artist || "",
                "description": m.description || "",
                "status": m.status === "ONGOING" ? 1 : (m.status === "COMPLETED" ? 2 : 0),
                "genre": Array.isArray(m.genre) ? m.genre.join(", ") : (m.genre || ""),
                "sourceId": "WestManga"
            };
        } catch (e) {
            return {};
        }
    },

    // ─── getChapterList ──────────────────────────────────────────────
    getChapterList: function(mangaId) {
        var url = this._server + "/api/v1/manga/" + mangaId + "/chapters?onlineFetch=true";
        var raw = http.httpGet(url);
        if (!raw) return [];
        try {
            var data = JSON.parse(raw);
            var list = Array.isArray(data) ? data : (data.chapters || []);
            var chapters = [];
            for (var i = 0; i < list.length; i++) {
                var ch = list[i];
                chapters.push({
                    // id = "mangaId:chapterIndex" untuk getPageList
                    "id": String(mangaId) + ":" + String(ch.index || i),
                    "mangaId": String(mangaId),
                    "url": ch.url || "",
                    "name": ch.name || ("Chapter " + ch.chapterNumber),
                    "chapterNumber": ch.chapterNumber || -1.0,
                    "scanlator": ch.scanlator || "WestManga",
                    "dateUpload": ch.uploadDate ? Math.floor(ch.uploadDate / 1000) : 0
                });
            }
            return chapters;
        } catch (e) {
            return [];
        }
    },

    // ─── getPageList ─────────────────────────────────────────────────
    // chapterId = "mangaId:chapterIndex" (format dari getChapterList)
    getPageList: function(chapterId) {
        var parts = chapterId.split(":");
        if (parts.length < 2) return [];
        var mangaId = parts[0];
        var chapterIndex = parts[1];

        // Suwayomi menyimpan gambar di endpoint:
        // /api/v1/manga/{mangaId}/chapter/{chapterIndex}/page/{pageIdx}
        // Kita perlu tahu dulu ada berapa halaman — ambil dari chapter detail
        var chUrl = this._server + "/api/v1/manga/" + mangaId + "/chapter/" + chapterIndex;
        var raw = http.httpGet(chUrl);
        if (!raw) return [];
        try {
            var ch = JSON.parse(raw);
            var pageCount = ch.pageCount || 0;
            if (pageCount <= 0) {
                // Coba trigger fetch pages dulu
                var fetchUrl = this._server + "/api/v1/manga/" + mangaId
                             + "/chapter/" + chapterIndex + "?onlineFetch=true";
                raw = http.httpGet(fetchUrl);
                ch = JSON.parse(raw);
                pageCount = ch.pageCount || 0;
            }

            var pages = [];
            for (var i = 0; i < pageCount; i++) {
                pages.push({
                    "index": i,
                    "imageUrl": this._server + "/api/v1/manga/" + mangaId
                              + "/chapter/" + chapterIndex + "/page/" + i
                });
            }
            return pages;
        } catch (e) {
            return [];
        }
    }
})
