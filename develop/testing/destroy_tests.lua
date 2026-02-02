local evo = require 'evolved'

evo.debug_mode(true)

do
    local e = evo.id()
    assert(evo.alive(e))

    evo.destroy(e)
    assert(not evo.alive(e))

    evo.destroy(e)
    assert(not evo.alive(e))
end

do
    local e1, e2 = evo.id(2)
    assert(evo.alive_all(e1, e2))

    evo.destroy(e1, e2)
    assert(not evo.alive_any(e1, e2))

    evo.destroy(e1, e2)
    assert(not evo.alive_any(e1, e2))
end

do
    do
        local e, f1, f2, f3 = evo.id(4)

        evo.set(e, f1, 42)
        evo.set(e, f2, 21)
        evo.set(e, f3, 84)

        evo.destroy(f1, f2)
        assert(evo.alive(e) and not evo.has_any(e, f1, f2) and evo.has(e, f3))
    end
    do
        local e, f1, f2, f3 = evo.id(4)
        evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)

        evo.set(e, f1, 42)
        evo.set(e, f2, 21)
        evo.set(e, f3, 84)

        evo.destroy(f1, f2)
        assert(evo.alive(e) and not evo.has_any(e, f1, f2) and evo.has(e, f3))
    end
    do
        local e, f1, f2, f3 = evo.id(4)
        evo.set(f2, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)

        evo.set(e, f1, 42)
        evo.set(e, f2, 21)
        evo.set(e, f3, 84)

        evo.destroy(f1, f2)
        assert(evo.alive(e) and not evo.has_any(e, f1, f2) and evo.has(e, f3))
    end
    do
        local e, f1, f2, f3 = evo.id(4)
        evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)
        evo.set(f2, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)

        evo.set(e, f1, 42)
        evo.set(e, f2, 21)
        evo.set(e, f3, 84)

        evo.destroy(f1, f2)
        assert(evo.alive(e) and not evo.has_any(e, f1, f2) and evo.has(e, f3))
    end
    do
        local e, f1, f2, f3 = evo.id(4)
        evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

        evo.set(e, f1, 42)
        evo.set(e, f2, 21)
        evo.set(e, f3, 84)

        evo.destroy(f1, f2)
        assert(not evo.alive(e))
    end
    do
        local e, f1, f2, f3 = evo.id(4)
        evo.set(f2, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

        evo.set(e, f1, 42)
        evo.set(e, f2, 21)
        evo.set(e, f3, 84)

        evo.destroy(f1, f2)
        assert(not evo.alive(e))
    end
    do
        local e, f1, f2, f3 = evo.id(4)
        evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
        evo.set(f2, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

        evo.set(e, f1, 42)
        evo.set(e, f2, 21)
        evo.set(e, f3, 84)

        evo.destroy(f1, f2)
        assert(not evo.alive(e))
    end
end
