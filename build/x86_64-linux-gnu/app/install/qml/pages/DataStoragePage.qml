import QtQuick 2.9
import Lomiri.Components 1.3

Page {
    id: dataStoragePage

    Rectangle { anchors.fill: parent; color: "#111111" }

    header: PageHeader {
        title: "Data and Storage"
        StyleHints { foregroundColor: "white"; backgroundColor: "#1A1A1A"; dividerColor: "#2A2A2A" }
    }

    Timer {
        id: statusTimer
        interval: 2000
        repeat: false
        onTriggered: statusLabel.text = ""
    }

    function showStatus(msg) {
        statusLabel.text = msg;
        statusTimer.restart();
    }

    Column {
        anchors.fill: parent
        anchors.topMargin: parent.header.height + units.gu(2)
        spacing: units.gu(1)

        // Transient status indicator
        Label {
            id: statusLabel
            text: ""
            color: "#4A90D9"
            font.bold: true
            font.pixelSize: units.gu(1.8)
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
            height: text !== "" ? units.gu(4) : 0
            Behavior on height { NumberAnimation { duration: 150 } }
        }

        // Cache Option Card
        Item {
            width: parent.width
            height: units.gu(8.5)
            Row {
                anchors.fill: parent
                anchors.leftMargin: units.gu(2)
                anchors.rightMargin: units.gu(2)
                spacing: units.gu(2)

                Icon { name: "folder"; width: units.gu(3); height: units.gu(3); color: "#888888"; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    width: parent.width - units.gu(3) - units.gu(2) - units.gu(10)
                    anchors.verticalCenter: parent.verticalCenter
                    Label { text: "Clear Cache"; color: "white"; font.pixelSize: units.gu(1.9); font.bold: true }
                    Label { text: "Frees up temporary storage space"; color: "#888888"; font.pixelSize: units.gu(1.5) }
                }
                Rectangle {
                    width: units.gu(8)
                    height: units.gu(4)
                    color: "#222222"
                    radius: units.dp(4)
                    anchors.verticalCenter: parent.verticalCenter
                    border.color: "#333333"
                    Label { anchors.centerIn: parent; text: "Clear"; color: "#FF6B6B"; font.bold: true; font.pixelSize: units.gu(1.4) }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            db.clearAllCache();
                            dataStoragePage.showStatus("Cache Cleared!");
                        }
                    }
                }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }
        }

        // History Option Card
        Item {
            width: parent.width
            height: units.gu(8.5)
            Row {
                anchors.fill: parent
                anchors.leftMargin: units.gu(2)
                anchors.rightMargin: units.gu(2)
                spacing: units.gu(2)

                Icon { name: "delete"; width: units.gu(3); height: units.gu(3); color: "#888888"; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    width: parent.width - units.gu(3) - units.gu(2) - units.gu(10)
                    anchors.verticalCenter: parent.verticalCenter
                    Label { text: "Clear History"; color: "white"; font.pixelSize: units.gu(1.9); font.bold: true }
                    Label { text: "Deletes reading progress and entries"; color: "#888888"; font.pixelSize: units.gu(1.5) }
                }
                Rectangle {
                    width: units.gu(8)
                    height: units.gu(4)
                    color: "#3E2525"
                    radius: units.dp(4)
                    anchors.verticalCenter: parent.verticalCenter
                    Label { anchors.centerIn: parent; text: "Reset"; color: "#FF6B6B"; font.bold: true; font.pixelSize: units.gu(1.4) }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            db.clearHistory();
                            dataStoragePage.showStatus("History Cleared!");
                        }
                    }
                }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }
        }

        // Backup Options
        Item {
            width: parent.width
            height: units.gu(8.5)
            Row {
                anchors.fill: parent
                anchors.leftMargin: units.gu(2)
                anchors.rightMargin: units.gu(2)
                spacing: units.gu(2)

                Icon { name: "save"; width: units.gu(3); height: units.gu(3); color: "#888888"; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    width: parent.width - units.gu(3) - units.gu(2) - units.gu(10)
                    anchors.verticalCenter: parent.verticalCenter
                    Label { text: "Database Backups"; color: "white"; font.pixelSize: units.gu(1.9); font.bold: true }
                    Label { text: "Create or restore local data backups"; color: "#888888"; font.pixelSize: units.gu(1.5) }
                }
                Rectangle {
                    width: units.gu(8)
                    height: units.gu(4)
                    color: "#1A3A6A"
                    radius: units.dp(4)
                    anchors.verticalCenter: parent.verticalCenter
                    Label { anchors.centerIn: parent; text: "Backup"; color: "#4A90D9"; font.bold: true; font.pixelSize: units.gu(1.4) }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            dataStoragePage.showStatus("Backup Created in .local/share!");
                        }
                    }
                }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }
        }
    }
}
