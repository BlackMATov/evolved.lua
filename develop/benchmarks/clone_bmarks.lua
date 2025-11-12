local evo = require 'evolved'
local basics = require 'develop.basics'

evo.debug_mode(false)

local N = 1000

local F1, F2, F3, F4, F5 = evo.id(5)

local Q1 = evo.builder():include(F1):spawn()

local R1 = evo.builder():require(F1):spawn()
local R3 = evo.builder():require(F1, F2, F3):spawn()
local R5 = evo.builder():require(F1, F2, F3, F4, F5):spawn()

print '----------------------------------------'

basics.describe_bench(string.format('Clone Benchmarks: Simple Clone | %d entities with 1 component', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [F1] = true }

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Simple Defer Clone | %d entities with 1 component', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [F1] = true }

        evo.defer()
        for _ = 1, N do
            clone(prefab)
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Simple Clone | %d entities with 3 components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [F1] = true, [F2] = true, [F3] = true }

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Simple Defer Clone | %d entities with 3 components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [F1] = true, [F2] = true, [F3] = true }

        evo.defer()
        for _ = 1, N do
            clone(prefab)
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Simple Clone | %d entities with 5 components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Simple Defer Clone | %d entities with 5 components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        evo.defer()
        for _ = 1, N do
            clone(prefab)
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Clone Benchmarks: Simple Clone | %d entities with 1 required component', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [R1] = true }

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Simple Defer Clone | %d entities with 1 required component', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [R1] = true }

        evo.defer()
        for _ = 1, N do
            clone(prefab)
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Simple Clone | %d entities with 3 required components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [R3] = true }

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Simple Defer Clone | %d entities with 3 required components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [R3] = true }

        evo.defer()
        for _ = 1, N do
            clone(prefab)
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Simple Clone | %d entities with 5 required components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [R5] = true }

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Simple Defer Clone | %d entities with 5 required components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [R5] = true }

        evo.defer()
        for _ = 1, N do
            clone(prefab)
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Clone Benchmarks: Multi Clone | %d entities with 1 component', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [F1] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Multi Defer Clone | %d entities with 1 component', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [F1] = true }

        evo.defer()
        multi_clone(N, prefab)
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Multi Clone | %d entities with 3 components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [F1] = true, [F2] = true, [F3] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Multi Defer Clone | %d entities with 3 components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [F1] = true, [F2] = true, [F3] = true }

        evo.defer()
        multi_clone(N, prefab)
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Multi Clone | %d entities with 5 components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Multi Defer Clone | %d entities with 5 components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        evo.defer()
        multi_clone(N, prefab)
        evo.commit()

        evo.batch_destroy(Q1)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Clone Benchmarks: Multi Clone | %d entities with 1 required component', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [R1] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Multi Defer Clone | %d entities with 1 required component', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [R1] = true }

        evo.defer()
        multi_clone(N, prefab)
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Multi Clone | %d entities with 3 required components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [R3] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Multi Defer Clone | %d entities with 3 required components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [R3] = true }

        evo.defer()
        multi_clone(N, prefab)
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Multi Clone | %d entities with 5 required components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [R5] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Clone Benchmarks: Multi Defer Clone | %d entities with 5 required components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [R5] = true }

        evo.defer()
        multi_clone(N, prefab)
        evo.commit()

        evo.batch_destroy(Q1)
    end)
