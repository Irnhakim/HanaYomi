({
    getPopularManga: function(page) {
        var baseUrl = "https://komiku.org";
        // Komiku paginates via /page/N/?post_type=manga&orderby=meta_value_num&meta_key=views
        // or simple /manga/page/N/
        var url = baseUrl + "/manga/page/" + page + "/";
        if (page === 1) url = baseUrl + "/manga/";
        
        var html = http.httpGet(url);
        if (!html) return [];

        var results = [];
        // Regex to match cards in listing
        // Format: <div class="bge">...<a href="/manga/..."><img src="..." /></a>...<h3>...</h3>
        var regex = /<div class="bge">[\s\S]*?<a href="([^"]+)"[^>]*>[\s\S]*?<img[^>]+(?:src|data-src)="([^"]+)"[\s\S]*?<h3>([^<]+)<\/h3>/g;
        var match;
        while ((match = regex.exec(html)) !== null) {
            var mUrl = match[1].trim();
            var cover = match[2].trim();
            var title = match[3].replace("Komik", "").trim();

            results.push({
                "id": mUrl,
                "url": mUrl,
                "title": title,
                "thumbnailUrl": cover,
                "author": "",
                "description": "",
                "status": 0,
                "genre": "",
                "sourceId": "Komiku"
            });
        }
        return results;
    },

    searchManga: function(query, page) {
        var baseUrl = "https://komiku.org";
        var url = baseUrl + "/page/" + page + "/?post_type=manga&s=" + encodeURIComponent(query);
        if (page === 1) url = baseUrl + "/?post_type=manga&s=" + encodeURIComponent(query);

        var html = http.httpGet(url);
        if (!html) return [];

        var results = [];
        var regex = /<div class="bge">[\s\S]*?<a href="([^"]+)"[^>]*>[\s\S]*?<img[^>]+(?:src|data-src)="([^"]+)"[\s\S]*?<h3>([^<]+)<\/h3>/g;
        var match;
        while ((match = regex.exec(html)) !== null) {
            var mUrl = match[1].trim();
            var cover = match[2].trim();
            var title = match[3].replace("Komik", "").trim();

            results.push({
                "id": mUrl,
                "url": mUrl,
                "title": title,
                "thumbnailUrl": cover,
                "author": "",
                "description": "",
                "status": 0,
                "genre": "",
                "sourceId": "Komiku"
            });
        }
        return results;
    },

    getMangaDetails: function(mangaId) {
        var baseUrl = "https://komiku.org";
        var html = http.httpGet(baseUrl + mangaId);
        if (!html) return {};

        var titleMatch = html.match(/<h1[^>]*itemprop="name"[^>]*>([^<]+)<\/h1>/) || html.match(/<h1[^>]*>([^<]+)<\/h1>/);
        var title = titleMatch ? titleMatch[1].replace("Komik", "").trim() : "Komiku Manga";

        var coverMatch = html.match(/<div class="ims">[\s\S]*?<img[^>]+src="([^"]+)"/);
        var coverUrl = coverMatch ? coverMatch[1] : "";

        var descMatch = html.match(/<p itemprop="description"[^>]*>([\s\S]*?)<\/p>/) || html.match(/<div class="desc">([\s\S]*?)<\/div>/);
        var desc = descMatch ? descMatch[1].replace(/<[^>]*>/g, "").trim() : "";

        return {
            "id": mangaId,
            "title": title,
            "thumbnailUrl": coverUrl,
            "author": "",
            "description": desc,
            "status": html.indexOf("Ongoing") !== -1 ? 1 : (html.indexOf("Tamat") !== -1 ? 2 : 0),
            "genre": "",
            "sourceId": "Komiku"
        };
    },

    getChapterList: function(mangaId) {
        var baseUrl = "https://komiku.org";
        var html = http.httpGet(baseUrl + mangaId);
        if (!html) return [];

        var chapters = [];
        // Match chapters: <td class="tuji"><a href="/ch/..." title="...">Chapter ...</a></td>
        var regex = /<td class="tuji"><a href="([^"]+)"[^>]*>([^<]+)<\/a>/g;
        var match;
        while ((match = regex.exec(html)) !== null) {
            var chUrl = match[1].trim();
            var chName = match[2].trim();
            
            // Extract chapter number
            var numMatch = chName.match(/Chapter\s*(\d+(\.\d+)?)/i);
            var chNum = numMatch ? parseFloat(numMatch[1]) : -1.0;

            chapters.push({
                "id": chUrl,
                "mangaId": mangaId,
                "url": chUrl,
                "name": chName,
                "chapterNumber": chNum,
                "scanlator": "Komiku",
                "dateUpload": 0
            });
        }
        return chapters;
    },

    getPageList: function(chapterId) {
        var baseUrl = "https://komiku.org";
        var html = http.httpGet(baseUrl + chapterId);
        if (!html) return [];

        var pages = [];
        // Match pages: <img src="https://image.komiku.org/uploads/..." ...> inside #Baca_Komik
        var regex = /<img[^>]+src="([^"]+(?:jpg|jpeg|png|webp)[^"]*)"/g;
        var match;
        var index = 0;
        var seen = {};
        while ((match = regex.exec(html)) !== null) {
            var imgUrl = match[1];
            if (imgUrl.indexOf("logo") !== -1 || imgUrl.indexOf("banner") !== -1 || imgUrl.indexOf("loading") !== -1) continue;
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
