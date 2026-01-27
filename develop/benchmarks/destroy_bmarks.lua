local evo = require 'evolved'
local basics = require 'develop.basics'

evo.debug_mode(false)

local N = 1000

print '----------------------------------------'

basics.describe_bench(string.format('Destroy Benchmarks: Acquire and Release %d ids', N),
    function(tables)
        local id = evo.id
        local destroy = evo.destroy

        for i = 1, N do
            tables[i] = id()
        end

        for i = 1, N do
            destroy(tables[i])
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('Destroy Benchmarks: Acquire and Release %d double ids', N),
    function(tables)
        local id = evo.id
        local destroy = evo.destroy

        for i = 1, N, 2 do
            tables[i], tables[i + 1] = id(2)
        end

        for i = 1, N, 2 do
            destroy(tables[i], tables[i + 1])
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('Destroy Benchmarks: Acquire and Release %d triple ids', N),
    function(tables)
        local id = evo.id
        local destroy = evo.destroy

        for i = 1, N, 3 do
            tables[i], tables[i + 1], tables[i + 2] = id(3)
        end

        for i = 1, N, 3 do
            destroy(tables[i], tables[i + 1], tables[i + 2])
        end
    end, function()
        return {}
    end)
