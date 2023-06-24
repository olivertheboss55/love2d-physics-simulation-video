-- set up the physics world
love.physics.setMeter(64)
world = love.physics.newWorld(0, 9.81 * 64, true)

-- set up the ball object
ball = {
    radius = 20,
    density = 1,
}

-- set up the square object
square = {
    size = 40,
    density = 1,
}

-- set up the ground object
ground = {
    y = love.graphics.getHeight() - 50, -- position the ground near the bottom of the window
    height = 50,
}

-- create the ground body
ground.body = love.physics.newBody(world, love.graphics.getWidth() / 2, ground.y, "static")
ground.shape = love.physics.newEdgeShape(-love.graphics.getWidth() / 2, 0, love.graphics.getWidth() / 2, 0)
ground.fixture = love.physics.newFixture(ground.body, ground.shape)

-- list to keep track of all the balls
balls = {}

-- list to keep track of all the squares
squares = {}

-- variables to keep track of the selected objects
selectedBall = nil
selectedSquare = nil
mouseJoint = nil

-- mouse click function to spawn a new ball or square
function love.mousepressed(x, y, button)
    if button == 2 then -- right mouse button
        -- create a new ball object with a physics body
        local b = {}
        b.body = love.physics.newBody(world, x, y, "dynamic")
        b.shape = love.physics.newCircleShape(ball.radius)
        b.fixture = love.physics.newFixture(b.body, b.shape, ball.density)
        b.fixture:setRestitution(0.9) -- make the ball bouncy
        table.insert(balls, b) -- add the new ball to the list
    elseif button == 1 then -- left mouse button
        -- check if the click is inside a ball
        local ballClicked = false
        for _, b in ipairs(balls) do
            if distance(x, y, b.body:getX(), b.body:getY()) <= ball.radius then
                selectedBall = b -- select the ball
                -- create a mouse joint to drag the ball
                mouseJoint = love.physics.newMouseJoint(b.body, x, y)
                mouseJoint:setMaxForce(1000 * b.body:getMass())
                b.body:setGravityScale(0) -- disable gravity for the selected ball
                ballClicked = true
                break
            end
        end

        -- check if the click is inside a square
        local squareClicked = false
        for _, s in ipairs(squares) do
            if distance(x, y, s.body:getX(), s.body:getY()) <= square.size / 2 then
                selectedSquare = s -- select the square
                -- create a mouse joint to drag the square
                mouseJoint = love.physics.newMouseJoint(s.body, x, y)
                mouseJoint:setMaxForce(1000 * s.body:getMass())
                s.body:setGravityScale(0) -- disable gravity for the selected square
                squareClicked = true
                break
            end
        end

        -- if no ball or square was clicked, spawn a new square
        if not ballClicked and not squareClicked then
            local s = {}
            s.body = love.physics.newBody(world, x, y, "dynamic")
            s.shape = love.physics.newRectangleShape(square.size, square.size)
            s.fixture = love.physics.newFixture(s.body, s.shape, square.density)
            s.fixture:setRestitution(0.5) -- make the square bouncy
            table.insert(squares, s) -- add the new square to the list
        end
    end
end

-- mouse release function
function love.mousereleased(x, y, button)
    if button == 1 then -- left mouse button
        if selectedBall ~= nil then
            selectedBall.body:setGravityScale(1) -- restore gravity scale for the released ball
            selectedBall = nil
        end

        if selectedSquare ~= nil then
            selectedSquare.body:setGravityScale(1) -- restore gravity scale for the released square
            selectedSquare = nil
        end

        if mouseJoint ~= nil then
            mouseJoint:destroy()
            mouseJoint = nil
        end
    end
end

-- update function
function love.update(dt)
    world:update(dt) -- update the physics world

    -- update the position of the mouse joint
    if mouseJoint ~= nil then
        mouseJoint:setTarget(love.mouse.getPosition())
    end

    -- remove any balls that have gone offscreen
    for i = #balls, 1, -1 do
        local b = balls[i]
        if b.body:getY() > love.graphics.getHeight() + ball.radius then
            if selectedBall == b then
                selectedBall.body:setGravityScale(1) -- restore gravity scale if the selected ball goes offscreen
                selectedBall = nil
                mouseJoint:destroy()
                mouseJoint = nil
            end
            b.body:destroy()
            table.remove(balls, i)
        end
    end

    -- remove any squares that have gone offscreen
    for i = #squares, 1, -1 do
        local s = squares[i]
        if s.body:getY() > love.graphics.getHeight() + square.size / 2 then
            if selectedSquare == s then
                selectedSquare.body:setGravityScale(1) -- restore gravity scale if the selected square goes offscreen
                selectedSquare = nil
                mouseJoint:destroy()
                mouseJoint = nil
            end
            s.body:destroy()
            table.remove(squares, i)
        end
    end
end

-- draw function
function love.draw()
    -- draw the ground
    love.graphics.setColor(0.3, 0.3, 0.3) -- gray color
    love.graphics.rectangle("fill", 0, ground.y, love.graphics.getWidth(), ground.height)

    -- draw the balls
    love.graphics.setColor(1, 1, 1) -- white color for balls
    for _, b in ipairs(balls) do
        love.graphics.circle("fill", b.body:getX(), b.body:getY(), ball.radius)
    end

    -- draw the squares
    love.graphics.setColor(0, 1, 0) -- green color for squares
    for _, s in ipairs(squares) do
        love.graphics.rectangle("fill", s.body:getX() - square.size / 2, s.body:getY() - square.size / 2, square.size, square.size)
    end

    -- draw the selected ball (if any)
    if selectedBall ~= nil then
        love.graphics.setColor(1, 0, 0) -- red color for selected ball
        love.graphics.circle("fill", selectedBall.body:getX(), selectedBall.body:getY(), ball.radius)
    end

    -- draw the selected square (if any)
    if selectedSquare ~= nil then
        love.graphics.setColor(0, 0, 1) -- blue color for selected square
        love.graphics.rectangle("fill", selectedSquare.body:getX() - square.size / 2, selectedSquare.body:getY() - square.size / 2, square.size, square.size)
    end
end

-- helper function to calculate distance between two points
function distance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end
