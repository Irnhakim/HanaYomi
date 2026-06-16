import QtQuick 2.9
import Lomiri.Components 1.3
import Qt.labs.settings 1.0

// ReaderPage — terhubung ke C++ MangaDexSource untuk load gambar
Page {
    id: readerPage

    property var    mainStack: null
    property string chapterId: ""
    property string chapterTitle: "Chapter"
    property string mangaId: ""
    property string mangaTitle: ""

    property bool navVisible: false
    property bool isLoading: true
    property int  currentPage: 0
    property int  totalPages: 0
    property string readingMode: "webtoon"

    Settings {
        id: readerSettings
        category: "Reader"
        property string readingMode: "webtoon"
    }

    Component.onCompleted: {
        readingMode = readerSettings.readingMode
        if (chapterId !== "") {
            mangaDex.getPageList(chapterId)
        }
    }

    Rectangle { anchors.fill: parent; color: "#000000" }

    // Koneksikan ke sinyal C++
    Connections {
        target: mangaDex
        onPageListReady: {
            readerPage.isLoading = false
            pageModel.clear()
            for (var i = 0; i < pages.length; i++) {
                pageModel.append(pages[i])
            }
            readerPage.totalPages = pages.length
        }
        onNetworkError: {
            readerPage.isLoading = false
            console.log("Reader error:", message)
        }
    }



    // Tandai chapter sudah dibaca saat keluar
    Component.onDestruction: {
        if (chapterId !== "") {
            db.markChapterRead(chapterId, true, readerPage.currentPage)
        }
    }

    ListModel { id: pageModel }

    // Header (tersembunyi default)
    header: PageHeader {
        visible: readerPage.navVisible
        title: chapterTitle + " — " + mangaTitle
        StyleHints { foregroundColor: "white"; backgroundColor: "#000000CC"; dividerColor: "transparent" }
    }

    // Loading indicator
    Item {
        visible: isLoading
        anchors.fill: parent

        ActivityIndicator {
            running: true
            anchors.centerIn: parent
        }
        Label {
            text: "Loading chapter..."
            color: "#888888"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.verticalCenter
            anchors.topMargin: units.gu(4)
        }
    }

    // Page viewer — vertical/horizontal scroll
    ListView {
        id: pageListView
        visible: !isLoading
        anchors.fill: parent
        model: pageModel
        clip: true
        orientation: readerPage.readingMode === "webtoon" ? ListView.Vertical : ListView.Horizontal
        snapMode: readerPage.readingMode === "webtoon" ? ListView.NoSnap : ListView.SnapToItem

        onCurrentIndexChanged: {
            readerPage.currentPage = currentIndex
        }

        delegate: Item {
            width: pageListView.width
            height: pageListView.height

            Image {
                id: pageImage
                anchors.fill: parent
                source: model.imageUrl || ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                cache: true

                // Loading placeholder per halaman
                Rectangle {
                    visible: pageImage.status === Image.Loading
                    anchors.fill: parent
                    color: "#111111"
                    ActivityIndicator {
                        running: true
                        anchors.centerIn: parent
                    }
                    Label {
                        text: "Page " + (model.index + 1)
                        color: "#555555"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.verticalCenter
                        anchors.topMargin: units.gu(4)
                    }
                }
            }

            // Tap zones — kiri = prev, tengah = toggle nav, kanan = next
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var xRatio = mouse.x / width
                    if (xRatio < 0.25) {
                        // Previous page
                        if (pageListView.currentIndex > 0)
                            pageListView.currentIndex--
                    } else if (xRatio > 0.75) {
                        // Next page
                        if (pageListView.currentIndex < pageModel.count - 1)
                            pageListView.currentIndex++
                    } else {
                        // Toggle nav
                        readerPage.navVisible = !readerPage.navVisible
                    }
                }
            }
        }
    }

    // Bottom nav bar (page indicator + progress)
    Rectangle {
        visible: readerPage.navVisible && !isLoading
        anchors.bottom: parent.bottom
        width: parent.width
        height: units.gu(7)
        color: "#000000CC"

        Row {
            anchors.centerIn: parent
            spacing: units.gu(2)

            Icon {
                name: "settings"
                width: units.gu(3.5); height: units.gu(3.5)
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: settingsOverlay.visible = true
                }
            }

            Icon {
                name: "go-previous"
                width: units.gu(4); height: units.gu(4)
                color: pageListView.currentIndex > 0 ? "white" : "#444444"
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (pageListView.currentIndex > 0) pageListView.currentIndex--
                }
            }

            Label {
                text: (readerPage.currentPage + 1) + " / " + readerPage.totalPages
                color: "white"
                font.pixelSize: units.gu(2)
                anchors.verticalCenter: parent.verticalCenter
            }

            Icon {
                name: "go-next"
                width: units.gu(4); height: units.gu(4)
                color: pageListView.currentIndex < pageModel.count - 1 ? "white" : "#444444"
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (pageListView.currentIndex < pageModel.count - 1) pageListView.currentIndex++
                }
            }
        }
    }

    // ---- SETTINGS OVERLAY ----
    Rectangle {
        id: settingsOverlay
        anchors.fill: parent
        color: "#AA000000"
        visible: false

        MouseArea { anchors.fill: parent } // Block clicks below

        Rectangle {
            width: parent.width - units.gu(6)
            height: units.gu(18)
            radius: units.dp(12)
            color: "#1E1E1E"
            border.color: "#2A2A2A"
            anchors.centerIn: parent

            Column {
                anchors.fill: parent
                anchors.margins: units.gu(2)
                spacing: units.gu(2)

                Label { text: "Reader Settings"; font.bold: true; font.pixelSize: units.gu(2); color: "white" }

                // Reading Mode
                Row {
                    width: parent.width
                    spacing: units.gu(1.5)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        width: parent.width / 2 - units.gu(0.75)
                        height: units.gu(4.5)
                        radius: units.dp(6)
                        color: readerPage.readingMode === "webtoon" ? "#1A3A6A" : "#2D2D2D"
                        Label { anchors.centerIn: parent; text: "Webtoon (Vertical)"; color: readerPage.readingMode === "webtoon" ? "#4A90D9" : "white" }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                readerPage.readingMode = "webtoon";
                                readerSettings.readingMode = "webtoon";
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width / 2 - units.gu(0.75)
                        height: units.gu(4.5)
                        radius: units.dp(6)
                        color: readerPage.readingMode === "pager" ? "#1A3A6A" : "#2D2D2D"
                        Label { anchors.centerIn: parent; text: "Pager (Horizontal)"; color: readerPage.readingMode === "pager" ? "#4A90D9" : "white" }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                readerPage.readingMode = "pager";
                                readerSettings.readingMode = "pager";
                            }
                        }
                    }
                }

                // Done Button
                Rectangle {
                    width: parent.width; height: units.gu(4.5); radius: units.dp(6); color: "#4A90D9"
                    Label { anchors.centerIn: parent; text: "Close"; color: "white"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: settingsOverlay.visible = false
                    }
                }
            }
        }
    }
}
