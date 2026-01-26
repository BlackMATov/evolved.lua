local evo = require 'evolved'
local basics = require 'develop.basics'

evo.debug_mode(false)

local N = 1000

print '----------------------------------------'

basics.describe_bench(string.format('Id Benchmarks: Acquire and Release %d ids', N),
    function(tables)
        for i = 1, N do
            tables[i] = evo.id()
        end

        for i = 1, N do
            evo.destroy(tables[i])
        end
    end, function()
        return {}
    end)
