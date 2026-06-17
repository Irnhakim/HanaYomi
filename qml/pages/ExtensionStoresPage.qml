import QtQuick 2.9
import Lomiri.Components 1.3
import Qt.labs.settings 1.0

// Extension Stores page — ported from Mihon
// User can add/remove extension repository URLs manually
Page {
    id: extStoresPage

    Settings {
        id: repoSettings
        category: "ExtensionRepos"
        property string repos: "[]"
    }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------
    function getRepos() {
        try { return JSON.parse(repoSettings.repos); } catch(e) { return []; }
    }

    function saveRepos(arr) {
        repoSettings.repos = JSON.stringify(arr);
        reposModel.reload();
    }

    function addRepo(name, url) {
        var arr = getRepos();
        // Prevent duplicates by URL
        for (var i = 0; i < arr.length; i++) {
            if (arr[i].url === url) return false;
        }
        arr.push({ name: name, url: url });
        saveRepos(arr);
        return true;
    }

    function removeRepo(index) {
        var arr = getRepos();
        arr.splice(index, 1);
        saveRepos(arr);
    }

    // -----------------------------------------------------------------------
    // Model
    // -----------------------------------------------------------------------
    ListModel {
        id: reposModel

        function reload() {
            clear();
            var arr = extStoresPage.getRepos();
            for (var i = 0; i < arr.length; i++) {
                append({ name: arr[i].name, url: arr[i].url });
            }
        }

        Component.onCompleted: reload()
    }

    // -----------------------------------------------------------------------
    // Background
    // -----------------------------------------------------------------------
    Rectangle { anchors.fill: parent; color: "#111111" }

    // -----------------------------------------------------------------------
    // Header
    // -----------------------------------------------------------------------
    header: PageHeader {
        title: "Extension stores"
        StyleHints { foregroundColor: "white"; backgroundColor: "#111111"; dividerColor: "#2A2A2A" }

        trailingActionBar.actions: [
            Action {
                iconName: "reload"
                text: "Refresh"
                onTriggered: reposModel.reload()
            }
        ]
    }

    // -----------------------------------------------------------------------
    // Body
    // -----------------------------------------------------------------------
    Item {
        anchors.top: parent.header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: addButton.top
        anchors.bottomMargin: units.gu(1)

        // Empty state
        Column {
            visible: reposModel.count === 0
            anchors.centerIn: parent
            spacing: units.gu(1.5)

            Icon {
                name: "stock_website"
                width: units.gu(6); height: units.gu(6)
                color: "#444444"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Label {
                text: "No extension stores added"
                color: "#888888"
                font.pixelSize: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Label {
                text: "Tap \"+  Add\" to add a repository"
                color: "#555555"
                font.pixelSize: units.gu(1.6)
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Repo list
        ListView {
            anchors.fill: parent
            model: reposModel
            clip: true
            spacing: units.gu(1)

            contentItem.anchors.topMargin: units.gu(1.5)

            delegate: Rectangle {
                width: parent.width - units.gu(4)
                height: units.gu(10)
                anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                color: "#1A1A1A"
                border.color: "#2A2A2A"
                radius: units.dp(10)

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(1.5)
                    anchors.rightMargin: units.gu(1)
                    anchors.topMargin: units.gu(1)
                    anchors.bottomMargin: units.gu(1)
                    spacing: units.gu(1)

                    // Folder icon
                    Icon {
                        name: "stock_folder"
                        width: units.gu(3); height: units.gu(3)
                        color: "#888888"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Name & URL
                    Column {
                        width: parent.width - units.gu(3) - units.gu(12) - units.gu(3)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: units.dp(4)

                        Label {
                            text: model.name
                            color: "white"
                            font.pixelSize: units.gu(1.9)
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        Label {
                            text: model.url
                            color: "#888888"
                            font.pixelSize: units.gu(1.3)
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    // Action buttons: open in browser, copy URL, delete
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: units.gu(0.5)

                        // Open website
                        Rectangle {
                            width: units.gu(4); height: units.gu(4)
                            radius: units.gu(2)
                            color: "transparent"
                            Icon { name: "external-link"; width: units.gu(2.4); height: units.gu(2.4); color: "#888888"; anchors.centerIn: parent }
                            MouseArea { anchors.fill: parent; onClicked: Qt.openUrlExternally(model.url) }
                        }

                        // Copy URL
                        Rectangle {
                            width: units.gu(4); height: units.gu(4)
                            radius: units.gu(2)
                            color: "transparent"
                            Icon { name: "edit-copy"; width: units.gu(2.4); height: units.gu(2.4); color: "#888888"; anchors.centerIn: parent }
                            MouseArea { anchors.fill: parent; onClicked: { Clipboard.push(model.url); copyToast.show() } }
                        }

                        // Delete
                        Rectangle {
                            width: units.gu(4); height: units.gu(4)
                            radius: units.gu(2)
                            color: "transparent"
                            Icon { name: "delete"; width: units.gu(2.4); height: units.gu(2.4); color: "#FF6B6B"; anchors.centerIn: parent }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    deleteConfirmIndex = model.index
                                    deleteConfirmDialog.visible = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // -----------------------------------------------------------------------
    // + Add button (bottom right)
    // -----------------------------------------------------------------------
    property int deleteConfirmIndex: -1

    Rectangle {
        id: addButton
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: units.gu(3)
        anchors.rightMargin: units.gu(2.5)
        width: units.gu(15)
        height: units.gu(5.5)
        radius: units.dp(28)
        color: "#4A90D9"

        Row {
            anchors.centerIn: parent
            spacing: units.gu(0.8)
            Icon { name: "add"; width: units.gu(2.5); height: units.gu(2.5); color: "white"; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "Add"; color: "white"; font.bold: true; font.pixelSize: units.gu(2); anchors.verticalCenter: parent.verticalCenter }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: addDialog.visible = true
        }
    }

    // -----------------------------------------------------------------------
    // Add dialog
    // -----------------------------------------------------------------------
    Rectangle {
        id: addDialog
        visible: false
        anchors.fill: parent
        color: "#BB000000"
        z: 100

        MouseArea { anchors.fill: parent; onClicked: addDialog.visible = false }

        Rectangle {
            width: parent.width - units.gu(6)
            height: dialogColumn.height + units.gu(5)
            anchors.centerIn: parent
            color: "#1E1E1E"
            border.color: "#2A2A2A"
            radius: units.dp(12)

            MouseArea { anchors.fill: parent } // Block through-click

            Column {
                id: dialogColumn
                width: parent.width - units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: units.gu(2.5)
                spacing: units.gu(1.5)

                Label {
                    text: "Add extension store"
                    color: "white"
                    font.bold: true
                    font.pixelSize: units.gu(2.1)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    text: "Enter the URL of the extension repository index file\n(e.g. https://raw.githubusercontent.com/…/index.min.json)"
                    color: "#888888"
                    font.pixelSize: units.gu(1.4)
                    wrapMode: Text.WordWrap
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                }

                // URL field
                Rectangle {
                    width: parent.width
                    height: units.gu(5.5)
                    color: "#111111"
                    border.color: urlField.activeFocus ? "#4A90D9" : "#2A2A2A"
                    radius: units.dp(8)

                    TextField {
                        id: urlField
                        anchors.fill: parent
                        anchors.margins: units.dp(2)
                        placeholderText: "https://…"
                        color: "white"
                        font.pixelSize: units.gu(1.6)
                        inputMethodHints: Qt.ImhUrlCharactersOnly
                    }
                }

                // Buttons row
                Row {
                    width: parent.width
                    spacing: units.gu(1.5)
                    layoutDirection: Qt.RightToLeft

                    // Add
                    Rectangle {
                        width: (parent.width - units.gu(1.5)) / 2
                        height: units.gu(5)
                        radius: units.dp(8)
                        color: urlField.text.trim() !== "" ? "#4A90D9" : "#2A2A2A"

                        Label {
                            anchors.centerIn: parent
                            text: "Add"
                            color: "white"
                            font.bold: true
                            font.pixelSize: units.gu(1.8)
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var url = urlField.text.trim()
                                if (url === "") return
                                // Derive a friendly name from the URL
                                var name = url.replace(/https?:\/\//, "")
                                                .replace(/\/index\.min\.json$/, "")
                                                .replace(/\/repo\.json$/, "")
                                extStoresPage.addRepo(name, url)
                                urlField.text = ""
                                addDialog.visible = false
                            }
                        }
                    }

                    // Cancel
                    Rectangle {
                        width: (parent.width - units.gu(1.5)) / 2
                        height: units.gu(5)
                        radius: units.dp(8)
                        color: "#2A2A2A"

                        Label {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: "#888888"
                            font.pixelSize: units.gu(1.8)
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { urlField.text = ""; addDialog.visible = false }
                        }
                    }
                }
            }
        }
    }

    // -----------------------------------------------------------------------
    // Delete confirm dialog
    // -----------------------------------------------------------------------
    Rectangle {
        id: deleteConfirmDialog
        visible: false
        anchors.fill: parent
        color: "#BB000000"
        z: 100

        MouseArea { anchors.fill: parent; onClicked: deleteConfirmDialog.visible = false }

        Rectangle {
            width: parent.width - units.gu(8)
            height: deleteDialogCol.height + units.gu(4)
            anchors.centerIn: parent
            color: "#1E1E1E"
            border.color: "#2A2A2A"
            radius: units.dp(12)

            MouseArea { anchors.fill: parent }

            Column {
                id: deleteDialogCol
                width: parent.width - units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: units.gu(2)
                spacing: units.gu(1.5)

                Label {
                    text: "Remove this store?"
                    color: "white"
                    font.bold: true
                    font.pixelSize: units.gu(2)
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Label {
                    text: "Extensions from this store will remain installed."
                    color: "#888888"
                    font.pixelSize: units.gu(1.5)
                    wrapMode: Text.WordWrap
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                }

                Row {
                    width: parent.width
                    spacing: units.gu(1.5)
                    layoutDirection: Qt.RightToLeft

                    Rectangle {
                        width: (parent.width - units.gu(1.5)) / 2
                        height: units.gu(4.5)
                        radius: units.dp(8)
                        color: "#C0392B"

                        Label { anchors.centerIn: parent; text: "Remove"; color: "white"; font.bold: true; font.pixelSize: units.gu(1.8) }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                extStoresPage.removeRepo(extStoresPage.deleteConfirmIndex)
                                deleteConfirmDialog.visible = false
                            }
                        }
                    }

                    Rectangle {
                        width: (parent.width - units.gu(1.5)) / 2
                        height: units.gu(4.5)
                        radius: units.dp(8)
                        color: "#2A2A2A"

                        Label { anchors.centerIn: parent; text: "Cancel"; color: "#888888"; font.pixelSize: units.gu(1.8) }
                        MouseArea { anchors.fill: parent; onClicked: deleteConfirmDialog.visible = false }
                    }
                }
            }
        }
    }

    // -----------------------------------------------------------------------
    // Copy toast
    // -----------------------------------------------------------------------
    Rectangle {
        id: copyToast
        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.gu(10)
        anchors.horizontalCenter: parent.horizontalCenter
        width: copyToastLabel.implicitWidth + units.gu(4)
        height: units.gu(4.5)
        radius: units.dp(22)
        color: "#2A2A2A"
        opacity: 0
        z: 200

        Label {
            id: copyToastLabel
            anchors.centerIn: parent
            text: "URL copied to clipboard"
            color: "white"
            font.pixelSize: units.gu(1.6)
        }

        function show() {
            opacity = 1
            toastTimer.restart()
        }

        Timer {
            id: toastTimer
            interval: 1800
            onTriggered: copyToast.opacity = 0
        }

        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
