import QtQuick 2.9
import Lomiri.Components 1.3
import Qt.labs.settings 1.0
import "pages"

MainView {
    id: root
    objectName: "mainView"
    applicationName: "hanayomi.hakim"
    automaticOrientation: true
    visible: true

    Settings {
        id: appSettings
        category: "General"
        property bool incognitoMode: false
        property bool downloadedOnly: false
        property bool nsfwEnabled: false
        property bool trackUpdateAfterReading: true
        property bool trackUpdateAfterMarkAsRead: true
    }

    width: units.gu(50)
    height: units.gu(80)

    // Global dark background
    backgroundColor: "#111111"

    PageStack {
        id: mainPageStack
        Component.onCompleted: push(mainBaseComponent)
    }

    Component {
        id: mainBaseComponent
        Page {
            id: basePage
            head.visible: false

            // Dark background
            Rectangle {
                anchors.fill: parent
                color: "#111111"
            }

            // Content area
            Loader {
                id: contentLoader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: bottomNav.top
            }

            // Bottom Navigation Bar — Mihon style
            Rectangle {
                id: bottomNav
                anchors.bottom: parent.bottom
                width: parent.width
                height: units.gu(7)
                color: "#1A1A1A"

                // Top border line
                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: units.dp(1)
                    color: "#2A2A2A"
                }

                Row {
                    anchors.fill: parent

                    Repeater {
                        id: navRepeater
                        property int currentIndex: 0
                        model: [
                            { label: "Library",  icon: "bookmark-new",       comp: libComp     },
                            { label: "Updates",  icon: "clock",              comp: updatesComp },
                            { label: "History",  icon: "media-seek-backward",comp: historyComp },
                            { label: "Browse",   icon: "search",             comp: browseComp  },
                            { label: "More",     icon: "contextual-menu",    comp: moreComp    }
                        ]

                        Item {
                            id: navItem
                            width: parent.width / 5
                            height: parent.height

                            property bool isSelected: navRepeater.currentIndex === index

                            // Blue oval background for selected item (Mihon style)
                            Rectangle {
                                visible: isSelected
                                anchors.top: parent.top
                                anchors.topMargin: units.gu(0.5)
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: units.gu(8)
                                height: units.gu(3.2)
                                radius: height / 2
                                color: "#2600bfa5"
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            Column {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: units.gu(0.3)
                                spacing: units.dp(2)

                                Icon {
                                    name: modelData.icon
                                    width: units.gu(2.8)
                                    height: units.gu(2.8)
                                    color: isSelected ? "#00bfa5" : "#888888"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                Label {
                                    text: modelData.label
                                    color: isSelected ? "#00bfa5" : "#888888"
                                    font.pixelSize: units.gu(1.2)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    navRepeater.currentIndex = index
                                    contentLoader.sourceComponent = modelData.comp
                                }
                            }
                        }
                    }
                }
            }

            // Page components — pass mainStack for navigation
            Component { id: libComp;      LibraryPage  { mainStack: mainPageStack } }
            Component { id: updatesComp;  UpdatesPage  { mainStack: mainPageStack } }
            Component { id: historyComp;  HistoryPage  { mainStack: mainPageStack } }
            Component { id: browseComp;   BrowsePage   { mainStack: mainPageStack } }
            Component { id: moreComp;     MorePage     { mainStack: mainPageStack } }

            Component.onCompleted: {
                suwayomiRunner.start()
                contentLoader.sourceComponent = libComp
            }
        }
    }
}
