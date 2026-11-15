// Lock screen: its own qs instance, started by scripts/lock.sh and gone
// once unlocked. One LockScreen per screen (ext-session-lock through
// WlSessionLock), the password checked by PAM with pam/password.conf.
// Colors from the matugen file of the shell, the background from the
// still of the current wallpaper, the form side from set-wallpaper.sh.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string userName: Quickshell.env("USER") ?? ""
    property string realName: ""

    property string password: ""
    property bool busy: false
    property string message: ""
    property bool capsLock: false
    property int failures: 0

    property var scheme: ({})
    function pick(key, fallback) {
        const value = root.scheme[key];
        return (typeof value === "string" && value.length > 0) ? value : fallback;
    }

    function submit() {
        if (root.busy || root.password === "")
            return;
        root.busy = true;
        root.message = "";
        if (!pam.start()) {
            root.busy = false;
            root.message = "Could not start PAM";
        }
    }

    PamContext {
        id: pam
        configDirectory: "pam"          // relative to this file
        config: "password.conf"

        // pam_unix asks once, for the password.
        onPamMessage: {
            if (pam.responseRequired)
                pam.respond(root.password);
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                lock.locked = false;
                quit.start();
                return;
            }
            root.busy = false;
            root.password = "";
            root.message = result === PamResult.Failed ? "Wrong password" : "Authentication error";
            root.failures++;
        }
    }

    // Exits only after the unlock has been sent: quitting while locked
    // would leave the screens locked, painted in a plain color.
    Timer {
        id: quit
        interval: 200
        onTriggered: Qt.quit()
    }

    WlSessionLock {
        id: lock
        locked: true

        WlSessionLockSurface {
            id: surface
            color: root.pick("surface", "#11131a")

            LockScreen {
                anchors.fill: parent
                wallpaper: "file://" + root.home + "/.cache/current_wallpaper.png"
                formRight: sideFile.text().trim() !== "left"
                userName: root.userName
                realName: root.realName
                userIcon: "file:///var/lib/AccountsService/icons/" + root.userName
                password: root.password
                busy: root.busy
                message: root.message
                capsLock: root.capsLock
                failures: root.failures

                primary: root.pick("primary", "#adc6ff")
                inkOnPrimary: root.pick("on_primary", "#102f60")
                surface: root.pick("surface", "#11131a")
                ink: root.pick("on_surface", "#e1e2eb")
                inkMuted: root.pick("on_surface_variant", "#c4c6d0")
                field: root.pick("surface_container_high", "#272a31")
                error: root.pick("error", "#ffb4ab")
                accent: root.pick("tertiary", "#ddbce0")

                onEdited: text => {
                    root.password = text;
                    root.message = "";
                }
                onSubmitted: root.submit()
                onKeyChanged: caps.check()
            }
        }
    }

    // Colors of the shell, written by matugen.
    FileView {
        path: root.home + "/.config/quickshell/colors.json"
        blockLoading: true
        onLoaded: {
            try {
                root.scheme = JSON.parse(text());
            } catch (e) {
                console.warn("lock: colors.json could not be parsed, using the fallback colors");
            }
        }
    }

    // "left" or "right", written by set-wallpaper.sh with each new wallpaper.
    FileView {
        id: sideFile
        path: root.home + "/.cache/current_wallpaper.side"
        blockLoading: true
        printErrors: false
    }

    // The full name (GECOS) of the user, as on the login screen.
    Process {
        running: true
        command: ["getent", "passwd", root.userName]
        stdout: StdioCollector {
            onStreamFinished: root.realName = (text.split(":")[4] ?? "").split(",")[0]
        }
    }

    // Caps Lock, read again after every key press and release (the release
    // of Caps Lock itself comes after the change). On if any keyboard has it:
    // the main one is the last one used, not always the one typed on.
    Process {
        id: caps
        property bool again: false
        function check() {
            if (caps.running)
                caps.again = true;          // once more after this run, with the newer state
            else
                caps.running = true;
        }
        onExited: (exitCode, exitStatus) => {
            if (caps.again) {
                caps.again = false;
                Qt.callLater(() => caps.running = true);
            }
        }
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const keyboards = JSON.parse(text).keyboards;
                    root.capsLock = keyboards.some(k => k.capsLock === true);
                } catch (e) {
                    root.capsLock = false;
                }
            }
        }
    }
}
