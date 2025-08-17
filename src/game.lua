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
    
    raycastHits = {}
    maxRaycastBounces = 3

    score = 0

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
            body = love.physics.newBody(world, wW / 2, wH - 200, "static"),
            w = wW,
            h = 20
        }
    }

    for _, wall in pairs(walls) do
        wall.shape = love.physics.newRectangleShape(wall.w, wall.h)
        wall.fixture = love.physics.newFixture(wall.body, wall.shape)
        wall.fixture:setRestitution(0.5)
        wall.fixture:setFriction(0.7)
    end

    ball.fixture:setRestitution(0.5)

    -- Create blocks with proper fixture-to-block mapping
    blocks = {}
    fixtureToBlock = {}

    local blockIndex = 1
    for i = 1, 4 do
        for j = 1, 10 do
            blocks[blockIndex] = {
                body = love.physics.newBody(world, j * 116, i * 75, "static"),
                shape = love.physics.newRectangleShape(512/5, 206/5),
                img = love.graphics.newImage("assets/blocks/" .. i .. ".png"),
                destroyed = false,
                destroyFactor = 0,
                scoreMult = i * 5
            }
            blocks[blockIndex].fixture = love.physics.newFixture(blocks[blockIndex].body, blocks[blockIndex].shape)

            -- Map the fixture to this block for collision detection
            fixtureToBlock[blocks[blockIndex].fixture] = blocks[blockIndex]

            blockIndex = blockIndex + 1
        end
    end

    destroyFactorStages = {}
    for i = 1, 3 do
        destroyFactorStages[i] = love.graphics.newImage("assets/blocks/break/" .. (i - 1) .. ".png")
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
        rangeVal = math.max(0, math.min(1, distance / 250))
        
        -- Perform raycast prediction
        self:performRaycast(ball.x, ball.y, (mx - ball.x) * -30, (my - ball.y) * -30)
    end
end

function game:performRaycast(startX, startY, velX, velY)
    raycastHits = {}
    
    local currentX, currentY = startX, startY
    local currentVelX, currentVelY = velX, velY
    local ballRadius = ball.shape:getRadius()
    
    for bounce = 1, maxRaycastBounces do
        local speed = math.sqrt(currentVelX * currentVelX + currentVelY * currentVelY)
        if speed == 0 then break end
        
        local dirX, dirY = currentVelX / speed, currentVelY / speed
        
        local rayLength = 2000
        local endX = currentX + dirX * rayLength
        local endY = currentY + dirY * rayLength
        
        local closestFraction = 1
        local closestFixture = nil
        local closestX, closestY = endX, endY
        local closestNormalX, closestNormalY = 0, 0
        
        local function raycastCallback(fixture, x, y, xn, yn, fraction)
            if fraction < closestFraction then
                closestFraction = fraction
                closestFixture = fixture
                closestX, closestY = x, y
                closestNormalX, closestNormalY = xn, yn
            end
            return 1
        end
        
        world:rayCast(currentX, currentY, endX, endY, raycastCallback)
        
        if closestFixture then
            local hitX = closestX - closestNormalX * ballRadius
            local hitY = closestY - closestNormalY * ballRadius
            
            local incidentAngle = math.atan2(-dirY, -dirX)
            local normalAngle = math.atan2(closestNormalY, closestNormalX)
            local relativeAngle = incidentAngle - normalAngle
            
            table.insert(raycastHits, {
                x = hitX,
                y = hitY,
                normalX = closestNormalX,
                normalY = closestNormalY,
                angle = math.deg(relativeAngle),
                fixture = closestFixture,
                startX = currentX,
                startY = currentY
            })
            
            local dotProduct = currentVelX * closestNormalX + currentVelY * closestNormalY
            currentVelX = currentVelX - 2 * dotProduct * closestNormalX
            currentVelY = currentVelY - 2 * dotProduct * closestNormalY
            
            local restitution = closestFixture:getRestitution()
            currentVelX = currentVelX * restitution
            currentVelY = currentVelY * restitution
            
            currentX, currentY = hitX, hitY
            
            if math.sqrt(currentVelX * currentVelX + currentVelY * currentVelY) < 50 then
                break
            end
        else
            table.insert(raycastHits, {
                x = endX,
                y = endY,
                startX = currentX,
                startY = currentY,
                final = true
            })
            break
        end
    end
end

function game:syncPhysics()
    ball.x, ball.y = ball.body:getPosition()
    ball.xVel, ball.yVel = ball.body:getLinearVelocity()
end

function game:draw()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.05)
    -- Draw walls
    for _, wall in pairs(walls) do
        local wx, wy = wall.body:getPosition()
        love.graphics.setColor(0.83, 1, 0.74)
        love.graphics.rectangle("fill", wx - wall.w / 2, wy - wall.h / 2, wall.w, wall.h)
    end
    love.graphics.setColor(1, 1, 1)

    love.graphics.draw(ball.img,
        ball.x,
        ball.y,
        ball.body:getAngle(),
        ball.shape:getRadius() * 2 / ball.img:getWidth(),
        ball.shape:getRadius() * 2 / ball.img:getHeight(),
        ball.img:getWidth() / 2,
        ball.img:getHeight() / 2)

    for i = 1, #blocks do
        local block = blocks[i]
        if block and not block.destroyed then
            love.graphics.draw(block.img,
                block.body:getX(),
                block.body:getY(),
                0,
                512/5  / block.img:getWidth(),
                206/5 / block.img:getHeight(),
                block.img:getWidth() / 2,
                block.img:getHeight() / 2)

            love.graphics.draw(destroyFactorStages[block.destroyFactor + 1],
                block.body:getX(),
                block.body:getY(),
                0,
                185 / block.img:getWidth(),
                75 / block.img:getHeight(),
                block.img:getWidth() / 2,
                block.img:getHeight() / 2)
        end
    end

    if draggingBall and #raycastHits > 0 then
        love.graphics.setLineWidth(3)
        
        for i, hit in ipairs(raycastHits) do
            if hit.final then
                love.graphics.setColor(0.5, 0.5, 1, 0.6) 
            else
                local alpha = 1 - (i - 1) / maxRaycastBounces * 0.7
                -- love.graphics.setColor(1, 1 - (i - 1) * 0.3, 0, alpha)
                love.graphics.setColor(1, 1, 1, alpha)
            end
            
            love.graphics.line(hit.startX, hit.startY, hit.x, hit.y)
            
            if not hit.final then
                love.graphics.setColor(1, 0, 0, 0.8)
                love.graphics.circle("fill", hit.x, hit.y, 8)
                
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.line(hit.x, hit.y, 
                    hit.x + hit.normalX * 50, hit.y + hit.normalY * 50)
                
                love.graphics.setColor(1, 1, 1, 0.9)
                love.graphics.print(string.format("%.1f°", hit.angle), 
                    hit.x + 15, hit.y - 10)
                
                local block = fixtureToBlock[hit.fixture]
                if block and not block.destroyed then
                    love.graphics.setColor(1, 1, 1, 0.3) -- the target block color
                    love.graphics.rectangle("fill", 
                        block.body:getX() - 512/5/2, 
                        block.body:getY() - 206/5/2, 
                        512/5, 206/5)
                end
            end
        end
        
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1)
    end

    if draggingBall then
        love.graphics.setColor(1, 1, 1, math.max(0.3, rangeVal))
        local mx, my = love.mouse.getPosition()
        love.graphics.setLineWidth(3)
        love.graphics.line(mx, my, ball.x, ball.y)
        love.graphics.circle("line", mx, my, 10)
        love.graphics.setColor(1, 1, 1)
    end

    love.graphics.print("Score: " .. math.floor(score), 25, 25)
    
    if draggingBall and #raycastHits > 0 then
        love.graphics.print("Predicted bounces: " .. (#raycastHits - (raycastHits[#raycastHits].final and 1 or 0)), 25, 45)
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
        raycastHits = {} 
    end
end

function breakBlock(fixture)
    local block = fixtureToBlock[fixture]
    if block and not block.destroyed then
        block.destroyFactor = block.destroyFactor + 1
        score = score + 1.67823 * block.destroyFactor * block.scoreMult
        if block.destroyFactor > 2 then
            block.destroyed = true
            block.fixture:destroy()
            block.body:destroy()
            fixtureToBlock[fixture] = nil
            print("Block broken!")
        end
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