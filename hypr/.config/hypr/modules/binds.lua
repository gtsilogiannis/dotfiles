-- Keybinds. Shell menus and panels are toggled over quickshell IPC.

local terminal    = "kitty"
local fileManager = "nautilus --new-window"
local menu        = "qs ipc call menu toggle launcher"
local browser     = "firefox"

local mainMod = "SUPER"

-- Apps and session
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",      hl.dsp.exec_cmd("~/.config/hypr/scripts/close-window.sh"))
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(terminal .. " -e yazi"))
hl.bind(mainMod .. " + N",      hl.dsp.exec_cmd("qs ipc call controlcenter toggle"))
hl.bind(mainMod .. " + SPACE",  hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + J",      hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + M",      hl.dsp.exit())
hl.bind(mainMod .. " + CTRL + BackSpace", hl.dsp.exec_cmd("~/.config/quickshell/scripts/mode.sh toggle"))
hl.bind(mainMod .. " + BackSpace",        hl.dsp.exec_cmd("~/.config/quickshell/scripts/mode.sh opaque toggle"))

-- Screenshots to the clipboard (full screen, region), lock, power menu, clipboard
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("grim - | wl-copy --type image/png"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy --type image/png"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("~/.config/quickshell/scripts/lock.sh"))
hl.bind("ALT + F4", hl.dsp.exec_cmd("qs ipc call menu toggle power"))
-- Without Fn the laptop F4 key sends XF86AudioMicMute
hl.bind("ALT + XF86AudioMicMute", hl.dsp.exec_cmd("qs ipc call menu toggle power"))
hl.bind("ALT + comma", hl.dsp.exec_cmd("qs ipc call menu toggle clipboard"))

-- Focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Wallpaper picker and workspace overview
hl.bind("SUPER + W", hl.dsp.exec_cmd("qs ipc call menu toggle wallpaper"))
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("qs ipc call menu toggle overview"))

-- Workspaces 1-10 (key 0 is 10): go there, or move the window there
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Move and resize windows with the mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume, brightness and media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
hl.bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl next"),                                 { locked = true })
hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl play-pause"),                            { locked = true })
hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl previous"),                             { locked = true })
