import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

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

    Shortcut {
        sequence: StandardKey.FullScreen
        onActivated: window.showMaximized()
    }

    Shortcut {
        sequence: "Tab"
        onActivated: drawer.open()
    }

    Shortcut {
        sequence: "k"
        onActivated: thumbnails.model ? thumbnails.currentIndex = (thumbnails.currentIndex+1) % thumbnails.model : 0
    }
    Shortcut {
        sequence: "j"
        onActivated: thumbnails.model ? thumbnails.currentIndex = (thumbnails.currentIndex-1+thumbnails.model) % thumbnails.model : 0
    }

    header: ToolBar {
        id: toolbar
        RowLayout {
            spacing: 0
            anchors.fill: parent

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
                Component {
                    id: fileDialogComponent
                    FileDialog {
                        id: fileDialog
                        fileMode: FileDialog.OpenFiles
                        title: qsTr("Please choose a file")
                        //: File open dialog title bar
                        onAccepted: {
                            py_SimulationApp.load_new_img(selectedFiles)
                            dialog_loader.hide()
                        }
                        onRejected: dialog_loader.hide()
                    }
                }
            }

            ToolButton {
                text: "\uE800" // icon-floppy
                font.family: "fontello"
                onClicked: dialog_loader.sourceComponent = saveDialogComponent;
                ToolTip.text: qsTr("Save Images (Ctrl + S)")
                //: Hover tooltip text
                ToolTip.visible: hovered
                Shortcut {
                    sequence: StandardKey.Save
                    onActivated: dialog_loader.sourceComponent = fileDialogComponent
                    context: Qt.ApplicationShortcut
                }
                Component {
                    id: saveDialogComponent
                    FileDialog {
                        id: saveDialog
                        fileMode: FileDialog.SaveFile
                        nameFilters: [ "PNG file (*.png)", "Floating point TIFF (*.tiff)", "NumPy file with a complex K-Space (*.npy)" ]
                        title: qsTr("Save image files")
                        //: Save dialog title bar
                        onAccepted: {
                            py_SimulationApp.save_img(selectedFile)
                            dialog_loader.hide()
                            }
                        onRejected: dialog_loader.hide()
                    }
                }
            }

            Item {
                // spacer item
                Layout.fillWidth: true
                Layout.fillHeight: true
                //Rectangle { anchors.fill: parent; color: "#ffaaaa" } // to visualize the spacer
            }

            ToolButton {
                id: hide_progressbar
                text: "\uF2D1" // icon-window-minimize
                font.family: "fontello"
                onClicked: footer.visible = !footer.visible
                ToolTip.text: qsTr("Toggle scan progress (F7)")
                //: Hover tooltip text
                ToolTip.visible: hovered
                Shortcut {
                    sequence: "F7"
                    onActivated: hide_progressbar.onClicked()
                    context: Qt.ApplicationShortcut
                }
            }

            ToolButton {
                text: "\uF29C" // icon-question-circle-o
                font.family: "fontello"
                onClicked: dialog_loader.sourceComponent = aboutDialog_component;
                ToolTip.text: qsTr("Additional options")
                //: Hover tooltip text
                ToolTip.visible: hovered
            }
        }
    }

    footer: ToolBar {
        id: footer
        RowLayout {
            anchors.fill: parent

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
                objectName: "play_btn"
                text: play_anim.running ? "\uE804" : "\uE803" // icon-pause : icon-play
                font.family: "fontello"
                ToolTip.text: "Play/Pause (F5)"
                //: Image acquisition footer button tooltip text
                ToolTip.visible: hovered
                ToolTip.timeout: 1500
                highlighted: play_anim.running
                onPressed: internalTriggerPlay()
                Shortcut {
                    sequence: "F5"
                    onActivated: play_btn.onPressed()
                    context: Qt.ApplicationShortcut
                }
                function internalTriggerPlay() {
                    play_anim.notify_enabled = false
                    triggerPlay()
                }
                function externalTriggerPlay() {
                    play_anim.notify_enabled = true
                    triggerPlay()
                }
                function triggerPlay() {
                    if (filling.value == 100)
                        filling.value = 0
                    play_anim.running ? play_anim.stop() : play_anim.start()
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
                onValueChanged: py_SimulationApp.update_displays()
                PropertyAnimation {
                    property int len: 10000
                    property bool notify_enabled: false
                    id: play_anim
                    target: filling
                    property: "value"
                    to: 100
                    duration: (100 - filling.value)/100 * len
                    onFinished: {
                        if(notify_enabled)
                            py_SimulationApp.kspace_simulation_finished()
                    }
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

    Drawer {
        id: drawer
        y: toolbar.height
        width: narrowWindow ? window.width : 400
        height: window.height - toolbar.height - footer.height
        edge: Qt.LeftEdge
        modal: false
        interactive: true
        visible: true

        TabBar {
            id: barProperties
            width: parent.width
            anchors.top: parent.top

            TabButton {
                text: qsTr("K-Space Parameter")
            }
            TabButton {
                text: qsTr("ScanHub Connection")
            }
        }

        StackLayout {
            id: propertiesStackLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: barProperties.bottom
            anchors.bottom: parent.bottom

            currentIndex: barProperties.currentIndex

            KSpaceParameterView {
                id: kspaceParameterTab
            }

            Item {
                id: cloudConnectionTab

            }
        }
    }

    SplitView {
        id: split_view
        anchors.fill: parent
        anchors.leftMargin: drawer.position * drawer.width
        orientation: Qt.Vertical
        Pane {
            id: top_pane
            //            Material.background: "#666666"
            visible: thumbnails.model
            SplitView.minimumHeight: 0
            SplitView.preferredHeight: 0
            padding: 5
            ListView {
                id: thumbnails
                objectName: "thumbnails"
                model: 0
                anchors.fill: parent
                orientation: Qt.Horizontal
                spacing: 5
                snapMode: ListView.SnapPosition
                delegate: Rectangle {
                    property int itemIndex: index
                    objectName: "rect" + itemIndex
                    height: thumbnails.height - 10
                    width: childrenRect.width
                    color: thumbnails.currentIndex == index ? "steelblue" : "white"
                    Image {
                        objectName: "thumb_" + parent.itemIndex
                        fillMode: Image.PreserveAspectFit
                        source: "image://imgs/" + objectName + "_"
                        height: parent.height - 3
                        smooth: false
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                thumbnails.currentIndex = parent.parent.itemIndex
                            }
                        }
                    }
                }
                onVisibleChanged: top_pane.visible == true ? top_pane.state = "open" : top_pane.state = ""
                onCurrentIndexChanged: if (currentIndex >= 0) {py_SimulationApp.channel_change(currentIndex)}
                ScrollIndicator.horizontal: ScrollIndicator { objectName: "lol" }
            }

            states: [
                State {
                    name: "open"
                    PropertyChanges {
                        target: top_pane
                        SplitView.preferredHeight: 200
                    }
                }
            ]
            transitions: Transition {
                PropertyAnimation { properties: "SplitView.preferredHeight"; duration: 500}
            }
        }

        Pane {
            id: main_pane
            states: [
                State {
                    name: "spike_mode"
                    PropertyChanges { target: kspaceParameterTab; btnSpikeEnabled: false }
                    PropertyChanges { target: kspaceParameterTab; btnPatchEnabled: false }
                    PropertyChanges { target: kspace_mouse; cursorShape: Qt.CrossCursor }
                },
                State {
                    name: "patch_mode"
                    PropertyChanges { target: kspaceParameterTab; btnSpikeEnabled: false }
                    PropertyChanges { target: kspaceParameterTab; btnPatchEnabled: false }
                    PropertyChanges { target: kspace_mouse; cursorShape: Qt.CrossCursor }
                },
                State {
                    name: "compress_mode"
                    PropertyChanges { target: kspaceParameterTab; btnSpikeEnabled: false }
                    PropertyChanges { target: kspaceParameterTab; btnPatchEnabled: false }
                    PropertyChanges { target: kspace_mouse; cursorShape: Qt.ArrowCursor }
                },
                State {
                    name: "normal_mode"
                    PropertyChanges { target: kspaceParameterTab; btnSpikeEnabled: true }
                    PropertyChanges { target: kspaceParameterTab; btnPatchEnabled: true }
                    PropertyChanges { target: kspace_mouse; cursorShape: Qt.ArrowCursor }
                }
            ]

            BusyIndicator {
                running: dialog_loader.status === Loader.Loading
                anchors.centerIn: parent
                z: 1
            }

            DropArea {
                property int loaded_imgs: 1
                property int curr_img: 1
                id: dropArea
                objectName: "droparea"
                anchors.fill: parent
                enabled: true
                onDropped: {
                    py_SimulationApp.load_new_img(drop.urls);
                }
            }

            GridLayout {
                id: gridLayout
                anchors.fill: parent
                rowSpacing: 10
                columnSpacing: 10
                flow:  width > height ? GridLayout.LeftToRight : GridLayout.TopToBottom

                Item {
                    id: image_item
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    Image {
                        id: image
                        objectName: "image_display"
                        source: "image://imgs/image"
                        sourceSize.width: 100
                        sourceSize.height: 100
                        smooth: false
                        fillMode: Image.PreserveAspectFit
                        anchors.fill: parent
                        visible: true
                        property real ww: 1
                        property real wc: 0.5
                    }

                    MouseArea {
                        z: 2
                        id: image_mouse
                        objectName: "image_mouse"
                        anchors.fill: image
                        acceptedButtons: Qt.AllButtons
                        onPositionChanged: {
                            if (image_mouse.pressedButtons == Qt.RightButton) {
                                image_gamma.contrast = mouseX*2 / parent.width / 3
                                image_gamma.brightness = mouseY*2 / parent.height / 3
                            } else if (image_mouse.pressedButtons == Qt.MiddleButton) {
                                image.ww = mouseX / parent.width;
                                image.wc = mouseY / parent.height;
                                py_SimulationApp.update_displays()
                            }
                        }

                        onDoubleClicked: {
                            image_gamma.contrast = 0
                            image_gamma.brightness = 0
                            image.ww = 1
                            image.wc = 0.5
                            py_SimulationApp.update_displays()
                            kspace_item.visible = !kspace_item.visible
                        }

                        onWheel: {
                            if (wheel.angleDelta.y > 0) {
                                py_SimulationApp.next_img(1)}
                            else {
                                py_SimulationApp.next_img(0)}
                        }
                    }

                    // PySide6 BrightnessContrast replacement
                    Item {
                        z: 1
                        id: image_gamma
                        anchors.fill: image
                        property real brightness: 0.0
                        property real contrast: 0.0
                        property bool cached: false

                        ShaderEffectSource {
                            id: imageSource
                            anchors.fill: parent
                            visible: image_gamma.cached
                            smooth: true
                            sourceItem: image
                            live: true
                            hideSource: visible
                        }

                        ShaderEffect {
                            id: shaderItem
                            property variant source: imageSource
                            property real brightness: image_gamma.brightness
                            property real contrast: image_gamma.contrast

                            anchors.fill: parent
                            blending: !image_gamma.cached

                            fragmentShader: "shaders/brightnesscontrast.frag.qsb"
                        }
                    }

                    Label {
                        id: im_no
                        z: 1
                        color: "lightgray"
                        text: dropArea.curr_img + " / " + dropArea.loaded_imgs
                        visible: (dropArea.loaded_imgs-1)
                        padding: 7
                        background: Rectangle {
                            color: "black"
                            radius: 10
                            anchors.fill: parent
                            opacity: 0.5
                        }
                    }
                }

                Item {
                    id: kspace_item
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    Image {
                        id: kspace
                        objectName: "kspace_display"
                        source: "image://imgs/kspace"
                        smooth: false
                        fillMode: Image.PreserveAspectFit
                        anchors.fill: parent
                        visible: false
                    }

                    MouseArea {
                        id: kspace_mouse
                        //z: 1
                        anchors.centerIn: kspace
                        height: kspace.paintedHeight
                        width: kspace.paintedWidth
                        acceptedButtons: Qt.RightButton | Qt.LeftButton
                        onPositionChanged: {
                            if (kspace_mouse.pressedButtons == Qt.RightButton) {
                                kspace_gamma.gamma = mouseX*2 / parent.width
                            }
                        }
                        onDoubleClicked: {
                            kspace_gamma.gamma = 1
                            image_item.visible = !image_item.visible
                        }
                        onClicked: (mouse)=> {
                            if ((main_pane.state != "normal_mode" && main_pane.state != "compress_mode") && mouse.button === Qt.LeftButton) {
                                var wd_ratio = kspace.paintedWidth/kspace.sourceSize.width;
                                var ht_ratio = kspace.paintedHeight/kspace.sourceSize.height;
                                if (main_pane.state == "spike_mode") {
                                    py_SimulationApp.add_spike((mouseX-1)/wd_ratio, (mouseY-1)/ht_ratio)
                                }
                                else if (main_pane.state == "patch_mode") {
                                    py_SimulationApp.add_patch((mouseX-1)/wd_ratio, (mouseY-1)/ht_ratio, 2)
                                }
                                py_SimulationApp.update_displays()
                                main_pane.state = "normal_mode"
                                drawer.modal && drawer.open()
                            } else if (main_pane.state != "normal_mode" && mouse.button === Qt.RightButton) {
                                main_pane.state = "normal_mode"
                                drawer.modal && drawer.open()
                            }
                        }
                    }

                    // PySide6 GammaAdjust replacement
                    Item {
                        z: 1
                        id: kspace_gamma
                        anchors.fill: kspace
                        property real gamma: 1.0

                        ShaderEffectSource {
                            id: kspaceSource
                            sourceItem: kspace
                        }

                        ShaderEffect {
                            anchors.fill: parent
                            property variant source: kspaceSource
                            property real gamma: 1.0 / Math.max(kspace_gamma.gamma, 0.0001)
                            fragmentShader: "shaders/gammaadjust.frag.qsb"

                        }
                    }
                }
            }

            RoundButton {
                id: button1
                radius: 50
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                onClicked: drawer.visible ? drawer.close() : drawer.open()
                text: "\uF1DE"
                font.family: "fontello"
            }
        }
    }

    Loader {
        id: dialog_loader
        onLoaded: item.visible = true
        asynchronous: true
        function hide(){ sourceComponent = undefined;}
    }

    Component {
        id: aboutDialog_component
        Dialog {
            id: aboutDialog
            modal: true
            focus: true
            title: "ScanHub MRI Device Simulator"
            x: (window.width - width) / 2
            y: window.height / 6
            width: Math.min(window.width, window.height) / 3 * 2
            contentHeight: aboutColumn.height
            onRejected: {dialog_loader.hide(); modal = false}

            RowLayout {
                id: aboutColumn
                spacing: 0
                width: aboutDialog.width - aboutDialog.rightPadding * 2
                Image {
                    source: "../resources/scanhub.ico"
                    fillMode: Image.PreserveAspectFit
                    Layout.fillWidth: true
                }
                ColumnLayout {
                    spacing: 15
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        clip: true
                        text: "ScanHub MRI Device Simulator emulates an MRI device which can connect to ScanHub"
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        clip: true
                        text: 'Homepage: <a href="http://brain-link.de">brain-link.de</a>'
                        //onLinkActivated: Qt.openUrlExternally(link)
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        clip: true
                        text: 'Author & contributors: <a href="https://github.com/brain-link/scanhub-mri-device-simulator#author--contributors">View on GitHub</a>'
                        //onLinkActivated: Qt.openUrlExternally(link)
                    }
                }
            }
        }
    }
}
