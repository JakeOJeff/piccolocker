local game = {}

world = nil
wW = love.graphics.getWidth()
wH = love.graphics.getHeight()

function game:load()
    love.physics.setMeter(64) --the height of a meter our worlds will be 64px

    world = love.physics.newWorld(0, 2000, false)

    draggingBall = false

    ball = {}
    ball.x = 0
    ball.y = 0
    ball.xVel = 0
    ball.yVel = 0
    ball.vx = 0
    ball.vy = 0
    ball.body = love.physics.newBody(world, 400, 300, "dynamic")
    ball.body:setFixedRotation(true)
    ball.shape = love.physics.newCircleShape(20)
    ball.fixture = love.physics.newFixture(ball.body, ball.shape)
    
    walls = {
        left = {
            body  = love.physics.newBody(world, 10, wH/2, "static"), -- centered at x=10, middle of screen height
            w = 20,
            h = wH
        },
        top = {
            body  = love.physics.newBody(world, wW/2, 10, "static"), -- centered at middle of screen width, y=10
            w = wW,
            h = 20
        },
        right = {
            body  = love.physics.newBody(world, wW - 10, wH/2, "static"), -- centered at x=wW-10, middle of screen height
            w = 20,
            h = wH
        },
        bottom = {
            body  = love.physics.newBody(world, wW/2, wH - 10, "static"), -- centered at middle of screen width, y=wH-10
            w = wW,
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

    ball.fixture:setRestitution(0.5)
    for _, wall in pairs(walls) do
        wall.fixture:setRestitution(0.5)
        wall.fixture:setFriction(0.7)
    end
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
    -- Draw walls with proper center-based positioning
    for _, wall in pairs(walls) do
        local wx, wy = wall.body:getPosition()
        love.graphics.rectangle("fill", wx - wall.w/2, wy - wall.h/2, wall.w, wall.h)
    end
    
    -- Draw ball
    love.graphics.circle("fill", ball.x, ball.y, ball.shape:getRadius())

    -- Draw drag line if dragging
    if draggingBall then
        local mx, my = love.mouse.getPosition()
        love.graphics.line(mx, my, ball.x, ball.y)
        love.graphics.circle("line", mx, my, 10)
    end
end

function game:mousepressed(x, y, button)
    if button == 1 then
        -- Check if mouse is within ball radius before starting drag
        local dx = x - ball.x
        local dy = y - ball.y
        local distance = math.sqrt(dx*dx + dy*dy)
        if distance <= ball.shape:getRadius() then
            draggingBall = true
        end
    end
end

function game:mousereleased(x, y, button)
    if button == 1 and draggingBall then
        ball.body:setLinearVelocity((x - ball.x) * -30, (y - ball.y) * -30)
        draggingBall = false
    end
end

return game