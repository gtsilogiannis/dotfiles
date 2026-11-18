-- Runs once per session; `hyprctl reload` does not fire hyprland.start again.

hl.on("hyprland.start", function ()
    hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent &")
    hl.exec_cmd("awww-daemon --format xrgb &")
    hl.exec_cmd("sleep 1 && awww img ~/.cache/current_wallpaper.png &")
    hl.exec_cmd("qs &")
    hl.exec_cmd("hypridle &")
    hl.exec_cmd("wl-paste --type text --watch cliphist store &")
    hl.exec_cmd("wl-paste --type image --watch cliphist store &")
    -- Back to browsing mode; reloads Hyprland if the last session ended in focus
    hl.exec_cmd("sleep 2 && ~/.config/quickshell/scripts/mode.sh init &")
end)
