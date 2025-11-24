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
    string.format('Spawn Benchmarks: Simple Spawn | %d entities with 1 component', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Defer Spawn | %d entities with 1 component', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true }

        evo.defer()
        for _ = 1, N do
            spawn(components)
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Spawn With Defaults | %d entities with 1 component', N),
    function()
        local spawn = evo.spawn

        local components = { [D1] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Spawn | %d entities with 3 components', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true, [F2] = true, [F3] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Defer Spawn | %d entities with 3 components', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true, [F2] = true, [F3] = true }

        evo.defer()
        for _ = 1, N do
            spawn(components)
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Spawn With Defaults | %d entities with 3 components', N),
    function()
        local spawn = evo.spawn

        local components = { [D1] = true, [D2] = true, [D3] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Spawn | %d entities with 5 components', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Defer Spawn | %d entities with 5 components', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        evo.defer()
        for _ = 1, N do
            spawn(components)
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Spawn With Defaults | %d entities with 5 components', N),
    function()
        local spawn = evo.spawn

        local components = { [D1] = true, [D2] = true, [D3] = true, [D4] = true, [D5] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(QD1)
    end)

print '----------------------------------------'

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Spawn | %d entities with 1 required component', N),
    function()
        local spawn = evo.spawn

        local components = { [RF1] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Defer Spawn | %d entities with 1 required component', N),
    function()
        local spawn = evo.spawn

        local components = { [RF1] = true }

        evo.defer()
        for _ = 1, N do
            spawn(components)
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Spawn With Defaults | %d entities with 1 required component', N),
    function()
        local spawn = evo.spawn

        local components = { [RD1] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Spawn | %d entities with 3 required components', N),
    function()
        local spawn = evo.spawn

        local components = { [RF123] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Defer Spawn | %d entities with 3 required components', N),
    function()
        local spawn = evo.spawn

        local components = { [RF123] = true }

        evo.defer()
        for _ = 1, N do
            spawn(components)
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Spawn With Defaults | %d entities with 3 required components', N),
    function()
        local spawn = evo.spawn

        local components = { [RD123] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Spawn | %d entities with 5 required components', N),
    function()
        local spawn = evo.spawn

        local components = { [RF12345] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Defer Spawn | %d entities with 5 required components', N),
    function()
        local spawn = evo.spawn

        local components = { [RF12345] = true }

        evo.defer()
        for _ = 1, N do
            spawn(components)
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Simple Spawn With Defaults | %d entities with 5 required components', N),
    function()
        local spawn = evo.spawn

        local components = { [RD12345] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(QD1)
    end)

print '----------------------------------------'

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Spawn | %d entities with 1 component', N),
    function()
        local builder = evo.builder():set(F1)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Defer Spawn | %d entities with 1 component', N),
    function()
        local builder = evo.builder():set(F1)

        evo.defer()
        for _ = 1, N do
            builder:spawn()
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Spawn With Defaults | %d entities with 1 component', N),
    function()
        local builder = evo.builder():set(D1)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Spawn | %d entities with 3 components', N),
    function()
        local builder = evo.builder():set(F1):set(F2):set(F3)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Defer Spawn | %d entities with 3 components', N),
    function()
        local builder = evo.builder():set(F1):set(F2):set(F3)

        evo.defer()
        for _ = 1, N do
            builder:spawn()
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Spawn With Defaults | %d entities with 3 components', N),
    function()
        local builder = evo.builder():set(D1):set(D2):set(D3)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Spawn | %d entities with 5 components', N),
    function()
        local builder = evo.builder():set(F1):set(F2):set(F3):set(F4):set(F5)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Defer Spawn | %d entities with 5 components', N),
    function()
        local builder = evo.builder():set(F1):set(F2):set(F3):set(F4):set(F5)

        evo.defer()
        for _ = 1, N do
            builder:spawn()
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Spawn With Defaults | %d entities with 5 components', N),
    function()
        local builder = evo.builder():set(D1):set(D2):set(D3):set(D4):set(D5)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(QD1)
    end)

print '----------------------------------------'

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Spawn | %d entities with 1 required component', N),
    function()
        local builder = evo.builder():set(RF1)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Defer Spawn | %d entities with 1 required component', N),
    function()
        local builder = evo.builder():set(RF1)

        evo.defer()
        for _ = 1, N do
            builder:spawn()
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Spawn With Defaults | %d entities with 1 required component', N),
    function()
        local builder = evo.builder():set(RD1)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Spawn | %d entities with 3 required components', N),
    function()
        local builder = evo.builder():set(RF123)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Defer Spawn | %d entities with 3 required components', N),
    function()
        local builder = evo.builder():set(RF123)

        evo.defer()
        for _ = 1, N do
            builder:spawn()
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Spawn With Defaults | %d entities with 3 required components', N),
    function()
        local builder = evo.builder():set(RD123)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Spawn | %d entities with 5 required components', N),
    function()
        local builder = evo.builder():set(RF12345)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Defer Spawn | %d entities with 5 required components', N),
    function()
        local builder = evo.builder():set(RF12345)

        evo.defer()
        for _ = 1, N do
            builder:spawn()
        end
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Builder Spawn With Defaults | %d entities with 5 required components', N),
    function()
        local builder = evo.builder():set(RD12345)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(QD1)
    end)

print '----------------------------------------'

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Spawn | %d entities with 1 component', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true }

        multi_spawn(N, components)

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Defer Spawn | %d entities with 1 component', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true }

        evo.defer()
        multi_spawn(N, components)
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Spawn With Defaults | %d entities with 1 component', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [D1] = true }

        multi_spawn(N, components)

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Spawn | %d entities with 3 components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true, [F2] = true, [F3] = true }

        multi_spawn(N, components)

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Defer Spawn | %d entities with 3 components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true, [F2] = true, [F3] = true }

        evo.defer()
        multi_spawn(N, components)
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Spawn With Defaults | %d entities with 3 components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [D1] = true, [D2] = true, [D3] = true }

        multi_spawn(N, components)

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Spawn | %d entities with 5 components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        multi_spawn(N, components)

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Defer Spawn | %d entities with 5 components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        evo.defer()
        multi_spawn(N, components)
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Spawn With Defaults | %d entities with 5 components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [D1] = true, [D2] = true, [D3] = true, [D4] = true, [D5] = true }

        multi_spawn(N, components)

        evo.batch_destroy(QD1)
    end)

print '----------------------------------------'

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Spawn | %d entities with 1 required component', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true }

        multi_spawn(N, components)

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Defer Spawn | %d entities with 1 required component', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true }

        evo.defer()
        multi_spawn(N, components)
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Spawn With Defaults | %d entities with 1 required component', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [D1] = true }

        multi_spawn(N, components)

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Spawn | %d entities with 3 required components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [RF123] = true }

        multi_spawn(N, components)

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Defer Spawn | %d entities with 3 required components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [RF123] = true }

        evo.defer()
        multi_spawn(N, components)
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Spawn With Defaults | %d entities with 3 required components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [RD123] = true }

        multi_spawn(N, components)

        evo.batch_destroy(QD1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Spawn | %d entities with 5 required components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [RF12345] = true }

        multi_spawn(N, components)

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Defer Spawn | %d entities with 5 required components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [RF12345] = true }

        evo.defer()
        multi_spawn(N, components)
        evo.commit()

        evo.batch_destroy(QF1)
    end)

basics.describe_bench(
    string.format('Spawn Benchmarks: Multi Spawn With Defaults | %d entities with 5 required components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [RD12345] = true }

        multi_spawn(N, components)

        evo.batch_destroy(QD1)
    end)
