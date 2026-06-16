import QtQuick 2.9
import Lomiri.Components 1.3

Page {
    id: historyPage
    property var mainStack: null

    Rectangle { anchors.fill: parent; color: "#111111" }

    Connections {
        target: db
        onHistoryChanged: historyPage.reloadHistory()
    }

    ListModel { id: historyModel }

    function reloadHistory() {
        historyModel.clear()
        var entries = db.getHistory()
        var currentDate = ""
        for (var i = 0; i < entries.length; i++) {
            var e = entries[i]
            var d = new Date(e.readAt * 1000)
            var dateStr = d.toLocaleDateString()
            if (dateStr !== currentDate) {
                historyModel.append({ isHeader: true, dateLabel: dateStr, mangaTitle: "", chapterName: "", thumbnailUrl: "", id: "", mangaId: "", chapterNumber: 0, readAt: 0 })
                currentDate = dateStr
            }
            historyModel.append({
                isHeader: false,
                dateLabel: "",
                id: e.id,
                mangaId: e.mangaId,
                mangaTitle: e.mangaTitle,
                chapterName: e.chapterName,
                chapterNumber: e.chapterNumber,
                thumbnailUrl: e.thumbnailUrl,
                readAt: e.readAt
            })
        }
    }

    Component.onCompleted: reloadHistory()

    header: PageHeader {
        title: "History"
        StyleHints { foregroundColor: "white"; backgroundColor: "#111111"; dividerColor: "#2A2A2A" }
        trailingActionBar.actions: [
            Action { iconName: "search"; text: "Search" },
            Action { iconName: "delete"; text: "Clear All" }
        ]
    }

    // Empty state
    Column {
        visible: historyModel.count === 0
        anchors.centerIn: parent
        spacing: units.gu(2)
        Label { text: "No reading history yet"; color: "#555555"; font.pixelSize: units.gu(2); anchors.horizontalCenter: parent.horizontalCenter }
    }

    ListView {
        anchors.top: parent.header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        model: historyModel
        clip: true

        delegate: Loader {
            width: parent.width
            sourceComponent: model.isHeader ? dateHeaderComp : historyItemComp

            Component {
                id: dateHeaderComp
                Item {
                    width: parent ? parent.width : 0
                    height: units.gu(4)
                    Label { anchors.left: parent.left; anchors.leftMargin: units.gu(2); anchors.verticalCenter: parent.verticalCenter; text: model.dateLabel; color: "white"; font.bold: true; font.pixelSize: units.gu(1.8) }
                }
            }

            Component {
                id: historyItemComp
                Item {
                    width: parent ? parent.width : 0
                    height: units.gu(9)

                    Row {
                        anchors.fill: parent; anchors.leftMargin: units.gu(2); anchors.rightMargin: units.gu(1); spacing: units.gu(1.5)

                        Rectangle {
                            width: units.gu(7); height: units.gu(8); anchors.verticalCenter: parent.verticalCenter
                            color: "#2A2A2A"; radius: units.dp(4); clip: true
                            Image { anchors.fill: parent; source: model.thumbnailUrl || ""; fillMode: Image.PreserveAspectCrop }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - units.gu(7) - units.gu(10) - units.gu(2.5)
                            spacing: units.dp(6)
                            Label { text: model.mangaTitle || ""; color: "white"; font.pixelSize: units.gu(1.9); elide: Text.ElideRight; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2 }
                            Label { text: model.chapterName || "Ch. " + model.chapterNumber; color: "#888888"; font.pixelSize: units.gu(1.5) }
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter; spacing: units.gu(1)
                            Icon { name: "like"; width: units.gu(3); height: units.gu(3); color: "#888888" }
                            Icon { name: "delete"; width: units.gu(3); height: units.gu(3); color: "#888888"
                                MouseArea { anchors.fill: parent; onClicked: db.removeHistory(model.id) }
                            }
                        }
                    }

                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }
                }
            }
        }
    }
}
