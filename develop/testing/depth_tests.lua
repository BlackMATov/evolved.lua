local evo = require 'evolved'

do
    assert(evo.depth() == 0)

    assert(evo.defer())
    assert(evo.depth() == 1)

    assert(not evo.defer())
    assert(evo.depth() == 2)

    assert(not evo.cancel())
    assert(evo.depth() == 1)

    assert(evo.cancel())
    assert(evo.depth() == 0)
end

do
    assert(evo.depth() == 0)

    assert(evo.defer())
    assert(evo.depth() == 1)

    assert(not evo.defer())
    assert(evo.depth() == 2)

    assert(not evo.commit())
    assert(evo.depth() == 1)

    assert(evo.commit())
    assert(evo.depth() == 0)
end

do
    assert(evo.depth() == 0)

    assert(evo.defer())
    assert(evo.depth() == 1)

    assert(not evo.defer())
    assert(evo.depth() == 2)

    assert(not evo.cancel())
    assert(evo.depth() == 1)

    assert(evo.commit())
    assert(evo.depth() == 0)
end

do
    assert(evo.depth() == 0)

    assert(evo.defer())
    assert(evo.depth() == 1)

    assert(not evo.defer())
    assert(evo.depth() == 2)

    assert(not evo.commit())
    assert(evo.depth() == 1)

    assert(evo.cancel())
    assert(evo.depth() == 0)
end
