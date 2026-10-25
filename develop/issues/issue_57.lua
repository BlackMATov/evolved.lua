local evo = require 'evolved'

evo.debug_mode(true)

do
    local f1, f2 = evo.id(2)

    evo.set(f1, evo.DEFAULT, 1)
    evo.set(f2, evo.REQUIRES, { f1 })

    -- the chunk with both fragments caches the default value of the first fragment
    local e1 = evo.spawn({ [f2] = true })
    assert(evo.get(e1, f1) == 1)

    evo.set(f1, evo.DEFAULT, 2)

    -- the cached default value should be updated after reassignment
    local e2 = evo.spawn({ [f2] = true })
    assert(evo.get(e2, f1) == 2)
end

do
    local f1, f2 = evo.id(2)

    evo.set(f1, evo.DEFAULT, 1)
    evo.set(f1, evo.DUPLICATE, function(v) return v + 10 end)
    evo.set(f2, evo.REQUIRES, { f1 })

    -- the chunk with both fragments caches the duplicate function of the first fragment
    local e1 = evo.spawn({ [f2] = true })
    assert(evo.get(e1, f1) == 11)

    evo.set(f1, evo.DUPLICATE, function(v) return v + 20 end)

    -- the cached duplicate function should be updated after reassignment
    local e2 = evo.spawn({ [f2] = true })
    assert(evo.get(e2, f1) == 21)
end
