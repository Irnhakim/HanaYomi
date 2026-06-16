import QtQuick 2.9
import Lomiri.Components 1.3

Page {
    id: updatesPage
    property var mainStack: null

    Rectangle { anchors.fill: parent; color: "#111111" }

    Connections {
        target: db
        onLibraryChanged: updatesPage.reloadUpdates()
    }

    ListModel { id: updatesModel }

    function reloadUpdates() {
        updatesModel.clear()
        var entries = db.getUpdates()
        var currentDate = ""
        for (var i = 0; i < entries.length; i++) {
            var e = entries[i]
            var d = new Date(e.dateFetch * 1000)
            var dateStr = d.toLocaleDateString()
            if (dateStr !== currentDate) {
                updatesModel.append({ isHeader: true, dateLabel: dateStr, mangaTitle: "", chapterName: "", thumbnailUrl: "", chapterId: "", mangaId: "", isRead: false })
                currentDate = dateStr
            }
            updatesModel.append({
                isHeader: false, dateLabel: "",
                mangaTitle: e.mangaTitle, chapterName: e.chapterName,
                thumbnailUrl: e.thumbnailUrl, chapterId: e.chapterId,
                mangaId: e.mangaId, isRead: e.isRead
            })
        }
    }

    Component.onCompleted: reloadUpdates()

    header: PageHeader {
        title: "Updates"
        StyleHints { foregroundColor: "white"; backgroundColor: "#111111"; dividerColor: "#2A2A2A" }
        trailingActionBar.actions: [
            Action { iconName: "sort-listview"; text: "Filter" },
            Action { iconName: "reload"; text: "Refresh" }
        ]
    }

    Column {
        visible: updatesModel.count === 0
        anchors.centerIn: parent
        spacing: units.gu(2)
        Label { text: "No updates yet"; color: "#555555"; font.pixelSize: units.gu(2); anchors.horizontalCenter: parent.horizontalCenter }
        Label { text: "Add manga to your library to see updates here"; color: "#444444"; font.pixelSize: units.gu(1.6); anchors.horizontalCenter: parent.horizontalCenter }
    }

    ListView {
        anchors.top: parent.header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        model: updatesModel
        clip: true

        delegate: Loader {
            width: parent.width
            sourceComponent: model.isHeader ? dateHeaderComp : updateItemComp

            Component {
                id: dateHeaderComp
                Item {
                    width: parent ? parent.width : 0; height: units.gu(4)
                    Label { anchors.left: parent.left; anchors.leftMargin: units.gu(2); anchors.verticalCenter: parent.verticalCenter; text: model.dateLabel; color: "white"; font.bold: true; font.pixelSize: units.gu(1.8) }
                }
            }

            Component {
                id: updateItemComp
                Item {
                    width: parent ? parent.width : 0; height: units.gu(8)

                    Row {
                        anchors.fill: parent; anchors.leftMargin: units.gu(2); anchors.rightMargin: units.gu(2); spacing: units.gu(1.5)

                        Rectangle {
                            width: units.gu(6); height: units.gu(7); anchors.verticalCenter: parent.verticalCenter
                            color: "#2A2A2A"; radius: units.dp(4); clip: true
                            Image { anchors.fill: parent; source: model.thumbnailUrl || ""; fillMode: Image.PreserveAspectCrop }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - units.gu(6) - units.gu(5) - units.gu(3)
                            spacing: units.dp(4)
                            Label { text: model.mangaTitle || ""; color: model.isRead ? "#888888" : "white"; font.pixelSize: units.gu(1.9); elide: Text.ElideRight; width: parent.width }
                            Row {
                                spacing: units.gu(0.8)
                                Rectangle { visible: !model.isRead; width: units.gu(1); height: units.gu(1); radius: width/2; color: "#4A90D9"; anchors.verticalCenter: parent.verticalCenter }
                                Label { text: model.chapterName || ""; color: "#888888"; font.pixelSize: units.gu(1.6) }
                            }
                        }

                        Item {
                            width: units.gu(5); height: units.gu(5); anchors.verticalCenter: parent.verticalCenter
                            Rectangle { anchors.fill: parent; anchors.margins: units.gu(0.5); radius: width/2; color: "transparent"; border.color: "#555555"; border.width: units.dp(1.5)
                                Icon { name: model.isRead ? "tick" : "save"; width: units.gu(2.5); height: units.gu(2.5); color: "#888888"; anchors.centerIn: parent }
                            }
                        }
                    }

                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }
                }
            }
        }
    }
}
