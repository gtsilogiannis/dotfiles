-- Curves and animations: lively in browsing mode, calmer in focus mode.

local focus = require("modules.mode").focus

hl.curve("wind",   { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("winIn",  { type = "bezier", points = { {0.1, 1.1},  {0.1, 1.05} } })
hl.curve("winOut", { type = "bezier", points = { {0.3, -0.3}, {0, 1} } })
hl.curve("liner",  { type = "bezier", points = { {0, 0},      {1, 1} } })
hl.curve("calm",   { type = "bezier", points = { {0.25, 1},   {0.5, 1} } })

if focus then
    -- Same motions, shorter and without overshoot; the border stays still
    hl.animation({ leaf = "windows",     enabled = true,  speed = 4, bezier = "calm",  style = "popin 90%" })
    hl.animation({ leaf = "windowsIn",   enabled = true,  speed = 4, bezier = "calm",  style = "popin 90%" })
    hl.animation({ leaf = "windowsOut",  enabled = true,  speed = 3, bezier = "calm",  style = "popin 90%" })
    hl.animation({ leaf = "windowsMove", enabled = true,  speed = 4, bezier = "calm",  style = "slide" })
    hl.animation({ leaf = "border",      enabled = true,  speed = 1, bezier = "liner" })
    hl.animation({ leaf = "borderangle", enabled = false, speed = 1, bezier = "liner" })
    hl.animation({ leaf = "fade",        enabled = true,  speed = 3, bezier = "default" })
    hl.animation({ leaf = "workspaces",  enabled = true,  speed = 4, bezier = "calm",  style = "slidefade 20%" })
else
    hl.animation({ leaf = "windows",     enabled = true, speed = 6,  bezier = "wind",   style = "popin" })
    hl.animation({ leaf = "windowsIn",   enabled = true, speed = 6,  bezier = "winIn",  style = "popin 80%" })
    hl.animation({ leaf = "windowsOut",  enabled = true, speed = 5,  bezier = "winOut", style = "popin 80%" })
    hl.animation({ leaf = "windowsMove", enabled = true, speed = 5,  bezier = "wind",   style = "slide" })
    hl.animation({ leaf = "border",      enabled = true, speed = 1,  bezier = "liner" })
    hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "liner",  style = "loop" })
    hl.animation({ leaf = "fade",        enabled = true, speed = 4,  bezier = "default" })
    hl.animation({ leaf = "workspaces",  enabled = true, speed = 5,  bezier = "wind",   style = "slide" })
end
