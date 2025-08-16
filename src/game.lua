local game = {}

    world = nil
    wW = love.graphics:getWidth()
    wH = love.graphics:getHeight()

function game:load()
    love.physics.setMeter(64) --the height of a meter our worlds will be 64px

    world = love.physics.newWorld(0, 2000, false)



    ball = {}
    ball.x = 0
    ball.y = 0
    ball.xVel = 0
    ball.yVel = 0
    ball.body = love.physics.newBody(world, 400, 300, "dynamic")
    ball.body:setFixedRotation(true)
    ball.shape = love.physics.newCircleShape(20)
    ball.fixture = love.physics.newFixture(ball.body, ball.shape)
    walls = {
        left = {
            body  = love.physics.newBody(world, 0, 20, "static"),
            w = 20,
            h = wH - 40
        },
        top = {
            body  = love.physics.newBody(world, 20, 0, "static"),
            w = wW - 40,
            h = 20
        },
        right = {
            body  = love.physics.newBody(world, wW - 20, 20, "static"),
            w = 20,
            h = wH - 40
        },
        bottom = {
            body  = love.physics.newBody(world, 20, wH - 20, "static"),
            w = wW - 40,
            h = 20
        }
    }
    walls.left.shape = love.physics.newRectangleShape(walls.left.w, walls.left.h)
    walls.left.fixture = love.physics.newFixture(walls.left.body, walls.left.shape)
    walls.top.shape = love.physics.newRectangleShape(walls.top.w, walls.top.h)
    walls.top.fixture = love.physics.newFixture(walls.top.body, walls.top.shape)
    walls.right.shape = love.physics.newRectangleShape(walls.right.w, walls.right.h)
    walls.right.fixture = love.physics.newFixture(walls.right.body, walls.right.shape)
    walls.bottom.shape = love.physics.newRectangleShape(walls.bottom.w, walls.bottom.h)
    walls.bottom.fixture = love.physics.newFixture(walls.bottom.body, walls.bottom.shape)
end
function game:update(dt)
    world:update(dt)
    self:syncPhysics()
end

function game:syncPhysics()
    ball.x, ball.y = ball.body:getPosition()
    ball.xVel, ball.yVel = ball.body:getLinearVelocity()
end

function game:draw()
    for _, wall in pairs(walls) do
        love.graphics.rectangle("fill", wall.body:getX(), wall.body:getY(), wall.w, wall.h)
    end
    love.graphics.circle("fill", ball.x, ball.y, ball.shape:getRadius())
end


function game:mousepressed(x, y, button)

    if button == 1 then
        ball.body:setPosition(x, y)
    end

end


return game