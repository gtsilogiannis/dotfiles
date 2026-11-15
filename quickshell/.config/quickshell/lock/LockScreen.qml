// What one screen of the lock shows, the same layout as the login screen
// (SDDM theme gtsilos): the wallpaper, the side away from its subject blurred
// with a soft fade, and on it the clock, the user and the password field.
// State lives in shell.qml; every screen shows the same password text.
import QtQuick
import QtQuick.Effects
import QtQuick.Controls.Basic

Item {
    id: root

    // Set by shell.qml.
    property url wallpaper
    property bool formRight: true
    property string family: "IBM Plex Sans"
    property string userName: ""
    property string realName: ""
    property url userIcon
    property string password: ""
    property bool busy: false
    property string message: ""
    property bool capsLock: false
    property int failures: 0                   // a change shakes the field

    property color primary: "#adc6ff"
    property color inkOnPrimary: "#102f60"
    property color surface: "#11131a"
    property color ink: "#e1e2eb"
    property color inkMuted: "#c4c6d0"
    property color field: "#272a31"
    property color error: "#ffb4ab"
    property color accent: "#ddbce0"

    signal edited(string text)
    signal submitted()
    signal keyChanged()                         // any key down or up: Caps Lock may have changed

    readonly property real side: width * 0.4                    // width of the blurred side
    readonly property real fade: Math.min(320, side / 2)        // its soft inner edge
    readonly property int corners: 24

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    property date now: new Date()

    // 0 → 1 once at start: blur and form fade in over the sharp wallpaper.
    property real reveal
    NumberAnimation on reveal { from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }

    onFailuresChanged: shake.restart()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // Under the image, and alone if it does not load.
    Rectangle {
        anchors.fill: parent
        color: root.surface
    }

    Image {
        id: wall
        anchors.fill: parent
        source: root.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: false         // in the first frame: the lock never shows the bare color first
        cache: false                // a new wallpaper since the last lock is read again
        smooth: true
    }

    // Alpha of this item decides where the blur shows: 0 over the subject,
    // a linear ramp across `fade` (the effect bends it into a smoothstep),
    // 1 for the rest of the side.
    Item {
        id: blurMask
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            id: maskRect
            width: root.side
            height: parent.height
            x: root.formRight ? parent.width - width : 0
            readonly property real f: root.fade / root.side     // fade as a fraction of the side
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(0, 0, 0, root.formRight ? 0 : 1) }
                GradientStop { position: root.formRight ? maskRect.f : 1 - maskRect.f; color: Qt.rgba(0, 0, 0, 1) }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, root.formRight ? 1 : 0) }
            }
        }
    }

    // The blurred copy of the wallpaper, cut by the mask above.
    MultiEffect {
        anchors.fill: wall
        source: wall
        visible: wall.status === Image.Ready
        opacity: root.reveal
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: 32
        maskEnabled: true
        maskSource: blurMask
        // Shown alpha = smoothstep(min(1 + spread) - spread, min(1 + spread), mask alpha)
        // = smoothstep(0, 1, mask alpha): a soft edge instead of a cut.
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    // A click anywhere gives the keyboard back to the field.
    MouseArea {
        anchors.fill: parent
        onClicked: passwordField.forceActiveFocus()
    }

    Column {
        id: form
        width: 340
        spacing: 0
        opacity: root.reveal
        anchors.verticalCenter: parent.verticalCenter
        // Centered in the fully blurred part of the side, away from the fade.
        x: root.formRight ? parent.width - (root.side - root.fade) / 2 - width / 2 : (root.side - root.fade) / 2 - width / 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, "HH:mm")
            color: root.ink
            font { family: root.family; pixelSize: 112; weight: Font.Light }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.now.toLocaleDateString(Qt.locale(), "dddd, d MMMM")
            color: root.primary
            font { family: root.family; pixelSize: 22; weight: Font.Medium }
        }

        Item { width: 1; height: 64 }

        // Avatar: the AccountsService icon cut to a circle, else the initial.
        Item {
            width: 108
            height: 108
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: root.field
                border { width: 2; color: root.primary }
            }

            Text {
                anchors.centerIn: parent
                visible: face.status !== Image.Ready
                text: (root.realName || root.userName).charAt(0).toUpperCase()
                color: root.primary
                font { family: root.family; pixelSize: 46; weight: Font.Medium }
            }

            Image {
                id: face
                anchors.fill: parent
                anchors.margins: 4
                source: root.userIcon
                sourceSize { width: 200; height: 200 }
                fillMode: Image.PreserveAspectCrop
                visible: false
            }

            Rectangle {
                id: faceMask
                anchors.fill: face
                radius: width / 2
                visible: false
                layer.enabled: true
            }

            MultiEffect {
                anchors.fill: face
                source: face
                visible: face.status === Image.Ready
                maskEnabled: true
                maskSource: faceMask
            }
        }

        Item { width: 1; height: 16 }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.realName || root.userName
            color: root.ink
            font { family: root.family; pixelSize: 22; weight: Font.Medium }
        }

        Item { width: 1; height: 24 }

        TextField {
            id: passwordField
            width: 300
            height: 48
            anchors.horizontalCenter: parent.horizontalCenter
            focus: true
            enabled: !root.busy
            text: root.password                 // shared by every screen
            echoMode: TextInput.Password
            passwordCharacter: "•"
            horizontalAlignment: TextInput.AlignHCenter
            placeholderText: "Password"
            placeholderTextColor: root.inkMuted
            color: root.ink
            selectionColor: root.primary
            selectedTextColor: root.inkOnPrimary
            font { family: root.family; pixelSize: 16 }
            transform: Translate { id: offset }
            background: Rectangle {
                radius: root.corners
                color: root.withAlpha(root.field, 0.85)
                border { width: passwordField.activeFocus ? 2 : 1; color: passwordField.activeFocus ? root.primary : root.withAlpha(root.inkMuted, 0.3) }
            }
            Component.onCompleted: forceActiveFocus()
            onTextEdited: root.edited(text)
            onAccepted: root.submitted()
            Keys.onEscapePressed: root.edited("")
            // Not accepted: the key still types.
            Keys.onPressed: event => root.keyChanged()
            Keys.onReleased: event => root.keyChanged()
        }

        Item { width: 1; height: 14 }

        // Error after a failed attempt, else a Caps Lock warning; the line keeps its height.
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.message !== "" ? root.message : (root.capsLock ? "Caps Lock is on" : (root.busy ? "Unlocking…" : " "))
            color: root.message !== "" ? root.error : (root.capsLock ? root.accent : root.inkMuted)
            font { family: root.family; pixelSize: 14 }
        }
    }

    // Short horizontal shake of the field after a wrong password.
    SequentialAnimation {
        id: shake
        NumberAnimation { target: offset; property: "x"; to: -12; duration: 50 }
        NumberAnimation { target: offset; property: "x"; to: 12; duration: 70 }
        NumberAnimation { target: offset; property: "x"; to: -8; duration: 60 }
        NumberAnimation { target: offset; property: "x"; to: 0; duration: 50 }
    }
}
