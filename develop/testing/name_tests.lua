local evo = require 'evolved'

do
    local id = evo.id()

    local index, version, options = evo.unpack(id)
    assert(evo.name(id) == string.format('$%d#%d:%d:%d', id, index, version, options))

    evo.set(id, evo.NAME, 'hello')
    assert(evo.name(id) == 'hello')

    evo.set(id, evo.NAME, 'world')
    assert(evo.name(id) == 'world')

    evo.destroy(id)
    assert(evo.name(id) == string.format('$%d#%d:%d:%d', id, index, version, options))
end

do
    local id1, id2, id3, id4, id5 = evo.id(5)

    evo.set(id1, evo.NAME, 'id1')
    evo.set(id2, evo.NAME, 'id2')
    evo.set(id3, evo.NAME, 'id3')
    evo.set(id4, evo.NAME, 'id4')
    evo.set(id5, evo.NAME, 'id5')

    do
        local id1_n, id3_n, id5_n = evo.name(id1, id3, id5)
        assert(id1_n == 'id1')
        assert(id3_n == 'id3')
        assert(id5_n == 'id5')
    end

    do
        local id1_n, id2_n, id3_n, id4_n, id5_n = evo.name(id1, id2, id3, id4, id5)
        assert(id1_n == 'id1')
        assert(id2_n == 'id2')
        assert(id3_n == 'id3')
        assert(id4_n == 'id4')
        assert(id5_n == 'id5')
    end
end
