({
    getPopularManga: function(page) {
        var url = "https://api.mangadex.org/manga?limit=20&offset=" + ((page - 1) * 20) + "&order[followedCount]=desc&includes[]=cover_art&includes[]=author&contentRating[]=safe&contentRating[]=suggestive";
        var rawJson = http.httpGet(url);
        if (!rawJson) return [];
        try {
            var res = JSON.parse(rawJson);
            var data = res.data || [];
            var results = [];
            for (var i = 0; i < data.length; i++) {
                var item = data[i];
                var attrs = item.attributes || {};
                var rels = item.relationships || [];
                
                // Extract title
                var title = attrs.title ? (attrs.title.en || attrs.title["ja-ro"] || "") : "";
                if (!title && attrs.title) {
                    for (var k in attrs.title) {
                        title = attrs.title[k];
                        break;
                    }
                }
                
                // Extract cover fileName
                var coverFileName = "";
                for (var j = 0; j < rels.length; j++) {
                    if (rels[j].type === "cover_art" && rels[j].attributes) {
                        coverFileName = rels[j].attributes.fileName || "";
                    }
                }
                var coverUrl = coverFileName ? "https://uploads.mangadex.org/covers/" + item.id + "/" + coverFileName + ".512.jpg" : "";
                
                results.push({
                    "id": item.id,
                    "url": "/manga/" + item.id,
                    "title": title,
                    "thumbnailUrl": coverUrl,
                    "author": "",
                    "description": attrs.description ? (attrs.description.en || "") : "",
                    "status": attrs.status === "ongoing" ? 1 : (attrs.status === "completed" ? 2 : 0),
                    "genre": "",
                    "sourceId": "MangaDex"
                });
            }
            return results;
        } catch (e) {
            return [];
        }
    },

    searchManga: function(query, page) {
        var url = "https://api.mangadex.org/manga?limit=20&offset=" + ((page - 1) * 20) + "&title=" + encodeURIComponent(query) + "&includes[]=cover_art&includes[]=author&contentRating[]=safe&contentRating[]=suggestive";
        var rawJson = http.httpGet(url);
        if (!rawJson) return [];
        try {
            var res = JSON.parse(rawJson);
            var data = res.data || [];
            var results = [];
            for (var i = 0; i < data.length; i++) {
                var item = data[i];
                var attrs = item.attributes || {};
                var rels = item.relationships || [];
                
                // Extract title
                var title = attrs.title ? (attrs.title.en || attrs.title["ja-ro"] || "") : "";
                if (!title && attrs.title) {
                    for (var k in attrs.title) {
                        title = attrs.title[k];
                        break;
                    }
                }
                
                // Extract cover fileName
                var coverFileName = "";
                for (var j = 0; j < rels.length; j++) {
                    if (rels[j].type === "cover_art" && rels[j].attributes) {
                        coverFileName = rels[j].attributes.fileName || "";
                    }
                }
                var coverUrl = coverFileName ? "https://uploads.mangadex.org/covers/" + item.id + "/" + coverFileName + ".512.jpg" : "";
                
                results.push({
                    "id": item.id,
                    "url": "/manga/" + item.id,
                    "title": title,
                    "thumbnailUrl": coverUrl,
                    "author": "",
                    "description": attrs.description ? (attrs.description.en || "") : "",
                    "status": attrs.status === "ongoing" ? 1 : (attrs.status === "completed" ? 2 : 0),
                    "genre": "",
                    "sourceId": "MangaDex"
                });
            }
            return results;
        } catch (e) {
            return [];
        }
    },

    getMangaDetails: function(mangaId) {
        var url = "https://api.mangadex.org/manga/" + mangaId + "?includes[]=cover_art&includes[]=author";
        var rawJson = http.httpGet(url);
        if (!rawJson) return {};
        try {
            var res = JSON.parse(rawJson);
            var item = res.data || {};
            var attrs = item.attributes || {};
            var rels = item.relationships || [];
            
            var title = attrs.title ? (attrs.title.en || attrs.title["ja-ro"] || "") : "";
            if (!title && attrs.title) {
                for (var k in attrs.title) {
                    title = attrs.title[k];
                    break;
                }
            }
            
            var coverFileName = "";
            var author = "";
            for (var j = 0; j < rels.length; j++) {
                if (rels[j].type === "cover_art" && rels[j].attributes) {
                    coverFileName = rels[j].attributes.fileName || "";
                }
                if (rels[j].type === "author" && rels[j].attributes) {
                    author = rels[j].attributes.name || "";
                }
            }
            var coverUrl = coverFileName ? "https://uploads.mangadex.org/covers/" + item.id + "/" + coverFileName + ".512.jpg" : "";
            
            return {
                "id": item.id,
                "title": title,
                "thumbnailUrl": coverUrl,
                "author": author,
                "description": attrs.description ? (attrs.description.en || "") : "",
                "status": attrs.status === "ongoing" ? 1 : (attrs.status === "completed" ? 2 : 0),
                "genre": "",
                "sourceId": "MangaDex"
            };
        } catch (e) {
            return {};
        }
    },

    getChapterList: function(mangaId) {
        var url = "https://api.mangadex.org/manga/" + mangaId + "/feed?limit=96&offset=0&translatedLanguage[]=en&translatedLanguage[]=id&order[chapter]=desc&includes[]=scanlation_group";
        var rawJson = http.httpGet(url);
        if (!rawJson) return [];
        try {
            var res = JSON.parse(rawJson);
            var data = res.data || [];
            var chapters = [];
            for (var i = 0; i < data.length; i++) {
                var ch = data[i];
                var attrs = ch.attributes || {};
                var rels = ch.relationships || [];
                
                var scanlator = "";
                for (var j = 0; j < rels.length; j++) {
                    if (rels[j].type === "scanlation_group" && rels[j].attributes) {
                        scanlator = rels[j].attributes.name || "";
                    }
                }
                
                var chTitle = attrs.title || "";
                var chNum = attrs.chapter || "";
                var displayName = chNum === "" 
                    ? (chTitle === "" ? "Oneshot" : chTitle) 
                    : ("Chapter " + chNum + (chTitle === "" ? "" : " - " + chTitle));
                
                chapters.push({
                    "id": ch.id,
                    "mangaId": mangaId,
                    "url": "/chapter/" + ch.id,
                    "name": displayName,
                    "chapterNumber": chNum === "" ? -1.0 : parseFloat(chNum),
                    "scanlator": scanlator,
                    "dateUpload": attrs.publishAt ? Date.parse(attrs.publishAt) / 1000 : 0
                });
            }
            return chapters;
        } catch (e) {
            return [];
        }
    },

    getPageList: function(chapterId) {
        var url = "https://api.mangadex.org/at-home/server/" + chapterId;
        var rawJson = http.httpGet(url);
        if (!rawJson) return [];
        try {
            var res = JSON.parse(rawJson);
            var host = res.baseUrl || "";
            var chapter = res.chapter || {};
            var hash = chapter.hash || "";
            var data = chapter.data || [];
            var pages = [];
            for (var i = 0; i < data.length; i++) {
                pages.push({
                    "index": i,
                    "imageUrl": host + "/data/" + hash + "/" + data[i]
                });
            }
            return pages;
        } catch (e) {
            return [];
        }
    }
})
