local evo = require 'evolved'

evo.debug_mode(true)

do
    local f1, f2 = evo.id(2)
    local q = evo.builder():include(f1):spawn()
    local q_ex = evo.builder():include(f1):exclude(f2):spawn()

    do
        assert(evo.search(q) == nil)

        local entity_list, entity_count = evo.multi_search(q)
        assert(entity_list and #entity_list == 0 and entity_count == 0)
    end

    local e1 = evo.builder():set(f1, 1):spawn()
    local e2 = evo.builder():set(f1, 2):set(f2, 3):spawn()
    local e3 = evo.builder():set(f1, 4):spawn()

    do
        local e = evo.search(q)
        assert(e == e1 or e == e2 or e == e3)
        assert(evo.search(q_ex) == e1 or evo.search(q_ex) == e3)
    end

    do
        local entity_list, entity_count = evo.multi_search(q)
        assert(entity_count == 3 and #entity_list == 3)

        local entity_set = {}
        for i = 1, entity_count do entity_set[entity_list[i]] = true end
        assert(entity_set[e1] and entity_set[e2] and entity_set[e3])
    end

    do
        local entity_list, entity_count = evo.multi_search(q_ex)
        assert(entity_count == 2 and #entity_list == 2)

        local entity_set = {}
        for i = 1, entity_count do entity_set[entity_list[i]] = true end
        assert(entity_set[e1] and entity_set[e3] and not entity_set[e2])
    end

    do
        local entity_list = { 'a', 'b' }
        local entity_count = evo.multi_search_to(entity_list, 3, q)

        assert(entity_count == 3 and #entity_list == 5)
        assert(entity_list[1] == 'a' and entity_list[2] == 'b')

        local entity_set = {}
        for i = 3, 3 + entity_count - 1 do entity_set[entity_list[i]] = true end
        assert(entity_set[e1] and entity_set[e2] and entity_set[e3])
    end
end
