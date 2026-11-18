-- Window rules.

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class    = "^$",
        title    = "^$",
        xwayland = true,
        float    = true,
    },
    no_focus = true,
})

-- pavucontrol, opened from the bar volume pill: a small panel under the bar
hl.window_rule({
    name  = "pavucontrol-panel",
    match = { class = [[^(pavucontrol|org\.pulseaudio\.pavucontrol)$]] },
    float = true,
    pin   = true,
    size  = { 640, 450 },
    move  = { "monitor_w-655", "42" },
})

-- Video, images, documents, the browser and Spotify stay opaque in every mode
hl.window_rule({
    name    = "always-opaque",
    match   = { class = [[^(mpv|org\.gnome\.Loupe|org\.gnome\.Evince|evince|ONLYOFFICE|DesktopEditors|firefox|[Ss]potify)$]] },
    opacity = "1.0 override 1.0 override",
})
