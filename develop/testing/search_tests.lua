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

    do
        local entity_list = { 42, 21 }
        local entity_count = evo.multi_search_to(entity_list, 3, fragment, component)
        assert(#entity_list == expected_count + 2 and entity_count == expected_count)
        assert(entity_list[1] == 42 and entity_list[2] == 21)

        for i = 1, expected_count do
            assert(entity_list[i + 2] == select(i, ...))
        end
    end
end

---@param fragment evolved.fragment
---@param component evolved.component
---@param ... evolved.entity expected entities in any order
local function check_search_unordered(fragment, component, ...)
    local expected_set = {}
    local expected_count = select('#', ...)

    for i = 1, expected_count do
        expected_set[select(i, ...)] = true
    end

    local entity_list, entity_count = evo.multi_search(fragment, component)
    assert(entity_list and #entity_list == expected_count and entity_count == expected_count)

    for i = 1, entity_count do
        assert(expected_set[entity_list[i]])
        expected_set[entity_list[i]] = nil
    end

    assert(evo.search(fragment, component) == entity_list[1])
end

do
    local f = evo.id()

    local e1 = evo.spawn { [f] = 'hello' }
    local e2 = evo.spawn { [f] = 'hello' }

    -- fragments without the INDEX trait are not searchable
    check_search(f, 'hello')

    assert(evo.get(e1, f) == 'hello')
    assert(evo.get(e2, f) == 'hello')
end

do
    local f = evo.builder():index():build()
    assert(evo.has(f, evo.INDEX))

    check_search(f, 'hello')
    check_search(f, 'world')

    local e1, e2, e3 = evo.id(3)

    evo.set(e1, f, 'hello')
    check_search(f, 'hello', e1)
    check_search(f, 'world')

    evo.set(e2, f, 'hello')
    evo.set(e3, f, 'hello')
    check_search(f, 'hello', e1, e2, e3)

    evo.set(e2, f, 'world')
    check_search(f, 'hello', e1, e3)
    check_search(f, 'world', e2)

    -- assigning the same value keeps the entity position
    evo.set(e1, f, 'hello')
    check_search(f, 'hello', e1, e3)

    evo.set(e1, f, 'world')
    check_search(f, 'hello', e3)
    check_search(f, 'world', e2, e1)

    evo.remove(e2, f)
    check_search(f, 'world', e1)

    evo.clear(e1)
    check_search(f, 'world')

    evo.destroy(e3)
    check_search(f, 'hello')
end

do
    local f1 = evo.builder():index():build()
    local f2 = evo.builder():index():build()

    local e1 = evo.spawn { [f1] = 1, [f2] = 'a' }
    local e2 = evo.spawn { [f1] = 1, [f2] = 'b' }
    local e3 = evo.spawn { [f1] = 2, [f2] = 'a' }

    check_search(f1, 1, e1, e2)
    check_search(f1, 2, e3)
    check_search(f2, 'a', e1, e3)
    check_search(f2, 'b', e2)

    -- components of different fragments are indexed separately
    check_search(f1, 'a')
    check_search(f2, 1)

    evo.remove(e1, f2)
    check_search(f1, 1, e1, e2)
    check_search(f2, 'a', e3)
end

do
    local f = evo.builder():index():build()

    do
        local entity_list, entity_count = evo.multi_spawn(3, { [f] = 'multi' })
        check_search(f, 'multi', entity_list[1], entity_list[2], entity_list[3])
        assert(entity_count == 3)
        evo.destroy(entity_list[1], entity_list[2], entity_list[3])
        check_search(f, 'multi')
    end

    do
        local prefab = evo.builder():prefab():set(f, 'prefab'):build()
        check_search(f, 'prefab', prefab)

        local clone = evo.clone(prefab)
        check_search(f, 'prefab', prefab, clone)

        local clone_list = evo.multi_clone(2, prefab)
        check_search(f, 'prefab', prefab, clone, clone_list[1], clone_list[2])

        local other_clone = evo.clone(prefab, { [f] = 'other' })
        check_search(f, 'prefab', prefab, clone, clone_list[1], clone_list[2])
        check_search(f, 'other', other_clone)

        evo.destroy(prefab, clone, clone_list[1], clone_list[2], other_clone)
        check_search(f, 'prefab')
        check_search(f, 'other')
    end
end

do
    local f = evo.builder():index():default('def'):build()
    local r = evo.builder():tag():require(f):build()

    local e1 = evo.id()
    evo.set(e1, r)
    check_search(f, 'def', e1)

    local q = evo.builder():include(r):build()

    local e2 = evo.spawn { [r] = true }
    check_search(f, 'def', e1, e2)

    local e3 = evo.id()
    evo.set(e3, f, 'other')

    local t = evo.id()
    evo.set(e3, t)

    local qt = evo.builder():include(t):build()
    evo.batch_set(qt, r)
    check_search(f, 'other', e3)
    check_search(f, 'def', e1, e2)

    evo.batch_set(q, f, 'batch')
    check_search(f, 'def')
    check_search(f, 'other')
    check_search_unordered(f, 'batch', e1, e2, e3)

    evo.batch_remove(q, f)
    check_search(f, 'batch')

    evo.batch_set(q, f, 'again')
    check_search_unordered(f, 'again', e1, e2, e3)

    evo.batch_clear(qt)
    check_search_unordered(f, 'again', e1, e2)

    evo.batch_destroy(q)
    check_search(f, 'again')
end

do
    local f = evo.id()

    local e1 = evo.spawn { [f] = 'existing' }
    local e2 = evo.spawn { [f] = 'existing' }

    check_search(f, 'existing')

    -- the index is built from existing entities when the trait is added
    evo.set(f, evo.INDEX)
    do
        local entity_list, entity_count = evo.multi_search(f, 'existing')
        assert(entity_count == 2)
        assert(entity_list[1] == e1 or entity_list[1] == e2)
        assert(entity_list[2] == e1 or entity_list[2] == e2)
        assert(entity_list[1] ~= entity_list[2])
    end

    -- the index is dropped when the trait is removed
    evo.remove(f, evo.INDEX)
    check_search(f, 'existing')

    local e3 = evo.spawn { [f] = 'existing' }
    check_search(f, 'existing')

    evo.set(f, evo.INDEX)
    do
        local _, entity_count = evo.multi_search(f, 'existing')
        assert(entity_count == 3)
    end

    evo.destroy(e1, e2, e3)
    check_search(f, 'existing')
end

do
    local f = evo.id()

    evo.defer()
    do
        evo.set(f, evo.INDEX)
        check_search(f, 'deferred')
    end
    evo.commit()

    local e1, e2

    evo.defer()
    do
        e1 = evo.spawn { [f] = 'deferred' }
        e2 = evo.spawn { [f] = 'deferred' }
        check_search(f, 'deferred')
    end
    evo.commit()

    check_search(f, 'deferred', e1, e2)

    evo.defer()
    do
        evo.set(e1, f, 'changed')
        evo.destroy(e2)
        check_search(f, 'deferred', e1, e2)
    end
    evo.commit()

    check_search(f, 'deferred')
    check_search(f, 'changed', e1)
end

do
    local set_count, insert_count, remove_count = 0, 0, 0

    local f = evo.builder()
        :index()
        :on_set(function(e, ff, v)
            set_count = set_count + 1
            -- the index is already updated when the set hook is called
            local entity_list, entity_count = evo.multi_search(ff, v)
            local found = false
            for i = 1, entity_count do found = found or entity_list[i] == e end
            assert(found)
        end)
        :on_insert(function()
            insert_count = insert_count + 1
        end)
        :on_remove(function(e, ff, v)
            remove_count = remove_count + 1
            -- the index is still not updated when the remove hook is called
            local entity_list, entity_count = evo.multi_search(ff, v)
            local found = false
            for i = 1, entity_count do found = found or entity_list[i] == e end
            assert(found)
        end)
        :build()

    local e = evo.spawn { [f] = 'hooked' }
    assert(set_count == 1 and insert_count == 1 and remove_count == 0)
    check_search(f, 'hooked', e)

    evo.set(e, f, 'other')
    assert(set_count == 2 and insert_count == 1 and remove_count == 0)
    check_search(f, 'hooked')
    check_search(f, 'other', e)

    evo.remove(e, f)
    assert(set_count == 2 and insert_count == 1 and remove_count == 1)
    check_search(f, 'other')
end

do
    local f = evo.builder():index():build()

    local nan = 0 / 0

    -- NaN components cannot be indexed
    local e = evo.spawn { [f] = nan }
    check_search(f, nan)

    evo.set(e, f, 'number')
    check_search(f, 'number', e)

    evo.set(e, f, nan)
    check_search(f, 'number')
    check_search(f, nan)

    evo.destroy(e)
end

do
    local t = evo.builder():tag():index():build()

    -- tags have no components, so they are not indexed
    local e = evo.spawn { [t] = true }
    check_search(t, true)

    evo.destroy(e)
end

do
    local f = evo.builder():index():build()

    local k1, k2 = {}, {}

    local e1 = evo.spawn { [f] = k1 }
    local e2 = evo.spawn { [f] = k2 }

    -- table components are indexed by reference
    check_search(f, k1, e1)
    check_search(f, k2, e2)
    check_search(f, {})

    evo.destroy(e1, e2)
end

do
    local f = evo.builder():index():build()

    local e1 = evo.spawn { [f] = 'gone' }
    local e2 = evo.spawn { [f] = 'gone' }

    check_search(f, 'gone', e1, e2)

    evo.destroy(f)

    assert(evo.alive(e1) and not evo.has(e1, f))
    assert(evo.alive(e2) and not evo.has(e2, f))

    check_search(f, 'gone')
end

do
    local f = evo.builder():index():destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY):build()
    local g = evo.builder():index():build()

    local e1 = evo.spawn { [f] = 'a', [g] = 'b' }
    local e2 = evo.spawn { [g] = 'b' }

    check_search(g, 'b', e1, e2)

    evo.destroy(f)

    assert(not evo.alive(e1) and evo.alive(e2))
    check_search(g, 'b', e2)
end

do
    -- names and groups are searchable through the generic functions too
    local e = evo.builder():name('search_name'):build()
    check_search(evo.NAME, 'search_name', e)
    assert(evo.lookup('search_name') == e)

    local group = evo.id()
    local s1 = evo.builder():group(group):build()
    local s2 = evo.builder():group(group):build()
    check_search(evo.GROUP, group, s1, s2)

    evo.destroy(e, group, s1, s2)
end
