local evo = require 'evolved'

evo.debug_mode(true)

do
    local insert_count, assign_count = 0, 0

    local g, f = evo.id(2)

    if g > f then
        -- the bug shows up when the fragment is greater than the group
        g, f = f, g
    end

    evo.set(f, evo.ON_INSERT, function() insert_count = insert_count + 1 end)
    evo.set(f, evo.ON_ASSIGN, function() assign_count = assign_count + 1 end)

    local q = evo.builder():include(g):build()

    evo.spawn({ [g] = true })
    evo.spawn({ [g] = true, [f] = 1 })

    insert_count, assign_count = 0, 0

    -- the first entity receives the fragment, the second one already has it,
    -- so each hook should be invoked only once
    evo.batch_set(q, f, 2)

    assert(insert_count == 1)
    assert(assign_count == 1)
end
