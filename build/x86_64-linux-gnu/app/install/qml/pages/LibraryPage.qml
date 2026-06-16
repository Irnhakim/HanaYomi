import QtQuick 2.9
import Lomiri.Components 1.3
import Qt.labs.settings 1.0

// LibraryPage — terhubung ke SQLite via C++ DatabaseHelper
Page {
    id: libraryPage
    property var mainStack: null

    // State penyaringan & pengurutan
    property int selectedCategoryIndex: 0
    property int selectedCategoryId: -1 // -1 berarti "Semua"
    property string sortBy: "title" // "title", "date_added", "last_update"
    property string sortOrder: "ASC" // "ASC", "DESC"
    property string filterStatus: "all" // "all", "ongoing", "completed"

    Rectangle { anchors.fill: parent; color: "#111111" }

    // Settings untuk menyimpan status preferensi sort
    Settings {
        id: libSettings
        category: "Library"
        property string sortBy: "title"
        property string sortOrder: "ASC"
        property string filterStatus: "all"
    }

    Component.onCompleted: {
        sortBy = libSettings.sortBy;
        sortOrder = libSettings.sortOrder;
        filterStatus = libSettings.filterStatus;
        reloadCategories();
    }

    Connections {
        target: db
        onLibraryChanged: {
            reloadCategories();
        }
    }

    ListModel { id: categoryModel }
    ListModel { id: libraryModel }

    function reloadCategories() {
        categoryModel.clear();
        categoryModel.append({ "id": -1, "name": "Default" });

        var cats = db.getCategories();
        for (var i = 0; i < cats.length; i++) {
            categoryModel.append(cats[i]);
        }

        // Koreksi batas index aktif
        if (selectedCategoryIndex >= categoryModel.count) {
            selectedCategoryIndex = 0;
        }
        selectedCategoryId = categoryModel.get(selectedCategoryIndex).id;
        reloadLibrary();
    }

    function reloadLibrary() {
        libraryModel.clear();
        var books = db.getLibraryMangaFiltered(selectedCategoryId, sortBy, sortOrder, filterStatus);
        for (var i = 0; i < books.length; i++) {
            libraryModel.append(books[i]);
        }
    }

    header: PageHeader {
        title: "Library"
        StyleHints { foregroundColor: "white"; backgroundColor: "#111111"; dividerColor: "#2A2A2A" }
        trailingActionBar.actions: [
            Action {
                iconName: "sort-listview"
                text: "Sort & Filter"
                onTriggered: filterOverlay.visible = true
            },
            Action {
                iconName: "settings"
                text: "Manage Categories"
                onTriggered: categoryOverlay.visible = true
            }
        ]
    }

    Column {
        anchors.top: parent.header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        // Tab bar kategori
        Rectangle {
            width: parent.width
            height: categoryModel.count > 1 ? units.gu(5.5) : 0
            visible: categoryModel.count > 1
            color: "#111111"

            ListView {
                anchors.fill: parent
                orientation: ListView.Horizontal
                model: categoryModel
                clip: true
                delegate: Item {
                    width: Math.max(units.gu(12), tabLabel.implicitWidth + units.gu(4))
                    height: parent.height

                    Label {
                        id: tabLabel
                        anchors.centerIn: parent
                        text: model.name
                        color: selectedCategoryIndex === index ? "#4A90D9" : "#888888"
                        font.pixelSize: units.gu(1.7)
                        font.bold: selectedCategoryIndex === index
                    }
                    Rectangle {
                        visible: selectedCategoryIndex === index
                        anchors.bottom: parent.bottom
                        width: parent.width; height: units.dp(2)
                        color: "#4A90D9"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            selectedCategoryIndex = index;
                            selectedCategoryId = model.id;
                            reloadLibrary();
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: categoryModel.count > 1 ? units.dp(1) : 0
            visible: categoryModel.count > 1
            color: "#2A2A2A"
        }

        // Empty state
        Column {
            visible: libraryModel.count === 0
            width: parent.width
            height: parent.height - units.gu(10)
            spacing: units.gu(2)
            Item { width: 1; height: units.gu(5) } // spacer

            Label {
                text: "📚"
                font.pixelSize: units.gu(6)
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Label {
                text: "No manga found"
                color: "#555555"
                font.pixelSize: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Label {
                text: "Try changing filters or category"
                color: "#444444"
                font.pixelSize: units.gu(1.6)
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Grid/List of library items
        ListView {
            visible: libraryModel.count > 0
            width: parent.width
            height: parent.height - (categoryModel.count > 1 ? units.gu(5.5) : 0)
            model: libraryModel
            clip: true

            delegate: Item {
                width: parent.width
                height: units.gu(9)

                Rectangle { anchors.fill: parent; color: "#111111" }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(2)
                    anchors.rightMargin: units.gu(2)
                    spacing: units.gu(2)

                    Rectangle {
                        width: units.gu(6)
                        height: units.gu(7.5)
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#2A2A2A"
                        radius: units.dp(4)
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: model.thumbnailUrl || ""
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                        }
                        Label {
                            visible: !model.thumbnailUrl
                            anchors.centerIn: parent
                            text: model.title ? model.title.charAt(0) : "?"
                            color: "white"; font.bold: true; font.pixelSize: units.gu(2.5)
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - units.gu(15)
                        spacing: units.dp(4)

                        Label {
                            text: model.title || ""
                            color: "white"
                            font.pixelSize: units.gu(1.8)
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        Label {
                            text: model.author || "Unknown Author"
                            color: "#888888"
                            font.pixelSize: units.gu(1.4)
                        }
                    }

                    Rectangle {
                        visible: model.unreadCount > 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(units.gu(4), unreadLbl.width + units.gu(1.5))
                        height: units.gu(2.8)
                        radius: units.dp(4)
                        color: "#1A3A6A"
                        Label {
                            id: unreadLbl
                            anchors.centerIn: parent
                            text: model.unreadCount || ""
                            color: "#4A90D9"; font.pixelSize: units.gu(1.4); font.bold: true
                        }
                    }
                }

                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (mainStack) {
                            mainStack.push(Qt.resolvedUrl("MangaDetailPage.qml"), {
                                mangaId: model.id,
                                mangaTitle: model.title,
                                mangaDesc: model.description || "",
                                mangaCover: model.thumbnailUrl || "",
                                mainStack: mainStack
                            })
                        }
                    }
                }
            }
        }
    }

    // ---- OVERLAY 1: SORT & FILTER POPUP ----
    Rectangle {
        id: filterOverlay
        anchors.fill: parent
        color: "#AA000000"
        visible: false

        MouseArea { anchors.fill: parent } // block clicks below

        Rectangle {
            width: parent.width - units.gu(6)
            height: units.gu(38)
            radius: units.dp(12)
            color: "#1E1E1E"
            border.color: "#2A2A2A"
            anchors.centerIn: parent

            Column {
                anchors.fill: parent
                anchors.margins: units.gu(2.5)
                spacing: units.gu(2)

                Label { text: "Sort & Filter Settings"; font.bold: true; font.pixelSize: units.gu(2); color: "white" }

                // Sort By
                Column {
                    width: parent.width; spacing: units.dp(5)
                    Label { text: "Sort By"; color: "#888888"; font.pixelSize: units.gu(1.4) }
                    Row {
                        spacing: units.gu(1)
                        Repeater {
                            model: [
                                { "label": "Title", "val": "title" },
                                { "label": "Date Added", "val": "date_added" }
                            ]
                            Rectangle {
                                width: units.gu(14); height: units.gu(4.5); radius: units.dp(6)
                                color: libraryPage.sortBy === modelData.val ? "#1A3A6A" : "#2D2D2D"
                                Label { anchors.centerIn: parent; text: modelData.label; color: libraryPage.sortBy === modelData.val ? "#4A90D9" : "white" }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        libraryPage.sortBy = modelData.val;
                                        libSettings.sortBy = modelData.val;
                                    }
                                }
                            }
                        }
                    }
                }

                // Sort Order
                Column {
                    width: parent.width; spacing: units.dp(5)
                    Label { text: "Order"; color: "#888888"; font.pixelSize: units.gu(1.4) }
                    Row {
                        spacing: units.gu(1)
                        Repeater {
                            model: [
                                { "label": "Ascending (A-Z)", "val": "ASC" },
                                { "label": "Descending (Z-A)", "val": "DESC" }
                            ]
                            Rectangle {
                                width: units.gu(14); height: units.gu(4.5); radius: units.dp(6)
                                color: libraryPage.sortOrder === modelData.val ? "#1A3A6A" : "#2D2D2D"
                                Label { anchors.centerIn: parent; text: modelData.label; color: libraryPage.sortOrder === modelData.val ? "#4A90D9" : "white" }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        libraryPage.sortOrder = modelData.val;
                                        libSettings.sortOrder = modelData.val;
                                    }
                                }
                            }
                        }
                    }
                }

                // Filter Status
                Column {
                    width: parent.width; spacing: units.dp(5)
                    Label { text: "Filter Status"; color: "#888888"; font.pixelSize: units.gu(1.4) }
                    Row {
                        spacing: units.gu(1)
                        Repeater {
                            model: [
                                { "label": "All", "val": "all" },
                                { "label": "Ongoing", "val": "ongoing" },
                                { "label": "Completed", "val": "completed" }
                            ]
                            Rectangle {
                                width: units.gu(9); height: units.gu(4.5); radius: units.dp(6)
                                color: libraryPage.filterStatus === modelData.val ? "#1A3A6A" : "#2D2D2D"
                                Label { anchors.centerIn: parent; text: modelData.label; color: libraryPage.filterStatus === modelData.val ? "#4A90D9" : "white" }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        libraryPage.filterStatus = modelData.val;
                                        libSettings.filterStatus = modelData.val;
                                    }
                                }
                            }
                        }
                    }
                }

                // Close Button
                Rectangle {
                    width: parent.width; height: units.gu(5); radius: units.dp(6); color: "#4A90D9"
                    Label { anchors.centerIn: parent; text: "Apply & Close"; color: "white"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            filterOverlay.visible = false;
                            libraryPage.reloadLibrary();
                        }
                    }
                }
            }
        }
    }

    // ---- OVERLAY 2: MANAGE CATEGORIES POPUP ----
    Rectangle {
        id: categoryOverlay
        anchors.fill: parent
        color: "#AA000000"
        visible: false

        MouseArea { anchors.fill: parent }

        Rectangle {
            width: parent.width - units.gu(6)
            height: units.gu(45)
            radius: units.dp(12)
            color: "#1E1E1E"
            border.color: "#2A2A2A"
            anchors.centerIn: parent

            Column {
                anchors.fill: parent
                anchors.margins: units.gu(2.5)
                spacing: units.gu(2)

                Label { text: "Manage Categories"; font.bold: true; font.pixelSize: units.gu(2); color: "white" }

                // Add Category Input
                Row {
                    width: parent.width; height: units.gu(5); spacing: units.gu(1)
                    Rectangle {
                        width: parent.width - units.gu(9); height: parent.height; color: "#2D2D2D"; radius: units.dp(6)
                        TextField {
                            id: catNameInput
                            anchors.fill: parent; anchors.margins: units.dp(2)
                            placeholderText: "New Category Name..."
                            color: "white"
                        }
                    }
                    Rectangle {
                        width: units.gu(8); height: parent.height; color: "#1A3A6A"; radius: units.dp(6)
                        Label { anchors.centerIn: parent; text: "Add"; color: "#4A90D9"; font.bold: true }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var name = catNameInput.text.trim();
                                if (name !== "") {
                                    db.createCategory(name);
                                    catNameInput.text = "";
                                    libraryPage.reloadCategories();
                                }
                            }
                        }
                    }
                }

                // List of existing categories (excluding Default/All)
                ListView {
                    width: parent.width
                    height: units.gu(22)
                    clip: true
                    model: categoryModel
                    delegate: Item {
                        // Jangan tampilkan Default (-1) untuk dihapus
                        visible: model.id !== -1
                        width: parent.width
                        height: visible ? units.gu(5) : 0

                        Row {
                            anchors.fill: parent
                            anchors.verticalCenter: parent.verticalCenter
                            Label {
                                text: model.name || ""
                                color: "white"
                                font.pixelSize: units.gu(1.8)
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - units.gu(6)
                            }
                            Icon {
                                name: "delete"
                                width: units.gu(3)
                                height: units.gu(3)
                                color: "#FF6B6B"
                                anchors.verticalCenter: parent.verticalCenter
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        db.deleteCategory(model.id);
                                        libraryPage.reloadCategories();
                                    }
                                }
                            }
                        }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#2A2A2A"; visible: model.id !== -1 }
                    }
                }

                // Done Button
                Rectangle {
                    width: parent.width; height: units.gu(5); radius: units.dp(6); color: "#2A2A2A"
                    Label { anchors.centerIn: parent; text: "Done"; color: "white" }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            categoryOverlay.visible = false;
                        }
                    }
                }
            }
        }
    }
}
