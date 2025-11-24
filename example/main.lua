local evolved = require 'evolved'

local STAGES = {
    ON_SETUP = evolved.builder()
        :name('STAGES.ON_SETUP')
        :build(),
    ON_UPDATE = evolved.builder()
        :name('STAGES.ON_UPDATE')
        :build(),
    ON_RENDER = evolved.builder()
        :name('STAGES.ON_RENDER')
        :build(),
}

local UNIFORMS = {
    DELTA_TIME = 1.0 / 60.0,
}

local FRAGMENTS = {
    POSITION_X = evolved.builder()
        :name('FRAGMENTS.POSITION_X')
        :default(0)
        :build(),
    POSITION_Y = evolved.builder()
        :name('FRAGMENTS.POSITION_Y')
        :default(0)
        :build(),
    VELOCITY_X = evolved.builder()
        :name('FRAGMENTS.VELOCITY_X')
        :default(0)
        :build(),
    VELOCITY_Y = evolved.builder()
        :name('FRAGMENTS.VELOCITY_Y')
        :default(0)
        :build(),
}

local PREFABS = {
    CIRCLE = evolved.builder()
        :name('PREFABS.CIRCLE')
        :prefab()
        :set(FRAGMENTS.POSITION_X)
        :set(FRAGMENTS.POSITION_Y)
        :set(FRAGMENTS.VELOCITY_X)
        :set(FRAGMENTS.VELOCITY_Y)
        :build(),
}

---
---
---
---
---

evolved.builder()
    :name('SYSTEMS.STARTUP')
    :group(STAGES.ON_SETUP)
    :prologue(function()
        local screen_width, screen_height = love.graphics.getDimensions()

        local circle_list, circle_count = evolved.multi_clone(100, PREFABS.CIRCLE)

        for i = 1, circle_count do
            local circle = circle_list[i]

            local px = math.random() * screen_width
            local py = math.random() * screen_height

            local vx = math.random(-100, 100)
            local vy = math.random(-100, 100)

            evolved.set(circle, FRAGMENTS.POSITION_X, px)
            evolved.set(circle, FRAGMENTS.POSITION_Y, py)

            evolved.set(circle, FRAGMENTS.VELOCITY_X, vx)
            evolved.set(circle, FRAGMENTS.VELOCITY_Y, vy)
        end
    end):build()

evolved.builder()
    :name('SYSTEMS.MOVEMENT')
    :group(STAGES.ON_UPDATE)
    :include(FRAGMENTS.POSITION_X, FRAGMENTS.POSITION_Y)
    :include(FRAGMENTS.VELOCITY_X, FRAGMENTS.VELOCITY_Y)
    :execute(function(chunk, _, entity_count)
        local delta_time = UNIFORMS.DELTA_TIME
        local screen_width, screen_height = love.graphics.getDimensions()

        ---@type number[], number[]
        local position_xs, position_ys = chunk:components(
            FRAGMENTS.POSITION_X, FRAGMENTS.POSITION_Y)

        ---@type number[], number[]
        local velocity_xs, velocity_ys = chunk:components(
            FRAGMENTS.VELOCITY_X, FRAGMENTS.VELOCITY_Y)

        for i = 1, entity_count do
            local px, py = position_xs[i], position_ys[i]
            local vx, vy = velocity_xs[i], velocity_ys[i]

            px = px + vx * delta_time
            py = py + vy * delta_time

            if px < 0 and vx < 0 then
                vx = -vx
            elseif px > screen_width and vx > 0 then
                vx = -vx
            end

            if py < 0 and vy < 0 then
                vy = -vy
            elseif py > screen_height and vy > 0 then
                vy = -vy
            end

            position_xs[i], position_ys[i] = px, py
            velocity_xs[i], velocity_ys[i] = vx, vy
        end
    end):build()

evolved.builder()
    :name('SYSTEMS.RENDERING')
    :group(STAGES.ON_RENDER)
    :include(FRAGMENTS.POSITION_X, FRAGMENTS.POSITION_Y)
    :execute(function(chunk, _, entity_count)
        ---@type number[], number[]
        local position_xs, position_ys = chunk:components(
            FRAGMENTS.POSITION_X, FRAGMENTS.POSITION_Y)

        for i = 1, entity_count do
            local x, y = position_xs[i], position_ys[i]
            love.graphics.circle('fill', x, y, 10)
        end
    end):build()

evolved.builder()
    :name('SYSTEMS.DEBUGGING')
    :group(STAGES.ON_RENDER)
    :epilogue(function()
        local fps = love.timer.getFPS()
        local mem = collectgarbage('count')
        love.graphics.print(string.format('FPS: %d', fps), 10, 10)
        love.graphics.print(string.format('MEM: %d KB', mem), 10, 30)
    end):build()

---
---
---
---
---

---@type love.load
function love.load()
    evolved.process(STAGES.ON_SETUP)
end

---@type love.update
function love.update(dt)
    UNIFORMS.DELTA_TIME = dt
    evolved.process(STAGES.ON_UPDATE)
end

---@type love.draw
function love.draw()
    evolved.process(STAGES.ON_RENDER)
end

---@type love.keypressed
function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end
end
