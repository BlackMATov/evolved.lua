local evo = require 'evolved'

evo.debug_mode(true)

do
    local e = evo.id()
    assert(evo.alive(e))

    evo.destroy(e)
    assert(not evo.alive(e))

    evo.destroy(e)
    assert(not evo.alive(e))
end

do
    local e1, e2 = evo.id(2)
    assert(evo.alive_all(e1, e2))

    evo.destroy(e1, e2)
    assert(not evo.alive_any(e1, e2))

    evo.destroy(e1, e2)
    assert(not evo.alive_any(e1, e2))
end

do
    do
        local e, f1, f2, f3 = evo.id(4)

        evo.set(e, f1, 42)
        evo.set(e, f2, 21)
        evo.set(e, f3, 84)

        evo.destroy(f1, f2)
        assert(evo.alive(e) and not evo.has_any(e, f1, f2) and evo.has(e, f3))
    end
    do
        local e, f1, f2, f3 = evo.id(4)
        evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)

        evo.set(e, f1, 42)
        evo.set(e, f2, 21)
        evo.set(e, f3, 84)

        evo.destroy(f1, f2)
        assert(evo.alive(e) and not evo.has_any(e, f1, f2) and evo.has(e, f3))
    end
    do
        local e, f1, f2, f3 = evo.id(4)
        evo.set(f2, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)

        evo.set(e, f1, 42)
        evo.set(e, f2, 21)
        evo.set(e, f3, 84)

        evo.destroy(f1, f2)
        assert(evo.alive(e) and not evo.has_any(e, f1, f2) and evo.has(e, f3))
    end
    do
        local e, f1, f2, f3 = evo.id(4)
        evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)
        evo.set(f2, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)

        evo.set(e, f1, 42)
        evo.set(e, f2, 21)
        evo.set(e, f3, 84)

        evo.destroy(f1, f2)
        assert(evo.alive(e) and not evo.has_any(e, f1, f2) and evo.has(e, f3))
    end
    do
        local e, f1, f2, f3 = evo.id(4)
        evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

        evo.set(e, f1, 42)
        evo.set(e, f2, 21)
        evo.set(e, f3, 84)

        evo.destroy(f1, f2)
        assert(not evo.alive(e))
    end
    do
        local e, f1, f2, f3 = evo.id(4)
        evo.set(f2, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

        evo.set(e, f1, 42)
        evo.set(e, f2, 21)
        evo.set(e, f3, 84)

        evo.destroy(f1, f2)
        assert(not evo.alive(e))
    end
    do
        local e, f1, f2, f3 = evo.id(4)
        evo.set(f1, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
        evo.set(f2, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

        evo.set(e, f1, 42)
        evo.set(e, f2, 21)
        evo.set(e, f3, 84)

        evo.destroy(f1, f2)
        assert(not evo.alive(e))
    end
end

do
    local f = evo.builder():destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY):build()

    local remove_count = 0
    local g = evo.builder():set(f):on_remove(function(e, g, c)
        remove_count = remove_count + 1
        assert(evo.alive_all(e, g) and c == 42)
    end):build()

    local e = evo.spawn({ [g] = 42 })

    evo.destroy(f)
    assert(not evo.alive_any(f, g))
    assert(evo.alive(e) and not evo.has(e, g))
    assert(remove_count == 1)
end

do
    local f = evo.builder():destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY):build()

    local remove_count = 0
    local g = evo.builder():set(f):destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
        :on_remove(function(e, g, c)
            remove_count = remove_count + 1
            assert(evo.alive_all(f, e, g) and c == 42)
        end):build()

    local e1 = evo.spawn({ [g] = 42 })
    local e2 = evo.spawn({ [f] = true, [g] = 42 })

    evo.destroy(f)
    assert(not evo.alive_any(f, g, e1, e2))
    assert(remove_count == 2)
end

do
    local q = evo.id()

    local remove_count = 0
    local g = evo.builder():set(q):on_remove(function(e, g, c)
        remove_count = remove_count + 1
        assert(evo.alive_all(e, g) and c == 42)
    end):build()

    local e1 = evo.spawn({ [g] = 42 })
    local e2 = evo.spawn({ [q] = true })

    evo.batch_destroy(evo.builder():include(q):build())
    assert(not evo.alive_any(g, e2))
    assert(evo.alive(e1) and not evo.has(e1, g))
    assert(remove_count == 1)
end

for _, f_first in ipairs({ true, false }) do
    local remove_count = 0
    local f = evo.builder():destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
        :on_remove(function(e, f)
            remove_count = remove_count + 1
            assert(evo.alive_all(e, f))
        end):build()

    local g = evo.spawn({ [f] = true })
    local e = evo.spawn({ [g] = 42 })

    if f_first then
        evo.destroy(f, g)
    else
        evo.destroy(g, f)
    end

    assert(not evo.alive_any(f, g))
    assert(evo.alive(e) and not evo.has(e, g))
    assert(remove_count == 1)
end

do
    local DE = evo.DESTRUCTION_POLICY_DESTROY_ENTITY
    local RF = evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT

    for _, f_policy in ipairs({ DE, RF }) do
        for _, g_policy in ipairs({ DE, RF }) do
            for _, destroy_case in ipairs({ 'f', 'g', 'f,g', 'g,f' }) do
                local f_remove_count, g_remove_count = 0, 0

                local f, g = evo.id(2)

                evo.set(f, evo.DESTRUCTION_POLICY, f_policy)
                evo.set(g, evo.DESTRUCTION_POLICY, g_policy)

                evo.set(f, evo.ON_REMOVE, function(e, ff, c)
                    f_remove_count = f_remove_count + 1
                    assert(e == g and ff == f and c == 21)
                    assert(evo.alive_all(f, g))
                end)

                evo.set(g, evo.ON_REMOVE, function(e, gg, c)
                    g_remove_count = g_remove_count + 1
                    assert(e == f and gg == g and c == 42)
                    assert(evo.alive_all(f, g))
                end)

                evo.set(f, g, 42)
                evo.set(g, f, 21)

                if destroy_case == 'f' then
                    evo.destroy(f)
                    assert(not evo.alive(f))
                    assert(evo.alive(g) == (f_policy == RF))
                elseif destroy_case == 'g' then
                    evo.destroy(g)
                    assert(not evo.alive(g))
                    assert(evo.alive(f) == (g_policy == RF))
                elseif destroy_case == 'f,g' then
                    evo.destroy(f, g)
                    assert(not evo.alive_any(f, g))
                else
                    evo.destroy(g, f)
                    assert(not evo.alive_any(f, g))
                end

                assert(not evo.alive(f) or not evo.has(f, g))
                assert(not evo.alive(g) or not evo.has(g, f))

                assert(f_remove_count == 1)
                assert(g_remove_count == 1)
            end
        end
    end
end

for g_place = 1, 4 do
    local remove_count = 0
    local f = evo.builder():destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
        :on_remove(function(e, f)
            remove_count = remove_count + 1
            assert(evo.alive_all(e, f))
        end):build()

    local x = evo.id()
    evo.set(x, evo.INDEX)

    local g, plain_list = nil, {}

    for i = 1, 4 do
        local e = evo.spawn({ [f] = true, [x] = i })

        if i == g_place then
            g = e
        else
            plain_list[#plain_list + 1] = e
        end
    end

    ---@cast g -?
    local u = evo.spawn({ [g] = 42 })

    evo.destroy(f)
    assert(not evo.alive_any(f, g))
    assert(not evo.alive_any(plain_list[1], plain_list[2], plain_list[3]))
    assert(evo.alive(u) and not evo.has(u, g))
    assert(remove_count == 4)

    for i = 1, 4 do
        assert(evo.search(x, i) == nil)
    end

    local e = evo.spawn({ [x] = 5 })
    assert(evo.search(x, 5) == e)
end

do
    local l1 = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()
    local l2 = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()

    local t1, t2 = evo.id(2)

    local r = evo.spawn({ [l1] = t1, [l2] = t2 })

    evo.destroy(t1, t2)
    assert(not evo.alive_any(t1, t2, r))

    local ids = { evo.id(8) }

    for i = 1, #ids do
        for j = i + 1, #ids do
            assert(ids[i] % 2 ^ 20 ~= ids[j] % 2 ^ 20)
        end
    end

    evo.destroy(ids[1], ids[2], ids[3], ids[4], ids[5], ids[6], ids[7], ids[8])
end

do
    local l1 = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()
    local l2 = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()

    local t = evo.id()

    local r = evo.spawn({ [l1] = t, [l2] = t })

    evo.destroy(t)
    assert(not evo.alive_any(t, r))

    local ids = { evo.id(8) }

    for i = 1, #ids do
        for j = i + 1, #ids do
            assert(ids[i] % 2 ^ 20 ~= ids[j] % 2 ^ 20)
        end
    end

    evo.destroy(ids[1], ids[2], ids[3], ids[4], ids[5], ids[6], ids[7], ids[8])
end

do
    local f = evo.builder():destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY):build()
    local l = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()

    local t = evo.id()

    local r = evo.spawn({ [f] = true, [l] = t })

    for _, f_first in ipairs({ true, false }) do
        if f_first then
            evo.destroy(f, t)
        else
            evo.destroy(t, f)
        end

        assert(not evo.alive_any(f, t, r))
        assert(evo.search(l, t) == nil)

        f = evo.builder():destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY):build()
        t = evo.id()
        r = evo.spawn({ [f] = true, [l] = t })
    end
end

do
    local f = evo.builder():destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY):build()
    local l = evo.builder():link():build()

    local t = evo.id()

    local r1 = evo.spawn({ [f] = true, [l] = t })
    local r2 = evo.spawn({ [f] = true, [l] = t })

    evo.destroy(t, f)
    assert(not evo.alive_any(f, t, r1, r2))
    assert(evo.search(l, t) == nil)
end

do
    local e = evo.id()

    evo.destroy()
    assert(evo.alive(e))

    evo.destroy(e)
end
