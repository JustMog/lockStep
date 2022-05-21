local lockStep = {
    -- updates per second
    updateRate = 60,
    -- maximum number of simulation steps "behind" allowed to accumulate
    maxUpdateDebt = 8,
    -- maximum amount of time to fudge dt by
    dtSnap = 0.0002,
    -- number of frames to incorporate into rolling average of dt
    averageOver = 4

}
local timeStep

--buffer of dts from previous frames for averaging
local frameTimes = {
    --keep our own idea of the update rate to detect if it was changed
    updateRate = lockStep.updateRate,
}

--timing values buffered by one frame to sync draw and update
local timingBack = {
    updateTime = 0,
    updates = 0,
    drawTime = 0,
}

local lg
local defaultCols = {
    update = {0,1,1},
    draw = {1,0,1},
    alpha = 1,
}
function lockStep.drawBreakdown(x, y, w, h, cols)
    cols = cols or defaultCols
    local a = cols.alpha or 1
    cols.update = cols.update or defaultCols.update
    cols.draw = cols.draw or defaultCols.draw
    cols.update[4] = a
    cols.draw[4] = a

    lg.push("all")

    lg.origin()

    lg.setColor(1,1,1,a)
    lg.rectangle("fill",x,y,w,h)

    x, y = x + 3, y + 3
    w, h = w - 6, h - 6

    lg.setColor(0,0,0,a)

    lg.rectangle("fill",x,y,w,h)

    local t = timingBack.updateTime / timeStep
    lg.setColor(unpack(cols.update))

    t = t / timingBack.updates
    for i = 1, timingBack.updates do
        lg.rectangle("fill", x, y, math.max(0, (t*w)-2), h)
        x = x + t*w
    end

    t =  timingBack.drawTime / timeStep
    lg.setColor(unpack(cols.draw))
    lg.rectangle("fill", x, y, t*w, h)

    lg.pop()

end

local time_60hz = 1/60
local snapFrequencies = {
    time_60hz,        --60fps
    time_60hz*2,      --30fps
    time_60hz*3,      --20fps
    time_60hz*4,      --15fps
    (time_60hz+1)/2,  --120fps --120hz, 240hz, or higher need to round up, so that adding 120hz twice guaranteed is at least the same as adding time_60hz once
}

function love.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
    lg = love.graphics

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end
    local accum = 0

    local timing = {}

    return function()

        timeStep = 1/lockStep.updateRate
        local dt = love.timer.step()

        if dt < 0  then dt = 0 end

        --dt snap
        if lockStep.dtSnap then
            for _, snap in ipairs(snapFrequencies) do
                if math.abs(dt - snap) <= lockStep.dtSnap then
                    dt = snap
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

            table.remove(frameTimes, 1)
            table.insert(frameTimes, dt)

            dt = 0
            for _, v in ipairs(frameTimes) do
                dt = dt + v
            end

            dt = dt / lockStep.averageOver
        end

        accum = accum + dt
        --prevent spiral of death
        if accum >= timeStep * lockStep.maxUpdateDebt then
            accum = timeStep
        end

        --start measuring time taken to update
        timing.updateTime = love.timer.getTime()
        timing.updates = 0

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

        while accum >= timeStep do
            accum = accum - timeStep
            if love.update then love.update(timeStep) end
            timing.updates = timing.updates + 1
        end

        --finish measuring time taken to update
        timing.updateTime = love.timer.getTime() - timing.updateTime


        if lg and lg.isActive() and timing.updates > 0 then

            --start measuring time taken to update
            timing.drawStartTime = love.timer.getTime()

            lg.origin()
            lg.clear(lg.getBackgroundColor())

            if love.draw then love.draw() end

            lg.present()

            --finish measuring time taken to draw
            timing.drawTime = love.timer.getTime() - timing.drawStartTime

            timingBack, timing = timing, timingBack

        end

        -- why stop when you can yield
        if not lockStep.drawRate then love.timer.sleep(0.001) end
    end
end

return lockStep