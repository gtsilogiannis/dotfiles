-- Desktop mode, written by quickshell/scripts/mode.sh before it reloads Hyprland.
-- Browsing: gradient border, glass windows. Focus: plain border, opaque windows.

local mode = "browsing"
pcall(function()
    local file = io.open(os.getenv("HOME") .. "/.local/state/desktop/mode", "r")
    if file then
        if file:read("*l") == "focus" then mode = "focus" end
        file:close()
    end
end)
local focus = mode == "focus"

-- Browsing only: SUPER + BackSpace (mode.sh opaque) makes the glass windows opaque
local opaque = false
if not focus then
    pcall(function()
        local file = io.open(os.getenv("HOME") .. "/.local/state/desktop/opaque", "r")
        if file then
            opaque = file:read("*l") == "on"
            file:close()
        end
    end)
end

return {
    focus = focus,
    solid = focus or opaque,
}
