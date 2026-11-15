// SDDM greeter theme (Qt 6): the wallpaper, one side blurred with a soft fade
// towards the subject, and on it the clock, the user and the password field.
// Keys come from theme.conf, overridden by theme.conf.user (written by
// /usr/local/bin/sddm-set-background from the wallpaper picker).
import QtQuick
import QtQuick.Effects
import QtQuick.Controls.Basic

Item {
    id: root

    width: 1920
    height: 1080

    // A key as a string, or the fallback when it is missing or empty.
    function cfg(key, fallback) {
        const value = config[key];
        return value === undefined || value === null || String(value) === "" ? fallback : String(value);
    }

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // Caps Lock state; `keyboard` is missing in some SDDM builds.
    readonly property bool capsLock: typeof keyboard !== "undefined" && keyboard !== null && keyboard.capsLock

    // An absolute path becomes a file URL; a relative one is read from the theme folder.
    function imageUrl(path) {
        if (path === "")
            return "";
        return path.startsWith("/") ? "file://" + path : Qt.resolvedUrl(path);
    }

    readonly property bool formRight: cfg("FormPosition", "right") !== "left"
    readonly property real side: width * 0.4                    // width of the blurred side
    readonly property real fade: Math.min(320, side / 2)        // its soft inner edge
    readonly property real blurAmount: Math.max(0, Math.min(1, Number(cfg("Blur", "1.0"))))
    readonly property int blurRadius: Math.max(1, Math.min(64, parseInt(cfg("BlurMax", "32"))))
    readonly property int corners: Math.min(24, parseInt(cfg("RoundCorners", "24")))
    readonly property string family: cfg("Font", "IBM Plex Sans")

    readonly property color primary: cfg("PrimaryColor", "#b3c5ff")
    readonly property color inkOnPrimary: cfg("OnPrimaryColor", "#002b75")
    readonly property color surface: cfg("SurfaceColor", "#10131c")
    readonly property color ink: cfg("OnSurfaceColor", "#e0e2ef")
    readonly property color inkMuted: cfg("OnSurfaceVariantColor", "#c4c6d3")
    readonly property color field: cfg("FieldColor", "#272a34")
    readonly property color error: cfg("ErrorColor", "#ffb4ab")
    readonly property color accent: cfg("AccentColor", "#d0bdf6")

    // The user shown: the last one that logged in, else the first in the list.
    property string userName: ""
    property string realName: ""
    property string userIcon: ""
    readonly property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    readonly property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

    property date now: new Date()
    property bool busy: false
    property string message: ""

    function login() {
        if (busy || password.text === "")
            return;
        busy = true;
        message = "";
        sddm.login(userName, password.text, sessionIndex);
    }

    // Reads name / realName / icon of userIndex from the model (no other API for one row).
    Repeater {
        model: userModel
        delegate: Item {
            required property int index
            required property string name
            required property string realName
            required property string icon
            Component.onCompleted: {
                if (index === root.userIndex) {
                    root.userName = name;
                    root.realName = realName;
                    root.userIcon = icon;
                }
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            root.message = "Wrong password";
            password.text = "";
            shake.restart();
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // Shown under the image, and alone when no Background is set.
    Rectangle {
        anchors.fill: parent
        color: root.surface
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: root.imageUrl(root.cfg("Background", ""))
        fillMode: Image.PreserveAspectCrop
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
        anchors.fill: wallpaper
        source: wallpaper
        visible: wallpaper.status === Image.Ready
        autoPaddingEnabled: false
        blurEnabled: true
        blur: root.blurAmount
        blurMax: root.blurRadius
        maskEnabled: true
        maskSource: blurMask
        // Shown alpha = smoothstep(min(1 + spread) - spread, min(1 + spread), mask alpha)
        // = smoothstep(0, 1, mask alpha): a soft edge instead of a cut.
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    Column {
        id: form
        width: 340
        spacing: 0
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
            id: avatar
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
                source: root.userIcon === "" ? "" : root.imageUrl(root.userIcon.replace(/^file:\/\//, ""))
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
            id: password
            width: 300
            height: 48
            anchors.horizontalCenter: parent.horizontalCenter
            focus: true
            enabled: !root.busy
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
                border { width: password.activeFocus ? 2 : 1; color: password.activeFocus ? root.primary : root.withAlpha(root.inkMuted, 0.3) }
            }
            onAccepted: root.login()
            onTextEdited: root.message = ""
            Keys.onEscapePressed: text = ""
        }

        Item { width: 1; height: 14 }

        // Error after a failed login, else a Caps Lock warning; the line keeps its height.
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.message !== "" ? root.message : (root.capsLock ? "Caps Lock is on" : (root.busy ? "Signing in…" : " "))
            color: root.message !== "" ? root.error : (root.capsLock ? root.accent : root.inkMuted)
            font { family: root.family; pixelSize: 14 }
        }
    }

    // Short horizontal shake of the field after a wrong password.
    SequentialAnimation {
        id: shake
        loops: 1
        NumberAnimation { target: offset; property: "x"; to: -12; duration: 50 }
        NumberAnimation { target: offset; property: "x"; to: 12; duration: 70 }
        NumberAnimation { target: offset; property: "x"; to: -8; duration: 60 }
        NumberAnimation { target: offset; property: "x"; to: 0; duration: 50 }
    }
}
