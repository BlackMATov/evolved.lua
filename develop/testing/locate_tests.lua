local evo = require 'evolved'

evo.debug_mode(true)

do
    local e1, e2, f1, f2 = evo.id(4)

    do
        local chunk, place = evo.locate(e1)
        assert(chunk == nil and place == 0)
    end

    evo.set(e1, f1, 42)

    do
        local chunk, place = evo.locate(e1)
        assert(chunk and chunk == evo.chunk(f1) and place == 1)
        assert(chunk:components(f1)[place] == 42)

        chunk, place = evo.locate(e2)
        assert(chunk == nil and place == 0)
    end

    evo.set(e1, f2, 'hello')

    do
        local chunk, place = evo.locate(e1)
        assert(chunk and chunk == evo.chunk(f1, f2) and place == 1)
        assert(chunk:components(f1)[place] == 42)
        assert(chunk:components(f2)[place] == 'hello')

        chunk, place = evo.locate(e2)
        assert(chunk == nil and place == 0)
    end

    evo.set(e2, f1, 84)
    evo.set(e2, f2, 'world')

    do
        local chunk, place = evo.locate(e1)
        assert(chunk and chunk == evo.chunk(f1, f2) and place == 1)
        assert(chunk:components(f1)[place] == 42)
        assert(chunk:components(f2)[place] == 'hello')

        chunk, place = evo.locate(e2)
        assert(chunk and chunk == evo.chunk(f1, f2) and place == 2)
        assert(chunk:components(f1)[place] == 84)
        assert(chunk:components(f2)[place] == 'world')
    end
end
