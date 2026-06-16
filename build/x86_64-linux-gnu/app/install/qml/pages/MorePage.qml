import QtQuick 2.9
import Lomiri.Components 1.3

// More page — Mihon style: logo + toggles + menu list
Page {
    id: morePage
    property var mainStack: null

    Rectangle { anchors.fill: parent; color: "#111111" }

    header: PageHeader {
        title: ""
        StyleHints { foregroundColor: "white"; backgroundColor: "#111111"; dividerColor: "#111111" }
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

            // Logo section
            Item {
                width: parent.width
                height: units.gu(18)

                Column {
                    anchors.centerIn: parent
                    spacing: units.gu(1)

                    Image {
                        source: "../assets/icon.svg"
                        width: units.gu(9)
                        height: units.gu(9)
                        fillMode: Image.PreserveAspectFit
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        text: "HanaYomi"
                        font.pixelSize: units.gu(2.2)
                        color: "white"
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // Divider
            Rectangle { width: parent.width; height: units.dp(1); color: "#2A2A2A" }

            // Toggles section
            Column {
                width: parent.width

                // Downloaded Only Toggle
                Item {
                    width: parent.width
                    height: units.gu(8)
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: units.gu(2)
                        anchors.rightMargin: units.gu(2)
                        spacing: units.gu(2)

                        Icon { name: "save"; width: units.gu(3); height: units.gu(3); color: "#888888"; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            width: parent.width - units.gu(3) - units.gu(2) - units.gu(6)
                            anchors.verticalCenter: parent.verticalCenter
                            Label { text: "Downloaded only"; color: "white"; font.pixelSize: units.gu(1.9) }
                            Label { text: "Filters all entries in your library"; color: "#888888"; font.pixelSize: units.gu(1.5) }
                        }
                        Switch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: false
                        }
                    }
                }
                Rectangle { width: parent.width; height: units.dp(1); color: "#1E1E1E" }

                // Incognito mode Toggle
                Item {
                    width: parent.width
                    height: units.gu(8)
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: units.gu(2)
                        anchors.rightMargin: units.gu(2)
                        spacing: units.gu(2)

                        Icon { name: "private-browsing"; width: units.gu(3); height: units.gu(3); color: "#888888"; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            width: parent.width - units.gu(3) - units.gu(2) - units.gu(6)
                            anchors.verticalCenter: parent.verticalCenter
                            Label { text: "Incognito mode"; color: "white"; font.pixelSize: units.gu(1.9) }
                            Label { text: "Pauses reading history"; color: "#888888"; font.pixelSize: units.gu(1.5) }
                        }
                        Switch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: false
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: units.dp(1); color: "#2A2A2A" }

            // Menu items
            Column {
                width: parent.width

                Repeater {
                    model: [
                        { label: "Download queue",  icon: "save"     },
                        { label: "Categories",       icon: "tag"      },
                        { label: "Statistics",       icon: "stock_sms"},
                        { label: "Data and storage", icon: "storage"  }
                    ]
                    Item {
                        width: parent.width
                        height: units.gu(7)
                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: units.gu(2)
                            spacing: units.gu(2)
                            Icon { name: modelData.icon; width: units.gu(3); height: units.gu(3); color: "#888888"; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: modelData.label; color: "white"; font.pixelSize: units.gu(1.9); anchors.verticalCenter: parent.verticalCenter }
                        }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }
                        MouseArea { anchors.fill: parent }
                    }
                }
            }

            Rectangle { width: parent.width; height: units.dp(1); color: "#2A2A2A" }

            Column {
                width: parent.width
                Repeater {
                    model: [
                        { label: "Settings",    icon: "settings" },
                        { label: "Support Us",  icon: "like"     },
                        { label: "About",       icon: "info"     },
                        { label: "Help",        icon: "help"     }
                    ]
                    Item {
                        width: parent.width
                        height: units.gu(7)
                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: units.gu(2)
                            spacing: units.gu(2)
                            Icon { name: modelData.icon; width: units.gu(3); height: units.gu(3); color: "#888888"; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: modelData.label; color: "white"; font.pixelSize: units.gu(1.9); anchors.verticalCenter: parent.verticalCenter }
                        }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }
                        MouseArea { anchors.fill: parent }
                    }
                }
            }
        }
    }
}
