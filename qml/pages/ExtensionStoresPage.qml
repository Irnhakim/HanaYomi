import QtQuick 2.9
import Lomiri.Components 1.3
import Qt.labs.settings 1.0

Page {
    id: extensionStoresPage
    title: "Extension stores"

    // Reference to the main stack to pop/push
    property var mainStack: null
    property var onClosed: null

    Rectangle {
        anchors.fill: parent
        color: "#111111"
    }

    Settings {
        id: settings
        category: "Extensions"
        property string extensionRepos: "[]"
    }

    ListModel {
        id: repoModel
    }

    function loadRepos() {
        repoModel.clear()
        var repos = JSON.parse(settings.extensionRepos)
        for (var i = 0; i < repos.length; i++) {
            repoModel.append(repos[i])
        }
    }

    function saveRepos() {
        var repos = []
        for (var i = 0; i < repoModel.count; i++) {
            repos.push({
                "name": repoModel.get(i).name,
                "url": repoModel.get(i).url
            })
        }
        settings.extensionRepos = JSON.stringify(repos)
    }

    function addRepo(url) {
        if (!url || url.trim() === "") return;
        url = url.trim()
        
        // Coba fetch repo.json untuk mendeteksi nama repo
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var repoName = "Custom Repo"
                if (xhr.status === 200) {
                    try {
                        var info = JSON.parse(xhr.responseText)
                        if (info.name) {
                            repoName = info.name
                        }
                    } catch(e) {
                        // Gunakan nama default jika gagal parse
                    }
                }
                
                // Cari nama dari domain/path jika HTTP request gagal
                if (repoName === "Custom Repo") {
                    try {
                        var parts = url.split('/')
                        if (parts.length > 3) {
                            repoName = parts[2] + " (" + parts[parts.length - 2] + ")"
                        }
                    } catch(e) {}
                }

                repoModel.append({
                    "name": repoName,
                    "url": url
                })
                saveRepos()
                addDialog.visible = false
                inputUrlField.text = ""
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    Component.onCompleted: {
        loadRepos()
    }

    header: PageHeader {
        title: "Extension stores"
        StyleHints { foregroundColor: "white"; backgroundColor: "#111111"; dividerColor: "#2A2A2A" }

        leadingActionBar.actions: [
            Action {
                iconName: "back"
                onTriggered: {
                    if (mainStack) {
                        mainStack.pop()
                        if (extensionStoresPage.onClosed) {
                            extensionStoresPage.onClosed()
                        }
                    }
                }
            }
        ]

        trailingActionBar.actions: [
            Action {
                iconName: "reload"
                onTriggered: {
                    loadRepos()
                }
            }
        ]
    }

    // List of Repositories
    ListView {
        id: repoListView
        anchors.fill: parent
        anchors.topMargin: parent.header.height + units.gu(2)
        anchors.bottomMargin: units.gu(10)
        model: repoModel
        clip: true
        spacing: units.gu(1.5)

        delegate: Rectangle {
            width: parent.width - units.gu(4)
            height: units.gu(10)
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#1E1E1E"
            border.color: "#2A2A2A"
            radius: units.dp(8)

            Column {
                anchors.fill: parent
                anchors.margins: units.gu(1.5)
                spacing: units.gu(1)

                Row {
                    width: parent.width
                    spacing: units.gu(1)

                    Icon {
                        name: "folder"
                        width: units.gu(2.4)
                        height: units.gu(2.4)
                        color: "#4A90D9"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Label {
                        text: model.name || "Unknown Repository"
                        color: "white"
                        font.pixelSize: units.gu(1.8)
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width - units.gu(4)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    anchors.right: parent.right
                    spacing: units.gu(2.5)

                    // Globe (View in browser/open URL)
                    Icon {
                        name: "browser"
                        width: units.gu(2.2)
                        height: units.gu(2.2)
                        color: "#888888"
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Qt.openUrlExternally(model.url)
                        }
                    }

                    // Copy to clipboard
                    Icon {
                        name: "copy"
                        width: units.gu(2.2)
                        height: units.gu(2.2)
                        color: "#888888"
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Clipboard.push(model.url)
                            }
                        }
                    }

                    // Delete
                    Icon {
                        name: "delete"
                        width: units.gu(2.2)
                        height: units.gu(2.2)
                        color: "#FF6B6B"
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                repoModel.remove(index)
                                saveRepos()
                            }
                        }
                    }
                }
            }
        }

        Label {
            visible: repoModel.count === 0
            anchors.centerIn: parent
            text: "No extension stores added yet.\nTap '+ Add' to add one."
            color: "#888888"
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: units.gu(1.6)
        }
    }

    // Floating action button "+ Add"
    Rectangle {
        id: addButton
        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.gu(4)
        anchors.right: parent.right
        anchors.rightMargin: units.gu(3)
        width: units.gu(12)
        height: units.gu(4.8)
        color: "#1A3A6A"
        radius: height / 2
        border.color: "#4A90D9"

        Row {
            anchors.centerIn: parent
            spacing: units.gu(0.8)

            Icon {
                name: "add"
                width: units.gu(2)
                height: units.gu(2)
                color: "#4A90D9"
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                text: "Add"
                color: "#4A90D9"
                font.bold: true
                font.pixelSize: units.gu(1.6)
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                addDialog.visible = true
            }
        }
    }

    // Custom overlay dialog for entering URL
    Rectangle {
        id: addDialog
        visible: false
        anchors.fill: parent
        color: "#AA000000"
        z: 99999

        // Dismiss when clicking background
        MouseArea {
            anchors.fill: parent
            onClicked: addDialog.visible = false
        }

        Rectangle {
            width: parent.width - units.gu(6)
            height: units.gu(22)
            anchors.centerIn: parent
            color: "#1E1E1E"
            border.color: "#2A2A2A"
            radius: units.dp(8)

            // Prevent clicks from propagating
            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: units.gu(2)
                spacing: units.gu(1.5)

                Label {
                    text: "Add extension store"
                    color: "white"
                    font.bold: true
                    font.pixelSize: units.gu(1.8)
                }

                TextField {
                    id: inputUrlField
                    width: parent.width
                    placeholderText: "https://example.com/repo.json"
                    text: ""
                    color: "white"
                    font.pixelSize: units.gu(1.5)
                }

                Row {
                    anchors.right: parent.right
                    spacing: units.gu(1.5)

                    Button {
                        text: "Cancel"
                        color: "transparent"
                        strokeColor: "#444444"
                        width: units.gu(10)
                        onClicked: {
                            addDialog.visible = false
                            inputUrlField.text = ""
                        }
                    }

                    Button {
                        text: "Add"
                        color: "#1A3A6A"
                        width: units.gu(10)
                        onClicked: {
                            addRepo(inputUrlField.text)
                        }
                    }
                }
            }
        }
    }
}
