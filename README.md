lockstep
===

[fixed timestep](http://gafferongames.com/game-physics/fix-your-timestep/) based gameloop with timescaling and basic profiling functionality

Usage
---

Require lockStep.lua. Since it modifies love.run, it must be required outside of love callbacks such as love.load to have any effect.

```lua
local lockStep = require 'lockStep'

function love.load(arg)
    lockStep.updateRate = 60,
    lockStep.drawRate = 60,
end
```

Documentation
---

### Callbacks

```lua
function love.update(dt)
    -- dt remains fixed at 1/lockStep.updateRate.
    -- number of update()s to draw()s varies with lockStep.timeScale,
    -- and number of timesteps elapsed since previous frame (can be zero)
end

function love.freeUpdate(dt)
    -- functions like default update() with variable dt.
    -- called once per frame after update() (if any) and before draw().
    -- capped along with draw() by lockStep.drawRate.
end

function love.draw(alpha)
    -- alpha is a number 0 - 1 representing the fraction of a timestep elapsed but not yet simulated 
    -- it can be used to interpolate between values to smooth out movement visually at low timescales
end

-- other callbacks:
    -- fire before each update() timestep
    -- or once per frame if no timestep elapsed

```

- `lockStep.updateRate [default 60]`

Calls to love.update per second at a timeScale of 1

- `lockStep.drawRate [default 60]`

Caps the framerate (love.draw calls per second).
Set to nil for unlimited.

- `lockStep.timeScale [default 1]`

Causes update to be called more or less frequently to speed up or slow down the simulation ( 0.5 = half speed, 2 = double )
Interpolation between the more infrequent update()s must be used when drawing to achieve smooth results at low timeScales.
Beware that a timeScale of 0 will stop update() being called at all! It must be reset from another callback in that case.

```lua
lockStep.breakdown(x, y, w, h, [alpha])
```
Begin drawing a bar showing how long is spent in update (cyan), freeUpdate (yellow) and draw (magenta)
as a proportion of the length of one timestep. if it exceeds 100%, the simulation will start to fall behind
and the game may suffer from slowdown.

```lua
lockStep.breakdown()
```
Stop drawing the bar.


```