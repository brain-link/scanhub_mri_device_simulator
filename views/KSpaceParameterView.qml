import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs


Item {

    property alias btnSpikeEnabed : btnSpike.enabled
    property alias btnPatchEnabled : btnPatch.enabled

    RowLayout {
        spacing: 0
        id: switches
        width: parent.width
        height: toolbar.height


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
                        onCheckedChanged: { py_SimulationApp.update_displays() }
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
                            py_SimulationApp.update_displays()
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
                        onCheckedChanged: py_SimulationApp.update_displays()
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
                    onValueChanged: py_SimulationApp.update_displays()
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
                        py_SimulationApp.update_displays()
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
                    onValueChanged: py_SimulationApp.update_displays()
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

                    onValueChanged: py_SimulationApp.update_displays()
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
                        onValueChanged: py_SimulationApp.update_displays()
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
                            py_SimulationApp.update_displays();
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
                    onValueChanged: py_SimulationApp.update_displays()
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
                            drawer.modal && drawer.close();
                        }
                    }

                    Button {
                        text: "\uE806 " + qsTr("Clear") // icon-trash-empty
                        font.family: "fontello"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        onPressed: {
                            py_SimulationApp.delete_spikes()
                            py_SimulationApp.update_displays()
                        }
                    }
                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uE805" // icon-ccw
                        font.family: "fontello"
                        onPressed: {
                            py_SimulationApp.undo_spike()
                            py_SimulationApp.update_displays()
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
                            drawer.modal && drawer.close();
                        }
                    }

                    Button {
                        id: btnClearPatches
                        text: "\uE806 " + qsTr("Clear") // icon-trash-empty
                        font.family: "fontello"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        onPressed: {
                            py_SimulationApp.delete_patches()
                            py_SimulationApp.update_displays()
                        }
                    }
                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uE805" // icon-ccw
                        font.family: "fontello"
                        onPressed: {
                            py_SimulationApp.undo_patch()
                            py_SimulationApp.update_displays()
                        }
                    }
                }

                Button {
                    id: reset_button
                    text: "\uE805 Reset Defaults" // icon-ccw
                    font.family: "fontello"
                    highlighted: false
                    Layout.rightMargin: 20
                    Layout.alignment: Qt.AlignRight
                    onPressed: {
                        py_SimulationApp.delete_spikes()
                        py_SimulationApp.delete_patches()
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
                    onValueChanged: py_SimulationApp.update_displays()
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
