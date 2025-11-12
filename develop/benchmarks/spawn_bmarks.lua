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

basics.describe_bench(string.format('Spawn Benchmarks: Simple Spawn | %d entities with 1 component', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Simple Defer Spawn | %d entities with 1 component', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true }

        evo.defer()
        for _ = 1, N do
            spawn(components)
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Simple Spawn | %d entities with 3 components', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true, [F2] = true, [F3] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Simple Defer Spawn | %d entities with 3 components', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true, [F2] = true, [F3] = true }

        evo.defer()
        for _ = 1, N do
            spawn(components)
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Simple Spawn | %d entities with 5 components', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Simple Defer Spawn | %d entities with 5 components', N),
    function()
        local spawn = evo.spawn

        local components = { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        evo.defer()
        for _ = 1, N do
            spawn(components)
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Spawn Benchmarks: Simple Spawn | %d entities with 1 required component', N),
    function()
        local spawn = evo.spawn

        local components = { [R1] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Simple Defer Spawn | %d entities with 1 required component', N),
    function()
        local spawn = evo.spawn

        local components = { [R1] = true }

        evo.defer()
        for _ = 1, N do
            spawn(components)
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Simple Spawn | %d entities with 3 required components', N),
    function()
        local spawn = evo.spawn

        local components = { [R3] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Simple Defer Spawn | %d entities with 3 required components', N),
    function()
        local spawn = evo.spawn

        local components = { [R3] = true }

        evo.defer()
        for _ = 1, N do
            spawn(components)
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Simple Spawn | %d entities with 5 required components', N),
    function()
        local spawn = evo.spawn

        local components = { [R5] = true }

        for _ = 1, N do
            spawn(components)
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Simple Defer Spawn | %d entities with 5 required components', N),
    function()
        local spawn = evo.spawn

        local components = { [R5] = true }

        evo.defer()
        for _ = 1, N do
            spawn(components)
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 1 component', N),
    function()
        local builder = evo.builder():set(F1)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Defer Spawn | %d entities with 1 component', N),
    function()
        local builder = evo.builder():set(F1)

        evo.defer()
        for _ = 1, N do
            builder:spawn()
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 3 components', N),
    function()
        local builder = evo.builder():set(F1):set(F2):set(F3)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Defer Spawn | %d entities with 3 components', N),
    function()
        local builder = evo.builder():set(F1):set(F2):set(F3)

        evo.defer()
        for _ = 1, N do
            builder:spawn()
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 5 components', N),
    function()
        local builder = evo.builder():set(F1):set(F2):set(F3):set(F4):set(F5)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Defer Spawn | %d entities with 5 components', N),
    function()
        local builder = evo.builder():set(F1):set(F2):set(F3):set(F4):set(F5)

        evo.defer()
        for _ = 1, N do
            builder:spawn()
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 1 required component', N),
    function()
        local builder = evo.builder():set(R1)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Defer Spawn | %d entities with 1 required component', N),
    function()
        local builder = evo.builder():set(R1)

        evo.defer()
        for _ = 1, N do
            builder:spawn()
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 3 required components', N),
    function()
        local builder = evo.builder():set(R3)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Defer Spawn | %d entities with 3 required components', N),
    function()
        local builder = evo.builder():set(R3)

        evo.defer()
        for _ = 1, N do
            builder:spawn()
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Spawn | %d entities with 5 required components', N),
    function()
        local builder = evo.builder():set(R5)

        for _ = 1, N do
            builder:spawn()
        end

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Builder Defer Spawn | %d entities with 5 required components', N),
    function()
        local builder = evo.builder():set(R5)

        evo.defer()
        for _ = 1, N do
            builder:spawn()
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Spawn Benchmarks: Multi Spawn | %d entities with 1 component', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true }

        multi_spawn(N, components)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Multi Defer Spawn | %d entities with 1 component', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true }

        evo.defer()
        multi_spawn(N, components)
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Multi Spawn | %d entities with 3 components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true, [F2] = true, [F3] = true }

        multi_spawn(N, components)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Multi Defer Spawn | %d entities with 3 components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true, [F2] = true, [F3] = true }

        evo.defer()
        multi_spawn(N, components)
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Multi Spawn | %d entities with 5 components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        multi_spawn(N, components)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Multi Defer Spawn | %d entities with 5 components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        evo.defer()
        multi_spawn(N, components)
        evo.commit()

        evo.batch_destroy(Q1)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Spawn Benchmarks: Multi Spawn | %d entities with 1 required component', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true }

        multi_spawn(N, components)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Multi Defer Spawn | %d entities with 1 required component', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [F1] = true }

        evo.defer()
        multi_spawn(N, components)
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Multi Spawn | %d entities with 3 required components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [R3] = true }

        multi_spawn(N, components)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Multi Defer Spawn | %d entities with 3 required components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [R3] = true }

        evo.defer()
        multi_spawn(N, components)
        evo.commit()

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Multi Spawn | %d entities with 5 required components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [R5] = true }

        multi_spawn(N, components)

        evo.batch_destroy(Q1)
    end)

basics.describe_bench(string.format('Spawn Benchmarks: Multi Defer Spawn | %d entities with 5 required components', N),
    function()
        local multi_spawn = evo.multi_spawn

        local components = { [R5] = true }

        evo.defer()
        multi_spawn(N, components)
        evo.commit()

        evo.batch_destroy(Q1)
    end)
