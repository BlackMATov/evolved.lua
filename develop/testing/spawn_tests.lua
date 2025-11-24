local evo = require 'evolved'

do
    do
        local e = evo.spawn()
        assert(evo.alive(e) and evo.empty(e))
    end

    do
        local e = evo.spawn({})
        assert(evo.alive(e) and evo.empty(e))
    end
end

do
    local f1, f2, f3 = evo.id(3)
    evo.set(f2, evo.REQUIRES, { f1, f3 })

    do
        local e = evo.spawn({ [f1] = 42 })
        assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f1))
        assert(evo.has(e, f1) and evo.get(e, f1) == 42)
    end

    do
        local e = evo.spawn({ [f1] = 42, [f2] = 'hello' })
        assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f1, f2, f3))
        assert(evo.has(e, f1) and evo.get(e, f1) == 42)
        assert(evo.has(e, f2) and evo.get(e, f2) == 'hello')
        assert(evo.has(e, f3) and evo.get(e, f3) == true)
    end
end

do
    local f1, f2, f3 = evo.id(3)
    evo.set(f2, evo.REQUIRES, { f1, f3 })
    evo.set(f3, evo.DEFAULT, 21)
    evo.set(f3, evo.REQUIRES, { f2 })

    do
        local e = evo.spawn({ [f1] = 42 })
        assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f1))
        assert(evo.has(e, f1) and evo.get(e, f1) == 42)
    end

    do
        local e = evo.spawn({ [f1] = 42, [f2] = 'hello' })
        assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f1, f2, f3))
        assert(evo.has(e, f1) and evo.get(e, f1) == 42)
        assert(evo.has(e, f2) and evo.get(e, f2) == 'hello')
        assert(evo.has(e, f3) and evo.get(e, f3) == 21)
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)
    evo.set(f2, evo.DUPLICATE, function() return nil end)
    evo.set(f2, evo.REQUIRES, { f1, f3, f4 })
    evo.set(f3, evo.DEFAULT, 21)
    evo.set(f3, evo.DUPLICATE, function(v) return v * 3 end)
    evo.set(f3, evo.REQUIRES, { f2 })

    do
        local e = evo.spawn({ [f1] = 42 })
        assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f1))
        assert(evo.has(e, f1) and evo.get(e, f1) == 42)
    end

    do
        local e = evo.spawn({ [f1] = 42, [f2] = true })
        assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f1, f2, f3, f4))
        assert(evo.has(e, f1) and evo.get(e, f1) == 42)
        assert(evo.has(e, f2) and evo.get(e, f2) == true)
        assert(evo.has(e, f3) and evo.get(e, f3) == 21 * 3)
        assert(evo.has(e, f4) and evo.get(e, f4) == true)
    end
end

do
    local f1, f2, f3 = evo.id(3)
    evo.set(f2, evo.REQUIRES, { f3 })
    evo.set(f3, evo.TAG)

    local f2_set_sum, f2_inserted_sum = 0, 0
    local f3_set_count, f3_inserted_count = 0, 0

    evo.set(f2, evo.ON_SET, function(e, f, c)
        assert(c == 42)
        assert(evo.get(e, f) == c)
        assert(f == f2)
        f2_set_sum = f2_set_sum + c
    end)

    evo.set(f2, evo.ON_INSERT, function(e, f, c)
        assert(c == 42)
        assert(evo.get(e, f) == c)
        assert(f == f2)
        f2_inserted_sum = f2_inserted_sum + c
    end)

    evo.set(f3, evo.ON_SET, function(e, f, c)
        assert(c == nil)
        assert(evo.get(e, f) == c)
        assert(f == f3)
        f3_set_count = f3_set_count + 1
    end)

    evo.set(f3, evo.ON_INSERT, function(e, f, c)
        assert(c == nil)
        assert(evo.get(e, f) == c)
        assert(f == f3)
        f3_inserted_count = f3_inserted_count + 1
    end)

    do
        f3_set_count, f3_inserted_count = 0, 0
        local e = evo.spawn({ [f1] = 'hello', [f2] = 42 })
        assert(evo.alive(e) and not evo.empty(e) and evo.locate(e) == evo.chunk(f1, f2, f3))
        assert(f2_set_sum == 42 and f2_inserted_sum == 42)
        assert(f3_set_count == 1 and f3_inserted_count == 1)
    end
end

do
    do
        local es, ec = evo.multi_spawn(2)
        assert(#es == 2 and ec == 2)

        for i = 1, ec do
            assert(evo.alive(es[i]) and evo.empty(es[i]))
        end
    end

    do
        local es, ec = evo.multi_spawn(2, {})
        assert(#es == 2 and ec == 2)

        for i = 1, ec do
            assert(evo.alive(es[i]) and evo.empty(es[i]))
        end
    end
end

do
    local f1, f2 = evo.id(2)

    do
        local es, ec = evo.multi_spawn(3, { [f1] = 42 })
        assert(#es == 3 and ec == 3)

        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f1))
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 42)
        end
    end

    do
        local es, ec = evo.multi_spawn(3, { [f1] = 42, [f2] = 'hello' })
        assert(#es == 3 and ec == 3)

        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f1, f2))
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 42)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 'hello')
        end
    end
end

do
    local f1, f2 = evo.id(2)
    evo.set(f1, evo.REQUIRES, { f2 })

    do
        local es, ec = evo.multi_spawn(3, { [f1] = 42 })
        assert(#es == 3 and ec == 3)

        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f1, f2))
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 42)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == true)
        end
    end
end

do
    local f1, f2 = evo.id(2)
    evo.set(f1, evo.REQUIRES, { f2 })

    do
        local es, ec = evo.multi_spawn(1, { [f1] = 42 })
        assert(#es == 1 and ec == 1)

        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f1, f2))
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 42)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == true)
        end
    end
end

do
    local f1, f2, f3 = evo.id(3)
    evo.set(f1, evo.REQUIRES, { f2, f3 })
    evo.set(f2, evo.DEFAULT, 'hello')

    do
        local es, ec = evo.multi_spawn(4, { [f1] = 42 })
        assert(#es == 4 and ec == 4)

        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f1, f2, f3))
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 42)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 'hello')
            assert(evo.has(es[i], f3) and evo.get(es[i], f3) == true)
        end
    end

    do
        local es, ec = evo.multi_spawn(4, { [f1] = 42, [f2] = 'world' })
        assert(#es == 4 and ec == 4)

        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f1, f2, f3))
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 42)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 'world')
            assert(evo.has(es[i], f3) and evo.get(es[i], f3) == true)
        end
    end

    do
        local es, ec = evo.multi_spawn(4, { [f1] = 42, [f2] = 'world', [f3] = false })
        assert(#es == 4 and ec == 4)

        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f1, f2, f3))
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 42)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 'world')
            assert(evo.has(es[i], f3) and evo.get(es[i], f3) == false)
        end
    end
end

do
    local f1, f2 = evo.id(2)
    evo.set(f1, evo.REQUIRES, { f2 })
    evo.set(f1, evo.DUPLICATE, function() return nil end)
    evo.set(f2, evo.DEFAULT, 'hello')
    evo.set(f2, evo.DUPLICATE, function(v) return v .. '!' end)

    do
        local es, ec = evo.multi_spawn(4, { [f1] = 42 })
        assert(#es == 4 and ec == 4)

        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f1, f2))
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == true)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 'hello!')
        end
    end

    do
        local es, ec = evo.multi_spawn(4, { [f1] = 42, [f2] = 'world' })
        assert(#es == 4 and ec == 4)

        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f1, f2))
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == true)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 'world!')
        end
    end

    do
        local es, ec = evo.multi_spawn(4, { [f2] = 'hello world' })
        assert(#es == 4 and ec == 4)

        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f2))
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 'hello world!')
        end
    end
end

do
    local f1, f2, f3 = evo.id(3)
    evo.set(f2, evo.REQUIRES, { f3 })
    evo.set(f3, evo.TAG)

    local f2_set_sum, f2_inserted_sum = 0, 0
    local f3_set_count, f3_inserted_count = 0, 0

    evo.set(f2, evo.ON_SET, function(e, f, c)
        assert(c == 42)
        assert(evo.get(e, f) == c)
        assert(f == f2)
        f2_set_sum = f2_set_sum + c
    end)

    evo.set(f2, evo.ON_INSERT, function(e, f, c)
        assert(c == 42)
        assert(evo.get(e, f) == c)
        assert(f == f2)
        f2_inserted_sum = f2_inserted_sum + c
    end)

    evo.set(f3, evo.ON_SET, function(e, f, c)
        assert(c == nil)
        assert(evo.get(e, f) == c)
        assert(f == f3)
        f3_set_count = f3_set_count + 1
    end)

    evo.set(f3, evo.ON_INSERT, function(e, f, c)
        assert(c == nil)
        assert(evo.get(e, f) == c)
        assert(f == f3)
        f3_inserted_count = f3_inserted_count + 1
    end)

    do
        local es, ec = evo.multi_spawn(3, { [f1] = 'hello', [f2] = 42 })
        assert(#es == 3 and ec == 3)

        for i = 1, ec do
            assert(evo.alive(es[i]) and not evo.empty(es[i]) and evo.locate(es[i]) == evo.chunk(f1, f2, f3))
            assert(f2_set_sum == 42 * 3 and f2_inserted_sum == 42 * 3)
            assert(f3_set_count == 3 and f3_inserted_count == 3)
        end
    end
end
