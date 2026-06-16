import QtQuick 2.9
import Lomiri.Components 1.3
import Qt.labs.settings 1.0

// Browse page — terhubung ke C++ MangaDexSource & Keiyoushi Extensions
Page {
    id: browsePage
    property var mainStack: null
    property bool isLoading: false
    property int activeTab: 0
    property bool isLoadingExtensions: false
    property string selectedSource: "" // "" berarti tampilkan daftar source, lainnya tampilkan isi manga source tersebut

    Rectangle { anchors.fill: parent; color: "#111111" }

    Settings {
        id: settings
        category: "Extensions"
        property string installedPkgs: "[]"
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
            refreshActiveSources();
        }
    }

    function uninstallExtension(pkg) {
        var pkgs = JSON.parse(settings.installedPkgs);
        var idx = pkgs.indexOf(pkg);
        if (idx !== -1) {
            pkgs.splice(idx, 1);
            settings.installedPkgs = JSON.stringify(pkgs);
            refreshActiveSources();
        }
    }

    function refreshActiveSources() {
        activeSourcesModel.clear();
        // Selalu sertakan MangaDex sebagai default built-in source
        activeSourcesModel.append({
            "name": "MangaDex",
            "pkg": "eu.kanade.tachiyomi.extension.en.mangadex",
            "lang": "en",
            "isBuiltIn": true
        });

        // Tambah ekstensi lain yang telah di-install
        var pkgs = JSON.parse(settings.installedPkgs);
        for (var i = 0; i < extensionModel.count; i++) {
            var ext = extensionModel.get(i);
            if (pkgs.indexOf(ext.pkg) !== -1 && ext.pkg !== "eu.kanade.tachiyomi.extension.en.mangadex") {
                activeSourcesModel.append({
                    "name": ext.name.replace("Tachiyomi: ", ""),
                    "pkg": ext.pkg,
                    "lang": ext.lang,
                    "isBuiltIn": false
                });
            }
        }
    }

    function loadExtensions() {
        if (extensionModel.count > 0) {
            refreshActiveSources();
            return;
        }
        isLoadingExtensions = true
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                isLoadingExtensions = false
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        extensionModel.clear();
                        for (var i = 0; i < data.length; i++) {
                            var ext = data[i];
                            extensionModel.append({
                                "name": ext.name || "",
                                "pkg": ext.pkg || "",
                                "version": ext.version || "",
                                "lang": ext.lang || "",
                                "nsfw": ext.nsfw === 1,
                                "apk": ext.apk || ""
                            });
                        }
                        refreshActiveSources();
                    } catch (e) {
                        console.log("Failed to parse extensions JSON:", e);
                    }
                } else {
                    console.log("Failed to fetch extensions:", xhr.statusText);
                }
            }
        }
        xhr.open("GET", "https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json");
        xhr.send();
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

    Component.onCompleted: {
        loadExtensions();
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
                                    loadExtensions();
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle { visible: selectedSource === ""; width: parent.width; height: visible ? units.dp(1) : 0; color: "#2A2A2A" }

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

            // Loading indicator
            Item {
                visible: browsePage.isLoading
                width: parent.width
                height: units.gu(6)
                anchors.top: searchBarContainer.bottom
                ActivityIndicator { running: parent.visible; anchors.centerIn: parent }
            }

            // Error label container
            Item {
                id: errorContainer
                visible: errorLabel.text !== "" && !browsePage.isLoading
                width: parent.width
                height: errorLabel.implicitHeight + units.gu(4)
                anchors.top: searchBarContainer.bottom

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

            // List of manga
            ListView {
                anchors.top: searchBarContainer.bottom
                anchors.bottom: parent.bottom
                width: parent.width
                visible: !browsePage.isLoading
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
                                text: {
                                    var s = model.status
                                    if (s === 1) return "Ongoing"
                                    if (s === 2) return "Completed"
                                    return ""
                                }
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
        }

        // ---- VIEW 2: Daftar Active Sources (Tab 0) ----
        ListView {
            visible: selectedSource === "" && browsePage.activeTab === 0
            width: parent.width
            height: parent.height - units.gu(5.5)
            clip: true
            model: activeSourcesModel

            delegate: Item {
                width: parent.width
                height: units.gu(8)

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(2)
                    anchors.rightMargin: units.gu(2)
                    spacing: units.gu(2)

                    Rectangle {
                        width: units.gu(5)
                        height: units.gu(5)
                        anchors.verticalCenter: parent.verticalCenter
                        color: model.isBuiltIn ? "#1A3A6A" : "#2A2A2A"
                        radius: units.dp(8)
                        Label {
                            anchors.centerIn: parent
                            text: model.name.charAt(0)
                            color: "white"
                            font.bold: true
                            font.pixelSize: units.gu(2.2)
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
                            text: model.lang.toUpperCase() + (model.isBuiltIn ? " • Built-in Source" : " • Extension Source")
                            color: "#888888"
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
                                selectedSource = model.name;
                                browsePage.isLoading = true;
                                mangaModel.clear();
                                // load popular manga (untuk demo, source lain juga memanggil MangaDex)
                                mangaDex.getPopularManga(1);
                            }
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
            height: parent.height - units.gu(5.5)

            ActivityIndicator {
                anchors.centerIn: parent
                running: browsePage.isLoadingExtensions
                visible: running
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
                    height: units.gu(8)
                    
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
                                        fallbackText.visible = true
                                    }
                                }
                            }
                            Label {
                                id: fallbackText
                                visible: false
                                anchors.centerIn: parent
                                text: model.name ? model.name.replace("Tachiyomi: ", "").charAt(0).toUpperCase() : "?"
                                color: "white"
                                font.bold: true
                                font.pixelSize: units.gu(2.5)
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
}
