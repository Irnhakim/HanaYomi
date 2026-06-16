import QtQuick 2.9
import Lomiri.Components 1.3

Page {
    id: categoriesPage
    
    Rectangle { anchors.fill: parent; color: "#111111" }

    header: PageHeader {
        title: "Manage Categories"
        StyleHints { foregroundColor: "white"; backgroundColor: "#1A1A1A"; dividerColor: "#2A2A2A" }
    }

    ListModel { id: categoryModel }

    function loadCategories() {
        categoryModel.clear();
        var cats = db.getCategories();
        for (var i = 0; i < cats.length; i++) {
            categoryModel.append(cats[i]);
        }
    }

    Component.onCompleted: {
        loadCategories();
    }

    Column {
        anchors.fill: parent
        anchors.topMargin: parent.header.height + units.gu(2)
        anchors.leftMargin: units.gu(2)
        anchors.rightMargin: units.gu(2)
        spacing: units.gu(2)

        // Add New Category Section
        Row {
            width: parent.width
            height: units.gu(5.5)
            spacing: units.gu(1)

            Rectangle {
                width: parent.width - units.gu(9)
                height: parent.height
                color: "#1E1E1E"
                border.color: "#2A2A2A"
                radius: units.dp(6)

                TextField {
                    id: newCatInput
                    anchors.fill: parent
                    anchors.margins: units.dp(2)
                    placeholderText: "New category name..."
                    color: "white"
                }
            }

            Rectangle {
                width: units.gu(8)
                height: parent.height
                color: "#1A3A6A"
                radius: units.dp(6)
                Label {
                    anchors.centerIn: parent
                    text: "Add"
                    color: "#4A90D9"
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var name = newCatInput.text.trim();
                        if (name !== "") {
                            db.createCategory(name);
                            newCatInput.text = "";
                            categoriesPage.loadCategories();
                        }
                    }
                }
            }
        }

        // Categories List
        ListView {
            width: parent.width
            height: parent.height - units.gu(10)
            clip: true
            model: categoryModel

            Label {
                visible: categoryModel.count === 0
                text: "No categories created yet."
                color: "#666666"
                anchors.centerIn: parent
                font.pixelSize: units.gu(1.8)
            }

            delegate: Item {
                width: parent.width
                height: units.gu(6.5)

                Row {
                    anchors.fill: parent
                    spacing: units.gu(1)

                    Label {
                        text: model.name || ""
                        color: "white"
                        font.pixelSize: units.gu(1.9)
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - units.gu(14)
                        elide: Text.ElideRight
                    }

                    // Rename Button
                    Rectangle {
                        width: units.gu(6)
                        height: units.gu(4)
                        color: "#222222"
                        radius: units.dp(4)
                        anchors.verticalCenter: parent.verticalCenter
                        Icon { name: "edit"; width: units.gu(2.2); height: units.gu(2.2); color: "#888888"; anchors.centerIn: parent }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                renamePopup.catId = model.id;
                                renamePopup.catName = model.name;
                                renamePopupInput.text = model.name;
                                renamePopup.visible = true;
                            }
                        }
                    }

                    // Delete Button
                    Rectangle {
                        width: units.gu(6)
                        height: units.gu(4)
                        color: "#3E2525"
                        radius: units.dp(4)
                        anchors.verticalCenter: parent.verticalCenter
                        Icon { name: "delete"; width: units.gu(2.2); height: units.gu(2.2); color: "#FF6B6B"; anchors.centerIn: parent }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                db.deleteCategory(model.id);
                                categoriesPage.loadCategories();
                            }
                        }
                    }
                }

                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: units.dp(1); color: "#1E1E1E" }
            }
        }
    }

    // Rename Popup Overlay
    Rectangle {
        id: renamePopup
        anchors.fill: parent
        color: "#AA000000"
        visible: false

        property int catId: 0
        property string catName: ""

        MouseArea { anchors.fill: parent } // Block clicks

        Rectangle {
            width: parent.width - units.gu(8)
            height: units.gu(22)
            color: "#1A1A1A"
            radius: units.dp(12)
            border.color: "#2A2A2A"
            anchors.centerIn: parent

            Column {
                anchors.fill: parent
                anchors.margins: units.gu(2)
                spacing: units.gu(2)

                Label { text: "Rename Category"; font.bold: true; color: "white"; font.pixelSize: units.gu(2) }

                Rectangle {
                    width: parent.width
                    height: units.gu(5)
                    color: "#2A2A2A"
                    radius: units.dp(6)
                    TextField {
                        id: renamePopupInput
                        anchors.fill: parent
                        anchors.margins: units.dp(2)
                        color: "white"
                    }
                }

                Row {
                    width: parent.width
                    height: units.gu(4.5)
                    spacing: units.gu(1.5)

                    Rectangle {
                        width: parent.width / 2 - units.gu(0.75)
                        height: parent.height
                        color: "#333333"
                        radius: units.dp(6)
                        Label { anchors.centerIn: parent; text: "Cancel"; color: "#AAAAAA" }
                        MouseArea { anchors.fill: parent; onClicked: renamePopup.visible = false }
                    }

                    Rectangle {
                        width: parent.width / 2 - units.gu(0.75)
                        height: parent.height
                        color: "#1A3A6A"
                        radius: units.dp(6)
                        Label { anchors.centerIn: parent; text: "Save"; color: "#4A90D9"; font.bold: true }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var newName = renamePopupInput.text.trim();
                                if (newName !== "" && newName !== renamePopup.catName) {
                                    db.renameCategory(renamePopup.catId, newName);
                                    categoriesPage.loadCategories();
                                }
                                renamePopup.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
