local evo = require 'evolved'

evo.debug_mode(true)

do
    local f1, f2 = evo.id(2)

    local insert_hook_calls = 0

    if f1 < f2 then
        evo.set(f1, evo.ON_INSERT, function()
            insert_hook_calls = insert_hook_calls + 1
        end)
    else
        evo.set(f2, evo.ON_INSERT, function()
            insert_hook_calls = insert_hook_calls + 1
        end)
    end

    do
        insert_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        assert(insert_hook_calls == 1)
        evo.destroy(e)
    end

    evo.remove(f1, evo.ON_INSERT)
    evo.remove(f2, evo.ON_INSERT)

    do
        insert_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        assert(insert_hook_calls == 0)
        evo.destroy(e)
    end

    if f1 < f2 then
        evo.set(f1, evo.ON_INSERT, function()
            insert_hook_calls = insert_hook_calls + 2
        end)
    else
        evo.set(f2, evo.ON_INSERT, function()
            insert_hook_calls = insert_hook_calls + 2
        end)
    end

    do
        insert_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        assert(insert_hook_calls == 2)
        evo.destroy(e)
    end
end

do
    local f1, f2 = evo.id(2)

    local insert_hook_calls = 0

    if f1 > f2 then
        evo.set(f1, evo.ON_INSERT, function()
            insert_hook_calls = insert_hook_calls + 1
        end)
    else
        evo.set(f2, evo.ON_INSERT, function()
            insert_hook_calls = insert_hook_calls + 1
        end)
    end

    do
        insert_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        assert(insert_hook_calls == 1)
        evo.destroy(e)
    end

    evo.remove(f1, evo.ON_INSERT)
    evo.remove(f2, evo.ON_INSERT)

    do
        insert_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        assert(insert_hook_calls == 0)
        evo.destroy(e)
    end

    if f1 > f2 then
        evo.set(f1, evo.ON_INSERT, function()
            insert_hook_calls = insert_hook_calls + 2
        end)
    else
        evo.set(f2, evo.ON_INSERT, function()
            insert_hook_calls = insert_hook_calls + 2
        end)
    end

    do
        insert_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        assert(insert_hook_calls == 2)
        evo.destroy(e)
    end
end

do
    local f1, f2 = evo.id(2)

    local remove_hook_calls = 0

    if f1 < f2 then
        evo.set(f1, evo.ON_REMOVE, function()
            remove_hook_calls = remove_hook_calls + 1
        end)
    else
        evo.set(f2, evo.ON_REMOVE, function()
            remove_hook_calls = remove_hook_calls + 1
        end)
    end

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.destroy(e)
        assert(remove_hook_calls == 1)
    end

    evo.remove(f1, evo.ON_REMOVE)
    evo.remove(f2, evo.ON_REMOVE)

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.destroy(e)
        assert(remove_hook_calls == 0)
    end

    if f1 < f2 then
        evo.set(f1, evo.ON_REMOVE, function()
            remove_hook_calls = remove_hook_calls + 2
        end)
    else
        evo.set(f2, evo.ON_REMOVE, function()
            remove_hook_calls = remove_hook_calls + 2
        end)
    end

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.destroy(e)
        assert(remove_hook_calls == 2)
    end
end

do
    local f1, f2 = evo.id(2)

    local remove_hook_calls = 0

    if f1 > f2 then
        evo.set(f1, evo.ON_REMOVE, function()
            remove_hook_calls = remove_hook_calls + 1
        end)
    else
        evo.set(f2, evo.ON_REMOVE, function()
            remove_hook_calls = remove_hook_calls + 1
        end)
    end

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.destroy(e)
        assert(remove_hook_calls == 1)
    end

    evo.remove(f1, evo.ON_REMOVE)
    evo.remove(f2, evo.ON_REMOVE)

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.destroy(e)
        assert(remove_hook_calls == 0)
    end

    if f1 > f2 then
        evo.set(f1, evo.ON_REMOVE, function()
            remove_hook_calls = remove_hook_calls + 2
        end)
    else
        evo.set(f2, evo.ON_REMOVE, function()
            remove_hook_calls = remove_hook_calls + 2
        end)
    end

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.destroy(e)
        assert(remove_hook_calls == 2)
    end
end

do
    local f1, f2 = evo.id(2)

    local remove_hook_calls = 0

    evo.set(f1, evo.ON_REMOVE, function()
        remove_hook_calls = remove_hook_calls + 1
    end)

    evo.set(f2, evo.ON_REMOVE, function()
        remove_hook_calls = remove_hook_calls + 10
    end)

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.destroy(e)
        assert(remove_hook_calls == 11)
    end

    evo.set(f1, evo.ON_REMOVE, function()
        remove_hook_calls = remove_hook_calls + 2
    end)

    evo.set(f2, evo.ON_REMOVE, function()
        remove_hook_calls = remove_hook_calls + 20
    end)

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.destroy(e)
        assert(remove_hook_calls == 22)
    end

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.remove(e, f1)
        assert(remove_hook_calls == 2)
        evo.clear(e)
        assert(remove_hook_calls == 22)
        evo.destroy(e)
    end

    do
        local q = evo.builder():include(f1, f2):build()

        remove_hook_calls = 0
        local e1 = evo.spawn { [f1] = 42, [f2] = 'hello' }
        local e2 = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.batch_remove(q, f2)
        assert(remove_hook_calls == 40)
        evo.destroy(e1, e2)
        assert(remove_hook_calls == 44)

        remove_hook_calls = 0
        local e3 = evo.spawn { [f1] = 42, [f2] = 'hello' }
        local e4 = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.batch_clear(q)
        assert(remove_hook_calls == 44)
        evo.destroy(e3, e4)

        remove_hook_calls = 0
        local e5 = evo.spawn { [f1] = 42, [f2] = 'hello' }
        local e6 = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.batch_destroy(q)
        assert(remove_hook_calls == 44)
        assert(not evo.alive(e5) and not evo.alive(e6))

        evo.destroy(q)
    end

    evo.set(f1, evo.ON_REMOVE, false)

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.destroy(e)
        assert(remove_hook_calls == 20)
    end

    evo.set(f2, evo.ON_REMOVE, false)

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.destroy(e)
        assert(remove_hook_calls == 0)
    end
end

do
    local f1, f2 = evo.id(2)

    local calls = ''

    local function hooks(tag)
        evo.set(f1, evo.ON_SET, function() calls = calls .. tag .. 's' end)
        evo.set(f1, evo.ON_ASSIGN, function() calls = calls .. tag .. 'a' end)
        evo.set(f1, evo.ON_INSERT, function() calls = calls .. tag .. 'i' end)
    end

    hooks '1'

    do
        calls = ''
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.set(e, f1, 43)
        evo.destroy(e)
        assert(calls == '1s1i1s1a')
    end

    hooks '2'

    do
        calls = ''
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        assert(calls == '2s2i')
        evo.set(e, f1, 43)
        assert(calls == '2s2i2s2a')
        evo.destroy(e)
    end

    do
        calls = ''
        local e = evo.spawn { [f2] = 'hello' }
        evo.set(e, f1, 42)
        assert(calls == '2s2i')
        evo.destroy(e)
    end

    do
        calls = ''
        local es = evo.multi_spawn(2, { [f1] = 42, [f2] = 'hello' })
        assert(calls == '2s2i2s2i')
        evo.destroy(es[1], es[2])
    end

    do
        local p = evo.spawn { [f1] = 42, [f2] = 'hello' }

        calls = ''
        local e1 = evo.clone(p)
        assert(calls == '2s2i')

        calls = ''
        local es = evo.multi_clone(2, p)
        assert(calls == '2s2i2s2i')

        evo.destroy(p, e1, es[1], es[2])
    end

    do
        local q1 = evo.builder():include(f1, f2):build()
        local q2 = evo.builder():include(f2):exclude(f1):build()

        local e1 = evo.spawn { [f1] = 42, [f2] = 'hello' }

        calls = ''
        evo.batch_set(q1, f1, 43)
        assert(calls == '2s2a')

        local e2 = evo.spawn { [f2] = 'hello' }

        calls = ''
        evo.batch_set(q2, f1, 42)
        assert(calls == '2s2i')

        evo.destroy(e1, e2, q1, q2)
    end

    evo.set(f1, evo.ON_SET, false)
    evo.set(f1, evo.ON_ASSIGN, false)

    do
        calls = ''
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.set(e, f1, 43)
        evo.destroy(e)
        assert(calls == '2i')
    end

    evo.set(f1, evo.ON_INSERT, false)

    do
        calls = ''
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.set(e, f1, 43)
        evo.destroy(e)
        assert(calls == '')
    end
end

do
    local f1, f2, f3 = evo.id(3)

    evo.set(f3, evo.REQUIRES, { f1 })

    evo.set(f1, evo.DEFAULT, 1)

    do
        local e = evo.spawn { [f2] = 'hello', [f3] = true }
        assert(evo.get(e, f1) == 1)
        evo.destroy(e)
    end

    evo.set(f1, evo.DEFAULT, 2)

    do
        local e = evo.spawn { [f2] = 'hello', [f3] = true }
        assert(evo.get(e, f1) == 2)
        evo.destroy(e)
    end

    do
        local es = evo.multi_spawn(2, { [f2] = 'hello', [f3] = true })
        assert(evo.get(es[1], f1) == 2 and evo.get(es[2], f1) == 2)
        evo.destroy(es[1], es[2])
    end

    do
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.set(e, f1)
        assert(evo.get(e, f1) == 2)
        evo.destroy(e)
    end

    do
        local q = evo.builder():include(f2):build()
        local e = evo.spawn { [f2] = 'hello' }
        evo.batch_set(q, f1)
        assert(evo.get(e, f1) == 2)
        evo.destroy(e, q)
    end

    evo.set(f1, evo.DEFAULT, { 3 })
    evo.set(f1, evo.DUPLICATE, function(v) return { v[1] } end)

    do
        local e1 = evo.spawn { [f2] = 'hello', [f3] = true }
        local e2 = evo.spawn { [f2] = 'hello', [f3] = true }
        assert(evo.get(e1, f1)[1] == 3 and evo.get(e2, f1)[1] == 3)
        assert(evo.get(e1, f1) ~= evo.get(e2, f1))
        evo.destroy(e1, e2)
    end

    evo.set(f1, evo.DUPLICATE, function(v) return { v[1] + 1 } end)

    do
        local e = evo.spawn { [f2] = 'hello', [f3] = true }
        assert(evo.get(e, f1)[1] == 4)
        evo.set(e, f1)
        assert(evo.get(e, f1)[1] == 4)
        evo.destroy(e)
    end
end
