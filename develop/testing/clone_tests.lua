local evo = require 'evolved'

evo.debug_mode(true)

do
    do
        local p = evo.spawn()
        local e = evo.clone(p)
        assert(evo.alive(e) and evo.empty(e))
    end

    do
        local p = evo.spawn()
        local e = evo.clone(p, {})
        assert(evo.alive(e) and evo.empty(e))
    end

    do
        local f1, f2 = evo.id(2)
        evo.set(f1, evo.REQUIRES, { f2 })
        evo.set(f2, evo.DEFAULT, 42)

        local p = evo.spawn()
        local e = evo.clone(p, { [f1] = 'hello' })
        assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f1, f2))
        assert(evo.has(e, f1) and evo.get(e, f1) == 'hello')
        assert(evo.has(e, f2) and evo.get(e, f2) == 42)
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)
    evo.set(f1, evo.TAG)
    evo.set(f1, evo.REQUIRES, { f2, f3 })
    evo.set(f4, evo.UNIQUE)

    do
        local p = evo.spawn { [f4] = 'unique' }
        local e = evo.clone(p)
        assert(evo.alive(e) and evo.empty(e))
    end

    do
        local p = evo.spawn { [f4] = 'unique' }
        local e = evo.clone(p, {})
        assert(evo.alive(e) and evo.empty(e))
    end

    do
        local p = evo.spawn { [f4] = 'unique' }
        local e = evo.clone(p, { [f4] = 'another' })
        assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f4))
        assert(evo.has(e, f4) and evo.get(e, f4) == 'another')
    end

    do
        local p = evo.spawn { [f2] = 100, [f4] = 'unique' }
        local e = evo.clone(p, { [f4] = 'another' })
        assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f2, f4))
        assert(evo.has(e, f2) and evo.get(e, f2) == 100)
        assert(evo.has(e, f4) and evo.get(e, f4) == 'another')
    end

    do
        local p = evo.spawn { [f2] = 100, [f4] = 'unique' }
        local e = evo.clone(p, { [f1] = 'hello', [f3] = 10 })
        assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f1, f2, f3))
        assert(evo.has(e, f1) and evo.get(e, f1) == nil)
        assert(evo.has(e, f2) and evo.get(e, f2) == 100)
        assert(evo.has(e, f3) and evo.get(e, f3) == 10)
    end
end

do
    do
        local f1, f2, f3, f4 = evo.id(4)
        evo.set(f4, evo.TAG)

        do
            local p = evo.spawn { [f2] = 21, [f3] = 'hello', [f4] = true }
            local e = evo.clone(p, { [f1] = 'world', [f2] = 10 })
            assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f1, f2, f3, f4))
            assert(evo.has(e, f1) and evo.get(e, f1) == 'world')
            assert(evo.has(e, f2) and evo.get(e, f2) == 10)
            assert(evo.has(e, f3) and evo.get(e, f3) == 'hello')
            assert(evo.has(e, f4) and evo.get(e, f4) == nil)
        end
    end

    do
        local f1, f2, f3, f4 = evo.id(4)
        evo.set(f2, evo.DEFAULT, 42)
        evo.set(f3, evo.DUPLICATE, function() return nil end)
        evo.set(f4, evo.TAG)

        do
            local p = evo.spawn { [f2] = 21, [f3] = 'hello', [f4] = true }
            local e = evo.clone(p, { [f1] = 'world', [f2] = 10 })
            assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f1, f2, f3, f4))
            assert(evo.has(e, f1) and evo.get(e, f1) == 'world')
            assert(evo.has(e, f2) and evo.get(e, f2) == 10)
            assert(evo.has(e, f3) and evo.get(e, f3) == true)
            assert(evo.has(e, f4) and evo.get(e, f4) == nil)
        end
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)
    evo.set(f1, evo.TAG)
    evo.set(f1, evo.REQUIRES, { f2, f3 })
    evo.set(f2, evo.DEFAULT, 42)
    evo.set(f2, evo.DUPLICATE, function(v) return v * 2 end)
    evo.set(f3, evo.DUPLICATE, function() return nil end)
    evo.set(f4, evo.UNIQUE)

    do
        local p = evo.spawn { [f4] = 'unique' }
        local e = evo.clone(p)
        assert(evo.alive(e) and evo.empty(e))
    end

    do
        local p = evo.spawn { [f4] = 'unique' }
        local e = evo.clone(p, {})
        assert(evo.alive(e) and evo.empty(e))
    end

    do
        local p = evo.spawn { [f4] = 'unique' }
        local e = evo.clone(p, { [f4] = 'another' })
        assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f4))
        assert(evo.has(e, f4) and evo.get(e, f4) == 'another')
    end

    do
        local p = evo.spawn { [f2] = 100, [f4] = 'unique' }
        local e = evo.clone(p, { [f4] = 'another' })
        assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f2, f4))
        assert(evo.has(e, f2) and evo.get(e, f2) == 200 * 2)
        assert(evo.has(e, f4) and evo.get(e, f4) == 'another')
    end

    do
        local p = evo.spawn { [f2] = 100, [f4] = 'unique' }
        local e = evo.clone(p, { [f1] = 'hello', [f2] = 10 })
        assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f1, f2, f3))
        assert(evo.has(e, f1) and evo.get(e, f1) == nil)
        assert(evo.has(e, f2) and evo.get(e, f2) == 10 * 2)
        assert(evo.has(e, f3) and evo.get(e, f3) == true)
    end

    local f1_set_count, f1_inserted_count = 0, 0
    local f2_set_sum, f3_inserted_count = 0, 0

    evo.set(f1, evo.ON_SET, function(e, f, c)
        assert(evo.get(e, f) == c)
        f1_set_count = f1_set_count + 1
    end)

    evo.set(f1, evo.ON_INSERT, function(e, f, c)
        assert(evo.get(e, f) == c)
        f1_inserted_count = f1_inserted_count + 1
    end)

    evo.set(f2, evo.ON_SET, function(e, f, c)
        assert(evo.get(e, f) == c)
        f2_set_sum = f2_set_sum + c
    end)

    evo.set(f3, evo.ON_INSERT, function(e, f, c)
        assert(evo.get(e, f) == c)
        f3_inserted_count = f3_inserted_count + 1
    end)

    do
        f1_set_count, f1_inserted_count = 0, 0
        f2_set_sum, f3_inserted_count = 0, 0

        local p = evo.spawn { [f2] = 100, [f4] = 'unique' }
        local e = evo.clone(p, { [f1] = 'hello', [f2] = 10 })
        assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f1, f2, f3))
        assert(evo.has(e, f1) and evo.get(e, f1) == nil)
        assert(evo.has(e, f2) and evo.get(e, f2) == 10 * 2)
        assert(evo.has(e, f3) and evo.get(e, f3) == true)

        assert(f1_set_count == 1)
        assert(f1_inserted_count == 1)
        assert(f2_set_sum == 100 * 2 + 10 * 2)
        assert(f3_inserted_count == 1)
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)
    evo.set(f1, evo.TAG)
    evo.set(f1, evo.REQUIRES, { f2, f3 })
    evo.set(f4, evo.UNIQUE)

    do
        local p = evo.spawn { [f4] = 'unique' }
        local es, ec = evo.multi_clone(1, p)
        assert(#es == 1 and ec == 1)
        for i = 1, ec do
            assert(evo.alive(es[i]) and evo.empty(es[i]))
        end
    end

    do
        local p = evo.spawn { [f4] = 'unique' }
        local es, ec = evo.multi_clone(2, p, {})
        assert(#es == 2 and ec == 2)
        for i = 1, ec do
            assert(evo.alive(es[i]) and evo.empty(es[i]))
        end
    end

    do
        local p = evo.spawn { [f4] = 'unique' }
        local es, ec = evo.multi_clone(3, p, { [f4] = 'another' })
        assert(#es == 3 and ec == 3)
        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f4))
            assert(evo.has(es[i], f4) and evo.get(es[i], f4) == 'another')
        end
    end

    do
        local p = evo.spawn { [f2] = 100, [f4] = 'unique' }
        local es, ec = evo.multi_clone(4, p, { [f4] = 'another' })
        assert(#es == 4 and ec == 4)
        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f2, f4))
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 100)
            assert(evo.has(es[i], f4) and evo.get(es[i], f4) == 'another')
        end
    end

    do
        local p = evo.spawn { [f2] = 100, [f4] = 'unique' }
        local es, ec = evo.multi_clone(5, p, { [f1] = 'hello', [f3] = 10 })
        assert(#es == 5 and ec == 5)
        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f1, f2, f3))
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == nil)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 100)
            assert(evo.has(es[i], f3) and evo.get(es[i], f3) == 10)
        end
    end
end

do
    do
        local f1, f2, f3, f4 = evo.id(4)
        evo.set(f4, evo.TAG)

        do
            local p = evo.spawn { [f2] = 21, [f3] = 'hello', [f4] = true }
            local es, ec = evo.multi_clone(2, p, { [f1] = 'world', [f2] = 10 })
            assert(#es == 2 and ec == 2)
            for i = 1, ec do
                assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f1, f2, f3, f4))
                assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 'world')
                assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 10)
                assert(evo.has(es[i], f3) and evo.get(es[i], f3) == 'hello')
                assert(evo.has(es[i], f4) and evo.get(es[i], f4) == nil)
            end
        end
    end

    do
        local f1, f2, f3, f4 = evo.id(4)
        evo.set(f2, evo.DEFAULT, 42)
        evo.set(f3, evo.DUPLICATE, function() return nil end)
        evo.set(f4, evo.TAG)

        do
            local p = evo.spawn { [f2] = 21, [f3] = 'hello', [f4] = true }
            local es, ec = evo.multi_clone(2, p, { [f1] = 'world', [f2] = 10 })
            assert(#es == 2 and ec == 2)
            for i = 1, ec do
                assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f1, f2, f3, f4))
                assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 'world')
                assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 10)
                assert(evo.has(es[i], f3) and evo.get(es[i], f3) == true)
                assert(evo.has(es[i], f4) and evo.get(es[i], f4) == nil)
            end
        end
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)
    evo.set(f1, evo.TAG)
    evo.set(f1, evo.REQUIRES, { f2, f3 })
    evo.set(f2, evo.DEFAULT, 42)
    evo.set(f2, evo.DUPLICATE, function(v) return v * 2 end)
    evo.set(f3, evo.DUPLICATE, function() return nil end)
    evo.set(f4, evo.UNIQUE)

    do
        local p = evo.spawn { [f4] = 'unique' }
        local es, ec = evo.multi_clone(3, p)
        assert(#es == 3 and ec == 3)

        for i = 1, ec do
            assert(evo.alive(es[i]) and evo.empty(es[i]))
        end
    end

    do
        local p = evo.spawn { [f4] = 'unique' }
        local es, ec = evo.multi_clone(3, p, {})
        assert(#es == 3 and ec == 3)

        for i = 1, ec do
            assert(evo.alive(es[i]) and evo.empty(es[i]))
        end
    end

    do
        local p = evo.spawn { [f4] = 'unique' }
        local es, ec = evo.multi_clone(2, p, { [f4] = 'another' })
        assert(#es == 2 and ec == 2)

        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f4))
            assert(evo.has(es[i], f4) and evo.get(es[i], f4) == 'another')
        end
    end

    do
        local p = evo.spawn { [f2] = 100, [f4] = 'unique' }
        local es, ec = evo.multi_clone(4, p, { [f4] = 'another' })
        assert(#es == 4 and ec == 4)

        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f2, f4))
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 200 * 2)
            assert(evo.has(es[i], f4) and evo.get(es[i], f4) == 'another')
        end
    end

    do
        local p = evo.spawn { [f2] = 100, [f4] = 'unique' }
        local es, ec = evo.multi_clone(5, p, { [f1] = 'hello', [f2] = 10 })
        assert(#es == 5 and ec == 5)

        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f1, f2, f3))
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == nil)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 10 * 2)
            assert(evo.has(es[i], f3) and evo.get(es[i], f3) == true)
        end
    end

    local f1_set_count, f1_inserted_count = 0, 0
    local f2_set_sum, f3_inserted_count = 0, 0

    evo.set(f1, evo.ON_SET, function(e, f, c)
        assert(evo.get(e, f) == c)
        f1_set_count = f1_set_count + 1
    end)

    evo.set(f1, evo.ON_INSERT, function(e, f, c)
        assert(evo.get(e, f) == c)
        f1_inserted_count = f1_inserted_count + 1
    end)

    evo.set(f2, evo.ON_SET, function(e, f, c)
        assert(evo.get(e, f) == c)
        f2_set_sum = f2_set_sum + c
    end)

    evo.set(f3, evo.ON_INSERT, function(e, f, c)
        assert(evo.get(e, f) == c)
        f3_inserted_count = f3_inserted_count + 1
    end)

    do
        f1_set_count, f1_inserted_count = 0, 0
        f2_set_sum, f3_inserted_count = 0, 0

        local p = evo.spawn { [f2] = 100, [f4] = 'unique' }
        local es, ec = evo.multi_clone(1, p, { [f1] = 'hello', [f2] = 10 })

        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f1, f2, f3))
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == nil)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 10 * 2)
            assert(evo.has(es[i], f3) and evo.get(es[i], f3) == true)

            assert(f1_set_count == 1)
            assert(f1_inserted_count == 1)
            assert(f2_set_sum == 100 * 2 + 10 * 2)
            assert(f3_inserted_count == 1)
        end
    end
end

do
    local f1, f2 = evo.id(2)
    local p = evo.spawn { [f1] = 42, [f2] = 'hello' }

    do
        local entity_list, entity_count = {}, 2
        evo.multi_clone_to(entity_list, 1, entity_count, p)
        assert(evo.has_all(entity_list[1], f1, f2))
        assert(evo.has_all(entity_list[2], f1, f2))
        assert(evo.get(entity_list[1], f1) == 42 and evo.get(entity_list[1], f2) == 'hello')
        assert(evo.get(entity_list[2], f1) == 42 and evo.get(entity_list[2], f2) == 'hello')
    end

    do
        local entity_list, entity_count = {}, 2
        evo.multi_clone_to(entity_list, 2, entity_count, p)
        assert(evo.has_all(entity_list[2], f1, f2))
        assert(evo.has_all(entity_list[3], f1, f2))
        assert(evo.get(entity_list[2], f1) == 42 and evo.get(entity_list[2], f2) == 'hello')
        assert(evo.get(entity_list[3], f1) == 42 and evo.get(entity_list[3], f2) == 'hello')
    end

    do
        local entity_list, entity_count = {}, 2
        evo.defer()
        evo.multi_clone_to(entity_list, 1, entity_count, p)
        assert(entity_list[1] and entity_list[2])
        assert(evo.empty_all(entity_list[1], entity_list[2]))
        evo.commit()
        assert(evo.has_all(entity_list[1], f1, f2))
        assert(evo.has_all(entity_list[2], f1, f2))
        assert(evo.get(entity_list[1], f1) == 42 and evo.get(entity_list[1], f2) == 'hello')
        assert(evo.get(entity_list[2], f1) == 42 and evo.get(entity_list[2], f2) == 'hello')
    end

    do
        local entity_list, entity_count = {}, 2
        evo.defer()
        evo.multi_clone_to(entity_list, 2, entity_count, p)
        assert(entity_list[2] and entity_list[3])
        assert(evo.empty_all(entity_list[2], entity_list[3]))
        evo.commit()
        assert(evo.has_all(entity_list[2], f1, f2))
        assert(evo.has_all(entity_list[3], f1, f2))
        assert(evo.get(entity_list[2], f1) == 42 and evo.get(entity_list[2], f2) == 'hello')
        assert(evo.get(entity_list[3], f1) == 42 and evo.get(entity_list[3], f2) == 'hello')
    end
end

do
    local f1, f2 = evo.id(2)
    local q12 = evo.builder():include(f1, f2):build()
    local p = evo.spawn { [f1] = 42, [f2] = 'hello' }

    do
        assert(select('#', evo.multi_clone_nr(2, p)) == 0)

        do
            local entity_count = 0

            for chunk in evo.execute(q12) do
                local _, chunk_entity_count = chunk:entities()
                entity_count = entity_count + chunk_entity_count
            end

            assert(entity_count == 3)
        end
    end

    do
        local b = evo.builder():set(f1, 42):set(f2, 'hello')

        assert(select('#', b:multi_clone_nr(2, p)) == 0)

        do
            local entity_count = 0

            for chunk in evo.execute(q12) do
                local _, chunk_entity_count = chunk:entities()
                entity_count = entity_count + chunk_entity_count
            end

            assert(entity_count == 5)
        end
    end

    do
        local b = evo.builder():set(f1, 42):set(f2, 'hello')

        assert(select('#', b:multi_build_nr(2, p)) == 0)

        do
            local entity_count = 0

            for chunk in evo.execute(q12) do
                local _, chunk_entity_count = chunk:entities()
                entity_count = entity_count + chunk_entity_count
            end

            assert(entity_count == 7)
        end
    end
end

do
    local f1, f2 = evo.id(2)
    local q12 = evo.builder():include(f1, f2):build()
    local p = evo.spawn { [f1] = 42, [f2] = 'hello' }

    do
        local entity_list = {}
        assert(select('#', evo.multi_clone_to(entity_list, 1, 2, p)) == 0)

        do
            local entity_count = 0

            for chunk in evo.execute(q12) do
                local _, chunk_entity_count = chunk:entities()
                entity_count = entity_count + chunk_entity_count
            end

            assert(entity_count == 3)
        end
    end

    do
        local b = evo.builder():set(f1, 42):set(f2, 'hello')

        local entity_list = {}
        assert(select('#', b:multi_clone_to(entity_list, 1, 2, p)) == 0)

        do
            local entity_count = 0

            for chunk in evo.execute(q12) do
                local _, chunk_entity_count = chunk:entities()
                entity_count = entity_count + chunk_entity_count
            end

            assert(entity_count == 5)
        end
    end

    do
        local b = evo.builder():set(f1, 42):set(f2, 'hello')

        local entity_list = {}
        assert(select('#', b:multi_build_to(entity_list, 1, 2, p)) == 0)

        do
            local entity_count = 0

            for chunk in evo.execute(q12) do
                local _, chunk_entity_count = chunk:entities()
                entity_count = entity_count + chunk_entity_count
            end

            assert(entity_count == 7)
        end
    end
end
