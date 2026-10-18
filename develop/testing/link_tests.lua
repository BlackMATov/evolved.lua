local evo = require 'evolved'

evo.debug_mode(true)

do
    assert(evo.has_all(evo.GROUP, evo.LINK, evo.INDEX))
    assert(evo.get(evo.GROUP, evo.LINK_POLICY) == evo.LINK_POLICY_DESTROY_ENTITY)

    assert(evo.has_all(evo.QUERY, evo.LINK, evo.INDEX))
    assert(evo.get(evo.QUERY, evo.LINK_POLICY) == evo.LINK_POLICY_DESTROY_ENTITY)
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
