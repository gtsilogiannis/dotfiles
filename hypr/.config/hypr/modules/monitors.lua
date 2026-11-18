-- Laptop panel, the AOC to its right, and a default for anything else.

hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@144",
    position = "auto",
    scale    = "1",
    vrr      = 0,
})

hl.monitor({
    output   = "desc:AOC 24G2WG3", -- description prefix: model only, no serial
    mode     = "1920x1080@144",
    position = "auto-right",
    scale    = "1",
    vrr      = 0,
})

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto-right",
    scale    = "1",
})
