// Entry point of the shell: `qs` loads ~/.config/quickshell/shell.qml.
import Quickshell

ShellRoot {
    // One bar per connected screen; bars are created and removed as screens come and go.
    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }

    // Single instances, on the monitor that has focus.
    NotificationPopups {}
    ControlCenter {}
    CalendarPopup {}
    ModeOsd {}

    // No window of its own: plays the video wallpaper on one output, paused while that output shows windows.
    VideoWallpaper {}

    // Bottom layer, only on a depth wallpaper: a clock between the wallpaper and its subject.
    DesktopLayer {}

    // Menus: one at a time, switched through MenuState (qs ipc call menu toggle <name>).
    Launcher {}
    Clipboard {}
    PowerMenu {}
    WallpaperPicker {}
    Overview {}
}
