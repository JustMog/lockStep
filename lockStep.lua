local lockStep = {
    -- updates per second at timescale 1
    updateRate = 60,
    -- maximum love.draw calls per second
    drawRate = 60,
    -- causes update to be called more or less frequently to speed up or slow down the simulation
    timeScale = 1,
    -- maximum number of simulation steps allowed to accumulate
    maxUpdateDebt = 8
}

local breakDownArgs
--pass nil to stop drawing
function lockStep.breakdown(x, y, w, h, alpha)
    if not x then breakDownArgs = nil
    else breakDownArgs = {x = x, y = y, w = w, h = h, alpha = alpha} end
end

local dt, accum, timeStep, lastFrame, updateTime, updatesDone, freeUpdateTime, drawTime

local function events()
    if love.event then
        love.event.pump()
        for name, a,b,c,d,e,f in love.event.poll() do
            if name == "quit" then
                if not love.quit or not love.quit() then
                    return a or 0
                end
            end
            love.handlers[name](a,b,c,d,e,f)
        end
    end
end

local lg
local function drawBreakdown(opts)
    lg.origin()
    local pr, pg, pb, pa = lg.getColor()

    local x, y = opts.x, opts.y
    local w, h, a = opts.w, opts.h, opts.alpha or 1

    lg.setColor(1,1,1,a)
    lg.rectangle("fill",x,y,w,h)

    x, y = x + 3, y + 3
    w, h = w - 6, h - 6
    lg.setColor(0,0,0,a)
    lg.rectangle("fill",x,y,w,h)

    local t = updateTime / timeStep
    lg.setColor(0,1,1,a)

    t = t / updatesDone
    for i = 1, updatesDone do
        lg.rectangle("fill", x, y, math.max(0, (t*w)-2), h)
        x = x + t*w
    end

    t = freeUpdateTime / timeStep
    lg.setColor(1,1,0,a)
    lg.rectangle("fill", x, y, t*w, h)
    x = x + t * w

    t =  drawTime / timeStep
    lg.setColor(1,0,1,a)
    lg.rectangle("fill", x, y, t*w, h)

    lg.setColor(pr, pg, pb, pa)

end

function love.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
    lg = love.graphics

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end
    lastFrame = love.timer.getTime()

    accum = 0

    return function()

        timeStep = 1/lockStep.updateRate

        dt = love.timer.step()
        accum = accum + dt * lockStep.timeScale
        --prevent spiral of death
        accum = math.min(accum, timeStep * lockStep.maxUpdateDebt)

        --start measuring time taken to update
        updateTime = love.timer.getTime()
        updatesDone = math.floor(accum / timeStep)

        -- Process events at least once per drawn frame, even if update isn't called
        -- Stops love from becoming unresponsive at slow timescales
        if accum < timeStep then
            if events() then return true end
        end

        while accum >= timeStep do
            accum = accum - timeStep
            if events() then return true end
            if love.update then love.update(timeStep) end
        end

        --finish measuring time taken to update
        updateTime = love.timer.getTime() - updateTime

        -- non-fixed timestep, useful for e.g. particle systems,
        --since they have no way of implementing alpha interpolation
        freeUpdateTime = love.timer.getTime()
        if love.freeUpdate then love.freeUpdate(dt * lockStep.timeScale) end
        freeUpdateTime = love.timer.getTime() - freeUpdateTime

        --wait if enforcing max framerate
        while lockStep.drawRate and love.timer.getTime() - lastFrame < 1 / lockStep.drawRate do
            love.timer.sleep(.0005)
        end


        if lg and lg.isActive() then

            lg.origin()
            lg.clear(lg.getBackgroundColor())

            --start measuring time taken to update
            drawTime = love.timer.getTime()

            --pass time left unsimulated for interpolation
            if love.draw then love.draw(accum / timeStep) end

            --finish measuring time taken to draw
            drawTime = love.timer.getTime() - drawTime

            if breakDownArgs then
                drawBreakdown(breakDownArgs)
            end

            lg.present()
        end

        lastFrame = love.timer.getTime()

        -- why stop when you can yield
        if not lockStep.drawRate then love.timer.sleep(0.001) end
    end
end

return lockStep