local evo = require 'evolved'
local basics = require 'develop.basics'

evo.debug_mode(false)

local N = 1000

print '----------------------------------------'

local Q_NAME = evo.builder():include(evo.NAME):spawn()

local F1 = evo.id()
local Q_F1 = evo.builder():include(F1):spawn()

basics.describe_bench(
    string.format('Registry Benchmarks: Spawn + Set Generic | %d entities', N),
    function()
        local id_fn = evo.id
        local set = evo.set

        for _ = 1, N do
            local e = id_fn()
            set(e, F1, true)
        end

        evo.batch_destroy(Q_F1)
    end)

basics.describe_bench(
    string.format('Registry Benchmarks: Spawn + Set Name | %d entities', N),
    function()
        local id_fn = evo.id
        local set = evo.set
        local NAME = evo.NAME

        for i = 1, N do
            local e = id_fn()
            set(e, NAME, "Entity_" .. i)
        end

        evo.batch_destroy(Q_NAME)
    end)

basics.describe_bench(
    string.format('Registry Benchmarks: Register Helper | %d entities', N),
    function()
        local register = evo.register

        for i = 1, N do
            register("Entity_" .. i)
        end

        evo.batch_destroy(Q_NAME)
    end)

basics.describe_bench(
    string.format('Registry Benchmarks: Find Name | %d lookups', N),
    function()
        local find = evo.find
        for i = 1, N do
            find("Entity_" .. i)
        end
    end,
    function()
        for i = 1, N do
            evo.register("Entity_" .. i)
        end
    end,
    function()
        evo.batch_destroy(Q_NAME)
    end
)
