local SceneryInit = require("src.libs.scenery")
local scenery = SceneryInit(
    { path = "src.menu"; key = "menu"; default = "true" },
    { path = "src.game"; key = "game"; }
)



scenery:hook(love)
