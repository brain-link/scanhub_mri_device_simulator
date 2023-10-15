import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs


Item {
  id: connectionItem

  ColumnLayout {
    id: laylayout
    width: parent.width
    anchors.left: parent.left
    anchors.leftMargin: 20
    anchors.right: parent.right
    anchors.rightMargin: 20
    anchors.bottom: parent.bottom
    anchors.top: parent.top
    RowLayout {
        Label {
            text: "uuid"
        }
        TextField {
            id: uuid
            Layout.fillWidth: true
            text: "123456789"
        }
    }
    RowLayout {
        Label {
            text: "ip:port"
        }
        TextField {
            id: ipaddress
            Layout.fillWidth: true
            text: "host.docker.internal:5000"
        }
    }
    RowLayout {
        Label {
            text: "name"
        }
        TextField {
            id: name
            Layout.fillWidth: true
            text: "simulator"
        }
    }
    RowLayout {
        Label {
            text: "manufacturer"
        }
        TextField {
            id: manufacturer
            Layout.fillWidth: true
            text: "brain-link UG (haftungsbeschränkt)"
        }
    }
    RowLayout {
        Label {
            text: "modality"
        }
        TextField {
            id: modality
            Layout.fillWidth: true
            text: "MRI"
        }
    }
    RowLayout {
        Label {
            text: "status"
        }
        TextField {
            id: status
            Layout.fillWidth: true
            text: "new"
        }
    }
    RowLayout {
        Label {
            text: "site"
        }
        TextField {
            id: site
            Layout.fillWidth: true
            text: "Hamburg"
        }
    }

    RowLayout {
        Button {
            text: "Register device"
            onPressed: {
                var json_register = {
                    "command": "register",
                    "ip_address": ipaddress.text,
                    "data": {
                        "id": uuid.text,
                        "name": name.text,
                        "manufacturer": manufacturer.text,
                        "modality": modality.text,
                        "status": status.text,
                        "site": site.text
                    }
                }
                // console.log(JSON.stringify(json_register))
                websocket.sendTextMessage(JSON.stringify(json_register))
            }
        }
        Button {
            text: "Update Status"
            onPressed: {
                var json_register = {
                    "command": "update_status",
                    "ip_address": ipaddress.text,
                    "data": {
                        "id": uuid.text,
                        "status": status.text
                    }
                }
                // console.log(JSON.stringify(json_register))
                websocket.sendTextMessage(JSON.stringify(json_register))
            }
        }
    }
 
    RowLayout {
        Label {
            text: "Status: "
        }
        Label {
            text: {
                if (websocket.status == 0) return "Connecting"
                if (websocket.status == 1) return "Open"
                if (websocket.status == 2) return "Closing"
                if (websocket.status == 3) return "Closed"
                if (websocket.status == 4) return "Error"
            }
        }
    }

    Label {
        id: lastMessageLabel
        text: "Last received message: "
    }

    Flickable {
        id: flickable
        Layout.fillWidth: true
        height: 250
        contentWidth: width
        contentHeight: textArea.implicitHeight

        TextArea.flickable: TextArea {
            id: textArea
            text: ""
            wrapMode: Text.WordWrap
        }
        ScrollBar.vertical: ScrollBar {}
    }

    RowLayout {
        Label {
            text: "Errorstring: "
        }
        Label {
            text: websocket.errorString
        }
    }
  }
}
