local evo = require 'evolved'

evo.debug_mode(true)

do
    assert(evo.defer())
    assert(evo.cancel())
end

do
    assert(evo.defer())
    assert(not evo.defer())
    assert(not evo.cancel())
    assert(evo.commit())
end

do
    assert(evo.defer())
    assert(not evo.defer())
    assert(not evo.cancel())
    assert(evo.cancel())
end

do
    assert(evo.defer())
    assert(not evo.defer())
    assert(not evo.cancel())
    assert(not evo.defer())
    assert(not evo.cancel())
    assert(evo.commit())
end

do
    local e, f = evo.id(2)

    assert(evo.defer())
    do
        evo.set(e, f)
        assert(not evo.has(e, f))
    end
    assert(evo.cancel())

    assert(not evo.has(e, f))
end

do
    local e, f1, f2 = evo.id(3)

    assert(evo.defer())
    do
        evo.set(e, f1)
        assert(not evo.has(e, f1))

        assert(not evo.defer())
        do
            evo.set(e, f2)
            assert(not evo.has(e, f2))
        end
        assert(not evo.cancel())
    end
    assert(evo.commit())

    assert(evo.has(e, f1))
    assert(not evo.has(e, f2))
end

do
    local e, f1, f2 = evo.id(3)

    assert(evo.defer())
    do
        evo.set(e, f1)
        assert(not evo.has(e, f1))

        assert(not evo.defer())
        do
            evo.set(e, f2)
            assert(not evo.has(e, f2))
        end
        assert(not evo.cancel())
    end
    assert(evo.cancel())

    assert(not evo.has(e, f1))
    assert(not evo.has(e, f2))
end

do
    local e, f1, f2 = evo.id(3)

    assert(evo.defer())
    do
        evo.set(e, f1)
        assert(not evo.has(e, f1))

        assert(not evo.defer())
        do
            evo.set(e, f2)
            assert(not evo.has(e, f2))
        end
        assert(not evo.commit())
    end
    assert(evo.cancel())

    assert(not evo.has(e, f1))
    assert(not evo.has(e, f2))
end
