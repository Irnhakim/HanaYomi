import QtQuick 2.9
import Lomiri.Components 1.3

Page {
    id: settingsPage

    Rectangle { anchors.fill: parent; color: "#111111" }

    header: PageHeader {
        title: "Settings"
        StyleHints { foregroundColor: "white"; backgroundColor: "#1A1A1A"; dividerColor: "#2A2A2A" }
    }

    Column {
        anchors.fill: parent
        anchors.topMargin: parent.header.height + units.gu(1)
        spacing: 0

        Repeater {
            model: [
                { label: "General",       icon: "settings",     page: "" },
                { label: "Library",       icon: "tag",          page: "" },
                { label: "Reader",        icon: "stock_website",page: "" },
                { label: "Downloads",     icon: "save",         page: "" },
                { label: "Tracking",      icon: "bookmark",     page: "TrackingSettingsPage.qml" },
                { label: "Advanced",      icon: "developer-info",page: "" }
            ]

            delegate: Item {
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
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (modelData.page !== "") {
                            settingsPage.pageStack.push(Qt.resolvedUrl(modelData.page))
                        }
                    }
                }
            }
        }
    }
}
