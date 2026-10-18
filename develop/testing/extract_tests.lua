local evo = require 'evolved'

evo.debug_mode(true)

---@param fragment evolved.fragment
---@param component evolved.component
---@param ... evolved.entity expected entities
local function check_search(fragment, component, ...)
    local expected_count = select('#', ...)

    do
        assert(evo.search(fragment, component) == ...)
    end

    do
        local entity_list, entity_count = evo.multi_search(fragment, component)
        assert(entity_list and #entity_list == expected_count and entity_count == expected_count)

        for i = 1, expected_count do
            assert(entity_list[i] == select(i, ...))
        end
    end
end

---@param c table
local function extract_team(c)
    return c.team
end

do
    local f = evo.builder():extract(extract_team):build()
    assert(evo.get(f, evo.EXTRACT) == extract_team)
    assert(not evo.has_any(f, evo.INDEX, evo.LINK))
end

do
    local f = evo.builder():index():extract(string.lower):build()

    local e1 = evo.spawn { [f] = 'Hello' }
    local e2 = evo.spawn { [f] = 'HELLO' }
    local e3 = evo.spawn { [f] = 'World' }

    check_search(f, 'hello', e1, e2)
    check_search(f, 'world', e3)
    check_search(f, 'Hello')

    evo.set(e3, f, 'hElLo')
    check_search(f, 'hello', e1, e2, e3)
    check_search(f, 'world')

    -- components are stored as is, only the index uses extracted values
    assert(evo.get(e3, f) == 'hElLo')
end

do
    local f = evo.builder():index():extract(extract_team):build()

    local e1 = evo.spawn { [f] = { team = 'red' } }
    local e2 = evo.spawn { [f] = { team = 'red' } }
    local e3 = evo.spawn { [f] = { team = 'blue' } }

    check_search(f, 'red', e1, e2)
    check_search(f, 'blue', e3)

    -- a new table with the same extracted value keeps the entity position
    evo.set(e1, f, { team = 'red' })
    check_search(f, 'red', e1, e2)

    evo.set(e1, f, { team = 'blue' })
    check_search(f, 'red', e2)
    check_search(f, 'blue', e3, e1)

    evo.remove(e3, f)
    check_search(f, 'blue', e1)

    evo.destroy(e1)
    check_search(f, 'blue')

    evo.clear(e2)
    check_search(f, 'red')
end

do
    local f = evo.builder():index():extract(extract_team):build()

    -- nil and NaN extracted values are not indexed
    local e1 = evo.spawn { [f] = {} }
    local e2 = evo.spawn { [f] = { team = 'red' } }
    local e3 = evo.spawn { [f] = { team = 0 / 0 } }
    check_search(f, 'red', e2)

    evo.set(e1, f, { team = 'red' })
    evo.set(e3, f, { team = 'red' })
    check_search(f, 'red', e2, e1, e3)

    evo.set(e2, f, {})
    evo.set(e3, f, { team = 0 / 0 })
    check_search(f, 'red', e1)

    evo.set(e2, f, {})
    check_search(f, 'red', e1)

    evo.destroy(e1, e2, e3)
    check_search(f, 'red')
end

do
    local f = evo.builder():index():extract(extract_team):build()

    local c1, c2 = { team = 'red' }, { team = 'red' }
    local e1 = evo.spawn { [f] = c1 }
    local e2 = evo.spawn { [f] = c2 }

    -- in-place changes bypass the index
    c1.team = 'blue'
    check_search(f, 'red', e1, e2)
    check_search(f, 'blue')

    -- setting the same table again updates the index
    evo.set(e1, f, c1)
    check_search(f, 'red', e2)
    check_search(f, 'blue', e1)

    -- reindexing updates the index too
    c2.team = 'blue'
    evo.reindex(f)
    check_search(f, 'red')
    check_search(f, 'blue', e1, e2)

    -- removing uses the indexed value, not the changed component
    c1.team = 'green'
    evo.remove(e1, f)
    check_search(f, 'blue', e2)
    check_search(f, 'green')
end

do
    local f = evo.builder():index():build()

    local c1, c2 = { team = 'red' }, { team = 'blue' }
    local e1 = evo.spawn { [f] = c1 }
    local e2 = evo.spawn { [f] = c2 }

    check_search(f, c1, e1)
    check_search(f, 'red')

    -- setting the trait rebuilds the index
    evo.set(f, evo.EXTRACT, extract_team)
    check_search(f, c1)
    check_search(f, 'red', e1)
    check_search(f, 'blue', e2)

    -- changing the trait rebuilds the index
    evo.set(f, evo.EXTRACT, function(c) return c.team == 'red' end)
    check_search(f, 'red')
    check_search(f, true, e1)
    check_search(f, false, e2)

    -- removing the trait rebuilds the index
    evo.remove(f, evo.EXTRACT)
    check_search(f, true)
    check_search(f, c1, e1)
    check_search(f, c2, e2)
end

do
    local f = evo.builder():extract(extract_team):build()

    local e1 = evo.spawn { [f] = { team = 'red' } }
    local e2 = evo.spawn { [f] = { team = 'blue' } }

    -- the trait is used as soon as the fragment is indexed
    evo.set(f, evo.INDEX)
    check_search(f, 'red', e1)
    check_search(f, 'blue', e2)

    evo.remove(f, evo.INDEX)
    evo.set(e1, f, { team = 'blue' })

    evo.set(f, evo.INDEX)
    check_search(f, 'red')
    check_search(f, 'blue', e1, e2)
end

do
    local extract_count = 0

    local f = evo.builder():index():extract(function(c)
        extract_count = extract_count + 1
        return c.team
    end):build()

    local g = evo.builder():build()

    local e = evo.spawn { [f] = { team = 'red' } }
    assert(extract_count == 1)

    evo.set(e, f, { team = 'blue' })
    assert(extract_count == 2)

    -- moving between chunks does not extract values again
    evo.set(e, g, 42)
    evo.remove(e, g)
    assert(extract_count == 2)

    -- removing uses the indexed value, so nothing is extracted
    evo.remove(e, f)
    assert(extract_count == 2)

    evo.set(e, f, { team = 'red' })
    assert(extract_count == 3)

    evo.destroy(e)
    assert(extract_count == 3)
    check_search(f, 'red')
end

do
    local f = evo.builder():index():extract(extract_team):build()

    local prefab = evo.spawn { [f] = { team = 'red' } }

    local clone = evo.clone(prefab)
    check_search(f, 'red', prefab, clone)

    local clone_list = evo.multi_clone(2, prefab, { [f] = { team = 'blue' } })
    check_search(f, 'blue', clone_list[1], clone_list[2])

    local spawn_list = evo.multi_spawn(2, { [f] = { team = 'green' } })
    check_search(f, 'green', spawn_list[1], spawn_list[2])

    local q = evo.builder():include(f):build()
    evo.batch_set(q, f, { team = 'yellow' })
    check_search(f, 'red')
    check_search(f, 'blue')
    check_search(f, 'green')
    assert(select(2, evo.multi_search(f, 'yellow')) == 6)

    evo.batch_destroy(q)
    check_search(f, 'yellow')
end

do
    local f = evo.builder()
        :index()
        :default({ team = 'none' })
        :duplicate(function(c) return { team = c.team } end)
        :extract(extract_team)
        :build()

    local e1 = evo.spawn { [f] = { team = 'red' } }
    local e2 = evo.builder():set(f):build()
    check_search(f, 'red', e1)
    check_search(f, 'none', e2)

    evo.defer()
    local e3 = evo.spawn { [f] = { team = 'red' } }
    evo.set(e2, f, { team = 'red' })
    check_search(f, 'red', e1)
    evo.commit()
    check_search(f, 'red', e1, e3, e2)
    check_search(f, 'none')
end

do
    local owner = evo.builder():link():extract(function(c) return c.owner end):build()

    local player1, player2 = evo.id(2)

    local sword = evo.spawn { [owner] = { owner = player1, slot = 1 } }
    local shield = evo.spawn { [owner] = { owner = player1, slot = 2 } }
    local bow = evo.spawn { [owner] = { owner = player2, slot = 1 } }

    check_search(owner, player1, sword, shield)
    check_search(owner, player2, bow)

    evo.destroy(player1)
    assert(evo.alive_all(sword, shield, bow))
    assert(not evo.has(sword, owner) and not evo.has(shield, owner))
    assert(evo.get(bow, owner).owner == player2)

    check_search(owner, player1)
    check_search(owner, player2, bow)
end

do
    local owner = evo.builder():link():extract(function(c) return c.owner end):build()

    local player = evo.id()

    -- nil extracted values do not link to anything
    local item = evo.spawn { [owner] = { slot = 1 } }
    check_search(owner, player)

    evo.set(item, owner, { owner = player, slot = 1 })
    check_search(owner, player, item)

    evo.set(item, owner, { slot = 1 })
    check_search(owner, player)

    evo.destroy(player)
    assert(evo.has(item, owner))
end

do
    local parent = evo.builder()
        :link()
        :link_policy(evo.LINK_POLICY_DESTROY_ENTITY)
        :extract(function(c) return c.parent end)
        :build()

    local root = evo.id()

    local child = evo.spawn { [parent] = { parent = root } }
    local grandchild = evo.spawn { [parent] = { parent = child } }
    local orphan = evo.spawn { [parent] = {} }

    evo.destroy(root)
    assert(not evo.alive_any(child, grandchild))
    assert(evo.alive(orphan) and evo.has(orphan, parent))
end

do
    local attached_to = evo.builder():link():extract(function(c) return c.pillars end):build()

    local p1, p2, p3 = evo.id(3)

    local c = { pillars = { p1, p2 } }
    local rope = evo.spawn { [attached_to] = c }

    check_search(attached_to, p1, rope)
    check_search(attached_to, p2, rope)
    check_search(attached_to, p3)

    -- the extracted list is changed in place, so set the component again
    c.pillars[2] = p3
    evo.set(rope, attached_to, c)
    check_search(attached_to, p1, rope)
    check_search(attached_to, p2)
    check_search(attached_to, p3, rope)

    evo.destroy(p2)
    assert(evo.has(rope, attached_to))

    evo.destroy(p1)
    assert(evo.alive(rope) and not evo.has(rope, attached_to))
    check_search(attached_to, p3)
end

do
    local f = evo.builder():link():build()

    local t1, t2, t3 = evo.id(3)

    local e = evo.spawn { [f] = { t1, t2, t3 } }
    check_search(f, t1, e)
    check_search(f, t2, e)

    -- setting the trait relinks existing components
    evo.set(f, evo.EXTRACT, function(c) return c[1] end)
    check_search(f, t1, e)
    check_search(f, t2)

    evo.destroy(t2)
    assert(evo.has(e, f))

    evo.set(e, f, { t1, t3 })

    -- removing the trait relinks existing components
    evo.remove(f, evo.EXTRACT)
    check_search(f, t1, e)
    check_search(f, t3, e)

    evo.destroy(t3)
    assert(evo.alive(e) and not evo.has(e, f))
end
