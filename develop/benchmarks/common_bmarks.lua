local evo = require 'evolved'
local basics = require 'develop.basics'

local tiny = require 'develop.3rdparty.tiny'

evo.debug_mode(false)

local N = 1000

print '----------------------------------------'

basics.describe_bench(string.format('Common Benchmarks: Tiny Entity Cycle | %d entities', N),
    function(world)
        world:update()
    end, function()
        local world = tiny.world()

        for _ = 1, N do
            world:addEntity({ a = 0 })
        end

        local A = tiny.processingSystem()
        A.filter = tiny.requireAll('a')
        A.process = function(_, e) world:addEntity({ b = e.a }) end
        A.postProcess = function(_) world:refresh() end

        local B = tiny.processingSystem()
        B.filter = tiny.requireAll('b')
        B.process = function(_, e) world:removeEntity(e) end
        B.postProcess = function(_) world:refresh() end

        world:addSystem(A)
        world:addSystem(B)

        world:refresh()

        return world
    end)

basics.describe_bench(string.format('Common Benchmarks: Evolved Entity Cycle | %d entities', N),
    function(world)
        evo.process(world)
    end, function()
        local world = evo.builder()
            :destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
            :spawn()

        local a = evo.builder():set(world):spawn()
        local b = evo.builder():set(world):spawn()

        local query_a = evo.builder():set(world):include(a):spawn()
        local query_b = evo.builder():set(world):include(b):spawn()

        local prefab_a = evo.builder():prefab():set(world):set(a, 0):spawn()
        local prefab_b = evo.builder():prefab():set(world):set(b, 0):spawn()

        evo.multi_clone_nr(N, prefab_a)

        evo.builder()
            :set(world):group(world):query(query_a)
            :execute(function(chunk, _, entity_count)
                local as = chunk:components(a)
                local entity_bs = evo.multi_clone(entity_count, prefab_b)
                for i = 1, entity_count do evo.set(entity_bs[i], b, as[i]) end
            end):spawn()

        evo.builder()
            :set(world):group(world):query(query_b)
            :prologue(function()
                evo.batch_destroy(query_b)
            end):spawn()

        return world
    end, function(world)
        evo.destroy(world)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Common Benchmarks: Tiny Simple Iteration | %d entities', N),
    function(world)
        world:update()
    end, function()
        local world = tiny.world()

        for _ = 1, N do
            world:addEntity({ a = 0, b = 0 })
            world:addEntity({ a = 0, b = 0, c = 0 })
            world:addEntity({ a = 0, b = 0, c = 0, d = 0 })
            world:addEntity({ a = 0, b = 0, c = 0, e = 0 })
        end

        local AB = tiny.processingSystem()
        AB.filter = tiny.requireAll('a', 'b')
        AB.process = function(_, e) e.a, e.b = e.b, e.a end

        local CD = tiny.processingSystem()
        CD.filter = tiny.requireAll('c', 'd')
        CD.process = function(_, e) e.c, e.d = e.d, e.c end

        local CE = tiny.processingSystem()
        CE.filter = tiny.requireAll('c', 'e')
        CE.process = function(_, e) e.c, e.e = e.e, e.c end

        world:addSystem(AB)
        world:addSystem(CD)
        world:addSystem(CE)

        world:refresh()

        return world
    end)

basics.describe_bench(string.format('Common Benchmarks: Evolved Simple Iteration | %d entities', N),
    function(world)
        evo.process(world)
    end, function()
        local world = evo.builder()
            :destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
            :spawn()

        local a = evo.builder():set(world):spawn()
        local b = evo.builder():set(world):spawn()
        local c = evo.builder():set(world):spawn()
        local d = evo.builder():set(world):spawn()
        local e = evo.builder():set(world):spawn()

        local query_ab = evo.builder():set(world):include(a, b):spawn()
        local query_cd = evo.builder():set(world):include(c, d):spawn()
        local query_ce = evo.builder():set(world):include(c, e):spawn()

        evo.multi_spawn_nr(N, { [world] = true, [a] = 0, [b] = 0 })
        evo.multi_spawn_nr(N, { [world] = true, [a] = 0, [b] = 0, [c] = 0 })
        evo.multi_spawn_nr(N, { [world] = true, [a] = 0, [b] = 0, [c] = 0, [d] = 0 })
        evo.multi_spawn_nr(N, { [world] = true, [a] = 0, [b] = 0, [c] = 0, [e] = 0 })

        evo.builder()
            :set(world):group(world):query(query_ab)
            :execute(function(chunk, _, entity_count)
                local as, bs = chunk:components(a, b)
                for i = 1, entity_count do as[i], bs[i] = bs[i], as[i] end
            end):spawn()

        evo.builder()
            :set(world):group(world):query(query_cd)
            :execute(function(chunk, _, entity_count)
                local cs, ds = chunk:components(c, d)
                for i = 1, entity_count do cs[i], ds[i] = ds[i], cs[i] end
            end):spawn()

        evo.builder()
            :set(world):group(world):query(query_ce)
            :execute(function(chunk, _, entity_count)
                local cs, es = chunk:components(c, e)
                for i = 1, entity_count do cs[i], es[i] = es[i], cs[i] end
            end):spawn()

        return world
    end, function(world)
        evo.destroy(world)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Common Benchmarks: Tiny Packed Iteration | %d entities', N),
    function(world)
        world:update()
    end, function()
        local world = tiny.world()

        for _ = 1, N do
            world:addEntity({ a = 0, b = 0, c = 0, d = 0, e = 0 })
        end

        local A = tiny.processingSystem()
        A.filter = tiny.requireAll('a')
        A.process = function(_, e) e.a = e.a * 2 end

        local B = tiny.processingSystem()
        B.filter = tiny.requireAll('b')
        B.process = function(_, e) e.b = e.b * 2 end

        local C = tiny.processingSystem()
        C.filter = tiny.requireAll('c')
        C.process = function(_, e) e.c = e.c * 2 end

        local D = tiny.processingSystem()
        D.filter = tiny.requireAll('d')
        D.process = function(_, e) e.d = e.d * 2 end

        local E = tiny.processingSystem()
        E.filter = tiny.requireAll('e')
        E.process = function(_, e) e.e = e.e * 2 end

        world:addSystem(A)
        world:addSystem(B)
        world:addSystem(C)
        world:addSystem(D)
        world:addSystem(E)

        world:refresh()

        return world
    end)

basics.describe_bench(string.format('Common Benchmarks: Evolved Packed Iteration | %d entities', N),
    function(world)
        evo.process(world)
    end, function()
        local world = evo.builder()
            :destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
            :spawn()

        local a = evo.builder():set(world):spawn()
        local b = evo.builder():set(world):spawn()
        local c = evo.builder():set(world):spawn()
        local d = evo.builder():set(world):spawn()
        local e = evo.builder():set(world):spawn()

        local query_a = evo.builder():set(world):include(a):spawn()
        local query_b = evo.builder():set(world):include(b):spawn()
        local query_c = evo.builder():set(world):include(c):spawn()
        local query_d = evo.builder():set(world):include(d):spawn()
        local query_e = evo.builder():set(world):include(e):spawn()

        evo.multi_spawn_nr(N, { [world] = true, [a] = 0, [b] = 0, [c] = 0, [d] = 0, [e] = 0 })

        evo.builder()
            :set(world):group(world):query(query_a)
            :execute(function(chunk, _, entity_count)
                local as = chunk:components(a)
                for i = 1, entity_count do as[i] = as[i] * 2 end
            end):spawn()

        evo.builder()
            :set(world):group(world):query(query_b)
            :execute(function(chunk, _, entity_count)
                local bs = chunk:components(b)
                for i = 1, entity_count do bs[i] = bs[i] * 2 end
            end):spawn()

        evo.builder()
            :set(world):group(world):query(query_c)
            :execute(function(chunk, _, entity_count)
                local cs = chunk:components(c)
                for i = 1, entity_count do cs[i] = cs[i] * 2 end
            end):spawn()

        evo.builder()
            :set(world):group(world):query(query_d)
            :execute(function(chunk, _, entity_count)
                local ds = chunk:components(d)
                for i = 1, entity_count do ds[i] = ds[i] * 2 end
            end):spawn()

        evo.builder()
            :set(world):group(world):query(query_e)
            :execute(function(chunk, _, entity_count)
                local es = chunk:components(e)
                for i = 1, entity_count do es[i] = es[i] * 2 end
            end):spawn()

        return world
    end, function(world)
        evo.destroy(world)
    end)

print '----------------------------------------'

basics.describe_bench(string.format('Common Benchmarks: Tiny Fragmented Iteration | %d entities', N),
    function(world)
        world:update()
    end, function()
        local world = tiny.world()

        ---@type string[]
        local chars = {}

        for i = 1, 26 do
            chars[i] = string.char(string.byte('a') + i - 1)
        end

        for i, char in ipairs(chars) do
            for _ = 1, N do
                world:addEntity({ [char] = i, data = i })
            end
        end

        local Data = tiny.processingSystem()
        Data.filter = tiny.requireAll('data')
        Data.process = function(_, e) e.data = e.data * 2 end

        local Last = tiny.processingSystem()
        Last.filter = tiny.requireAll('z')
        Last.process = function(_, e) e.z = e.z * 2 end

        world:addSystem(Data)
        world:addSystem(Last)

        world:refresh()

        return world
    end)

basics.describe_bench(string.format('Common Benchmarks: Evolved Fragmented Iteration | %d entities', N),
    function(world)
        evo.process(world)
    end, function()
        local world = evo.builder()
            :destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
            :spawn()

        local data = evo.spawn { [world] = true }
        local chars = evo.multi_spawn(26, { [world] = true })

        local query_data = evo.builder():set(world):include(data):spawn()
        local query_z = evo.builder():set(world):include(chars[#chars]):spawn()

        for i = 1, #chars do
            evo.multi_spawn_nr(N, { [world] = true, [chars[i]] = i, [data] = i })
        end

        evo.builder()
            :set(world):group(world):query(query_data)
            :execute(function(chunk, _, entity_count)
                local datas = chunk:components(data)
                for i = 1, entity_count do datas[i] = datas[i] * 2 end
            end):spawn()

        evo.builder()
            :set(world):group(world):query(query_z)
            :execute(function(chunk, _, entity_count)
                local zs = chunk:components(chars[#chars])
                for i = 1, entity_count do zs[i] = zs[i] * 2 end
            end):spawn()

        return world
    end, function(world)
        evo.destroy(world)
    end)
