local basics = require 'develop.basics'
basics.unload 'evolved'

local evo = require 'evolved'

evo.debug_mode(true)

if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == nil then
    local i = evo.id()

    for _ = 1, 0xFFFFE do
        local _, v0 = evo.unpack(i)
        evo.destroy(i)
        i = evo.id()
        local _, v1 = evo.unpack(i)
        assert(v1 == v0 + 1)
    end

    do
        local _, v = evo.unpack(i)
        assert(v == 0xFFFFF)
    end

    evo.destroy(i)
    i = evo.id()

    do
        local _, v = evo.unpack(i)
        assert(v == 1)
    end
end

do
    local e1, e2 = evo.id(), evo.id()
    assert(e1 ~= e2)

    assert(evo.alive(e1))
    assert(evo.alive(e2))

    evo.destroy(e1)

    assert(not evo.alive(e1))
    assert(evo.alive(e2))

    evo.destroy(e1)
    evo.destroy(e2)

    assert(not evo.alive(e1))
    assert(not evo.alive(e2))

    evo.destroy(e1)
    evo.destroy(e2)

    assert(not evo.alive(e1))
    assert(not evo.alive(e2))
end

do
    do
        local i0 = evo.id(-1)
        assert(type(i0) == 'nil')
    end
    do
        local i0 = evo.id(0)
        assert(type(i0) == 'nil')
    end
    do
        local i1, i2 = evo.id()
        assert(type(i1) == 'number')
        assert(type(i2) == 'nil')
    end
    do
        local i1, i2 = evo.id(1)
        assert(type(i1) == 'number')
        assert(type(i2) == 'nil')
    end
    do
        local i1, i2, i3 = evo.id(2)
        assert(type(i1) == 'number')
        assert(type(i2) == 'number')
        assert(type(i3) == 'nil')
    end
    do
        local i1, i2, i3, i4 = evo.id(3)
        assert(type(i1) == 'number')
        assert(type(i2) == 'number')
        assert(type(i3) == 'number')
        assert(type(i4) == 'nil')
    end
    do
        local i1, i2, i3, i4, i5 = evo.id(4)
        assert(type(i1) == 'number')
        assert(type(i2) == 'number')
        assert(type(i3) == 'number')
        assert(type(i4) == 'number')
        assert(type(i5) == 'nil')
    end
    do
        local i1, i2, i3, i4, i5, i6 = evo.id(5)
        assert(type(i1) == 'number')
        assert(type(i2) == 'number')
        assert(type(i3) == 'number')
        assert(type(i4) == 'number')
        assert(type(i5) == 'number')
        assert(type(i6) == 'nil')
    end
end

do
    local f1, f2 = evo.id(2)
    local e = evo.id()

    do
        assert(not evo.has(e, f1))
        assert(not evo.has(e, f2))
        assert(not evo.has_all(e, f1, f2))
        assert(not evo.has_any(e, f1, f2))
    end

    do
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)

        local c1, c2 = evo.get(e, f1, f2)
        assert(c1 == nil and c2 == nil)
    end

    evo.set(e, f1, 41)

    do
        assert(evo.has(e, f1))
        assert(not evo.has(e, f2))
        assert(not evo.has_all(e, f1, f2))
        assert(evo.has_any(e, f1, f2))
    end

    do
        assert(evo.get(e, f1) == 41)
        assert(evo.get(e, f2) == nil)

        local c1, c2 = evo.get(e, f1, f2)
        assert(c1 == 41 and c2 == nil)
    end

    evo.set(e, f2, 42)

    do
        assert(evo.has(e, f1))
        assert(evo.has(e, f2))
        assert(evo.has_all(e, f1, f2))
        assert(evo.has_any(e, f1, f2))
    end

    do
        assert(evo.get(e, f1) == 41)
        assert(evo.get(e, f2) == 42)

        local c1, c2 = evo.get(e, f1, f2)
        assert(c1 == 41 and c2 == 42)
    end
end

do
    local f1, f2 = evo.id(2)
    local e = evo.id()

    evo.set(e, f1, 41)

    evo.set(e, f2, 42)

    do
        assert(evo.has_all(e, f1, f2))
        local c1, c2 = evo.get(e, f1, f2)
        assert(c1 == 41 and c2 == 42)
    end
end

do
    local f1, f2 = evo.id(2)

    do
        local e = evo.id()
        evo.set(e, f1, 41)
        evo.set(e, f2, 42)

        evo.remove(e, f1)

        assert(not evo.has(e, f1))
        assert(evo.has(e, f2))

        local c1, c2 = evo.get(e, f1, f2)
        assert(c1 == nil and c2 == 42)
    end

    do
        local e = evo.id()
        evo.set(e, f1, 41)
        evo.set(e, f2, 42)

        evo.remove(e, f2)

        assert(evo.has(e, f1))
        assert(not evo.has(e, f2))

        local c1, c2 = evo.get(e, f1, f2)
        assert(c1 == 41 and c2 == nil)
    end

    do
        local e = evo.id()
        evo.set(e, f1, 41)
        evo.set(e, f2, 42)

        evo.remove(e, f1, f2)

        assert(not evo.has_any(e, f1, f2))

        local c1, c2 = evo.get(e, f1, f2)
        assert(c1 == nil and c2 == nil)
    end
end

do
    local f1, f2 = evo.id(2)
    local e1, e2 = evo.id(2)

    evo.set(e1, f1, 41)
    evo.set(e2, f2, 42)

    do
        assert(evo.get(e1, f1) == 41 and evo.get(e1, f2) == nil)
        assert(evo.get(e2, f2) == 42 and evo.get(e2, f1) == nil)
    end

    evo.set(e1, f2, 43)

    do
        assert(evo.get(e1, f1) == 41 and evo.get(e1, f2) == 43)
        assert(evo.get(e2, f2) == 42 and evo.get(e2, f1) == nil)
    end

    evo.set(e2, f1, 44)

    do
        assert(evo.get(e1, f1) == 41 and evo.get(e1, f2) == 43)
        assert(evo.get(e2, f2) == 42 and evo.get(e2, f1) == 44)
    end
end

do
    local f1, f2 = evo.id(2)

    do
        local e1, e2 = evo.id(2)

        evo.set(e1, f1, 41)
        evo.set(e1, f2, 43)
        evo.set(e2, f1, 44)
        evo.set(e2, f2, 42)

        do
            assert(evo.get(e1, f1) == 41 and evo.get(e1, f2) == 43)
            assert(evo.get(e2, f2) == 42 and evo.get(e2, f1) == 44)
        end

        evo.remove(e1, f1)

        do
            assert(evo.get(e1, f1) == nil and evo.get(e1, f2) == 43)
            assert(evo.get(e2, f2) == 42 and evo.get(e2, f1) == 44)
        end

        evo.remove(e2, f1)

        do
            assert(evo.get(e1, f1) == nil and evo.get(e1, f2) == 43)
            assert(evo.get(e2, f2) == 42 and evo.get(e2, f1) == nil)
        end
    end
end

do
    local f1, f2 = evo.id(2)
    local e1, e2 = evo.id(2)

    evo.set(e1, f1, 41)
    evo.set(e1, f2, 43)
    evo.set(e2, f1, 44)
    evo.set(e2, f2, 42)

    evo.clear(e1)

    do
        assert(evo.get(e1, f1) == nil and evo.get(e1, f2) == nil)
        assert(evo.get(e2, f2) == 42 and evo.get(e2, f1) == 44)
    end

    evo.clear(e2)

    do
        assert(evo.get(e1, f1) == nil and evo.get(e1, f2) == nil)
        assert(evo.get(e2, f2) == nil and evo.get(e2, f1) == nil)
    end
end

do
    local f1, f2 = evo.id(2)

    local e = evo.id()

    assert(evo.get(e, f1) == nil)

    evo.set(e, f1, 41)
    evo.set(e, f1, 42)
    assert(evo.get(e, f1) == 42)

    assert(evo.get(e, f2) == nil)

    evo.set(e, f2, 43)
    evo.set(e, f2, 44)
    assert(evo.get(e, f2) == 44)
end

do
    local f1, f2 = evo.id(2)

    local e = evo.id()

    evo.set(e, f1, 41)
    assert(evo.get(e, f1) == 41)
    assert(evo.get(e, f2) == nil)

    evo.set(e, f1, 43)
    assert(evo.get(e, f1) == 43)
    assert(evo.get(e, f2) == nil)

    evo.set(e, f2, 42)
    assert(evo.get(e, f1) == 43)
    assert(evo.get(e, f2) == 42)

    evo.set(e, f2, 44)
    assert(evo.get(e, f1) == 43)
    assert(evo.get(e, f2) == 44)
end

do
    local f1, f2 = evo.id(2)
    local e1, e2 = evo.id(2)

    evo.set(e1, f1, 41)
    evo.set(e2, f1, 42)

    do
        assert(evo.get(e1, f1) == 41 and evo.get(e1, f2) == nil)
        assert(evo.get(e2, f1) == 42 and evo.get(e2, f2) == nil)
    end

    evo.set(e1, f2, 43)

    do
        assert(evo.get(e1, f1) == 41 and evo.get(e1, f2) == 43)
        assert(evo.get(e2, f1) == 42 and evo.get(e2, f2) == nil)
    end

    evo.set(e2, f2, 44)

    do
        assert(evo.get(e1, f1) == 41 and evo.get(e1, f2) == 43)
        assert(evo.get(e2, f1) == 42 and evo.get(e2, f2) == 44)
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)
    evo.set(f1, evo.DEFAULT, 42)
    evo.set(f2, evo.DEFAULT, false)

    local e = evo.id()

    evo.set(e, f1)
    evo.set(e, f2)
    evo.set(e, f3)
    evo.set(e, f4, false)

    assert(evo.get(e, f1) == 42)
    assert(evo.get(e, f2) == false)
    assert(evo.get(e, f3) == true)
    assert(evo.get(e, f4) == false)
end

do
    local f = evo.id()
    local e = evo.id()

    local set_count = 0
    local assign_count = 0
    local insert_count = 0
    local remove_count = 0

    local last_set_new_component = nil
    local last_set_old_component = nil
    local last_assign_new_component = nil
    local last_assign_old_component = nil
    local last_insert_new_component = nil
    local last_remove_old_component = nil

    evo.set(f, evo.ON_SET, function(entity, fragment, new_component, old_component)
        assert(entity == e)
        assert(fragment == f)
        set_count = set_count + 1
        last_set_new_component = new_component
        last_set_old_component = old_component
    end)

    evo.set(f, evo.ON_ASSIGN, function(entity, fragment, new_component, old_component)
        assert(entity == e)
        assert(fragment == f)
        assign_count = assign_count + 1
        last_assign_new_component = new_component
        last_assign_old_component = old_component
    end)

    evo.set(f, evo.ON_INSERT, function(entity, fragment, new_component)
        assert(entity == e)
        assert(fragment == f)
        insert_count = insert_count + 1
        last_insert_new_component = new_component
    end)

    evo.set(f, evo.ON_REMOVE, function(entity, fragment, old_component)
        assert(entity == e)
        assert(fragment == f)
        remove_count = remove_count + 1
        last_remove_old_component = old_component
    end)

    evo.set(e, f, 21)
    assert(set_count == 1)
    assert(assign_count == 0)
    assert(insert_count == 1)
    assert(remove_count == 0)
    assert(last_set_old_component == nil)
    assert(last_set_new_component == 21)
    assert(last_insert_new_component == 21)

    evo.set(e, f, 42)
    assert(set_count == 2)
    assert(assign_count == 1)
    assert(insert_count == 1)
    assert(remove_count == 0)
    assert(last_set_new_component == 42)
    assert(last_set_old_component == 21)
    assert(last_assign_new_component == 42)
    assert(last_assign_old_component == 21)

    evo.set(e, f, 43)
    assert(set_count == 3)
    assert(assign_count == 2)
    assert(insert_count == 1)
    assert(remove_count == 0)
    assert(last_set_new_component == 43)
    assert(last_set_old_component == 42)
    assert(last_assign_new_component == 43)
    assert(last_assign_old_component == 42)

    evo.clear(e)
    assert(set_count == 3)
    assert(assign_count == 2)
    assert(insert_count == 1)
    assert(remove_count == 1)
    assert(last_remove_old_component == 43)

    evo.set(e, f, 44)
    assert(set_count == 4)
    assert(assign_count == 2)
    assert(insert_count == 2)
    assert(remove_count == 1)
    assert(last_set_new_component == 44)
    assert(last_set_old_component == nil)
    assert(last_insert_new_component == 44)

    evo.set(e, f, 45)
    assert(set_count == 5)
    assert(assign_count == 3)
    assert(insert_count == 2)
    assert(remove_count == 1)
    assert(last_set_new_component == 45)
    assert(last_set_old_component == 44)
    assert(last_assign_new_component == 45)
    assert(last_assign_old_component == 44)

    evo.destroy(e)
    assert(set_count == 5)
    assert(assign_count == 3)
    assert(insert_count == 2)
    assert(remove_count == 2)
    assert(last_remove_old_component == 45)
end

do
    local f1, f2 = evo.id(2)
    local e = evo.id()

    local remove_count = 0
    local removed_sum = 0

    evo.set(f1, evo.ON_REMOVE, function(entity, fragment, component)
        assert(entity == e)
        assert(fragment == f1)
        remove_count = remove_count + 1
        removed_sum = removed_sum + component
    end)

    evo.set(f2, evo.ON_REMOVE, function(entity, fragment, component)
        assert(entity == e)
        assert(fragment == f2)
        remove_count = remove_count + 1
        removed_sum = removed_sum + component
    end)

    evo.set(e, f1, 42)
    evo.remove(e, f1, f2)
    assert(remove_count == 1)
    assert(removed_sum == 42)

    evo.set(e, f1, 42)
    evo.set(e, f2, 43)
    evo.remove(e, f1, f2, f2)
    assert(remove_count == 3)
    assert(removed_sum == 42 + 42 + 43)

    evo.set(e, f1, 44)
    evo.set(e, f2, 45)
    evo.clear(e)
    assert(remove_count == 5)
    assert(removed_sum == 42 + 42 + 43 + 44 + 45)

    evo.set(e, f1, 46)
    evo.set(e, f2, 47)
    evo.destroy(e)
    assert(remove_count == 7)
    assert(removed_sum == 42 + 42 + 43 + 44 + 45 + 46 + 47)
end

do
    local f = evo.id()
    local e = evo.id()

    evo.set(e, f, 42)
    assert(evo.has(e, f))
    assert(evo.alive(e))

    evo.destroy(e)
    assert(not evo.has(e, f))
    assert(not evo.alive(e))
end

do
    local f = evo.id()

    do
        local e = evo.id()
        assert(evo.empty(e))

        evo.set(e, f, 42)
        assert(not evo.empty(e))

        evo.clear(e)
        assert(evo.empty(e))
    end

    do
        local e = evo.id()
        assert(evo.empty(e))

        evo.set(e, f, 42)
        assert(not evo.empty(e))

        evo.destroy(e)
        assert(evo.empty(e))
    end
end

do
    local f1, f2, f3 = evo.id(3)

    local _ = evo.id()

    local e1 = evo.id()
    evo.set(e1, f1, 41)

    local e2 = evo.id()
    evo.set(e2, f1, 42)
    evo.set(e2, f2, 43)

    local e2b = evo.id()
    evo.set(e2b, f1, 44)
    evo.set(e2b, f2, 45)

    do
        local chunk, entity_list, entity_count = evo.chunk(f1)
        assert(entity_list and entity_list[1] == e1)
        assert(entity_count and entity_count == 1)
        assert(chunk and chunk:components(f1)[1] == 41)
    end

    do
        local chunk, entity_list, entity_count = evo.chunk(f1, f2)
        assert(chunk == evo.chunk(f1, f2))
        assert(chunk == evo.chunk(f1, f1, f2))
        assert(chunk == evo.chunk(f1, f1, f2, f2))
        assert(chunk == evo.chunk(f1, f2, f2, f1))
        assert(chunk == evo.chunk(f2, f1))
        assert(chunk == evo.chunk(f2, f1, f2, f1))
        assert(entity_list and entity_list[1] == e2 and entity_list[2] == e2b)
        assert(entity_count and entity_count == 2)
        assert(chunk and chunk:components(f1)[1] == 42 and chunk:components(f2)[1] == 43)
        assert(chunk and chunk:components(f1)[2] == 44 and chunk:components(f2)[2] == 45)
    end

    do
        local chunk123, entities123, entity123_count = evo.chunk(f1, f2, f3)
        local chunk321, entities321, entity321_count = evo.chunk(f3, f2, f1)
        assert(chunk123 and #entities123 >= 0 and entity123_count == 0)
        assert(chunk321 and #entities321 >= 0 and entity321_count == 0)
        assert(chunk123 == chunk321 and entities123 == entities321)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f1, evo.DEFAULT, 42)

    local e1, e2, e3, e4 = evo.id(4)

    evo.set(e1, f3, 44)

    evo.set(e2, f1, 45)
    evo.set(e2, f2, 46)
    evo.set(e2, f3, 47)

    evo.set(e3, f1, 45)
    evo.set(e3, f2, 46)
    evo.set(e3, f3, 47)

    assert(evo.defer())
    assert(not evo.defer())

    evo.set(e1, f1)
    evo.set(e1, f2, 43)
    evo.remove(e2, f1, f2)
    evo.set(e2, f3, 48)
    evo.clear(e3)
    evo.set(e3, f1, 48)
    evo.destroy(e4)

    assert(evo.get(e1, f1) == nil)
    assert(evo.get(e1, f2) == nil)
    assert(evo.get(e1, f3) == 44)

    assert(evo.get(e2, f1) == 45)
    assert(evo.get(e2, f2) == 46)
    assert(evo.get(e2, f3) == 47)

    assert(evo.get(e3, f1) == 45)
    assert(evo.get(e3, f2) == 46)
    assert(evo.get(e3, f3) == 47)

    assert(not evo.commit())
    assert(evo.commit())

    assert(evo.get(e1, f1) == 42)
    assert(evo.get(e1, f2) == 43)
    assert(evo.get(e1, f3) == 44)

    assert(evo.get(e2, f1) == nil)
    assert(evo.get(e2, f2) == nil)
    assert(evo.get(e2, f3) == 48)

    assert(evo.get(e3, f1) == 48)
    assert(evo.get(e3, f2) == nil)
    assert(evo.get(e3, f3) == nil)

    assert(not evo.alive(e4))
end

do
    local f1, f2 = evo.id(2)

    ---@param entity evolved.entity
    ---@param fragment evolved.fragment
    ---@param component evolved.component
    evo.set(f1, evo.ON_SET, function(entity, fragment, component)
        assert(fragment == f1)
        evo.set(entity, f2, component * 2)
    end)

    ---@param entity evolved.entity
    ---@param fragment evolved.fragment
    ---@param component evolved.component
    evo.set(f1, evo.ON_REMOVE, function(entity, fragment, component)
        assert(fragment == f1)
        assert(component == 21)
        evo.remove(entity, f2)
    end)

    do
        local e = evo.id()

        evo.set(e, f1, 21)
        assert(evo.get(e, f1) == 21)
        assert(evo.get(e, f2) == 42)

        evo.remove(e, f1)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
    end
    do
        local e = evo.id()

        evo.set(e, f1, 21)
        assert(evo.get(e, f1) == 21)
        assert(evo.get(e, f2) == 42)

        evo.clear(e)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
    end
    do
        local e = evo.id()

        evo.set(e, f1, 21)
        assert(evo.get(e, f1) == 21)
        assert(evo.get(e, f2) == 42)

        evo.destroy(e)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
    end
end

do
    local f1, f2 = evo.id(2)

    ---@param entity evolved.entity
    ---@param fragment evolved.fragment
    ---@param component evolved.component
    evo.set(f1, evo.ON_INSERT, function(entity, fragment, component)
        assert(fragment == f1)
        evo.set(entity, f2, component * 2)
    end)

    ---@param entity evolved.entity
    ---@param fragment evolved.fragment
    ---@param component evolved.component
    evo.set(f1, evo.ON_REMOVE, function(entity, fragment, component)
        assert(fragment == f1)
        assert(component == 21)
        evo.remove(entity, f2)
    end)

    do
        local e = evo.id()

        evo.set(e, f1, 21)
        assert(evo.get(e, f1) == 21)
        assert(evo.get(e, f2) == 42)

        evo.remove(e, f1)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
    end
    do
        local e = evo.id()

        evo.set(e, f1, 21)
        assert(evo.get(e, f1) == 21)
        assert(evo.get(e, f2) == 42)

        evo.clear(e)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
    end
    do
        local e = evo.id()

        evo.set(e, f1, 21)
        assert(evo.get(e, f1) == 21)
        assert(evo.get(e, f2) == 42)

        evo.destroy(e)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
    end
end

do
    do
        local f1, f2, f3, f4 = evo.id(4)

        local e1 = evo.id()
        evo.set(e1, f1, 41)

        local e2 = evo.id()
        evo.set(e2, f1, 42)
        evo.set(e2, f2, 43)

        local e3 = evo.id()
        evo.set(e3, f1, 44)
        evo.set(e3, f2, 45)
        evo.set(e3, f3, 46)

        local e4 = evo.id()
        evo.set(e4, f1, 47)
        evo.set(e4, f2, 48)
        evo.set(e4, f3, 49)
        evo.set(e4, f4, 50)

        local e5 = evo.id()
        evo.set(e5, f2, 51)
        evo.set(e5, f3, 52)
        evo.set(e5, f4, 53)

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f1, f2 })

        evo.batch_set(q, f1, 60)

        assert(evo.get(e1, f1) == 41 and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 60 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 60 and evo.get(e3, f3) == 46)
        assert(evo.get(e4, f1) == 60 and evo.get(e4, f3) == 49)
        assert(evo.get(e5, f1) == nil and evo.get(e5, f3) == 52)

        evo.set(q, evo.INCLUDES, { f1, f2, f3 })
        evo.batch_set(q, f3, 70)

        assert(evo.get(e1, f1) == 41 and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 60 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 60 and evo.get(e3, f3) == 70)
        assert(evo.get(e4, f1) == 60 and evo.get(e4, f3) == 70)
        assert(evo.get(e5, f1) == nil and evo.get(e5, f3) == 52)
    end
    do
        local f1, f2, f3, f4 = evo.id(4)

        local entity_sum = 0
        local component_sum = 0

        evo.set(f1, evo.ON_ASSIGN, function(entity, fragment, new_component, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f1)
            component_sum = component_sum + new_component + old_component
        end)

        evo.set(f3, evo.ON_ASSIGN, function(entity, fragment, new_component, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f3)
            component_sum = component_sum + new_component + old_component
        end)

        local e1 = evo.id()
        evo.set(e1, f1, 41)

        local e2 = evo.id()
        evo.set(e2, f1, 42)
        evo.set(e2, f2, 43)

        local e3 = evo.id()
        evo.set(e3, f1, 44)
        evo.set(e3, f2, 45)
        evo.set(e3, f3, 46)

        local e4 = evo.id()
        evo.set(e4, f1, 47)
        evo.set(e4, f2, 48)
        evo.set(e4, f3, 49)
        evo.set(e4, f4, 50)

        local e5 = evo.id()
        evo.set(e5, f2, 51)
        evo.set(e5, f3, 52)
        evo.set(e5, f4, 53)

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f1, f2 })

        evo.batch_set(q, f1, 60)

        assert(entity_sum == e2 + e3 + e4)
        assert(component_sum == 42 + 44 + 47 + 60 + 60 + 60)
        entity_sum = 0
        component_sum = 0

        assert(evo.get(e1, f1) == 41 and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 60 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 60 and evo.get(e3, f3) == 46)
        assert(evo.get(e4, f1) == 60 and evo.get(e4, f3) == 49)
        assert(evo.get(e5, f1) == nil and evo.get(e5, f3) == 52)

        evo.set(q, evo.INCLUDES, { f1, f2, f3 })
        evo.batch_set(q, f3, 70)

        assert(entity_sum == e3 + e4)
        assert(component_sum == 46 + 49 + 70 + 70)
        entity_sum = 0
        component_sum = 0

        assert(evo.get(e1, f1) == 41 and evo.get(e1, f3) == nil)
        assert(evo.get(e2, f1) == 60 and evo.get(e2, f3) == nil)
        assert(evo.get(e3, f1) == 60 and evo.get(e3, f3) == 70)
        assert(evo.get(e4, f1) == 60 and evo.get(e4, f3) == 70)
        assert(evo.get(e5, f1) == nil and evo.get(e5, f3) == 52)
    end
end

do
    do
        local f1, f2, f3, f4 = evo.id(4)

        local e1 = evo.id()
        evo.set(e1, f1, 41)

        local e2 = evo.id()
        evo.set(e2, f1, 42)
        evo.set(e2, f2, 43)

        local e3 = evo.id()
        evo.set(e3, f1, 44)
        evo.set(e3, f2, 45)
        evo.set(e3, f3, 46)

        local e4 = evo.id()
        evo.set(e4, f1, 47)
        evo.set(e4, f2, 48)
        evo.set(e4, f3, 49)
        evo.set(e4, f4, 50)

        local e5 = evo.id()
        evo.set(e5, f2, 51)
        evo.set(e5, f3, 52)
        evo.set(e5, f4, 53)

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f1, f2 })

        evo.batch_clear(q)

        assert(evo.alive(e1))
        assert(evo.alive(e2))
        assert(evo.alive(e3))
        assert(evo.alive(e4))
        assert(evo.alive(e5))

        assert(not evo.empty(e1))
        assert(evo.empty(e2))
        assert(evo.empty(e3))
        assert(evo.empty(e4))
        assert(not evo.empty(e5))
    end
    do
        local f1, f2, f3, f4 = evo.id(4)

        local entity_sum = 0
        local component_sum = 0

        evo.set(f1, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f1)
            component_sum = component_sum + old_component
        end)

        evo.set(f2, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f2)
            component_sum = component_sum + old_component
        end)

        evo.set(f3, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f3)
            component_sum = component_sum + old_component
        end)

        evo.set(f4, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f4)
            component_sum = component_sum + old_component
        end)

        local e1 = evo.id()
        evo.set(e1, f1, 41)

        local e2 = evo.id()
        evo.set(e2, f1, 42)
        evo.set(e2, f2, 43)

        local e3 = evo.id()
        evo.set(e3, f1, 44)
        evo.set(e3, f2, 45)
        evo.set(e3, f3, 46)

        local e4 = evo.id()
        evo.set(e4, f1, 47)
        evo.set(e4, f2, 48)
        evo.set(e4, f3, 49)
        evo.set(e4, f4, 50)

        local e5 = evo.id()
        evo.set(e5, f2, 51)
        evo.set(e5, f3, 52)
        evo.set(e5, f4, 53)

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f1, f2 })

        evo.batch_clear(q)
        assert(entity_sum == e2 * 2 + e3 * 3 + e4 * 4)
        assert(component_sum == 42 + 43 + 44 + 45 + 46 + 47 + 48 + 49 + 50)

        assert(evo.alive(e1))
        assert(evo.alive(e2))
        assert(evo.alive(e3))
        assert(evo.alive(e4))
        assert(evo.alive(e5))

        assert(not evo.empty(e1))
        assert(evo.empty(e2))
        assert(evo.empty(e3))
        assert(evo.empty(e4))
        assert(not evo.empty(e5))
    end
end

do
    do
        local f1, f2, f3, f4 = evo.id(4)

        local e1 = evo.id()
        evo.set(e1, f1, 41)

        local e2 = evo.id()
        evo.set(e2, f1, 42)
        evo.set(e2, f2, 43)

        local e3 = evo.id()
        evo.set(e3, f1, 44)
        evo.set(e3, f2, 45)
        evo.set(e3, f3, 46)

        local e4 = evo.id()
        evo.set(e4, f1, 47)
        evo.set(e4, f2, 48)
        evo.set(e4, f3, 49)
        evo.set(e4, f4, 50)

        local e5 = evo.id()
        evo.set(e5, f2, 51)
        evo.set(e5, f3, 52)
        evo.set(e5, f4, 53)

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f1, f2 })

        evo.batch_destroy(q)

        assert(evo.alive(e1))
        assert(not evo.alive(e2))
        assert(not evo.alive(e3))
        assert(not evo.alive(e4))
        assert(evo.alive(e5))

        assert(not evo.empty(e1))
        assert(evo.empty(e2))
        assert(evo.empty(e3))
        assert(evo.empty(e4))
        assert(not evo.empty(e5))
    end
    do
        local f1, f2, f3, f4 = evo.id(4)

        local entity_sum = 0
        local component_sum = 0

        evo.set(f1, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f1)
            component_sum = component_sum + old_component
        end)

        evo.set(f2, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f2)
            component_sum = component_sum + old_component
        end)

        evo.set(f3, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f3)
            component_sum = component_sum + old_component
        end)

        evo.set(f4, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f4)
            component_sum = component_sum + old_component
        end)

        local e1 = evo.id()
        evo.set(e1, f1, 41)

        local e2 = evo.id()
        evo.set(e2, f1, 42)
        evo.set(e2, f2, 43)

        local e3 = evo.id()
        evo.set(e3, f1, 44)
        evo.set(e3, f2, 45)
        evo.set(e3, f3, 46)

        local e4 = evo.id()
        evo.set(e4, f1, 47)
        evo.set(e4, f2, 48)
        evo.set(e4, f3, 49)
        evo.set(e4, f4, 50)

        local e5 = evo.id()
        evo.set(e5, f2, 51)
        evo.set(e5, f3, 52)
        evo.set(e5, f4, 53)

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f1, f2 })

        evo.batch_destroy(q)
        assert(entity_sum == e2 * 2 + e3 * 3 + e4 * 4)
        assert(component_sum == 42 + 43 + 44 + 45 + 46 + 47 + 48 + 49 + 50)

        assert(evo.alive(e1))
        assert(not evo.alive(e2))
        assert(not evo.alive(e3))
        assert(not evo.alive(e4))
        assert(evo.alive(e5))

        assert(not evo.empty(e1))
        assert(evo.empty(e2))
        assert(evo.empty(e3))
        assert(evo.empty(e4))
        assert(not evo.empty(e5))
    end
end

do
    do
        local f1, f2, f3, f4 = evo.id(4)

        local e1 = evo.id()
        evo.set(e1, f1, 41)

        local e2 = evo.id()
        evo.set(e2, f1, 42)
        evo.set(e2, f2, 43)

        local e3 = evo.id()
        evo.set(e3, f1, 44)
        evo.set(e3, f2, 45)
        evo.set(e3, f3, 46)

        local e4 = evo.id()
        evo.set(e4, f1, 47)
        evo.set(e4, f2, 48)
        evo.set(e4, f3, 49)
        evo.set(e4, f4, 50)

        local e5 = evo.id()
        evo.set(e5, f2, 51)
        evo.set(e5, f3, 52)
        evo.set(e5, f4, 53)

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f1, f2 })

        evo.batch_remove(q, f2, f3)

        assert(evo.get(e1, f1) == 41)
        assert(evo.get(e2, f1) == 42)
        assert(evo.get(e2, f2) == nil)
        assert(evo.get(e3, f1) == 44)
        assert(evo.get(e3, f2) == nil)
        assert(evo.get(e3, f3) == nil)
        assert(evo.get(e4, f1) == 47)
        assert(evo.get(e4, f2) == nil)
        assert(evo.get(e4, f3) == nil)
        assert(evo.get(e4, f4) == 50)
        assert(evo.get(e5, f1) == nil)
        assert(evo.get(e5, f2) == 51)
        assert(evo.get(e5, f3) == 52)
        assert(evo.get(e5, f4) == 53)
    end
    do
        local f1, f2, f3, f4 = evo.id(4)

        local entity_sum = 0
        local component_sum = 0

        evo.set(f1, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f1)
            component_sum = component_sum + old_component
        end)

        evo.set(f2, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f2)
            component_sum = component_sum + old_component
        end)

        evo.set(f3, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f3)
            component_sum = component_sum + old_component
        end)

        evo.set(f4, evo.ON_REMOVE, function(entity, fragment, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f4)
            component_sum = component_sum + old_component
        end)

        local e1 = evo.id()
        evo.set(e1, f1, 41)

        local e2 = evo.id()
        evo.set(e2, f1, 42)
        evo.set(e2, f2, 43)

        local e3 = evo.id()
        evo.set(e3, f1, 44)
        evo.set(e3, f2, 45)
        evo.set(e3, f3, 46)

        local e4 = evo.id()
        evo.set(e4, f1, 47)
        evo.set(e4, f2, 48)
        evo.set(e4, f3, 49)
        evo.set(e4, f4, 50)

        local e5 = evo.id()
        evo.set(e5, f2, 51)
        evo.set(e5, f3, 52)
        evo.set(e5, f4, 53)

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f1, f2 })

        evo.batch_remove(q, f2, f3, f3)
        assert(entity_sum == e2 + e3 * 2 + e4 * 2)
        assert(component_sum == 43 + 45 + 46 + 48 + 49)

        assert(not evo.has_any(e1, f2, f3))
        assert(not evo.has_any(e2, f2, f3))
        assert(not evo.has_any(e3, f2, f3))
        assert(not evo.has_any(e4, f2, f3))
        assert(evo.has_all(e5, f2, f3))
    end
end

do
    do
        local f1, f2 = evo.id(2)
        evo.set(f2, evo.DEFAULT, 42)

        local e1 = evo.builder():set(f1, 11):spawn()
        local e2 = evo.builder():set(f1, 21):set(f2, 22):spawn()

        assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == nil)
        assert(evo.get(e2, f1) == 21 and evo.get(e2, f2) == 22)

        local q = evo.builder():include(f1):exclude(f2):spawn()
        evo.batch_set(q, f2)

        assert(evo.get(e1, f1) == 11 and evo.get(e1, f2) == 42)
        assert(evo.get(e2, f1) == 21 and evo.get(e2, f2) == 22)
    end
    do
        local f1, f2, f3, f4 = evo.id(4)

        local e1 = evo.id()
        evo.set(e1, f1, 41)

        local e2 = evo.id()
        evo.set(e2, f1, 42)
        evo.set(e2, f2, 43)

        local e3 = evo.id()
        evo.set(e3, f1, 44)
        evo.set(e3, f2, 45)
        evo.set(e3, f3, 46)

        local e4 = evo.id()
        evo.set(e4, f2, 48)
        evo.set(e4, f3, 49)
        evo.set(e4, f4, 50)

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f2 })
        evo.set(q, evo.EXCLUDES, { f1 })

        evo.batch_set(q, f1, 60)

        assert(evo.get(e1, f1) == 41)
        assert(evo.get(e2, f1) == 42)
        assert(evo.get(e3, f1) == 44)
        assert(evo.get(e4, f1) == 60)
    end
    do
        local f1, f2, f3, f4, f5 = evo.id(5)

        local entity_sum = 0
        local component_sum = 0

        evo.set(f1, evo.ON_INSERT, function(entity, fragment, new_component)
            entity_sum = entity_sum + entity
            assert(fragment == f1)
            component_sum = component_sum + new_component
        end)

        evo.set(f5, evo.ON_INSERT, function(entity, fragment, new_component)
            entity_sum = entity_sum + entity
            assert(fragment == f5)
            component_sum = component_sum + new_component
        end)

        local e1 = evo.id()
        evo.set(e1, f1, 41)

        local e2 = evo.id()
        evo.set(e2, f1, 42)
        evo.set(e2, f2, 43)

        local e3 = evo.id()
        evo.set(e3, f1, 44)
        evo.set(e3, f2, 45)
        evo.set(e3, f3, 46)

        local e4 = evo.id()
        evo.set(e4, f2, 48)
        evo.set(e4, f3, 49)
        evo.set(e4, f4, 50)

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f2 })
        evo.set(q, evo.EXCLUDES, { f1 })

        entity_sum = 0
        component_sum = 0
        evo.batch_set(q, f1, 60)
        assert(entity_sum == e4)
        assert(component_sum == 60)

        assert(evo.get(e1, f1) == 41)
        assert(evo.get(e2, f1) == 42)
        assert(evo.get(e3, f1) == 44)
        assert(evo.get(e4, f1) == 60)

        evo.set(q, evo.EXCLUDES)

        entity_sum = 0
        component_sum = 0
        evo.batch_set(q, f5, 70)
        assert(entity_sum == e2 + e3 + e4)
        assert(component_sum == 70 * 3)
    end
end

do
    do
        local f1, f2, f3, f4 = evo.id(4)

        local e1 = evo.id()
        evo.set(e1, f1, 41)

        local e2 = evo.id()
        evo.set(e2, f1, 42)
        evo.set(e2, f2, 43)

        local e3 = evo.id()
        evo.set(e3, f1, 44)
        evo.set(e3, f2, 45)
        evo.set(e3, f3, 46)

        local e4 = evo.id()
        evo.set(e4, f2, 48)
        evo.set(e4, f3, 49)
        evo.set(e4, f4, 50)

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f2 })

        evo.batch_set(q, f1, 60)

        assert(evo.get(e1, f1) == 41)
        assert(evo.get(e2, f1) == 60)
        assert(evo.get(e3, f1) == 60)
        assert(evo.get(e4, f1) == 60)
    end
    do
        local f1, f2, f3, f4 = evo.id(4)

        local entity_sum = 0
        local component_sum = 0

        evo.set(f1, evo.ON_ASSIGN, function(entity, fragment, new_component, old_component)
            entity_sum = entity_sum + entity
            assert(fragment == f1)
            component_sum = component_sum + new_component + old_component
        end)

        evo.set(f1, evo.ON_INSERT, function(entity, fragment, new_component)
            entity_sum = entity_sum + entity
            assert(fragment == f1)
            component_sum = component_sum + new_component
        end)

        local e1 = evo.id()
        evo.set(e1, f1, 41)

        local e2 = evo.id()
        evo.set(e2, f1, 42)
        evo.set(e2, f2, 43)

        local e3 = evo.id()
        evo.set(e3, f1, 44)
        evo.set(e3, f2, 45)
        evo.set(e3, f3, 46)

        local e4 = evo.id()
        evo.set(e4, f2, 48)
        evo.set(e4, f3, 49)
        evo.set(e4, f4, 50)

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f2 })

        entity_sum = 0
        component_sum = 0
        evo.batch_set(q, f1, 60)
        assert(entity_sum == e2 + e3 + e4)
        assert(component_sum == 42 + 60 + 44 + 60 + 60)

        assert(evo.get(e1, f1) == 41)
        assert(evo.get(e2, f1) == 60)
        assert(evo.get(e3, f1) == 60)
        assert(evo.get(e4, f1) == 60)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    local last_set_entity = 0
    local last_assign_entity = 0
    local last_remove_entity = 0

    evo.set(f1, evo.TAG)
    evo.set(f1, evo.ON_SET, function(e, f, c)
        last_set_entity = e
        assert(f == f1)
        assert(c == nil)
    end)
    evo.set(f1, evo.ON_ASSIGN, function(e, f, c)
        last_assign_entity = e
        assert(f == f1)
        assert(c == nil)
    end)
    evo.set(f1, evo.ON_REMOVE, function(e, f, c)
        last_remove_entity = e
        assert(f == f1)
        assert(c == nil)
    end)

    evo.set(f2, evo.TAG)
    evo.set(f2, evo.ON_SET, function(e, f, c)
        last_set_entity = e
        assert(f == f2)
        assert(c == nil)
    end)
    evo.set(f2, evo.ON_ASSIGN, function(e, f, c)
        last_assign_entity = e
        assert(f == f2)
        assert(c == nil)
    end)
    evo.set(f2, evo.ON_REMOVE, function(e, f, c)
        last_remove_entity = e
        assert(f == f2)
        assert(c == nil)
    end)

    evo.set(f3, evo.ON_SET, function(e, f, c)
        last_set_entity = e
        assert(f == f3)
        assert(c ~= nil)
    end)
    evo.set(f3, evo.ON_ASSIGN, function(e, f, c)
        last_assign_entity = e
        assert(f == f3)
        assert(c ~= nil)
    end)
    evo.set(f3, evo.ON_REMOVE, function(e, f, c)
        last_remove_entity = e
        assert(f == f3)
        assert(c ~= nil)
    end)

    do
        local e = evo.id()

        last_set_entity = 0
        evo.set(e, f1, 41)
        assert(last_set_entity == e)
        assert(evo.has(e, f1) and not evo.has(e, f2))
        assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

        do
            last_set_entity = 0
            evo.set(e, f1, 41)
            assert(last_set_entity == 0)
            assert(evo.has(e, f1) and not evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)
        end

        last_set_entity = 0
        evo.set(e, f2, 42)
        assert(last_set_entity == e)
        assert(evo.has(e, f1) and evo.has(e, f2))
        assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

        do
            last_set_entity = 0
            evo.set(e, f1, 42)
            assert(last_set_entity == 0)
            assert(evo.has(e, f1) and evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

            last_set_entity = 0
            evo.set(e, f2, 42)
            assert(last_set_entity == 0)
            assert(evo.has(e, f1) and evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)
        end

        last_set_entity = 0
        evo.set(e, f3, 43)
        assert(last_set_entity == e)
        assert(evo.has(e, f1) and evo.has(e, f2) and evo.has(e, f3))
        assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 43)

        do
            last_set_entity = 0
            evo.set(e, f1, 42)
            assert(last_set_entity == 0)
            assert(evo.has(e, f1) and evo.has(e, f2) and evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 43)

            last_set_entity = 0
            evo.set(e, f2, 42)
            assert(last_set_entity == 0)
            assert(evo.has(e, f1) and evo.has(e, f2) and evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 43)

            last_set_entity = 0
            evo.set(e, f3, 44)
            assert(last_set_entity == e)
            assert(evo.has(e, f1) and evo.has(e, f2) and evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 44)
        end
    end

    do
        local e = evo.id()

        last_set_entity = 0
        evo.set(e, f1)
        assert(last_set_entity == e)
        assert(evo.has(e, f1) and not evo.has(e, f2))
        assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

        last_set_entity = 0
        evo.set(e, f2, 42)
        assert(last_set_entity == e)
        assert(evo.has(e, f1) and evo.has(e, f2))
        assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

        last_set_entity = 0
        evo.set(e, f3, 43)
        assert(last_set_entity == e)
        assert(evo.has(e, f1) and evo.has(e, f2) and evo.has(e, f3))
        assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 43)
    end

    do
        local e = evo.id()

        do
            last_assign_entity = 0
            evo.set(e, f1)
            assert(evo.has(e, f1) and not evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

            last_assign_entity = 0
            evo.set(e, f1)
            assert(last_assign_entity == 0)
            assert(evo.has(e, f1) and not evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)
        end

        do
            last_assign_entity = 0
            evo.set(e, f2, 43)
            assert(evo.has(e, f1) and evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)

            last_assign_entity = 0
            evo.set(e, f2, 44)
            assert(last_assign_entity == 0)
            assert(evo.has(e, f1) and evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)
        end

        do
            last_assign_entity = 0
            evo.set(e, f3, 44)
            assert(evo.has(e, f1) and evo.has(e, f2) and evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 44)

            last_assign_entity = 0
            evo.set(e, f3, 45)
            assert(last_assign_entity == e)
            assert(evo.has(e, f1) and evo.has(e, f2) and evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == 45)
        end
    end

    do
        do
            local e = evo.id()
            evo.set(e, f1, 41)

            last_remove_entity = 0
            evo.remove(e, f1)
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1))
            assert(evo.get(e, f1) == nil)
        end

        do
            local e = evo.id()
            evo.set(e, f1, 41)
            evo.set(e, f2, 42)

            last_remove_entity = 0
            evo.remove(e, f1, f2)
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1) and not evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)
        end

        do
            local e = evo.id()
            evo.set(e, f1, 41)
            evo.set(e, f2, 42)
            evo.set(e, f3, 43)

            last_remove_entity = 0
            evo.remove(e, f1, f2, f3)
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1) and not evo.has(e, f2) and not evo.has(e, f3))
        end

        do
            local e = evo.id()
            evo.set(e, f1, 41)
            evo.set(e, f2, 42)
            evo.set(e, f3, 43)

            last_remove_entity = 0
            evo.remove(e, f3)
            assert(last_remove_entity == e)
            assert(evo.has(e, f1) and evo.has(e, f2) and not evo.has(e, f3))

            last_remove_entity = 0
            evo.remove(e, f1, f2, f3)
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1) and not evo.has(e, f2) and not evo.has(e, f3))
        end
    end

    do
        do
            local e = evo.id()
            evo.set(e, f1, 41)

            last_remove_entity = 0
            evo.clear(e)
            assert(evo.alive(e))
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1))
            assert(evo.get(e, f1) == nil)
        end

        do
            local e = evo.id()
            evo.set(e, f1, 41)
            evo.set(e, f2, 42)

            last_remove_entity = 0
            evo.clear(e)
            assert(evo.alive(e))
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1) and not evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)
        end

        do
            local e = evo.id()
            evo.set(e, f1, 41)
            evo.set(e, f2, 42)
            evo.set(e, f3, 43)

            last_remove_entity = 0
            evo.clear(e)
            assert(evo.alive(e))
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1) and not evo.has(e, f2) and not evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == nil)
        end
    end

    do
        do
            local e = evo.id()
            evo.set(e, f1, 41)

            last_remove_entity = 0
            evo.destroy(e)
            assert(not evo.alive(e))
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1))
            assert(evo.get(e, f1) == nil)
        end

        do
            local e = evo.id()
            evo.set(e, f1, 41)
            evo.set(e, f2, 42)

            last_remove_entity = 0
            evo.destroy(e)
            assert(not evo.alive(e))
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1) and not evo.has(e, f2))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil)
        end

        do
            local e = evo.id()
            evo.set(e, f1, 41)
            evo.set(e, f2, 42)
            evo.set(e, f3, 43)

            last_remove_entity = 0
            evo.destroy(e)
            assert(not evo.alive(e))
            assert(last_remove_entity == e)
            assert(not evo.has(e, f1) and not evo.has(e, f2) and not evo.has(e, f3))
            assert(evo.get(e, f1) == nil and evo.get(e, f2) == nil and evo.get(e, f3) == nil)
        end
    end

    do
        do
            local q = evo.id()
            evo.set(q, evo.INCLUDES, { f1 })
            evo.batch_destroy(q)
        end

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f1, f2 })

        do
            local e = evo.id()
            evo.batch_set(q, f1, 50)
            assert(not evo.has(e, f1))
            assert(evo.get(e, f1) == nil)
        end

        do
            local e = evo.id()
            evo.set(e, f1, 41)

            evo.batch_set(q, f1, 50)
            assert(evo.has(e, f1))
            assert(evo.get(e, f1) == nil)
        end

        do
            local e1 = evo.id()
            evo.set(e1, f1, 41)
            evo.set(e1, f2, 42)

            local e2 = evo.id()
            evo.set(e2, f1, 41)
            evo.set(e2, f2, 42)
            evo.set(e2, f3, 43)

            evo.batch_set(q, f1, 50)
            assert(evo.has(e1, f1) and evo.has(e1, f2) and not evo.has(e1, f3))
            assert(evo.has(e2, f1) and evo.has(e2, f2) and evo.has(e2, f3))
            assert(evo.get(e1, f1) == nil and evo.get(e1, f2) == nil)
            assert(evo.get(e2, f1) == nil and evo.get(e2, f2) == nil and evo.get(e2, f3) == 43)

            evo.set(q, evo.INCLUDES, { f1, f2, f3 })
            evo.batch_set(q, f3, 51)

            assert(evo.has(e1, f1) and evo.has(e1, f2) and not evo.has(e1, f3))
            assert(evo.has(e2, f1) and evo.has(e2, f2) and evo.has(e2, f3))
            assert(evo.get(e1, f1) == nil and evo.get(e1, f2) == nil)
            assert(evo.get(e2, f1) == nil and evo.get(e2, f2) == nil and evo.get(e2, f3) == 51)
        end
    end

    do
        do
            local q = evo.id()
            evo.set(q, evo.INCLUDES, { f1 })
            evo.batch_destroy(q)
        end

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f1, f2 })

        do
            local e1 = evo.id()
            evo.set(e1, f1, 41)
            evo.set(e1, f2, 42)

            local e2 = evo.id()
            evo.set(e2, f1, 41)

            local e3 = evo.id()
            evo.set(e3, f1, 41)
            evo.set(e3, f2, 42)
            evo.set(e3, f3, 43)

            evo.set(q, evo.EXCLUDES, { f3 })
            evo.batch_set(q, f3, 50)

            assert(evo.has(e1, f1) and evo.has(e1, f2) and evo.has(e1, f3))
            assert(evo.get(e1, f1) == nil and evo.get(e1, f2) == nil and evo.get(e1, f3) == 50)

            assert(evo.has(e2, f1) and not evo.has(e2, f2) and not evo.has(e2, f3))
            assert(evo.get(e2, f1) == nil and evo.get(e2, f2) == nil and evo.get(e2, f3) == nil)

            assert(evo.has(e3, f1) and evo.has(e3, f2) and evo.has(e3, f3))
            assert(evo.get(e3, f1) == nil and evo.get(e3, f2) == nil and evo.get(e3, f3) == 43)

            do
                local chunk, chunk_entity_list, chunk_entity_count = evo.chunk(f1, f2, f3)
                assert(chunk and chunk_entity_list and chunk_entity_count == 2)

                assert(chunk_entity_list[1] == e3 and chunk_entity_list[2] == e1)

                assert(#chunk:components(f1) >= 0)
                assert(#chunk:components(f2) >= 0)
                assert(chunk:components(f3)[1] == 43 and chunk:components(f3)[2] == 50)
            end
        end
    end

    do
        do
            local q = evo.id()
            evo.set(q, evo.INCLUDES, { f1 })
            evo.batch_destroy(q)
        end

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f1, f2 })

        do
            local e1 = evo.id()
            evo.set(e1, f1, 41)
            evo.set(e1, f2, 42)

            local e2 = evo.id()
            evo.set(e2, f1, 41)

            local e3 = evo.id()
            evo.set(e3, f1, 41)
            evo.set(e3, f2, 42)
            evo.set(e3, f3, 43)

            evo.batch_remove(q, f1)

            assert(not evo.has(e1, f1) and evo.has(e1, f2) and not evo.has(e1, f3))
            assert(evo.has(e2, f1) and not evo.has(e2, f2) and not evo.has(e2, f3))
            assert(not evo.has(e3, f1) and evo.has(e3, f2) and evo.has(e3, f3))

            do
                local chunk, chunk_entity_list, chunk_entity_count = evo.chunk(f2)
                assert(chunk and chunk_entity_list and chunk_entity_count == 1)

                assert(chunk_entity_list[1] == e1)
                assert(#chunk:components(f1) >= 0)
                assert(#chunk:components(f2) >= 0)
                assert(#chunk:components(f3) >= 0)
            end

            do
                local chunk, chunk_entity_list, chunk_entity_count = evo.chunk(f2, f3)
                assert(chunk and chunk_entity_list and chunk_entity_count == 1)

                assert(chunk_entity_list[1] == e3)
                assert(#chunk:components(f1) >= 0)
                assert(#chunk:components(f2) >= 0)
                assert(chunk:components(f3)[1] == 43)
            end
        end
    end

    do
        do
            local q = evo.id()
            evo.set(q, evo.INCLUDES, { f1 })
            evo.batch_destroy(q)
        end

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f1, f2 })

        do
            local e1 = evo.id()
            evo.set(e1, f1, 41)
            evo.set(e1, f2, 42)

            local e2 = evo.id()
            evo.set(e2, f1, 41)

            local e3 = evo.id()
            evo.set(e3, f1, 41)
            evo.set(e3, f2, 42)
            evo.set(e3, f3, 43)

            evo.batch_clear(q)

            assert(evo.alive(e1))
            assert(evo.alive(e2))
            assert(evo.alive(e3))

            assert(not evo.has(e1, f1) and not evo.has(e1, f2) and not evo.has(e1, f3))
            assert(evo.has(e2, f1) and not evo.has(e2, f2) and not evo.has(e2, f3))
            assert(not evo.has(e3, f1) and not evo.has(e3, f2) and not evo.has(e3, f3))

            do
                local chunk, chunk_entity_list, chunk_entity_count = evo.chunk(f1, f2, f3)
                assert(chunk and chunk_entity_list and chunk_entity_count == 0)

                assert(#chunk_entity_list >= 0)
                assert(#chunk:components(f1) >= 0)
                assert(#chunk:components(f2) >= 0)
                assert(#chunk:components(f3) >= 0)
            end
        end
    end

    do
        do
            local q = evo.id()
            evo.set(q, evo.INCLUDES, { f1 })
            evo.batch_destroy(q)
        end

        local q = evo.id()
        evo.set(q, evo.INCLUDES, { f1, f2 })

        do
            local e1 = evo.id()
            evo.set(e1, f1, 41)
            evo.set(e1, f2, 42)

            local e2 = evo.id()
            evo.set(e2, f1, 41)

            local e3 = evo.id()
            evo.set(e3, f1, 41)
            evo.set(e3, f2, 42)
            evo.set(e3, f3, 43)

            evo.batch_destroy(q)

            assert(not evo.alive(e1))
            assert(evo.alive(e2))
            assert(not evo.alive(e3))

            assert(not evo.has(e1, f1) and not evo.has(e1, f2) and not evo.has(e1, f3))
            assert(evo.has(e2, f1) and not evo.has(e2, f2) and not evo.has(e2, f3))
            assert(not evo.has(e3, f1) and not evo.has(e3, f2) and not evo.has(e3, f3))

            do
                local chunk, chunk_entity_list, chunk_entity_count = evo.chunk(f1, f2, f3)
                assert(chunk and chunk_entity_list and chunk_entity_count == 0)

                assert(#chunk_entity_list >= 0)
                assert(#chunk:components(f1) >= 0)
                assert(#chunk:components(f2) >= 0)
                assert(#chunk:components(f3) >= 0)
            end
        end
    end
end

do
    local f1, f2 = evo.id(2)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, { f1 })

    local e1 = evo.id()
    evo.set(e1, f1, 41)

    do
        assert(evo.defer())

        evo.batch_set(q, f1, 42)
        assert(evo.get(e1, f1) == 41)

        assert(evo.commit())
        assert(evo.get(e1, f1) == 42)
    end

    do
        assert(evo.defer())

        evo.batch_set(q, f2, 43)
        assert(evo.get(e1, f2) == nil)

        assert(evo.commit())
        assert(evo.get(e1, f2) == 43)
    end
end

do
    local f1, f2 = evo.id(2)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, { f1 })

    local e1 = evo.id()
    evo.set(e1, f1, 41)

    do
        assert(evo.defer())

        evo.batch_set(q, f1, 42)
        assert(evo.get(e1, f1) == 41)

        assert(evo.commit())
        assert(evo.get(e1, f1) == 42)
    end

    do
        assert(evo.defer())

        do
            evo.set(q, evo.INCLUDES, { f1, f2 })
            evo.batch_set(q, f2, 43)
        end
        assert(evo.get(e1, f2) == nil)

        assert(evo.commit())
        assert(evo.get(e1, f2) == nil)
    end
end

do
    local f1, f2 = evo.id(2)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, { f1 })

    local e1 = evo.id()
    evo.set(e1, f1, 41)

    do
        assert(evo.defer())

        do
            evo.set(q, evo.EXCLUDES, { f1 })
            evo.batch_set(q, f1, 42)
        end
        assert(evo.get(e1, f1) == 41)

        assert(evo.commit())
        assert(evo.get(e1, f1) == 41)
    end

    do
        assert(evo.defer())

        do
            evo.set(q, evo.EXCLUDES)
            evo.batch_set(q, f2, 43)
        end
        assert(evo.get(e1, f2) == nil)

        assert(evo.commit())
        assert(evo.get(e1, f2) == 43)
    end
end

do
    local f1 = evo.id(1)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, { f1 })

    local e1 = evo.id()
    evo.set(e1, f1, 41)

    do
        assert(evo.defer())

        evo.batch_remove(q, f1)
        assert(evo.get(e1, f1) == 41)

        assert(evo.commit())
        assert(evo.get(e1, f1) == nil)
    end
end

do
    local f1 = evo.id(1)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, { f1 })

    local e1 = evo.id()
    evo.set(e1, f1, 41)

    do
        assert(evo.defer())

        assert(not evo.batch_clear(q))
        assert(evo.alive(e1))
        assert(evo.get(e1, f1) == 41)

        assert(evo.commit())
        assert(evo.alive(e1))
        assert(evo.get(e1, f1) == nil)
    end
end

do
    local f1 = evo.id(1)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, { f1 })

    local e1 = evo.id()
    evo.set(e1, f1, 41)

    do
        assert(evo.defer())

        assert(not evo.batch_destroy(q))
        assert(evo.alive(e1))
        assert(evo.get(e1, f1) == 41)

        assert(evo.commit())
        assert(not evo.alive(e1))
        assert(evo.get(e1, f1) == nil)
    end
end

do
    local f1, f2 = evo.id(2)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, { f1 })
    evo.set(q, evo.INCLUDES, { f2 })

    local e1 = evo.id()
    evo.set(e1, f1, 41)

    local e2 = evo.id()
    evo.set(e2, f2, 42)

    do
        local iter, state = evo.execute(q)

        local chunk, entity_list, entity_count = iter(state)
        assert(chunk == evo.chunk(f2))
        assert(entity_list and entity_list[1] == e2)
        assert(entity_count == 1)

        chunk, entity_list, entity_count = iter(state)
        assert(not chunk)
        assert(not entity_list)
        assert(not entity_count)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, { f1 })

    local e1 = evo.id()
    evo.set(e1, f1, 41)
    evo.set(e1, f2, 42)

    local e2 = evo.id()
    evo.set(e2, f1, 43)
    evo.set(e2, f3, 44)

    do
        local entity_sum = 0

        for _, entity_list, entity_count in evo.execute(q) do
            assert(entity_count > 0)
            for _, e in ipairs(entity_list) do
                entity_sum = entity_sum + e
            end
        end

        assert(entity_sum == e1 + e2)
    end
end

do
    local f1, f2 = evo.id(2)

    local q = evo.id()
    evo.set(q, evo.INCLUDES, { f1 })

    evo.set(q, evo.EXCLUDES, { f1 })
    evo.set(q, evo.EXCLUDES, { f2 })

    local e1 = evo.id()
    evo.set(e1, f1, 41)

    local e2 = evo.id()
    evo.set(e2, f1, 43)
    evo.set(e2, f2, 44)

    do
        local iter, state = evo.execute(q)
        local chunk, entity_list, entity_count = iter(state)
        assert(chunk == evo.chunk(f1))
        assert(entity_list and entity_list[1] == e1)
        assert(entity_count == 1)

        chunk, entity_list, entity_count = iter(state)
        assert(not chunk)
        assert(not entity_list)
        assert(not entity_count)
    end

    evo.set(q, evo.EXCLUDES)

    do
        local iter, state = evo.execute(q)
        local chunk, entity_list, entity_count = iter(state)
        assert(chunk == evo.chunk(f1))
        assert(entity_list and entity_list[1] == e1)
        assert(entity_count == 1)

        chunk, entity_list, entity_count = iter(state)
        assert(chunk == evo.chunk(f1, f2))
        assert(entity_list and entity_list[1] == e2)
        assert(entity_count == 1)

        chunk, entity_list, entity_count = iter(state)
        assert(not chunk)
        assert(not entity_list)
        assert(not entity_count)
    end
end

do
    local f1, f2 = evo.id(2)

    local q = evo.id()

    local e1 = evo.id()
    evo.set(e1, f1, 41)

    local e2 = evo.id()
    evo.set(e2, f1, 43)
    evo.set(e2, f2, 44)

    do
        local e1_count = 0
        local e2_count = 0

        for _, entity_list, entity_count in evo.execute(q) do
            for i = 1, entity_count do
                if entity_list[i] == e1 then
                    e1_count = e1_count + 1
                elseif entity_list[i] == e2 then
                    e2_count = e2_count + 1
                end
            end
        end

        assert(e1_count == 1)
        assert(e2_count == 1)
    end

    evo.set(q, evo.EXCLUDES, { f2 })

    do
        local e1_count = 0
        local e2_count = 0

        for chunk, entity_list, entity_count in evo.execute(q) do
            assert(not chunk:has(f2))

            for i = 1, entity_count do
                if entity_list[i] == e1 then
                    e1_count = e1_count + 1
                elseif entity_list[i] == e2 then
                    e2_count = e2_count + 1
                end
            end
        end

        assert(e1_count == 1)
        assert(e2_count == 0)
    end

    evo.set(q, evo.INCLUDES, { f1 })

    do
        local e1_count = 0
        local e2_count = 0

        for chunk, entity_list, entity_count in evo.execute(q) do
            assert(chunk:has(f1))
            assert(not chunk:has(f2))

            for i = 1, entity_count do
                if entity_list[i] == e1 then
                    e1_count = e1_count + 1
                elseif entity_list[i] == e2 then
                    e2_count = e2_count + 1
                end
            end
        end

        assert(e1_count == 1)
        assert(e2_count == 0)
    end
end

do
    local f1, f2 = evo.id(3)

    do
        local e = evo.id()

        local iter, state = evo.each(e)
        local fragment, component = iter(state)
        assert(not fragment and not component)
    end

    do
        local e = evo.id()
        evo.set(e, f1, 41)

        local iter, state = evo.each(e)
        local fragment, component = iter(state)
        assert(fragment == f1 and component == 41)

        fragment, component = iter(state)
        assert(not fragment and not component)
    end

    do
        local e = evo.id()
        evo.set(e, f1, 41)
        evo.set(e, f2, 42)

        do
            local iter, state = evo.each(e)
            local fragment, component = iter(state)
            assert(fragment == f1 or fragment == f2)
            assert((fragment == f1 and component == 41) or (fragment == f2 and component == 42))

            fragment, component = iter(state)
            assert(fragment == f1 or fragment == f2)
            assert((fragment == f1 and component == 41) or (fragment == f2 and component == 42))

            fragment, component = iter(state)
            assert(not fragment and not component)
        end

        do
            local fragment_sum = 0
            local component_sum = 0
            for f, c in evo.each(e) do
                fragment_sum = fragment_sum + f
                component_sum = component_sum + c
            end
            assert(fragment_sum == f1 + f2)
            assert(component_sum == 41 + 42)
        end
    end

    do
        local s = evo.id()
        evo.set(s, evo.TAG)

        local e = evo.id()
        evo.set(e, f1)
        evo.set(e, s)

        do
            local iter, state = evo.each(e)
            local fragment, component = iter(state)
            assert(fragment == f1 or fragment == s)
            if fragment == f1 then
                assert(component == true)
            elseif fragment == s then
                assert(component == nil)
            end

            fragment, component = iter(state)
            assert(fragment == f1 or fragment == s)
            if fragment == f1 then
                assert(component == true)
            elseif fragment == s then
                assert(component == nil)
            end

            fragment, component = iter(state)
            assert(not fragment and not component)
        end
    end
end

do
    local f1, f2 = evo.id(2)

    do
        local e = evo.builder()
            :set(f1, 41)
            :set(f2, 42)
            :spawn()
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(evo.has(e, f2) and evo.get(e, f2) == 42)
    end

    do
        local e = evo.builder()
            :set(f1, 11)
            :set(f1, 41)
            :spawn()
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
    end
end

do
    local f1 = evo.builder():default(41):spawn()
    local f2 = evo.builder():default(42):spawn()
    local f3 = evo.builder():tag():spawn()

    local e0 = evo.builder():spawn()
    assert(not evo.has_any(e0, f1, f2, f3))

    local e1 = evo.builder():set(f1):spawn()
    assert(evo.has(e1, f1))
    assert(evo.get(e1, f1) == 41)

    local e2 = evo.builder():set(f1):set(f2):spawn()
    assert(evo.has(e2, f1) and evo.has(e2, f2))
    assert(evo.get(e2, f1) == 41 and evo.get(e2, f2) == 42)

    local e3 = evo.builder():set(f1):set(f2):set(f3):spawn()
    assert(evo.has(e3, f1) and evo.has(e3, f2) and evo.has(e3, f3))
    assert(evo.get(e3, f1) == 41 and evo.get(e3, f2) == 42 and evo.get(e3, f3) == nil)

    ---@param q evolved.query
    ---@return evolved.entity[]
    local function collect_entities(q)
        local entities = {}
        for _, es, es_count in evo.execute(q) do
            assert(#es >= es_count)
            for _, e in ipairs(es) do
                entities[#entities + 1] = e
            end
        end
        return entities
    end

    local q1 = evo.builder():include(f1):spawn()
    local q2 = evo.builder():include(f1, f2):spawn()
    local q3 = evo.builder():include(f1):include(f2):exclude(f3):spawn()

    do
        local entities = collect_entities(q1)
        assert(#entities >= 3)
        assert(entities[1] == e1)
        assert(entities[2] == e2)
        assert(entities[3] == e3)
    end

    do
        local entities = collect_entities(q2)
        assert(#entities >= 2)
        assert(entities[1] == e2)
        assert(entities[2] == e3)
    end

    do
        local entities = collect_entities(q3)
        assert(#entities >= 1)
        assert(entities[1] == e2)
    end
end

do
    local f1_assign_count = 0
    local f1_insert_count = 0
    local f2_set_count = 0
    local f2_remove_count = 0

    local FB = evo.builder()

    local f1 = FB:clear()
        :on_assign(function(e, f, nc, oc)
            f1_assign_count = f1_assign_count + 1
            assert(evo.alive(e))
            assert(evo.alive(f))
            assert(nc == 42)
            assert(oc == 41)
        end)
        :on_insert(function(e, f, nc)
            f1_insert_count = f1_insert_count + 1
            assert(evo.alive(e))
            assert(evo.alive(f))
            assert(nc == 41)
        end)
        :spawn()

    local f2 = FB:clear()
        :on_set(function(e, f, nc, oc)
            f2_set_count = f2_set_count + 1
            assert(evo.alive(e))
            assert(evo.alive(f))
            if oc then
                assert(oc == 81)
                assert(nc == 82)
            else
                assert(nc == 81)
            end
        end)
        :on_remove(function(e, f, c)
            f2_remove_count = f2_remove_count + 1
            assert(evo.get(e, f) == c)
            assert(evo.alive(f))
            assert(c == 82)
        end)
        :spawn()

    local e1 = evo.builder():set(f1, 41):spawn()
    assert(f1_assign_count == 0 and f1_insert_count == 1)

    local e2 = evo.builder():set(f1, 42):set(f1, 41):spawn()
    assert(f1_assign_count == 0 and f1_insert_count == 2)

    evo.set(e1, f1, 42)
    assert(f1_assign_count == 1 and f1_insert_count == 2)

    evo.set(e2, f1, 42)
    assert(f1_assign_count == 2 and f1_insert_count == 2)

    assert(evo.get(e1, f1) == 42 and evo.get(e2, f1) == 42)

    evo.set(e1, f2, 81)
    assert(f2_set_count == 1)
    evo.set(e1, f2, 82)
    assert(f2_set_count == 2)

    evo.set(e2, f2, 81)
    assert(f2_set_count == 3)
    evo.set(e2, f2, 82)
    assert(f2_set_count == 4)

    assert(evo.get(e1, f2) == 82 and evo.get(e2, f2) == 82)

    evo.remove(e1, f1, f1, f2, f2)
    evo.remove(e1, f1, f1, f2, f2)
    assert(f2_remove_count == 1)

    evo.destroy(e2)
    evo.destroy(e2)
    assert(f2_remove_count == 2)
end

do
    local f1, f2 = evo.id(2)
    local qb = evo.builder()

    do
        local q = qb:clear():spawn()

        local includes, excludes = evo.get(q, evo.INCLUDES, evo.EXCLUDES)
        assert(includes == nil)
        assert(excludes == nil)
    end

    do
        local q = qb:clear():include(f1):spawn()

        local includes, excludes = evo.get(q, evo.INCLUDES, evo.EXCLUDES)
        assert(#includes == 1 and includes[1] == f1)
        assert(excludes == nil)
    end

    do
        local q = qb:clear():include(f1, f2):spawn()

        local includes, excludes = evo.get(q, evo.INCLUDES, evo.EXCLUDES)
        assert(#includes == 2 and includes[1] == f1 and includes[2] == f2)
        assert(excludes == nil)
    end

    do
        local q = qb:clear():include(f1):include(f2):spawn()

        local includes, excludes = evo.get(q, evo.INCLUDES, evo.EXCLUDES)
        assert(#includes == 2 and includes[1] == f1 and includes[2] == f2)
        assert(excludes == nil)
    end

    do
        local q = qb:clear():exclude(f1):spawn()

        local includes, excludes = evo.get(q, evo.INCLUDES, evo.EXCLUDES)
        assert(includes == nil)
        assert(#excludes == 1 and excludes[1] == f1)
    end

    do
        local q = qb:clear():exclude(f1, f2):spawn()

        local includes, excludes = evo.get(q, evo.INCLUDES, evo.EXCLUDES)
        assert(includes == nil)
        assert(#excludes == 2 and excludes[1] == f1 and excludes[2] == f2)
    end

    do
        local q = qb:clear():exclude(f1):exclude(f2):spawn()

        local includes, excludes = evo.get(q, evo.INCLUDES, evo.EXCLUDES)
        assert(includes == nil)
        assert(#excludes == 2 and excludes[1] == f1 and excludes[2] == f2)
    end

    do
        qb:clear()
        qb:include(f1)
        qb:exclude(f2)

        local q = qb:spawn()

        local includes, excludes = evo.get(q, evo.INCLUDES, evo.EXCLUDES)
        assert(#includes == 1 and includes[1] == f1)
        assert(#excludes == 1 and excludes[1] == f2)
    end
end

do
    local f1, f2 = evo.id(2)
    local eb = evo.builder()

    do
        local e = eb:clear():spawn()
        assert(evo.alive(e) and evo.empty(e))
    end

    do
        local e = eb:clear():set(f1, 41):spawn()
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(not evo.has(e, f2) and evo.get(e, f2) == nil)
    end

    do
        local e = eb:clear():set(f1, 41):set(f2, 42):spawn()
        assert(evo.has(e, f1) and evo.get(e, f1) == 41)
        assert(evo.has(e, f2) and evo.get(e, f2) == 42)
    end

    do
        local e = eb:clear():spawn()
        assert(evo.alive(e) and evo.empty(e))
    end
end

do
    local f1, f2 = evo.id(2)
    local eb = evo.builder()

    local e1 = eb:clear():set(f1, 1):set(f2, 2):spawn()
    local e2 = eb:clear():set(f1, 11):spawn()

    assert(evo.has(e1, f1) and evo.get(e1, f1) == 1)
    assert(evo.has(e1, f2) and evo.get(e1, f2) == 2)

    assert(evo.has(e2, f1) and evo.get(e2, f1) == 11)
    assert(not evo.has(e2, f2) and evo.get(e2, f2) == nil)
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f3, evo.TAG)

    do
        local e = evo.spawn()
        assert(evo.alive(e) and evo.empty(e))
    end

    do
        local e = evo.spawn({})
        assert(evo.alive(e) and evo.empty(e))
    end

    do
        local e1 = evo.spawn({ [f1] = true })
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)

        local e2 = evo.spawn({ [f1] = true })
        assert(evo.has(e2, f1) and evo.get(e2, f1) == true)

        local e3 = evo.spawn({ [f1] = 41 })
        assert(evo.has(e3, f1) and evo.get(e3, f1) == 41)
    end

    do
        local e1 = evo.spawn({ [f1] = true, [f2] = true })
        assert(evo.has_all(e1, f1, f2))
        assert(evo.get(e1, f1) == true and evo.get(e1, f2) == true)

        local e2 = evo.spawn({ [f1] = true, [f2] = true })
        assert(evo.has_all(e2, f1, f2))
        assert(evo.get(e2, f1) == true and evo.get(e2, f2) == true)

        local e3 = evo.spawn({ [f1] = 41, [f2] = true })
        assert(evo.has_all(e3, f1, f2))
        assert(evo.get(e3, f1) == 41 and evo.get(e3, f2) == true)

        local e4 = evo.spawn({ [f1] = true, [f2] = 42 })
        assert(evo.has_all(e4, f1, f2))
        assert(evo.get(e4, f1) == true and evo.get(e4, f2) == 42)

        local e5 = evo.spawn({ [f1] = 41, [f2] = 42 })
        assert(evo.has_all(e5, f1, f2))
        assert(evo.get(e5, f1) == 41 and evo.get(e5, f2) == 42)
    end

    do
        local e1 = evo.spawn({ [f3] = true })
        assert(evo.has(e1, f3))
        assert(evo.get(e1, f3) == nil)

        local e2 = evo.spawn({ [f2] = true, [f3] = true })
        assert(evo.has_all(e2, f2, f3))
        assert(evo.get(e2, f2) == true and evo.get(e2, f3) == nil)

        local e3 = evo.spawn({ [f2] = 42, [f3] = true })
        assert(evo.has_all(e3, f2, f3))
        assert(evo.get(e3, f2) == 42 and evo.get(e3, f3) == nil)

        local e4 = evo.spawn({ [f2] = 42, [f3] = 43 })
        assert(evo.has_all(e4, f2, f3))
        assert(evo.get(e4, f2) == 42 and evo.get(e4, f3) == nil)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f2, evo.DEFAULT, 21)
    evo.set(f3, evo.TAG)

    do
        local e = evo.spawn()
        assert(evo.alive(e) and evo.empty(e))
    end

    do
        local e = evo.spawn({})
        assert(evo.alive(e) and evo.empty(e))
    end

    do
        local e1 = evo.spawn({ [f1] = true })
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)

        local e2 = evo.spawn({ [f1] = true })
        assert(evo.has(e2, f1) and evo.get(e2, f1) == true)

        local e3 = evo.spawn({ [f1] = 41 })
        assert(evo.has(e3, f1) and evo.get(e3, f1) == 41)
    end

    do
        local e1 = evo.spawn({ [f1] = true, [f2] = 21 })
        assert(evo.has_all(e1, f1, f2))
        assert(evo.get(e1, f1) == true and evo.get(e1, f2) == 21)

        local e2 = evo.spawn({ [f1] = true, [f2] = 21 })
        assert(evo.has_all(e2, f1, f2))
        assert(evo.get(e2, f1) == true and evo.get(e2, f2) == 21)

        local e3 = evo.spawn({ [f1] = 41, [f2] = 21 })
        assert(evo.has_all(e3, f1, f2))
        assert(evo.get(e3, f1) == 41 and evo.get(e3, f2) == 21)

        local e4 = evo.spawn({ [f1] = true, [f2] = 42 })
        assert(evo.has_all(e4, f1, f2))
        assert(evo.get(e4, f1) == true and evo.get(e4, f2) == 42)

        local e5 = evo.spawn({ [f1] = 41, [f2] = 42 })
        assert(evo.has_all(e5, f1, f2))
        assert(evo.get(e5, f1) == 41 and evo.get(e5, f2) == 42)

        local e6 = evo.spawn({ [f1] = 41, [f2] = 42 })
        assert(evo.has_all(e6, f1, f2))
        assert(evo.get(e6, f1) == 41 and evo.get(e6, f2) == 42)
    end

    do
        local e1 = evo.spawn({ [f3] = true })
        assert(evo.has(e1, f3))
        assert(evo.get(e1, f3) == nil)

        local e2 = evo.spawn({ [f2] = 21, [f3] = true })
        assert(evo.has_all(e2, f2, f3))
        assert(evo.get(e2, f2) == 21 and evo.get(e2, f3) == nil)

        local e3 = evo.spawn({ [f2] = 42, [f3] = true })
        assert(evo.has_all(e3, f2, f3))
        assert(evo.get(e3, f2) == 42 and evo.get(e3, f3) == nil)

        local e4 = evo.spawn({ [f2] = 42, [f3] = 43 })
        assert(evo.has_all(e4, f2, f3))
        assert(evo.get(e4, f2) == 42 and evo.get(e4, f3) == nil)
    end
end

do
    local cf = evo.id()
    local f1, f2, f3 = evo.id(3)

    evo.set(f1, cf)
    evo.set(f2, cf)
    evo.set(f3, cf)

    evo.set(f2, evo.DEFAULT, 21)
    evo.set(f3, evo.TAG)

    local set_count = 0
    local insert_count = 0

    local last_set_entity = 0
    local last_set_component = 0
    local last_insert_entity = 0
    local last_insert_component = 0

    local q = evo.builder():include(cf):spawn()

    evo.batch_set(q, evo.ON_SET, function(e, f, c)
        last_set_entity = e
        assert(f == f1 or f == f2 or f == f3)
        last_set_component = c
        set_count = set_count + 1
    end)

    evo.batch_set(q, evo.ON_INSERT, function(e, f, c)
        last_insert_entity = e
        assert(f == f1 or f == f2 or f == f3)
        last_insert_component = c
        insert_count = insert_count + 1
    end)

    assert(set_count == 0 and insert_count == 0)
    assert(last_set_entity == 0 and last_set_component == 0)
    assert(last_insert_entity == 0 and last_insert_component == 0)

    do
        set_count, insert_count = 0, 0
        last_set_entity, last_set_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0
        local e = evo.spawn({ [f1] = true })
        assert(set_count == 1 and insert_count == 1)
        assert(last_set_entity == e and last_set_component == true)
        assert(last_insert_entity == e and last_insert_component == true)
    end

    do
        set_count, insert_count = 0, 0
        last_set_entity, last_set_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0
        local e = evo.spawn({ [f2] = 21 })
        assert(set_count == 1 and insert_count == 1)
        assert(last_set_entity == e and last_set_component == 21)
        assert(last_insert_entity == e and last_insert_component == 21)
    end

    do
        set_count, insert_count = 0, 0
        last_set_entity, last_set_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0
        local e = evo.spawn({ [f2] = 21, [f1] = true })
        assert(set_count == 2 and insert_count == 2)
        assert(last_set_entity == e and last_set_component == 21)
        assert(last_insert_entity == e and last_insert_component == 21)
    end

    do
        set_count, insert_count = 0, 0
        last_set_entity, last_set_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0
        local e = evo.spawn({ [f3] = true })
        assert(set_count == 1 and insert_count == 1)
        assert(last_set_entity == e and last_set_component == nil)
        assert(last_insert_entity == e and last_insert_component == nil)
    end

    do
        set_count, insert_count = 0, 0
        last_set_entity, last_set_component = 0, 0
        last_insert_entity, last_insert_component = 0, 0
        local e = evo.spawn({ [f3] = 33, [f2] = 22 })
        assert(set_count == 2 and insert_count == 2)
        assert(last_set_entity == e and last_set_component == nil)
        assert(last_insert_entity == e and last_insert_component == nil)
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)

    evo.set(f3, evo.DEFAULT, 3)
    evo.set(f4, evo.TAG)

    do
        assert(evo.defer())
        local e = evo.spawn()
        assert(evo.alive(e) and evo.empty(e))
        assert(evo.commit())
        assert(evo.alive(e) and evo.empty(e))
    end

    do
        assert(evo.defer())
        local e = evo.spawn({})
        assert(evo.alive(e) and evo.empty(e))
        assert(evo.commit())
        assert(evo.alive(e) and evo.empty(e))
    end

    do
        assert(evo.defer())
        local e1 = evo.spawn({ [f1] = true })
        assert(evo.alive(e1) and evo.empty(e1))
        assert(evo.commit())
        assert(evo.alive(e1) and not evo.empty(e1))
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)

        assert(evo.defer())
        local e2 = evo.spawn({ [f1] = true })
        assert(evo.alive(e2) and evo.empty(e2))
        assert(evo.commit())
        assert(evo.alive(e2) and not evo.empty(e2))
        assert(evo.has(e2, f1) and evo.get(e2, f1) == true)

        assert(evo.defer())
        local e3 = evo.spawn({ [f1] = 41 })
        assert(evo.alive(e3) and evo.empty(e3))
        assert(evo.commit())
        assert(evo.alive(e3) and not evo.empty(e3))
        assert(evo.has(e3, f1) and evo.get(e3, f1) == 41)
    end

    do
        assert(evo.defer())
        local e1 = evo.spawn({ [f1] = true, [f2] = true })
        assert(evo.alive(e1) and evo.empty(e1))
        assert(evo.commit())
        assert(evo.alive(e1) and not evo.empty(e1))
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == true)

        assert(evo.defer())
        local e2 = evo.spawn({ [f1] = true, [f2] = true })
        assert(evo.alive(e2) and evo.empty(e2))
        assert(evo.commit())
        assert(evo.alive(e2) and not evo.empty(e2))
        assert(evo.has(e2, f1) and evo.get(e2, f1) == true)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == true)

        assert(evo.defer())
        local e3 = evo.spawn({ [f1] = 41, [f2] = true })
        assert(evo.alive(e3) and evo.empty(e3))
        assert(evo.commit())
        assert(evo.alive(e3) and not evo.empty(e3))
        assert(evo.has(e3, f1) and evo.get(e3, f1) == 41)
        assert(evo.has(e3, f2) and evo.get(e3, f2) == true)

        assert(evo.defer())
        local e4 = evo.spawn({ [f1] = true, [f2] = 42 })
        assert(evo.alive(e4) and evo.empty(e4))
        assert(evo.commit())
        assert(evo.alive(e4) and not evo.empty(e4))
        assert(evo.has(e4, f1) and evo.get(e4, f1) == true)
        assert(evo.has(e4, f2) and evo.get(e4, f2) == 42)

        assert(evo.defer())
        local e5 = evo.spawn({ [f1] = 41, [f2] = 42 })
        assert(evo.alive(e5) and evo.empty(e5))
        assert(evo.commit())
        assert(evo.alive(e5) and not evo.empty(e5))
        assert(evo.has(e5, f1) and evo.get(e5, f1) == 41)
        assert(evo.has(e5, f2) and evo.get(e5, f2) == 42)

        assert(evo.defer())
        local e6 = evo.spawn({ [f1] = 41, [f2] = 42 })
        assert(evo.alive(e6) and evo.empty(e6))
        assert(evo.commit())
        assert(evo.alive(e6) and not evo.empty(e6))
        assert(evo.has(e6, f1) and evo.get(e6, f1) == 41)
        assert(evo.has(e6, f2) and evo.get(e6, f2) == 42)
    end

    do
        assert(evo.defer())
        local e1 = evo.spawn({ [f3] = 3, [f4] = true })
        assert(evo.alive(e1) and evo.empty(e1))
        assert(evo.commit())
        assert(evo.alive(e1) and not evo.empty(e1))
        assert(evo.has(e1, f3) and evo.get(e1, f3) == 3)
        assert(evo.has(e1, f4) and evo.get(e1, f4) == nil)

        assert(evo.defer())
        local e2 = evo.spawn({ [f3] = 33, [f4] = 44 })
        assert(evo.alive(e2) and evo.empty(e2))
        assert(evo.commit())
        assert(evo.alive(e2) and not evo.empty(e2))
        assert(evo.has(e2, f3) and evo.get(e2, f3) == 33)
        assert(evo.has(e2, f4) and evo.get(e2, f4) == nil)
    end
end

do
    local f1, f2, f3, f4, f5 = evo.id(5)
    local e = evo.builder():set(f1, 11):set(f2, 22):set(f3, 33):set(f4, 44):set(f5, 55):spawn()

    do
        local c1 = evo.get(e, f1)
        assert(c1 == 11)
    end
    do
        local c1, c2 = evo.get(e, f1, f2)
        assert(c1 == 11 and c2 == 22)
    end
    do
        local c2, c1 = evo.get(e, f2, f1)
        assert(c1 == 11 and c2 == 22)
    end
    do
        local c1, c2, c3 = evo.get(e, f1, f2, f3)
        assert(c1 == 11 and c2 == 22 and c3 == 33)
    end
    do
        local c3, c2, c1 = evo.get(e, f3, f2, f1)
        assert(c1 == 11 and c2 == 22 and c3 == 33)
    end
    do
        local c1, c2, c3, c4 = evo.get(e, f1, f2, f3, f4)
        assert(c1 == 11 and c2 == 22 and c3 == 33 and c4 == 44)
    end
    do
        local c1, c2, c3, c4, c5 = evo.get(e, f1, f2, f3, f4, f5)
        assert(c1 == 11 and c2 == 22 and c3 == 33 and c4 == 44 and c5 == 55)
    end
    do
        local c5, c4, c3, c2, c1 = evo.get(e, f5, f4, f3, f2, f1)
        assert(c1 == 11 and c2 == 22 and c3 == 33 and c4 == 44 and c5 == 55)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f2, evo.DEFAULT, 42)

    local e1a = evo.builder():set(f1, 11):spawn()
    local e1b = evo.builder():set(f1, 11):spawn()

    local e2a = evo.builder():set(f1, 11):set(f2, 22):spawn()
    local e2b = evo.builder():set(f1, 11):set(f2, 22):spawn()

    local q = evo.builder():include(f1):spawn()

    evo.set(q, evo.EXCLUDES, { f2 })
    evo.batch_set(q, f2)
    assert(evo.get(e1a, f1) == 11 and evo.get(e1a, f2) == 42)
    assert(evo.get(e1b, f1) == 11 and evo.get(e1b, f2) == 42)
    assert(evo.get(e2a, f1) == 11 and evo.get(e2a, f2) == 22)
    assert(evo.get(e2b, f1) == 11 and evo.get(e2b, f2) == 22)

    evo.set(q, evo.EXCLUDES)
    evo.batch_set(q, f2)
    assert(evo.get(e1a, f1) == 11 and evo.get(e1a, f2) == 42)
    assert(evo.get(e1b, f1) == 11 and evo.get(e1b, f2) == 42)
    assert(evo.get(e2a, f1) == 11 and evo.get(e2a, f2) == 42)
    assert(evo.get(e2b, f1) == 11 and evo.get(e2b, f2) == 42)

    evo.batch_set(q, f1)
    assert(evo.get(e1a, f1) == true and evo.get(e1a, f2) == 42)
    assert(evo.get(e1b, f1) == true and evo.get(e1b, f2) == 42)
    assert(evo.get(e2a, f1) == true and evo.get(e2a, f2) == 42)
    assert(evo.get(e2b, f1) == true and evo.get(e2b, f2) == 42)

    evo.batch_set(q, f3)
    assert(evo.get(e1a, f1) == true and evo.get(e1a, f2) == 42 and evo.get(e1a, f3) == true)
    assert(evo.get(e1b, f1) == true and evo.get(e1b, f2) == 42 and evo.get(e1b, f3) == true)
    assert(evo.get(e2a, f1) == true and evo.get(e2a, f2) == 42 and evo.get(e2a, f3) == true)
    assert(evo.get(e2b, f1) == true and evo.get(e2b, f2) == 42 and evo.get(e2b, f3) == true)
end

do
    local fc = evo.id()
    local f1, f2, f3, f4 = evo.id(4)

    evo.set(f2, evo.DEFAULT, 42)
    evo.set(f3, evo.TAG)

    evo.set(f1, fc)
    evo.set(f2, fc)
    evo.set(f3, fc)
    evo.set(f4, fc)

    local sum_entity = 0
    local last_assign_entity = 0
    local last_assign_component = 0
    local last_insert_entity = 0
    local last_insert_component = 0

    do
        local q = evo.builder():include(fc):spawn()
        evo.batch_set(q, evo.ON_ASSIGN, function(e, f, c)
            assert(f == f1 or f == f2 or f == f3 or f == f4)
            sum_entity = sum_entity + e
            last_assign_entity = e
            last_assign_component = c
        end)
        evo.batch_set(q, evo.ON_INSERT, function(e, f, c)
            assert(f == f1 or f == f2 or f == f3 or f == f4)
            sum_entity = sum_entity + e
            last_insert_entity = e
            last_insert_component = c
        end)
    end

    local e1a = evo.builder():set(f1, 11):spawn()
    local e1b = evo.builder():set(f1, 11):spawn()

    local e2a = evo.builder():set(f1, 11):set(f2, 22):spawn()
    local e2b = evo.builder():set(f1, 11):set(f2, 22):spawn()

    do
        local q = evo.builder():include(f1):exclude(f2):spawn()

        sum_entity = 0
        last_insert_entity = 0
        last_insert_component = 0

        evo.batch_set(q, f2)
        assert(evo.get(e1a, f1) == 11 and evo.get(e1a, f2) == 42)
        assert(evo.get(e1b, f1) == 11 and evo.get(e1b, f2) == 42)
        assert(evo.get(e2a, f1) == 11 and evo.get(e2a, f2) == 22)
        assert(evo.get(e2b, f1) == 11 and evo.get(e2b, f2) == 22)

        assert(sum_entity == e1a + e1b)
        assert(last_insert_entity == e1b)
        assert(last_insert_component == 42)
    end

    do
        local q = evo.builder():include(f2):spawn()

        sum_entity = 0
        last_insert_entity = 0
        last_insert_component = 0

        evo.batch_set(q, f3)
        assert(evo.has_all(e1a, f1, f2, f3) and evo.has_all(e1b, f1, f2, f3))
        assert(evo.has_all(e2a, f1, f2, f3) and evo.has_all(e2b, f1, f2, f3))
        assert(evo.get(e1a, f1) == 11 and evo.get(e1a, f2) == 42 and evo.get(e1a, f3) == nil)
        assert(evo.get(e1b, f1) == 11 and evo.get(e1b, f2) == 42 and evo.get(e1b, f3) == nil)
        assert(evo.get(e2a, f1) == 11 and evo.get(e2a, f2) == 22 and evo.get(e2a, f3) == nil)
        assert(evo.get(e2b, f1) == 11 and evo.get(e2b, f2) == 22 and evo.get(e2b, f3) == nil)
    end

    do
        local q = evo.builder():include(f2):spawn()

        sum_entity = 0
        last_insert_entity = 0
        last_insert_component = 0

        evo.batch_set(q, f4)
        assert(evo.has_all(e1a, f1, f2, f3, f4) and evo.has_all(e1b, f1, f2, f3, f4))
        assert(evo.has_all(e2a, f1, f2, f3, f4) and evo.has_all(e2b, f1, f2, f3, f4))
        assert(evo.get(e1a, f1) == 11 and evo.get(e1a, f2) == 42 and evo.get(e1a, f3) == nil and evo.get(e1a, f4) == true)
        assert(evo.get(e1b, f1) == 11 and evo.get(e1b, f2) == 42 and evo.get(e1b, f3) == nil and evo.get(e1b, f4) == true)
        assert(evo.get(e2a, f1) == 11 and evo.get(e2a, f2) == 22 and evo.get(e2a, f3) == nil and evo.get(e2a, f4) == true)
        assert(evo.get(e2b, f1) == 11 and evo.get(e2b, f2) == 22 and evo.get(e2b, f3) == nil and evo.get(e2b, f4) == true)
    end

    do
        local q = evo.builder():include(f3):spawn()

        sum_entity = 0
        last_assign_entity = 0
        last_assign_component = 0

        evo.batch_set(q, f2)
        assert(sum_entity == e1a + e1b + e2a + e2b)
        assert(last_assign_entity == e1b)
        assert(last_assign_component == 42)

        sum_entity = 0
        last_assign_entity = 0
        last_assign_component = 0

        evo.batch_set(q, f1)
        assert(sum_entity == e1a + e1b + e2a + e2b)
        assert(last_assign_entity == e1b)
        assert(last_assign_component == true)
    end
end

do
    local id = evo.pack(7, 3)
    local index, version = evo.unpack(id)
    assert(index == 7 and version == 3)
end

do
    local id = evo.pack(0xBCDEF, 0xFEDCB)
    local index, version = evo.unpack(id)
    assert(index == 0xBCDEF and version == 0xFEDCB)
end

do
    local id = evo.pack(0xFFFFF, 0xFFFFF)
    local index, version = evo.unpack(id)
    assert(index == 0xFFFFF and version == 0xFFFFF)
end

do
    local f1 = evo.id(2)

    local e = evo.id()
    evo.clear(e)
    evo.clear(e)
    evo.set(e, f1, 11)
    evo.clear(e)
    evo.clear(e)
    evo.destroy(e)
    evo.destroy(e)
    evo.clear(e)
end

do
    local f1, f2, f3, f4, f5 = evo.id(5)
    local e = evo.spawn({ [f1] = 1, [f2] = 2, [f3] = 3, [f4] = 4, [f5] = 5 })

    local c, es = evo.chunk(f1, f2, f3, f4, f5)
    assert(c and es and #es >= 1 and es[1] == e)

    do
        local c1, c2 = c:components(f1, f2)
        assert(c1 and #c1 >= 1 and c1[1] == 1)
        assert(c2 and #c2 >= 1 and c2[1] == 2)
    end

    do
        local c1, c2, c3 = c:components(f1, f2, f3)
        assert(c1 and #c1 >= 1 and c1[1] == 1)
        assert(c2 and #c2 >= 1 and c2[1] == 2)
        assert(c3 and #c3 >= 1 and c3[1] == 3)
    end

    do
        local c1, c2, c3, c4 = c:components(f1, f2, f3, f4)
        assert(c1 and #c1 >= 1 and c1[1] == 1)
        assert(c2 and #c2 >= 1 and c2[1] == 2)
        assert(c3 and #c3 >= 1 and c3[1] == 3)
        assert(c4 and #c4 >= 1 and c4[1] == 4)
    end

    do
        local c1, c2, c3, c4, c5 = c:components(f1, f2, f3, f4, f5)
        assert(c1 and #c1 >= 1 and c1[1] == 1)
        assert(c2 and #c2 >= 1 and c2[1] == 2)
        assert(c3 and #c3 >= 1 and c3[1] == 3)
        assert(c4 and #c4 >= 1 and c4[1] == 4)
        assert(c5 and #c5 >= 1 and c5[1] == 5)
    end
end

do
    local f1, f2 = evo.id(2)

    local assign_count = 0
    local insert_count = 0
    local remove_count = 0

    do
        evo.set(f1, evo.ON_ASSIGN, function(e, f, c)
            assign_count = assign_count + 1
            assert(f == f1)
            assert(evo.get(e, f1) == c)

            do
                evo.set(e, f2, c)
            end
        end)

        evo.set(f1, evo.ON_INSERT, function(e, f, c)
            insert_count = insert_count + 1
            assert(f == f1)
            assert(evo.get(e, f1) == c)

            do
                evo.set(e, f2, c)
            end
        end)

        evo.set(f1, evo.ON_REMOVE, function(e, f, c)
            remove_count = remove_count + 1
            assert(f == f1)
            assert(c == 51)
            assert(evo.get(e, f1) == c)

            do
                evo.remove(e, f2)
            end
        end)
    end

    do
        evo.set(f2, evo.ON_ASSIGN, function(e, f, c)
            assign_count = assign_count + 1
            assert(f == f2)
            assert(evo.get(e, f1) == c)
            assert(evo.get(e, f2) == c)
        end)

        evo.set(f2, evo.ON_INSERT, function(e, f, c)
            insert_count = insert_count + 1
            assert(f == f2)
            assert(evo.get(e, f1) == c)
            assert(evo.get(e, f2) == c)
        end)

        evo.set(f2, evo.ON_REMOVE, function(e, f, c)
            remove_count = remove_count + 1
            assert(f == f2)
            assert(c == 51)
            assert(evo.get(e, f2) == c)
        end)
    end

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        local e = evo.id()

        evo.set(e, f1, 41)
        assert(evo.get(e, f1) == 41)
        assert(evo.get(e, f2) == 41)
        assert(assign_count == 0 and insert_count == 2 and remove_count == 0)

        evo.set(e, f1, 51)
        assert(evo.get(e, f1) == 51)
        assert(evo.get(e, f2) == 51)
        assert(assign_count == 2 and insert_count == 2 and remove_count == 0)

        evo.remove(e, f1)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
        assert(assign_count == 2 and insert_count == 2 and remove_count == 2)
    end

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        local e = evo.id()

        evo.set(e, f1, 41)
        assert(evo.get(e, f1) == 41)
        assert(evo.get(e, f2) == 41)
        assert(assign_count == 0 and insert_count == 2 and remove_count == 0)

        evo.set(e, f1, 51)
        assert(evo.get(e, f1) == 51)
        assert(evo.get(e, f2) == 51)
        assert(assign_count == 2 and insert_count == 2 and remove_count == 0)

        evo.remove(e, f1)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
        assert(assign_count == 2 and insert_count == 2 and remove_count == 2)
    end

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        local e = evo.id()

        evo.set(e, f1, 51)
        assert(evo.get(e, f1) == 51)
        assert(evo.get(e, f2) == 51)
        assert(assign_count == 0 and insert_count == 2 and remove_count == 0)

        evo.clear(e)
        assert(assign_count == 0 and insert_count == 2 and remove_count == 2)
    end

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        local e = evo.id()

        evo.set(e, f1, 51)
        assert(evo.get(e, f1) == 51)
        assert(evo.get(e, f2) == 51)
        assert(assign_count == 0 and insert_count == 2 and remove_count == 0)

        evo.destroy(e)
        assert(assign_count == 0 and insert_count == 2 and remove_count == 2)
    end
end

do
    local f1, f2 = evo.id(2)

    local assign_count = 0
    local insert_count = 0
    local remove_count = 0

    evo.set(f1, evo.ON_ASSIGN, function(e, f, c)
        assign_count = assign_count + 1
        assert(f == f1)
        assert(c == 51)
        assert(evo.get(e, f1) == 51)
        assert(evo.get(e, f2) == 52)
    end)

    evo.set(f2, evo.ON_ASSIGN, function(e, f, c)
        assign_count = assign_count + 1
        assert(f == f2)
        assert(c == 52)
        assert(evo.get(e, f1) == 51)
        assert(evo.get(e, f2) == 52)
    end)

    evo.set(f1, evo.ON_INSERT, function(e, f, c)
        insert_count = insert_count + 1
        assert(f == f1)
        assert(c == 41)
        assert(evo.get(e, f1) == 41)
        assert(evo.get(e, f2) == 42)
    end)

    evo.set(f2, evo.ON_INSERT, function(e, f, c)
        insert_count = insert_count + 1
        assert(f == f2)
        assert(c == 42)
        assert(evo.get(e, f1) == 41)
        assert(evo.get(e, f2) == 42)
    end)

    evo.set(f1, evo.ON_REMOVE, function(e, f, c)
        remove_count = remove_count + 1
        assert(f == f1)
        assert(c == 51)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
    end)

    evo.set(f2, evo.ON_REMOVE, function(e, f, c)
        remove_count = remove_count + 1
        assert(f == f2)
        assert(c == 52)
        assert(evo.get(e, f1) == nil)
        assert(evo.get(e, f2) == nil)
    end)
end

do
    local f0, f1 = evo.id(2)
    local q0 = evo.builder():include(f0):spawn()

    local assign_count = 0
    local insert_count = 0
    local remove_count = 0

    local e1, e2 = evo.id(2)

    evo.set(f1, evo.ON_ASSIGN, function(e, f, c)
        assign_count = assign_count + 1
        assert(e == e1 or e == e2)
        assert(f == f1)
        assert(evo.get(e1, f1) == c)
        assert(evo.get(e2, f1) == c)
    end)

    evo.set(f1, evo.ON_INSERT, function(e, f, c)
        insert_count = insert_count + 1
        assert(e == e1 or e == e2)
        assert(f == f1)
        assert(evo.get(e1, f1) == c)
        assert(evo.get(e2, f1) == c)
    end)

    evo.set(f1, evo.ON_REMOVE, function(e, f, c)
        remove_count = remove_count + 1
        assert(e == e1 or e == e2)
        assert(f == f1)
        assert(c == 51)
        assert(evo.get(e, f) == c)
    end)

    do
        assign_count = 0
        insert_count = 0
        remove_count = 0

        evo.set(e1, f0)
        evo.set(e2, f0)

        evo.batch_set(q0, f1, 41)
        assert(assign_count == 0 and insert_count == 2 and remove_count == 0)

        evo.batch_set(q0, f1, 51)
        assert(assign_count == 2 and insert_count == 2 and remove_count == 0)

        evo.batch_remove(q0, f1)
        assert(assign_count == 2 and insert_count == 2 and remove_count == 2)

        evo.batch_set(q0, f1, 51)
        assert(assign_count == 2 and insert_count == 4 and remove_count == 2)

        evo.batch_clear(q0)
        assert(assign_count == 2 and insert_count == 4 and remove_count == 4)

        evo.set(e1, f0)
        evo.set(e2, f0)
        evo.batch_set(q0, f1, 51)
        assert(assign_count == 2 and insert_count == 6 and remove_count == 4)

        evo.batch_destroy(q0)
        assert(assign_count == 2 and insert_count == 6 and remove_count == 6)
    end
end

do
    local f1, f2, f3, f4, f5 = evo.id(5)

    local assign_count = 0

    evo.set(f4, evo.ON_ASSIGN, function()
        assign_count = assign_count + 1
    end)

    local e1 = evo.id()
    evo.set(e1, f1, 41)

    local e12 = evo.id()
    evo.set(e12, f1, 41)
    evo.set(e12, f2, 42)

    local e35 = evo.id()
    evo.set(e35, f3, 43)
    evo.set(e35, f5, 45)

    local e34 = evo.id()
    evo.set(e34, f3, 43)
    evo.set(e34, f4, 44)

    evo.set(f1, evo.ON_ASSIGN, function()
        assign_count = assign_count + 1
    end)

    evo.set(f3, evo.ON_ASSIGN, function()
        assign_count = assign_count + 1
    end)

    assert(assign_count == 0)

    evo.set(e1, f1, 41)
    assert(assign_count == 1)

    evo.set(e12, f1, 42)
    assert(assign_count == 2)

    evo.set(e34, f3, 43)
    assert(assign_count == 3)

    evo.set(e35, f3, 43)
    assert(assign_count == 4)
end

do
    local f1, f2, f3 = evo.id(3)
    local set_count = 0

    evo.set(f1, evo.ON_SET, function() set_count = set_count + 1 end)
    evo.set(f2, evo.ON_SET, function() set_count = set_count + 1 end)
    evo.set(f3, evo.ON_SET, function() set_count = set_count + 1 end)

    local e13 = evo.id()
    evo.set(e13, f1, 41)
    evo.set(e13, f3, 43)
    assert(set_count == 2)

    local e123 = evo.id()
    evo.set(e123, f1, 41)
    evo.set(e123, f2, 42)
    evo.set(e123, f3, 43)
    assert(set_count == 5)

    evo.set(e123, f1, 41)
    evo.set(e123, f2, 42)
    evo.set(e123, f3, 43)
    assert(set_count == 8)

    do
        set_count = 0

        evo.remove(f1, evo.ON_SET)

        evo.set(e13, f1, 41)
        assert(set_count == 0)
        evo.set(e13, f3, 43)
        assert(set_count == 1)

        evo.set(e123, f1, 41)
        assert(set_count == 1)
        evo.set(e123, f2, 42)
        assert(set_count == 2)
        evo.set(e123, f3, 43)
        assert(set_count == 3)
    end

    do
        set_count = 0

        evo.remove(f2, evo.ON_SET)

        evo.set(e13, f1, 41)
        assert(set_count == 0)
        evo.set(e13, f3, 43)
        assert(set_count == 1)

        evo.set(e123, f1, 41)
        assert(set_count == 1)
        evo.set(e123, f2, 42)
        assert(set_count == 1)
        evo.set(e123, f3, 43)
        assert(set_count == 2)
    end
end

do
    local f1, f2 = evo.id(2)

    local e1 = evo.id()
    evo.set(e1, f1, 41)
    evo.set(e1, f2, 42)

    evo.set(f1, evo.DEFAULT, 51)
    evo.set(f2, evo.DEFAULT, 52)

    evo.set(e1, f1)
    evo.set(e1, f2)

    assert(evo.get(e1, f1) == 51)
    assert(evo.get(e1, f2) == 52)
end

do
    local f1, f2 = evo.id(2)

    local e1 = evo.id()
    evo.set(e1, f1, 41)

    local e2 = evo.id()
    evo.set(e2, f1, 41)
    evo.set(e2, f2, 42)

    assert(evo.get(e1, f1) == 41)
    assert(evo.get(e2, f1) == 41)
    assert(evo.get(e2, f2) == 42)

    evo.set(f1, evo.TAG)
    assert(evo.get(e1, f1) == nil)
    assert(evo.get(e2, f1) == nil)
    assert(evo.get(e2, f2) == 42)

    evo.remove(f1, evo.TAG)
    assert(evo.get(e1, f1) == true)
    assert(evo.get(e2, f1) == true)
    assert(evo.get(e2, f2) == 42)

    evo.set(f2, evo.TAG)
    assert(evo.get(e1, f1) == true)
    assert(evo.get(e2, f1) == true)
    assert(evo.get(e2, f2) == nil)

    evo.set(f2, evo.DEFAULT, 42)
    evo.remove(f2, evo.TAG)
    assert(evo.get(e1, f1) == true)
    assert(evo.get(e2, f1) == true)
    assert(evo.get(e2, f2) == 42)

    evo.set(f1, evo.DEFAULT, 81)
    evo.set(f2, evo.DEFAULT, 82)
    assert(evo.get(e1, f1) == true)
    assert(evo.get(e2, f1) == true)
    assert(evo.get(e2, f2) == 42)
end

do
    local f1, f2 = evo.id(2)

    local q1 = evo.builder():include(f1):spawn()

    local e1a = evo.builder():set(f1, 1):spawn()
    local e1b = evo.builder():set(f1, 11):spawn()

    do
        local c1, c1_es = evo.chunk(f1)
        assert(c1 and c1_es and #c1_es >= 2)
        assert(c1_es[1] == e1a and c1_es[2] == e1b)
        assert(c1:components(f1)[1] == 1 and c1:components(f1)[2] == 11)
    end

    evo.batch_set(q1, f2, 2)

    do
        local c1, c1_es = evo.chunk(f1)
        assert(c1 and c1_es and #c1_es >= 0)

        local c12, c12_es = evo.chunk(f1, f2)
        assert(c12 and c12_es and #c12_es >= 2)
        assert(c12_es[1] == e1a and c12_es[2] == e1b)
        assert(c12:components(f1)[1] == 1 and c12:components(f1)[2] == 11)
        assert(c12:components(f2)[1] == 2 and c12:components(f2)[2] == 2)
    end

    local e1c = evo.builder():set(f1, 111):spawn()
    local e1d = evo.builder():set(f1, 1111):spawn()

    do
        local c1, c1_es = evo.chunk(f1)
        assert(c1 and c1_es and #c1_es >= 2)
        assert(c1_es[1] == e1c and c1_es[2] == e1d)
        assert(c1:components(f1)[1] == 111 and c1:components(f1)[2] == 1111)
    end

    evo.set(q1, evo.EXCLUDES, { f2 })
    evo.batch_set(q1, f2, 22)

    do
        local c1, c1_es = evo.chunk(f1)
        assert(c1 and c1_es and #c1_es >= 0)

        local c12, c12_es = evo.chunk(f1, f2)
        assert(c12 and c12_es and #c12_es >= 4)
        assert(c12_es[1] == e1a and c12_es[2] == e1b)
        assert(c12_es[3] == e1c and c12_es[4] == e1d)
        assert(c12:components(f1)[1] == 1 and c12:components(f1)[2] == 11)
        assert(c12:components(f1)[3] == 111 and c12:components(f1)[4] == 1111)
        assert(c12:components(f2)[1] == 2 and c12:components(f2)[2] == 2)
        assert(c12:components(f2)[3] == 22 and c12:components(f2)[4] == 22)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    local q1 = evo.builder():include(f1):spawn()

    local e123a = evo.builder():set(f1, 1):set(f2, 2):set(f3, 3):spawn()
    local e123b = evo.builder():set(f1, 11):set(f2, 22):set(f3, 33):spawn()

    do
        local c123, c123_es = evo.chunk(f1, f2, f3)
        assert(c123 and c123_es and #c123_es >= 2)
        assert(c123_es[1] == e123a and c123_es[2] == e123b)
        assert(c123:components(f1)[1] == 1 and c123:components(f1)[2] == 11)
        assert(c123:components(f2)[1] == 2 and c123:components(f2)[2] == 22)
        assert(c123:components(f3)[1] == 3 and c123:components(f3)[2] == 33)
    end

    evo.batch_remove(q1, f2)

    do
        local c13, c13_es = evo.chunk(f3, f1)
        assert(c13 and c13_es and #c13_es >= 2)
        assert(c13_es[1] == e123a and c13_es[2] == e123b)
        assert(c13:components(f1)[1] == 1 and c13:components(f1)[2] == 11)
        assert(c13:components(f2)[1] == nil and c13:components(f2)[2] == nil)
        assert(c13:components(f3)[1] == 3 and c13:components(f3)[2] == 33)
    end

    local e3a = evo.builder():set(f3, 3):spawn()
    local e3b = evo.builder():set(f3, 33):spawn()

    do
        local c3, c3_es = evo.chunk(f3)
        assert(c3 and c3_es and #c3_es >= 2)
        assert(c3_es[1] == e3a and c3_es[2] == e3b)
        assert(c3:components(f3)[1] == 3 and c3:components(f3)[2] == 33)
    end

    evo.batch_remove(q1, f1)

    do
        local c3, c3_es = evo.chunk(f3)
        assert(c3 and c3_es and #c3_es >= 4)
        assert(c3_es[1] == e3a and c3_es[2] == e3b)
        assert(c3_es[3] == e123a and c3_es[4] == e123b)
        assert(c3:components(f1)[1] == nil and c3:components(f1)[2] == nil)
        assert(c3:components(f1)[3] == nil and c3:components(f1)[4] == nil)
        assert(c3:components(f2)[1] == nil and c3:components(f2)[2] == nil)
        assert(c3:components(f2)[3] == nil and c3:components(f2)[4] == nil)
        assert(c3:components(f3)[1] == 3 and c3:components(f3)[2] == 33)
        assert(c3:components(f3)[3] == 3 and c3:components(f3)[4] == 33)
    end
end

do
    local f1, f2 = evo.id(2)

    local e1a = evo.builder():set(f1, 1):spawn()
    local e1b = evo.builder():set(f1, 2):spawn()

    local e12 = evo.builder():set(f1, 3):set(f2, 4):spawn()

    do
        local c1, c1_es, c1_ec = evo.chunk(f1)
        assert(c1 and c1_es and c1_ec)
        assert(c1_ec == 2 and #c1_es >= 2 and c1_es[1] == e1a and c1_es[2] == e1b)
    end

    do
        local c12, c12_es, c12_ec = evo.chunk(f1, f2)
        assert(c12 and c12_es and c12_ec)
        assert(c12_ec == 1 and #c12_es >= 1 and c12_es[1] == e12)
    end
end

do
    local f = evo.builder():spawn()
    assert(evo.get(f, evo.NAME) == nil)

    local q = evo.builder():spawn()
    assert(evo.get(q, evo.NAME) == nil)

    local s = evo.builder():spawn()
    assert(evo.get(s, evo.NAME) == nil)
end

do
    local fb = evo.builder()
    local qb = evo.builder()
    local sb = evo.builder()

    do
        local f = fb:name('fragment'):spawn()
        assert(evo.get(f, evo.NAME) == 'fragment')

        local q = qb:name('query'):spawn()
        assert(evo.get(q, evo.NAME) == 'query')

        local s = sb:name('system'):spawn()
        assert(evo.get(s, evo.NAME) == 'system')
    end

    do
        local f = fb:clear():spawn()
        assert(evo.get(f, evo.NAME) == nil)

        local q = qb:clear():spawn()
        assert(evo.get(q, evo.NAME) == nil)

        local s = sb:clear():spawn()
        assert(evo.get(s, evo.NAME) == nil)
    end
end

do
    local f1, f2 = evo.id(2)

    local c1 = assert(evo.chunk(f1))
    local c2 = assert(evo.chunk(f2))
    local c12 = assert(evo.chunk(f1, f2))

    local e1a = evo.builder():set(f1, 1):spawn()
    local e1b = evo.builder():set(f1, 2):spawn()

    local e12a = evo.builder():set(f1, 3):set(f2, 4):spawn()
    local e12b = evo.builder():set(f1, 5):set(f2, 6):spawn()

    do
        local c1_es, c1_ec = c1:entities()
        assert(c1_es and #c1_es >= 2 and c1_ec == 2)
        assert(c1_es[1] == e1a and c1_es[2] == e1b)

        local c2_es, c2_ec = c2:entities()
        assert(c2_es and #c2_es >= 0 and c2_ec == 0)

        local c12_es, c12_ec = c12:entities()
        assert(c12_es and #c12_es >= 2 and c12_ec == 2)
        assert(c12_es[1] == e12a and c12_es[2] == e12b)
    end

    evo.remove(e12a, f1)
    evo.remove(e12b, f1)
    evo.set(e1a, f2, 7)
    evo.set(e1b, f2, 8)

    do
        local c1_es, c1_ec = c1:entities()
        assert(c1_es and #c1_es >= 0 and c1_ec == 0)

        local c2_es, c2_ec = c2:entities()
        assert(c2_es and #c2_es >= 2 and c2_ec == 2)
        assert(c2_es[1] == e12a and c2_es[2] == e12b)

        local c12_es, c12_ec = c12:entities()
        assert(c12_es and #c12_es >= 2 and c12_ec == 2)
        assert(c12_es[1] == e1a and c12_es[2] == e1b)
    end
end

do
    local f1, f2 = evo.id(2)
    local c1 = assert(evo.chunk(f1))
    evo.set(f2, f1)
    evo.destroy(f1)
    do
        assert(not evo.alive(f1))
        assert(evo.alive(f2))
        assert(evo.empty(f2))

        local c1_es, c1_ec = c1:entities()
        assert(c1_es and #c1_es >= 0 and c1_ec == 0)
    end
end

do
    local f1 = evo.id()
    local c1 = assert(evo.chunk(f1))
    evo.set(f1, f1)
    evo.destroy(f1)
    do
        local c1_es, c1_ec = c1:entities()
        assert(c1_es and #c1_es >= 0 and c1_ec == 0)
    end
end

do
    local f1, f2 = evo.id(2)
    local c1 = assert(evo.chunk(f1))
    local c2 = assert(evo.chunk(f2))
    local c12 = assert(evo.chunk(f1, f2))
    evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)
    evo.set(f1, f1)
    evo.set(f2, f1)
    evo.set(f2, f2)
    do
        local c1_es, c1_ec = c1:entities()
        assert(c1_es and #c1_es >= 0 and c1_ec == 0)

        local c2_es, c2_ec = c2:entities()
        assert(c2_es and #c2_es >= 0 and c2_ec == 0)

        local c12_es, c12_ec = c12:entities()
        assert(c12_es and #c12_es >= 1 and c12_ec == 1)
        assert(c12_es[1] == f2)
    end
    evo.destroy(f1)
    do
        local c1_es, c1_ec = c1:entities()
        assert(c1_es and #c1_es >= 0 and c1_ec == 0)

        local c2_es, c2_ec = c2:entities()
        assert(c2_es and #c2_es >= 1 and c2_ec == 1)
        assert(c2_es[1] == f2)

        local c12_es, c12_ec = c12:entities()
        assert(c12_es and #c12_es >= 0 and c12_ec == 0)
    end
end

do
    local f1, f2 = evo.id(2)
    local c1 = assert(evo.chunk(f1))
    local c2 = assert(evo.chunk(f2))
    local c12 = assert(evo.chunk(f1, f2))
    evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
    evo.set(f1, f1)
    evo.set(f2, f1)
    evo.set(f2, f2)
    do
        local c1_es, c1_ec = c1:entities()
        assert(c1_es and #c1_es >= 0 and c1_ec == 0)

        local c2_es, c2_ec = c2:entities()
        assert(c2_es and #c2_es >= 0 and c2_ec == 0)

        local c12_es, c12_ec = c12:entities()
        assert(c12_es and #c12_es >= 1 and c12_ec == 1)
        assert(c12_es[1] == f2)
    end
    evo.destroy(f1)
    do
        local c1_es, c1_ec = c1:entities()
        assert(c1_es and #c1_es >= 0 and c1_ec == 0)

        local c2_es, c2_ec = c2:entities()
        assert(c2_es and #c2_es >= 0 and c2_ec == 0)

        local c12_es, c12_ec = c12:entities()
        assert(c12_es and #c12_es >= 0 and c12_ec == 0)
    end
end

do
    local f1, f2, f3 = evo.id(3)
    local c1 = assert(evo.chunk(f1))
    local c2 = assert(evo.chunk(f2))
    evo.set(f2, f1)
    evo.set(f3, f2)
    do
        local c1_es, c1_ec = c1:entities()
        assert(c1_es and #c1_es >= 1 and c1_ec == 1)
        assert(c1_es[1] == f2)

        local c2_es, c2_ec = c2:entities()
        assert(c2_es and #c2_es >= 1 and c2_ec == 1)
        assert(c2_es[1] == f3)
    end
    evo.destroy(f1)
    do
        local c1_es, c1_ec = c1:entities()
        assert(c1_es and #c1_es >= 0 and c1_ec == 0)

        local c2_es, c2_ec = c2:entities()
        assert(c2_es and #c2_es >= 1 and c2_ec == 1)
        assert(c2_es[1] == f3)
    end
end

do
    local f1, f2, f3 = evo.id(3)
    local c1 = assert(evo.chunk(f1))
    local c2 = assert(evo.chunk(f2))
    evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)
    evo.set(f2, f1)
    evo.set(f3, f2)
    do
        local c1_es, c1_ec = c1:entities()
        assert(c1_es and #c1_es >= 1 and c1_ec == 1)
        assert(c1_es[1] == f2)

        local c2_es, c2_ec = c2:entities()
        assert(c2_es and #c2_es >= 1 and c2_ec == 1)
        assert(c2_es[1] == f3)
    end
    evo.destroy(f1)
    do
        local c1_es, c1_ec = c1:entities()
        assert(c1_es and #c1_es >= 0 and c1_ec == 0)

        local c2_es, c2_ec = c2:entities()
        assert(c2_es and #c2_es >= 1 and c2_ec == 1)
        assert(c2_es[1] == f3)
    end
end

do
    local f1, f2, f3 = evo.id(3)
    local c1 = assert(evo.chunk(f1))
    local c2 = assert(evo.chunk(f2))
    evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
    evo.set(f2, f1)
    evo.set(f3, f2)
    do
        local c1_es, c1_ec = c1:entities()
        assert(c1_es and #c1_es >= 1 and c1_ec == 1)
        assert(c1_es[1] == f2)

        local c2_es, c2_ec = c2:entities()
        assert(c2_es and #c2_es >= 1 and c2_ec == 1)
        assert(c2_es[1] == f3)
    end
    evo.destroy(f1)
    do
        local c1_es, c1_ec = c1:entities()
        assert(c1_es and #c1_es >= 0 and c1_ec == 0)

        local c2_es, c2_ec = c2:entities()
        assert(c2_es and #c2_es >= 0 and c2_ec == 0)
    end
end

do
    local f1, f2, f3, f4, ft = evo.id(5)
    evo.set(f1, ft)
    evo.set(f2, ft)
    evo.set(f3, ft)
    evo.set(f3, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
    local qt = evo.builder():include(ft):spawn()

    local c4 = assert(evo.chunk(f4))
    local c14 = assert(evo.chunk(f1, f4))
    local c24 = assert(evo.chunk(f2, f4))
    local c234 = assert(evo.chunk(f2, f3, f4))
    local c124 = assert(evo.chunk(f1, f2, f4))

    local e14 = evo.builder():set(f1, 1):set(f4, 2):spawn()
    local e24 = evo.builder():set(f2, 3):set(f4, 4):spawn()
    local e234 = evo.builder():set(f2, 5):set(f3, 6):set(f4, 7):spawn()
    local e124 = evo.builder():set(f1, 8):set(f2, 6):set(f4, 9):spawn()

    evo.batch_destroy(qt)

    do
        local c4_es, c4_ec = c4:entities()
        assert(c4_es and #c4_es >= 3 and c4_ec == 3)
        assert(c4_es[1] == e24 and c4_es[2] == e14 and c4_es[3] == e124)
    end

    assert(#c14:entities() >= 0)
    assert(#c24:entities() >= 0)
    assert(#c124:entities() >= 0)
    assert(#c234:entities() >= 0)

    assert(evo.alive(e14) and not evo.empty(e14))
    assert(evo.alive(e24) and not evo.empty(e24))
    assert(not evo.alive(e234) and evo.empty(e234))
    assert(evo.alive(e124) and not evo.empty(e124))
end

do
    local f1 = evo.id()
    evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
    evo.set(f1, f1, f1)

    local remove_count = 0
    evo.set(f1, evo.ON_REMOVE, function(e, f, c)
        assert(e == f1)
        assert(f == f1)
        assert(c == f1)
        remove_count = remove_count + 1
    end)

    local c1 = assert(evo.chunk(f1))

    evo.destroy(f1)

    do
        assert(not evo.alive(f1))
        assert(remove_count == 1)

        local c1_es, c1_ec = c1:entities()
        assert(c1_es and #c1_es >= 0 and c1_ec == 0)
    end
end

do
    local f1 = evo.id()
    evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)
    evo.set(f1, f1, f1)

    local remove_count = 0
    evo.set(f1, evo.ON_REMOVE, function(e, f, c)
        assert(e == f1)
        assert(f == f1)
        assert(c == f1)
        remove_count = remove_count + 1
    end)

    local c1 = assert(evo.chunk(f1))

    evo.destroy(f1)

    do
        assert(not evo.alive(f1))
        assert(remove_count == 1)

        local c1_es, c1_ec = c1:entities()
        assert(c1_es and #c1_es >= 0 and c1_ec == 0)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f1, evo.NAME, 'f1')
    evo.set(f2, evo.NAME, 'f2')
    evo.set(f3, evo.NAME, 'f3')

    local c1 = evo.chunk(f1)
    local c12 = evo.chunk(f1, f2)
    local c13 = evo.chunk(f1, f3)
    local c123 = evo.chunk(f1, f2, f3)

    local e1a = evo.builder():set(f1, 1):spawn()
    local e1b = evo.builder():set(f1, 2):spawn()

    local e12a = evo.builder():set(f1, 3):set(f2, 4):spawn()
    local e12b = evo.builder():set(f1, 5):set(f2, 6):spawn()

    local e123a = evo.builder():set(f1, 7):set(f2, 8):set(f3, 9):spawn()
    local e123b = evo.builder():set(f1, 10):set(f2, 11):set(f3, 12):spawn()

    evo.destroy(f2)

    do
        assert(c1 and c12 and c13 and c123)
    end

    do
        local c1_es, c1_ec = c1:entities()
        assert(c1 and c1_es and c1_ec)
        assert(c1_ec == 4 and #c1_es >= 4)
        assert(c1_es[1] == e1a and c1_es[2] == e1b and c1_es[3] == e12a and c1_es[4] == e12b)
    end

    do
        local c12_es, c12_ec = c12:entities()
        assert(c12 and c12_es and c12_ec)
        assert(c12_ec == 0 and #c12_es >= 0)
    end

    do
        local c13_es, c13_ec = c13:entities()
        assert(c13 and c13_es and c13_ec)
        assert(c13_ec == 2 and #c13_es >= 2)
        assert(c13_es[1] == e123a and c13_es[2] == e123b)
    end

    do
        local c123_es, c123_ec = c123:entities()
        assert(c123 and c123_es and c123_ec)
        assert(c123_ec == 0 and #c123_es >= 0)
    end
end

do
    do
        local f1, f2 = evo.id(2)
        evo.set(f1, f1)
        evo.set(f2, f1)
        evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
        evo.destroy(f1)
        assert(not evo.alive(f1))
        assert(not evo.alive(f2))
    end

    do
        local f1, f2 = evo.id(2)
        evo.set(f1, f1)
        evo.set(f2, f1)
        evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)
        evo.destroy(f1)
        assert(not evo.alive(f1))
        assert(evo.alive(f2) and evo.empty(f2))
    end
end

do
    local f1, f2 = evo.id(2)

    evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

    local e12a = evo.builder():set(f1, 1):set(f2, 2):spawn()
    local e12b = evo.builder():set(f1, 3):set(f2, 4):spawn()
    local e_e12a_e12b = evo.builder():set(e12a, 11):set(e12b, 22):spawn()

    local e2a = evo.builder():set(f2, 5):spawn()
    local e2b = evo.builder():set(f2, 6):spawn()
    local e_e2a_e2b = evo.builder():set(e2a, 55):set(e2b, 66):spawn()

    evo.destroy(f1)

    do
        assert(not evo.alive(e12a) and not evo.alive(e12b))
        assert(evo.alive(e_e12a_e12b) and evo.empty(e_e12a_e12b))

        assert(evo.alive(e2a) and evo.alive(e2b))
        assert(evo.alive(e_e2a_e2b) and not evo.empty(e_e2a_e2b))
    end

    do
        local c2, c2_es, c2_ec = evo.chunk(f2)
        assert(c2 and c2_es and c2_ec)
        assert(#c2_es >= 2 and c2_ec == 2)
        assert(c2_es[1] == e2a and c2_es[2] == e2b)
    end
end

do
    local f1, f2 = evo.id(2)

    evo.set(f1, evo.NAME, "f1")
    evo.set(f2, evo.NAME, "f2")

    evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)

    local e12a = evo.builder():set(f1, 1):set(f2, 2):spawn()
    local e12b = evo.builder():set(f1, 3):set(f2, 4):spawn()
    local e_e12a_e12b = evo.builder():set(e12a, 11):set(e12b, 22):spawn()

    local e2a = evo.builder():set(f2, 5):spawn()
    local e2b = evo.builder():set(f2, 6):spawn()
    local e_e2a_e2b = evo.builder():set(e2a, 55):set(e2b, 66):spawn()

    evo.destroy(f1)

    do
        assert(evo.alive(e12a) and evo.alive(e12b))
        assert(evo.alive(e_e12a_e12b) and not evo.empty(e_e12a_e12b))
        assert(evo.alive(e2a) and evo.alive(e2b))
        assert(evo.alive(e_e2a_e2b) and not evo.empty(e_e2a_e2b))
    end

    do
        local c2, c2_es, c2_ec = evo.chunk(f2)
        assert(c2 and c2_es and c2_ec)
        assert(#c2_es >= 4 and c2_ec == 4)
        assert(c2_es[1] == e2a and c2_es[2] == e2b and c2_es[3] == e12a and c2_es[4] == e12b)
    end
end

do
    local fb = evo.builder()

    local f1 = fb:spawn()
    local f2 = fb:destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY):spawn()
    local f3 = fb:destruction_policy(evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT):spawn()

    assert(evo.get(f1, evo.DESTRUCTION_POLICY) == nil)
    assert(evo.get(f2, evo.DESTRUCTION_POLICY) == evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
    assert(evo.get(f3, evo.DESTRUCTION_POLICY) == evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)
end

do
    local f1, f2, f3 = evo.id(3)

    local c1 = evo.chunk(f1)
    local c23 = evo.chunk(f2, f3)

    assert(c1 and c23)

    assert(#c1:fragments() >= 1)
    assert(c1:fragments()[1] == f1)

    assert(#c23:fragments() >= 2)
    assert(c23:fragments()[1] == f2)
    assert(c23:fragments()[2] == f3)
end

do
    local f0, f1, f2, f3 = evo.id(4)

    local e1 = evo.builder():set(f0, 0):set(f1, 1):spawn()
    local e12 = evo.builder():set(f0, 0):set(f1, 2):set(f2, 3):spawn()
    local e123 = evo.builder():set(f0, 0):set(f1, 4):set(f2, 5):set(f3, 6):spawn()

    evo.builder():set(f1, 41):spawn()
    evo.builder():set(f1, 42):set(f2, 43):spawn()

    do
        local q1 = evo.builder():include(f0, f1):spawn()

        local iter, state = evo.execute(q1)

        local chunk, entity_list, entity_count = iter(state)
        assert(entity_list and #entity_list >= 1)
        assert(entity_count and entity_count == 1)
        assert(chunk == evo.chunk(f0, f1) and entity_list[1] == e1)

        chunk, entity_list, entity_count = iter(state)
        assert(entity_list and #entity_list >= 1)
        assert(entity_count and entity_count == 1)
        assert(chunk == evo.chunk(f0, f1, f2) and entity_list[1] == e12)

        chunk, entity_list, entity_count = iter(state)
        assert(entity_list and #entity_list >= 1)
        assert(entity_count and entity_count == 1)
        assert(chunk == evo.chunk(f0, f1, f2, f3) and entity_list[1] == e123)

        chunk, entity_list, entity_count = iter(state)
        assert(not chunk and not entity_list and not entity_count)
    end

    do
        local q1 = evo.builder():include(f0, f1):exclude(f3):spawn()

        local iter, state = evo.execute(q1)

        local chunk, entity_list, entity_count = iter(state)
        assert(entity_list and #entity_list >= 1)
        assert(entity_count and entity_count == 1)
        assert(chunk == evo.chunk(f0, f1) and entity_list[1] == e1)

        chunk, entity_list, entity_count = iter(state)
        assert(entity_list and #entity_list >= 1)
        assert(entity_count and entity_count == 1)
        assert(chunk == evo.chunk(f0, f1, f2) and entity_list[1] == e12)

        chunk, entity_list, entity_count = iter(state)
        assert(not chunk and not entity_list and not entity_count)
    end
end

do
    local f1, f2 = evo.id(2)
    local q12 = evo.builder():include(f1, f2):spawn()

    do
        local iter, state = evo.execute(q12)
        local chunk, entity_list, entity_count = iter(state)
        assert(not chunk and not entity_list and not entity_count)
    end
end

do
    local f1, f2 = evo.id(2)
    local qe12 = evo.builder():exclude(f1, f2):spawn()

    evo.builder():set(f1, 1):spawn()
    evo.builder():set(f2, 2):spawn()
    local e12 = evo.builder():set(f1, 3):set(f2, 4):spawn()

    local c1 = evo.chunk(f1)
    local c2 = evo.chunk(f2)
    local c12 = evo.chunk(f1, f2)

    do
        local matched_chunk_count = 0
        local matched_entity_count = 0

        for c, es, ec in evo.execute(qe12) do
            assert(ec > 0)
            assert(#es >= ec)
            assert(c ~= c1 and c ~= c2 and c ~= c12)
            matched_chunk_count = matched_chunk_count + 1
            matched_entity_count = matched_entity_count + ec
        end

        assert(matched_chunk_count > 0)
        assert(matched_entity_count > 0)
    end

    evo.set(qe12, evo.EXCLUDES)

    do
        local matched_chunk_count = 0
        local matched_entity_count = 0

        for _, es, ec in evo.execute(qe12) do
            assert(ec > 0)
            assert(#es >= ec)
            matched_chunk_count = matched_chunk_count + 1
            matched_entity_count = matched_entity_count + ec
        end

        assert(matched_chunk_count > 0)
        assert(matched_entity_count > 0)
    end

    evo.set(qe12, evo.INCLUDES, { f1, f2 })

    do
        local iter, state = evo.execute(qe12)
        local chunk, entity_list, entity_count = iter(state)
        assert(chunk == c12)
        assert(entity_list and #entity_list >= 1)
        assert(entity_count and entity_count == 1)
        assert(entity_list[1] == e12)
    end
end

do
    local f1, f2 = evo.id(2)

    evo.set(f1, evo.NAME, 'f1')
    evo.set(f2, evo.NAME, 'f2')

    local old_c1 = assert(evo.chunk(f1))
    local old_c12 = assert(evo.chunk(f1, f2))

    local e1 = evo.builder():set(f1, 1):spawn()

    evo.collect_garbage()

    local e12 = evo.builder():set(f1, 2):set(f2, 3):spawn()

    do
        assert(old_c1:alive())
        assert(old_c1 == evo.chunk(f1))

        local old_c1_es, old_c1_ec = old_c1:entities()
        assert(old_c1_es and old_c1_ec)
        assert(#old_c1_es >= 1 and old_c1_ec == 1)
        assert(old_c1_es[1] == e1)
    end

    do
        local new_c12 = assert(evo.chunk(f1, f2))

        assert(not old_c12:alive())
        assert(old_c12 ~= new_c12)

        local new_c12_es, new_c12_ec = new_c12:entities()
        assert(new_c12_es and new_c12_ec)
        assert(#new_c12_es >= 1 and new_c12_ec == 1)
        assert(new_c12_es[1] == e12)
    end

    evo.destroy(e1)
    evo.destroy(e12)

    evo.collect_garbage()

    do
        local new_c1 = assert(evo.chunk(f1))

        assert(not old_c1:alive())
        assert(old_c1 ~= new_c1)

        local new_c12 = assert(evo.chunk(f1, f2))

        assert(not old_c12:alive())
        assert(old_c12 ~= new_c12)
    end
end

do
    local f1 = evo.id()
    local old_c1 = assert(evo.chunk(f1))

    assert(evo.defer())

    evo.collect_garbage()

    assert(old_c1:alive())
    assert(old_c1 == evo.chunk(f1))

    assert(evo.commit())

    assert(not old_c1:alive())
    assert(old_c1 ~= evo.chunk(f1))
end

do
    do
        local f1 = evo.id()

        local e1, e2 = evo.id(2)
        evo.set(e1, f1, f1)
        evo.set(e2, f1, f1)

        evo.clear(e1, e2)

        assert(evo.alive(e1) and evo.empty(e1))
        assert(evo.alive(e2) and evo.empty(e2))
    end

    do
        local f1 = evo.id()

        local e1, e2, e3, e4, e5 = evo.id(5)
        evo.set(e1, f1, f1)
        evo.set(e2, f1, f1)
        evo.set(e3, f1, f1)
        evo.set(e4, f1, f1)
        evo.set(e5, f1, f1)

        evo.clear(e1, e2, e3, e4, e5)

        assert(evo.alive(e1) and evo.empty(e1))
        assert(evo.alive(e2) and evo.empty(e2))
        assert(evo.alive(e3) and evo.empty(e3))
        assert(evo.alive(e4) and evo.empty(e4))
        assert(evo.alive(e5) and evo.empty(e5))
    end
end

do
    do
        local f1 = evo.id()

        local e1, e2, e3 = evo.id(3)
        evo.set(e1, f1, f1)
        evo.set(e2, f1, f1)
        evo.set(e3, f1, f1)

        assert(evo.defer())
        do
            evo.clear(e1, e2, e3)
            assert(evo.alive(e1) and not evo.empty(e1))
            assert(evo.alive(e2) and not evo.empty(e2))
            assert(evo.alive(e3) and not evo.empty(e3))
        end
        assert(evo.commit())

        assert(evo.alive(e1) and evo.empty(e1))
        assert(evo.alive(e2) and evo.empty(e2))
        assert(evo.alive(e3) and evo.empty(e3))
    end

    do
        local f1 = evo.id()

        local e1, e2, e3, e4, e5 = evo.id(5)
        evo.set(e1, f1, f1)
        evo.set(e2, f1, f1)
        evo.set(e3, f1, f1)
        evo.set(e4, f1, f1)
        evo.set(e5, f1, f1)

        assert(evo.defer())
        do
            evo.clear(e1, e2, e3, e4, e5)
            assert(evo.alive(e1) and not evo.empty(e1))
            assert(evo.alive(e2) and not evo.empty(e2))
            assert(evo.alive(e3) and not evo.empty(e3))
            assert(evo.alive(e4) and not evo.empty(e4))
            assert(evo.alive(e5) and not evo.empty(e5))
        end
        assert(evo.commit())

        assert(evo.alive(e1) and evo.empty(e1))
        assert(evo.alive(e2) and evo.empty(e2))
        assert(evo.alive(e3) and evo.empty(e3))
        assert(evo.alive(e4) and evo.empty(e4))
        assert(evo.alive(e5) and evo.empty(e5))
    end
end

do
    do
        local f1 = evo.id()

        local e1, e2 = evo.id(2)
        evo.set(e1, f1, f1)
        evo.set(e2, f1, f1)

        evo.destroy(e1, e2)

        assert(not evo.alive(e1) and evo.empty(e1))
        assert(not evo.alive(e2) and evo.empty(e2))
    end

    do
        local f1 = evo.id()

        local e1, e2, e3, e4, e5 = evo.id(5)
        evo.set(e1, f1, f1)
        evo.set(e2, f1, f1)
        evo.set(e3, f1, f1)
        evo.set(e4, f1, f1)
        evo.set(e5, f1, f1)

        evo.destroy(e1, e2, e3, e4, e5)

        assert(not evo.alive(e1) and evo.empty(e1))
        assert(not evo.alive(e2) and evo.empty(e2))
        assert(not evo.alive(e3) and evo.empty(e3))
        assert(not evo.alive(e4) and evo.empty(e4))
        assert(not evo.alive(e5) and evo.empty(e5))
    end
end

do
    do
        local f1 = evo.id()

        local e1, e2, e3 = evo.id(3)
        evo.set(e1, f1, f1)
        evo.set(e2, f1, f1)
        evo.set(e3, f1, f1)

        assert(evo.defer())
        do
            evo.destroy(e1, e2, e3)
            assert(evo.alive(e1) and not evo.empty(e1))
            assert(evo.alive(e2) and not evo.empty(e2))
            assert(evo.alive(e3) and not evo.empty(e3))
        end
        assert(evo.commit())

        assert(not evo.alive(e1) and evo.empty(e1))
        assert(not evo.alive(e2) and evo.empty(e2))
        assert(not evo.alive(e3) and evo.empty(e3))
    end

    do
        local f1 = evo.id()

        local e1, e2, e3, e4, e5 = evo.id(5)
        evo.set(e1, f1, f1)
        evo.set(e2, f1, f1)
        evo.set(e3, f1, f1)
        evo.set(e4, f1, f1)
        evo.set(e5, f1, f1)

        assert(evo.defer())
        do
            evo.destroy(e1, e2, e3, e4, e5)
            assert(evo.alive(e1) and not evo.empty(e1))
            assert(evo.alive(e2) and not evo.empty(e2))
            assert(evo.alive(e3) and not evo.empty(e3))
            assert(evo.alive(e4) and not evo.empty(e4))
            assert(evo.alive(e5) and not evo.empty(e5))
        end
        assert(evo.commit())

        assert(not evo.alive(e1) and evo.empty(e1))
        assert(not evo.alive(e2) and evo.empty(e2))
        assert(not evo.alive(e3) and evo.empty(e3))
        assert(not evo.alive(e4) and evo.empty(e4))
        assert(not evo.alive(e5) and evo.empty(e5))
    end
end

do
    local f1 = evo.id()
    local e1, e2 = evo.id(2)
    evo.set(e1, f1, f1)
    evo.set(e2, f1, f1)
    evo.clear(e1, e2, e1, e1)
    assert(evo.alive(e1) and evo.empty(e1))
    assert(evo.alive(e2) and evo.empty(e2))
end

do
    local f1 = evo.id()
    local e1, e2 = evo.id(2)
    evo.set(e1, f1, f1)
    evo.set(e2, f1, f1)
    evo.destroy(e1, e2, e1, e1)
    assert(not evo.alive(e1) and evo.empty(e1))
    assert(not evo.alive(e2) and evo.empty(e2))
end

do
    local f1, f2 = evo.id(2)

    local q1, q2 = evo.id(2)
    evo.set(q1, evo.INCLUDES, { f1 })
    evo.set(q2, evo.INCLUDES, { f2 })

    local e1, e2 = evo.id(2)
    evo.set(e1, f1, f1)
    evo.set(e2, f2, f2)

    evo.batch_clear()

    assert(evo.alive(e1) and not evo.empty(e1))
    assert(evo.alive(e2) and not evo.empty(e2))

    evo.batch_clear(q1, q2, q1, q1)

    assert(evo.alive(e1) and evo.empty(e1))
    assert(evo.alive(e2) and evo.empty(e2))
end

do
    local f1, f2 = evo.id(2)

    local q1, q2 = evo.id(2)
    evo.set(q1, evo.INCLUDES, { f1 })
    evo.set(q2, evo.INCLUDES, { f2 })

    local e1, e2 = evo.id(2)
    evo.set(e1, f1, f1)
    evo.set(e2, f2, f2)

    assert(evo.defer())
    do
        evo.batch_clear(q2, q1, q2, q2)
        assert(evo.alive(e1) and not evo.empty(e1))
        assert(evo.alive(e2) and not evo.empty(e2))
    end
    assert(evo.commit())

    assert(evo.alive(e1) and evo.empty(e1))
    assert(evo.alive(e2) and evo.empty(e2))
end

do
    local f1, f2 = evo.id(2)

    local q1, q2 = evo.id(2)
    evo.set(q1, evo.INCLUDES, { f1 })
    evo.set(q2, evo.INCLUDES, { f2 })

    local e1, e2 = evo.id(2)
    evo.set(e1, f1, f1)
    evo.set(e2, f2, f2)

    evo.batch_destroy()

    assert(evo.alive(e1) and not evo.empty(e1))
    assert(evo.alive(e2) and not evo.empty(e2))

    evo.batch_destroy(q1, q2, q1, q1)

    assert(not evo.alive(e1) and evo.empty(e1))
    assert(not evo.alive(e2) and evo.empty(e2))
end

do
    local f1, f2 = evo.id(2)

    local q1, q2 = evo.id(2)
    evo.set(q1, evo.INCLUDES, { f1 })
    evo.set(q2, evo.INCLUDES, { f2 })

    local e1, e2 = evo.id(2)
    evo.set(e1, f1, f1)
    evo.set(e2, f2, f2)

    assert(evo.defer())
    do
        evo.batch_destroy(q2, q1, q2, q2)
        assert(evo.alive(e1) and not evo.empty(e1))
        assert(evo.alive(e2) and not evo.empty(e2))
    end
    assert(evo.commit())

    assert(not evo.alive(e1) and evo.empty(e1))
    assert(not evo.alive(e2) and evo.empty(e2))
end

do
    local a1, a2, a3, a4, a5 = evo.id(5)

    assert(evo.alive(a1))
    assert(evo.alive_all())
    assert(evo.alive_all(a1))
    assert(evo.alive_all(a1, a2))
    assert(evo.alive_all(a1, a2, a3))
    assert(evo.alive_all(a1, a2, a3, a4))
    assert(evo.alive_all(a1, a2, a3, a4, a5))

    assert(not evo.alive_any())
    assert(evo.alive_any(a1))
    assert(evo.alive_any(a1, a2))
    assert(evo.alive_any(a1, a2, a3))
    assert(evo.alive_any(a1, a2, a3, a4))
    assert(evo.alive_any(a1, a2, a3, a4, a5))

    local d1, d2 = evo.id(2)
    evo.destroy(d1, d2)

    assert(not evo.alive(d1))
    assert(not evo.alive_all(d1))
    assert(not evo.alive_all(d1, d2))
    assert(not evo.alive_all(d1, a1))
    assert(not evo.alive_all(a1, d1))
    assert(not evo.alive_all(d1, d2, a1))
    assert(not evo.alive_all(d1, a1, a2))
    assert(not evo.alive_all(d1, a1, a2, d2, a3))
    assert(not evo.alive_all(d1, a1, a2, d2, a3, d1))

    assert(not evo.alive_any(d1))
    assert(not evo.alive_any(d1, d2))
    assert(evo.alive_any(d1, a1))
    assert(evo.alive_any(a1, d1))
    assert(evo.alive_any(d1, d2, a1))
    assert(evo.alive_any(d1, a1, a2))
    assert(evo.alive_any(d1, a1, a2, d2, a3))
    assert(evo.alive_any(d1, a1, a2, d2, a3, d1))
end

do
    local e1, e2, e3, e4, e5 = evo.id(5)

    assert(evo.empty(e1))
    assert(evo.empty_all())
    assert(evo.empty_all(e1))
    assert(evo.empty_all(e1, e2))
    assert(evo.empty_all(e1, e2, e3))
    assert(evo.empty_all(e1, e2, e3, e4))
    assert(evo.empty_all(e1, e2, e3, e4, e5))

    assert(not evo.empty_any())
    assert(evo.empty_any(e1))
    assert(evo.empty_any(e1, e2))
    assert(evo.empty_any(e1, e2, e3))
    assert(evo.empty_any(e1, e2, e3, e4))
    assert(evo.empty_any(e1, e2, e3, e4, e5))

    local d1, d2 = evo.id(2)
    evo.destroy(d1, d2)

    assert(evo.empty(d1))
    assert(evo.empty_all(d1))
    assert(evo.empty_all(d1, d2))
    assert(evo.empty_all(d1, e1))
    assert(evo.empty_all(e1, d1))
    assert(evo.empty_all(d1, d2, e1))
    assert(evo.empty_all(d1, e1, e2))
    assert(evo.empty_all(d1, e1, e2, d2, e3))
    assert(evo.empty_all(d1, e1, e2, d2, e3, d1))

    assert(evo.empty_any(d1))
    assert(evo.empty_any(d1, d2))
    assert(evo.empty_any(d1, e1))
    assert(evo.empty_any(e1, d1))
    assert(evo.empty_any(d1, d2, e1))
    assert(evo.empty_any(d1, e1, e2))
    assert(evo.empty_any(d1, e1, e2, d2, e3))
    assert(evo.empty_any(d1, e1, e2, d2, e3, d1))

    local f1, f2 = evo.id(2)
    evo.set(f1, f1)
    evo.set(f2, f2)

    assert(not evo.empty(f1))
    assert(not evo.empty_all(f1))
    assert(not evo.empty_all(f1, f2))
    assert(not evo.empty_all(f1, e1))
    assert(not evo.empty_all(e1, f1))
    assert(not evo.empty_all(f1, f2, e1))
    assert(not evo.empty_all(f1, e1, e2))
    assert(not evo.empty_all(f1, e1, e2, f2, e3))
    assert(not evo.empty_all(f1, e1, e2, f2, e3, f1))

    assert(not evo.empty_any(f1))
    assert(not evo.empty_any(f1, f2))
    assert(evo.empty_any(f1, e1))
    assert(evo.empty_any(e1, f1))
    assert(evo.empty_any(f1, f2, e1))
    assert(evo.empty_any(f1, e1, e2))
    assert(evo.empty_any(f1, e1, e2, f2, e3))
    assert(evo.empty_any(f1, e1, e2, f2, e3, f1))
end

do
    local f1, f2, f3, f4, f5, f6 = evo.id(6)

    local e2 = evo.spawn({ [f1] = true, [f2] = true })
    local e5 = evo.spawn({ [f1] = 41, [f2] = 42, [f3] = 43, [f4] = 44, [f5] = 45 })

    assert(evo.has_all(e2, f1))
    assert(evo.has_all(e2, f1, f2))
    assert(evo.has_all(e2, f2, f1))
    assert(evo.has_all(e2, f2, f1, f2))
    assert(not evo.has_all(e2, f1, f2, f3))

    assert(evo.has_all(e5, f1))
    assert(evo.has_all(e5, f1, f2))
    assert(evo.has_all(e5, f1, f2, f3))
    assert(evo.has_all(e5, f1, f2, f3, f4))
    assert(evo.has_all(e5, f1, f2, f3, f4, f5))

    assert(not evo.has_all(e5, f6, f1, f2, f3, f4, f5))
    assert(not evo.has_all(e5, f1, f2, f3, f4, f5, f6))
    assert(not evo.has_all(e5, f1, f2, f6, f3, f4, f5))
end

do
    local f1, f2, f3, f4, f5, f6, f7 = evo.id(7)

    local e2 = evo.spawn({ [f1] = true, [f2] = true })
    local e5 = evo.spawn({ [f1] = 41, [f2] = 42, [f3] = 43, [f4] = 44, [f5] = 45 })

    assert(evo.has_all(e2))
    assert(not evo.has_any(e2))

    assert(evo.has_any(e2, f1))
    assert(evo.has_any(e2, f1, f2))
    assert(evo.has_any(e2, f2, f1))
    assert(evo.has_any(e2, f2, f1, f2))
    assert(evo.has_any(e2, f1, f2, f3))
    assert(evo.has_any(e2, f3, f4, f5, f6, f7, f1))

    assert(not evo.has_any(e2, f3))
    assert(not evo.has_any(e2, f3, f4))
    assert(not evo.has_any(e2, f3, f7, f4))

    assert(evo.has_any(e5, f1))
    assert(evo.has_any(e5, f1, f2))
    assert(evo.has_any(e5, f1, f2, f3))
    assert(evo.has_any(e5, f1, f2, f3, f4))
    assert(evo.has_any(e5, f1, f2, f3, f4, f5))

    assert(evo.has_any(e5, f6, f1, f2, f3, f4, f5))
    assert(evo.has_any(e5, f1, f2, f3, f4, f5, f6))
    assert(evo.has_any(e5, f1, f2, f6, f3, f4, f5))

    assert(not evo.has_any(e5, f7))
    assert(not evo.has_any(e5, f7, f7))
    assert(not evo.has_any(e5, f7, f7, f6))
end

do
    local f1, f2 = evo.id(2)
    local c1 = assert(evo.chunk(f1))
    local c12 = assert(evo.chunk(f1, f2))

    assert(c1:has(f1))
    assert(not c1:has(f2))
    assert(c12:has(f1))
    assert(c12:has(f2))

    assert(c1:has_all())
    assert(c1:has_all(f1))
    assert(not c1:has_all(f1, f2))
    assert(c12:has_all())
    assert(c12:has_all(f1))
    assert(c12:has_all(f1, f2))

    assert(not c1:has_any())
    assert(c1:has_any(f1))
    assert(c1:has_any(f1, f2))
    assert(not c12:has_any())
    assert(c12:has_any(f1))
    assert(c12:has_any(f1, f2))

    evo.collect_garbage()
    assert(not c1:alive())
    assert(not c12:alive())

    assert(c1:has(f1))
    assert(not c1:has(f2))
    assert(c12:has(f1))
    assert(c12:has(f2))

    assert(c1:has_all())
    assert(c1:has_all(f1))
    assert(not c1:has_all(f1, f2))
    assert(c12:has_all())
    assert(c12:has_all(f1))
    assert(c12:has_all(f1, f2))

    assert(not c1:has_any())
    assert(c1:has_any(f1))
    assert(c1:has_any(f1, f2))
    assert(not c12:has_any())
    assert(c12:has_any(f1))
    assert(c12:has_any(f1, f2))
end

do
    local gb = evo.builder()

    local g1 = gb:clear():spawn()
    local g2 = gb:clear():name('g2'):spawn()

    assert(not evo.has(g1, evo.NAME) and not evo.has(g1, g1))
    assert(evo.get(g2, evo.NAME) == 'g2' and not evo.has(g2, g2))
end

do
    local g = evo.builder():spawn()
    local s = evo.builder():group(g):spawn()
    assert(evo.get(s, evo.GROUP) == g)
end

do
    -- evo.set

    local function v2(x, y) return { x = x or 0, y = y or 0 } end
    local function v2_clone(v) return { x = v.x, y = v.y } end

    do
        local f = evo.builder():spawn()

        do
            local e1, e2 = evo.id(2)

            evo.set(e1, f)
            evo.set(e2, f)

            assert(evo.get(e1, f) == true)
            assert(evo.get(e2, f) == true)

            evo.set(e1, f, v2(1, 2))
            evo.set(e2, f, v2(3, 4))

            assert(evo.get(e1, f).x == 1 and evo.get(e1, f).y == 2)
            assert(evo.get(e2, f).x == 3 and evo.get(e2, f).y == 4)

            evo.set(e1, f)
            evo.set(e2, f)

            assert(evo.get(e1, f) == true)
            assert(evo.get(e2, f) == true)
        end

        do
            local e1, e2 = evo.id(2)

            evo.set(e1, f, v2(1, 2))
            evo.set(e2, f, v2(3, 4))

            assert(evo.get(e1, f).x == 1 and evo.get(e1, f).y == 2)
            assert(evo.get(e2, f).x == 3 and evo.get(e2, f).y == 4)

            evo.set(e1, f)
            evo.set(e2, f)

            assert(evo.get(e1, f) == true)
            assert(evo.get(e2, f) == true)
        end
    end

    do
        local f = evo.builder():default(v2(11, 22)):spawn()

        do
            local e1, e2 = evo.id(3)

            evo.set(e1, f)
            evo.set(e2, f)

            assert(evo.get(e1, f).x == 11 and evo.get(e1, f).y == 22)
            assert(evo.get(e2, f).x == 11 and evo.get(e2, f).y == 22)
            assert(evo.get(e1, f) == evo.get(e2, f))

            evo.set(e1, f, v2(1, 2))
            evo.set(e2, f, v2(3, 4))

            assert(evo.get(e1, f).x == 1 and evo.get(e1, f).y == 2)
            assert(evo.get(e2, f).x == 3 and evo.get(e2, f).y == 4)
            assert(evo.get(e1, f) ~= evo.get(e2, f))

            evo.set(e1, f)
            evo.set(e2, f)

            assert(evo.get(e1, f).x == 11 and evo.get(e1, f).y == 22)
            assert(evo.get(e2, f).x == 11 and evo.get(e2, f).y == 22)
            assert(evo.get(e1, f) == evo.get(e2, f))
        end

        do
            local e1, e2 = evo.id(2)

            evo.set(e1, f, v2(1, 2))
            evo.set(e2, f, v2(3, 4))

            assert(evo.get(e1, f).x == 1 and evo.get(e1, f).y == 2)
            assert(evo.get(e2, f).x == 3 and evo.get(e2, f).y == 4)
            assert(evo.get(e1, f) ~= evo.get(e2, f))

            evo.set(e1, f)
            evo.set(e2, f)

            assert(evo.get(e1, f).x == 11 and evo.get(e1, f).y == 22)
            assert(evo.get(e2, f).x == 11 and evo.get(e2, f).y == 22)
            assert(evo.get(e1, f) == evo.get(e2, f))
        end
    end

    do
        local f = evo.builder():default(v2(11, 22)):duplicate(v2_clone):spawn()

        do
            local e1, e2 = evo.id(2)

            evo.set(e1, f)
            evo.set(e2, f)

            assert(evo.get(e1, f).x == 11 and evo.get(e1, f).y == 22)
            assert(evo.get(e2, f).x == 11 and evo.get(e2, f).y == 22)
            assert(evo.get(e1, f) ~= evo.get(e2, f))

            evo.set(e1, f, v2(1, 2))
            evo.set(e2, f, v2(3, 4))

            assert(evo.get(e1, f).x == 1 and evo.get(e1, f).y == 2)
            assert(evo.get(e2, f).x == 3 and evo.get(e2, f).y == 4)
            assert(evo.get(e1, f) ~= evo.get(e2, f))

            evo.set(e1, f)
            evo.set(e2, f)

            assert(evo.get(e1, f).x == 11 and evo.get(e1, f).y == 22)
            assert(evo.get(e2, f).x == 11 and evo.get(e2, f).y == 22)
            assert(evo.get(e1, f) ~= evo.get(e2, f))
        end

        do
            local e1, e2 = evo.id(2)

            evo.set(e1, f, v2(1, 2))
            evo.set(e2, f, v2(3, 4))

            assert(evo.get(e1, f).x == 1 and evo.get(e1, f).y == 2)
            assert(evo.get(e2, f).x == 3 and evo.get(e2, f).y == 4)
            assert(evo.get(e1, f) ~= evo.get(e2, f))

            evo.set(e1, f)
            evo.set(e2, f)

            assert(evo.get(e1, f).x == 11 and evo.get(e1, f).y == 22)
            assert(evo.get(e2, f).x == 11 and evo.get(e2, f).y == 22)
            assert(evo.get(e1, f) ~= evo.get(e2, f))
        end
    end

    do
        local f = evo.builder():duplicate(v2_clone):spawn()

        do
            local e1, e2 = evo.id(2)

            evo.set(e1, f)
            evo.set(e2, f)

            assert(evo.get(e1, f) == true)
            assert(evo.get(e2, f) == true)
            assert(evo.get(e1, f) == evo.get(e2, f))

            evo.set(e1, f, v2(1, 2))
            evo.set(e2, f, v2(3, 4))

            assert(evo.get(e1, f).x == 1 and evo.get(e1, f).y == 2)
            assert(evo.get(e2, f).x == 3 and evo.get(e2, f).y == 4)
            assert(evo.get(e1, f) ~= evo.get(e2, f))

            evo.set(e1, f)
            evo.set(e2, f)

            assert(evo.get(e1, f) == true)
            assert(evo.get(e2, f) == true)
            assert(evo.get(e1, f) == evo.get(e2, f))
        end

        do
            local e1, e2 = evo.id(2)

            evo.set(e1, f, v2(1, 2))
            evo.set(e2, f, v2(3, 4))

            assert(evo.get(e1, f).x == 1 and evo.get(e1, f).y == 2)
            assert(evo.get(e2, f).x == 3 and evo.get(e2, f).y == 4)
            assert(evo.get(e1, f) ~= evo.get(e2, f))

            evo.set(e1, f)
            evo.set(e2, f)

            assert(evo.get(e1, f) == true)
            assert(evo.get(e2, f) == true)
            assert(evo.get(e1, f) == evo.get(e2, f))
        end
    end
end

do
    local function v2(x, y) return { x = x or 0, y = y or 0 } end
    local function v2_clone(v) return { x = v.x, y = v.y } end

    do
        local f = evo.builder():spawn()

        local t1 = evo.builder():tag():spawn()
        local qt1 = evo.builder():include(t1):spawn()

        do
            local e1, e2 = evo.id(2)
            evo.set(e1, t1); evo.set(e2, t1)

            evo.batch_set(qt1, f)

            assert(evo.get(e1, f) == true)
            assert(evo.get(e2, f) == true)

            evo.batch_set(qt1, f, v2(1, 2))

            assert(evo.get(e1, f).x == 1 and evo.get(e1, f).y == 2)
            assert(evo.get(e2, f).x == 1 and evo.get(e2, f).y == 2)
            assert(evo.get(e1, f) == evo.get(e2, f))

            evo.batch_set(qt1, f)

            assert(evo.get(e1, f) == true)
            assert(evo.get(e2, f) == true)
        end

        do
            local e1, e2 = evo.id(2)
            evo.set(e1, t1); evo.set(e2, t1)

            evo.batch_set(qt1, f, v2(1, 2))

            assert(evo.get(e1, f).x == 1 and evo.get(e1, f).y == 2)
            assert(evo.get(e2, f).x == 1 and evo.get(e2, f).y == 2)
            assert(evo.get(e1, f) == evo.get(e2, f))

            evo.batch_set(qt1, f)

            assert(evo.get(e1, f) == true)
            assert(evo.get(e2, f) == true)
        end
    end

    do
        local f = evo.builder():default(v2(11, 22)):spawn()

        local t1 = evo.builder():tag():spawn()
        local qt1 = evo.builder():include(t1):spawn()

        do
            local e1, e2 = evo.id(2)
            evo.set(e1, t1); evo.set(e2, t1)

            evo.batch_set(qt1, f)

            assert(evo.get(e1, f).x == 11 and evo.get(e1, f).y == 22)
            assert(evo.get(e2, f).x == 11 and evo.get(e2, f).y == 22)
            assert(evo.get(e1, f) == evo.get(e2, f))

            evo.batch_set(qt1, f, v2(1, 2))

            assert(evo.get(e1, f).x == 1 and evo.get(e1, f).y == 2)
            assert(evo.get(e2, f).x == 1 and evo.get(e2, f).y == 2)
            assert(evo.get(e1, f) == evo.get(e2, f))

            evo.batch_set(qt1, f)

            assert(evo.get(e1, f).x == 11 and evo.get(e1, f).y == 22)
            assert(evo.get(e2, f).x == 11 and evo.get(e2, f).y == 22)
            assert(evo.get(e1, f) == evo.get(e2, f))
        end

        do
            local e1, e2 = evo.id(2)
            evo.set(e1, t1); evo.set(e2, t1)

            evo.batch_set(qt1, f, v2(1, 2))

            assert(evo.get(e1, f).x == 1 and evo.get(e1, f).y == 2)
            assert(evo.get(e2, f).x == 1 and evo.get(e2, f).y == 2)
            assert(evo.get(e1, f) == evo.get(e2, f))

            evo.batch_set(qt1, f)

            assert(evo.get(e1, f).x == 11 and evo.get(e1, f).y == 22)
            assert(evo.get(e2, f).x == 11 and evo.get(e2, f).y == 22)
            assert(evo.get(e1, f) == evo.get(e2, f))
        end
    end

    do
        local f = evo.builder():default(v2(11, 22)):duplicate(v2_clone):spawn()

        local t1 = evo.builder():tag():spawn()
        local qt1 = evo.builder():include(t1):spawn()

        do
            local e1, e2 = evo.id(2)
            evo.set(e1, t1); evo.set(e2, t1)

            evo.batch_set(qt1, f)

            assert(evo.get(e1, f).x == 11 and evo.get(e1, f).y == 22)
            assert(evo.get(e2, f).x == 11 and evo.get(e2, f).y == 22)
            assert(evo.get(e1, f) ~= evo.get(e2, f))

            evo.batch_set(qt1, f, v2(1, 2))

            assert(evo.get(e1, f).x == 1 and evo.get(e1, f).y == 2)
            assert(evo.get(e2, f).x == 1 and evo.get(e2, f).y == 2)
            assert(evo.get(e1, f) ~= evo.get(e2, f))

            evo.batch_set(qt1, f)

            assert(evo.get(e1, f).x == 11 and evo.get(e1, f).y == 22)
            assert(evo.get(e2, f).x == 11 and evo.get(e2, f).y == 22)
            assert(evo.get(e1, f) ~= evo.get(e2, f))
        end

        do
            local e1, e2 = evo.id(2)
            evo.set(e1, t1); evo.set(e2, t1)

            evo.batch_set(qt1, f, v2(1, 2))

            assert(evo.get(e1, f).x == 1 and evo.get(e1, f).y == 2)
            assert(evo.get(e2, f).x == 1 and evo.get(e2, f).y == 2)
            assert(evo.get(e1, f) ~= evo.get(e2, f))

            evo.batch_set(qt1, f)

            assert(evo.get(e1, f).x == 11 and evo.get(e1, f).y == 22)
            assert(evo.get(e2, f).x == 11 and evo.get(e2, f).y == 22)
            assert(evo.get(e1, f) ~= evo.get(e2, f))
        end
    end

    do
        local f = evo.builder():duplicate(v2_clone):spawn()

        local t1 = evo.builder():tag():spawn()
        local qt1 = evo.builder():include(t1):spawn()

        do
            local e1, e2 = evo.id(2)
            evo.set(e1, t1); evo.set(e2, t1)

            evo.batch_set(qt1, f)

            assert(evo.get(e1, f) == true)
            assert(evo.get(e2, f) == true)
            assert(evo.get(e1, f) == evo.get(e2, f))

            evo.batch_set(qt1, f, v2(1, 2))

            assert(evo.get(e1, f).x == 1 and evo.get(e1, f).y == 2)
            assert(evo.get(e2, f).x == 1 and evo.get(e2, f).y == 2)
            assert(evo.get(e1, f) ~= evo.get(e2, f))

            evo.batch_set(qt1, f)

            assert(evo.get(e1, f) == true)
            assert(evo.get(e2, f) == true)
            assert(evo.get(e1, f) == evo.get(e2, f))
        end

        do
            local e1, e2 = evo.id(2)
            evo.set(e1, t1); evo.set(e2, t1)

            evo.batch_set(qt1, f, v2(1, 2))

            assert(evo.get(e1, f).x == 1 and evo.get(e1, f).y == 2)
            assert(evo.get(e2, f).x == 1 and evo.get(e2, f).y == 2)
            assert(evo.get(e1, f) ~= evo.get(e2, f))

            evo.batch_set(qt1, f)

            assert(evo.get(e1, f) == true)
            assert(evo.get(e2, f) == true)
            assert(evo.get(e1, f) == evo.get(e2, f))
        end
    end
end

do
    local function v2(x, y) return { x = x or 0, y = y or 0 } end

    local f1 = evo.builder():default(v2(10, 11)):spawn()
    local f2 = evo.builder():default(v2(11, 22)):spawn()

    do
        local cs = { [f1] = v2(1, 2), [f2] = v2(11, 22) }

        local e1 = evo.spawn(cs)
        local e2 = evo.spawn(cs)

        assert(evo.get(e1, f1).x == 1 and evo.get(e1, f1).y == 2)
        assert(evo.get(e2, f1).x == 1 and evo.get(e2, f1).y == 2)
        assert(evo.get(e1, f1) == evo.get(e2, f1))

        assert(evo.get(e1, f2).x == 11 and evo.get(e1, f2).y == 22)
        assert(evo.get(e2, f2).x == 11 and evo.get(e2, f2).y == 22)
        assert(evo.get(e1, f2) == evo.get(e2, f2))
    end
end

do
    local function v2(x, y) return { x = x or 0, y = y or 0 } end
    local function v2_clone(v) return { x = v.x, y = v.y } end

    local f1 = evo.builder():default(v2(10, 11)):duplicate(v2_clone):spawn()
    local f2 = evo.builder():default(v2(11, 22)):duplicate(v2_clone):spawn()

    do
        local cs = { [f1] = v2(1, 2), [f2] = v2(11, 22) }

        local e1 = evo.spawn(cs)
        local e2 = evo.spawn(cs)

        assert(evo.get(e1, f1).x == 1 and evo.get(e1, f1).y == 2)
        assert(evo.get(e2, f1).x == 1 and evo.get(e2, f1).y == 2)
        assert(evo.get(e1, f1) ~= evo.get(e2, f1))

        assert(evo.get(e1, f2).x == 11 and evo.get(e1, f2).y == 22)
        assert(evo.get(e2, f2).x == 11 and evo.get(e2, f2).y == 22)
        assert(evo.get(e1, f2) ~= evo.get(e2, f2))
    end
end

do
    local f1, f2, f3 = evo.id(3)

    do
        local p1 = evo.spawn { [f2] = 42, [f3] = 43 }
        local e1 = evo.clone(p1, { [f1] = 41 })

        assert(evo.alive_all(p1, e1) and not evo.empty_any(p1, e1))

        assert(not evo.has(p1, f1) and evo.get(p1, f1) == nil)
        assert(evo.has(p1, f2) and evo.get(p1, f2) == 42)
        assert(evo.has(p1, f3) and evo.get(p1, f3) == 43)

        assert(evo.has(e1, f1) and evo.get(e1, f1) == 41)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == 42)
        assert(evo.has(e1, f3) and evo.get(e1, f3) == 43)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f2, evo.DUPLICATE, function(v) return v * 2 end)

    do
        local p1 = evo.spawn { [f2] = 42, [f3] = 43 }
        local e1 = evo.clone(p1, { [f1] = 41 })

        assert(evo.alive_all(p1, e1) and not evo.empty_any(p1, e1))

        assert(not evo.has(p1, f1) and evo.get(p1, f1) == nil)
        assert(evo.has(p1, f2) and evo.get(p1, f2) == 84)
        assert(evo.has(p1, f3) and evo.get(p1, f3) == 43)

        assert(evo.has(e1, f1) and evo.get(e1, f1) == 41)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == 168)
        assert(evo.has(e1, f3) and evo.get(e1, f3) == 43)
    end
end

do
    local b = evo.builder()

    local f1, f2 = evo.id(2)

    do
        local e1 = b:clear():set(f1, 41):spawn()
        local e2 = b:clear():set(f2, 42):spawn()

        assert(evo.has(e1, f1) and evo.get(e1, f1) == 41)
        assert(not evo.has(e1, f2) and evo.get(e1, f2) == nil)

        assert(not evo.has(e2, f1) and evo.get(e2, f1) == nil)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == 42)
    end

    do
        local e1 = b:clear():set(f1, 41):spawn()
        local e2 = b:set(f2, 42):spawn()
        local e3 = b:clear():set(f2, 43):spawn()

        assert(evo.has(e1, f1) and evo.get(e1, f1) == 41)
        assert(not evo.has(e1, f2) and evo.get(e1, f2) == nil)

        assert(evo.has(e2, f1) and evo.get(e2, f1) == 41)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == 42)

        assert(not evo.has(e3, f1) and evo.get(e3, f1) == nil)
        assert(evo.has(e3, f2) and evo.get(e3, f2) == 43)
    end

    do
        assert(evo.defer())

        local e1 = b:clear():set(f1, 41):spawn()
        local e2 = b:clear():set(f2, 42):spawn()

        assert(not evo.has_any(e1, f1, f2))
        assert(not evo.has_any(e2, f1, f2))

        assert(evo.commit())

        assert(evo.has(e1, f1) and evo.get(e1, f1) == 41)
        assert(not evo.has(e1, f2) and evo.get(e1, f2) == nil)

        assert(not evo.has(e2, f1) and evo.get(e2, f1) == nil)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == 42)
    end

    do
        assert(evo.defer())

        local e1 = b:clear():set(f1, 41):spawn()
        local e2 = b:set(f2, 42):spawn()
        local e3 = b:clear():set(f2, 43):spawn()

        assert(not evo.has_any(e1, f1, f2))
        assert(not evo.has_any(e2, f1, f2))
        assert(not evo.has_any(e3, f1, f2))

        assert(evo.commit())

        assert(evo.has(e1, f1) and evo.get(e1, f1) == 41)
        assert(not evo.has(e1, f2) and evo.get(e1, f2) == nil)

        assert(evo.has(e2, f1) and evo.get(e2, f1) == 41)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == 42)

        assert(not evo.has(e3, f1) and evo.get(e3, f1) == nil)
        assert(evo.has(e3, f2) and evo.get(e3, f2) == 43)
    end
end

do
    local b = evo.builder()

    local f1, f2 = evo.id(2)

    do
        local e1 = b:set(f1, 41):spawn()
        local e2 = b:set(f2, 42):clone(e1)

        assert(evo.has(e1, f1) and evo.get(e1, f1) == 41)
        assert(not evo.has(e1, f2) and evo.get(e1, f2) == nil)

        assert(evo.has(e2, f1) and evo.get(e2, f1) == 41)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == 42)
    end

    do
        local e1 = b:clear():set(f1, 41):spawn()
        local e2 = b:set(f2, 42):clone(e1)
        local e3 = b:clear():set(f2, 43):spawn()

        assert(evo.has(e1, f1) and evo.get(e1, f1) == 41)
        assert(not evo.has(e1, f2) and evo.get(e1, f2) == nil)

        assert(evo.has(e2, f1) and evo.get(e2, f1) == 41)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == 42)

        assert(not evo.has(e3, f1) and evo.get(e3, f1) == nil)
        assert(evo.has(e3, f2) and evo.get(e3, f2) == 43)
    end

    do
        assert(evo.defer())

        local e1 = b:clear():set(f1, 41):spawn()
        local e2 = b:set(f2, 42):clone(e1)

        assert(not evo.has_any(e1, f1, f2))
        assert(not evo.has_any(e2, f1, f2))

        assert(evo.commit())

        assert(evo.has(e1, f1) and evo.get(e1, f1) == 41)
        assert(not evo.has(e1, f2) and evo.get(e1, f2) == nil)

        assert(evo.has(e2, f1) and evo.get(e2, f1) == 41)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == 42)
    end

    do
        assert(evo.defer())

        local e1 = b:clear():set(f1, 41):spawn()
        local e2 = b:set(f2, 42):clone(e1)
        local e3 = b:clear():set(f2, 43):spawn()

        assert(not evo.has_any(e1, f1, f2))
        assert(not evo.has_any(e2, f1, f2))
        assert(not evo.has_any(e3, f1, f2))

        assert(evo.commit())

        assert(evo.has(e1, f1) and evo.get(e1, f1) == 41)
        assert(not evo.has(e1, f2) and evo.get(e1, f2) == nil)

        assert(evo.has(e2, f1) and evo.get(e2, f1) == 41)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == 42)

        assert(not evo.has(e3, f1) and evo.get(e3, f1) == nil)
        assert(evo.has(e3, f2) and evo.get(e3, f2) == 43)
    end
end

do
    local f1, f2 = evo.id(2)

    do
        local b = evo.builder()

        assert(b:has_all())
        assert(not b:has_any())

        assert(not b:has(f1) and b:get(f1) == nil)
        assert(not b:has(f2) and b:get(f2) == nil)

        assert(not b:has_all(f1, f2))
        assert(not b:has_any(f1, f2))

        do
            local e = b:spawn()

            assert(not evo.has(e, f1) and evo.get(e, f1) == nil)
            assert(not evo.has(e, f2) and evo.get(e, f2) == nil)
        end

        b:set(f1, 41)

        assert(b:has(f1) and b:get(f1) == 41)
        assert(not b:has(f2) and b:get(f2) == nil)

        assert(not b:has_all(f1, f2))
        assert(b:has_any(f1, f2))

        do
            local e = b:spawn()

            assert(evo.has(e, f1) and evo.get(e, f1) == 41)
            assert(not evo.has(e, f2) and evo.get(e, f2) == nil)
        end

        b:set(f2, 42)

        assert(b:has(f1) and b:get(f1) == 41)
        assert(b:has(f2) and b:get(f2) == 42)

        assert(b:has_all(f1, f2))
        assert(b:has_any(f1, f2))

        do
            local e = b:spawn()

            assert(evo.has(e, f1) and evo.get(e, f1) == 41)
            assert(evo.has(e, f2) and evo.get(e, f2) == 42)
        end

        b:remove(f1)

        assert(not b:has(f1) and b:get(f1) == nil)
        assert(b:has(f2) and b:get(f2) == 42)

        assert(not b:has_all(f1, f2))
        assert(b:has_any(f1, f2))

        do
            local e = b:spawn()

            assert(not evo.has(e, f1) and evo.get(e, f1) == nil)
            assert(evo.has(e, f2) and evo.get(e, f2) == 42)
        end

        b:remove(f2)

        assert(not b:has_all(f1, f2))
        assert(not b:has_any(f1, f2))

        assert(not b:has(f1) and b:get(f1) == nil)
        assert(not b:has(f2) and b:get(f2) == nil)

        do
            local e = b:spawn()

            assert(not evo.has(e, f1) and evo.get(e, f1) == nil)
            assert(not evo.has(e, f2) and evo.get(e, f2) == nil)
        end
    end
end

do
    local f0, f1, f2, f3, f4, f5 = evo.id(6)

    do
        local b = evo.builder()

        do
            assert(b:get() == nil)
        end

        do
            local c1 = b:get(f1)
            assert(c1 == nil)
        end

        do
            local c1, c2 = b:get(f1, f2)
            assert(c1 == nil and c2 == nil)
        end

        do
            local c1, c2, c3 = b:get(f1, f2, f3)
            assert(c1 == nil and c2 == nil and c3 == nil)
        end

        do
            local c1, c2, c3, c4 = b:get(f1, f2, f3, f4)
            assert(c1 == nil and c2 == nil and c3 == nil and c4 == nil)
        end

        do
            local c1, c2, c3, c4, c5 = b:get(f1, f2, f3, f4, f5)
            assert(c1 == nil and c2 == nil and c3 == nil and c4 == nil and c5 == nil)
        end

        do
            local c0, c1, c2, c3, c4, c5 = b:get(f0, f1, f2, f3, f4, f5)
            assert(c0 == nil and c1 == nil and c2 == nil and c3 == nil and c4 == nil and c5 == nil)
        end
    end

    do
        local b = evo.builder():set(f1, 11):set(f2, 22):set(f3, 33):set(f4, 44):set(f5, 55)

        do
            assert(b:get() == nil)
        end

        do
            local c1 = b:get(f1)
            assert(c1 == 11)
        end

        do
            local c1, c2 = b:get(f1, f2)
            assert(c1 == 11 and c2 == 22)
        end

        do
            local c1, c2, c3 = b:get(f1, f2, f3)
            assert(c1 == 11 and c2 == 22 and c3 == 33)
        end

        do
            local c1, c2, c3, c4 = b:get(f1, f2, f3, f4)
            assert(c1 == 11 and c2 == 22 and c3 == 33 and c4 == 44)
        end

        do
            local c1, c2, c3, c4, c5 = b:get(f1, f2, f3, f4, f5)
            assert(c1 == 11 and c2 == 22 and c3 == 33 and c4 == 44 and c5 == 55)
        end

        do
            local c0, c1, c2, c3, c4, c5 = b:get(f0, f1, f2, f3, f4, f5)
            assert(c0 == nil and c1 == 11 and c2 == 22 and c3 == 33 and c4 == 44 and c5 == 55)
        end

        do
            local c1, c0, c2, c3, c4, c5 = b:get(f1, f0, f2, f3, f4, f5)
            assert(c0 == nil and c1 == 11 and c2 == 22 and c3 == 33 and c4 == 44 and c5 == 55)
        end

        do
            local c5, c4, c3, c2, c1, c0 = b:get(f5, f4, f3, f2, f1, f0)
            assert(c0 == nil and c1 == 11 and c2 == 22 and c3 == 33 and c4 == 44 and c5 == 55)
        end
    end
end

do
    local f1, f2, f3 = evo.id(3)

    do
        local b = evo.builder():set(f1, 11):set(f2, 22)
        assert(b == b:remove(f1))
        assert(not b:has(f1) and b:get(f1) == nil)
        assert(b:has(f2) and b:get(f2) == 22)
        local e = b:spawn()
        assert(not evo.has(e, f1) and evo.get(e, f1) == nil)
        assert(evo.has(e, f2) and evo.get(e, f2) == 22)
    end

    do
        local b = evo.builder():set(f1, 11):set(f2, 22)
        assert(b == b:remove(f3, f1))
        assert(not b:has(f1) and b:get(f1) == nil)
        assert(b:has(f2) and b:get(f2) == 22)
        local e = b:spawn()
        assert(not evo.has(e, f1) and evo.get(e, f1) == nil)
        assert(evo.has(e, f2) and evo.get(e, f2) == 22)
    end

    do
        local b = evo.builder():set(f1, 11):set(f2, 22)
        assert(b == b:remove(f1, f2))
        assert(not b:has(f1) and b:get(f1) == nil)
        assert(not b:has(f2) and b:get(f2) == nil)
        local e = b:spawn()
        assert(not evo.has(e, f1) and evo.get(e, f1) == nil)
        assert(not evo.has(e, f2) and evo.get(e, f2) == nil)
    end

    do
        local b = evo.builder():set(f1, 11):set(f2, 22)
        assert(b == b:remove(f2, f1, f1))
        assert(not b:has(f1) and b:get(f1) == nil)
        assert(not b:has(f2) and b:get(f2) == nil)
        local e = b:spawn()
        assert(not evo.has(e, f1) and evo.get(e, f1) == nil)
        assert(not evo.has(e, f2) and evo.get(e, f2) == nil)
    end
end

do
    local f1, f2 = evo.id(2)

    do
        local e = evo.spawn()
        assert(evo.alive(e) and evo.empty(e))
    end

    do
        local e = evo.spawn({})
        assert(evo.alive(e) and evo.empty(e))
    end

    do
        local e = evo.spawn({ [f1] = 1 })
        assert(evo.alive(e) and not evo.empty(e))
        assert(evo.has(e, f1) and evo.get(e, f1) == 1)
        assert(not evo.has(e, f2) and evo.get(e, f2) == nil)
    end

    do
        local e = evo.spawn({ [f1] = 1, [f2] = 2 })
        assert(evo.alive(e) and not evo.empty(e))
        assert(evo.has(e, f1) and evo.get(e, f1) == 1)
        assert(evo.has(e, f2) and evo.get(e, f2) == 2)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    do
        local p = evo.spawn()

        local e1 = evo.clone(p)
        assert(evo.alive(e1) and evo.empty(e1))

        local e2 = evo.clone(p, {})
        assert(evo.alive(e2) and evo.empty(e2))

        local e3 = evo.clone(p, { [f1] = 11 })
        assert(evo.alive(e3) and not evo.empty(e3))
        assert(evo.has(e3, f1) and evo.get(e3, f1) == 11)
        assert(not evo.has(e3, f2) and evo.get(e3, f2) == nil)

        local e4 = evo.clone(p, { [f1] = 11, [f2] = 22 })
        assert(evo.alive(e4) and not evo.empty(e4))
        assert(evo.has(e4, f1) and evo.get(e4, f1) == 11)
        assert(evo.has(e4, f2) and evo.get(e4, f2) == 22)

        local e5 = evo.clone(p, { [f3] = 33 })
        assert(evo.alive(e5) and not evo.empty(e5))
        assert(not evo.has(e5, f1) and evo.get(e5, f1) == nil)
        assert(not evo.has(e5, f2) and evo.get(e5, f2) == nil)
        assert(evo.has(e5, f3) and evo.get(e5, f3) == 33)

        local e6 = evo.clone(p, { [f1] = 11, [f2] = 22, [f3] = 33 })
        assert(evo.alive(e6) and not evo.empty(e6))
        assert(evo.has(e6, f1) and evo.get(e6, f1) == 11)
        assert(evo.has(e6, f2) and evo.get(e6, f2) == 22)
        assert(evo.has(e6, f3) and evo.get(e6, f3) == 33)
    end

    do
        local p = evo.spawn({ [f1] = 1 })

        local e1 = evo.clone(p)
        assert(evo.alive(e1) and not evo.empty(e1))
        assert(evo.has(e1, f1) and evo.get(e1, f1) == 1)
        assert(not evo.has(e1, f2) and evo.get(e1, f2) == nil)

        local e2 = evo.clone(p, {})
        assert(evo.alive(e2) and not evo.empty(e2))
        assert(evo.has(e2, f1) and evo.get(e2, f1) == 1)
        assert(not evo.has(e2, f2) and evo.get(e2, f2) == nil)

        local e3 = evo.clone(p, { [f1] = 11 })
        assert(evo.alive(e3) and not evo.empty(e3))
        assert(evo.has(e3, f1) and evo.get(e3, f1) == 11)
        assert(not evo.has(e3, f2) and evo.get(e3, f2) == nil)

        local e4 = evo.clone(p, { [f2] = 22 })
        assert(evo.alive(e4) and not evo.empty(e4))
        assert(evo.has(e4, f1) and evo.get(e4, f1) == 1)
        assert(evo.has(e4, f2) and evo.get(e4, f2) == 22)

        local e5 = evo.clone(p, { [f1] = 11, [f2] = 22 })
        assert(evo.alive(e5) and not evo.empty(e5))
        assert(evo.has(e5, f1) and evo.get(e5, f1) == 11)
        assert(evo.has(e5, f2) and evo.get(e5, f2) == 22)

        local e6 = evo.clone(p, { [f3] = 33 })
        assert(evo.alive(e6) and not evo.empty(e6))
        assert(evo.has(e6, f1) and evo.get(e6, f1) == 1)
        assert(not evo.has(e6, f2) and evo.get(e6, f2) == nil)
        assert(evo.has(e6, f3) and evo.get(e6, f3) == 33)

        local e7 = evo.clone(p, { [f1] = 11, [f2] = 22, [f3] = 33 })
        assert(evo.alive(e7) and not evo.empty(e7))
        assert(evo.has(e7, f1) and evo.get(e7, f1) == 11)
        assert(evo.has(e7, f2) and evo.get(e7, f2) == 22)
        assert(evo.has(e7, f3) and evo.get(e7, f3) == 33)
    end

    do
        local p = evo.spawn({ [f1] = 1, [f2] = 2 })

        local e1 = evo.clone(p)
        assert(evo.alive(e1) and not evo.empty(e1))
        assert(evo.has(e1, f1) and evo.get(e1, f1) == 1)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == 2)

        local e2 = evo.clone(p, {})
        assert(evo.alive(e2) and not evo.empty(e2))
        assert(evo.has(e2, f1) and evo.get(e2, f1) == 1)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == 2)

        local e3 = evo.clone(p, { [f1] = 11 })
        assert(evo.alive(e3) and not evo.empty(e3))
        assert(evo.has(e3, f1) and evo.get(e3, f1) == 11)
        assert(evo.has(e3, f2) and evo.get(e3, f2) == 2)

        local e4 = evo.clone(p, { [f2] = 22 })
        assert(evo.alive(e4) and not evo.empty(e4))
        assert(evo.has(e4, f1) and evo.get(e4, f1) == 1)
        assert(evo.has(e4, f2) and evo.get(e4, f2) == 22)

        local e5 = evo.clone(p, { [f1] = 11, [f2] = 22 })
        assert(evo.alive(e5) and not evo.empty(e5))
        assert(evo.has(e5, f1) and evo.get(e5, f1) == 11)
        assert(evo.has(e5, f2) and evo.get(e5, f2) == 22)

        local e6 = evo.clone(p, { [f3] = 33 })
        assert(evo.alive(e6) and not evo.empty(e6))
        assert(evo.has(e6, f1) and evo.get(e6, f1) == 1)
        assert(evo.has(e6, f2) and evo.get(e6, f2) == 2)
        assert(evo.has(e6, f3) and evo.get(e6, f3) == 33)

        local e7 = evo.clone(p, { [f1] = 11, [f2] = 22, [f3] = 33 })
        assert(evo.alive(e7) and not evo.empty(e7))
        assert(evo.has(e7, f1) and evo.get(e7, f1) == 11)
        assert(evo.has(e7, f2) and evo.get(e7, f2) == 22)
        assert(evo.has(e7, f3) and evo.get(e7, f3) == 33)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    do
        assert(evo.defer())

        local e1 = evo.spawn()
        local e2 = evo.spawn({})
        local e3 = evo.spawn({ [f1] = 11 })
        local e4 = evo.spawn({ [f1] = 11, [f2] = 22 })

        assert(evo.alive(e1) and evo.empty(e1))
        assert(evo.alive(e2) and evo.empty(e2))
        assert(evo.alive(e3) and evo.empty(e3))
        assert(evo.alive(e4) and evo.empty(e4))

        assert(evo.commit())

        assert(evo.alive(e1) and evo.empty(e1))
        assert(evo.alive(e2) and evo.empty(e2))
        assert(evo.alive(e3) and not evo.empty(e3))
        assert(evo.alive(e4) and not evo.empty(e4))

        assert(evo.has(e3, f1) and evo.get(e3, f1) == 11)
        assert(not evo.has(e3, f2) and evo.get(e3, f2) == nil)

        assert(evo.has(e4, f1) and evo.get(e4, f1) == 11)
        assert(evo.has(e4, f2) and evo.get(e4, f2) == 22)
    end

    do
        local p1 = evo.spawn()
        local p2 = evo.spawn({ [f1] = 1 })
        local p3 = evo.spawn({ [f1] = 1, [f2] = 2 })

        assert(evo.defer())

        local e1a = evo.clone(p1)
        local e1b = evo.clone(p1, {})
        local e1c = evo.clone(p1, { [f1] = 11 })
        local e1d = evo.clone(p1, { [f2] = 22 })
        local e1e = evo.clone(p1, { [f1] = 11, [f2] = 22 })
        local e1f = evo.clone(p1, { [f3] = 33 })
        local e1g = evo.clone(p1, { [f1] = 11, [f2] = 22, [f3] = 33 })

        local e2a = evo.clone(p2)
        local e2b = evo.clone(p2, {})
        local e2c = evo.clone(p2, { [f1] = 11 })
        local e2d = evo.clone(p2, { [f2] = 22 })
        local e2e = evo.clone(p2, { [f1] = 11, [f2] = 22 })
        local e2f = evo.clone(p2, { [f3] = 33 })
        local e2g = evo.clone(p2, { [f1] = 11, [f2] = 22, [f3] = 33 })

        local e3a = evo.clone(p3)
        local e3b = evo.clone(p3, {})
        local e3c = evo.clone(p3, { [f1] = 11 })
        local e3d = evo.clone(p3, { [f2] = 22 })
        local e3e = evo.clone(p3, { [f1] = 11, [f2] = 22 })
        local e3f = evo.clone(p3, { [f3] = 33 })
        local e3g = evo.clone(p3, { [f1] = 11, [f2] = 22, [f3] = 33 })

        assert(evo.alive_all(e1a, e1b, e1c, e1d, e1e, e1f, e1g))
        assert(evo.alive_all(e2a, e2b, e2c, e2d, e2e, e2f, e2g))
        assert(evo.alive_all(e3a, e3b, e3c, e3d, e3e, e3f, e3g))

        assert(evo.empty_all(e1a, e1b, e1c, e1d, e1e, e1f, e1g))
        assert(evo.empty_all(e2a, e2b, e2c, e2d, e2e, e2f, e2g))
        assert(evo.empty_all(e3a, e3b, e3c, e3d, e3e, e3f, e3g))

        assert(evo.commit())

        assert(not evo.has(e1a, f1) and not evo.has(e1a, f2))
        assert(not evo.has(e1b, f1) and not evo.has(e1b, f2))

        assert(evo.has(e1c, f1) and evo.get(e1c, f1) == 11 and not evo.has(e1c, f2))
        assert(not evo.has(e1d, f1) and evo.has(e1d, f2) and evo.get(e1d, f2) == 22)

        assert(not evo.has(e1f, f1) and evo.get(e1f, f1) == nil)
        assert(not evo.has(e1f, f2) and evo.get(e1f, f2) == nil)
        assert(evo.has(e1f, f3) and evo.get(e1f, f3) == 33)

        assert(evo.has(e1g, f1) and evo.get(e1g, f1) == 11)
        assert(evo.has(e1g, f2) and evo.get(e1g, f2) == 22)
        assert(evo.has(e1g, f3) and evo.get(e1g, f3) == 33)

        assert(evo.has(e2a, f1) and evo.get(e2a, f1) == 1)
        assert(not evo.has(e2a, f2) and evo.get(e2a, f2) == nil)

        assert(evo.has(e2b, f1) and evo.get(e2b, f1) == 1)
        assert(not evo.has(e2b, f2) and evo.get(e2b, f2) == nil)

        assert(evo.has(e2c, f1) and evo.get(e2c, f1) == 11)
        assert(not evo.has(e2c, f2) and evo.get(e2c, f2) == nil)

        assert(evo.has(e2d, f1) and evo.get(e2d, f1) == 1)
        assert(evo.has(e2d, f2) and evo.get(e2d, f2) == 22)

        assert(evo.has(e2e, f1) and evo.get(e2e, f1) == 11)
        assert(evo.has(e2e, f2) and evo.get(e2e, f2) == 22)

        assert(evo.has(e2f, f1) and evo.get(e2f, f1) == 1)
        assert(not evo.has(e2f, f2) and evo.get(e2f, f2) == nil)
        assert(evo.has(e2f, f3) and evo.get(e2f, f3) == 33)

        assert(evo.has(e2g, f1) and evo.get(e2g, f1) == 11)
        assert(evo.has(e2g, f2) and evo.get(e2g, f2) == 22)
        assert(evo.has(e2g, f3) and evo.get(e2g, f3) == 33)

        assert(evo.has(e3a, f1) and evo.get(e3a, f1) == 1)
        assert(evo.has(e3a, f2) and evo.get(e3a, f2) == 2)

        assert(evo.has(e3b, f1) and evo.get(e3b, f1) == 1)
        assert(evo.has(e3b, f2) and evo.get(e3b, f2) == 2)

        assert(evo.has(e3c, f1) and evo.get(e3c, f1) == 11)
        assert(evo.has(e3c, f2) and evo.get(e3c, f2) == 2)

        assert(evo.has(e3d, f1) and evo.get(e3d, f1) == 1)
        assert(evo.has(e3d, f2) and evo.get(e3d, f2) == 22)

        assert(evo.has(e3e, f1) and evo.get(e3e, f1) == 11)
        assert(evo.has(e3e, f2) and evo.get(e3e, f2) == 22)

        assert(evo.has(e3f, f1) and evo.get(e3f, f1) == 1)
        assert(evo.has(e3f, f2) and evo.get(e3f, f2) == 2)
        assert(evo.has(e3f, f3) and evo.get(e3f, f3) == 33)

        assert(evo.has(e3g, f1) and evo.get(e3g, f1) == 11)
        assert(evo.has(e3g, f2) and evo.get(e3g, f2) == 22)
        assert(evo.has(e3g, f3) and evo.get(e3g, f3) == 33)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f2, evo.UNIQUE)
    evo.set(f3, evo.UNIQUE)

    do
        local p = evo.spawn { [f1] = 11, [f2] = 22 }
        local e = evo.clone(p)

        assert(evo.has(p, f1) and evo.get(p, f1) == 11)
        assert(evo.has(p, f2) and evo.get(p, f2) == 22)

        assert(evo.has(e, f1) and evo.get(e, f1) == 11)
        assert(not evo.has(e, f2) and evo.get(e, f2) == nil)
    end

    do
        local p = evo.spawn { [f1] = 11, [f2] = 22, [f3] = 33 }
        local e = evo.clone(p)

        assert(evo.has(p, f1) and evo.get(p, f1) == 11)
        assert(evo.has(p, f2) and evo.get(p, f2) == 22)
        assert(evo.has(p, f3) and evo.get(p, f3) == 33)

        assert(evo.has(e, f1) and evo.get(e, f1) == 11)
        assert(not evo.has(e, f2) and evo.get(e, f2) == nil)
        assert(not evo.has(e, f3) and evo.get(e, f3) == nil)
    end

    do
        local p = evo.spawn { [f2] = 22 }
        local e = evo.clone(p)

        assert(not evo.has(p, f1) and evo.get(p, f1) == nil)
        assert(evo.has(p, f2) and evo.get(p, f2) == 22)
        assert(not evo.has(p, f3) and evo.get(p, f3) == nil)

        assert(not evo.has(e, f1) and evo.get(e, f1) == nil)
        assert(not evo.has(e, f2) and evo.get(e, f2) == nil)
        assert(not evo.has(e, f3) and evo.get(e, f3) == nil)
    end
    do
        local p = evo.spawn { [f2] = 22, [f3] = 33 }
        local e = evo.clone(p)

        assert(not evo.has(p, f1) and evo.get(p, f1) == nil)
        assert(evo.has(p, f2) and evo.get(p, f2) == 22)
        assert(evo.has(p, f3) and evo.get(p, f3) == 33)

        assert(not evo.has(e, f1) and evo.get(e, f1) == nil)
        assert(not evo.has(e, f2) and evo.get(e, f2) == nil)
        assert(not evo.has(e, f3) and evo.get(e, f3) == nil)
    end

    do
        local p = evo.spawn { [f1] = 11, [f2] = 22 }
        local e = evo.clone(p, { [f2] = 2 })

        assert(evo.has(p, f1) and evo.get(p, f1) == 11)
        assert(evo.has(p, f2) and evo.get(p, f2) == 22)

        assert(evo.has(e, f1) and evo.get(e, f1) == 11)
        assert(evo.has(e, f2) and evo.get(e, f2) == 2)
    end

    do
        local p = evo.spawn { [f1] = 11, [f2] = 22 }
        local e = evo.clone(p, { [f2] = 2, [f3] = 3 })

        assert(evo.has(p, f1) and evo.get(p, f1) == 11)
        assert(evo.has(p, f2) and evo.get(p, f2) == 22)

        assert(evo.has(e, f1) and evo.get(e, f1) == 11)
        assert(evo.has(e, f2) and evo.get(e, f2) == 2)
        assert(evo.has(e, f3) and evo.get(e, f3) == 3)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f2, evo.UNIQUE)

    do
        local p = evo.spawn { [f1] = 11, [f2] = 22, [f3] = 33 }
        local e = evo.clone(p)

        assert(evo.has(p, f1) and evo.get(p, f1) == 11)
        assert(evo.has(p, f2) and evo.get(p, f2) == 22)
        assert(evo.has(p, f3) and evo.get(p, f3) == 33)

        assert(evo.has(e, f1) and evo.get(e, f1) == 11)
        assert(not evo.has(e, f2) and evo.get(e, f2) == nil)
        assert(evo.has(e, f3) and evo.get(e, f3) == 33)
    end
end

do
    local f1, f2 = evo.id(2)

    local p = evo.builder():prefab():set(f1, 11):set(f2, 22):spawn()
    local e = evo.clone(p)

    do
        local q = evo.builder():include(f1, f2):spawn()
        local iter, state = evo.execute(q)
        local chunk, entity_list, entity_count = iter(state)
        assert(chunk and entity_list and entity_count)
        assert(chunk == evo.chunk(f1, f2))
        assert(entity_count == 1 and entity_list[1] == e)
    end

    do
        local q = evo.builder():exclude(f1):spawn()

        for c in evo.execute(q) do
            local fs, fc = c:fragments()
            for i = 1, fc do assert(not evo.has(fs[i], evo.EXPLICIT)) end
        end
    end

    do
        local q = evo.builder():spawn()

        for c in evo.execute(q) do
            local fs, fc = c:fragments()
            for i = 1, fc do assert(not evo.has(fs[i], evo.EXPLICIT)) end
        end
    end
end

do
    local f1, f2 = evo.id(2)

    evo.set(f2, evo.EXPLICIT)

    local e1 = evo.builder():set(f1, 11):spawn()
    local e2 = evo.builder():set(f1, 11):set(f2, 22):spawn()

    do
        local q = evo.builder():include(f1):spawn()
        local iter, state = evo.execute(q)
        local chunk, entity_list, entity_count = iter(state)
        assert(chunk and entity_list and entity_count)
        assert(chunk == evo.chunk(f1))
        assert(entity_count == 1 and entity_list[1] == e1)
        chunk, entity_list, entity_count = iter(state)
        assert(not chunk and not entity_list and not entity_count)
    end

    do
        local q = evo.builder():include(f1, f2):spawn()
        local iter, state = evo.execute(q)
        local chunk, entity_list, entity_count = iter(state)
        assert(chunk and entity_list and entity_count)
        assert(chunk == evo.chunk(f1, f2))
        assert(entity_count == 1 and entity_list[1] == e2)
        chunk, entity_list, entity_count = iter(state)
        assert(not chunk and not entity_list and not entity_count)
    end
end

do
    local function v2(x, y) return { x = x or 0, y = y or 0 } end
    local function v2_clone(v) return { x = v.x, y = v.y } end

    local v2_default = v2(1, 2)

    do
        local f = evo.builder():default(v2_default):spawn()

        local b = evo.builder()

        b:set(f)
        evo.remove(f, evo.DEFAULT)

        local e = b:spawn()
        assert(evo.has(e, f) and evo.get(e, f).x == 1 and evo.get(e, f).y == 2)
        assert(evo.get(e, f) == v2_default)
    end

    do
        local f = evo.builder():default(v2_default):duplicate(v2_clone):spawn()

        local b = evo.builder()

        b:set(f)
        evo.remove(f, evo.DEFAULT, evo.DUPLICATE)

        local e = b:spawn()
        assert(evo.has(e, f) and evo.get(e, f).x == 1 and evo.get(e, f).y == 2)
        assert(evo.get(e, f) ~= v2_default)
    end
end

do
    local f1, f2 = evo.id(2)

    local prefab = evo.builder():prefab():set(f1, 11):set(f2, 22):spawn()

    do
        local entity = evo.clone(prefab)
        assert(evo.has(entity, f1) and evo.get(entity, f1) == 11)
        assert(evo.has(entity, f2) and evo.get(entity, f2) == 22)
    end

    evo.set(f2, evo.UNIQUE)

    do
        local entity = evo.clone(prefab)
        assert(evo.has(entity, f1) and evo.get(entity, f1) == 11)
        assert(not evo.has(entity, f2) and evo.get(entity, f2) == nil)
    end

    evo.remove(f2, evo.UNIQUE)

    do
        local entity = evo.clone(prefab)
        assert(evo.has(entity, f1) and evo.get(entity, f1) == 11)
        assert(evo.has(entity, f2) and evo.get(entity, f2) == 22)
    end

    evo.set(f1, evo.UNIQUE)
    evo.set(f2, evo.UNIQUE)

    do
        local entity = evo.clone(prefab)
        assert(evo.empty(entity))
    end

    evo.remove(f1, evo.UNIQUE)
    evo.remove(f2, evo.UNIQUE)

    do
        local entity = evo.clone(prefab)
        assert(evo.has(entity, f1) and evo.get(entity, f1) == 11)
        assert(evo.has(entity, f2) and evo.get(entity, f2) == 22)
    end
end

do
    do
        local f = evo.id()
        local c = evo.chunk(f)
        local b = evo.builder():set(f, 42)
        evo.collect_garbage()
        local e = b:spawn()
        assert(evo.locate(e) ~= c)
        assert(evo.locate(e) == evo.chunk(f))
    end

    do
        local f = evo.id()
        local c = evo.chunk(f)
        local b = evo.builder():set(f, 42)
        evo.collect_garbage()
        local es = b:multi_spawn(5)
        for i = 1, 5 do
            assert(evo.locate(es[i]) ~= c)
            assert(evo.locate(es[i]) == evo.chunk(f))
        end
    end
end

do
    local ff, ft = evo.id(2)
    local b = evo.builder():set(ff, false):set(ft, true)
    assert(b:has_all() and not b:has_any())
    assert(b:has(ff) and b:has(ft) and b:has_all(ff, ft) and b:has_any(ff, ft))
end

do
    do
        local f = evo.id()
        local q = evo.builder():include(f):spawn()
        local e = evo.builder():set(f, 42):spawn()

        local iter, state = evo.execute(q)
        local chunk, entity_list, entity_count = iter(state)
        assert(chunk and entity_list and entity_count)
        assert(chunk == evo.chunk(f) and entity_count == 1 and entity_list[1] == e)
    end

    do
        local f = evo.id()
        local e = evo.builder():set(f, 42):spawn()
        local q = evo.builder():include(f):spawn()

        local iter, state = evo.execute(q)
        local chunk, entity_list, entity_count = iter(state)
        assert(chunk and entity_list and entity_count)
        assert(chunk == evo.chunk(f) and entity_count == 1 and entity_list[1] == e)
    end

    do
        local f1, f2 = evo.id(2)
        local q = evo.builder():exclude(f2):spawn()
        local e = evo.builder():set(f1, 42):spawn()

        local e_count = 0

        for chunk, entity_list, entity_count in evo.execute(q) do
            for i = 1, entity_count do
                if entity_list[i] == e then
                    e_count = e_count + 1
                    assert(chunk == evo.chunk(f1))
                    assert(chunk:components(f1)[1] == 42)
                end
            end
        end

        assert(e_count == 1)
    end

    do
        local f1, f2, f3 = evo.id(3)
        local q = evo.builder():exclude(f2):spawn()
        local e1 = evo.builder():set(f1, 42):spawn()
        local e2 = evo.builder():set(f1, 42):set(f3, 21):spawn()

        local e1_count, e2_count = 0, 0

        for chunk, entity_list, entity_count in evo.execute(q) do
            for i = 1, entity_count do
                if entity_list[i] == e1 then
                    e1_count = e1_count + 1
                    assert(chunk == evo.chunk(f1))
                    assert(chunk:components(f1)[1] == 42)
                end

                if entity_list[i] == e2 then
                    e2_count = e2_count + 1
                    assert(chunk == evo.chunk(f1, f3))
                    assert(chunk:components(f1)[1] == 42)
                    assert(chunk:components(f3)[1] == 21)
                end
            end
        end

        assert(e1_count == 1)
        assert(e2_count == 1)
    end

    do
        local f1, f2 = evo.id(2)
        local e = evo.builder():set(f1, 42):spawn()
        local q = evo.builder():exclude(f2):spawn()

        local e_count = 0

        for chunk, entity_list, entity_count in evo.execute(q) do
            for i = 1, entity_count do
                if entity_list[i] == e then
                    e_count = e_count + 1
                    assert(chunk == evo.chunk(f1))
                    assert(chunk:components(f1)[1] == 42)
                end
            end
        end

        assert(e_count == 1)
    end

    do
        local f1, f2, f3 = evo.id(3)
        local e1 = evo.builder():set(f1, 42):spawn()
        local e2 = evo.builder():set(f1, 42):set(f3, 21):spawn()
        local q = evo.builder():exclude(f2):spawn()

        local e1_count, e2_count = 0, 0

        for chunk, entity_list, entity_count in evo.execute(q) do
            for i = 1, entity_count do
                if entity_list[i] == e1 then
                    e1_count = e1_count + 1
                    assert(chunk == evo.chunk(f1))
                    assert(chunk:components(f1)[1] == 42)
                end

                if entity_list[i] == e2 then
                    e2_count = e2_count + 1
                    assert(chunk == evo.chunk(f1, f3))
                    assert(chunk:components(f1)[1] == 42)
                    assert(chunk:components(f3)[1] == 21)
                end
            end
        end

        assert(e1_count == 1)
        assert(e2_count == 1)
    end
end

do
    local f1, f2 = evo.id(2)
    local q1 = evo.builder():include(f1):spawn()
    local q2 = evo.builder():include(f2):spawn()
    local e12 = evo.builder():set(f1, 42):set(f2, 21):spawn()

    do
        local iter, state = evo.execute(q1)
        local chunk, entity_list, entity_count = iter(state)
        assert(chunk and entity_list and entity_count)
        assert(chunk == evo.chunk(f1, f2) and entity_count == 1 and entity_list[1] == e12)
    end

    do
        local iter, state = evo.execute(q2)
        local chunk, entity_list, entity_count = iter(state)
        assert(chunk and entity_list and entity_count)
        assert(chunk == evo.chunk(f1, f2) and entity_count == 1 and entity_list[1] == e12)
    end

    evo.set(f1, evo.EXPLICIT)

    do
        local iter, state = evo.execute(q1)
        local chunk, entity_list, entity_count = iter(state)
        assert(chunk and entity_list and entity_count)
        assert(chunk == evo.chunk(f1, f2) and entity_count == 1 and entity_list[1] == e12)
    end

    do
        local iter, state = evo.execute(q2)
        local chunk, entity_list, entity_count = iter(state)
        assert(not chunk and not entity_list and not entity_count)
    end
end

do
    local function v2(x, y) return { x = x or 0, y = y or 0 } end
    local function v2_clone(v) return { x = v.x, y = v.y } end

    local f1, f2 = evo.id(2)

    local f1_default = v2(1, 2)
    local f2_default = v2(3, 4)

    evo.set(f1, evo.DEFAULT, f1_default)
    evo.set(f2, evo.DEFAULT, f2_default)

    evo.set(f1, evo.DUPLICATE, v2_clone)
    evo.set(f2, evo.DUPLICATE, v2_clone)

    local e1 = evo.builder():set(f1, v2(10, 11)):spawn()
    local e2 = evo.builder():set(f1, v2(12, 13)):set(f2, v2(14, 15)):spawn()

    do
        assert(evo.has(e1, f1) and evo.get(e1, f1).x == 10 and evo.get(e1, f1).y == 11)
        assert(evo.get(e1, f1) ~= f1_default)

        assert(evo.has(e2, f1) and evo.get(e2, f1).x == 12 and evo.get(e2, f1).y == 13)
        assert(evo.get(e2, f1) ~= f1_default)
        assert(evo.has(e2, f2) and evo.get(e2, f2).x == 14 and evo.get(e2, f2).y == 15)
        assert(evo.get(e2, f2) ~= f2_default)
    end

    evo.set(f1, evo.TAG)

    do
        assert(evo.has(e1, f1) and evo.get(e1, f1) == nil)

        assert(evo.has(e2, f1) and evo.get(e2, f1) == nil)
        assert(evo.has(e2, f2) and evo.get(e2, f2).x == 14 and evo.get(e2, f2).y == 15)
        assert(evo.get(e2, f2) ~= f2_default)
    end

    evo.remove(f1, evo.TAG)

    do
        assert(evo.has(e1, f1) and evo.get(e1, f1).x == 1 and evo.get(e1, f1).y == 2)
        assert(evo.get(e1, f1) ~= f1_default)

        assert(evo.has(e2, f1) and evo.get(e2, f1).x == 1 and evo.get(e2, f1).y == 2)
        assert(evo.get(e2, f1) ~= f1_default)
        assert(evo.has(e2, f2) and evo.get(e2, f2).x == 14 and evo.get(e2, f2).y == 15)
        assert(evo.get(e2, f2) ~= f2_default)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f1, evo.REQUIRES, { f2, f3 })
    evo.set(f2, evo.DEFAULT, false)
    evo.set(f3, evo.TAG)

    local v_set_sum = 0
    local v_insert_sum = 0

    local f3_set_times = 0
    local f3_insert_times = 0

    evo.set(f1, evo.ON_SET, function(e, f, v)
        assert(f == f1)
        v_set_sum = v_set_sum + v
        assert(evo.get(e, f) == v)
    end)

    evo.set(f1, evo.ON_INSERT, function(e, f, v)
        assert(f == f1)
        v_insert_sum = v_insert_sum + v
        assert(evo.get(e, f) == v)
    end)

    evo.set(f3, evo.ON_SET, function(e, f, v)
        assert(f == f3)
        f3_set_times = f3_set_times + 1
        assert(v == nil)
        assert(evo.has(e, f))
    end)

    evo.set(f3, evo.ON_INSERT, function(e, f, v)
        assert(f == f3)
        f3_insert_times = f3_insert_times + 1
        assert(v == nil)
        assert(evo.has(e, f))
    end)

    do
        local e = evo.spawn({ [f1] = 42 })
        assert(e and not evo.empty(e))

        assert(evo.has(e, f1) and evo.get(e, f1) == 42)
        assert(evo.has(e, f2) and evo.get(e, f2) == false)
    end

    do
        local entity_prefab = evo.builder():set(f1, 42):spawn()

        local e = evo.clone(entity_prefab)
        assert(e and not evo.empty(e))

        assert(evo.has(e, f1) and evo.get(e, f1) == 42)
        assert(evo.has(e, f2) and evo.get(e, f2) == false)
    end

    do
        local entity_prefab = evo.builder():set(f1, 42):spawn()
        evo.remove(entity_prefab, f2, f3)

        local e = evo.clone(entity_prefab, { [f1] = 21 })
        assert(e and not evo.empty(e))

        assert(evo.has(e, f1) and evo.get(e, f1) == 21)
        assert(evo.has(e, f2) and evo.get(e, f2) == false)
    end

    assert(v_set_sum == 42 * 4 + 21 * 1)
    assert(v_insert_sum == 42 * 4 + 21 * 1)

    assert(f3_set_times == 5)
    assert(f3_insert_times == 5)
end

do
    local function v2(x, y) return { x = x or 0, y = y or 0 } end
    local function v2_clone(v) return { x = v.x, y = v.y } end

    local f1, f2, f3, f4, f5, f6, f7 = evo.id(7)
    evo.set(f1, evo.REQUIRES, { f2, f3, f4 })
    evo.set(f5, evo.REQUIRES, { f6, f7 })

    local f1_default = v2(1, 2)
    local f2_default = v2(3, 4)
    local f3_default = v2(10, 11)
    local f4_default = v2(12, 13)
    local f6_default = v2(14, 15)
    local f7_default = v2(16, 17)

    evo.set(f1, evo.DEFAULT, f1_default)
    evo.set(f2, evo.DEFAULT, f2_default)
    evo.set(f3, evo.DEFAULT, f3_default)
    evo.set(f4, evo.DEFAULT, f4_default)
    evo.set(f6, evo.DEFAULT, f6_default)
    evo.set(f7, evo.DEFAULT, f7_default)

    evo.set(f1, evo.DUPLICATE, v2_clone)
    evo.set(f2, evo.DUPLICATE, v2_clone)
    evo.set(f3, evo.DUPLICATE, v2_clone)
    evo.set(f5, evo.DUPLICATE, v2_clone)
    evo.set(f6, evo.DUPLICATE, v2_clone)

    do
        local entity_list, entity_count = evo.multi_spawn(2, { [f1] = v2(5, 6), [f2] = v2(7, 8) })

        assert(entity_list and #entity_list == 2)
        assert(entity_count == 2)

        local q_f1 = evo.builder():include(f1):spawn()

        local f2_v = v2(20, 21)
        evo.batch_set(q_f1, f2, f2_v)

        for i = 1, entity_count do
            local e = entity_list[i]

            assert(evo.has(e, f1) and evo.get(e, f1).x == 5 and evo.get(e, f1).y == 6)
            assert(evo.has(e, f2) and evo.get(e, f2).x == 20 and evo.get(e, f2).y == 21)
            assert(evo.has(e, f3) and evo.get(e, f3).x == 10 and evo.get(e, f3).y == 11)
            assert(evo.has(e, f4) and evo.get(e, f4).x == 12 and evo.get(e, f4).y == 13)

            assert(evo.get(e, f1) ~= f1_default)
            assert(evo.get(e, f2) ~= f2_v and evo.get(e, f2) ~= f2_default)
            assert(evo.get(e, f3) ~= f3_default)
            assert(evo.get(e, f4) == f4_default)
        end

        local f5_v = v2(30, 31)
        evo.batch_set(q_f1, f5, f5_v)

        for i = 1, entity_count do
            local e = entity_list[i]

            assert(evo.has(e, f1) and evo.get(e, f1).x == 5 and evo.get(e, f1).y == 6)
            assert(evo.has(e, f2) and evo.get(e, f2).x == 20 and evo.get(e, f2).y == 21)
            assert(evo.has(e, f3) and evo.get(e, f3).x == 10 and evo.get(e, f3).y == 11)
            assert(evo.has(e, f4) and evo.get(e, f4).x == 12 and evo.get(e, f4).y == 13)
            assert(evo.has(e, f5) and evo.get(e, f5).x == 30 and evo.get(e, f5).y == 31)
            assert(evo.has(e, f6) and evo.get(e, f6).x == 14 and evo.get(e, f6).y == 15)
            assert(evo.has(e, f7) and evo.get(e, f7).x == 16 and evo.get(e, f7).y == 17)

            assert(evo.get(e, f1) ~= f1_default)
            assert(evo.get(e, f2) ~= f2_v and evo.get(e, f2) ~= f2_default)
            assert(evo.get(e, f3) ~= f3_default)
            assert(evo.get(e, f4) == f4_default)
            assert(evo.get(e, f5) ~= f5_v)
            assert(evo.get(e, f6) ~= f6_default)
            assert(evo.get(e, f7) == f7_default)
        end

        f5_v = v2(32, 33)
        evo.batch_set(q_f1, f5, f5_v)

        for i = 1, entity_count do
            local e = entity_list[i]

            assert(evo.has(e, f1) and evo.get(e, f1).x == 5 and evo.get(e, f1).y == 6)
            assert(evo.has(e, f2) and evo.get(e, f2).x == 20 and evo.get(e, f2).y == 21)
            assert(evo.has(e, f3) and evo.get(e, f3).x == 10 and evo.get(e, f3).y == 11)
            assert(evo.has(e, f4) and evo.get(e, f4).x == 12 and evo.get(e, f4).y == 13)
            assert(evo.has(e, f5) and evo.get(e, f5).x == 32 and evo.get(e, f5).y == 33)
            assert(evo.has(e, f6) and evo.get(e, f6).x == 14 and evo.get(e, f6).y == 15)
            assert(evo.has(e, f7) and evo.get(e, f7).x == 16 and evo.get(e, f7).y == 17)

            assert(evo.get(e, f1) ~= f1_default)
            assert(evo.get(e, f2) ~= f2_v and evo.get(e, f2) ~= f2_default)
            assert(evo.get(e, f3) ~= f3_default)
            assert(evo.get(e, f4) == f4_default)
            assert(evo.get(e, f5) ~= f5_v)
            assert(evo.get(e, f6) ~= f6_default)
            assert(evo.get(e, f7) == f7_default)
        end
    end
end

do
    local function v2(x, y) return { x = x or 0, y = y or 0 } end
    local function v2_clone(v) return { x = v.x, y = v.y } end

    local f1, f2, f3, f4, f5, f6, f7 = evo.id(7)
    evo.set(f1, evo.REQUIRES, { f2, f3, f4 })
    evo.set(f5, evo.REQUIRES, { f6, f7 })

    local f1_default = v2(1, 2)
    local f2_default = v2(3, 4)
    local f3_default = v2(10, 11)
    local f4_default = v2(12, 13)
    local f6_default = v2(14, 15)
    local f7_default = v2(16, 17)

    evo.set(f1, evo.DEFAULT, f1_default)
    evo.set(f2, evo.DEFAULT, f2_default)
    evo.set(f3, evo.DEFAULT, f3_default)
    evo.set(f4, evo.DEFAULT, f4_default)
    evo.set(f6, evo.DEFAULT, f6_default)
    evo.set(f7, evo.DEFAULT, f7_default)

    evo.set(f1, evo.DUPLICATE, v2_clone)
    evo.set(f2, evo.DUPLICATE, v2_clone)
    evo.set(f3, evo.DUPLICATE, v2_clone)
    evo.set(f5, evo.DUPLICATE, v2_clone)
    evo.set(f6, evo.DUPLICATE, v2_clone)

    local f5_set_sum = 0
    local f5_insert_sum = 0
    local f6_set_sum = 0
    local f6_insert_sum = 0
    local f7_set_sum = 0
    local f7_insert_sum = 0

    evo.set(f5, evo.ON_SET, function(e, f, v)
        assert(evo.get(e, f) == v)
        assert(f == f5)
        f5_set_sum = f5_set_sum + v.x + v.y
    end)

    evo.set(f5, evo.ON_INSERT, function(e, f, v)
        assert(evo.get(e, f) == v)
        assert(f == f5)
        f5_insert_sum = f5_insert_sum + v.x + v.y
    end)

    evo.set(f6, evo.ON_SET, function(e, f, v)
        assert(evo.get(e, f) == v)
        assert(f == f6)
        f6_set_sum = f6_set_sum + v.x + v.y
    end)

    evo.set(f6, evo.ON_INSERT, function(e, f, v)
        assert(evo.get(e, f) == v)
        assert(f == f6)
        f6_insert_sum = f6_insert_sum + v.x + v.y
    end)

    evo.set(f7, evo.ON_SET, function(e, f, v)
        assert(evo.get(e, f) == v)
        assert(f == f7)
        f7_set_sum = f7_set_sum + v.x + v.y
    end)

    evo.set(f7, evo.ON_INSERT, function(e, f, v)
        assert(evo.get(e, f) == v)
        assert(f == f7)
        f7_insert_sum = f7_insert_sum + v.x + v.y
    end)

    do
        local entity_list, entity_count = evo.multi_spawn(2, { [f1] = v2(5, 6), [f2] = v2(7, 8) })

        assert(entity_list and #entity_list == 2)
        assert(entity_count == 2)

        local q_f1 = evo.builder():include(f1):spawn()

        local f2_v = v2(20, 21)
        evo.batch_set(q_f1, f2, f2_v)

        for i = 1, entity_count do
            local e = entity_list[i]

            assert(evo.has(e, f1) and evo.get(e, f1).x == 5 and evo.get(e, f1).y == 6)
            assert(evo.has(e, f2) and evo.get(e, f2).x == 20 and evo.get(e, f2).y == 21)
            assert(evo.has(e, f3) and evo.get(e, f3).x == 10 and evo.get(e, f3).y == 11)
            assert(evo.has(e, f4) and evo.get(e, f4).x == 12 and evo.get(e, f4).y == 13)

            assert(evo.get(e, f1) ~= f1_default)
            assert(evo.get(e, f2) ~= f2_v and evo.get(e, f2) ~= f2_default)
            assert(evo.get(e, f3) ~= f3_default)
            assert(evo.get(e, f4) == f4_default)
        end

        assert(f5_set_sum == 0)
        assert(f5_insert_sum == 0)
        assert(f6_set_sum == 0)
        assert(f6_insert_sum == 0)
        assert(f7_set_sum == 0)
        assert(f7_insert_sum == 0)

        local f5_v = v2(30, 31)
        evo.batch_set(q_f1, f5, f5_v)

        assert(f5_set_sum == (30 + 31) * entity_count)
        assert(f5_insert_sum == (30 + 31) * entity_count)
        assert(f6_set_sum == (14 + 15) * entity_count)
        assert(f6_insert_sum == (14 + 15) * entity_count)
        assert(f7_set_sum == (16 + 17) * entity_count)
        assert(f7_insert_sum == (16 + 17) * entity_count)

        for i = 1, entity_count do
            local e = entity_list[i]

            assert(evo.has(e, f1) and evo.get(e, f1).x == 5 and evo.get(e, f1).y == 6)
            assert(evo.has(e, f2) and evo.get(e, f2).x == 20 and evo.get(e, f2).y == 21)
            assert(evo.has(e, f3) and evo.get(e, f3).x == 10 and evo.get(e, f3).y == 11)
            assert(evo.has(e, f4) and evo.get(e, f4).x == 12 and evo.get(e, f4).y == 13)
            assert(evo.has(e, f5) and evo.get(e, f5).x == 30 and evo.get(e, f5).y == 31)
            assert(evo.has(e, f6) and evo.get(e, f6).x == 14 and evo.get(e, f6).y == 15)
            assert(evo.has(e, f7) and evo.get(e, f7).x == 16 and evo.get(e, f7).y == 17)

            assert(evo.get(e, f1) ~= f1_default)
            assert(evo.get(e, f2) ~= f2_v and evo.get(e, f2) ~= f2_default)
            assert(evo.get(e, f3) ~= f3_default)
            assert(evo.get(e, f4) == f4_default)
            assert(evo.get(e, f5) ~= f5_v)
            assert(evo.get(e, f6) ~= f6_default)
            assert(evo.get(e, f7) == f7_default)
        end

        f5_set_sum = 0
        f5_insert_sum = 0
        f6_set_sum = 0
        f6_insert_sum = 0
        f7_set_sum = 0
        f7_insert_sum = 0

        f5_v = v2(32, 33)
        evo.batch_set(q_f1, f5, f5_v)

        assert(f5_set_sum == (32 + 33) * entity_count)
        assert(f5_insert_sum == 0)
        assert(f6_set_sum == 0)
        assert(f6_insert_sum == 0)
        assert(f7_set_sum == 0)
        assert(f7_insert_sum == 0)

        for i = 1, entity_count do
            local e = entity_list[i]

            assert(evo.has(e, f1) and evo.get(e, f1).x == 5 and evo.get(e, f1).y == 6)
            assert(evo.has(e, f2) and evo.get(e, f2).x == 20 and evo.get(e, f2).y == 21)
            assert(evo.has(e, f3) and evo.get(e, f3).x == 10 and evo.get(e, f3).y == 11)
            assert(evo.has(e, f4) and evo.get(e, f4).x == 12 and evo.get(e, f4).y == 13)
            assert(evo.has(e, f5) and evo.get(e, f5).x == 32 and evo.get(e, f5).y == 33)
            assert(evo.has(e, f6) and evo.get(e, f6).x == 14 and evo.get(e, f6).y == 15)
            assert(evo.has(e, f7) and evo.get(e, f7).x == 16 and evo.get(e, f7).y == 17)

            assert(evo.get(e, f1) ~= f1_default)
            assert(evo.get(e, f2) ~= f2_v and evo.get(e, f2) ~= f2_default)
            assert(evo.get(e, f3) ~= f3_default)
            assert(evo.get(e, f4) == f4_default)
            assert(evo.get(e, f5) ~= f5_v)
            assert(evo.get(e, f6) ~= f6_default)
            assert(evo.get(e, f7) == f7_default)
        end
    end
end

do
    local s1, s2 = evo.id(2)

    local process_order = ''

    evo.set(s1, evo.PROLOGUE, function()
        process_order = process_order .. '1'
    end)

    evo.set(s2, evo.PROLOGUE, function()
        process_order = process_order .. '2'
    end)

    do
        process_order = ''
        evo.set(s2, evo.GROUP, s1)
        evo.process(s1)
        assert(process_order == '12')
    end

    do
        process_order = ''
        evo.remove(s2, evo.GROUP)
        evo.process(s1)
        assert(process_order == '1')
    end
end

do
    local s1, s2, s3 = evo.id(3)

    local process_order = ''

    evo.set(s1, evo.PROLOGUE, function()
        process_order = process_order .. '1'
    end)

    evo.set(s2, evo.PROLOGUE, function()
        process_order = process_order .. '2'
    end)

    evo.set(s3, evo.PROLOGUE, function()
        process_order = process_order .. '3'
    end)

    do
        process_order = ''
        evo.set(s2, evo.GROUP, s1)
        evo.process(s1)
        assert(process_order == '12')
    end

    do
        process_order = ''
        evo.set(s2, evo.GROUP, s3)
        evo.process(s1)
        assert(process_order == '1')
        evo.process(s3)
        assert(process_order == '132')
    end
end

do
    local f1, f2 = evo.id(2)
    evo.set(f1, evo.NAME, 'f1')
    evo.set(f2, evo.NAME, 'f2')

    do
        local c1 = evo.chunk(f1)
        assert(tostring(c1) == '<f1>')

        local c2 = evo.chunk(f2)
        assert(tostring(c2) == '<f2>')

        local c12 = evo.chunk(f1, f2)
        assert(tostring(c12) == '<f1, f2>')

        local c21 = evo.chunk(f2, f1)
        assert(tostring(c21) == '<f1, f2>')
    end

    do
        local b = evo.builder():set(f1)
        assert(tostring(b) == '<f1>')

        b:set(f1, 1):set(f2, 2)
        assert(tostring(b) == '<f1, f2>')
    end
end
