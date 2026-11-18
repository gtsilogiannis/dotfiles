-- Each module runs in its own protected call: an error in one of them
-- shows up in `hyprctl configerrors` and the rest still load.

require("modules.monitors")
require("modules.autostart")
require("modules.env")
require("modules.look")
require("modules.animations")
require("modules.input")
require("modules.binds")
require("modules.rules")
