local basics = require 'develop.basics'
basics.unload 'evolved'

local evo = require 'evolved'

local N = 1000
local B = evo.builder()
local F1, F2, F3, F4, F5 = evo.id(5)
local Q1 = evo.builder():include(F1):spawn()
local R1 = evo.builder():require(F1):spawn()
local R2 = evo.builder():require(F1, F2):spawn()
local R3 = evo.builder():require(F1, F2, F3):spawn()
local R4 = evo.builder():require(F1, F2, F3, F4):spawn()
local R5 = evo.builder():require(F1, F2, F3, F4, F5):spawn()

print '----------------------------------------'

basics.describe_bench(string.format('create %d tables', N),
    ---@param tables table[]
    function(tables)
        for i = 1, N do
            local t = {}
            tables[i] = t
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and collect %d tables', N),
    ---@param tables table[]
    function(tables)
        for i = 1, N do
            local t = {}
            tables[i] = t
        end

        for i = 1, #tables do
            tables[i] = nil
        end

        collectgarbage('collect')
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create %d tables with 1 component / AoS', N),
    ---@param tables table
    function(tables)
        for i = 1, N do
            local e = {}
            e[F1] = true
            tables[i] = e
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create %d tables with 2 component / AoS', N),
    ---@param tables table
    function(tables)
        for i = 1, N do
            local e = {}
            e[F1] = true
            e[F2] = true
            tables[i] = e
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create %d tables with 3 component / AoS', N),
    ---@param tables table
    function(tables)
        for i = 1, N do
            local e = {}
            e[F1] = true
            e[F2] = true
            e[F3] = true
            tables[i] = e
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create %d tables with 4 component / AoS', N),
    ---@param tables table
    function(tables)
        for i = 1, N do
            local e = {}
            e[F1] = true
            e[F2] = true
            e[F3] = true
            e[F4] = true
            tables[i] = e
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create %d tables with 5 component / AoS', N),
    ---@param tables table
    function(tables)
        for i = 1, N do
            local e = {}
            e[F1] = true
            e[F2] = true
            e[F3] = true
            e[F4] = true
            e[F5] = true
            tables[i] = e
        end
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create %d tables with 1 component / SoA', N),
    ---@param tables table
    function(tables)
        local fs1 = {}
        for i = 1, N do
            local e = {}
            fs1[i] = true
            tables[i] = e
        end
        tables[F1] = fs1
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create %d tables with 2 component / SoA', N),
    ---@param tables table
    function(tables)
        local fs1 = {}
        local fs2 = {}
        for i = 1, N do
            local e = {}
            fs1[i] = true
            fs2[i] = true
            tables[i] = e
        end
        tables[F1] = fs1
        tables[F2] = fs2
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create %d tables with 3 component / SoA', N),
    ---@param tables table
    function(tables)
        local fs1 = {}
        local fs2 = {}
        local fs3 = {}
        for i = 1, N do
            local e = {}
            fs1[i] = true
            fs2[i] = true
            fs3[i] = true
            tables[i] = e
        end
        tables[F1] = fs1
        tables[F2] = fs2
        tables[F3] = fs3
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create %d tables with 4 component / SoA', N),
    ---@param tables table
    function(tables)
        local fs1 = {}
        local fs2 = {}
        local fs3 = {}
        local fs4 = {}
        for i = 1, N do
            local e = {}
            fs1[i] = i
            fs2[i] = i
            fs3[i] = i
            fs4[i] = i
            tables[i] = e
        end
        tables[F1] = fs1
        tables[F2] = fs2
        tables[F3] = fs3
        tables[F4] = fs4
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create %d tables with 5 component / SoA', N),
    ---@param tables table
    function(tables)
        local fs1 = {}
        local fs2 = {}
        local fs3 = {}
        local fs4 = {}
        local fs5 = {}
        for i = 1, N do
            local e = {}
            fs1[i] = i
            fs2[i] = i
            fs3[i] = i
            fs4[i] = i
            fs5[i] = i
            tables[i] = e
        end
        tables[F1] = fs1
        tables[F2] = fs2
        tables[F3] = fs3
        tables[F4] = fs4
        tables[F5] = fs5
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create and destroy %d entities', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local destroy = evo.destroy

        for i = 1, N do
            local e = id()
            entities[i] = e
        end

        for i = #entities, 1, -1 do
            destroy(entities[i])
        end
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 1 component', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        for i = 1, N do
            local e = id()
            set(e, F1)
            entities[i] = e
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 2 components', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        for i = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            entities[i] = e
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 3 components', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        for i = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            set(e, F3)
            entities[i] = e
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 4 components', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        for i = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            set(e, F3)
            set(e, F4)
            entities[i] = e
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 5 components', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        for i = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            set(e, F3)
            set(e, F4)
            set(e, F5)
            entities[i] = e
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create and destroy %d entities with 1 components / defer', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        evo.defer()
        for i = 1, N do
            local e = id()
            set(e, F1)
            entities[i] = e
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 2 components / defer', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        evo.defer()
        for i = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            entities[i] = e
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 3 components / defer', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        evo.defer()
        for i = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            set(e, F3)
            entities[i] = e
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 4 components / defer', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        evo.defer()
        for i = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            set(e, F3)
            set(e, F4)
            entities[i] = e
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 5 components / defer', N),
    ---@param entities evolved.id[]
    function(entities)
        local id = evo.id
        local set = evo.set

        evo.defer()
        for i = 1, N do
            local e = id()
            set(e, F1)
            set(e, F2)
            set(e, F3)
            set(e, F4)
            set(e, F5)
            entities[i] = e
        end
        evo.commit()

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create and destroy %d entities with 1 components / builder', N),
    ---@param entities evolved.id[]
    function(entities)
        local set = B.set
        local spawn = B.spawn

        for i = 1, N do
            set(B, F1)
            entities[i] = spawn(B)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 2 components / builder', N),
    ---@param entities evolved.id[]
    function(entities)
        local set = B.set
        local spawn = B.spawn

        for i = 1, N do
            set(B, F1)
            set(B, F2)
            entities[i] = spawn(B)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 3 components / builder', N),
    ---@param entities evolved.id[]
    function(entities)
        local set = B.set
        local spawn = B.spawn

        for i = 1, N do
            set(B, F1)
            set(B, F2)
            set(B, F3)
            entities[i] = spawn(B)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 4 components / builder', N),
    ---@param entities evolved.id[]
    function(entities)
        local set = B.set
        local spawn = B.spawn

        for i = 1, N do
            set(B, F1)
            set(B, F2)
            set(B, F3)
            set(B, F4)
            entities[i] = spawn(B)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 5 components / builder', N),
    ---@param entities evolved.id[]
    function(entities)
        local set = B.set
        local spawn = B.spawn

        for i = 1, N do
            set(B, F1)
            set(B, F2)
            set(B, F3)
            set(B, F4)
            set(B, F5)
            entities[i] = spawn(B)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create and destroy %d entities with 1 components / spawn', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn = evo.spawn

        local components = { [F1] = true }

        for i = 1, N do
            entities[i] = spawn(components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 2 components / spawn', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn = evo.spawn

        local components = { [F1] = true, [F2] = true }

        for i = 1, N do
            entities[i] = spawn(components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 3 components / spawn', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn = evo.spawn

        local components = { [F1] = true, [F2] = true, [F3] = true }

        for i = 1, N do
            entities[i] = spawn(components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 4 components / spawn', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn = evo.spawn

        local components = { [F1] = true, [F2] = true, [F3] = true, [F4] = true }

        for i = 1, N do
            entities[i] = spawn(components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 5 components / spawn', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn = evo.spawn

        local components = { [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true }

        for i = 1, N do
            entities[i] = spawn(components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create and destroy %d entities with 1 components / clone', N),
    ---@param entities evolved.id[]
    function(entities)
        local clone = evo.clone

        local prefab = evo.spawn({ [F1] = true })

        for i = 1, N do
            entities[i] = clone(prefab)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 2 components / clone', N),
    ---@param entities evolved.id[]
    function(entities)
        local clone = evo.clone

        local prefab = evo.spawn({ [F1] = true, [F2] = true })

        for i = 1, N do
            entities[i] = clone(prefab)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 3 components / clone', N),
    ---@param entities evolved.id[]
    function(entities)
        local clone = evo.clone

        local prefab = evo.spawn({ [F1] = true, [F2] = true, [F3] = true })

        for i = 1, N do
            entities[i] = clone(prefab)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 4 components / clone', N),
    ---@param entities evolved.id[]
    function(entities)
        local clone = evo.clone

        local prefab = evo.spawn({ [F1] = true, [F2] = true, [F3] = true, [F4] = true })

        for i = 1, N do
            entities[i] = clone(prefab)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 5 components / clone', N),
    ---@param entities evolved.id[]
    function(entities)
        local clone = evo.clone

        local prefab = evo.spawn({ [F1] = true, [F2] = true, [F3] = true, [F4] = true, [F5] = true })

        for i = 1, N do
            entities[i] = clone(prefab)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create and destroy %d entities with 1 requires / spawn', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn = evo.spawn

        local components = { [R1] = true }

        for i = 1, N do
            entities[i] = spawn(components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 2 requires / spawn', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn = evo.spawn

        local components = { [R2] = true }

        for i = 1, N do
            entities[i] = spawn(components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 3 requires / spawn', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn = evo.spawn

        local components = { [R3] = true }

        for i = 1, N do
            entities[i] = spawn(components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 4 requires / spawn', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn = evo.spawn

        local components = { [R4] = true }

        for i = 1, N do
            entities[i] = spawn(components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 5 requires / spawn', N),
    ---@param entities evolved.id[]
    function(entities)
        local spawn = evo.spawn

        local components = { [R5] = true }

        for i = 1, N do
            entities[i] = spawn(components)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

print '----------------------------------------'

basics.describe_bench(string.format('create and destroy %d entities with 1 requires / clone', N),
    ---@param entities evolved.id[]
    function(entities)
        local clone = evo.clone

        local prefab = evo.spawn({ [R1] = true })

        for i = 1, N do
            entities[i] = clone(prefab)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 2 requires / clone', N),
    ---@param entities evolved.id[]
    function(entities)
        local clone = evo.clone

        local prefab = evo.spawn({ [R2] = true })

        for i = 1, N do
            entities[i] = clone(prefab)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 3 requires / clone', N),
    ---@param entities evolved.id[]
    function(entities)
        local clone = evo.clone

        local prefab = evo.spawn({ [R3] = true })

        for i = 1, N do
            entities[i] = clone(prefab)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 4 requires / clone', N),
    ---@param entities evolved.id[]
    function(entities)
        local clone = evo.clone

        local prefab = evo.spawn({ [R4] = true })

        for i = 1, N do
            entities[i] = clone(prefab)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)

basics.describe_bench(string.format('create and destroy %d entities with 5 requires / clone', N),
    ---@param entities evolved.id[]
    function(entities)
        local clone = evo.clone

        local prefab = evo.spawn({ [R5] = true })

        for i = 1, N do
            entities[i] = clone(prefab)
        end

        evo.batch_destroy(Q1)
    end, function()
        return {}
    end)
