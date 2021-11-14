local lockStep = {
    -- updates per second at timescale 1
    updateRate = 60,
    -- maximum number of simulation steps "behind" allowed to accumulate
    maxUpdateDebt = 8,
    -- maximum amount of time to fudge dt by
    dtSnap = 0.0002,
    -- number of frames to incorporate into rolling average of dt
    averageOver = 4

}

local frameTimes = {
    updateRate = lockStep.updateRate,
}

local breakDownArgs
--pass nil to stop drawing
function lockStep.breakdown(x, y, w, h, alpha)
    if not x then breakDownArgs = nil
    else breakDownArgs = {x = x, y = y, w = w, h = h, alpha = alpha} end
end

local dt, accum, timeStep, updateTime, updatesDone, drawTime

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
    lg.setColor(1,1,0,a)

    t = t / updatesDone
    for i = 1, updatesDone do
        lg.rectangle("fill", x, y, math.max(0, (t*w)-2), h)
        x = x + t*w
    end

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
    accum = 0

    return function()

        timeStep = 1/lockStep.updateRate
        dt = love.timer.step()

        --dt snap
        if lockStep.dtSnap then
            for i = 1, lockStep.maxUpdateDebt do
                if math.abs(dt - (timeStep * i)) <= lockStep.dtSnap then
                    dt = timeStep * i
                    break
                end
            end
        end

        -- dt averaging
        if lockStep.averageOver then
            if frameTimes.updateRate ~= lockStep.updateRate then
                frameTimes = {}
                frameTimes.updateRate = lockStep.updateRate
            end
            while #frameTimes < lockStep.averageOver do
                table.insert(frameTimes, timeStep)
            end

            table.remove(frameTimes,1)
            table.insert(frameTimes, dt)
            for i = 1, lockStep.averageOver - 1 do
                dt = dt + frameTimes[i]
            end

            dt = dt / lockStep.averageOver
        end

        accum = accum + dt
        --prevent spiral of death
        if accum >= timeStep * lockStep.maxUpdateDebt then
            accum = timeStep
        end

        --start measuring time taken to update
        updateTime = love.timer.getTime()
        updatesDone = math.floor(accum / timeStep)

        --events
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

        local ticked = false

        while accum >= timeStep do
            accum = accum - timeStep
            if love.update then love.update(timeStep) end
            ticked = true
        end

        --finish measuring time taken to update
        updateTime = love.timer.getTime() - updateTime


        if lg and lg.isActive() and ticked then

            --start measuring time taken to update
            drawTime = love.timer.getTime()

            lg.origin()
            lg.clear(lg.getBackgroundColor())

            if love.draw then love.draw() end

            --finish measuring time taken to draw
            drawTime = love.timer.getTime() - drawTime


            if breakDownArgs then
                drawBreakdown(breakDownArgs)
            end

            lg.present()

        end

        -- why stop when you can yield
        if not lockStep.drawRate then love.timer.sleep(0.001) end
    end
end

return lockStep