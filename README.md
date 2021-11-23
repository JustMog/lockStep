lockstep
===

[fixed timestep](https://medium.com/@tglaiel/how-to-make-your-game-run-at-60fps-24c61210fe75) based gameloop for love2d with basic profiling functionality

Usage
---

Require lockStep.lua. Since it modifies love.run, it must be required outside of love callbacks such as love.load to have any effect.

```lua
local lockStep = require 'lockStep'
```

Documentation
---

- `lockStep.updateRate [default 60]`

Calls to love.update per second 

- `lockStep.maxUpdateDebt [default 8]`

Maximum number of timesteps the simulation is allowed to fall behind.
Further steps will be skipped to catch up, causing slowdown but preventing a "death spiral"

- `lockStep.dtSnap [default 0.0002]`

Maximum amount of time in seconds dt can be fudged by
to snap to nearby exact multiples of a timestep (i.e 1/lockStep.updateRate).
Set to nil to disable snapping.

- `lockStep.averageOver [default 4]`

Number of frames to incorporate into rolling average of dt
Set to nil to disable averaging.

```lua
lockStep.drawBreakdown(x, y, w, h, [colors])
```
Draw a bar showing how long is spent in update and draw as a proportion of the length of one timestep. 
if it exceeds 100%, the simulation will start to fall behind and the game may suffer from slowdown.

x & y are in screen space, ignoring any love.graphics transformations.

colors is an optional parameter. if included it can contain any of the following keys:

- alpha: number 0-1. sets the transparency of the breakdown. (default 1)
- update: table {r, g, b}. color to draw the update portion of the bar (default {0,1,1} cyan)
- draw: table {r, g, b}. color to draw the draw portion of the bar (default {1,0,1} magenta)

Note that draw timing will include any time spent waiting for vsync (if enabled) 
and that timings shown are from the previous frame.
