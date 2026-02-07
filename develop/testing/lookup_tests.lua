local evo = require 'evolved'

evo.debug_mode(true)

do
    local e1, e2, e3 = evo.id(3)

    do
        assert(evo.lookup('hello') == nil)
        assert(evo.lookup('world') == nil)

        do
            local entity_list, entity_count = evo.multi_lookup('hello')
            assert(entity_list and #entity_list == 0 and entity_count == 0)
        end

        do
            local entity_list, entity_count = evo.multi_lookup('world')
            assert(entity_list and #entity_list == 0 and entity_count == 0)
        end
    end

    evo.set(e1, evo.NAME, 'hello')

    do
        assert(evo.lookup('hello') == e1)
        assert(evo.lookup('world') == nil)

        do
            local entity_list, entity_count = evo.multi_lookup('hello')
            assert(entity_list and #entity_list == 1 and entity_count == 1)
            assert(entity_list[1] == e1)
        end

        do
            local entity_list, entity_count = evo.multi_lookup('world')
            assert(entity_list and #entity_list == 0 and entity_count == 0)
        end
    end

    evo.set(e2, evo.NAME, 'hello')
    evo.set(e3, evo.NAME, 'hello')

    do
        assert(evo.lookup('hello') == e3)
        assert(evo.lookup('world') == nil)

        do
            local entity_list, entity_count = evo.multi_lookup('hello')
            assert(entity_list and #entity_list == 3 and entity_count == 3)
            assert(entity_list[1] == e1 and entity_list[2] == e2 and entity_list[3] == e3)
        end
    end

    evo.set(e2, evo.NAME, 'world')

    do
        assert(evo.lookup('hello') == e3)
        assert(evo.lookup('world') == e2)

        do
            local entity_list, entity_count = evo.multi_lookup('hello')
            assert(entity_list and #entity_list == 2 and entity_count == 2)
            assert(entity_list[1] == e1 and entity_list[2] == e3)
        end

        do
            local entity_list, entity_count = evo.multi_lookup('world')
            assert(entity_list and #entity_list == 1 and entity_count == 1)
            assert(entity_list[1] == e2)
        end
    end

    evo.set(e3, evo.NAME, 'world')

    do
        assert(evo.lookup('hello') == e1)
        assert(evo.lookup('world') == e3)

        do
            local entity_list, entity_count = evo.multi_lookup('hello')
            assert(entity_list and #entity_list == 1 and entity_count == 1)
            assert(entity_list[1] == e1)
        end

        do
            local entity_list, entity_count = evo.multi_lookup('world')
            assert(entity_list and #entity_list == 2 and entity_count == 2)
            assert(entity_list[1] == e2 or entity_list[1] == e3)
        end
    end

    evo.remove(e1, evo.NAME)

    do
        assert(evo.lookup('hello') == nil)
        assert(evo.lookup('world') == e3)

        do
            local entity_list, entity_count = evo.multi_lookup('hello')
            assert(entity_list and #entity_list == 0 and entity_count == 0)
        end

        do
            local entity_list, entity_count = evo.multi_lookup('world')
            assert(entity_list and #entity_list == 2 and entity_count == 2)
            assert(entity_list[1] == e2 or entity_list[1] == e3)
        end
    end
end
