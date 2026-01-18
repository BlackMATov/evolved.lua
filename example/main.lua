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
        evolved.multi_clone(500, PREFABS.CIRCLE, nil, function(chunk, b_place, e_place)
            local screen_width, screen_height = love.graphics.getDimensions()

            ---@type number[], number[]
            local position_xs, position_ys = chunk:components(
                FRAGMENTS.POSITION_X, FRAGMENTS.POSITION_Y)

            ---@type number[], number[]
            local velocity_xs, velocity_ys = chunk:components(
                FRAGMENTS.VELOCITY_X, FRAGMENTS.VELOCITY_Y)

            for i = b_place, e_place do
                local px = math.random() * screen_width
                local py = math.random() * screen_height

                local vx = math.random(-100, 100)
                local vy = math.random(-100, 100)

                position_xs[i], position_ys[i] = px, py
                velocity_xs[i], velocity_ys[i] = vx, vy
            end
        end)
    end):build()

evolved.builder()
    :name('SYSTEMS.MOVEMENT')
    :group(STAGES.ON_UPDATE)
    :include(FRAGMENTS.POSITION_X, FRAGMENTS.POSITION_Y)
    :include(FRAGMENTS.VELOCITY_X, FRAGMENTS.VELOCITY_Y)
    :execute(function(chunk, _, entity_count, delta_time)
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
            love.graphics.circle('fill', x, y, 5)
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
    evolved.process_with(STAGES.ON_UPDATE, dt)
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
