local evo = require 'evolved'

evo.debug_mode(true)

do
    local e1, e2, e3 = evo.id(3)

    do
        assert(evo.lookup('lookup_hello') == nil)
        assert(evo.lookup('lookup_world') == nil)

        do
            local entity_list, entity_count = evo.multi_lookup('lookup_hello')
            assert(entity_list and #entity_list == 0 and entity_count == 0)
        end

        do
            local entity_list, entity_count = evo.multi_lookup('lookup_world')
            assert(entity_list and #entity_list == 0 and entity_count == 0)
        end
    end

    evo.set(e1, evo.NAME, 'lookup_hello')

    do
        assert(evo.lookup('lookup_hello') == e1)
        assert(evo.lookup('lookup_world') == nil)

        do
            local entity_list, entity_count = evo.multi_lookup('lookup_hello')
            assert(entity_list and #entity_list == 1 and entity_count == 1)
            assert(entity_list[1] == e1)
        end

        do
            local entity_list, entity_count = evo.multi_lookup('lookup_world')
            assert(entity_list and #entity_list == 0 and entity_count == 0)
        end
    end

    evo.set(e2, evo.NAME, 'lookup_hello')
    evo.set(e3, evo.NAME, 'lookup_hello')

    do
        assert(evo.lookup('lookup_hello') == e1)
        assert(evo.lookup('lookup_world') == nil)

        do
            local entity_list, entity_count = evo.multi_lookup('lookup_hello')
            assert(entity_list and #entity_list == 3 and entity_count == 3)
            assert(entity_list[1] == e1 and entity_list[2] == e2 and entity_list[3] == e3)
        end
    end

    evo.set(e2, evo.NAME, 'lookup_world')

    do
        assert(evo.lookup('lookup_hello') == e1)
        assert(evo.lookup('lookup_world') == e2)

        do
            local entity_list, entity_count = evo.multi_lookup('lookup_hello')
            assert(entity_list and #entity_list == 2 and entity_count == 2)
            assert(entity_list[1] == e1 and entity_list[2] == e3)
        end

        do
            local entity_list, entity_count = evo.multi_lookup('lookup_world')
            assert(entity_list and #entity_list == 1 and entity_count == 1)
            assert(entity_list[1] == e2)
        end
    end

    evo.set(e3, evo.NAME, 'lookup_world')

    do
        assert(evo.lookup('lookup_hello') == e1)
        assert(evo.lookup('lookup_world') == e2)

        do
            local entity_list, entity_count = evo.multi_lookup('lookup_hello')
            assert(entity_list and #entity_list == 1 and entity_count == 1)
            assert(entity_list[1] == e1)
        end

        do
            local entity_list, entity_count = evo.multi_lookup('lookup_world')
            assert(entity_list and #entity_list == 2 and entity_count == 2)
            assert(entity_list[1] == e2 or entity_list[1] == e3)
        end
    end

    evo.remove(e1, evo.NAME)

    do
        assert(evo.lookup('lookup_hello') == nil)
        assert(evo.lookup('lookup_world') == e2)

        do
            local entity_list, entity_count = evo.multi_lookup('lookup_hello')
            assert(entity_list and #entity_list == 0 and entity_count == 0)
        end

        do
            local entity_list, entity_count = evo.multi_lookup('lookup_world')
            assert(entity_list and #entity_list == 2 and entity_count == 2)
            assert(entity_list[1] == e2 or entity_list[1] == e3)
        end
    end
end

do
    local e1, e2, e3 = evo.id(3)

    evo.set(e1, evo.NAME, 'lookup_e')

    do
        local entity_list, entity_count = evo.multi_lookup('lookup_e')
        assert(entity_list and #entity_list == 1 and entity_count == 1)
        assert(entity_list[1] == e1)
    end

    evo.set(e2, evo.NAME, 'lookup_e')

    do
        local entity_list, entity_count = evo.multi_lookup('lookup_e')
        assert(entity_list and #entity_list == 2 and entity_count == 2)
        assert(entity_list[1] == e1 and entity_list[2] == e2)
    end

    evo.set(e3, evo.NAME, 'lookup_e')

    do
        local entity_list, entity_count = evo.multi_lookup('lookup_e')
        assert(entity_list and #entity_list == 3 and entity_count == 3)
        assert(entity_list[1] == e1 and entity_list[2] == e2 and entity_list[3] == e3)
    end

    evo.clear(e1, e2, e3)

    do
        local entity_list, entity_count = evo.multi_lookup('lookup_e')
        assert(entity_list and #entity_list == 0 and entity_count == 0)
    end

    evo.set(e3, evo.NAME, 'lookup_e')

    do
        local entity_list, entity_count = evo.multi_lookup('lookup_e')
        assert(entity_list and #entity_list == 1 and entity_count == 1)
        assert(entity_list[1] == e3)
    end

    evo.set(e2, evo.NAME, 'lookup_e')

    do
        local entity_list, entity_count = evo.multi_lookup('lookup_e')
        assert(entity_list and #entity_list == 2 and entity_count == 2)
        assert(entity_list[1] == e3 and entity_list[2] == e2)
    end

    evo.set(e1, evo.NAME, 'lookup_e')

    do
        local entity_list, entity_count = evo.multi_lookup('lookup_e')
        assert(entity_list and #entity_list == 3 and entity_count == 3)
        assert(entity_list[1] == e3 and entity_list[2] == e2 and entity_list[3] == e1)
    end

    evo.destroy(e3, e2, e1)

    do
        local entity_list, entity_count = evo.multi_lookup('lookup_e')
        assert(entity_list and #entity_list == 0 and entity_count == 0)
    end
end

do
    local e1, e2 = evo.id(2)

    evo.set(e1, evo.NAME, 'lookup_e')
    evo.set(e2, evo.NAME, 'lookup_e')

    do
        local entity_list = {}
        local entity_count = evo.multi_lookup_to(entity_list, 1, 'lookup_e')
        assert(entity_count == 2 and entity_list[1] == e1 and entity_list[2] == e2)
    end

    do
        local entity_list = {}
        local entity_count = evo.multi_lookup_to(entity_list, 2, 'lookup_e')
        assert(entity_count == 2 and entity_list[2] == e1 and entity_list[3] == e2)
    end
end
