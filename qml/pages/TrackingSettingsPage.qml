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
                            loginOverlay.selectedTrackerId = index + 1 // 1-based index
                            loginOverlay.selectedTrackerName = modelData.name
                            usernameInput.text = ""
                            passwordInput.text = ""
                            loginOverlay.visible = true
                        }
                    }
                }
            }
        }
    }

    // Connections to C++ signals
    Connections {
        target: mangaDex
        onTrackerLoginStatus: {
            // trackerId, success, message
            statusTimer.showStatus(success ? "Logged in to " + loginOverlay.selectedTrackerName : "Login failed: " + message)
            loginOverlay.visible = false
        }
        onTrackerLogoutStatus: {
            statusTimer.showStatus(success ? "Logged out" : "Logout failed")
        }
    }

    Timer {
        id: statusTimer
        interval: 3000
        property string msg: ""
        onTriggered: statusLabel.text = ""
        function showStatus(m) {
            statusLabel.text = m
            restart()
        }
    }

    Label {
        id: statusLabel
        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.gu(2)
        anchors.horizontalCenter: parent.horizontalCenter
        color: "#00bfa5"
        font.bold: true
        font.pixelSize: units.gu(1.8)
    }

    // ---- LOGIN OVERLAY ----
    Rectangle {
        id: loginOverlay
        anchors.fill: parent
        color: "#CC000000"
        visible: false

        property int selectedTrackerId: 0
        property string selectedTrackerName: ""

        MouseArea { anchors.fill: parent } // Block underlying clicks

        Rectangle {
            width: parent.width - units.gu(6)
            height: units.gu(32)
            radius: units.dp(10)
            color: "#1E1E1E"
            border.color: "#2A2A2A"
            anchors.centerIn: parent

            Column {
                anchors.fill: parent
                anchors.margins: units.gu(2)
                spacing: units.gu(2)

                Label {
                    text: "Login to " + loginOverlay.selectedTrackerName
                    font.bold: true
                    font.pixelSize: units.gu(2)
                    color: "white"
                }

                // Username Input
                TextField {
                    id: usernameInput
                    width: parent.width
                    placeholderText: "Username / Email"
                    color: "white"
                }

                // Password Input
                TextField {
                    id: passwordInput
                    width: parent.width
                    placeholderText: "Password"
                    echoMode: TextInput.Password
                    color: "white"
                }

                Row {
                    width: parent.width
                    spacing: units.gu(1.5)

                    Rectangle {
                        width: parent.width / 2 - units.gu(0.75)
                        height: units.gu(4.5)
                        radius: units.dp(6)
                        color: "#2D2D2D"
                        Label { anchors.centerIn: parent; text: "Cancel"; color: "white" }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: loginOverlay.visible = false
                        }
                    }

                    Rectangle {
                        width: parent.width / 2 - units.gu(0.75)
                        height: units.gu(4.5)
                        radius: units.dp(6)
                        color: "#004d40"
                        border.color: "#00bfa5"
                        Label { anchors.centerIn: parent; text: "Login"; color: "#00bfa5"; font.bold: true }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                mangaDex.loginTracker(loginOverlay.selectedTrackerId, usernameInput.text, passwordInput.text)
                                statusLabel.text = "Logging in..."
                            }
                        }
                    }
                }

                // Logout option if already logged in
                Rectangle {
                    width: parent.width
                    height: units.gu(4.5)
                    radius: units.dp(6)
                    color: "#3E2525"
                    Label { anchors.centerIn: parent; text: "Logout / Unlink Account"; color: "#FF6B6B"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            mangaDex.logoutTracker(loginOverlay.selectedTrackerId)
                            loginOverlay.visible = false
                            statusLabel.text = "Logging out..."
                        }
                    }
                }
            }
        }
    }
}
