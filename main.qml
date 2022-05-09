import QtQuick
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

    Text {
        anchors.centerIn: parent
        text: "Hello World"
        font.pixelSize: 24
    }

}
