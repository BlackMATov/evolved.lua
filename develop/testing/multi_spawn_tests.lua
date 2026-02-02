local evo = require 'evolved'

evo.debug_mode(true)

do
    local entity_list

    do
        entity_list = evo.multi_spawn(0)
        assert(entity_list and #entity_list == 0)

        entity_list = evo.multi_spawn(0, {})
        assert(entity_list and #entity_list == 0)
    end

    do
        entity_list = evo.multi_spawn(-1)
        assert(entity_list and #entity_list == 0)

        entity_list = evo.multi_spawn(-1, {})
        assert(entity_list and #entity_list == 0)
    end

    do
        entity_list = evo.builder():multi_spawn(0)
        assert(entity_list and #entity_list == 0)
    end

    do
        entity_list = evo.builder():multi_spawn(-1)
        assert(entity_list and #entity_list == 0)
    end
end

do
    local entity_list

    do
        entity_list = evo.multi_spawn(1)
        assert(entity_list and #entity_list == 1)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(not entity_list[2])

        entity_list = evo.multi_spawn(1, {})
        assert(entity_list and #entity_list == 1)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(not entity_list[2])
    end

    do
        entity_list = evo.multi_spawn(2)
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(entity_list[2] and evo.empty(entity_list[2]))
        assert(not entity_list[3])

        entity_list = evo.multi_spawn(2, {})
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(entity_list[2] and evo.empty(entity_list[2]))
        assert(not entity_list[3])
    end

    do
        entity_list = evo.builder():multi_spawn(1)
        assert(entity_list and #entity_list == 1)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(not entity_list[2])
    end

    do
        entity_list = evo.builder():multi_spawn(2)
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(entity_list[2] and evo.empty(entity_list[2]))
        assert(not entity_list[3])
    end
end

do
    local entity_list

    local prefab = evo.id()

    do
        entity_list = evo.multi_clone(0, prefab)
        assert(entity_list and #entity_list == 0)

        entity_list = evo.multi_clone(0, prefab, {})
        assert(entity_list and #entity_list == 0)
    end

    do
        entity_list = evo.multi_clone(-1, prefab)
        assert(entity_list and #entity_list == 0)

        entity_list = evo.multi_clone(-1, prefab, {})
        assert(entity_list and #entity_list == 0)
    end

    do
        entity_list = evo.builder():multi_clone(0, prefab)
        assert(entity_list and #entity_list == 0)
    end

    do
        entity_list = evo.builder():multi_clone(-1, prefab)
        assert(entity_list and #entity_list == 0)
    end
end

do
    local entity_list

    local prefab = evo.id()

    do
        entity_list = evo.multi_clone(1, prefab)
        assert(entity_list and #entity_list == 1)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(not entity_list[2])

        entity_list = evo.multi_clone(1, prefab, {})
        assert(entity_list and #entity_list == 1)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(not entity_list[2])
    end

    do
        entity_list = evo.multi_clone(2, prefab)
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(entity_list[2] and evo.empty(entity_list[2]))
        assert(not entity_list[3])

        entity_list = evo.multi_clone(2, prefab, {})
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(entity_list[2] and evo.empty(entity_list[2]))
        assert(not entity_list[3])
    end

    do
        entity_list = evo.builder():multi_clone(1, prefab)
        assert(entity_list and #entity_list == 1)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(not entity_list[2])
    end

    do
        entity_list = evo.builder():multi_clone(2, prefab)
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.empty(entity_list[1]))
        assert(entity_list[2] and evo.empty(entity_list[2]))
        assert(not entity_list[3])
    end
end

do
    local f1, f2 = evo.id(2)

    do
        local entity_list

        entity_list = evo.multi_spawn(2, { [f1] = true, [f2] = 123 })
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.get(entity_list[1], f1) == true and evo.get(entity_list[1], f2) == 123)
        assert(entity_list[2] and evo.get(entity_list[2], f1) == true and evo.get(entity_list[2], f2) == 123)

        entity_list = evo.multi_spawn(2, { [f1] = false, [f2] = 456 })
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.get(entity_list[1], f1) == false and evo.get(entity_list[1], f2) == 456)
        assert(entity_list[2] and evo.get(entity_list[2], f1) == false and evo.get(entity_list[2], f2) == 456)
    end

    do
        local prefab = evo.builder():set(f1, true):set(f2, 123):spawn()

        local entity_list

        entity_list = evo.multi_clone(2, prefab)
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.get(entity_list[1], f1) == true and evo.get(entity_list[1], f2) == 123)
        assert(entity_list[2] and evo.get(entity_list[2], f1) == true and evo.get(entity_list[2], f2) == 123)

        entity_list = evo.multi_clone(2, prefab, {})
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.get(entity_list[1], f1) == true and evo.get(entity_list[1], f2) == 123)
        assert(entity_list[2] and evo.get(entity_list[2], f1) == true and evo.get(entity_list[2], f2) == 123)

        entity_list = evo.multi_clone(2, prefab, { [f1] = false, [f2] = 456 })
        assert(entity_list and #entity_list == 2)
        assert(entity_list[1] and evo.get(entity_list[1], f1) == false and evo.get(entity_list[1], f2) == 456)
        assert(entity_list[2] and evo.get(entity_list[2], f1) == false and evo.get(entity_list[2], f2) == 456)
    end
end

do
    local f1, f2, f3 = evo.id(3)

    do
        local entity_list1, entity_list2

        evo.defer()
        do
            entity_list1 = evo.multi_spawn(2, { [f1] = 42, [f2] = "hello", [f3] = false })
            assert(entity_list1 and #entity_list1 == 2)
            assert(entity_list1[1] and evo.empty(entity_list1[1]))
            assert(entity_list1[2] and evo.empty(entity_list1[2]))
            assert(not entity_list1[3])

            entity_list2 = evo.multi_spawn(3, { [f2] = "world", [f3] = true })
            assert(entity_list2 and #entity_list2 == 3)
            assert(entity_list2[1] and evo.empty(entity_list2[1]))
            assert(entity_list2[2] and evo.empty(entity_list2[2]))
            assert(entity_list2[3] and evo.empty(entity_list2[3]))
        end
        evo.commit()
        do
            assert(entity_list1 and #entity_list1 == 2)
            assert(entity_list1[1] and not evo.empty(entity_list1[1]))
            assert(entity_list1[2] and not evo.empty(entity_list1[2]))
            assert(not entity_list1[3])
            assert(
                evo.get(entity_list1[1], f1) == 42 and
                evo.get(entity_list1[1], f2) == "hello" and
                evo.get(entity_list1[1], f3) == false)
            assert(
                evo.get(entity_list1[2], f1) == 42 and
                evo.get(entity_list1[2], f2) == "hello" and
                evo.get(entity_list1[2], f3) == false)

            assert(entity_list2 and #entity_list2 == 3)
            assert(entity_list2[1] and not evo.empty(entity_list2[1]))
            assert(entity_list2[2] and not evo.empty(entity_list2[2]))
            assert(entity_list2[3] and not evo.empty(entity_list2[3]))
            assert(not entity_list2[4])
            assert(
                evo.get(entity_list2[1], f1) == nil and
                evo.get(entity_list2[1], f2) == "world" and
                evo.get(entity_list2[1], f3) == true)
            assert(
                evo.get(entity_list2[2], f1) == nil and
                evo.get(entity_list2[2], f2) == "world" and
                evo.get(entity_list2[2], f3) == true)
            assert(
                evo.get(entity_list2[3], f1) == nil and
                evo.get(entity_list2[3], f2) == "world" and
                evo.get(entity_list2[3], f3) == true)
        end
    end
end

do
    local f1, f2, f3 = evo.id(3)

    do
        local prefab = evo.builder():set(f1, false):set(f2, 123):spawn()

        local entity_list1, entity_list2

        evo.defer()
        do
            entity_list1 = evo.multi_clone(2, prefab)
            assert(entity_list1 and #entity_list1 == 2)
            assert(entity_list1[1] and evo.empty(entity_list1[1]))
            assert(entity_list1[2] and evo.empty(entity_list1[2]))
            assert(not entity_list1[3])

            entity_list2 = evo.multi_clone(3, prefab, { [f2] = 456, [f3] = "world" })
            assert(entity_list2 and #entity_list2 == 3)
            assert(entity_list2[1] and evo.empty(entity_list2[1]))
            assert(entity_list2[2] and evo.empty(entity_list2[2]))
            assert(entity_list2[3] and evo.empty(entity_list2[3]))
        end
        evo.commit()
        do
            assert(entity_list1 and #entity_list1 == 2)
            assert(entity_list1[1] and not evo.empty(entity_list1[1]))
            assert(entity_list1[2] and not evo.empty(entity_list1[2]))
            assert(not entity_list1[3])
            assert(
                evo.get(entity_list1[1], f1) == false and
                evo.get(entity_list1[1], f2) == 123 and
                evo.get(entity_list1[1], f3) == nil)
            assert(
                evo.get(entity_list1[2], f1) == false and
                evo.get(entity_list1[2], f2) == 123 and
                evo.get(entity_list1[2], f3) == nil)

            assert(entity_list2 and #entity_list2 == 3)
            assert(entity_list2[1] and not evo.empty(entity_list2[1]))
            assert(entity_list2[2] and not evo.empty(entity_list2[2]))
            assert(entity_list2[3] and not evo.empty(entity_list2[3]))
            assert(not entity_list2[4])
            assert(
                evo.get(entity_list2[1], f1) == false and
                evo.get(entity_list2[1], f2) == 456 and
                evo.get(entity_list2[1], f3) == "world")
            assert(
                evo.get(entity_list2[2], f1) == false and
                evo.get(entity_list2[2], f2) == 456 and
                evo.get(entity_list2[2], f3) == "world")
            assert(
                evo.get(entity_list2[3], f1) == false and
                evo.get(entity_list2[3], f2) == 456 and
                evo.get(entity_list2[3], f3) == "world")
        end
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f1, evo.REQUIRES, { f2, f3 })
    evo.set(f3, evo.TAG)

    do
        local entity_list, entity_count = evo.multi_spawn(2, { [f1] = 42 })

        assert(entity_list and #entity_list == 2)
        assert(entity_count == 2)

        for i = 1, entity_count do
            local e = entity_list[i]
            assert(e and not evo.empty(e))

            assert(evo.has(e, f1) and evo.get(e, f1) == 42)
            assert(evo.has(e, f2) and evo.get(e, f2) == true)
            assert(evo.has(e, f3) and evo.get(e, f3) == nil)
        end
    end

    do
        local entity_prefab = evo.builder():set(f1, 42):spawn()

        local clone_list, clone_count = evo.multi_clone(2, entity_prefab)

        assert(clone_list and #clone_list == 2)
        assert(clone_count == 2)

        for i = 1, clone_count do
            local e = clone_list[i]
            assert(e and not evo.empty(e))

            assert(evo.has(e, f1) and evo.get(e, f1) == 42)
            assert(evo.has(e, f2) and evo.get(e, f2) == true)
            assert(evo.has(e, f3) and evo.get(e, f3) == nil)
        end
    end

    do
        local entity_prefab = evo.builder():set(f1, 42):spawn()
        evo.remove(entity_prefab, f2, f3)

        local clone_list, clone_count = evo.multi_clone(2, entity_prefab, { [f1] = 21 })

        assert(clone_list and #clone_list == 2)
        assert(clone_count == 2)

        for i = 1, clone_count do
            local e = clone_list[i]
            assert(e and not evo.empty(e))

            assert(evo.has(e, f1) and evo.get(e, f1) == 21)
            assert(evo.has(e, f2) and evo.get(e, f2) == true)
            assert(evo.has(e, f3) and evo.get(e, f3) == nil)
        end
    end

    evo.set(f2, evo.DEFAULT, false)

    do
        local entity_list, entity_count = evo.multi_spawn(2, { [f1] = 42 })

        assert(entity_list and #entity_list == 2)
        assert(entity_count == 2)

        for i = 1, entity_count do
            local e = entity_list[i]
            assert(e and not evo.empty(e))

            assert(evo.has(e, f1) and evo.get(e, f1) == 42)
            assert(evo.has(e, f2) and evo.get(e, f2) == false)
            assert(evo.has(e, f3) and evo.get(e, f3) == nil)
        end
    end

    do
        local entity_prefab = evo.builder():set(f1, 42):spawn()

        local clone_list, clone_count = evo.multi_clone(2, entity_prefab)

        assert(clone_list and #clone_list == 2)
        assert(clone_count == 2)

        for i = 1, clone_count do
            local e = clone_list[i]
            assert(e and not evo.empty(e))

            assert(evo.has(e, f1) and evo.get(e, f1) == 42)
            assert(evo.has(e, f2) and evo.get(e, f2) == false)
            assert(evo.has(e, f3) and evo.get(e, f3) == nil)
        end
    end

    do
        local entity_prefab = evo.builder():set(f1, 42):spawn()
        evo.remove(entity_prefab, f2, f3)

        local clone_list, clone_count = evo.multi_clone(2, entity_prefab, { [f1] = 21 })

        assert(clone_list and #clone_list == 2)
        assert(clone_count == 2)

        for i = 1, clone_count do
            local e = clone_list[i]
            assert(e and not evo.empty(e))

            assert(evo.has(e, f1) and evo.get(e, f1) == 21)
            assert(evo.has(e, f2) and evo.get(e, f2) == false)
            assert(evo.has(e, f3) and evo.get(e, f3) == nil)
        end
    end

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
        local entity_list, entity_count = evo.multi_spawn(2, { [f1] = 42 })

        assert(entity_list and #entity_list == 2)
        assert(entity_count == 2)

        for i = 1, entity_count do
            local e = entity_list[i]
            assert(e and not evo.empty(e))

            assert(evo.has(e, f1) and evo.get(e, f1) == 42)
            assert(evo.has(e, f2) and evo.get(e, f2) == false)
        end
    end

    do
        local entity_prefab = evo.builder():set(f1, 42):spawn()

        local clone_list, clone_count = evo.multi_clone(2, entity_prefab)

        assert(clone_list and #clone_list == 2)
        assert(clone_count == 2)

        for i = 1, clone_count do
            local e = clone_list[i]
            assert(e and not evo.empty(e))

            assert(evo.has(e, f1) and evo.get(e, f1) == 42)
            assert(evo.has(e, f2) and evo.get(e, f2) == false)
        end
    end

    do
        local entity_prefab = evo.builder():set(f1, 42):spawn()
        evo.remove(entity_prefab, f2, f3)

        local clone_list, clone_count = evo.multi_clone(2, entity_prefab, { [f1] = 21 })

        assert(clone_list and #clone_list == 2)
        assert(clone_count == 2)

        for i = 1, clone_count do
            local e = clone_list[i]
            assert(e and not evo.empty(e))

            assert(evo.has(e, f1) and evo.get(e, f1) == 21)
            assert(evo.has(e, f2) and evo.get(e, f2) == false)
        end
    end

    assert(v_set_sum == 42 * 6 + 21 * 2)
    assert(v_insert_sum == 42 * 6 + 21 * 2)

    assert(f3_set_times == 8)
    assert(f3_insert_times == 8)
end

do
    local function v2(x, y) return { x = x or 0, y = y or 0 } end
    local function v2_clone(v) return { x = v.x, y = v.y } end

    local f1, f2, f3, f4 = evo.id(4)
    evo.set(f1, evo.REQUIRES, { f2, f3, f4 })

    local f1_default = v2(1, 2)
    local f2_default = v2(3, 4)
    local f3_default = v2(10, 11)
    local f4_default = v2(12, 13)

    evo.set(f1, evo.DEFAULT, f1_default)
    evo.set(f2, evo.DEFAULT, f2_default)
    evo.set(f3, evo.DEFAULT, f3_default)
    evo.set(f4, evo.DEFAULT, f4_default)

    evo.set(f1, evo.DUPLICATE, v2_clone)
    evo.set(f2, evo.DUPLICATE, v2_clone)
    evo.set(f3, evo.DUPLICATE, v2_clone)

    do
        local entity_list, entity_count = evo.multi_spawn(2, { [f1] = v2(5, 6), [f2] = v2(7, 8) })

        assert(entity_list and #entity_list == 2)
        assert(entity_count == 2)

        for i = 1, entity_count do
            local e = entity_list[i]
            assert(e and not evo.empty(e))

            assert(evo.has(e, f1) and evo.get(e, f1) ~= f1_default)
            assert(evo.get(e, f1).x == 5 and evo.get(e, f1).y == 6)

            assert(evo.has(e, f2) and evo.get(e, f2) ~= f2_default)
            assert(evo.get(e, f2).x == 7 and evo.get(e, f2).y == 8)

            assert(evo.has(e, f3) and evo.get(e, f3) ~= f3_default)
            assert(evo.get(e, f3).x == 10 and evo.get(e, f3).y == 11)

            assert(evo.has(e, f4) and evo.get(e, f4) == f4_default)
        end
    end

    do
        local entity_prefab = evo.builder():set(f1, v2(5, 6)):set(f2, v2(7, 8)):spawn()

        local clone_list, clone_count = evo.multi_clone(2, entity_prefab, { [f2] = f2_default })

        assert(clone_list and #clone_list == 2)
        assert(clone_count == 2)

        for i = 1, clone_count do
            local e = clone_list[i]
            assert(e and not evo.empty(e))

            assert(evo.has(e, f1) and evo.get(e, f1) ~= f1_default and evo.get(e, f1) ~= evo.get(entity_prefab, f1))
            assert(evo.get(e, f1).x == 5 and evo.get(e, f1).y == 6)

            assert(evo.has(e, f2) and evo.get(e, f2) ~= f2_default and evo.get(e, f2) ~= evo.get(entity_prefab, f2))
            assert(evo.get(e, f2).x == 3 and evo.get(e, f2).y == 4)

            assert(evo.has(e, f3) and evo.get(e, f3) ~= f3_default)
            assert(evo.get(e, f3).x == 10 and evo.get(e, f3).y == 11)

            assert(evo.has(e, f4) and evo.get(e, f4) == f4_default)
        end
    end

    do
        local entity_prefab = evo.builder():set(f1, v2(5, 6)):set(f2, v2(7, 8)):spawn()
        evo.remove(entity_prefab, f2, f3, f4)

        local clone_list, clone_count = evo.multi_clone(2, entity_prefab, { [f2] = f2_default })

        assert(clone_list and #clone_list == 2)
        assert(clone_count == 2)

        for i = 1, clone_count do
            local e = clone_list[i]
            assert(e and not evo.empty(e))

            assert(evo.has(e, f1) and evo.get(e, f1) ~= f1_default and evo.get(e, f1) ~= evo.get(entity_prefab, f1))
            assert(evo.get(e, f1).x == 5 and evo.get(e, f1).y == 6)

            assert(evo.has(e, f2) and evo.get(e, f2) ~= f2_default and evo.get(e, f2) ~= evo.get(entity_prefab, f2))
            assert(evo.get(e, f2).x == 3 and evo.get(e, f2).y == 4)

            assert(evo.has(e, f3) and evo.get(e, f3) ~= f3_default)
            assert(evo.get(e, f3).x == 10 and evo.get(e, f3).y == 11)

            assert(evo.has(e, f4) and evo.get(e, f4) == f4_default)
        end
    end
end
