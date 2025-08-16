game = {}

world = nil
wW = love.graphics.getWidth()
wH = love.graphics.getHeight()
love.graphics.setDefaultFilter("nearest", "nearest")

function game:load()
    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 2000, false)
    world:setCallbacks(beginContact, endContact)

    draggingBall = false
    rangeVal = 0

    ball = {}
    ball.x = 0
    ball.y = 0
    ball.xVel = 0
    ball.yVel = 0
    ball.vx = 0
    ball.vy = 0
    ball.img = love.graphics.newImage("assets/ball.png")
    ball.body = love.physics.newBody(world, 100, 800, "dynamic")
    ball.shape = love.physics.newCircleShape(60)
    ball.fixture = love.physics.newFixture(ball.body, ball.shape)

    walls = {
        left = {
            body = love.physics.newBody(world, 10, wH / 2, "static"),
            w = 20,
            h = wH
        },
        top = {
            body = love.physics.newBody(world, wW / 2, 10, "static"),
            w = wW,
            h = 20
        },
        right = {
            body = love.physics.newBody(world, wW - 10, wH / 2, "static"),
            w = 20,
            h = wH
        },
        bottom = {
            body = love.physics.newBody(world, wW / 2, wH - 10, "static"),
            w = wW,
            h = 20
        }
    }

    -- Create wall shapes and fixtures
    for _, wall in pairs(walls) do
        wall.shape = love.physics.newRectangleShape(wall.w, wall.h)
        wall.fixture = love.physics.newFixture(wall.body, wall.shape)
        wall.fixture:setRestitution(0.5)
        wall.fixture:setFriction(0.7)
    end

    ball.fixture:setRestitution(0.5)

    -- Create blocks with proper fixture-to-block mapping
    blocks = {}
    fixtureToBlock = {} -- This will map fixtures to block objects
    
    local blockIndex = 1
    for i = 1, 4 do
        for j = 1, 5 do
            blocks[blockIndex] = {
                body = love.physics.newBody(world, j * 200, i * 100, "static"),
                shape = love.physics.newRectangleShape(185, 75),
                img = love.graphics.newImage("assets/blocks/" .. i .. ".png"),
                destroyed = false 
            }
            blocks[blockIndex].fixture = love.physics.newFixture(blocks[blockIndex].body, blocks[blockIndex].shape)
            
            -- Map the fixture to this block for collision detection
            fixtureToBlock[blocks[blockIndex].fixture] = blocks[blockIndex]
            
            blockIndex = blockIndex + 1
        end
    end
end

function game:update(dt)
    world:update(dt)
    self:syncPhysics()
    if draggingBall then
        local mx, my = love.mouse.getPosition()
        local dx = mx - ball.x
        local dy = my - ball.y
        local distance = math.sqrt(dx * dx + dy * dy)
        rangeVal = math.max(0, math.min(1, distance / 1500))
    end
end

function game:syncPhysics()
    ball.x, ball.y = ball.body:getPosition()
    ball.xVel, ball.yVel = ball.body:getLinearVelocity()
end

function game:draw()
    -- Draw walls
    for _, wall in pairs(walls) do
        local wx, wy = wall.body:getPosition()
        love.graphics.rectangle("fill", wx - wall.w / 2, wy - wall.h / 2, wall.w, wall.h)
    end

    -- Draw ball
    love.graphics.draw(ball.img,
        ball.x,
        ball.y,
        ball.body:getAngle(),
        ball.shape:getRadius() * 2 / ball.img:getWidth(),
        ball.shape:getRadius() * 2 / ball.img:getHeight(),
        ball.img:getWidth() / 2,
        ball.img:getHeight() / 2)

    -- Draw blocks (only non-destroyed ones)
    for i = 1, #blocks do
        local block = blocks[i]
        if block and not block.destroyed then
            love.graphics.draw(block.img, 
                block.body:getX(),
                block.body:getY(), 
                0, 
                185 / block.img:getWidth(), 
                75 / block.img:getHeight(),
                block.img:getWidth() / 2, 
                block.img:getHeight() / 2)
        end
    end

    -- Draw aiming line
    if draggingBall then
        love.graphics.setColor(1 - rangeVal, rangeVal, 0)
        local mx, my = love.mouse.getPosition()
        love.graphics.line(mx, my, ball.x, ball.y)
        love.graphics.circle("line", mx, my, 10)
        love.graphics.setColor(1, 1, 1)
    end
end

function game:mousepressed(x, y, button)
    if button == 1 then
        local dx = x - ball.x
        local dy = y - ball.y
        local distance = math.sqrt(dx * dx + dy * dy)

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

function breakBlock(fixture)
    local block = fixtureToBlock[fixture]
    if block and not block.destroyed then
        block.destroyed = true
        block.fixture:destroy()
        block.body:destroy()
        fixtureToBlock[fixture] = nil 
        print("Block broken!")
    end
end

function beginContact(a, b, collision)
    if a == ball.fixture then
        local block = fixtureToBlock[b]
        if block then
            breakBlock(b)
        end
    elseif b == ball.fixture then
        local block = fixtureToBlock[a]
        if block then
            breakBlock(a)
        end
    end
end

function endContact(a, b, collision)
end

return game