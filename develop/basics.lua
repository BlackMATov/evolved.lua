local basics = {}

local MIN_FUZZ_SECS = 0.5
local MIN_BENCH_SECS = 0.1
local MIN_WARMUP_SECS = 0.1

local MIN_FUZZ_ITERS = 100
local MIN_BENCH_ITERS = 100
local MIN_WARMUP_ITERS = 100

local __table_pack = (function()
    ---@diagnostic disable-next-line: deprecated
    return table.pack or function(...)
        return { n = select('#', ...), ... }
    end
end)()

local __table_unpack = (function()
    ---@diagnostic disable-next-line: deprecated
    return table.unpack or unpack
end)()

local __failure_count = 0

---@return integer
---@nodiscard
function basics.failure_count()
    return __failure_count
end

---@param pattern string
function basics.unload(pattern)
    for name, _ in pairs(package.loaded) do
        if name:match(pattern) then
            package.loaded[name] = nil
        end
    end
end

---@param modname string
function basics.describe_fuzz(modname)
    basics.unload('evolved')

    print(string.format('| %s ... |', modname))

    collectgarbage('collect')
    collectgarbage('stop')

    do
        local iters = 0

        local start_s = os.clock()
        local start_kb = collectgarbage('count')

        local success, result = pcall(function()
            repeat
                iters = iters + 1
                basics.unload(modname)
                require(modname)
            until iters >= MIN_FUZZ_ITERS and os.clock() - start_s >= MIN_FUZZ_SECS
        end)

        local finish_s = os.clock()
        local finish_kb = collectgarbage('count')

        if success then
            print(string.format('|-- PASS | us: %.2f | op/s: %.2f | kb/i: %.2f | iters: %d',
                (finish_s - start_s) * 1e6 / iters,
                iters / (finish_s - start_s),
                (finish_kb - start_kb) / iters,
                iters))
        else
            print('|-- FUZZ FAIL: ' .. result)
            __failure_count = __failure_count + 1
        end
    end

    collectgarbage('restart')
    collectgarbage('collect')
end

---@param name string
---@param loop fun(...): ...
---@param init? fun(): ...
---@param fini? fun(...): ...
function basics.describe_bench(name, loop, init, fini)
    basics.unload('evolved')

    print(string.format('| %s ... |', name))

    local state = init and __table_pack(init()) or {}

    do
        local iters = 0

        local warmup_s = os.clock()

        local success, result = pcall(function()
            repeat
                iters = iters + 1
                loop(__table_unpack(state))
            until iters >= MIN_WARMUP_ITERS and os.clock() - warmup_s > MIN_WARMUP_SECS
        end)

        if not success then
            print('|-- WARMUP FAIL: ' .. result)
            __failure_count = __failure_count + 1
            return
        end
    end

    collectgarbage('collect')
    collectgarbage('stop')

    do
        local iters = 0

        local start_s = os.clock()
        local start_kb = collectgarbage('count')

        local success, result = pcall(function()
            repeat
                iters = iters + 1
                loop(__table_unpack(state))
            until iters >= MIN_BENCH_ITERS and os.clock() - start_s > MIN_BENCH_SECS
        end)

        local finish_s = os.clock()
        local finish_kb = collectgarbage('count')

        if success then
            print(string.format('|-- PASS | us: %.2f | op/s: %.2f | kb/i: %.2f | iters: %d',
                (finish_s - start_s) * 1e6 / iters,
                iters / (finish_s - start_s),
                (finish_kb - start_kb) / iters,
                iters))
        else
            print('|-- LOOP FAIL: ' .. result)
            __failure_count = __failure_count + 1
        end
    end

    if fini then
        local success, result = pcall(function()
            fini(__table_unpack(state))
        end)

        if not success then
            print('|-- FINI FAIL: ' .. result)
            __failure_count = __failure_count + 1
        end
    end

    collectgarbage('restart')
    collectgarbage('collect')
end

return basics
