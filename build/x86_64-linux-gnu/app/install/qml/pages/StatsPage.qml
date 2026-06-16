import QtQuick 2.9
import Lomiri.Components 1.3

Page {
    id: statsPage

    Rectangle { anchors.fill: parent; color: "#111111" }

    header: PageHeader {
        title: "Statistics"
        StyleHints { foregroundColor: "white"; backgroundColor: "#1A1A1A"; dividerColor: "#2A2A2A" }
    }

    ListModel { id: genreModel }

    property int libCount: 0
    property int readCount: 0

    function loadStats() {
        libCount = db.getLibraryCount();
        readCount = db.getReadChaptersCount();
        
        genreModel.clear();
        var genres = db.getGenreStats();
        for (var i = 0; i < genres.length; i++) {
            genreModel.append(genres[i]);
        }
    }

    Component.onCompleted: {
        loadStats();
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: parent.header.height + units.gu(2)
        contentHeight: statsCol.height + units.gu(4)
        clip: true

        Column {
            id: statsCol
            width: parent.width - units.gu(4)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(3)

            // ---- Overview Cards ----
            Row {
                width: parent.width
                height: units.gu(12)
                spacing: units.gu(2)

                // Card 1: Library Count
                Rectangle {
                    width: parent.width / 2 - units.gu(1)
                    height: parent.height
                    color: "#1E1E1E"
                    radius: units.dp(10)
                    border.color: "#2A2A2A"

                    Column {
                        anchors.centerIn: parent
                        spacing: units.dp(4)
                        Label {
                            text: statsPage.libCount.toString()
                            font.pixelSize: units.gu(4.5)
                            font.bold: true
                            color: "#4A90D9"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Label {
                            text: "In Library"
                            font.pixelSize: units.gu(1.6)
                            color: "#888888"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                // Card 2: Read Chapters
                Rectangle {
                    width: parent.width / 2 - units.gu(1)
                    height: parent.height
                    color: "#1E1E1E"
                    radius: units.dp(10)
                    border.color: "#2A2A2A"

                    Column {
                        anchors.centerIn: parent
                        spacing: units.dp(4)
                        Label {
                            text: statsPage.readCount.toString()
                            font.pixelSize: units.gu(4.5)
                            font.bold: true
                            color: "#2E7D32"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Label {
                            text: "Chapters Read"
                            font.pixelSize: units.gu(1.6)
                            color: "#888888"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            // ---- Top Genres Section ----
            Column {
                width: parent.width
                spacing: units.gu(1.5)

                Label {
                    text: "Top Genres"
                    font.bold: true
                    font.pixelSize: units.gu(2.2)
                    color: "white"
                }

                Rectangle {
                    width: parent.width
                    height: Math.max(units.gu(10), genreCol.height + units.gu(2))
                    color: "#1E1E1E"
                    radius: units.dp(10)
                    border.color: "#2A2A2A"
                    clip: true

                    Label {
                        visible: genreModel.count === 0
                        text: "Add manga to library with genres\nto generate statistics."
                        color: "#666666"
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: units.gu(1.6)
                    }

                    Column {
                        id: genreCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: units.gu(2)
                        spacing: units.gu(1.5)

                        Repeater {
                            model: genreModel
                            delegate: Item {
                                width: parent.width
                                height: units.gu(4.5)

                                Column {
                                    anchors.fill: parent
                                    spacing: units.dp(4)

                                    Row {
                                        width: parent.width
                                        Label { text: model.genre; color: "white"; font.pixelSize: units.gu(1.6) }
                                        Item { width: parent.width - parent.children[0].width - parent.children[2].width; height: 1 }
                                        Label { text: model.count.toString() + " manga"; color: "#888888"; font.pixelSize: units.gu(1.5) }
                                    }

                                    // Custom visual bar chart representation
                                    Rectangle {
                                        width: parent.width
                                        height: units.dp(6)
                                        color: "#2A2A2A"
                                        radius: height / 2

                                        Rectangle {
                                            // Scale width based on ratio of count relative to first (maximum) count item
                                            width: parent.width * (model.count / genreModel.get(0).count)
                                            height: parent.height
                                            color: "#1A3A6A"
                                            radius: height / 2
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
