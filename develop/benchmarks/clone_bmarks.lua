local evo = require 'evolved'
local basics = require 'develop.basics'

evo.debug_mode(false)

local N = 1000

local F1, F2, F3, F4, F5 = evo.id(5)
local D1, D2, D3, D4, D5 = evo.id(5)

evo.set(D1, evo.DEFAULT, true)
evo.set(D2, evo.DEFAULT, true)
evo.set(D3, evo.DEFAULT, true)
evo.set(D4, evo.DEFAULT, true)
evo.set(D5, evo.DEFAULT, true)

evo.set(D1, evo.DUPLICATE, function(v) return not v end)
evo.set(D2, evo.DUPLICATE, function(v) return not v end)
evo.set(D3, evo.DUPLICATE, function(v) return not v end)
evo.set(D4, evo.DUPLICATE, function(v) return not v end)
evo.set(D5, evo.DUPLICATE, function(v) return not v end)

local QF1 = evo.builder():include(F1):spawn()
local QD1 = evo.builder():include(D1):spawn()

local RF1 = evo.builder():require(F1):spawn()
local RF123 = evo.builder():require(F1, F2, F3):spawn()
local RF12345 = evo.builder():require(F1, F2, F3, F4, F5):spawn()

local RD1 = evo.builder():require(D1):spawn()
local RD123 = evo.builder():require(D1, D2, D3):spawn()
local RD12345 = evo.builder():require(D1, D2, D3, D4, D5):spawn()

print '----------------------------------------'

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Clone | %d entities with 1 component', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [F1] = true }

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Defer Clone | %d entities with 1 component', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [F1] = true }

        evo.defer()
        for _ = 1, N do
            clone(prefab)
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Clone With Defaults | %d entities with 1 component', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [D1] = true }

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Clone | %d entities with 3 components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [F1] = true, [F2] = true, [F3] = true }

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Defer Clone | %d entities with 3 components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [F1] = true, [F2] = true, [F3] = true }

        evo.defer()
        for _ = 1, N do
            clone(prefab)
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Clone With Defaults | %d entities with 3 components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [D1] = true, [D2] = true, [D3] = true }

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Clone | %d entities with 5 components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Defer Clone | %d entities with 5 components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        evo.defer()
        for _ = 1, N do
            clone(prefab)
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Clone With Defaults | %d entities with 5 components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [D1] = true, [D2] = true, [D3] = true, [D4] = true, [D5] = true }

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(QD1)
    end)

print '----------------------------------------'

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Clone | %d entities with 1 required component', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [RF1] = true }
        evo.remove(prefab, F1)

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Defer Clone | %d entities with 1 required component', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [RF1] = true }

        evo.defer()
        for _ = 1, N do
            clone(prefab)
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Clone With Defaults | %d entities with 1 required component', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [RD1] = true }

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Clone | %d entities with 3 required components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [RF123] = true }
        evo.remove(prefab, F1, F2, F3)

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Defer Clone | %d entities with 3 required components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [RF123] = true }

        evo.defer()
        for _ = 1, N do
            clone(prefab)
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Clone With Defaults | %d entities with 3 required components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [RD123] = true }

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Clone | %d entities with 5 required components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [RF12345] = true }
        evo.remove(prefab, F1, F2, F3, F4, F5)

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Defer Clone | %d entities with 5 required components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [RF12345] = true }

        evo.defer()
        for _ = 1, N do
            clone(prefab)
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Simple Clone With Defaults | %d entities with 5 required components', N),
    function()
        local clone = evo.clone

        local prefab = evo.spawn { [RD12345] = true }

        for _ = 1, N do
            clone(prefab)
        end

        evo.batch_destroy(QD1)
    end)

print '----------------------------------------'

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Clone | %d entities with 1 component', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [F1] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Defer Clone | %d entities with 1 component', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [F1] = true }

        evo.defer()
        multi_clone(N, prefab)
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Clone With Defaults | %d entities with 1 component', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [D1] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Clone | %d entities with 3 components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [F1] = true, [F2] = true, [F3] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Defer Clone | %d entities with 3 components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [F1] = true, [F2] = true, [F3] = true }

        evo.defer()
        multi_clone(N, prefab)
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Clone With Defaults | %d entities with 3 components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [D1] = true, [D2] = true, [D3] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Clone | %d entities with 5 components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Defer Clone | %d entities with 5 components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        evo.defer()
        multi_clone(N, prefab)
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Clone With Defaults | %d entities with 5 components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [D1] = true, [D2] = true, [D3] = true, [D4] = true, [D5] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(QD1)
    end)

print '----------------------------------------'

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Clone | %d entities with 1 required component', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [RF1] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Defer Clone | %d entities with 1 required component', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [RF1] = true }

        evo.defer()
        multi_clone(N, prefab)
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Clone With Defaults | %d entities with 1 required component', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [RD1] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Clone | %d entities with 3 required components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [RF123] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Defer Clone | %d entities with 3 required components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [RF123] = true }

        evo.defer()
        multi_clone(N, prefab)
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Clone With Defaults | %d entities with 3 required components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [RD123] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Clone | %d entities with 5 required components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [RF12345] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Defer Clone | %d entities with 5 required components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [RF12345] = true }

        evo.defer()
        multi_clone(N, prefab)
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Clone Benchmarks: Multi Clone With Defaults | %d entities with 5 required components', N),
    function()
        local multi_clone = evo.multi_clone

        local prefab = evo.spawn { [RD12345] = true }

        multi_clone(N, prefab)

        evo.batch_destroy(QD1)
    end)
