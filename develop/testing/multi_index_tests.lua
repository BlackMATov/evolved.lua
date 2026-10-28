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

do
    assert(evo.get(evo.INCLUDES, evo.INDEX_POLICY) == evo.INDEX_POLICY_LIST)
    assert(evo.get(evo.EXCLUDES, evo.INDEX_POLICY) == evo.INDEX_POLICY_LIST)
    assert(evo.get(evo.VARIANTS, evo.INDEX_POLICY) == evo.INDEX_POLICY_LIST)
    assert(evo.get(evo.REQUIRES, evo.INDEX_POLICY) == evo.INDEX_POLICY_LIST)

    assert(not evo.has(evo.NAME, evo.INDEX_POLICY))
    assert(not evo.has(evo.GROUP, evo.INDEX_POLICY))
    assert(not evo.has(evo.QUERY, evo.INDEX_POLICY))
end

do
    local f = evo.builder():index():index_policy(evo.INDEX_POLICY_LIST):build()
    assert(evo.has(f, evo.INDEX) and evo.get(f, evo.INDEX_POLICY) == evo.INDEX_POLICY_LIST)

    local e1 = evo.spawn { [f] = { 'red', 'big' } }
    local e2 = evo.spawn { [f] = { 'blue', 'big' } }
    local e3 = evo.spawn { [f] = { 'red' } }
    local e4 = evo.spawn { [f] = {} }

    check_search(f, 'red', e1, e3)
    check_search(f, 'blue', e2)
    check_search(f, 'big', e1, e2)
    check_search(f, 'small')

    evo.set(e3, f, { 'small', 'red' })
    check_search(f, 'red', e1, e3)
    check_search(f, 'small', e3)

    evo.set(e1, f, { 'blue' })
    check_search(f, 'red', e3)
    check_search(f, 'blue', e2, e1)
    check_search(f, 'big', e2)

    evo.set(e4, f, { 'big', 'big', 'big' })
    check_search(f, 'big', e2, e4)

    evo.remove(e2, f)
    check_search(f, 'blue', e1)
    check_search(f, 'big', e4)

    evo.destroy(e1, e3, e4)
    check_search(f, 'red')
    check_search(f, 'blue')
    check_search(f, 'big')
    check_search(f, 'small')
end

do
    local f = evo.builder():index():index_policy(evo.INDEX_POLICY_KEYS):build()

    local e1 = evo.spawn { [f] = { red = true, big = true } }
    local e2 = evo.spawn { [f] = { blue = true, big = true } }
    local e3 = evo.spawn { [f] = { red = false } }

    -- every key of a set is indexed, whatever its value is
    check_search(f, 'red', e1, e3)
    check_search(f, 'blue', e2)
    check_search(f, 'big', e1, e2)
    check_search(f, true)
    check_search(f, false)

    evo.set(e1, f, { big = true, small = true })
    check_search(f, 'red', e3)
    check_search(f, 'big', e1, e2)
    check_search(f, 'small', e1)

    evo.remove(e1, f)
    check_search(f, 'big', e2)
    check_search(f, 'small')
end

do
    local f = evo.builder():index():index_policy(evo.INDEX_POLICY_VALUES):build()

    local e1 = evo.spawn { [f] = { left = 'sword', right = 'shield' } }
    local e2 = evo.spawn { [f] = { left = 'shield', right = 'shield' } }
    local e3 = evo.spawn { [f] = { 'sword', 'sword' } }

    -- only values of a map are indexed, keys are not
    check_search(f, 'sword', e1, e3)
    check_search(f, 'shield', e1, e2)
    check_search(f, 'left')
    check_search(f, 1)

    evo.set(e2, f, { left = 'sword' })
    check_search(f, 'sword', e1, e3, e2)
    check_search(f, 'shield', e1)

    evo.destroy(e1)
    check_search(f, 'sword', e3, e2)
    check_search(f, 'shield')
end

do
    local f = evo.builder():index():index_policy(evo.INDEX_POLICY_LIST):build()

    -- values with equal primary parts must not be mixed up
    local e1 = evo.spawn { [f] = { 1, 1048577, 2 ^ 40 + 1 } }
    local e2 = evo.spawn { [f] = { 1048577 } }
    local e3 = evo.spawn { [f] = { 1, 0.5, -1 } }

    check_search(f, 1, e1, e3)
    check_search(f, 1048577, e1, e2)
    check_search(f, 2 ^ 40 + 1, e1)
    check_search(f, 0.5, e3)
    check_search(f, -1, e3)

    evo.remove(e1, f)
    check_search(f, 1, e3)
    check_search(f, 1048577, e2)
    check_search(f, 2 ^ 40 + 1)

    evo.destroy(e2, e3)
    check_search(f, 1)
    check_search(f, 1048577)
end

do
    local f = evo.builder():index():index_policy(evo.INDEX_POLICY_LIST):build()

    local nan = 0 / 0

    local t1, t2 = {}, {}

    local e1 = evo.spawn { [f] = { nan, true, false, t1 } }
    local e2 = evo.spawn { [f] = { false, t2, nan } }

    -- NaN values are not indexed, tables are indexed by reference
    check_search(f, nan)
    check_search(f, true, e1)
    check_search(f, false, e1, e2)
    check_search(f, t1, e1)
    check_search(f, t2, e2)

    evo.set(e1, f, { nan })
    check_search(f, true)
    check_search(f, false, e2)
    check_search(f, t1)

    evo.destroy(e1, e2)
    check_search(f, false)
    check_search(f, t2)
end

do
    local f = evo.builder():index():index_policy(evo.INDEX_POLICY_LIST):build()

    local e1 = evo.spawn { [f] = { 1, 2, 3, 4, 5, 6, 7, 8 } }
    local e2 = evo.spawn { [f] = { 8, 7, 6, 5, 4, 3, 2, 1 } }

    for i = 1, 8 do
        check_search(f, i, e1, e2)
    end

    evo.set(e1, f, { 9, 10, 11, 12, 13, 14, 1, 8 })

    for i = 2, 7 do
        check_search(f, i, e2)
    end

    for i = 9, 14 do
        check_search(f, i, e1)
    end

    check_search(f, 1, e1, e2)
    check_search(f, 8, e1, e2)

    evo.set(e2, f, { 15 })

    for i = 1, 8 do
        if i == 1 or i == 8 then
            check_search(f, i, e1)
        else
            check_search(f, i)
        end
    end

    check_search(f, 15, e2)
end

do
    local f = evo.builder():index():index_policy(evo.INDEX_POLICY_LIST):build()

    local nan = 0 / 0

    local e1 = evo.spawn { [f] = { 1, 2, 3, 4, 5, 6, 7, 8 } }
    local e2 = evo.spawn { [f] = { 1, 2, 3, 4, 5, 6, 7, 8 } }

    -- the long middle is changed, but its retained values keep their order
    evo.set(e1, f, { 1, 7, 6, nan, 5, 4, 3, 9, 1, 8 })

    for i = 1, 8 do
        if i == 2 then
            check_search(f, i, e2)
        else
            check_search(f, i, e1, e2)
        end
    end

    check_search(f, 9, e1)
    check_search(f, nan)

    -- values duplicated outside of the long middle are not unlinked
    evo.set(e1, f, { 1, 10, 11, 12, 13, 14, 1 })

    check_search(f, 1, e1, e2)

    for i = 3, 9 do
        if i == 9 then
            check_search(f, i)
        else
            check_search(f, i, e2)
        end
    end

    for i = 10, 14 do
        check_search(f, i, e1)
    end

    evo.set(e1, f, { 14, 13, 12, 11, 10, 9, 8, 7 })

    check_search(f, 1, e2)
    check_search(f, 7, e2, e1)
    check_search(f, 8, e2, e1)
    check_search(f, 9, e1)

    for i = 10, 14 do
        check_search(f, i, e1)
    end
end

do
    local f = evo.builder():index():index_policy(evo.INDEX_POLICY_KEYS):build()

    local s1 = {}
    local s2 = {}

    for i = 1, 16 do
        s1['k' .. i] = true
        s2['k' .. i] = true
    end

    local e1 = evo.spawn { [f] = s1 }
    local e2 = evo.spawn { [f] = s2 }

    -- sets with other key orders keep the search order of their retained keys
    local s3 = {}

    for i = 32, 1, -1 do
        if i % 3 ~= 0 then
            s3['k' .. i] = true
        end
    end

    evo.set(e1, f, s3)

    for i = 1, 32 do
        if i % 3 == 0 and i <= 16 then
            check_search(f, 'k' .. i, e2)
        elseif i % 3 == 0 then
            check_search(f, 'k' .. i)
        elseif i <= 16 then
            check_search(f, 'k' .. i, e1, e2)
        else
            check_search(f, 'k' .. i, e1)
        end
    end
end

do
    local f = evo.builder()
        :link()
        :index_policy(evo.INDEX_POLICY_LIST)
        :link_policy(evo.LINK_POLICY_UNLINK_TARGET)
        :build()

    local ts = { evo.id(8) }

    local e1 = evo.spawn { [f] = { ts[1], ts[2], ts[3], ts[4], ts[5], ts[6], ts[7], ts[8] } }
    local e2 = evo.spawn { [f] = { ts[2], ts[4], ts[6] } }

    -- unlinking many targets keeps the search order of the other ones
    evo.destroy(ts[1], ts[3], ts[5], ts[7], ts[8])

    local c1 = evo.get(e1, f)
    assert(#c1 == 3 and c1[1] == ts[2] and c1[2] == ts[4] and c1[3] == ts[6])

    check_search(f, ts[2], e1, e2)
    check_search(f, ts[4], e1, e2)
    check_search(f, ts[6], e1, e2)
end

do
    local f = evo.builder():index():index_policy(evo.INDEX_POLICY_LIST):build()

    local weak_values = setmetatable({}, { __mode = 'v' })

    do
        local t = {}
        weak_values[1] = t

        local e = evo.spawn { [f] = { 1, 2, 3, 4, 5, 6 } }

        -- long middles mark their new values, these marks must not hold them
        evo.set(e, f, { 7, t, 8, 9, 10, 11 })
        check_search(f, t, e)

        evo.set(e, f, { 12, 13, 14, 15, 16, 17 })
        check_search(f, t)

        evo.destroy(e)
    end

    collectgarbage('collect')
    assert(weak_values[1] == nil)
end

do
    local f = evo.builder():index():index_policy(evo.INDEX_POLICY_LIST):build()

    local e = evo.spawn { [f] = {} }

    -- value keys are reused after values are not indexed anymore
    for i = 1, 100 do
        evo.set(e, f, { 'v' .. i, 'w' .. i, i })
        check_search(f, 'v' .. i, e)
        check_search(f, 'w' .. i, e)
        check_search(f, i, e)
        check_search(f, 'v' .. (i - 1))
        check_search(f, i - 1)
    end

    local e2 = evo.spawn { [f] = { 'v100', 100 } }
    check_search(f, 'v100', e, e2)
    check_search(f, 100, e, e2)

    evo.destroy(e)
    check_search(f, 'v100', e2)
    check_search(f, 'w100')
end

do
    local f = evo.builder():index():index_policy(evo.INDEX_POLICY_KEYS):build()
    local g = evo.builder():index():index_policy(evo.INDEX_POLICY_VALUES):build()

    local s = { red = true }
    local m = { left = 'sword' }

    local e = evo.spawn { [f] = s, [g] = m }

    s.blue, s.red = true, nil
    m.right, m.left = 'shield', nil

    -- tables changed in place are not reindexed until reindex is called
    check_search(f, 'red', e)
    check_search(f, 'blue')
    check_search(g, 'sword', e)
    check_search(g, 'shield')

    evo.reindex(f, g)

    check_search(f, 'red')
    check_search(f, 'blue', e)
    check_search(g, 'sword')
    check_search(g, 'shield', e)
end

do
    local f = evo.builder():index():build()

    local l = { 'red', 'big' }
    local s = { red = true }

    local e1 = evo.spawn { [f] = l }
    local e2 = evo.spawn { [f] = s }

    check_search(f, l, e1)
    check_search(f, 'red')

    evo.set(f, evo.INDEX_POLICY, evo.INDEX_POLICY_VALUES)
    check_search(f, l)
    check_search(f, 'red', e1)
    check_search(f, true, e2)

    evo.set(f, evo.INDEX_POLICY, evo.INDEX_POLICY_KEYS)
    check_search(f, 'red', e2)
    check_search(f, 1, e1)
    check_search(f, true)

    evo.set(f, evo.INDEX_POLICY, evo.INDEX_POLICY_LIST)
    check_search(f, 'red', e1)
    check_search(f, 'big', e1)

    evo.remove(f, evo.INDEX_POLICY)
    check_search(f, 'red')
    check_search(f, l, e1)
    check_search(f, s, e2)
end

do
    local f = evo.builder():index():index_policy(evo.INDEX_POLICY_LIST):build()

    local p = evo.builder():prefab():set(f, { 'red' }):build()

    local e1 = evo.clone(p)
    local l, c = evo.multi_clone(2, p)
    assert(c == 2)

    check_search(f, 'red', p, e1, l[1], l[2])

    local sl, sc = evo.multi_spawn(2, { [f] = { 'blue', 'red' } })
    assert(sc == 2)

    check_search(f, 'red', p, e1, l[1], l[2], sl[1], sl[2])
    check_search(f, 'blue', sl[1], sl[2])

    local q = evo.builder():include(f):build()

    evo.batch_set(q, f, { 'green' })
    check_search(f, 'red', p)
    check_search(f, 'blue')

    do
        local gl, gc = evo.multi_search(f, 'green')
        assert(gc == 5)

        local gs = {}
        for i = 1, gc do gs[gl[i]] = true end
        assert(gs[e1] and gs[l[1]] and gs[l[2]] and gs[sl[1]] and gs[sl[2]])
    end

    evo.batch_destroy(q)
    check_search(f, 'green')
end

do
    local f = evo.builder()
        :index()
        :index_policy(evo.INDEX_POLICY_KEYS)
        :link()
        :link_policy(evo.LINK_POLICY_UNLINK_TARGET)
        :build()

    local t1, t2, t3 = evo.id(3)

    local s = { [t1] = 'a', [t2] = 'b', [t3] = 'c' }
    local e = evo.spawn { [f] = s }

    check_search(f, t1, e)
    check_search(f, t2, e)

    evo.destroy(t2)

    do
        local ns = evo.get(e, f)
        assert(ns ~= s and ns[t1] == 'a' and ns[t2] == nil and ns[t3] == 'c')
        assert(s[t1] == 'a' and s[t2] == 'b' and s[t3] == 'c')
    end

    check_search(f, t1, e)
    check_search(f, t2)

    evo.destroy(t1, t3)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder()
        :link()
        :index_policy(evo.INDEX_POLICY_VALUES)
        :link_policy(evo.LINK_POLICY_UNLINK_TARGET)
        :build()

    local sword, shield = evo.id(2)

    local e1 = evo.spawn { [f] = { left = sword, right = shield } }
    local e2 = evo.spawn { [f] = { left = shield, right = shield } }

    check_search(f, sword, e1)
    check_search(f, shield, e1, e2)

    evo.destroy(shield)

    do
        local m1 = evo.get(e1, f)
        assert(m1.left == sword and m1.right == nil)
    end

    assert(evo.alive(e2) and not evo.has(e2, f))

    check_search(f, sword, e1)
    check_search(f, shield)
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_UNLINK_TARGET):build()

    local t = evo.id()
    local e = evo.spawn { [f] = t }

    -- single links are removed together with the fragment
    evo.destroy(t)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder():link():index_policy(evo.INDEX_POLICY_LIST):build()

    local t1, t2 = evo.id(2)
    local e = evo.spawn { [f] = { t1, t2 } }

    check_search(f, t1, e)
    check_search(f, t2, e)

    evo.set(f, evo.INDEX)
    evo.remove(f, evo.LINK)
    check_search(f, t1, e)

    -- not linked anymore, so nothing is resolved
    evo.destroy(t1)
    check_search(f, t1, e)
    assert(evo.get(e, f)[1] == t1)
end

do
    local f = evo.builder():index():index_policy(evo.INDEX_POLICY_KEYS):build()

    local weak_values = setmetatable({}, { __mode = 'v' })

    do
        local t1, t2 = {}, {}
        weak_values[1], weak_values[2] = t1, t2

        local e = evo.spawn { [f] = { [t1] = true } }
        evo.set(e, f, { [t1] = true, [t2] = true })
        check_search(f, t2, e)

        evo.destroy(e)
        check_search(f, t1)
        check_search(f, t2)
    end

    -- collected components of the last assignment are kept until garbage collection
    evo.collect_garbage()
    collectgarbage('collect')
    assert(weak_values[1] == nil and weak_values[2] == nil)
end

do
    local fk = evo.builder():index():index_policy(evo.INDEX_POLICY_KEYS):build()
    local fl = evo.builder():link():index_policy(evo.INDEX_POLICY_LIST):link_policy(evo.LINK_POLICY_UNLINK_TARGET):build()

    local ts = { evo.id(8) }

    local es = {}

    for i = 1, 1000 do
        es[i] = evo.spawn {
            [fk] = { ['k' .. i] = true, shared = true },
            [fl] = { ts[i % 8 + 1], ts[(i + 1) % 8 + 1] },
        }
    end

    for i = 3, 1000 do
        evo.destroy(es[i])
    end

    -- indices are shrunk here, and they must keep working after that
    evo.collect_garbage()

    check_search(fk, 'shared', es[1], es[2])
    check_search(fk, 'k1', es[1])
    check_search(fk, 'k3')
    check_search(fl, ts[3], es[1], es[2])

    local e3 = evo.spawn { [fk] = { k1 = true, new = true }, [fl] = { ts[3], ts[5] } }
    evo.set(es[1], fk, { shared = true, new = true })

    check_search(fk, 'k1', e3)
    check_search(fk, 'new', e3, es[1])
    check_search(fk, 'shared', es[1], es[2])
    check_search(fl, ts[3], es[1], es[2], e3)

    evo.destroy(ts[3])
    assert(evo.get(es[1], fl)[1] == ts[2] and #evo.get(es[1], fl) == 1)
    assert(evo.get(e3, fl)[1] == ts[5] and #evo.get(e3, fl) == 1)

    evo.collect_garbage()
    evo.destroy(es[1], es[2], e3)

    check_search(fk, 'shared')
    check_search(fk, 'new')
    check_search(fl, ts[2])
    check_search(fl, ts[5])

    evo.collect_garbage()

    local e4 = evo.spawn { [fk] = { shared = true } }
    check_search(fk, 'shared', e4)
end

do
    local f = evo.builder():index():index_policy(evo.INDEX_POLICY_LIST):build()

    local e = evo.spawn { [f] = { false } }

    -- false is the only interned value here, so interned values must not look empty
    evo.collect_garbage()
    check_search(f, false, e)

    evo.set(e, f, { true })
    check_search(f, false)
    check_search(f, true, e)

    evo.destroy(e)
    check_search(f, true)
end
