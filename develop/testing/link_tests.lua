local evo = require 'evolved'

evo.debug_mode(true)

do
    assert(evo.has_all(evo.GROUP, evo.LINK, evo.INDEX))
    assert(evo.get(evo.GROUP, evo.LINK_POLICY) == evo.LINK_POLICY_DESTROY_ENTITY)

    assert(evo.has_all(evo.QUERY, evo.LINK, evo.INDEX))
    assert(evo.get(evo.QUERY, evo.LINK_POLICY) == evo.LINK_POLICY_DESTROY_ENTITY)

    assert(evo.has(evo.INCLUDES, evo.LINK) and not evo.has(evo.INCLUDES, evo.INDEX))
    assert(evo.get(evo.INCLUDES, evo.LINK_POLICY) == evo.LINK_POLICY_DESTROY_ENTITY)

    assert(evo.has(evo.EXCLUDES, evo.LINK) and not evo.has(evo.EXCLUDES, evo.INDEX))
    assert(evo.get(evo.EXCLUDES, evo.LINK_POLICY) == evo.LINK_POLICY_DESTROY_ENTITY)

    assert(evo.has(evo.VARIANTS, evo.LINK) and not evo.has(evo.VARIANTS, evo.INDEX))
    assert(evo.get(evo.VARIANTS, evo.LINK_POLICY) == evo.LINK_POLICY_DESTROY_ENTITY)

    assert(evo.has(evo.REQUIRES, evo.LINK) and not evo.has(evo.REQUIRES, evo.INDEX))
    assert(evo.get(evo.REQUIRES, evo.LINK_POLICY) == evo.LINK_POLICY_DESTROY_ENTITY)
end

do
    local f = evo.builder():link():build()
    assert(evo.has(f, evo.LINK) and not evo.has(f, evo.INDEX))
    assert(not evo.has(f, evo.LINK_POLICY))
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()
    assert(evo.has(f, evo.LINK) and not evo.has(f, evo.INDEX))
    assert(evo.get(f, evo.LINK_POLICY) == evo.LINK_POLICY_DESTROY_ENTITY)
end

do
    local f, g = evo.id(2)
    local t1, t2 = evo.id(2)

    evo.set(f, evo.LINK)
    assert(evo.has(f, evo.LINK) and not evo.has(f, evo.INDEX))

    local e1 = evo.builder():set(f, t1):set(g, 42):build()
    local e2 = evo.builder():set(f, t1):build()
    local e3 = evo.builder():set(f, t2):set(g, 21):build()

    evo.destroy(t1)
    assert(evo.alive_all(e1, e2, e3))

    assert(not evo.has(e1, f) and evo.get(e1, g) == 42)
    assert(not evo.has(e2, f))
    assert(evo.get(e3, f) == t2 and evo.get(e3, g) == 21)

    assert(evo.search(f, t1) == nil)
    assert(evo.search(f, t2) == e3)
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()
    local g = evo.id()

    local t1, t2 = evo.id(2)

    local e1 = evo.builder():set(f, t1):set(g, 42):build()
    local e2 = evo.builder():set(f, t1):build()
    local e3 = evo.builder():set(f, t2):build()
    local e4 = evo.builder():set(g, t1):build()

    evo.destroy(t1)
    assert(not evo.alive_any(e1, e2))
    assert(evo.alive_all(e3, e4))
    assert(evo.get(e3, f) == t2 and evo.get(e4, g) == t1)
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()

    local e1 = evo.id()
    local e2 = evo.builder():set(f, e1):build()
    local e3 = evo.builder():set(f, e2):build()
    local e4 = evo.builder():set(f, e3):build()

    evo.destroy(e1)
    assert(not evo.alive_any(e1, e2, e3, e4))
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()

    local e1, e2, e3 = evo.id(3)
    evo.set(e1, f, e2)
    evo.set(e2, f, e3)
    evo.set(e3, f, e1)

    evo.destroy(e2)
    assert(not evo.alive_any(e1, e2, e3))
end

do
    local f1 = evo.builder():link():build()
    local f2 = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()

    local e1 = evo.id()
    evo.set(e1, f1, e1)

    local e2 = evo.id()
    evo.set(e2, f2, e2)

    evo.destroy(e1, e2)
    assert(not evo.alive_any(e1, e2))
end

do
    local f1, f2 = evo.builder():link():build(), evo.builder():link():build()

    local t = evo.id()
    local e = evo.builder():set(f1, t):set(f2, t):build()

    evo.destroy(t)
    assert(evo.alive(e) and not evo.has_any(e, f1, f2))
end

do
    local f = evo.builder():link():build()

    local t = evo.id()
    local e1 = evo.builder():set(f, t):build()
    local e2 = evo.builder():set(f, t):build()

    evo.destroy(t, e1)
    assert(not evo.alive_any(t, e1))
    assert(evo.alive(e2) and not evo.has(e2, f))
end

do
    local f = evo.builder():link():build()

    local t1, t2 = evo.id(2)
    local e = evo.builder():set(f, t1):build()

    evo.defer()
    do
        evo.destroy(t1)
        evo.set(e, f, t2)
    end
    evo.commit()

    assert(evo.get(e, f) == t2)
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()

    local t1, t2 = evo.id(2)
    local e = evo.builder():set(f, t1):build()

    evo.defer()
    do
        evo.set(e, f, t2)
        evo.destroy(t1)
    end
    evo.commit()

    assert(evo.alive(e) and evo.get(e, f) == t2)
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()

    local t = evo.id()
    local e = evo.builder():set(f, t):build()

    evo.defer()
    do
        evo.destroy(t)
        assert(evo.alive(e))
    end
    evo.commit()

    assert(not evo.alive(e))
end

do
    local f = evo.builder():link():build()

    local t = evo.id()
    local e = evo.builder():set(f, t):build()

    evo.defer()
    do
        evo.destroy(t)
        assert(evo.get(e, f) == t)
    end
    evo.commit()

    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder():link():build()

    local t = evo.builder():tag():build()
    local e1 = evo.builder():set(f, t):build()
    local e2 = evo.builder():set(t):build()

    evo.destroy(t)
    assert(evo.alive_all(e1, e2))
    assert(not evo.has(e1, f) and not evo.has(e2, t))
end

do
    local f = evo.builder():link():build()
    local g = evo.builder():tag():build()

    local t1 = evo.builder():set(g):build()
    local t2 = evo.builder():set(g):build()

    local e1 = evo.builder():set(f, t1):build()
    local e2 = evo.builder():set(f, t2):build()

    local q = evo.builder():include(g):build()

    evo.batch_destroy(q)
    assert(not evo.alive_any(t1, t2))
    assert(evo.alive_all(e1, e2))
    assert(not evo.has(e1, f) and not evo.has(e2, f))
end

do
    local f = evo.builder():link():build()
    local p = evo.builder():prefab():build()

    local t = evo.id()
    evo.set(p, f, t)

    local e1 = evo.clone(p)
    local e2 = evo.clone(p)
    assert(evo.get(e1, f) == t and evo.get(e2, f) == t)

    evo.destroy(t)
    assert(not evo.has_any(p, f) and not evo.has(e1, f) and not evo.has(e2, f))
end

do
    local f = evo.builder():link():build()

    local t = evo.id()
    local e = evo.builder():set(f, t):build()

    evo.remove(f, evo.LINK)
    assert(not evo.has_any(f, evo.LINK, evo.INDEX))

    evo.destroy(t)
    assert(evo.get(e, f) == t)
end

do
    local f = evo.builder():link():build()

    local t = evo.id()
    local e = evo.builder():set(f, t):build()

    assert(evo.search(f, t) == e)
end

do
    local f = evo.builder():index():link():build()

    local t = evo.id()
    local e = evo.builder():set(f, t):build()

    evo.remove(f, evo.INDEX)
    assert(evo.has(f, evo.LINK) and not evo.has(f, evo.INDEX))
    assert(evo.search(f, t) == e)

    evo.destroy(t)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder():index():build()

    local t1, t2 = evo.id(2)
    local e1 = evo.builder():set(f, t1):build()
    local e2 = evo.builder():set(f, t2):build()

    evo.destroy(t1)
    assert(evo.get(e1, f) == t1)

    evo.remove(e1, f)
    evo.set(f, evo.LINK)

    evo.destroy(t2)
    assert(evo.alive(e2) and not evo.has(e2, f))
end

do
    local f = evo.builder():link():build()

    local t1, t2 = evo.id(2)
    local e1 = evo.builder():set(f, t1):build()
    local e2 = evo.builder():set(f, t2):build()

    evo.remove(f, evo.LINK)

    evo.destroy(t1)
    assert(evo.get(e1, f) == t1)

    evo.remove(e1, f)
    evo.set(f, evo.LINK)

    evo.destroy(t2)
    assert(evo.alive(e2) and not evo.has(e2, f))
end

do
    local f = evo.builder():link():build()

    local t = evo.id()
    local e = evo.builder():set(f, t):build()

    evo.set(f, evo.LINK_POLICY, evo.LINK_POLICY_DESTROY_ENTITY)

    evo.destroy(t)
    assert(not evo.alive(e))
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_REMOVE_FRAGMENT):build()
    assert(evo.get(f, evo.LINK_POLICY) == evo.LINK_POLICY_REMOVE_FRAGMENT)

    local t = evo.id()
    local e = evo.builder():set(f, t):build()

    evo.destroy(t)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()

    local t = evo.id()
    local e = evo.builder():set(f, t):build()

    evo.remove(f, evo.LINK_POLICY)
    assert(evo.has(f, evo.LINK) and not evo.has(f, evo.LINK_POLICY))

    evo.destroy(t)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder():index():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()
    assert(not evo.has(f, evo.LINK) and evo.has(f, evo.LINK_POLICY))

    local t = evo.id()
    local e = evo.builder():set(f, t):build()

    evo.destroy(t)
    assert(evo.alive(e) and evo.get(e, f) == t)
end

do
    local f = evo.builder():index():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()

    local t = evo.id()
    local e = evo.builder():set(f, t):build()

    evo.set(f, evo.LINK)

    evo.destroy(t)
    assert(not evo.alive(e))
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()

    local t1, t2 = evo.id(2)
    local e1 = evo.builder():set(f, t1):build()
    local e2 = evo.builder():set(f, t2):build()

    evo.remove(f, evo.LINK)
    evo.set(f, evo.LINK)

    evo.destroy(t1)
    assert(not evo.alive(e1))

    evo.remove(f, evo.LINK_POLICY)
    evo.remove(f, evo.LINK)
    evo.set(f, evo.LINK)

    evo.destroy(t2)
    assert(evo.alive(e2) and not evo.has(e2, f))
end

do
    local f = evo.builder():link():build()

    local t1, t2 = evo.id(2)
    local e1 = evo.builder():set(f, t1):build()
    local e2 = evo.builder():set(f, t2):build()

    evo.defer()
    do
        evo.set(f, evo.LINK_POLICY, evo.LINK_POLICY_DESTROY_ENTITY)
        evo.destroy(t1)
        evo.remove(f, evo.LINK_POLICY)
        evo.destroy(t2)
    end
    evo.commit()

    assert(not evo.alive(e1))
    assert(evo.alive(e2) and not evo.has(e2, f))
end

do
    local f = evo.builder():link():build()

    local t1, t2 = evo.id(2)
    local e1 = evo.builder():set(f, t1):build()
    local e2 = evo.builder():set(f, t2):build()

    evo.set(f, evo.LINK_POLICY, evo.LINK_POLICY_DESTROY_ENTITY)

    evo.destroy(t1)
    assert(not evo.alive(e1))

    evo.set(f, evo.LINK_POLICY, evo.LINK_POLICY_REMOVE_FRAGMENT)

    evo.destroy(t2)
    assert(evo.alive(e2) and not evo.has(e2, f))
end

do
    local f = evo.builder():link():build()

    local t1, t2 = evo.id(2)
    local e = evo.builder():set(f, t1):build()

    evo.destroy(f)
    assert(evo.alive(e) and not evo.has(e, f))

    evo.destroy(t1, t2)
    assert(evo.alive(e))
end

do
    local group = evo.builder():build()

    local s1 = evo.builder():group(group):build()
    local s2 = evo.builder():group(group):build()
    local s3 = evo.builder():build()
    local s4 = evo.builder():group(s1):build()

    evo.destroy(group)
    assert(not evo.alive_any(group, s1, s2, s4))
    assert(evo.alive(s3))
end

do
    local f = evo.builder():build()

    local e = evo.builder():set(f, 42):build()
    local q = evo.builder():include(f):build()

    local executed = 0

    local s = evo.builder()
        :query(q)
        :execute(function(chunk, entity_list, entity_count)
            for i = 1, entity_count do
                assert(chunk:components(f)[i] == 42)
                assert(entity_list[i] == e)
            end
            executed = executed + entity_count
        end)
        :build()

    evo.process(s)
    assert(executed == 1)

    evo.destroy(q)
    assert(not evo.alive(s))
    assert(evo.alive(e) and evo.get(e, f) == 42)
end

do
    local q = evo.builder():build()

    local s1 = evo.builder():query(q):build()
    local s2 = evo.builder():group(s1):build()
    local s3 = evo.builder():query(q):group(s1):build()

    evo.destroy(q)
    assert(not evo.alive_any(q, s1, s2, s3))
end

do
    local f = evo.builder():link():build()

    local t1, t2 = evo.id(2)
    local e1 = evo.builder():set(f, t1):build()
    local e2 = evo.builder():set(f, t1):build()

    evo.set(e1, f, t2)
    evo.set(e2, f, t2)

    evo.destroy(t1)
    assert(evo.get(e1, f) == t2 and evo.get(e2, f) == t2)

    evo.destroy(t2)
    assert(not evo.has(e1, f) and not evo.has(e2, f))
end

do
    local f = evo.builder():link():build()

    local t1, t2 = evo.id(2)
    local e = evo.builder():set(f, t1):build()

    do
        local chunk, place = evo.locate(e)
        assert(chunk):components(f)[place] = t2
        evo.reindex(f)
    end

    evo.destroy(t1)
    assert(evo.get(e, f) == t2)

    evo.destroy(t2)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f1 = evo.builder():link():build()
    local f2 = evo.builder():link():build()

    local t = evo.id()
    local e = evo.builder():set(f1, t):set(f2, t):build()

    evo.remove(f1, evo.LINK)

    evo.destroy(t)
    assert(evo.get(e, f1) == t and not evo.has(e, f2))
end

do
    local f = evo.builder():link():build()

    local t = evo.id()
    local e = evo.builder():set(f, t):build()

    evo.remove(f, evo.INDEX)
    evo.set(f, evo.INDEX)

    evo.destroy(t)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder():link():build()

    local t = evo.id()
    local e1 = evo.builder():set(f, t):build()
    local e2 = evo.builder():set(f, t):build()

    evo.remove(e1, f)
    evo.destroy(e2)

    local e3 = evo.builder():set(f, t):build()

    evo.destroy(t)
    assert(evo.alive_all(e1, e3) and not evo.has_any(e1, f) and not evo.has(e3, f))
end

do
    local f = evo.builder():link():build()

    local t = evo.id()
    local e = evo.builder():set(f, t):build()

    evo.remove(f, evo.LINK)
    evo.set(f, evo.LINK)

    evo.destroy(t)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder():link():build()

    local t1, t2 = evo.id(2)
    local e = evo.builder():set(f, t1):build()

    evo.remove(f, evo.LINK)
    evo.set(e, f, t2)
    evo.set(f, evo.LINK)

    evo.destroy(t1)
    assert(evo.get(e, f) == t2)

    evo.destroy(t2)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f1 = evo.builder():link():build()
    local f2 = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()

    local t = evo.id()
    local e1 = evo.builder():set(f1, t):build()
    local e2 = evo.builder():set(f2, t):build()

    evo.remove(f1, evo.INDEX)
    evo.set(f1, evo.INDEX)

    evo.remove(f2, evo.LINK)
    evo.set(f2, evo.LINK)

    evo.destroy(t)
    assert(evo.alive(e1) and not evo.has(e1, f1))
    assert(not evo.alive(e2))
end

do
    local f = evo.builder():link():build()

    local t = evo.id()
    local e1 = evo.builder():set(f, t):build()
    local e2 = evo.builder():set(f, t):build()

    evo.set(f, evo.INDEX)
    evo.remove(f, evo.INDEX)

    evo.destroy(t)
    assert(evo.alive_all(e1, e2) and not evo.has(e1, f) and not evo.has(e2, f))
end

do
    local g = evo.builder():build()

    local removed_list = {}

    local f = evo.builder()
        :link()
        :link_policy(evo.LINK_POLICY_DESTROY_ENTITY)
        :on_remove(function(e, _, t)
            assert(evo.alive(t) and evo.get(t, g) == 42)
            removed_list[#removed_list + 1] = e
        end)
        :build()

    local e1 = evo.builder():set(g, 42):build()
    local e2 = evo.builder():set(f, e1):set(g, 42):build()
    local e3 = evo.builder():set(f, e2):set(g, 42):build()

    evo.destroy(e1)
    assert(not evo.alive_any(e1, e2, e3))
    assert(#removed_list == 2 and removed_list[1] == e3 and removed_list[2] == e2)
end

do
    local g = evo.builder():build()

    local removed_count = 0

    local f = evo.builder()
        :link()
        :on_remove(function(_, _, t)
            assert(evo.alive(t) and evo.get(t, g) == 42)
            removed_count = removed_count + 1
        end)
        :build()

    local t = evo.builder():set(g, 42):build()
    local e1 = evo.builder():set(f, t):build()
    local e2 = evo.builder():set(f, t):build()

    evo.destroy(t)
    assert(removed_count == 2)
    assert(evo.alive_all(e1, e2) and not evo.has(e1, f) and not evo.has(e2, f))
end

do
    local g = evo.builder():tag():build()

    local removed_count = 0

    local f = evo.builder()
        :link()
        :link_policy(evo.LINK_POLICY_DESTROY_ENTITY)
        :on_remove(function(_, _, t)
            assert(evo.alive(t))
            removed_count = removed_count + 1
        end)
        :build()

    local t = evo.builder():set(g):build()
    local e1 = evo.builder():set(f, t):build()
    local e2 = evo.builder():set(f, e1):build()

    local q = evo.builder():include(g):build()

    evo.batch_destroy(q)
    assert(removed_count == 2)
    assert(not evo.alive_any(t, e1, e2))
end

do
    local f = evo.builder():link():build()
    local g = evo.id()

    local t1, t2, t3 = evo.id(3)

    local e1 = evo.builder():set(f, { t1, t2 }):set(g, 42):build()
    local e2 = evo.builder():set(f, { t2, t3 }):build()
    local e3 = evo.builder():set(f, { t3 }):build()
    local e4 = evo.builder():set(f, t2):build()
    local e5 = evo.builder():set(f, {}):build()

    evo.destroy(t2)
    assert(evo.alive_all(e1, e2, e3, e4, e5))

    assert(not evo.has(e1, f) and evo.get(e1, g) == 42)
    assert(not evo.has(e2, f))
    assert(not evo.has(e4, f))

    do
        local l3 = evo.get(e3, f)
        assert(#l3 == 1 and l3[1] == t3)

        local l5 = evo.get(e5, f)
        assert(#l5 == 0)
    end

    assert(evo.search(f, t1) == nil)
    assert(evo.search(f, t2) == nil)
    assert(evo.search(f, t3) == e3)
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()

    local t1, t2 = evo.id(2)

    local e1 = evo.builder():set(f, { t1, t2 }):build()
    local e2 = evo.builder():set(f, { t2 }):build()
    local e3 = evo.builder():set(f, { t2, e1 }):build()
    local e4 = evo.builder():set(f, e3):build()
    local e5 = evo.builder():set(f, {}):build()

    evo.destroy(t1)
    assert(not evo.alive_any(t1, e1, e3, e4))
    assert(evo.alive_all(t2, e2, e5))

    evo.destroy(t2)
    assert(not evo.alive_any(t2, e2))
    assert(evo.alive(e5))
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()

    local e1, e2, e3 = evo.id(3)
    evo.set(e1, f, { e2 })
    evo.set(e2, f, { e3, e3 })
    evo.set(e3, f, { e1, e2 })

    evo.destroy(e2)
    assert(not evo.alive_any(e1, e2, e3))
end

do
    local f = evo.builder():link():build()

    local t1, t2 = evo.id(2)

    local e1 = evo.builder():set(f, { t1, t2 }):build()
    local e2 = evo.builder():set(f, { t2 }):build()
    local e3 = evo.builder():set(f, { t2, t1 }):build()

    assert(evo.search(f, t1) == e1)
    assert(evo.search(f, t2) == e1)

    do
        local l, c = evo.multi_search(f, t1)
        assert(c == 2 and l[1] == e1 and l[2] == e3)
    end

    do
        local l, c = evo.multi_search(f, t2)
        assert(c == 3 and l[1] == e1 and l[2] == e2 and l[3] == e3)
    end

    evo.remove(e1, f)

    do
        local l, c = evo.multi_search(f, t1)
        assert(c == 1 and l[1] == e3)
    end

    do
        local l, c = evo.multi_search(f, t2)
        assert(c == 2 and l[1] == e2 and l[2] == e3)
    end
end

do
    local f = evo.builder():link():build()

    local t = evo.id()

    local e1 = evo.builder():set(f, t):build()
    local e2 = evo.builder():set(f, { t }):build()

    do
        local l, c = evo.multi_search(f, t)
        assert(c == 2 and l[1] == e1 and l[2] == e2)
    end

    evo.remove(e1, f)
    assert(evo.search(f, t) == e2)

    evo.remove(e2, f)
    assert(evo.search(f, t) == nil)

    evo.set(e1, f, { t })
    evo.set(e2, f, t)

    evo.destroy(t)
    assert(evo.alive_all(e1, e2) and not evo.has_any(e1, f) and not evo.has_any(e2, f))
end

do
    local f = evo.builder():link():build()

    local t1, t2 = evo.id(2)

    local e1 = evo.builder():set(f, t1):build()
    local e2 = evo.builder():set(f, t2):build()
    local e3 = evo.builder():set(f, t1):build()

    local e4 = evo.builder():set(f, { t2, t1 }):build()

    do
        local l, c = evo.multi_search(f, t1)
        assert(c == 3 and l[1] == e1 and l[2] == e3 and l[3] == e4)
    end

    do
        local l, c = evo.multi_search(f, t2)
        assert(c == 2 and l[1] == e2 and l[2] == e4)
    end

    evo.remove(e1, f)
    evo.set(e2, f, t1)

    do
        local l, c = evo.multi_search(f, t1)
        assert(c == 3 and l[1] == e3 and l[2] == e4 and l[3] == e2)
    end

    do
        local l, c = evo.multi_search(f, t2)
        assert(c == 1 and l[1] == e4)
    end

    evo.destroy(t2)
    assert(evo.alive_all(e2, e3, e4) and not evo.has(e4, f))
    assert(evo.get(e2, f) == t1 and evo.get(e3, f) == t1)

    do
        local l, c = evo.multi_search(f, t1)
        assert(c == 2 and l[1] == e3 and l[2] == e2)
    end

    evo.destroy(t1)
    assert(evo.alive_all(e2, e3) and not evo.has(e2, f) and not evo.has(e3, f))
end

do
    local f = evo.builder():link():build()

    local t = evo.id()
    local e = evo.builder():set(f, { t, t, t }):build()

    do
        local l, c = evo.multi_search(f, t)
        assert(c == 1 and l[1] == e)
    end

    evo.remove(e, f)
    assert(evo.search(f, t) == nil)

    evo.set(e, f, { t, t })
    assert(evo.search(f, t) == e)

    evo.destroy(t)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder():link():build()

    local t = evo.id()

    local e1 = evo.builder():set(f, t):build()
    local e2 = evo.builder():set(f, { t, t }):build()
    local e3 = evo.builder():set(f, { t }):build()

    do
        local l, c = evo.multi_search(f, t)
        assert(c == 3 and l[1] == e1 and l[2] == e2 and l[3] == e3)
    end

    evo.remove(e2, f)

    do
        local l, c = evo.multi_search(f, t)
        assert(c == 2 and l[1] == e1 and l[2] == e3)
    end

    evo.set(e2, f, { t, t })
    evo.set(e2, f, { t })

    do
        local l, c = evo.multi_search(f, t)
        assert(c == 3 and l[1] == e1 and l[2] == e3 and l[3] == e2)
    end

    evo.set(e2, f, { t, t })
    evo.destroy(e2)

    do
        local l, c = evo.multi_search(f, t)
        assert(c == 2 and l[1] == e1 and l[2] == e3)
    end

    evo.destroy(t)
    assert(evo.alive_all(e1, e3) and not evo.has(e1, f) and not evo.has(e3, f))
end

do
    local f = evo.builder():link():build()

    local t1, t2, t3 = evo.id(3)
    local e = evo.builder():set(f, { t1, t2 }):build()

    evo.set(e, f, { t2, t3 })
    assert(evo.search(f, t1) == nil)
    assert(evo.search(f, t2) == e)
    assert(evo.search(f, t3) == e)

    evo.destroy(t1)
    assert(evo.has(e, f))

    evo.destroy(t3)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder():link():build()

    local t1, t2 = evo.id(2)
    local e = evo.builder():set(f, t1):build()

    evo.set(e, f, { t2 })
    assert(evo.search(f, t1) == nil)
    assert(evo.search(f, t2) == e)

    evo.set(e, f, t1)
    assert(evo.search(f, t1) == e)
    assert(evo.search(f, t2) == nil)

    evo.destroy(t2)
    assert(evo.get(e, f) == t1)

    evo.destroy(t1)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder():link():build()

    local t = evo.id()

    local e1 = evo.builder():set(f, { t }):build()
    local e2 = evo.builder():set(f, t):build()
    local e3 = evo.builder():set(f, { t, t }):build()

    do
        local l, c = evo.multi_search(f, t)
        assert(c == 3 and l[1] == e1 and l[2] == e2 and l[3] == e3)
    end

    evo.set(e1, f, { t })
    evo.set(e3, f, { t, t })

    do
        local l, c = evo.multi_search(f, t)
        assert(c == 3 and l[1] == e1 and l[2] == e2 and l[3] == e3)
    end

    evo.set(e1, f, { t, t })

    do
        local l, c = evo.multi_search(f, t)
        assert(c == 3 and l[1] == e2 and l[2] == e3 and l[3] == e1)
    end

    evo.set(e2, f, { t })

    do
        local l, c = evo.multi_search(f, t)
        assert(c == 3 and l[1] == e3 and l[2] == e1 and l[3] == e2)
    end
end

do
    local f = evo.builder():link():build()

    local t1, t2, t3 = evo.id(3)

    local e1 = evo.builder():set(f, { t1, t2 }):build()
    local e2 = evo.builder():set(f, { t1, t2 }):build()

    evo.set(e1, f, { t2, t3 })

    do
        local l, c = evo.multi_search(f, t1)
        assert(c == 1 and l[1] == e2)
    end

    do
        local l, c = evo.multi_search(f, t2)
        assert(c == 2 and l[1] == e2 and l[2] == e1)
    end

    assert(evo.search(f, t3) == e1)
end

do
    local f = evo.builder():link():build()
    local g = evo.id()

    local t1, t2 = evo.id(2)

    local e1 = evo.builder():set(f, { t1 }):build()
    local e2 = evo.builder():set(f, { t1 }):set(g, 42):build()
    local e3 = evo.builder():set(f, { t1 }):build()

    evo.reindex(f)

    do
        local l, c = evo.multi_search(f, t1)
        assert(c == 3 and l[1] == e1 and l[2] == e2 and l[3] == e3)
    end

    do
        local l = evo.get(e2, f)
        l[2] = t2
        evo.reindex(f)
    end

    do
        local l, c = evo.multi_search(f, t1)
        assert(c == 3 and l[1] == e1 and l[2] == e3 and l[3] == e2)
    end

    assert(evo.search(f, t2) == e2)

    evo.destroy(t2)
    assert(evo.alive(e2) and not evo.has(e2, f))

    do
        local l, c = evo.multi_search(f, t1)
        assert(c == 2 and l[1] == e1 and l[2] == e3)
    end
end

do
    local f = evo.builder():link():build()

    local t1, t2, t3 = evo.id(3)
    local e = evo.builder():set(f, { t1, t2 }):build()

    do
        local l = evo.get(e, f)
        l[1], l[2] = t2, t3
        evo.reindex(f)
    end

    assert(evo.search(f, t1) == nil)
    assert(evo.search(f, t2) == e)
    assert(evo.search(f, t3) == e)

    evo.destroy(t1)
    assert(evo.has(e, f))

    evo.destroy(t2)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder():link():build()

    local t1, t2 = evo.id(2)

    local l = { t1 }
    local e = evo.builder():set(f, l):build()

    l[1] = t2
    evo.set(e, f, l)

    assert(evo.search(f, t1) == nil)
    assert(evo.search(f, t2) == e)

    evo.destroy(t2)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder():index():build()

    local t = evo.id()

    local l = { t }
    local e = evo.builder():set(f, l):build()

    assert(evo.search(f, l) == e)
    assert(evo.search(f, t) == nil)

    evo.set(f, evo.LINK)

    assert(evo.search(f, l) == nil)
    assert(evo.search(f, t) == e)

    evo.remove(f, evo.LINK)

    assert(evo.search(f, l) == e)
    assert(evo.search(f, t) == nil)

    evo.destroy(t)
    assert(evo.get(e, f) == l)
end

do
    local f = evo.builder():link():build()

    local t1, t2 = evo.id(2)
    local e = evo.builder():set(f, { t1, t2 }):build()

    evo.remove(f, evo.LINK)

    evo.destroy(t1)
    assert(evo.has(e, f))

    evo.set(e, f, { t2 })
    evo.set(f, evo.LINK)
    assert(evo.search(f, t2) == e)

    evo.destroy(t2)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder():link():build()

    local t1, t2 = evo.id(2)
    local e = evo.builder():set(f, { t1 }):build()

    evo.defer()
    do
        evo.destroy(t1)
        evo.set(e, f, { t2 })
    end
    evo.commit()

    do
        local l = evo.get(e, f)
        assert(#l == 1 and l[1] == t2)
    end
end

do
    local f = evo.builder():link():build()
    local p = evo.builder():prefab():build()

    local t = evo.id()
    evo.set(p, f, { t })

    local e1 = evo.clone(p)
    local e2 = evo.clone(p)

    do
        local l, c = evo.multi_search(f, t)
        assert(c == 3 and l[1] == p and l[2] == e1 and l[3] == e2)
    end

    evo.destroy(t)
    assert(not evo.has(p, f) and not evo.has(e1, f) and not evo.has(e2, f))
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()

    local t1, t2 = evo.id(2)

    local l1, c1 = evo.multi_spawn(2, { [f] = { t1 } })
    local l2, c2 = evo.multi_spawn(2, { [f] = { t2, t1 } })
    assert(c1 == 2 and c2 == 2)

    evo.destroy(t2)
    assert(evo.alive_all(l1[1], l1[2]))
    assert(not evo.alive_any(l2[1], l2[2]))

    evo.destroy(t1)
    assert(not evo.alive_any(l1[1], l1[2]))
end

do
    local f = evo.builder():link():build()
    local g = evo.builder():tag():build()

    local t1, t2 = evo.id(2)

    local e1 = evo.builder():set(g):build()
    local e2 = evo.builder():set(g):set(f, t1):build()

    local q = evo.builder():include(g):build()

    evo.batch_set(q, f, { t1, t2 })

    do
        local l, c = evo.multi_search(f, t1)
        assert(c == 2)
        assert((l[1] == e1 and l[2] == e2) or (l[1] == e2 and l[2] == e1))
    end

    do
        local l, c = evo.multi_search(f, t2)
        assert(c == 2)
        assert((l[1] == e1 and l[2] == e2) or (l[1] == e2 and l[2] == e1))
    end

    evo.destroy(t2)
    assert(evo.alive_all(e1, e2) and not evo.has(e1, f) and not evo.has(e2, f))
end

do
    local f1, f2 = evo.id(2)

    local q = evo.builder():include(f1, f2):build()
    local s = evo.builder():query(q):build()

    local e = evo.builder():set(f1, 42):set(f2, 21):build()

    evo.destroy(f2)
    assert(not evo.alive_any(f2, q, s))
    assert(evo.alive(e) and evo.get(e, f1) == 42)
end

do
    local f1, f2, f3 = evo.id(3)

    local q1 = evo.builder():include(f1):exclude(f2):build()
    local q2 = evo.builder():include(f1):variant(f2, f3):build()
    local q3 = evo.builder():include(f1):exclude(f3):build()
    local q4 = evo.builder():variant(f1, f3):build()

    evo.destroy(f2)
    assert(not evo.alive_any(q1, q2))
    assert(evo.alive_all(q3, q4))

    evo.destroy(f3)
    assert(not evo.alive_any(q3, q4))
end

do
    local f1, f2 = evo.id(2)

    local s = evo.builder():include(f1):exclude(f2):execute(function() end):build()

    evo.destroy(f2)
    assert(not evo.alive(s))
end

do
    local f1, f2, f3 = evo.id(3)

    local q1 = evo.builder():include(f1):build()
    local q2 = evo.builder():include(f2, f1):exclude(f3):build()
    local q3 = evo.builder():variant(f1):build()

    do
        local l, c = evo.multi_search(evo.INCLUDES, f1)
        assert(c == 2 and l[1] == q1 and l[2] == q2)
    end

    assert(evo.search(evo.EXCLUDES, f3) == q2)
    assert(evo.search(evo.VARIANTS, f1) == q3)

    evo.set(q2, evo.INCLUDES, { f2 })

    do
        local l, c = evo.multi_search(evo.INCLUDES, f1)
        assert(c == 1 and l[1] == q1)
    end

    evo.destroy(f1)
    assert(not evo.alive_any(q1, q3))
    assert(evo.alive(q2))
end

do
    local f1, f2 = evo.id(2)
    local f3 = evo.builder():require(f1, f2):build()

    local e = evo.builder():set(f3, 42):build()
    assert(evo.has_all(e, f1, f2, f3))

    evo.destroy(f2)
    assert(not evo.alive_any(f2, f3))
    assert(evo.alive(e) and evo.has(e, f1) and not evo.has_any(e, f2, f3))

    local f4 = evo.builder():require(f1):build()
    evo.set(e, f4)
    assert(evo.has_all(e, f1, f4))
end

do
    local f1 = evo.id()
    local f2 = evo.builder():require(f1):destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY):build()

    local e1 = evo.builder():set(f2):build()
    local e2 = evo.builder():set(f1):build()

    evo.destroy(f1)
    assert(not evo.alive_any(f1, f2, e1))
    assert(evo.alive(e2) and not evo.has(e2, f1))
end

do
    local f1 = evo.id()
    local f2 = evo.builder():require(f1):build()
    local f3 = evo.builder():require(f2):build()
    local f4 = evo.builder():require(f3):destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY):build()

    local e1 = evo.builder():set(f3):build()
    local e2 = evo.builder():set(f4):build()

    assert(evo.has_all(e1, f1, f2, f3))
    assert(evo.has_all(e2, f1, f2, f3, f4))

    do
        local l, c = evo.multi_search(evo.REQUIRES, f2)
        assert(c == 1 and l[1] == f3)
    end

    evo.destroy(f1)
    assert(not evo.alive_any(f1, f2, f3, f4, e2))
    assert(evo.alive(e1) and evo.empty(e1))
end

do
    local f1, f2 = evo.id(2)

    local q = evo.builder():include(f1, f2):build()
    local s = evo.builder():query(q):build()

    evo.remove(q, evo.INCLUDES)
    assert(evo.search(evo.INCLUDES, f1) == nil)

    evo.destroy(f1)
    assert(evo.alive_all(q, s))

    evo.set(q, evo.INCLUDES, { f2 })

    evo.destroy(f2)
    assert(not evo.alive_any(q, s))
end

do
    evo.debug_mode(false)

    local f = evo.builder():link():build()

    local dead = evo.id()
    evo.destroy(dead)

    local alive = evo.id()
    assert(alive % 2 ^ 20 == dead % 2 ^ 20)

    local e1 = evo.builder():set(f, { dead, alive }):build()
    local e2 = evo.builder():set(f, alive):build()

    assert(evo.search(f, dead) == nil)

    do
        local l, c = evo.multi_search(f, alive)
        assert(c == 2 and l[1] == e1 and l[2] == e2)
    end

    evo.remove(e1, f)
    assert(evo.search(f, alive) == e2)

    do
        local l, c = evo.multi_search(f, alive)
        assert(c == 1 and l[1] == e2)
    end

    evo.destroy(e2)
    assert(evo.search(f, alive) == nil)

    local e3 = evo.builder():set(f, { dead, alive }):build()

    evo.destroy(e3)
    assert(evo.search(f, alive) == nil)

    local e4 = evo.builder():set(f, alive):build()

    evo.destroy(alive)
    assert(evo.alive(e4) and not evo.has(e4, f))

    evo.debug_mode(true)
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_UNLINK_TARGET):build()
    assert(evo.get(f, evo.LINK_POLICY) == evo.LINK_POLICY_UNLINK_TARGET)

    local t1, t2, t3 = evo.id(3)

    local l = { t1, t2, t3 }
    local e = evo.builder():set(f, l):build()

    evo.destroy(t2)
    assert(evo.alive(e))

    do
        local nl = evo.get(e, f)
        assert(nl ~= l and #nl == 2 and nl[1] == t1 and nl[2] == t3)
        assert(#l == 3 and l[1] == t1 and l[2] == t2 and l[3] == t3)
    end

    assert(evo.search(f, t1) == e)
    assert(evo.search(f, t2) == nil)
    assert(evo.search(f, t3) == e)

    evo.destroy(t1)

    do
        local nl = evo.get(e, f)
        assert(#nl == 1 and nl[1] == t3)
    end

    evo.destroy(t3)
    assert(evo.alive(e) and not evo.has(e, f))
    assert(evo.search(f, t3) == nil)
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_UNLINK_TARGET):build()
    local g = evo.id()

    local t1, t2 = evo.id(2)

    local e1 = evo.builder():set(f, t1):set(g, 42):build()
    local e2 = evo.builder():set(f, { t1, t2 }):build()
    local e3 = evo.builder():set(f, { t1 }):build()
    local e4 = evo.builder():set(f, {}):build()

    evo.destroy(t1)
    assert(evo.alive_all(e1, e2, e3, e4))

    assert(not evo.has(e1, f) and evo.get(e1, g) == 42)
    assert(not evo.has(e3, f))

    do
        local l2 = evo.get(e2, f)
        assert(#l2 == 1 and l2[1] == t2)

        local l4 = evo.get(e4, f)
        assert(#l4 == 0)
    end

    assert(evo.search(f, t1) == nil)
    assert(evo.search(f, t2) == e2)
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_UNLINK_TARGET):build()

    local t1, t2, t3, t4 = evo.id(4)
    local e = evo.builder():set(f, { t1, t2, t3, t4 }):build()

    evo.destroy(t1, t3)

    do
        local l = evo.get(e, f)
        assert(#l == 2 and l[1] == t2 and l[2] == t4)
    end

    evo.destroy(t2, t4)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_UNLINK_TARGET):build()

    local t1, t2 = evo.id(2)
    local e = evo.builder():set(f, { t1, t2, t1, t2, t1 }):build()

    evo.destroy(t1)

    do
        local l = evo.get(e, f)
        assert(#l == 2 and l[1] == t2 and l[2] == t2)
    end

    assert(evo.search(f, t2) == e)

    evo.destroy(t2)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_UNLINK_TARGET):build()

    local t1, t2 = evo.id(2)

    local l = { t1, t2 }
    local e1 = evo.builder():set(f, l):build()
    local e2 = evo.builder():set(f, l):build()

    evo.destroy(t1)

    do
        local l1, l2 = evo.get(e1, f), evo.get(e2, f)
        assert(l1 ~= l and #l1 == 1 and l1[1] == t2)
        assert(l2 ~= l and #l2 == 1 and l2[1] == t2)
        assert(#l == 2 and l[1] == t1 and l[2] == t2)
    end

    do
        local rl, rc = evo.multi_search(f, t2)
        assert(rc == 2 and rl[1] == e1 and rl[2] == e2)
    end
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_UNLINK_TARGET):build()

    local t1, t2 = evo.id(2)
    local e1 = evo.builder():set(f, { t1, t2 }):build()
    local e2 = evo.builder():set(f, { t1, t2 }):build()

    evo.destroy(t1, e1)
    assert(not evo.alive_any(t1, e1))
    assert(evo.alive(e2))

    do
        local l = evo.get(e2, f)
        assert(#l == 1 and l[1] == t2)
    end

    assert(evo.search(f, t2) == e2)
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_UNLINK_TARGET):build()

    local t1, t2 = evo.id(2)
    local e = evo.builder():set(f, { t1, t2 }):build()

    evo.destroy(f, t1)
    assert(not evo.alive_any(f, t1))
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local g = evo.builder():build()

    local set_count, assign_count, remove_count = 0, 0, 0

    local f = evo.builder()
        :link()
        :link_policy(evo.LINK_POLICY_UNLINK_TARGET)
        :on_set(function(e, _, nl, ol)
            assert(evo.alive(e))
            if ol then
                assert(#ol == 3 and #nl == 1)
                for _, t in ipairs(ol) do assert(evo.alive(t) and evo.get(t, g) == 42) end
                set_count = set_count + 1
            end
        end)
        :on_assign(function(_, _, nl, ol)
            assert(#ol == 3 and #nl == 1)
            assign_count = assign_count + 1
        end)
        :on_remove(function(_, _, ol)
            assert(#ol == 1)
            remove_count = remove_count + 1
        end)
        :build()

    local t1 = evo.builder():set(g, 42):build()
    local t2 = evo.builder():set(g, 42):build()
    local t3 = evo.builder():set(g, 42):build()

    local e = evo.builder():set(f, { t1, t2, t3 }):build()

    evo.destroy(t1, t3)
    assert(set_count == 1 and assign_count == 1 and remove_count == 0)

    evo.destroy(t2)
    assert(set_count == 1 and assign_count == 1 and remove_count == 1)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_UNLINK_TARGET):build()

    local t1, t2, t3 = evo.id(3)
    local e = evo.builder():set(f, { t1, t2, t3 }):build()

    evo.defer()
    do
        evo.destroy(t1)
        evo.destroy(t3)

        local l = evo.get(e, f)
        assert(#l == 3)
    end
    evo.commit()

    do
        local l = evo.get(e, f)
        assert(#l == 1 and l[1] == t2)
    end
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_UNLINK_TARGET):build()

    local t1, t2, t3 = evo.id(3)
    local e = evo.builder():set(f, { t1, t2 }):build()

    evo.defer()
    do
        evo.destroy(t1)
        evo.set(e, f, { t2, t3 })
    end
    evo.commit()

    do
        local l = evo.get(e, f)
        assert(#l == 2 and l[1] == t2 and l[2] == t3)
    end
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_UNLINK_TARGET):build()
    local g = evo.builder():tag():build()

    local t1 = evo.builder():set(g):build()
    local t2 = evo.builder():build()
    local t3 = evo.builder():set(g):build()

    local e = evo.builder():set(f, { t1, t2, t3 }):build()

    local q = evo.builder():include(g):build()

    evo.batch_destroy(q)
    assert(not evo.alive_any(t1, t3))

    do
        local l = evo.get(e, f)
        assert(#l == 1 and l[1] == t2)
    end
end

do
    local f = evo.builder():link():build()

    local t1, t2, t3 = evo.id(3)
    local e = evo.builder():set(f, { t1, t2, t3 }):build()

    evo.set(f, evo.LINK_POLICY, evo.LINK_POLICY_UNLINK_TARGET)

    evo.destroy(t2)

    do
        local l = evo.get(e, f)
        assert(#l == 2 and l[1] == t1 and l[2] == t3)
    end

    evo.remove(f, evo.LINK_POLICY)

    evo.destroy(t3)
    assert(evo.alive(e) and not evo.has(e, f))
end

do
    local parent = evo.builder()
        :link()
        :link_policy(evo.LINK_POLICY_DESTROY_ENTITY)
        :build()

    local children = evo.builder()
        :link()
        :link_policy(evo.LINK_POLICY_UNLINK_TARGET)
        :build()

    local root = evo.id()

    local c1 = evo.builder():set(parent, root):build()
    local c2 = evo.builder():set(parent, root):build()
    local c3 = evo.builder():set(parent, root):build()

    evo.set(root, children, { c1, c2, c3 })

    local gc1 = evo.builder():set(parent, c2):build()
    local gc2 = evo.builder():set(parent, c2):build()

    evo.set(c2, children, { gc1, gc2 })

    evo.destroy(c2)
    assert(not evo.alive_any(c2, gc1, gc2))
    assert(evo.alive_all(root, c1, c3))

    do
        local l = evo.get(root, children)
        assert(#l == 2 and l[1] == c1 and l[2] == c3)
    end

    evo.destroy(c1, c3)
    assert(evo.alive(root) and not evo.has(root, children))

    local c4 = evo.builder():set(parent, root):build()
    evo.set(root, children, { c4 })

    evo.destroy(root)
    assert(not evo.alive_any(root, c4))
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_UNLINK_TARGET):build()

    local e1, e2, e3 = evo.id(3)
    evo.set(e1, f, { e2, e3 })
    evo.set(e2, f, { e1, e3 })
    evo.set(e3, f, { e1, e2 })

    evo.destroy(e2)
    assert(evo.alive_all(e1, e3))

    do
        local l1, l3 = evo.get(e1, f), evo.get(e3, f)
        assert(#l1 == 1 and l1[1] == e3)
        assert(#l3 == 1 and l3[1] == e1)
    end

    evo.destroy(e1)
    assert(evo.alive(e3) and not evo.has(e3, f))
end

do
    local removed_list = {}
    local assigned_list = {}

    local f1 = evo.builder()
        :link()
        :on_remove(function(e) removed_list[#removed_list + 1] = e end)
        :build()

    local f2 = evo.builder()
        :link()
        :link_policy(evo.LINK_POLICY_UNLINK_TARGET)
        :on_assign(function(e) assigned_list[#assigned_list + 1] = e end)
        :build()

    local t1, t2 = evo.id(2)

    local e1 = evo.builder():set(f1, t1):set(f2, { t1, t2 }):build()
    local e2 = evo.builder():set(f1, t1):set(f2, { t1, t2 }):build()
    local e3 = evo.builder():set(f1, t1):set(f2, { t1, t2 }):build()

    evo.destroy(t1)

    assert(#removed_list == 3)
    assert(removed_list[1] == e1 and removed_list[2] == e2 and removed_list[3] == e3)

    assert(#assigned_list == 3)
    assert(assigned_list[1] == e1 and assigned_list[2] == e2 and assigned_list[3] == e3)

    do
        local l, c = evo.multi_search(f2, t2)
        assert(c == 3 and l[1] == e1 and l[2] == e2 and l[3] == e3)
    end
end

do
    local f = evo.builder():link():link_policy(evo.LINK_POLICY_UNLINK_TARGET):build()

    local t1, t2, t3 = evo.id(3)

    local e1 = evo.builder():set(f, { t1, t2, t3 }):build()
    local e2 = evo.builder():set(f, { t2, t3 }):build()
    local e3 = evo.builder():set(f, { t3, t1, t2 }):build()
    local e4 = evo.builder():set(f, { t2 }):build()

    evo.destroy(t1)

    do
        local l1, l3 = evo.get(e1, f), evo.get(e3, f)
        assert(#l1 == 2 and l1[1] == t2 and l1[2] == t3)
        assert(#l3 == 2 and l3[1] == t3 and l3[2] == t2)
    end

    do
        local l, c = evo.multi_search(f, t2)
        assert(c == 4 and l[1] == e1 and l[2] == e2 and l[3] == e3 and l[4] == e4)
    end

    do
        local l, c = evo.multi_search(f, t3)
        assert(c == 3 and l[1] == e1 and l[2] == e2 and l[3] == e3)
    end

    evo.destroy(t3)

    do
        local l, c = evo.multi_search(f, t2)
        assert(c == 4 and l[1] == e1 and l[2] == e2 and l[3] == e3 and l[4] == e4)
    end
end

do
    local f1 = evo.builder():link():build()
    local f2 = evo.builder():link():link_policy(evo.LINK_POLICY_DESTROY_ENTITY):build()
    local f3 = evo.builder():link():link_policy(evo.LINK_POLICY_UNLINK_TARGET):build()

    do
        local t1, t2 = evo.id(2)

        local e1 = evo.builder():set(f1, t1):build()
        local e2 = evo.builder():set(f2, t1):build()
        local e3 = evo.builder():set(f3, { t1, t2 }):build()
        local e4 = evo.builder():set(f2, t1):build()

        evo.remove(e2, f2)

        evo.destroy(t1)
        assert(evo.alive_all(e1, e2, e3) and not evo.alive(e4))
        assert(not evo.has(e1, f1) and not evo.has(e2, f2))

        do
            local l = evo.get(e3, f3)
            assert(#l == 1 and l[1] == t2)
        end
    end

    do
        local t = evo.id()

        local e1 = evo.builder():set(f1, t):build()
        local e2 = evo.builder():set(f2, t):build()

        evo.remove(e1, f1)
        evo.remove(e2, f2)

        local e3 = evo.builder():set(f2, t):build()
        local e4 = evo.builder():set(f1, t):build()

        evo.remove(e3, f2)

        evo.destroy(t)
        assert(evo.alive_all(e1, e2, e3, e4))
        assert(not evo.has(e4, f1))
    end

    do
        local t = evo.id()

        local e1 = evo.builder():set(f1, t):build()
        evo.remove(e1, f1)

        local e2 = evo.builder():set(f2, t):build()

        evo.destroy(t)
        assert(evo.alive(e1) and not evo.alive(e2))
    end
end
