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
        onActivated: drawer_right.open()
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
            anchors.rightMargin: !drawer_right.modal ? drawer_right.width : undefined

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
                            py_MainApp.load_new_img(fileUrls)
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
                ToolTip.text: qsTr("Save as images (Ctrl + S)")
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
                        nameFilters: [ "PNG file (*.png)", "Floating point TIFF (*.tiff)" ]
                        title: qsTr("Save image files")
                        //: Save dialog title bar
                        onAccepted: {
                            py_MainApp.save_img(fileUrl)
                            dialog_loader.hide()
                            }
                        onRejected: dialog_loader.hide()
                    }
                }
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
                Component {
                    id: saveDialogKSpaceComponent
                    FileDialog {
                        id: saveKSpaceDialog
                        fileMode: FileDialog.SaveFile
                        nameFilters: [ "NPY file (*.npy)" ]
                        title: qsTr("Save k-Space files")
                        //: Save dialog title bar
                        onAccepted: {
                            py_MainApp.save_kspace(fileUrl)
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
        RowLayout {
            anchors.rightMargin: !drawer_right.modal ? drawer_right.width : undefined
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
                text: play_anim.running ? "\uE804" : "\uE803" // icon-pause : icon-play
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

    Drawer {
        id: drawer_right
        width: narrowWindow ? window.width : 400
        height: window.height
        edge: Qt.RightEdge
        modal: !pin.checked
        interactive: !pin.checked

        RowLayout {
            spacing: 0
            id: switches
            width: parent.width
            height: toolbar.height

            Switch {
                id: pin
                onCheckedChanged: pin.checked ? split_view.state= "drawer_pinned" : split_view.state= "drawer_unpinned"
                text: "Pin sidebar"
                //: Right drawer switch button text
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft
                visible: narrowWindow ? false : true
                onVisibleChanged: checked = false
            }

            Button {
                id: reset_button
                text: "\uE805" // icon-ccw
                font.family: "fontello"
                highlighted: false
                Layout.rightMargin: 20
                Layout.alignment: Qt.AlignRight
                onPressed: {
                    py_MainApp.delete_spikes()
                    py_MainApp.delete_patches()
                    partial_fourier_slider.value = partial_fourier_slider.default_value
                    zero_fill.checked = zero_fill.default_value
                    noise_slider.value = noise_slider.default_value
                    rdc_slider.value = rdc_slider.default_value
                    high_pass_slider.value = high_pass_slider.default_value
                    low_pass_slider.value = low_pass_slider.default_value
                    compress.checked = compress.default_value
                    decrease_dc.value = decrease_dc.default_value
                    undersample_kspace.value = undersample_kspace.default_value
                    ksp_const.value = ksp_const.default_value
                    hamming.checked = hamming.default_value
                    smooth.checked = smooth.default_value
                }
            }
        }

        Flickable {
            id: flickable_controls
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: switches.bottom
            contentHeight: root.implicitHeight
            clip: true

            Pane {
                id: root
                anchors.fill: parent

                Column {
                    id: controlsColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10

                    Label {
                        id: controls_title
                        topPadding: 30
                        leftPadding: 15
                        rightPadding: 15
                        bottomPadding: 30
                        anchors.left: parent.left
                        anchors.right: parent.right
                        text: qsTr("modify k-space")
                        //: Right drawer title label
                        font.pixelSize: 25
                        font.bold: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        font.capitalization: Font.AllUppercase
                    }

                    RowLayout {
                        width: parent.width
                        Switch {
                            property bool default_value: false
                            id: smooth
                            text: "Smooth image"
                            //: Right drawer Smoothing Filter switch text
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft
                            onCheckedChanged: image.smooth = !image.smooth
                        }
                        Switch {
                            property bool default_value: false
                            id: hamming
                            text: qsTr("Hamming window")
                            //: Right drawer switch button text
                            objectName: "hamming"
                            Layout.alignment: Qt.AlignLeft
                            checked: false
                            onCheckedChanged: { py_MainApp.update_displays() }
                        }
                    }

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        Slider {
                            property var desc: qsTr("Reducing the scan time by scanning fewer lines of the k-space in phase direction. The remaining lines are either filled with zeroes or using a property of the k-space called conjugate symmetry. This means that in theory, k-space quadrants are symmetric i.e. a point in the top left corner equals the one in the bottom right corner (with the opposite sign of the imaginary part of the complex value.)")
                            property int default_value: 100
                            id: partial_fourier_slider
                            objectName: "partial_fourier_slider"
                            Layout.fillWidth: true
                            height: 48
                            from: 0
                            to: 100
                            stepSize: 1
                            value: 100
                            onHoveredChanged: {
                                descLabel.text = desc
                                descriptionPane.shown = !descriptionPane.shown;
                            }
                            onValueChanged: {
                                value == to ? rdc_slider.enabled = true : rdc_slider.enabled = false
                                py_MainApp.update_displays()
                            }
                            Label {
                                leftPadding: 5
                                anchors.left: parent.left
                                text: qsTr("Partial Fourier")
                                //: Right drawer slider label
                            }
                            ToolTip {
                                parent: partial_fourier_slider.handle
                                visible: partial_fourier_slider.pressed
                                text: partial_fourier_slider.value.toFixed(1)
                            }
                        }

                        CheckBox {
                            property bool default_value: false
                            id: zero_fill
                            objectName: "zero_fill"
                            checked: false
                            text: qsTr("Zero Fill")
                            onCheckedChanged: py_MainApp.update_displays()
                        }
                    }

                    Slider {
                        property var desc: qsTr("Image noise is a random granular pattern in the detected signal. It does not add value to the image due to its randomness. Noise can originate from the examined body itself (random thermal motion of atoms) or the electronic equipment used to detect signals. The signal-to-noise ratio is used to describe the relation between the useful signal and the random noise. This slider adds noise to the image to simulate the new signal-to-noise ratio SNR[dB]=20log₁₀(𝑆/𝑁) where 𝑆 is the mean signal and 𝑁 is the standard deviation of the noise.")
                        property int default_value: 30
                        id: noise_slider
                        objectName: "noise_slider"
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 48
                        from: -30
                        to: 30
                        value: 30
                        onHoveredChanged: {
                            descLabel.text = desc
                            descriptionPane.shown = !descriptionPane.shown;
                        }
                        onValueChanged: py_MainApp.update_displays()
                        Label {
                            leftPadding: 5
                            text: qsTr("Signal to Noise (dB)")
                        }
                        ToolTip {
                            parent: noise_slider.handle
                            visible: noise_slider.pressed
                            text: noise_slider.value.toFixed(1)
                        }
                    }

                    Slider {
                        property var desc: qsTr("Scan percentage is a k-space shutter which skips certain number of lines at the edges in phase encoding direction. This parameter is only available on certain manufacturers' scanners.")
                        property int default_value: 100
                        id: rdc_slider
                        objectName: "rdc_slider"
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 48
                        from: 0
                        to: 100
                        value: 100
                        onHoveredChanged: {
                            descLabel.text = desc
                            descriptionPane.shown = !descriptionPane.shown;
                        }
                        onValueChanged: {
                            value == to ? partial_fourier_slider.enabled = true : partial_fourier_slider.enabled = false
                            py_MainApp.update_displays()
                        }
                        Label {
                            leftPadding: 5
                            anchors.left: parent.left
                            text: qsTr("Scan Percentage")
                        }
                        ToolTip {
                            parent: rdc_slider.handle
                            visible: rdc_slider.pressed
                            text: rdc_slider.value.toFixed(1)
                        }
                    }

                    Slider {
                        property var desc: qsTr("The high pass filter keeps only the periphery of the k-space. The periphery contains the information about the details and edges in the image domain, while the overall contrast of the image is lost with the centre of the k-space.")
                        property int default_value: 0
                        id: high_pass_slider
                        objectName: "high_pass_slider"
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 48
                        from: 0
                        to: 100
                        stepSize: 0.1
                        value: 0
                        onHoveredChanged: {
                            descLabel.text = desc
                            descriptionPane.shown = !descriptionPane.shown;
                        }
                        onValueChanged: py_MainApp.update_displays()
                        Label {
                            leftPadding: 5
                            text: qsTr("High Pass Filter")
                        }
                        ToolTip {
                            parent: high_pass_slider.handle
                            visible: high_pass_slider.pressed
                            text: high_pass_slider.value.toFixed(1)
                        }
                    }

                    Slider {
                        property var desc: qsTr("The low pass filter keeps only the centre of the k-space. The centre contains the overall contrast in image domain, while the details of the image are lost with the periphery of the k-space.")
                        property int default_value: 100
                        id: low_pass_slider
                        objectName: "low_pass_slider"
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 48
                        from: 0
                        to: 100
                        stepSize: 0.1
                        value: 100
                        onHoveredChanged: {
                            descLabel.text = desc
                            descriptionPane.shown = !descriptionPane.shown;
                        }

                        onValueChanged: py_MainApp.update_displays()
                        Label {
                            leftPadding: 5
                            anchors.left: parent.left
                            text: qsTr("Low Pass Filter")
                        }
                        ToolTip {
                            parent: low_pass_slider.handle
                            visible: low_pass_slider.pressed
                            text: low_pass_slider.value.toFixed(1)
                        }
                    }

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        Slider {
                            property int default_value: 1
                            property var desc: qsTr("Simulates acquiring every 𝑛th (where 𝑛 is the acceleration factor) line of k-space, starting from the midline. Commonly used in the SENSE algorithm.")
                            id: undersample_kspace
                            objectName: "undersample_kspace"
                            Layout.fillWidth: true
                            height: 48
                            from: 1
                            to: 16
                            stepSize: 1
                            value: 1
                            onHoveredChanged: {
                                descLabel.text = desc
                                descriptionPane.shown = !descriptionPane.shown;
                            }
                            onValueChanged: py_MainApp.update_displays()
                            Label {
                                leftPadding: 5
                                anchors.left: parent.left
                                text: qsTr("Undersample k-space")
                            }
                            ToolTip {
                                parent: undersample_kspace.handle
                                visible: undersample_kspace.pressed
                                text: undersample_kspace.value
                            }
                        }
                        CheckBox {
                            property bool default_value: false
                            id: compress
                            objectName: "compress"
                            checked: false
                            text: qsTr("Compress")
                            onCheckedChanged: {
                                py_MainApp.update_displays();
                                if (checked) {
                                    main_pane.state = "compress_mode";
                                } else {
                                    main_pane.state = "normal_mode";
                                }
                            }
                        }
                    }

                    Slider {
                        property int default_value: 0
                        property var desc: qsTr("Decreases the amplitude of the highest peak in k-space (DC signal)")
                        id: decrease_dc
                        objectName: "decrease_dc"
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 48
                        from: 0
                        to: 100
                        stepSize: 1
                        value: 0
                        onHoveredChanged: {
                            descLabel.text = desc
                            descriptionPane.shown = !descriptionPane.shown;
                        }
                        onValueChanged: py_MainApp.update_displays()
                        Label {
                            leftPadding: 5
                            anchors.left: parent.left
                            text: qsTr("Decrease DC signal")
                        }
                        ToolTip {
                            parent: decrease_dc.handle
                            visible: decrease_dc.pressed
                            text: decrease_dc.value + "%"
                        }
                    }

                    GridLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        columns: 3
                        Button {
                            id: btnSpike
                            text: "\uE807 " + qsTr("Add spike") // icon-plus
                            font.family: "fontello"
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillWidth: true
                            onPressed: {
                                main_pane.state = "spike_mode";
                                drawer_right.modal && drawer_right.close();
                            }
                        }

                        Button {
                            text: "\uE806 " + qsTr("Clear") // icon-trash-empty
                            font.family: "fontello"
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillWidth: true
                            onPressed: {
                                py_MainApp.delete_spikes()
                                py_MainApp.update_displays()
                            }
                        }
                        Button {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uE805" // icon-ccw
                            font.family: "fontello"
                            onPressed: {
                                py_MainApp.undo_spike()
                                py_MainApp.update_displays()
                            }
                        }

                        Button {
                            id: btnPatch
                            text: "\uF12D " + qsTr("Add patch") // icon-eraser
                            font.family: "fontello"
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillWidth: true
                            onPressed: {
                                main_pane.state = "patch_mode";
                                drawer_right.modal && drawer_right.close();
                            }
                        }

                        Button {
                            id: btnClearPatches
                            text: "\uE806 " + qsTr("Clear") // icon-trash-empty
                            font.family: "fontello"
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillWidth: true
                            onPressed: {
                                py_MainApp.delete_patches()
                                py_MainApp.update_displays()
                            }
                        }
                        Button {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uE805" // icon-ccw
                            font.family: "fontello"
                            onPressed: {
                                py_MainApp.undo_patch()
                                py_MainApp.update_displays()
                            }
                        }
                    }

                    Label {
                        id: display_title
                        topPadding: 30
                        leftPadding: 15
                        rightPadding: 15
                        bottomPadding: 30
                        anchors.left: parent.left
                        anchors.right: parent.right
                        text: qsTr("display options")
                        font.pixelSize: 20
                        font.bold: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        font.capitalization: Font.AllUppercase
                    }

                    Slider {
                        property int default_value: -3
                        id: ksp_const
                        objectName: "ksp_const"
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 48
                        from: -10
                        to: 10
                        stepSize: 1
                        value: -3
                        onValueChanged: py_MainApp.update_displays()
                        Label {
                            leftPadding: 5
                            anchors.left: parent.left
                            text: qsTr("K-space scaling constant (10ⁿ)")
                        }
                        ToolTip {
                            parent: ksp_const.handle
                            visible: ksp_const.pressed
                            text: ksp_const.value
                        }
                    }

                    Pane {
                        id: descriptionPane
                        parent: flickable_controls
                        property bool shown: false
                        visible: height > 0
                        z: 1
                        height: shown ? implicitHeight : 0
                        onHoveredChanged: shown = !shown
                        Behavior on height {
                            SequentialAnimation {
                                PauseAnimation { duration: 5 }
                                NumberAnimation { easing.type: Easing.InOutQuad }
                            }
                        }
                        clip: true
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        background: Rectangle { color: "#eeeeee" }
                        Label {
                            id: descLabel
                            anchors.left: parent.left
                            anchors.right: parent.right
                            padding: 5
                            text: qsTr("The low pass filter keeps only the centre of the k-space. The centre contains the overall contrast in image domain, while the details of the image are lost with the periphery of the k-space.")
                            font.pixelSize: 16
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignJustify
                        }
                    }
                }
            }

            ScrollIndicator.vertical: ScrollIndicator { }
        }
    }

    SplitView {
        id: split_view
        anchors.fill: parent
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
                onCurrentIndexChanged: if (currentIndex >= 0) {py_MainApp.channel_change(currentIndex)}
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
            //            Material.background: "#333333"
            states: [
                State {
                    name: "spike_mode"
                    PropertyChanges { target: btnSpike; enabled: false }
                    PropertyChanges { target: btnPatch; enabled: false }
                    PropertyChanges { target: kspace_mouse; cursorShape: Qt.CrossCursor }
                },
                State {
                    name: "patch_mode"
                    PropertyChanges { target: btnSpike; enabled: false }
                    PropertyChanges { target: btnPatch; enabled: false }
                    PropertyChanges { target: kspace_mouse; cursorShape: Qt.CrossCursor }
                },
                State {
                    name: "compress_mode"
                    PropertyChanges { target: btnSpike; enabled: false }
                    PropertyChanges { target: btnPatch; enabled: false }
                    PropertyChanges { target: kspace_mouse; cursorShape: Qt.ArrowCursor }
                },
                State {
                    name: "normal_mode"
                    PropertyChanges { target: btnSpike; enabled: true }
                    PropertyChanges { target: btnPatch; enabled: true }
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
                    py_MainApp.load_new_img(drop.urls);
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
                                py_MainApp.update_displays()
                            }
                        }

                        onDoubleClicked: {
                            image_gamma.contrast = 0
                            image_gamma.brightness = 0
                            image.ww = 1
                            image.wc = 0.5
                            py_MainApp.update_displays()
                            kspace_item.visible = !kspace_item.visible
                        }

                        onWheel: {
                            if (wheel.angleDelta.y > 0) {
                                py_MainApp.wheel_img(1)}
                            else {
                                py_MainApp.wheel_img(0)}
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
                                    py_MainApp.add_spike((mouseX-1)/wd_ratio, (mouseY-1)/ht_ratio)
                                }
                                else if (main_pane.state == "patch_mode") {
                                    py_MainApp.add_patch((mouseX-1)/wd_ratio, (mouseY-1)/ht_ratio, 2)
                                }
                                py_MainApp.update_displays()
                                main_pane.state = "normal_mode"
                                drawer_right.modal && drawer_right.open()
                            } else if (main_pane.state != "normal_mode" && mouse.button === Qt.RightButton) {
                                main_pane.state = "normal_mode"
                                drawer_right.modal && drawer_right.open()
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
                anchors.right: parent.right
                onClicked: drawer_right.open()
                text: "\uF1DE"
                font.family: "fontello"
            }
        }

        states: State {
            name: "drawer_pinned"
            PropertyChanges { target: split_view; anchors.rightMargin : drawer_right.width }
        }
        State {
            name: "drawer_unpinned"
            PropertyChanges { target: split_view; anchors.rightMargin : undefined }
        }

        transitions: Transition {
            PropertyAnimation { properties: "anchors.rightMargin"; easing.type: Easing.InOutQuad }
        }
    }

    Loader {
        id: dialog_loader
        onLoaded: item.visible = true
        asynchronous: true
        function hide(){ sourceComponent = undefined;}
    }

    Component {
        id: settingsDialog_component
        Dialog {
            id: settingsDialog
            x: Math.round((window.width - width) / 2)
            y: Math.round(window.height / 6)
            width: Math.round(Math.min(window.width, window.height) / 3 * 2)
            modal: true
            focus: true
            title: qsTr("Settings")

            standardButtons: Dialog.Ok | Dialog.Cancel
            onAccepted: {
                py_MainApp.retranslate(languageBox.displayText)
                settingsDialog.close()
                modal = false //if not set, cursor will not change in Spikemode()
                dialog_loader.hide()
            }
            onRejected: {
                languageBox.currentIndex = languageBox.langIndex
                settingsDialog.close()
                modal = false
                dialog_loader.hide()
            }

            contentItem: ColumnLayout {
                id: settingsColumn
                spacing: 20

                RowLayout {
                    spacing: 10

                    Label {
                        text: "Language:"
                    }

                    ListModel {
                        id: availableLanguages
                        ListElement { text: "English (UK)" }
                    }

                    ComboBox {
                        id: languageBox
                        property int langIndex: -1
                        model: availableLanguages
                        Layout.fillWidth: true
                        Component.onCompleted: {
                            langIndex = find(availableLanguages.get[currentIndex], Qt.MatchFixedString)
                            if (langIndex !== -1)
                                currentIndex = langIndex
                        }
                    }
                }

                Label {
                    text: "Restart required"
                    color: "#e41e25"
                    opacity: languageBox.currentIndex !== languageBox.langIndex ? 1.0 : 0.0
                    horizontalAlignment: Label.AlignHCenter
                    verticalAlignment: Label.AlignVCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
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