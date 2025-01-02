package.loaded['evolved'] = nil
local evo = require 'evolved'

local __table_pack = (function()
    return table.pack or function(...)
        return { n = select('#', ...), ... }
    end
end)()

local __table_unpack = (function()
    return table.unpack or unpack
end)()

---@param name string
---@param loop fun(...): ...
---@param init? fun(): ...
local function __bench_describe(name, loop, init)
    collectgarbage('collect')
    collectgarbage('stop')

    print(string.format('| %s ... |', name))

    local iters = 0
    local state = init and __table_pack(init()) or {}

    local start_s = os.clock()
    local start_kb = collectgarbage('count')

    local success, result = pcall(function()
        repeat
            iters = iters + 1
            loop(__table_unpack(state))
        until os.clock() - start_s > 0.2
    end)

    local finish_s = os.clock()
    local finish_kb = collectgarbage('count')

    print(string.format('    %s | us: %.2f | op/s: %.2f | kb/i: %.2f',
        success and 'PASS' or 'FAIL',
        (finish_s - start_s) * 1e6 / iters,
        iters / (finish_s - start_s),
        (finish_kb - start_kb) / iters))

    if not success then print('    ' .. result) end

    collectgarbage('restart')
    collectgarbage('collect')
end

---@param entities evolved.id[]
__bench_describe('create and destroy 1k entities', function(entities)
    local id = evo.id
    local destroy = evo.destroy

    for i = 1, 1000 do
        local e = id()
        entities[i] = e
    end

    for i = 1, #entities do
        destroy(entities[i])
    end
end, function()
    return {}
end)

---@param f1 evolved.fragment
---@param entities evolved.id[]
__bench_describe('create and destroy 1k entities with one component', function(f1, entities)
    local id = evo.id
    local insert = evo.insert
    local destroy = evo.destroy

    for i = 1, 1000 do
        local e = id()
        entities[i] = e

        insert(e, f1)
    end

    for i = 1, #entities do
        destroy(entities[i])
    end
end, function()
    local f1 = evo.id(2)
    return f1, {}
end)

---@param f1 evolved.fragment
---@param f2 evolved.fragment
---@param entities evolved.id[]
__bench_describe('create and destroy 1k entities with two components', function(f1, f2, entities)
    local id = evo.id
    local insert = evo.insert
    local destroy = evo.destroy

    for i = 1, 1000 do
        local e = id()
        entities[i] = e

        insert(e, f1)
        insert(e, f2)
    end

    for i = 1, #entities do
        destroy(entities[i])
    end
end, function()
    local f1, f2 = evo.id(2)
    return f1, f2, {}
end)

---@param f1 evolved.fragment
---@param f2 evolved.fragment
---@param f3 evolved.fragment
---@param entities evolved.id[]
__bench_describe('create and destroy 1k entities with three components', function(f1, f2, f3, entities)
    local id = evo.id
    local insert = evo.insert
    local destroy = evo.destroy

    for i = 1, 1000 do
        local e = id()
        entities[i] = e

        insert(e, f1)
        insert(e, f2)
        insert(e, f3)
    end

    for i = 1, #entities do
        destroy(entities[i])
    end
end, function()
    local f1, f2, f3 = evo.id(3)
    return f1, f2, f3, {}
end)

--[[ lua 5.1
| create and destroy 1k entities ... |
    PASS | us: 312.60 | op/s: 3199.00 | kb/i: 0.05
| create and destroy 1k entities with one component ... |
    PASS | us: 1570.31 | op/s: 636.82 | kb/i: 0.63
| create and destroy 1k entities with two components ... |
    PASS | us: 2780.82 | op/s: 359.61 | kb/i: 0.91
| create and destroy 1k entities with three components ... |
    PASS | us: 4060.00 | op/s: 246.31 | kb/i: 1.67
]]

--[[ luajit 2.1
| create and destroy 1k entities ... |
    PASS | us: 12.22 | op/s: 81840.80 | kb/i: 0.00
| create and destroy 1k entities with one component ... |
    PASS | us: 56.22 | op/s: 17786.07 | kb/i: 0.02
| create and destroy 1k entities with two components ... |
    PASS | us: 412.73 | op/s: 2422.89 | kb/i: 0.11
| create and destroy 1k entities with three components ... |
    PASS | us: 611.62 | op/s: 1635.00 | kb/i: 0.17
]]
