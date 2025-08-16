local SceneryInit = require("src.libs.scenery")
-- wf = require 'src.libs.windfield'

local scenery = SceneryInit(
    { path = "src.menu"; key = "menu";  },
    { path = "src.game"; key = "game";default = "true" }
)



scenery:hook(love)
