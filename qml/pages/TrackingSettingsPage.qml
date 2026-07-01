import QtQuick 2.9
import Lomiri.Components 1.3

Page {
    id: trackingSettingsPage

    Rectangle { anchors.fill: parent; color: "#111111" }

    header: PageHeader {
        title: "Tracking"
        StyleHints { foregroundColor: "white"; backgroundColor: "#1A1A1A"; dividerColor: "#2A2A2A" }
    }

    Flickable {
        anchors.top: parent.header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        contentHeight: contentCol.height + units.gu(4)
        clip: true

        Column {
            id: contentCol
            width: parent.width
            spacing: 0

            // Toggle 1: Update progress after reading
            Item {
                width: parent.width
                height: units.gu(8)
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(2)
                    anchors.rightMargin: units.gu(2)
                    spacing: units.gu(2)

                    Column {
                        width: parent.width - units.gu(6) - units.gu(2)
                        anchors.verticalCenter: parent.verticalCenter
                        Label { text: "Update progress after reading"; color: "white"; font.pixelSize: units.gu(1.8) }
                    }
                    Switch {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: appSettings.trackUpdateAfterReading
                        onCheckedChanged: appSettings.trackUpdateAfterReading = checked
                    }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }
            }

            // Toggle 2: Update progress after manually marking as read
            Item {
                width: parent.width
                height: units.gu(10)
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(2)
                    anchors.rightMargin: units.gu(2)
                    spacing: units.gu(2)

                    Column {
                        width: parent.width - units.gu(6) - units.gu(2)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: units.dp(2)
                        Label { text: "Update progress after manually marking as read"; color: "white"; font.pixelSize: units.gu(1.8) }
                        Label { text: "Does not work when marking multiple manga as read at once"; color: "#888888"; font.pixelSize: units.gu(1.4); wrapMode: Text.Wrap }
                    }
                    Switch {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: appSettings.trackUpdateAfterMarkAsRead
                        onCheckedChanged: appSettings.trackUpdateAfterMarkAsRead = checked
                    }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }
            }

            // Header Section: Trackers
            Item {
                width: parent.width
                height: units.gu(5)
                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Trackers"
                    color: "#00bfa5"
                    font.bold: true
                    font.pixelSize: units.gu(1.6)
                }
            }

            // Trackers List
            Repeater {
                model: [
                    { name: "MyAnimeList",  color: "#2E51A2", textLogo: "MAL" },
                    { name: "AniList",       color: "#0B1622", textLogo: "AL" },
                    { name: "Kitsu",         color: "#FD5C63", textLogo: "Kitsu" },
                    { name: "MangaUpdates",  color: "#1F4275", textLogo: "MU" },
                    { name: "Shikimori",     color: "#212121", textLogo: "Shiki" },
                    { name: "Bangumi",       color: "#F09199", textLogo: "BGM" }
                ]

                delegate: Item {
                    width: parent.width
                    height: units.gu(9)

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: units.gu(2)
                        anchors.rightMargin: units.gu(2)
                        spacing: units.gu(2.5)

                        // Custom Premium Tracker Logo Box
                        Rectangle {
                            width: units.gu(6.5)
                            height: units.gu(6.5)
                            color: modelData.color
                            radius: units.dp(8)
                            anchors.verticalCenter: parent.verticalCenter
                            clip: true

                            Label {
                                anchors.centerIn: parent
                                text: modelData.name === "AniList" ? "A" : (modelData.name === "Kitsu" ? "🦊" : (modelData.name === "Shikimori" ? "示" : modelData.textLogo))
                                color: "white"
                                font.bold: true
                                font.pixelSize: modelData.name === "Kitsu" || modelData.name === "Shikimori" ? units.gu(3) : units.gu(2.2)
                            }
                        }

                        Label {
                            text: modelData.name
                            color: "white"
                            font.pixelSize: units.gu(1.9)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            // Handler login / integration tracking
                        }
                    }
                }
            }
        }
    }
}
