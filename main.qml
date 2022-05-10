import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ApplicationWindow {
    id: window
    width: 1200
    height: 800
    visible: true
    minimumHeight: 200
    minimumWidth: 250
    readonly property bool narrowWindow: window.width < 400
    title: qsTr("ScanHub MRI Simulator")
    //: Application title bar text


//    Shortcut {
//        sequence: StandardKey.FullScreen
//        onActivated: window.showMaximized()
//    }

//    Shortcut {
//        sequence: "Tab"
//        onActivated: drawer_right.open()
//    }

//    Shortcut {
//        sequence: "k"
//        onActivated: thumbnails.model ? thumbnails.currentIndex = (thumbnails.currentIndex+1) % thumbnails.model : 0
//    }
//    Shortcut {
//        sequence: "j"
//        onActivated: thumbnails.model ? thumbnails.currentIndex = (thumbnails.currentIndex-1+thumbnails.model) % thumbnails.model : 0
//    }


    header: ToolBar {
        id: toolbar
//        Material.foreground: "white"
//        Material.background: Material.BlueGrey

        RowLayout {
            spacing: 0
            anchors.fill: parent
//            anchors.rightMargin: !drawer_right.modal ? drawer_right.width : undefined

            ToolButton {
                id: open_img
                text: "\uF115" // icon-folder-open-empty
                font.family: "fontello"
                ToolTip.text: qsTr("Open new image (Ctrl + O)")
                //: Hover tooltip content
                ToolTip.visible: hovered
                onClicked: dialog_loader.sourceComponent = fileDialogComponent;
                Shortcut {
                    sequence: StandardKey.Open
                    onActivated: dialog_loader.sourceComponent = fileDialogComponent
                    context: Qt.ApplicationShortcut
                }
//                Component {
//                    id: fileDialogComponent
//                    FileDialog {
//                        id: fileDialog
//                        selectMultiple: true
//                        title: qsTr("Please choose a file")
//                        //: File open dialog title bar
//                        onAccepted: {
//                            py_MainApp.load_new_img(fileUrls)
//                            dialog_loader.hide()
//                           }
//                        onRejected: dialog_loader.hide()
//                    }
//                }
            }

            ToolButton {
                text: "\uE800" // icon-floppy
                font.family: "fontello"
                onClicked: dialog_loader.sourceComponent = saveDialogComponent;
                ToolTip.text: qsTr("Save as images (Ctrl + S)")
                //: Hover tooltip text
                ToolTip.visible: hovered
                Shortcut {
                    sequence: StandardKey.Save
                    onActivated: dialog_loader.sourceComponent = fileDialogComponent
                    context: Qt.ApplicationShortcut
                }
//                Component {
//                    id: saveDialogComponent
//                    FileDialog {
//                        id: saveDialog
//                        visible: false
//                        selectMultiple: false
//                        selectExisting: false
//                        nameFilters: [ "PNG file (*.png)", "Floating point TIFF (*.tiff)" ]
//                        title: qsTr("Save image files")
//                        //: Save dialog title bar
//                        onAccepted: {
//                            py_MainApp.save_img(fileUrl)
//                            dialog_loader.hide()
//                            }
//                        onRejected: dialog_loader.hide()
//                    }
//                }
            }

            ToolButton {
                text: "\uE800" // icon-floppy
                font.family: "fontello"
                onClicked: dialog_loader.sourceComponent = saveDialogKSpaceComponent;
                ToolTip.text: qsTr("Save K-Space (Ctrl + K)")
                //: Hover tooltip text
                ToolTip.visible: hovered
                Shortcut {
                    sequence: "Ctrl+K"
                    onActivated: dialog_loader.sourceComponent = fileDialogComponent
                    context: Qt.ApplicationShortcut
                }
//                Component {
//                    id: saveDialogKSpaceComponent
//                    FileDialog {
//                        id: saveDialog
//                        visible: false
//                        selectMultiple: false
//                        selectExisting: false
//                        nameFilters: [ "NPY file (*.npy)" ]
//                        title: qsTr("Save k-Space files")
//                        //: Save dialog title bar
//                        onAccepted: {
//                            py_MainApp.save_kspace(fileUrl)
//                            dialog_loader.hide()
//                            }
//                        onRejected: dialog_loader.hide()
//                    }
//                }
            }

            Item {
                // spacer item
                Layout.fillWidth: true
                Layout.fillHeight: true
                //Rectangle { anchors.fill: parent; color: "#ffaaaa" } // to visualize the spacer
            }

//            ToolButton {
//                id: hide_progressbar
//                icon.source: "images/layout-footer.png"
//                onClicked: footer.visible = !footer.visible
//                ToolTip.text: qsTr("Toggle scan progress (F7)")
//                //: Hover tooltip text
//                ToolTip.visible: hovered
//                Shortcut {
//                    sequence: "F7"
//                    onActivated: hide_progressbar.onClicked()
//                    context: Qt.ApplicationShortcut
//                }
//            }

            ToolButton {
                text: "\uE801" // icon-cog-alt
                font.family: "fontello"
                onClicked: optionsMenu.open()
                ToolTip.text: qsTr("Additional options")
                //: Hover tooltip text
                ToolTip.visible: hovered

                Menu {
                    id: optionsMenu
                    x: parent.width - width
                    transformOrigin: Menu.TopRight

                    MenuItem {
                        text: "Settings"
                        onTriggered: dialog_loader.sourceComponent = settingsDialog_component;
                    }
                    MenuItem {
                        text: "About"
                        onTriggered: dialog_loader.sourceComponent = aboutDialog_component;
                    }
                }
            }
        }
    }

    footer: ToolBar {
        id: footer
//        Material.foreground: "white"
//        Material.background: "#555555"
        RowLayout {
//            anchors.rightMargin: !drawer_right.modal ? drawer_right.width : undefined
//            anchors.fill: parent

            ToolButton {
                id: reset
                text: "\uE802" // icon-to-start-alt
                font.family: "fontello"
                ToolTip.text: "Reset (F4)"
                //: Image acquisition footer button tooltip text
                ToolTip.visible: hovered
                ToolTip.timeout: 1500
                highlighted: !filling.value
                onPressed: {
                        play_anim.running = false
                        filling.value = 0
                }
                Shortcut {
                    sequence: "F4"
                    onActivated: reset.onPressed()
                    context: Qt.ApplicationShortcut
                }
            }

            ToolButton {
                id: play_btn
                text: "\uE803" //play_anim.running ? "\uE804" : "\uE803" // icon-pause : icon-play
                font.family: "fontello"
                ToolTip.text: "Play/Pause (F5)"
                //: Image acquisition footer button tooltip text
                ToolTip.visible: hovered
                ToolTip.timeout: 1500
                highlighted: play_anim.running
                onPressed: {
                        if (filling.value == 100)
                            filling.value = 0
                        play_anim.running ? play_anim.stop() : play_anim.start()
                }
                Shortcut {
                    sequence: "F5"
                    onActivated: play_btn.onPressed()
                    context: Qt.ApplicationShortcut
                }
            }

            Slider {
                id: filling
                objectName: "filling"
                Layout.fillWidth: true
                from: 0
                height: 30
                to: 100
                stepSize: 0.001
                value: 100
                handle.height: 18
                handle.width: 8
                enabled: !play_anim.running
                onValueChanged: py_MainApp.update_displays()
                PropertyAnimation {
                    property int len: 10000
                    id: play_anim
                    target: filling
                    property: "value"
                    to: 100
                    duration: (100 - filling.value)/100 * len
                }
            }

            ComboBox {
                id: filling_mode
                objectName: "filling_mode"
                Layout.fillWidth: true
                Layout.maximumWidth: 200
                textRole: "text"
                model: ListModel {
                    id: filling_modes
                    ListElement { mode: 0; text: "Linear"}
                    ListElement { mode: 1; text: "Centric"}
                    ListElement { mode: 2; text: "Single-Shot EPI (blipped)"}
                }
            }
        }
    }

}
