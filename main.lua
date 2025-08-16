local SceneryInit = require("src.libs.scenery")
-- wf = require 'src.libs.windfield'

local scenery = SceneryInit(
    { path = "src.menu"; key = "menu";  },
    { path = "src.game"; key = "game";default = "true" }
)

function getDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

scenery:hook(love)
