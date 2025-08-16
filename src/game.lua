local game = {}

function game.load()
    world = wf.newWorld(0, 0, true)

    world:setGravity(0, 9.81)

    ball = {}
    ball.x = 0
    ball.y = 0
    ball.xVel = 0
    ball.yVel = 0
    ball.body = love.physics.newBody(world, 400, 300, "dynamic")
    ball.body:setFixedRotation(true)
    ball.shape = love.physics.newCircleShape(20)
    ball.fixture = love.physics.newFixture(ball.body, ball.shape)
    ball:setGravityScale(0)
end

function game.update(dt)

    world:update(dt)

end

function game.syncPhysics()
    ball.x, ball.y = ball.body:getPosition()
    ball.xVel, ball.yVel = ball.body:getLinearVelocity()
end

function game.draw()
end

return game