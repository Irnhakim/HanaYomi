import QtQuick 2.9
import Lomiri.Components 1.3
import Lomiri.Components.ListItems 1.3 as ListItem

// MangaDetailPage — terhubung ke C++ MangaDexSource
Page {
    id: mangaDetailPage
    property var  mainStack: null
    property string mangaId: ""
    property string mangaTitle: "Loading..."
    property string mangaDesc: ""
    property string mangaCover: ""
    property string mangaAuthor: ""
    property int    mangaStatus: 0
    property string mangaGenre: ""

    property bool isFavorite: false
    property bool isLoadingChapters: true

    Rectangle { anchors.fill: parent; color: "#111111" }

    // Sambungkan ke sinyal C++
    Connections {
        target: mangaDex

        onMangaDetailReady: {
            mangaTitle  = manga.title  || mangaTitle
            mangaDesc   = manga.description || ""
            mangaAuthor = manga.author || ""
            mangaStatus = manga.status || 0
            mangaGenre  = manga.genre  || ""
            if (manga.thumbnailUrl) mangaCover = manga.thumbnailUrl

            // Cek apakah sudah di library
            var saved = db.getMangaById(mangaId)
            mangaDetailPage.isFavorite = saved.favorite === true
            if (mangaDetailPage.isFavorite) {
                // Preload categories jika favorite
                loadCategories();
            }

            // Ambil chapter list
            mangaDex.getChapterList(mangaId)
        }

        onChapterListReady: {
            mangaDetailPage.isLoadingChapters = false
            chapterModel.clear()
            for (var i = 0; i < chapters.length; i++) {
                chapterModel.append(chapters[i])
            }
            // Simpan chapter ke DB jika sudah di library
            if (mangaDetailPage.isFavorite) {
                db.insertOrUpdateChapters(chapters, mangaId)
            }
        }

        onNetworkError: {
            mangaDetailPage.isLoadingChapters = false
            console.log("Detail error:", message)
        }
    }

    Component.onCompleted: {
        if (mangaId !== "") {
            mangaDex.getMangaDetails(mangaId)
        }
    }

    header: PageHeader {
        title: mangaTitle
        StyleHints { foregroundColor: "white"; backgroundColor: "#1A1A1A"; dividerColor: "#2A2A2A" }
    }

    ListModel { id: chapterModel }

    Flickable {
        anchors.top: parent.header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        contentHeight: mainCol.height + units.gu(4)
        clip: true

        Column {
            id: mainCol
            width: parent.width

            // ---- Header: Cover + Info ----
            Item {
                width: parent.width
                height: units.gu(22)

                // Background blur effect
                Rectangle {
                    anchors.fill: parent
                    color: "#1A1A1A"
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: units.gu(2)
                    spacing: units.gu(2)

                    // Cover art
                    Rectangle {
                        width: units.gu(13)
                        height: units.gu(18)
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#2A2A2A"
                        radius: units.dp(8)
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: mangaCover
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                        }
                    }

                    // Info
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - units.gu(15)
                        spacing: units.gu(0.8)

                        Label {
                            text: mangaTitle
                            color: "white"
                            font.bold: true
                            font.pixelSize: units.gu(2)
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                        Label {
                            text: mangaAuthor || "Unknown Author"
                            color: "#AAAAAA"
                            font.pixelSize: units.gu(1.6)
                        }
                        Label {
                            text: {
                                if (mangaStatus === 1) return "● Ongoing"
                                if (mangaStatus === 2) return "● Completed"
                                if (mangaStatus === 5) return "● Cancelled"
                                if (mangaStatus === 6) return "● On Hiatus"
                                return "● Unknown"
                            }
                            color: mangaStatus === 1 ? "#4CAF50" : "#888888"
                            font.pixelSize: units.gu(1.5)
                        }
                        Label {
                            text: "MangaDex"
                            color: "#4A90D9"
                            font.pixelSize: units.gu(1.5)
                        }
                    }
                }
            }

            // ---- Action Buttons ----
            Row {
                width: parent.width
                height: units.gu(9)
                spacing: 0

                // Add to Library / In Library
                Item {
                    width: parent.width / 2
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: units.dp(4)

                        Icon {
                            name: isFavorite ? "starred" : "bookmark-new"
                            width: units.gu(3.5)
                            height: units.gu(3.5)
                            color: isFavorite ? "#4A90D9" : "white"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Label {
                            text: isFavorite ? "In Library" : "Add to Library"
                            color: isFavorite ? "#4A90D9" : "white"
                            font.pixelSize: units.gu(1.5)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            // Selalu tampilkan pilihan kategori saat menambah atau mengelola manga di library
                            if (!isFavorite) {
                                // Simpan manga ke DB terlebih dahulu
                                var mangaMap = {
                                    "id": mangaId,
                                    "url": "/manga/" + mangaId,
                                    "title": mangaTitle,
                                    "author": mangaAuthor,
                                    "description": mangaDesc,
                                    "genre": mangaGenre,
                                    "thumbnailUrl": mangaCover,
                                    "status": mangaStatus,
                                    "favorite": 1,
                                    "sourceId": "mangadex"
                                }
                                db.insertOrUpdateManga(mangaMap)
                                if (chapterModel.count > 0) {
                                    var chapters = []
                                    for (var i = 0; i < chapterModel.count; i++) chapters.push(chapterModel.get(i))
                                    db.insertOrUpdateChapters(chapters, mangaId)
                                }
                            }
                            // Muat kategori dan tampilkan dialog overlay
                            loadCategories();
                            categorySelectOverlay.visible = true;
                        }
                    }
                }

                // Open WebView / External
                Item {
                    width: parent.width / 2
                    height: parent.height
                    Column {
                        anchors.centerIn: parent
                        spacing: units.dp(4)
                        Icon { name: "web-browser"; width: units.gu(3.5); height: units.gu(3.5); color: "white"; anchors.horizontalCenter: parent.horizontalCenter }
                        Label { text: "WebView"; color: "white"; font.pixelSize: units.gu(1.5); anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }
            }

            Rectangle { width: parent.width; height: units.dp(1); color: "#2A2A2A" }

            // ---- Description ----
            Label {
                width: parent.width - units.gu(6)
                anchors.horizontalCenter: parent.horizontalCenter
                text: mangaDesc || "No description available."
                color: "#CCCCCC"
                wrapMode: Text.WordWrap
                font.pixelSize: units.gu(1.6)
                visible: mangaDesc !== ""
            }

            // ---- Genre Tags ----
            Flow {
                visible: mangaGenre !== ""
                width: parent.width - units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: units.gu(0.5)
                Repeater {
                    model: mangaGenre.split(", ").slice(0, 8)
                    Rectangle {
                        height: units.gu(2.8)
                        width: genreLabel.width + units.gu(2)
                        color: "#2A2A3E"
                        radius: units.dp(4)
                        Label { id: genreLabel; anchors.centerIn: parent; text: modelData; color: "#8888FF"; font.pixelSize: units.gu(1.4) }
                    }
                }
            }

            Rectangle { width: parent.width; height: units.dp(1); color: "#2A2A2A"; visible: mangaGenre !== "" }

            // ---- Chapters Header ----
            Item {
                width: parent.width
                height: units.gu(6)

                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                    text: isLoadingChapters ? "Loading chapters..." : (chapterModel.count + " Chapters")
                    color: "white"
                    font.bold: true
                    font.pixelSize: units.gu(1.9)
                }

                ActivityIndicator {
                    visible: isLoadingChapters
                    running: isLoadingChapters
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // ---- Chapter List ----
            Column {
                width: parent.width
                Repeater {
                    model: chapterModel

                    Item {
                        width: parent.width
                        height: units.gu(7)

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: units.gu(2)
                            anchors.rightMargin: units.gu(2)
                            spacing: units.gu(1)

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - units.gu(4)
                                spacing: units.dp(3)

                                Label {
                                    text: model.name || ("Chapter " + model.chapterNumber)
                                    color: model.isRead ? "#666666" : "white"
                                    font.pixelSize: units.gu(1.8)
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Label {
                                    text: {
                                        var parts = []
                                        if (model.scanlator) parts.push(model.scanlator)
                                        if (model.dateUpload > 0) {
                                            var d = new Date(model.dateUpload * 1000)
                                            parts.push(d.toLocaleDateString())
                                        }
                                        return parts.join(" • ")
                                    }
                                    color: "#666666"
                                    font.pixelSize: units.gu(1.4)
                                }
                            }
                        }

                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                // Rekam history jika tidak dalam mode penyamaran
                                if (!appSettings.incognitoMode) {
                                    db.upsertHistory(model.id, mangaId, model.name,
                                        model.chapterNumber, mangaTitle, mangaCover)
                                }
                                if (mainStack) {
                                    mainStack.push(Qt.resolvedUrl("ReaderPage.qml"), {
                                        chapterId: model.id,
                                        chapterTitle: model.name,
                                        mangaId: mangaId,
                                        mangaTitle: mangaTitle,
                                        mainStack: mainStack
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- KATEGORI LOGIC & DIALOG OVERLAY ----
    ListModel { id: categoryModel }
    property var selectedCatIds: []

    function loadCategories() {
        categoryModel.clear();
        var cats = db.getCategories();
        for (var i = 0; i < cats.length; i++) {
            categoryModel.append(cats[i]);
        }
        selectedCatIds = db.getMangaCategories(mangaId);
    }

    function isCatSelected(catId) {
        return selectedCatIds.indexOf(catId) !== -1;
    }

    function toggleCatSelection(catId) {
        var idx = selectedCatIds.indexOf(catId);
        if (idx === -1) {
            selectedCatIds.push(catId);
        } else {
            selectedCatIds.splice(idx, 1);
        }
        // Force evaluation
        selectedCatIds = selectedCatIds.slice();
    }

    Rectangle {
        id: categorySelectOverlay
        anchors.fill: parent
        color: "#AA000000"
        visible: false

        MouseArea { anchors.fill: parent } // Block clicks below

        Rectangle {
            width: parent.width - units.gu(6)
            height: units.gu(38)
            radius: units.dp(12)
            color: "#1E1E1E"
            border.color: "#2A2A2A"
            anchors.centerIn: parent

            Column {
                anchors.fill: parent
                anchors.margins: units.gu(2.5)
                spacing: units.gu(2)

                Label { text: "Set Categories"; font.bold: true; font.pixelSize: units.gu(2); color: "white" }

                // Categories list
                ListView {
                    width: parent.width
                    height: units.gu(18)
                    clip: true
                    model: categoryModel
                    Label {
                        visible: categoryModel.count === 0
                        text: "No categories created yet.\nGo to Library -> Settings to create one."
                        color: "#888888"
                        font.pixelSize: units.gu(1.5)
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                    }
                    delegate: Item {
                        width: parent.width
                        height: units.gu(5)

                        property bool isChecked: categorySelectOverlay.visible ? mangaDetailPage.isCatSelected(model.id) : false

                        Row {
                            anchors.fill: parent
                            spacing: units.gu(2)

                            Rectangle {
                                width: units.gu(2.5); height: units.gu(2.5); radius: units.dp(4)
                                color: isChecked ? "#1A3A6A" : "transparent"
                                border.color: isChecked ? "#4A90D9" : "#888888"
                                anchors.verticalCenter: parent.verticalCenter
                                Label { anchors.centerIn: parent; text: "✓"; color: "#4A90D9"; visible: isChecked; font.bold: true }
                            }

                            Label {
                                text: model.name || ""
                                color: "white"
                                font.pixelSize: units.gu(1.8)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                mangaDetailPage.toggleCatSelection(model.id);
                            }
                        }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#2A2A2A" }
                    }
                }

                // Action Buttons
                Row {
                    width: parent.width
                    height: units.gu(5)
                    spacing: units.gu(1.5)

                    // Remove / Cancel
                    Rectangle {
                        width: parent.width / 2 - units.gu(0.75)
                        height: parent.height
                        radius: units.dp(6)
                        color: "#3E2525"
                        Label { anchors.centerIn: parent; text: isFavorite ? "Remove" : "Cancel"; color: "#FF6B6B"; font.bold: true }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (isFavorite) {
                                    db.toggleFavorite(mangaId, false);
                                    isFavorite = false;
                                }
                                categorySelectOverlay.visible = false;
                            }
                        }
                    }

                    // Save Button
                    Rectangle {
                        width: parent.width / 2 - units.gu(0.75)
                        height: parent.height
                        radius: units.dp(6)
                        color: "#4A90D9"
                        Label { anchors.centerIn: parent; text: "Save"; color: "white"; font.bold: true }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                db.setMangaCategories(mangaId, mangaDetailPage.selectedCatIds);
                                isFavorite = true;
                                categorySelectOverlay.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
