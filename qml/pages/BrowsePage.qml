import QtQuick 2.9
import Lomiri.Components 1.3
import Qt.labs.settings 1.0

// Browse page — terhubung ke C++ MangaDexSource, Keiyoushi Extensions & Suwayomi backend
Page {
    id: browsePage
    property var mainStack: null
    property bool isLoading: false
    property int activeTab: 0
    property bool isLoadingExtensions: false
    property string selectedSource: "" // "" berarti tampilkan daftar source, lainnya tampilkan isi manga source tersebut
    property string globalSearchQuery: ""
    property string extensionSearchQuery: ""
    property string selectedLanguageFilter: "All"
    property string layoutMode: "comfortable"

    // Suwayomi backend integration
    property string suwayomiServer: suwayomiRunner.isRunning ? suwayomiRunner.baseUrl : ""
    property bool isLoadingSuwayomi: false
    property var suwayomiSources: []  // cache sources dari Suwayomi API
    property var activeSyncingPkgs: []
    property var failedSyncingPkgs: []
    property var succeededSyncingPkgs: []

    // Peta pkg name → Suwayomi source ID (untuk scraper JS)
    // Source ID ini harus cocok dengan _sourceId di file .js scraper
    property var suwayomiPkgMap: ({
        "eu.kanade.tachiyomi.extension.id.westmanga":    "8883916630998758688",
        "eu.kanade.tachiyomi.extension.id.shinigami":    "3411809758861089969",
        "eu.kanade.tachiyomi.extension.id.klikmanga":    "5213948951740602020",
        "eu.kanade.tachiyomi.extension.id.komiku":       "4838485846640015979",
        "eu.kanade.tachiyomi.extension.id.komikucom":    "8489420317813224728",
        "eu.kanade.tachiyomi.extension.id.kiryuu":       "3639673976007021338",
        "eu.kanade.tachiyomi.extension.id.komikcast":    "972717448578983812",
        "eu.kanade.tachiyomi.extension.id.cosmicscansid":"6559481336553833282"
    })

    Rectangle { anchors.fill: parent; color: "#111111" }

    Settings {
        id: settings
        category: "Extensions"
        property string installedPkgs: "[]"
    }

    Settings {
        id: repoSettings
        category: "ExtensionRepos"
        property string repos: "[]"
    }

    ListModel { id: extensionModel }
    ListModel { id: activeSourcesModel }
    ListModel { id: mangaModel }

    // Helpers untuk instalasi ekstensi
    function isInstalled(pkg) {
        var pkgs = JSON.parse(settings.installedPkgs);
        return pkgs.indexOf(pkg) !== -1;
    }

    function installExtension(pkg) {
        var pkgs = JSON.parse(settings.installedPkgs);
        if (pkgs.indexOf(pkg) === -1) {
            pkgs.push(pkg);
            settings.installedPkgs = JSON.stringify(pkgs);
            if (suwayomiServer && suwayomiServer !== "") {
                var xhr = new XMLHttpRequest();
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200 || xhr.status === 201 || xhr.status === 302) {
                            console.log("Suwayomi installed extension: " + pkg);
                            loadSuwayomiSources();
                        } else {
                            console.log("Suwayomi failed to install extension: " + xhr.statusText);
                            refreshActiveSources();
                        }
                    }
                };
                xhr.open("GET", suwayomiServer + "/api/v1/extension/install/" + pkg);
                xhr.send();
            } else {
                refreshActiveSources();
            }
        }
    }

    function uninstallExtension(pkg) {
        var pkgs = JSON.parse(settings.installedPkgs);
        var idx = pkgs.indexOf(pkg);
        if (idx !== -1) {
            pkgs.splice(idx, 1);
            settings.installedPkgs = JSON.stringify(pkgs);
            if (suwayomiServer && suwayomiServer !== "") {
                var xhr = new XMLHttpRequest();
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200) {
                            console.log("Suwayomi uninstalled extension: " + pkg);
                            loadSuwayomiSources();
                        } else {
                            console.log("Suwayomi failed to uninstall extension: " + xhr.statusText);
                            refreshActiveSources();
                        }
                    }
                };
                xhr.open("GET", suwayomiServer + "/api/v1/extension/uninstall/" + pkg);
                xhr.send();
            } else {
                refreshActiveSources();
            }
        }
    }

    function refreshActiveSources() {
        activeSourcesModel.clear();

        // MangaDex built-in source (always shown)
        activeSourcesModel.append({
            "name": "MangaDex",
            "pkg": "eu.kanade.tachiyomi.extension.en.mangadex",
            "lang": "en",
            "baseUrl": "https://api.mangadex.org",
            "isBuiltIn": true,
            "isSuwayomi": false
        });

        // Suwayomi backend sources (selalu ditampilkan jika tersedia)
        // Peta Suwayomi source ID → pkg name untuk JS scraper
        var suwayomiIdToPkg = {
            "8883916630998758688": "eu.kanade.tachiyomi.extension.id.westmanga",
            "3411809758861089969": "eu.kanade.tachiyomi.extension.id.shinigami",
            "5213948951740602020": "eu.kanade.tachiyomi.extension.id.klikmanga",
            "4838485846640015979": "eu.kanade.tachiyomi.extension.id.komiku",
            "8489420317813224728": "eu.kanade.tachiyomi.extension.id.komikucom",
            "3639673976007021338": "eu.kanade.tachiyomi.extension.id.kiryuu",
            "972717448578983812":  "eu.kanade.tachiyomi.extension.id.komikcast",
            "6559481336553833282": "eu.kanade.tachiyomi.extension.id.cosmicscansid"
        };

        for (var s = 0; s < suwayomiSources.length; s++) {
            var src = suwayomiSources[s];
            if (src.id === "0") continue; // skip Local source
            var pkg = suwayomiIdToPkg[src.id] || ("suwayomi." + src.id);
            activeSourcesModel.append({
                "name": src.displayName || src.name,
                "pkg": pkg,
                "lang": src.lang || "id",
                "baseUrl": src.baseUrl || "",
                "isBuiltIn": false,
                "isSuwayomi": true,
                "suwayomiId": src.id
            });
        }

        // Tambah ekstensi Keiyoushi yang telah di-install (selain yang sudah ada di Suwayomi)
        var pkgs = JSON.parse(settings.installedPkgs);
        
        // Buat list package yang sudah dimasukkan sebagai Suwayomi source
        var suwayomiPkgs = [];
        for (var s = 0; s < suwayomiSources.length; s++) {
            var src = suwayomiSources[s];
            if (src.id !== "0") {
                var pkg = suwayomiIdToPkg[src.id] || src.pkg || ("suwayomi." + src.id);
                suwayomiPkgs.push(pkg);
            }
        }

        for (var i = 0; i < extensionModel.count; i++) {
            var ext = extensionModel.get(i);
            if (pkgs.indexOf(ext.pkg) !== -1
                && ext.pkg !== "eu.kanade.tachiyomi.extension.en.mangadex"
                && suwayomiPkgs.indexOf(ext.pkg) === -1) {
                activeSourcesModel.append({
                    "name": ext.name.replace("Tachiyomi: ", ""),
                    "pkg": ext.pkg,
                    "lang": ext.lang,
                    "baseUrl": ext.baseUrl || "",
                    "isBuiltIn": false,
                    "isSuwayomi": false
                });
            }
        }
    }

    // Fetch daftar sources yang aktif dari Suwayomi backend
    function loadSuwayomiSources() {
        if (!suwayomiServer || suwayomiServer === "" || isLoadingSuwayomi) return;
        isLoadingSuwayomi = true;
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                isLoadingSuwayomi = false;
                if (xhr.status === 200) {
                    try {
                        var sources = JSON.parse(xhr.responseText);
                        // Hanya tampilkan source yang bukan Local source
                        browsePage.suwayomiSources = sources.filter(function(s) {
                            return s.id !== "0";
                        });
                        console.log("Suwayomi sources loaded: " + browsePage.suwayomiSources.length);
                        refreshActiveSources();
                        // Only trigger sync if we haven't already done a sync this session
                        if (succeededSyncingPkgs.length === 0 && failedSyncingPkgs.length === 0) {
                            syncInstalledExtensionsToSuwayomi();
                        }
                    } catch (e) {
                        console.log("Failed to parse Suwayomi sources: " + e);
                    }
                } else {
                    console.log("Suwayomi server not available: " + xhr.status);
                }
            }
        };
        xhr.open("GET", suwayomiServer + "/api/v1/source/list");
        xhr.send();
    }

    function syncInstalledExtensionsToSuwayomi() {
        if (!suwayomiServer || suwayomiServer === "") return;
        var pkgs = [];
        try {
            pkgs = JSON.parse(settings.installedPkgs);
        } catch(e) {
            return;
        }
        if (pkgs.length === 0) return;

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var backendExtensions = JSON.parse(xhr.responseText);
                    var installedMap = {};
                    for (var i = 0; i < backendExtensions.length; i++) {
                        var ext = backendExtensions[i];
                        if (ext.isInstalled) {
                            installedMap[ext.pkgName] = true;
                        }
                    }
                    
                    var toInstall = [];
                    pkgs.forEach(function(pkg) {
                        if (pkg !== "eu.kanade.tachiyomi.extension.en.mangadex" && !installedMap[pkg]) {
                            if (activeSyncingPkgs.indexOf(pkg) === -1 &&
                                failedSyncingPkgs.indexOf(pkg) === -1 &&
                                succeededSyncingPkgs.indexOf(pkg) === -1) {
                                toInstall.push(pkg);
                            }
                        }
                    });

                    if (toInstall.length === 0) {
                        // All extensions are synced — just refresh the active sources list
                        // Do NOT call loadSuwayomiSources() here to avoid mutual recursion
                        refreshActiveSources();
                        return;
                    }

                    var pkgToInstall = toInstall[0];
                    var newSyncList = activeSyncingPkgs.slice();
                    newSyncList.push(pkgToInstall);
                    activeSyncingPkgs = newSyncList;

                    console.log("Syncing: Installing extension in Suwayomi backend: " + pkgToInstall);
                    var instXhr = new XMLHttpRequest();
                    instXhr.onreadystatechange = function() {
                        if (instXhr.readyState === XMLHttpRequest.DONE) {
                            var currentSyncs = activeSyncingPkgs.slice();
                            var idx = currentSyncs.indexOf(pkgToInstall);
                            if (idx !== -1) {
                                currentSyncs.splice(idx, 1);
                                activeSyncingPkgs = currentSyncs;
                            }

                            if (instXhr.status === 200 || instXhr.status === 201 || instXhr.status === 302) {
                                // 201 = newly installed, 302 = already installed (FOUND), both are success
                                console.log("Sync installed successfully (status " + instXhr.status + "): " + pkgToInstall);
                                // Track as succeeded so we don't retry it in recursive calls
                                var newSucceededList = succeededSyncingPkgs.slice();
                                newSucceededList.push(pkgToInstall);
                                succeededSyncingPkgs = newSucceededList;
                                // Continue syncing remaining extensions
                                syncInstalledExtensionsToSuwayomi();
                            } else {
                                console.log("Sync install failed for " + pkgToInstall + ": " + instXhr.status);
                                var newFailedList = failedSyncingPkgs.slice();
                                newFailedList.push(pkgToInstall);
                                failedSyncingPkgs = newFailedList;
                                syncInstalledExtensionsToSuwayomi();
                            }
                        }
                    };
                    instXhr.open("GET", suwayomiServer + "/api/v1/extension/install/" + pkgToInstall);
                    instXhr.send();
                } catch(e) {
                    console.log("Failed to sync extensions: " + e);
                }
            }
        };
        xhr.open("GET", suwayomiServer + "/api/v1/extension/list");
        xhr.send();
    }

    // --- Extension repo helpers ---
    function getConfiguredRepos() {
        try { return JSON.parse(repoSettings.repos); } catch(e) { return []; }
    }

    // Track pending fetches for multi-repo loading
    property int _pendingRepoFetches: 0

    function loadExtensions(forceReload) {
        if (!forceReload && extensionModel.count > 0) {
            refreshActiveSources();
            return;
        }

        var repos = getConfiguredRepos();

        if (repos.length === 0) {
            // No repos configured — show empty
            extensionModel.clear();
            isLoadingExtensions = false;
            console.log("Extension repos configured: []");
            return;
        }

        console.log("Extension repos configured: " + JSON.stringify(repos));

        isLoadingExtensions = true;
        extensionModel.clear();
        browsePage._pendingRepoFetches = repos.length;

        for (var r = 0; r < repos.length; r++) {
            (function(repoUrl) {
                console.log("Fetching extensions index from URL: " + repoUrl);
                var xhr = new XMLHttpRequest();
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        browsePage._pendingRepoFetches--;
                        if (xhr.status === 200) {
                            try {
                                var data = JSON.parse(xhr.responseText);
                                for (var i = 0; i < data.length; i++) {
                                    var ext = data[i];
                                    extensionModel.append({
                                        "name": ext.name || "",
                                        "pkg": ext.pkg || "",
                                        "version": ext.version || "",
                                        "lang": ext.lang || "",
                                        "nsfw": ext.nsfw === 1,
                                        "apk": ext.apk || "",
                                        // ambil baseUrl dari sources[0] jika ada
                                        "baseUrl": (ext.sources && ext.sources.length > 0) ? ext.sources[0].baseUrl : ""
                                    });
                                }
                            } catch (e) {
                                console.log("Failed to parse extensions from " + repoUrl + ": " + e);
                            }
                        } else {
                            console.log("Failed to fetch from " + repoUrl + ": " + xhr.statusText);
                        }
                        // When all repos done, finish loading
                        if (browsePage._pendingRepoFetches <= 0) {
                            isLoadingExtensions = false;
                            refreshActiveSources();
                        }
                    }
                }
                xhr.open("GET", repoUrl);
                xhr.send();
            })(repos[r].url);
        }
    }

    // Koneksikan sinyal dari C++ MangaDexSource
    Connections {
        target: mangaDex
        onMangaListReady: {
            browsePage.isLoading = false
            mangaModel.clear()
            for (var i = 0; i < mangas.length; i++) {
                mangaModel.append(mangas[i])
            }
        }
        onNetworkError: {
            browsePage.isLoading = false
            console.log("Network Error:", message)
            errorLabel.text = "Error: " + message
            errorLabel.visible = true
        }
    }

    Connections {
        target: appSettings
        onNsfwEnabledChanged: {
            mangaDex.setNsfwEnabled(appSettings.nsfwEnabled)
        }
    }

    Component.onCompleted: {
        mangaDex.setNsfwEnabled(appSettings.nsfwEnabled);
        if (suwayomiRunner.isRunning) {
            loadSuwayomiSources();  // Load if already running
        }
        loadExtensions(false);  // Then load Keiyoushi extensions
    }

    Connections {
        target: suwayomiRunner
        onReady: {
            loadSuwayomiSources();
        }
    }

    onVisibleChanged: {
        if (visible && activeTab === 1) {
            // Reload if repos might have changed
            loadExtensions(true);
        }
    }

    header: PageHeader {
        title: selectedSource === "" ? "Browse" : selectedSource
        StyleHints { foregroundColor: "white"; backgroundColor: "#111111"; dividerColor: "#2A2A2A" }
        
        leadingActionBar.actions: [
            Action {
                iconName: "back"
                visible: selectedSource !== ""
                onTriggered: selectedSource = ""
            }
        ]

        trailingActionBar.actions: [
            Action {
                iconSource: Qt.resolvedUrl("../assets/ic_grid.svg")
                visible: selectedSource !== ""
                onTriggered: layoutSelectorDropdown.visible = !layoutSelectorDropdown.visible
            },
            Action {
                iconName: "contextual-menu"
                text: "More"
                visible: selectedSource === ""
                onTriggered: browseHeaderMenu.visible = !browseHeaderMenu.visible
            }
        ]
    }

    Column {
        anchors.top: parent.header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        // Tab bar — hanya muncul saat berada di menu utama sources/extensions list
        Rectangle {
            visible: selectedSource === ""
            width: parent.width
            height: visible ? units.gu(5.5) : 0
            color: "#111111"

            Row {
                anchors.fill: parent

                Repeater {
                    model: ["Sources", "Extensions"]
                    Item {
                        width: parent.width / 2
                        height: parent.height

                        Label {
                            anchors.centerIn: parent
                            text: modelData
                            color: browsePage.activeTab === index ? "#4A90D9" : "#888888"
                            font.pixelSize: units.gu(1.9)
                            font.bold: browsePage.activeTab === index
                        }
                        Rectangle {
                            visible: browsePage.activeTab === index
                            anchors.bottom: parent.bottom
                            width: parent.width; height: units.dp(2)
                            color: "#4A90D9"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                browsePage.activeTab = index
                                if (index === 0) {
                                    refreshActiveSources();
                                } else if (index === 1) {
                                    loadExtensions(false);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Empty state for Extensions
        Label {
            visible: browsePage.activeTab === 1 && extensionModel.count === 0 && !isLoadingExtensions
            text: "No extensions available. Check repo settings."
            color: "#888888"
            anchors.centerIn: parent
        }

        Rectangle { visible: selectedSource === ""; width: parent.width; height: visible ? units.dp(1) : 0; color: "#2A2A2A" }

        // Search & Filter Section
        Column {
            visible: selectedSource === ""
            width: parent.width
            spacing: units.gu(1.2)
            bottomPadding: units.gu(1)
            topPadding: units.gu(1.5)

            // Search Bar
            Rectangle {
                width: parent.width - units.gu(4)
                height: units.gu(4.8)
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#1E1E1E"
                border.color: "#2A2A2A"
                radius: units.dp(8)

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(1.5)
                    anchors.rightMargin: units.gu(1.5)
                    spacing: units.gu(1)

                    Icon {
                        name: "search"
                        width: units.gu(2.2)
                        height: units.gu(2.2)
                        color: "#888888"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextField {
                        id: searchFieldInput
                        width: parent.width - units.gu(6)
                        height: parent.height
                        placeholderText: browsePage.activeTab === 0 ? "Global search manga..." : "Search extensions..."
                        color: "white"
                        font.pixelSize: units.gu(1.6)
                        anchors.verticalCenter: parent.verticalCenter
                        text: browsePage.activeTab === 0 ? browsePage.globalSearchQuery : browsePage.extensionSearchQuery

                        onTextChanged: {
                            if (browsePage.activeTab === 0) {
                                // Sync back text
                            } else {
                                browsePage.extensionSearchQuery = text.trim();
                            }
                        }

                        onAccepted: {
                            if (browsePage.activeTab === 0) {
                                var query = text.trim();
                                browsePage.globalSearchQuery = query;
                                if (query !== "") {
                                    browsePage.isLoading = true;
                                    mangaModel.clear();
                                    mangaDex.searchManga(query, 1);
                                }
                            }
                        }
                    }

                    // Clear button
                    Icon {
                        name: "close"
                        width: units.gu(2)
                        height: units.gu(2)
                        color: "#888888"
                        visible: searchFieldInput.text !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                searchFieldInput.text = "";
                                if (browsePage.activeTab === 0) {
                                    browsePage.globalSearchQuery = "";
                                    mangaModel.clear();
                                } else {
                                    browsePage.extensionSearchQuery = "";
                                }
                            }
                        }
                    }
                }
            }

            // Language Filter Chips
            Flickable {
                width: parent.width
                height: units.gu(4.5)
                contentWidth: filterRow.width + units.gu(4)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick

                Row {
                    id: filterRow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    spacing: units.gu(1)

                    Repeater {
                        model: [
                            { label: "All", code: "All" },
                            { label: "English", code: "en" },
                            { label: "Indonesian", code: "id" },
                            { label: "Japanese", code: "ja" }
                        ]
                        delegate: Rectangle {
                            width: filterLabel.implicitWidth + units.gu(3)
                            height: units.gu(3.2)
                            radius: height / 2
                            color: browsePage.selectedLanguageFilter === modelData.code ? "#264A90D9" : "#1E1E1E"
                            border.color: browsePage.selectedLanguageFilter === modelData.code ? "#4A90D9" : "#2A2A2A"

                            Label {
                                id: filterLabel
                                anchors.centerIn: parent
                                text: modelData.label
                                color: browsePage.selectedLanguageFilter === modelData.code ? "#4A90D9" : "#888888"
                                font.bold: browsePage.selectedLanguageFilter === modelData.code
                                font.pixelSize: units.gu(1.4)
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: browsePage.selectedLanguageFilter = modelData.code
                            }
                        }
                    }
                }
            }
        }

        // ---- VIEW 1: Browsing list manga dalam source tertentu ----
        Item {
            visible: selectedSource !== ""
            width: parent.width
            height: visible ? parent.height : 0

            // Search bar
            Item {
                id: searchBarContainer
                width: parent.width
                height: units.gu(6)

                Rectangle {
                    width: parent.width - units.gu(4)
                    height: units.gu(5)
                    anchors.centerIn: parent
                    color: "#2A2A2A"
                    radius: units.dp(8)

                    TextField {
                        id: searchField
                        anchors.fill: parent
                        anchors.margins: units.dp(2)
                        placeholderText: "Search in " + selectedSource + "..."
                        color: "white"
                        onAccepted: {
                            if (text.trim() !== "") {
                                browsePage.isLoading = true
                                mangaModel.clear()
                                mangaDex.searchManga(text.trim(), 1)
                            }
                        }
                    }
                }
            }

            // Sub-header filter buttons
            Row {
                id: sourceFiltersRow
                width: parent.width - units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: searchBarContainer.bottom
                height: units.gu(5)
                spacing: units.gu(1.5)

                property string activeFilter: "popular"

                Rectangle {
                    width: (parent.width - units.gu(3)) / 3
                    height: units.gu(4)
                    radius: units.dp(6)
                    color: parent.activeFilter === "popular" ? "#264A90D9" : "#1E1E1E"
                    border.color: parent.activeFilter === "popular" ? "#4A90D9" : "#2A2A2A"

                    Row {
                        anchors.centerIn: parent
                        spacing: units.dp(6)
                        Icon { name: "like"; width: units.gu(2); height: units.gu(2); color: parent.parent.activeFilter === "popular" ? "#4A90D9" : "#888888"; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: "Popular"; color: parent.parent.parent.activeFilter === "popular" ? "#4A90D9" : "#888888"; font.bold: parent.parent.parent.activeFilter === "popular"; anchors.verticalCenter: parent.verticalCenter }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            sourceFiltersRow.activeFilter = "popular"
                            browsePage.isLoading = true
                            mangaModel.clear()
                            mangaDex.getPopularManga(1)
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - units.gu(3)) / 3
                    height: units.gu(4)
                    radius: units.dp(6)
                    color: parent.activeFilter === "latest" ? "#264A90D9" : "#1E1E1E"
                    border.color: parent.activeFilter === "latest" ? "#4A90D9" : "#2A2A2A"

                    Row {
                        anchors.centerIn: parent
                        spacing: units.dp(6)
                        Icon { name: "clock"; width: units.gu(2); height: units.gu(2); color: parent.parent.activeFilter === "latest" ? "#4A90D9" : "#888888"; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: "Latest"; color: parent.parent.parent.activeFilter === "latest" ? "#4A90D9" : "#888888"; font.bold: parent.parent.parent.activeFilter === "latest"; anchors.verticalCenter: parent.verticalCenter }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            sourceFiltersRow.activeFilter = "latest"
                            browsePage.isLoading = true
                            mangaModel.clear()
                            mangaDex.getPopularManga(1)
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - units.gu(3)) / 3
                    height: units.gu(4)
                    radius: units.dp(6)
                    color: parent.activeFilter === "filter" ? "#264A90D9" : "#1E1E1E"
                    border.color: parent.activeFilter === "filter" ? "#4A90D9" : "#2A2A2A"

                    Row {
                        anchors.centerIn: parent
                        spacing: units.dp(6)
                        Icon { name: "settings"; width: units.gu(2); height: units.gu(2); color: parent.parent.activeFilter === "filter" ? "#4A90D9" : "#888888"; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: "Filter"; color: parent.parent.parent.activeFilter === "filter" ? "#4A90D9" : "#888888"; font.bold: parent.parent.parent.activeFilter === "filter"; anchors.verticalCenter: parent.verticalCenter }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            sourceFiltersRow.activeFilter = "filter"
                        }
                    }
                }
            }

            // Loading indicator
            Item {
                visible: browsePage.isLoading
                width: parent.width
                height: units.gu(6)
                anchors.top: sourceFiltersRow.bottom
                ActivityIndicator { running: parent.visible; anchors.centerIn: parent }
            }

            // Error label container
            Item {
                id: errorContainer
                visible: errorLabel.text !== "" && !browsePage.isLoading
                width: parent.width
                height: errorLabel.implicitHeight + units.gu(4)
                anchors.top: sourceFiltersRow.bottom

                Label {
                    id: errorLabel
                    anchors.centerIn: parent
                    width: parent.width - units.gu(4)
                    horizontalAlignment: Text.AlignHCenter
                    color: "#FF6B6B"
                    font.pixelSize: units.gu(1.8)
                    wrapMode: Text.WordWrap
                }
            }

            // List View Layout
            ListView {
                anchors.top: sourceFiltersRow.bottom
                anchors.bottom: parent.bottom
                width: parent.width
                visible: !browsePage.isLoading && browsePage.layoutMode === "list"
                model: mangaModel
                clip: true

                delegate: Item {
                    width: parent.width
                    height: units.gu(10)

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: units.gu(2)
                        anchors.rightMargin: units.gu(2)
                        spacing: units.gu(2)

                        Rectangle {
                            width: units.gu(7)
                            height: units.gu(9)
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#2A2A2A"
                            radius: units.dp(6)
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: model.thumbnailUrl || ""
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                            }
                            Label {
                                visible: model.thumbnailUrl === ""
                                anchors.centerIn: parent
                                text: model.title ? model.title.charAt(0).toUpperCase() : "?"
                                color: "white"
                                font.bold: true
                                font.pixelSize: units.gu(3)
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - units.gu(9)
                            spacing: units.dp(5)

                            Label {
                                text: model.title || ""
                                color: "white"
                                font.pixelSize: units.gu(1.9)
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Label {
                                text: model.author || "Unknown Author"
                                color: "#888888"
                                font.pixelSize: units.gu(1.5)
                            }
                            Label {
                                text: model.status === 1 ? "Ongoing" : (model.status === 2 ? "Completed" : "")
                                color: model.status === 1 ? "#4CAF50" : "#888888"
                                font.pixelSize: units.gu(1.4)
                            }
                        }
                    }

                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (mainStack) {
                                mainStack.push(Qt.resolvedUrl("MangaDetailPage.qml"), {
                                    mangaId: model.id,
                                    mangaTitle: model.title,
                                    mangaDesc: model.description,
                                    mangaCover: model.thumbnailUrl,
                                    mangaAuthor: model.author,
                                    mangaStatus: model.status,
                                    mangaGenre: model.genre,
                                    mainStack: mainStack
                                })
                            }
                        }
                    }
                }
            }

            // Grid View Layout (Mihon Style: Comfortable & Compact)
            GridView {
                id: mangaGridView
                anchors.top: sourceFiltersRow.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: units.gu(2)
                anchors.rightMargin: units.gu(2)
                visible: !browsePage.isLoading && browsePage.layoutMode !== "list"
                model: mangaModel
                clip: true
                cellWidth: browsePage.layoutMode === "comfortable" ? (width / 2) : (width / 3)
                cellHeight: browsePage.layoutMode === "comfortable" ? units.gu(25) : units.gu(18)

                delegate: Item {
                    width: mangaGridView.cellWidth - units.gu(1)
                    height: mangaGridView.cellHeight - units.gu(1)

                    // Comfortable layout (cover + separate title below)
                    Column {
                        anchors.fill: parent
                        spacing: units.gu(0.8)
                        visible: browsePage.layoutMode === "comfortable"

                        Rectangle {
                            width: parent.width
                            height: units.gu(18)
                            color: "#2A2A2A"
                            radius: units.dp(8)
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: model.thumbnailUrl || ""
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                            }
                            Label {
                                visible: model.thumbnailUrl === ""
                                anchors.centerIn: parent
                                text: model.title ? model.title.charAt(0).toUpperCase() : "?"
                                color: "white"
                                font.bold: true
                                font.pixelSize: units.gu(3)
                            }
                        }

                        Label {
                            text: model.title || ""
                            color: "white"
                            font.pixelSize: units.gu(1.5)
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    // Compact layout (full cover + semi-transparent text overlay at the bottom)
                    Rectangle {
                        anchors.fill: parent
                        visible: browsePage.layoutMode === "compact"
                        color: "#2A2A2A"
                        radius: units.dp(8)
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: model.thumbnailUrl || ""
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                        }
                        Label {
                            visible: model.thumbnailUrl === ""
                            anchors.centerIn: parent
                            text: model.title ? model.title.charAt(0).toUpperCase() : "?"
                            color: "white"
                            font.bold: true
                            font.pixelSize: units.gu(3)
                        }

                        // Bottom overlay for the title
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: units.gu(4.5)
                            color: "#CC000000"

                            Label {
                                anchors.fill: parent
                                anchors.margins: units.gu(0.5)
                                text: model.title || ""
                                color: "white"
                                font.pixelSize: units.gu(1.3)
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (mainStack) {
                                mainStack.push(Qt.resolvedUrl("MangaDetailPage.qml"), {
                                    mangaId: model.id,
                                    mangaTitle: model.title,
                                    mangaDesc: model.description,
                                    mangaCover: model.thumbnailUrl,
                                    mangaAuthor: model.author,
                                    mangaStatus: model.status,
                                    mangaGenre: model.genre,
                                    mainStack: mainStack
                                })
                            }
                        }
                    }
                }
            }
        }

        // ---- VIEW 2: Daftar Active Sources (Tab 0) ----
        ListView {
            visible: selectedSource === "" && browsePage.activeTab === 0 && browsePage.globalSearchQuery === ""
            width: parent.width
            height: parent.height - units.gu(18.5)
            clip: true
            model: activeSourcesModel

            delegate: Item {
                width: parent.width
                property bool matchesLanguage: browsePage.selectedLanguageFilter === "All" || model.lang.toLowerCase() === browsePage.selectedLanguageFilter.toLowerCase()
                visible: matchesLanguage
                height: visible ? units.gu(8) : 0
                clip: true

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(2)
                    anchors.rightMargin: units.gu(2)
                    spacing: units.gu(2)

                    Rectangle {
                        width: units.gu(5)
                        height: units.gu(5)
                        anchors.verticalCenter: parent.verticalCenter
                        color: "transparent"
                        radius: units.dp(8)
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: model.pkg ? "https://raw.githubusercontent.com/keiyoushi/extensions/repo/icon/" + model.pkg + ".png" : "../assets/ic_default_source.webp"
                            fillMode: Image.PreserveAspectFit
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    source = "../assets/ic_default_source.webp"
                                }
                            }
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - units.gu(15)
                        spacing: units.dp(2)
                        Label {
                            text: model.name
                            color: "white"
                            font.pixelSize: units.gu(1.8)
                            font.bold: true
                        }
                        Label {
                            text: model.lang.toUpperCase() + (model.isBuiltIn ? " • Built-in Source" : (model.isSuwayomi ? " • via Suwayomi ✓" : " • Extension Source"))
                            color: model.isSuwayomi ? "#4CAF50" : "#888888"
                            font.pixelSize: units.gu(1.4)
                        }
                    }

                    // Browse Button
                    Rectangle {
                        width: units.gu(8)
                        height: units.gu(3.2)
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#1A3A6A"
                        radius: units.dp(4)
                        Label {
                            anchors.centerIn: parent
                            text: "Browse"
                            color: "#4A90D9"
                            font.pixelSize: units.gu(1.3)
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var srcBaseUrl = model.baseUrl || "https://api.mangadex.org"
                                var srcName    = model.name

                                // Set source di C++ backend sebelum fetch
                                mangaDex.setBaseUrl(srcBaseUrl)
                                mangaDex.setSourceName(srcName)
                                mangaDex.setSourcePackage(model.pkg)
                                mangaDex.setSuwayomiServer(suwayomiServer)

                                selectedSource = srcName
                                browsePage.isLoading = true
                                mangaModel.clear()
                                errorLabel.visible = false
                                mangaDex.getPopularManga(1)
                            }
                        }
                    }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }
            }
        }

        // ---- VIEW 2B: Global Search Results (Tab 0 ketika mencari secara global) ----
        ListView {
            visible: selectedSource === "" && browsePage.activeTab === 0 && browsePage.globalSearchQuery !== ""
            width: parent.width
            height: parent.height - units.gu(18.5)
            clip: true
            model: mangaModel

            header: Item {
                width: parent.width
                height: units.gu(6)
                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                    text: browsePage.isLoading ? "Searching sources..." : "Search Results (" + mangaModel.count + ")"
                    color: "#4A90D9"
                    font.bold: true
                    font.pixelSize: units.gu(1.7)
                }
            }

            delegate: Item {
                width: parent.width
                height: units.gu(10)

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(2)
                    anchors.rightMargin: units.gu(2)
                    spacing: units.gu(2)

                    Rectangle {
                        width: units.gu(7)
                        height: units.gu(9)
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#2A2A2A"
                        radius: units.dp(6)
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: model.thumbnailUrl || ""
                            fillMode: Image.PreserveAspectCrop
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - units.gu(18)
                        spacing: units.dp(4)

                        Label {
                            text: model.title || ""
                            color: "white"
                            font.pixelSize: units.gu(1.8)
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Label {
                            text: "Source: MangaDex • " + (model.author || "Unknown")
                            color: "#888888"
                            font.pixelSize: units.gu(1.4)
                        }
                    }

                    Label {
                        text: model.status === 1 ? "Ongoing" : (model.status === 2 ? "Completed" : "")
                        color: model.status === 1 ? "#4CAF50" : "#888888"
                        font.pixelSize: units.gu(1.3)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (mainStack) {
                            mainStack.push(Qt.resolvedUrl("MangaDetailPage.qml"), {
                                mangaId: model.id,
                                mangaTitle: model.title,
                                mangaDesc: model.description,
                                mangaCover: model.thumbnailUrl,
                                mangaAuthor: model.author,
                                mangaStatus: model.status,
                                mangaGenre: model.genre,
                                mainStack: mainStack
                            })
                        }
                    }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }
            }
        }

        // ---- VIEW 3: Daftar Extensions Store (Tab 1) ----
        Item {
            visible: selectedSource === "" && browsePage.activeTab === 1
            width: parent.width
            height: parent.height - units.gu(18.5)

            ActivityIndicator {
                anchors.centerIn: parent
                running: browsePage.isLoadingExtensions
                visible: running
            }

            // Empty state — no repos configured
            Column {
                anchors.centerIn: parent
                visible: !browsePage.isLoadingExtensions && extensionModel.count === 0
                spacing: units.gu(1.5)

                Icon {
                    name: "stock_website"
                    width: units.gu(6); height: units.gu(6)
                    color: "#444444"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Label {
                    text: "No extension stores configured"
                    color: "#888888"
                    font.pixelSize: units.gu(2)
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Label {
                    text: "Go to \"···\" → Extension stores to add a repo"
                    color: "#555555"
                    font.pixelSize: units.gu(1.6)
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            ListView {
                anchors.fill: parent
                visible: !browsePage.isLoadingExtensions
                clip: true
                model: extensionModel
                header: Item {
                    width: parent.width; height: units.gu(4)
                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(2)
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Available Extensions"
                        color: "white"
                        font.bold: true
                        font.pixelSize: units.gu(1.6)
                    }
                }
                delegate: Item {
                    width: parent.width
                    property bool matchesLanguage: browsePage.selectedLanguageFilter === "All" || model.lang.toLowerCase() === browsePage.selectedLanguageFilter.toLowerCase()
                    property bool matchesSearch: browsePage.extensionSearchQuery === "" || model.name.toLowerCase().indexOf(browsePage.extensionSearchQuery.toLowerCase()) !== -1
                    property bool matchesNsfw: !model.nsfw || appSettings.nsfwEnabled
                    visible: matchesLanguage && matchesSearch && matchesNsfw
                    height: visible ? units.gu(8) : 0
                    clip: true
                    
                    // Cek status secara reaktif
                    property bool installed: browsePage.isInstalled(model.pkg)

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: units.gu(2)
                        anchors.rightMargin: units.gu(2)
                        spacing: units.gu(2)

                        Rectangle {
                            width: units.gu(6)
                            height: units.gu(6)
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#1E1E1E"
                            radius: units.dp(12)
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: "https://raw.githubusercontent.com/keiyoushi/extensions/repo/icon/" + model.pkg + ".png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                onStatusChanged: {
                                    if (status === Image.Error) {
                                        source = "../assets/ic_default_source.webp"
                                    }
                                }
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - units.gu(16)
                            spacing: units.dp(3)
                            Label {
                                text: model.name ? model.name.replace("Tachiyomi: ", "") : ""
                                color: "white"
                                font.pixelSize: units.gu(1.8)
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Label {
                                text: model.lang.toUpperCase() + " • v" + model.version + (model.nsfw ? " • [NSFW]" : "")
                                color: model.nsfw ? "#FF6B6B" : "#888888"
                                font.pixelSize: units.gu(1.4)
                            }
                        }

                        // Tombol Install / Uninstall
                        Rectangle {
                            width: units.gu(8)
                            height: units.gu(3.2)
                            anchors.verticalCenter: parent.verticalCenter
                            color: installed ? "#1A3A6A" : "#2A2A2A"
                            radius: units.dp(4)

                            Label {
                                anchors.centerIn: parent
                                text: installed ? "Active" : "Install"
                                color: installed ? "#4A90D9" : "#CCCCCC"
                                font.pixelSize: units.gu(1.3)
                                font.bold: true
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (installed) {
                                        browsePage.uninstallExtension(model.pkg);
                                    } else {
                                        browsePage.installExtension(model.pkg);
                                    }
                                }
                            }
                        }
                    }
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }
                }
            }
        }
    }

    // Browse header menu (Extension stores)
    MouseArea {
        anchors.fill: parent
        visible: browseHeaderMenu.visible
        onClicked: browseHeaderMenu.visible = false
        z: 9996
    }

    Rectangle {
        id: browseHeaderMenu
        visible: false
        anchors.top: parent.header.bottom
        anchors.topMargin: units.dp(4)
        anchors.right: parent.right
        anchors.rightMargin: units.gu(2)
        width: units.gu(26)
        height: browseMenuCol.height + units.gu(2)
        color: "#1E1E1E"
        border.color: "#2A2A2A"
        radius: units.dp(8)
        z: 9997

        Column {
            id: browseMenuCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: units.gu(1)
            anchors.leftMargin: units.gu(1)
            anchors.rightMargin: units.gu(1)

            // Filter
            Item {
                width: parent.width; height: units.gu(5)
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(1)
                    spacing: units.gu(1.5)
                    Icon { name: "filter"; width: units.gu(2.2); height: units.gu(2.2); color: "#888888"; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "Filter"; color: "white"; font.pixelSize: units.gu(1.7); anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; onClicked: browseHeaderMenu.visible = false }
            }

            Rectangle { width: parent.width; height: units.dp(1); color: "#2A2A2A" }

            // Extension stores
            Item {
                width: parent.width; height: units.gu(5)
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(1)
                    spacing: units.gu(1.5)
                    Icon { name: "stock_website"; width: units.gu(2.2); height: units.gu(2.2); color: "#888888"; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "Extension stores"; color: "white"; font.pixelSize: units.gu(1.7); anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        browseHeaderMenu.visible = false
                        if (mainStack) mainStack.push(Qt.resolvedUrl("ExtensionStoresPage.qml"))
                    }
                }
            }
        }
    }

    // Popover layout selector dropdown
    MouseArea {
        anchors.fill: parent
        visible: layoutSelectorDropdown.visible
        onClicked: layoutSelectorDropdown.visible = false
        z: 9998
    }

    Rectangle {
        id: layoutSelectorDropdown
        visible: false
        anchors.top: parent.header.bottom
        anchors.topMargin: units.dp(4)
        anchors.right: parent.right
        anchors.rightMargin: units.gu(2)
        width: units.gu(24)
        height: units.gu(15)
        color: "#1E1E1E"
        border.color: "#2A2A2A"
        radius: units.dp(8)
        z: 9999

        Column {
            anchors.fill: parent
            anchors.margins: units.gu(1)
            spacing: 0

            Repeater {
                model: [
                    { label: "Comfortable Grid", mode: "comfortable", icon: "view-grid" },
                    { label: "Compact Grid",     mode: "compact",     icon: "view-grid" },
                    { label: "List",             mode: "list",        icon: "view-list" }
                ]
                delegate: Item {
                    width: parent.width
                    height: units.gu(4.3)

                    Rectangle {
                        anchors.fill: parent
                        color: browsePage.layoutMode === modelData.mode ? "#264A90D9" : "transparent"
                        radius: units.dp(4)
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: units.gu(1)
                        spacing: units.gu(1.5)

                        Icon {
                            name: modelData.icon
                            width: units.gu(2.2)
                            height: units.gu(2.2)
                            color: browsePage.layoutMode === modelData.mode ? "#4A90D9" : "#888888"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            text: modelData.label
                            color: browsePage.layoutMode === modelData.mode ? "#4A90D9" : "white"
                            font.pixelSize: units.gu(1.5)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            browsePage.layoutMode = modelData.mode
                            layoutSelectorDropdown.visible = false
                        }
                    }
                }
            }
        }
    }
}
