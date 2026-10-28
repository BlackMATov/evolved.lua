local evo = require 'evolved'

evo.debug_mode(true)

do
    local remove_count = 0

    local f = evo.builder():destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY):build()
    local g = evo.builder():set(f):on_remove(function() remove_count = remove_count + 1 end):build()

    local e = evo.spawn({ [g] = true })

    -- destroying the first fragment also destroys the second one,
    -- so the second fragment should be removed from the entity with its hook
    evo.destroy(f)

    assert(evo.alive(e) and not evo.has(e, g) and remove_count == 1)
end
