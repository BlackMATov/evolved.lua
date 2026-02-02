local evo = require 'evolved'

evo.debug_mode(true)

do
    local f1, f2 = evo.id(2)

    do
        local e = evo.builder():set(f1, 42):set(f2, 'hello'):build()
        assert(evo.has(e, f1) and evo.get(e, f1) == 42)
        assert(evo.has(e, f2) and evo.get(e, f2) == 'hello')
    end

    do
        local p = evo.builder():set(f1, 42):build()
        local e = evo.builder():set(f2, 'hello'):build(p)
        assert(evo.has(e, f1) and evo.get(e, f1) == 42)
        assert(evo.has(e, f2) and evo.get(e, f2) == 'hello')
    end

    do
        local entity_list, entity_count = evo.builder():set(f1, 42):set(f2, 'hello'):multi_build(5)
        assert(entity_count == 5)

        for i = 1, entity_count do
            local e = entity_list[i]
            assert(evo.has(e, f1) and evo.get(e, f1) == 42)
            assert(evo.has(e, f2) and evo.get(e, f2) == 'hello')
        end
    end

    do
        local p = evo.builder():set(f1, 42):build()
        local entity_list, entity_count = evo.builder():set(f2, 'hello'):multi_build(5, p)
        assert(entity_count == 5)

        for i = 1, entity_count do
            local e = entity_list[i]
            assert(evo.has(e, f1) and evo.get(e, f1) == 42)
            assert(evo.has(e, f2) and evo.get(e, f2) == 'hello')
        end
    end
end
