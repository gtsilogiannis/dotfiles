// One Wi-Fi network. Click: disconnect if connected, connect if saved or open,
// ask for the password if new and secured (WPA/WPA2/WPA3 personal).
import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

Rectangle {
    id: row

    required property var network

    property bool askPassword: false
    property string error: ""

    readonly property int security: network.security
    readonly property bool secured: security !== WifiSecurityType.Open && security !== WifiSecurityType.Owe
    // connectWithPsk() only applies to these; enterprise networks (eduroam)
    // need a saved connection made once with nmcli.
    readonly property bool personal: security === WifiSecurityType.WpaPsk
                                  || security === WifiSecurityType.Wpa2Psk
                                  || security === WifiSecurityType.Sae
    readonly property real strength: network.signalStrength

    function activate() {
        row.error = "";
        if (row.network.stateChanging) return;
        if (row.network.connected) row.network.disconnect();
        else if (row.network.known || !row.secured) row.network.connect();
        else if (row.personal) { row.askPassword = true; password.forceActiveFocus(); }
        else row.error = "Enterprise network: set it up once with nmcli";
    }

    function submit() {
        if (password.text === "") return;
        row.network.connectWithPsk(password.text);
        password.text = "";
        row.askPassword = false;
    }

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight + 16
    radius: 12
    color: area.containsMouse ? Qt.alpha(Theme.surfaceContainerHigh, 0.95) : Qt.alpha(Theme.surfaceContainerHigh, 0.6)

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.activate()
    }

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8; leftMargin: 12; rightMargin: 12 }
        spacing: 8

        RowLayout {
            spacing: 12
            Layout.fillWidth: true

            MaterialIcon {
                icon: row.strength > 0.75 ? "signal_wifi_4_bar"
                    : row.strength > 0.5 ? "network_wifi_3_bar"
                    : row.strength > 0.25 ? "network_wifi_2_bar"
                    : "network_wifi_1_bar"
                filled: row.network.connected
                color: row.network.connected ? Theme.primary : Theme.surfaceText
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Label {
                    text: row.network.name
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Label {
                    text: row.error !== "" ? row.error
                        : row.network.stateChanging ? (row.network.connected ? "Disconnecting…" : "Connecting…")
                        : row.network.connected ? "Connected"
                        : row.network.known ? "Saved"
                        : row.secured ? "Secured" : "Open"
                    color: row.error !== "" ? Theme.error
                         : row.network.connected ? Theme.primary
                         : Theme.surfaceTextMuted
                    font.pixelSize: Theme.fontSize - 1
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            MaterialIcon {
                visible: row.secured
                icon: "lock"
                color: Theme.surfaceTextMuted
                font.pixelSize: 15
            }

            MaterialIcon {     // forget a saved network
                visible: row.network.known && area.containsMouse
                icon: "delete"
                color: forgetArea.containsMouse ? Theme.error : Theme.surfaceTextMuted
                MouseArea {
                    id: forgetArea
                    anchors { fill: parent; margins: -6 }
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: row.network.forget()
                }
            }
        }

        // Password field, shown for a new secured network or after a rejected password.
        Rectangle {
            visible: row.askPassword
            Layout.fillWidth: true
            implicitHeight: 36
            radius: 10
            color: Qt.alpha(Theme.surface, 0.8)
            border.width: 1
            border.color: password.activeFocus ? Theme.primary : Theme.outlineVariant

            RowLayout {
                anchors { fill: parent; leftMargin: 10; rightMargin: 6 }
                spacing: 6

                TextInput {
                    id: password
                    Layout.fillWidth: true
                    echoMode: reveal.on ? TextInput.Normal : TextInput.Password
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    clip: true

                    Keys.onReturnPressed: row.submit()
                    Keys.onEnterPressed: row.submit()
                    Keys.onEscapePressed: { password.text = ""; row.askPassword = false; }

                    Label {
                        visible: password.text === ""
                        text: "Password"
                        color: Theme.surfaceTextMuted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MaterialIcon {
                    id: reveal
                    property bool on: false
                    icon: on ? "visibility_off" : "visibility"
                    color: Theme.surfaceTextMuted
                    MouseArea {
                        anchors { fill: parent; margins: -4 }
                        cursorShape: Qt.PointingHandCursor
                        onClicked: reveal.on = !reveal.on
                    }
                }
                MaterialIcon {
                    icon: "arrow_forward"
                    color: Theme.primary
                    MouseArea {
                        anchors { fill: parent; margins: -4 }
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.submit()
                    }
                }
            }
        }
    }

    // A wrong or missing password comes back as NoSecrets: ask (again).
    Connections {
        target: row.network
        function onConnectionFailed(reason) {
            if (reason === ConnectionFailReason.NoSecrets && row.personal) {
                row.error = row.network.known ? "Wrong password" : "";
                row.askPassword = true;
                password.forceActiveFocus();
            } else {
                row.error = "Connection failed";
            }
        }
    }
}
