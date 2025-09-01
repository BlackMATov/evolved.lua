local evo = require 'evolved'

do
    do
        local p, s = evo.unpair(evo.pair(evo.ANY, evo.ANY))
        assert(p == evo.ANY and s == evo.ANY)
    end

    do
        local f = evo.id()
        local p, s = evo.unpair(evo.pair(evo.ANY, f))
        assert(p == evo.ANY and s == f)
    end

    do
        local f = evo.id()
        local p, s = evo.unpair(evo.pair(f, evo.ANY))
        assert(p == f and s == evo.ANY)
    end

    do
        local fp, fs = evo.id(2)
        local p, s = evo.unpair(evo.pair(fp, fs))
        assert(p == fp and s == fs)
    end
end

do
    local p, s1, s2 = evo.id(3)

    local e1 = evo.id()
    evo.set(e1, evo.pair(p, s1), 11)

    local e12 = evo.id()
    evo.set(e12, evo.pair(p, s1), 21)
    evo.set(e12, evo.pair(p, s2), 42)

    assert(evo.has(e1, evo.pair(p, s1)))
    assert(evo.get(e1, evo.pair(p, s1)) == 11)
    assert(evo.has(e12, evo.pair(p, s1)))
    assert(evo.get(e12, evo.pair(p, s1)) == 21)

    assert(not evo.has(e1, evo.pair(p, s2)))
    assert(evo.get(e1, evo.pair(p, s2)) == nil)
    assert(evo.has(e12, evo.pair(p, s2)))
    assert(evo.get(e12, evo.pair(p, s2)) == 42)

    assert(evo.has(e1, evo.pair(p, evo.ANY)))
    assert(evo.has(e1, evo.pair(evo.ANY, s1)))
    assert(not evo.has(e1, evo.pair(evo.ANY, s2)))
    assert(evo.has(e12, evo.pair(p, evo.ANY)))
    assert(evo.has(e12, evo.pair(evo.ANY, s1)))
    assert(evo.has(e12, evo.pair(evo.ANY, s2)))

    assert(not evo.has_all(e1, evo.pair(evo.ANY, s1), evo.pair(evo.ANY, s2)))
    assert(evo.has_any(e1, evo.pair(evo.ANY, s1), evo.pair(evo.ANY, s2)))
    assert(evo.has_all(e12, evo.pair(evo.ANY, s1), evo.pair(evo.ANY, s2)))
    assert(evo.has_any(e12, evo.pair(evo.ANY, s1), evo.pair(evo.ANY, s2)))
end

do
    local p1, p2, s = evo.id(3)

    local e1 = evo.id()
    evo.set(e1, evo.pair(p1, s), 11)

    local e12 = evo.id()
    evo.set(e12, evo.pair(p1, s), 21)
    evo.set(e12, evo.pair(p2, s), 42)

    assert(evo.has(e1, evo.pair(p1, s)))
    assert(evo.get(e1, evo.pair(p1, s)) == 11)
    assert(evo.has(e12, evo.pair(p1, s)))
    assert(evo.get(e12, evo.pair(p1, s)) == 21)

    assert(not evo.has(e1, evo.pair(p2, s)))
    assert(evo.get(e1, evo.pair(p2, s)) == nil)
    assert(evo.has(e12, evo.pair(p2, s)))
    assert(evo.get(e12, evo.pair(p2, s)) == 42)

    assert(evo.has(e1, evo.pair(p1, evo.ANY)))
    assert(not evo.has(e1, evo.pair(p2, evo.ANY)))
    assert(evo.has(e1, evo.pair(evo.ANY, s)))
    assert(evo.has(e12, evo.pair(p1, evo.ANY)))
    assert(evo.has(e12, evo.pair(p2, evo.ANY)))
    assert(evo.has(e12, evo.pair(evo.ANY, s)))

    assert(not evo.has_all(e1, evo.pair(p1, evo.ANY), evo.pair(p2, evo.ANY)))
    assert(evo.has_any(e1, evo.pair(p1, evo.ANY), evo.pair(p2, evo.ANY)))
    assert(evo.has_all(e12, evo.pair(p1, evo.ANY), evo.pair(p2, evo.ANY)))
    assert(evo.has_any(e12, evo.pair(p1, evo.ANY), evo.pair(p2, evo.ANY)))
end

do
    local p1, s1, p2, s2 = evo.id(4)
    evo.set(p1, s1)
    evo.set(s1, p1)
    evo.set(p2, s2)
    assert(evo.empty(evo.pair(p1, s1)))
    assert(evo.empty(evo.pair(p2, s2)))
    assert(evo.empty_all(evo.pair(p1, s1), evo.pair(p2, s2)))
    assert(evo.empty_any(evo.pair(p1, s1), evo.pair(p2, s2)))
    assert(not evo.empty_all(evo.pair(p1, s1), evo.pair(p2, s2), p1))
    assert(evo.empty_any(evo.pair(p1, s1), evo.pair(p2, s2), p1))
    assert(evo.empty_all(evo.pair(p1, s1), evo.pair(p2, s2), s2))
    assert(evo.empty_any(evo.pair(p1, s1), evo.pair(p2, s2), s2))
end

do
    local p1, s1 = evo.id(2)
    evo.set(p1, s1)
    evo.set(s1, p1)
    assert(not evo.has(evo.pair(p1, s1), p1))
    assert(not evo.has(evo.pair(p1, s1), s1))
    assert(not evo.has_all(evo.pair(p1, s1), p1, s1))
    assert(not evo.has_any(evo.pair(p1, s1), p1, s1))
    assert(evo.get(evo.pair(p1, s1), p1) == nil)
    assert(evo.get(evo.pair(p1, s1), s1) == nil)
end

do
    local p, s1, s2 = evo.id(3)

    do
        local e = evo.builder()
            :set(evo.pair(p, s1), 21)
            :set(evo.pair(p, s2), 42)
            :spawn()

        evo.remove(e, evo.pair(p, s1))

        assert(not evo.has(e, evo.pair(p, s1)))
        assert(evo.get(e, evo.pair(p, s1)) == nil)

        assert(evo.has(e, evo.pair(p, s2)))
        assert(evo.get(e, evo.pair(p, s2)) == 42)

        evo.remove(e, evo.pair(p, s2))

        assert(not evo.has(e, evo.pair(p, s2)))
        assert(evo.get(e, evo.pair(p, s2)) == nil)

        assert(not evo.has(e, evo.pair(p, s2)))
        assert(evo.get(e, evo.pair(p, s2)) == nil)
    end

    do
        local e = evo.builder()
            :set(evo.pair(p, s1), 21)
            :set(evo.pair(p, s2), 42)
            :spawn()

        evo.remove(e, evo.pair(p, s2))

        assert(evo.has(e, evo.pair(p, s1)))
        assert(evo.get(e, evo.pair(p, s1)) == 21)

        assert(not evo.has(e, evo.pair(p, s2)))
        assert(evo.get(e, evo.pair(p, s2)) == nil)

        evo.remove(e, evo.pair(p, s1))

        assert(not evo.has(e, evo.pair(p, s1)))
        assert(evo.get(e, evo.pair(p, s1)) == nil)

        assert(not evo.has(e, evo.pair(p, s2)))
        assert(evo.get(e, evo.pair(p, s2)) == nil)
    end
end

do
    local p1, p2, s1, s2 = evo.id(4)

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 11)
            :set(evo.pair(p1, s2), 12)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 22)
            :spawn()

        evo.remove(e, evo.pair(p1, evo.ANY))

        assert(not evo.has(e, evo.pair(p1, s1)))
        assert(not evo.has(e, evo.pair(p1, s2)))
        assert(not evo.has(e, evo.pair(p1, evo.ANY)))

        assert(evo.has(e, evo.pair(p2, s1)))
        assert(evo.get(e, evo.pair(p2, s1)) == 21)
        assert(evo.has(e, evo.pair(p2, s2)))
        assert(evo.get(e, evo.pair(p2, s2)) == 22)
        assert(evo.has(e, evo.pair(p2, evo.ANY)))
    end

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 11)
            :set(evo.pair(p1, s2), 12)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 22)
            :spawn()

        evo.remove(e, evo.pair(p2, evo.ANY))

        assert(not evo.has(e, evo.pair(p2, s1)))
        assert(not evo.has(e, evo.pair(p2, s2)))
        assert(not evo.has(e, evo.pair(p2, evo.ANY)))

        assert(evo.has(e, evo.pair(p1, s1)))
        assert(evo.get(e, evo.pair(p1, s1)) == 11)
        assert(evo.has(e, evo.pair(p1, s2)))
        assert(evo.get(e, evo.pair(p1, s2)) == 12)
        assert(evo.has(e, evo.pair(p1, evo.ANY)))
    end

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 11)
            :set(evo.pair(p1, s2), 12)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 22)
            :spawn()

        evo.remove(e, evo.pair(evo.ANY, s1))

        assert(not evo.has(e, evo.pair(p1, s1)))
        assert(not evo.has(e, evo.pair(p2, s1)))
        assert(not evo.has(e, evo.pair(evo.ANY, s1)))

        assert(evo.has(e, evo.pair(p1, s2)))
        assert(evo.get(e, evo.pair(p1, s2)) == 12)
        assert(evo.has(e, evo.pair(p2, s2)))
        assert(evo.get(e, evo.pair(p2, s2)) == 22)
    end

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 11)
            :set(evo.pair(p1, s2), 12)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 22)
            :spawn()

        evo.remove(e, evo.pair(evo.ANY, s2))

        assert(not evo.has(e, evo.pair(p1, s2)))
        assert(not evo.has(e, evo.pair(p2, s2)))
        assert(not evo.has(e, evo.pair(evo.ANY, s2)))

        assert(evo.has(e, evo.pair(p1, s1)))
        assert(evo.get(e, evo.pair(p1, s1)) == 11)
        assert(evo.has(e, evo.pair(p2, s1)))
        assert(evo.get(e, evo.pair(p2, s1)) == 21)
    end

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 11)
            :set(evo.pair(p1, s2), 12)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 22)
            :set(p1, s1)
            :set(p2, s2)
            :spawn()

        evo.remove(e, evo.pair(evo.ANY, evo.ANY))

        assert(not evo.has(e, evo.pair(p1, s1)))
        assert(not evo.has(e, evo.pair(p1, s2)))
        assert(not evo.has(e, evo.pair(p2, s1)))
        assert(not evo.has(e, evo.pair(p2, s2)))

        assert(evo.has(e, p1) and evo.get(e, p1) == s1)
        assert(evo.has(e, p2) and evo.get(e, p2) == s2)
    end
end

do
    local p1, s1, p2, s2 = evo.id(4)

    local e = evo.builder()
        :set(evo.pair(p1, s1), 42)
        :spawn()

    evo.remove(e, evo.pair(p2, evo.ANY))
    evo.remove(e, evo.pair(evo.ANY, s2))

    assert(evo.has(e, evo.pair(p1, s1)))
    assert(evo.get(e, evo.pair(p1, s1)) == 42)

    evo.remove(e, evo.pair(p1, s1))

    assert(not evo.has(e, evo.pair(p1, s1)))
    assert(evo.get(e, evo.pair(p1, s1)) == nil)
end

do
    local f1, f2, f3, p1, s1, p2, s2 = evo.id(7)
    evo.set(f1, evo.REQUIRES, { f2 })
    evo.set(f2, evo.DEFAULT, 84)
    evo.set(f2, evo.REQUIRES, { evo.pair(p2, s2) })
    evo.set(p1, evo.REQUIRES, { f3 })
    evo.set(s1, evo.REQUIRES, { f3 })
    evo.set(p2, evo.REQUIRES, { f3 })
    evo.set(s2, evo.REQUIRES, { f3 })

    local e = evo.builder()
        :set(f1, 21)
        :set(evo.pair(p1, s1), 42)
        :spawn()

    assert(evo.has(e, evo.pair(p1, s1)))
    assert(evo.get(e, evo.pair(p1, s1)) == 42)

    assert(evo.has(e, evo.pair(p2, s2)))
    assert(evo.get(e, evo.pair(p2, s2)) == true)

    assert(evo.has(e, f1))
    assert(evo.get(e, f1) == 21)

    assert(evo.has(e, f2))
    assert(evo.get(e, f2) == 84)

    assert(evo.has(e, f3))
    assert(evo.get(e, f3) == true)
end

do
    local p1, p2, s1, s2 = evo.id(4)

    do
        local e1 = evo.builder()
            :set(evo.pair(p1, s1))
            :set(evo.pair(p1, s2))
            :spawn()

        local e2 = evo.clone(e1)

        evo.remove(e1, evo.pair(p1, evo.ANY))
        evo.remove(e2, evo.pair(p1, evo.ANY))
        assert(evo.empty_all(e1, e2))
    end

    do
        local e1 = evo.builder()
            :set(evo.pair(p1, s1))
            :set(evo.pair(p2, s1))
            :spawn()

        local e2 = evo.clone(e1)

        evo.remove(e1, evo.pair(evo.ANY, s1))
        evo.remove(e2, evo.pair(evo.ANY, s1))
        assert(evo.empty_all(e1, e2))
    end

    do
        local e1 = evo.builder()
            :set(evo.pair(p1, s1))
            :set(evo.pair(p1, s2))
            :set(evo.pair(p2, s1))
            :set(evo.pair(p2, s2))
            :spawn()

        local e2 = evo.clone(e1)

        evo.remove(e1, evo.pair(evo.ANY, evo.ANY))
        evo.remove(e2, evo.pair(evo.ANY, evo.ANY))
        assert(evo.empty_all(e1, e2))
    end
end

do
    local f, p1, p2, s1, s2 = evo.id(5)

    do
        local e1 = evo.builder()
            :set(f, 42)
            :set(evo.pair(p1, s1))
            :set(evo.pair(p1, s2))
            :spawn()

        local e2 = evo.clone(e1)

        evo.remove(e1, evo.pair(p1, evo.ANY))
        evo.remove(e2, evo.pair(p1, evo.ANY))

        assert(evo.has(e1, f) and evo.has(e2, f))
        assert(not evo.has(e1, evo.pair(evo.ANY, evo.ANY)))
    end

    do
        local e1 = evo.builder()
            :set(f, 42)
            :set(evo.pair(p1, s1))
            :set(evo.pair(p2, s1))
            :spawn()

        local e2 = evo.clone(e1)

        evo.remove(e1, evo.pair(evo.ANY, s1))
        evo.remove(e2, evo.pair(evo.ANY, s1))

        assert(evo.has(e1, f) and evo.has(e2, f))
        assert(not evo.has(e1, evo.pair(evo.ANY, evo.ANY)))
    end

    do
        local e1 = evo.builder()
            :set(f, 42)
            :set(evo.pair(p1, s1))
            :set(evo.pair(p1, s2))
            :set(evo.pair(p2, s1))
            :set(evo.pair(p2, s2))
            :spawn()

        local e2 = evo.clone(e1)

        evo.remove(e1, evo.pair(evo.ANY, evo.ANY))
        evo.remove(e2, evo.pair(evo.ANY, evo.ANY))

        assert(evo.has(e1, f) and evo.has(e2, f))
        assert(not evo.has(e1, evo.pair(evo.ANY, evo.ANY)))
    end
end

do
    do
        local p, s = evo.id(2)
        evo.set(p, evo.NAME, 'p')
        evo.set(s, evo.NAME, 's')
        local ps_chunk = evo.chunk(evo.pair(p, s))
        assert(tostring(ps_chunk) == '<${p,s}>')
    end
    do
        local p, s = evo.id(2)
        local ps_chunk = evo.chunk(evo.pair(p, s))
        evo.set(p, evo.NAME, 'p')
        evo.set(s, evo.NAME, 's')
        evo.destroy(p)
        assert(tostring(ps_chunk) ~= '<${p,s}>')
    end
    do
        local p, s = evo.id(2)
        local ps_chunk = evo.chunk(evo.pair(p, s))
        evo.set(p, evo.NAME, 'p')
        evo.set(s, evo.NAME, 's')
        evo.destroy(s)
        assert(tostring(ps_chunk) ~= '<${p,s}>')
    end
    do
        local p, s = evo.id(2)
        local ps_chunk = evo.chunk(evo.pair(p, s))
        evo.set(p, evo.NAME, 'p')
        evo.set(s, evo.NAME, 's')
        evo.destroy(p, s)
        assert(tostring(ps_chunk) ~= '<${p,s}>')
    end
end

do
    do
        local p, s = evo.id(2)
        local ps = evo.pair(evo.ANY, s)
        local e = evo.id()
        evo.set(e, p, 42)
        evo.destroy(s)
        evo.remove(e, ps)
    end

    do
        local p, s = evo.id(2)
        local ps = evo.pair(p, evo.ANY)
        local e = evo.id()
        evo.set(e, s, 42)
        evo.destroy(p)
        evo.remove(e, ps)
    end
end

do
    local p, s = evo.id(2)

    local e = evo.id()
    assert(not evo.has(e, evo.pair(p, s)))
    assert(not evo.has(e, evo.pair(p, evo.ANY)))
    assert(not evo.has(e, evo.pair(evo.ANY, s)))
    assert(not evo.has(e, evo.pair(evo.ANY, evo.ANY)))

    evo.set(e, p)
    assert(not evo.has(e, evo.pair(p, s)))
    assert(not evo.has(e, evo.pair(p, evo.ANY)))
    assert(not evo.has(e, evo.pair(evo.ANY, s)))
    assert(not evo.has(e, evo.pair(evo.ANY, evo.ANY)))

    evo.set(e, s)
    assert(not evo.has(e, evo.pair(p, s)))
    assert(not evo.has(e, evo.pair(p, evo.ANY)))
    assert(not evo.has(e, evo.pair(evo.ANY, s)))
    assert(not evo.has(e, evo.pair(evo.ANY, evo.ANY)))

    evo.set(e, evo.pair(p, s))
    assert(evo.has(e, evo.pair(p, s)))
    assert(evo.has(e, evo.pair(p, evo.ANY)))
    assert(evo.has(e, evo.pair(evo.ANY, s)))
    assert(evo.has(e, evo.pair(evo.ANY, evo.ANY)))
end

do
    local p1, s1, p2, s2 = evo.id(4)

    local e = evo.builder():set(evo.pair(p1, s1)):spawn()
    assert(evo.has(e, evo.pair(p1, s1)))
    assert(evo.has(e, evo.pair(p1, evo.ANY)))
    assert(evo.has(e, evo.pair(evo.ANY, s1)))
    assert(evo.has(e, evo.pair(evo.ANY, evo.ANY)))
    assert(not evo.has(e, evo.pair(p1, s2)))
    assert(not evo.has(e, evo.pair(p2, s1)))
    assert(not evo.has(e, evo.pair(p2, s2)))
    assert(not evo.has(e, evo.pair(p2, evo.ANY)))
    assert(not evo.has(e, evo.pair(evo.ANY, s2)))

    evo.set(e, evo.pair(p2, s2))

    assert(evo.has(e, evo.pair(p1, s1)))
    assert(evo.has(e, evo.pair(p1, evo.ANY)))
    assert(evo.has(e, evo.pair(evo.ANY, s1)))
    assert(evo.has(e, evo.pair(evo.ANY, evo.ANY)))
    assert(not evo.has(e, evo.pair(p1, s2)))
    assert(not evo.has(e, evo.pair(p2, s1)))
    assert(evo.has(e, evo.pair(p2, s2)))
    assert(evo.has(e, evo.pair(p2, evo.ANY)))
    assert(evo.has(e, evo.pair(evo.ANY, s2)))
end

do
    local p1, s1, s2 = evo.id(3)

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 42)
            :spawn()

        evo.set(e, evo.pair(p1, s1), 84)
        assert(evo.get(e, evo.pair(p1, s1)) == 84)
        assert(evo.get(e, evo.pair(p1, s2)) == nil)

        evo.set(e, evo.pair(p1, s2), 42)
        assert(evo.get(e, evo.pair(p1, s1)) == 84)
        assert(evo.get(e, evo.pair(p1, s2)) == 42)
    end
end

do
    local p1, s1, p2, s2 = evo.id(4)

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 42)
            :set(evo.pair(p1, s2), 84)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 63)
            :spawn()

        evo.remove(e, evo.pair(p1, evo.ANY))
        assert(not evo.has(e, evo.pair(p1, s1)))
        assert(evo.get(e, evo.pair(p1, s1)) == nil)
        assert(not evo.has(e, evo.pair(p1, s2)))
        assert(evo.get(e, evo.pair(p1, s2)) == nil)
        assert(evo.has(e, evo.pair(p2, s1)))
        assert(evo.get(e, evo.pair(p2, s1)) == 21)
        assert(evo.has(e, evo.pair(p2, s2)))
        assert(evo.get(e, evo.pair(p2, s2)) == 63)
    end

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 42)
            :set(evo.pair(p1, s2), 84)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 63)
            :spawn()

        evo.remove(e, evo.pair(evo.ANY, s2))
        assert(evo.has(e, evo.pair(p1, s1)))
        assert(evo.get(e, evo.pair(p1, s1)) == 42)
        assert(not evo.has(e, evo.pair(p1, s2)))
        assert(evo.get(e, evo.pair(p1, s2)) == nil)
        assert(evo.has(e, evo.pair(p2, s1)))
        assert(evo.get(e, evo.pair(p2, s1)) == 21)
        assert(not evo.has(e, evo.pair(p2, s2)))
        assert(evo.get(e, evo.pair(p2, s2)) == nil)
    end
end

do
    local p1, p2, s1, s2 = evo.id(4)

    ---@param o evolved.entity
    ---@param s evolved.fragment
    ---@return evolved.fragment[], evolved.component[], number
    local function collect_primaries(o, s)
        local fragments, components, count = {}, {}, 0

        for f, c in evo.primaries(o, s) do
            count = count + 1

            fragments[count] = f
            components[count] = c

            do
                local ff, cc = evo.primary(o, s, count)
                assert(ff == f and cc == c)
            end
        end

        assert(evo.primary_count(o, s) == count)
        return fragments, components, count
    end

    ---@param o evolved.entity
    ---@param p evolved.fragment
    ---@return evolved.fragment[], evolved.component[], number
    local function collect_secondaries(o, p)
        local fragments, components, count = {}, {}, 0

        for f, c in evo.secondaries(o, p) do
            count = count + 1
            fragments[count] = f
            components[count] = c
        end

        return fragments, components, count
    end

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 42)
            :spawn()

        assert(evo.primary(e, s1) == p1)
        assert(evo.primary(e, s2) == nil)

        assert(evo.secondary(e, p1) == s1)
        assert(evo.secondary(e, p2) == nil)

        assert(evo.primary_count(e, s1) == 1)
        assert(evo.primary_count(e, s2) == 0)
        assert(evo.secondary_count(e, p1) == 1)
        assert(evo.secondary_count(e, p2) == 0)

        do
            local p_list, c_list, count = collect_primaries(e, s1)
            assert(#p_list == 1 and #c_list == 1 and count == 1)
            assert(p_list[1] == p1 and c_list[1] == 42)
        end

        do
            local p_list, c_list, count = collect_primaries(e, s2)
            assert(#p_list == 0 and #c_list == 0 and count == 0)
        end

        do
            local s_list, c_list, count = collect_secondaries(e, p1)
            assert(#s_list == 1 and #c_list == 1 and count == 1)
            assert(s_list[1] == s1 and c_list[1] == 42)
        end

        do
            local s_list, c_list, count = collect_secondaries(e, p2)
            assert(#s_list == 0 and #c_list == 0 and count == 0)
        end
    end

    do
        local e = evo.builder()
            :set(evo.pair(p1, s1), 42)
            :set(evo.pair(p1, s2), 84)
            :set(evo.pair(p2, s1), 21)
            :set(evo.pair(p2, s2), 63)
            :spawn()

        do
            assert(evo.primary_count(e, s1) == 2)
            assert(evo.primary_count(e, s2) == 2)
            assert(evo.secondary_count(e, p1) == 2)
            assert(evo.secondary_count(e, p2) == 2)
        end

        do
            local pp, cc = evo.primary(e, s1)
            assert(pp == p1 and cc == 42)

            pp, cc = evo.primary(e, s1, 1)
            assert(pp == p1 and cc == 42)

            pp, cc = evo.primary(e, s1, 2)
            assert(pp == p2 and cc == 21)

            pp, cc = evo.primary(e, s1, 3)
            assert(pp == nil and cc == nil)
        end

        do
            local pp, cc = evo.primary(e, s2)
            assert(pp == p1 and cc == 84)

            pp, cc = evo.primary(e, s2, 1)
            assert(pp == p1 and cc == 84)

            pp, cc = evo.primary(e, s2, 2)
            assert(pp == p2 and cc == 63)

            pp, cc = evo.primary(e, s2, 3)
            assert(pp == nil and cc == nil)
        end

        do
            local pp, cc = evo.secondary(e, p1)
            assert(pp == s1 and cc == 42)

            pp, cc = evo.secondary(e, p1, 1)
            assert(pp == s1 and cc == 42)

            pp, cc = evo.secondary(e, p1, 2)
            assert(pp == s2 and cc == 84)

            pp, cc = evo.secondary(e, p1, 3)
            assert(pp == nil and cc == nil)
        end

        do
            local pp, cc = evo.secondary(e, p2)
            assert(pp == s1 and cc == 21)

            pp, cc = evo.secondary(e, p2, 1)
            assert(pp == s1 and cc == 21)

            pp, cc = evo.secondary(e, p2, 2)
            assert(pp == s2 and cc == 63)

            pp, cc = evo.secondary(e, p2, 3)
            assert(pp == nil and cc == nil)
        end

        do
            local p_list, c_list, count = collect_primaries(e, s1)
            assert(#p_list == 2 and #c_list == 2 and count == 2)
            assert(p_list[1] == p1 and c_list[1] == 42)
            assert(p_list[2] == p2 and c_list[2] == 21)
        end

        do
            local p_list, c_list, count = collect_primaries(e, s2)
            assert(#p_list == 2 and #c_list == 2 and count == 2)
            assert(p_list[1] == p1 and c_list[1] == 84)
            assert(p_list[2] == p2 and c_list[2] == 63)
        end

        do
            local s_list, c_list, count = collect_secondaries(e, p1)
            assert(#s_list == 2 and #c_list == 2 and count == 2)
            assert(s_list[1] == s1 and c_list[1] == 42)
            assert(s_list[2] == s2 and c_list[2] == 84)
        end

        do
            local s_list, c_list, count = collect_secondaries(e, p2)
            assert(#s_list == 2 and #c_list == 2 and count == 2)
            assert(s_list[1] == s1 and c_list[1] == 21)
            assert(s_list[2] == s2 and c_list[2] == 63)
        end
    end
end

do
    local p, s = evo.id(2)

    local e = evo.id()

    assert(not evo.primary(e, s))
    assert(not evo.primary(e, s, 1))
    assert(not evo.primary(e, s, 2))
    assert(not evo.primary(e, s, 0))
    assert(not evo.primary(e, s, -1))
    assert(not evo.primary(e, s, -2))

    assert(not evo.secondary(e, p))
    assert(not evo.secondary(e, p, 1))
    assert(not evo.secondary(e, p, 2))
    assert(not evo.secondary(e, p, 0))
    assert(not evo.secondary(e, p, -1))
    assert(not evo.secondary(e, p, -2))

    assert(evo.primary_count(e, s) == 0)
    assert(evo.secondary_count(e, p) == 0)

    assert(evo.primaries(e, s)() == nil)
    assert(evo.secondaries(e, p)() == nil)
end

do
    local p1, p2, s1, s2 = evo.id(4)

    local e = evo.builder()
        :set(evo.pair(p1, s1), 42)
        :set(evo.pair(p1, s2), 84)
        :set(evo.pair(p2, s1), 21)
        :set(evo.pair(p2, s2), 63)
        :spawn()

    assert(evo.primary(e, evo.ANY) == nil)
    assert(evo.primary(e, evo.ANY, 1) == nil)
    assert(evo.primary(e, evo.ANY, 2) == nil)

    assert(evo.secondary(e, evo.ANY) == nil)
    assert(evo.secondary(e, evo.ANY, 1) == nil)
    assert(evo.secondary(e, evo.ANY, 2) == nil)

    assert(evo.primaries(e, evo.ANY)() == nil)
    assert(evo.secondaries(e, evo.ANY)() == nil)

    assert(evo.primary_count(e, evo.ANY) == 0)
    assert(evo.secondary_count(e, evo.ANY) == 0)
end

do
    do
        local p, s = evo.id(2)

        local e = evo.builder()
            :set(s)
            :set(evo.pair(p, s), 42)
            :spawn()

        evo.destroy(p)
        assert(evo.alive(e))
        assert(evo.has(e, s))
        assert(not evo.has(e, evo.pair(p, s)))
        assert(evo.get(e, evo.pair(p, s)) == nil)
    end

    do
        local p, s = evo.id(2)

        local e = evo.builder()
            :set(p)
            :set(evo.pair(p, s), 42)
            :spawn()

        evo.destroy(s)
        assert(evo.alive(e))
        assert(evo.has(e, p))
        assert(not evo.has(e, evo.pair(p, s)))
        assert(evo.get(e, evo.pair(p, s)) == nil)
    end

    do
        local p, s = evo.id(2)
        evo.set(p, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

        local e = evo.builder()
            :set(evo.pair(p, s), 42)
            :spawn()

        evo.destroy(p)
        assert(not evo.alive(e))
    end

    do
        local p, s = evo.id(2)
        evo.set(s, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

        local e = evo.builder()
            :set(evo.pair(p, s), 42)
            :spawn()

        evo.destroy(s)
        assert(not evo.alive(e))
    end
end

do
    local p1, s1 = evo.id(2)

    local e0 = evo.builder()
        :destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
        :spawn()

    local e1 = evo.builder()
        :set(evo.pair(p1, e0), 11)
        :destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
        :spawn()

    local e2 = evo.builder()
        :set(evo.pair(e1, s1), 22)
        :destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
        :spawn()

    local e3 = evo.builder()
        :set(evo.pair(e2, e2), 33)
        :spawn()

    evo.destroy(e0)
    assert(not evo.alive(e1))
    assert(not evo.alive(e2))
    assert(not evo.alive(e3))
end

do
    do
        local f, p, s = evo.id(3)

        local e = evo.builder():set(f, 21):set(evo.pair(p, s), 42):spawn()

        evo.destroy(f)
        assert(evo.get(e, f) == nil)
        assert(evo.get(e, evo.pair(p, s)) == 42)
    end

    do
        local f, p, s = evo.id(3)

        local e = evo.builder():set(f, 21):set(evo.pair(p, s), 42):spawn()

        evo.destroy(p)
        assert(evo.get(e, f) == 21)
        assert(evo.get(e, evo.pair(p, s)) == nil)
    end

    do
        local f, p, s = evo.id(3)

        local e = evo.builder():set(f, 21):set(evo.pair(p, s), 42):spawn()

        evo.destroy(s)
        assert(evo.get(e, f) == 21)
        assert(evo.get(e, evo.pair(p, s)) == nil)
    end

    do
        local f, p, s = evo.id(3)

        local e = evo.builder():set(f, 21):set(evo.pair(p, s), 42):spawn()

        evo.destroy(p, s)
        assert(evo.get(e, f) == 21)
        assert(evo.get(e, evo.pair(p, s)) == nil)
    end

    do
        local f, p, s = evo.id(3)

        local e = evo.builder():set(f, 21):set(evo.pair(p, s), 42):spawn()

        evo.destroy(f, p, s)
        assert(evo.alive(e) and evo.empty(e))
    end
end

do
    do
        local f, p, s = evo.id(3)
        evo.set(p, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

        local e = evo.builder():set(f, 21):set(evo.pair(p, s), 42):spawn()

        evo.destroy(p)
        assert(not evo.alive(e))
    end

    do
        local f, p, s = evo.id(3)
        evo.set(s, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

        local e = evo.builder():set(f, 21):set(evo.pair(p, s), 42):spawn()

        evo.destroy(p)
        assert(evo.get(e, f) == 21)
        assert(evo.get(e, evo.pair(p, s)) == nil)
    end

    do
        local f, p, s = evo.id(3)
        evo.set(p, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

        local e = evo.builder():set(f, 21):set(evo.pair(p, s), 42):spawn()

        evo.destroy(s)
        assert(evo.get(e, f) == 21)
        assert(evo.get(e, evo.pair(p, s)) == nil)
    end

    do
        local f, p, s = evo.id(3)
        evo.set(s, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

        local e = evo.builder():set(f, 21):set(evo.pair(p, s), 42):spawn()

        evo.destroy(s)
        assert(not evo.alive(e))
    end
end

do
    local f, p, s = evo.id(3)

    local e = evo.builder():set(f, 21):set(evo.pair(p, s), 42):spawn()

    evo.destroy(evo.pair(p, s))
    evo.destroy(evo.pair(evo.ANY, s))
    evo.destroy(evo.pair(p, evo.ANY))
    evo.destroy(evo.pair(evo.ANY, evo.ANY))

    assert(evo.get(e, f) == 21)
    assert(evo.get(e, evo.pair(p, s)) == 42)
end

do
    evo.collect_garbage()

    local f, p1, s1, p2, s2 = evo.id(5)

    local e1 = evo.builder()
        :set(f, 21)
        :set(evo.pair(p1, s1), 42)
        :set(evo.pair(p2, s2), 84)
        :spawn()

    local e2 = evo.builder()
        :set(f, 21)
        :set(evo.pair(p1, s1), 42)
        :set(evo.pair(p2, s2), 84)
        :spawn()

    local f_chunk = evo.chunk(f)
    local f_p2s2_chunk = evo.chunk(f, evo.pair(p2, s2))
    local f_p1s1_p2s2_chunk = evo.chunk(f, evo.pair(p1, s1), evo.pair(p2, s2))

    assert(f_p1s1_p2s2_chunk:entities()[1] == e1)
    assert(f_p1s1_p2s2_chunk:entities()[2] == e2)

    evo.remove(e1, evo.pair(p1, evo.ANY))

    assert(f_p2s2_chunk:entities()[1] == e1)
    assert(f_p1s1_p2s2_chunk:entities()[1] == e2)

    evo.remove(e1, evo.pair(p2, evo.ANY))

    assert(f_chunk:entities()[1] == e1)
    assert(f_p1s1_p2s2_chunk:entities()[1] == e2)

    evo.collect_garbage()

    assert(f_chunk:alive())
    assert(not f_p2s2_chunk:alive())
    assert(f_p1s1_p2s2_chunk:alive())

    evo.remove(e2, evo.pair(p1, evo.ANY))

    local new_f_p2s2_chunk = evo.chunk(f, evo.pair(p2, s2))
    assert(new_f_p2s2_chunk:entities()[1] == e2)
end

do
    evo.collect_garbage()

    local f, p1, p2, s1, s2 = evo.id(5)

    local e1 = evo.builder()
        :set(f, 21)
        :set(evo.pair(p1, s1), 42)
        :set(evo.pair(p2, s2), 84)
        :spawn()

    local f_p1s1_p2s2_chunk = evo.chunk(f, evo.pair(p1, s1), evo.pair(p2, s2))
    assert(f_p1s1_p2s2_chunk:entities()[1] == e1)

    evo.destroy(p2, s2)

    evo.collect_garbage()

    local f_p1s1_chunk = evo.chunk(f, evo.pair(p1, s1))
    assert(f_p1s1_chunk:entities()[1] == e1)
end

do
    local f, p, s = evo.id(3)
    evo.set(p, evo.DEFAULT, 42)

    do
        local e = evo.id()
        evo.set(e, f)
        evo.set(e, evo.pair(p, s))
        assert(evo.has(e, f) and evo.get(e, f) == true)
        assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == 42)
    end

    do
        local e = evo.builder():set(f):set(evo.pair(p, s)):spawn()
        assert(evo.has(e, f) and evo.get(e, f) == true)
        assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == 42)
    end

    do
        local e = evo.builder():set(f, 84):set(evo.pair(p, s), 21):spawn()
        evo.set(e, f)
        evo.set(e, evo.pair(p, s))
        assert(evo.has(e, f) and evo.get(e, f) == true)
        assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == 42)
    end
end

do
    do
        local f, p, s = evo.id(3)
        assert(evo.empty(evo.pair(p, s)))

        evo.set(p, f)
        assert(evo.empty(evo.pair(p, s)))

        evo.destroy(p)
        assert(evo.empty(evo.pair(p, s)))
    end

    do
        local f, p, s = evo.id(3)
        assert(evo.empty(evo.pair(p, s)))

        evo.set(p, f)
        assert(evo.empty(evo.pair(p, s)))

        evo.destroy(s)
        assert(evo.empty(evo.pair(p, s)))

        evo.destroy(p)
        assert(evo.empty(evo.pair(p, s)))
    end

    do
        local f, p, s = evo.id(3)
        assert(not evo.has(p, f))
        assert(not evo.has(evo.pair(p, s), f))

        evo.set(p, f, 42)
        assert(evo.has(p, f))
        assert(not evo.has(evo.pair(p, s), f))
        assert(not evo.has(evo.pair(s, p), f))
        assert(evo.get(p, f) == 42)
        assert(evo.get(evo.pair(p, s), f) == nil)
        assert(evo.get(evo.pair(s, p), f) == nil)
    end
end

do
    local p, s = evo.id(3)

    local set_count = 0
    local insert_count = 0
    local remove_count = 0

    evo.set(p, evo.ON_SET, function(e, f, nc, oc)
        set_count = set_count + 1
        assert(f == p or f == evo.pair(p, s))
        assert(nc == 21 or nc == 42)
        assert(oc == nil or oc == 21)
        assert(evo.has(e, f))
        assert(evo.get(e, f) == nc)
    end)

    evo.set(p, evo.ON_INSERT, function(e, f, nc)
        insert_count = insert_count + 1
        assert(f == p or f == evo.pair(p, s))
        assert(nc == 21 or nc == 42)
        assert(evo.has(e, f))
        assert(evo.get(e, f) == nc)
    end)

    evo.set(p, evo.ON_REMOVE, function(e, f, oc)
        remove_count = remove_count + 1
        assert(f == p or f == evo.pair(p, s))
        assert(oc == 21 or oc == 42)
        assert(not evo.has(e, f))
    end)

    do
        set_count, insert_count, remove_count = 0, 0, 0
        local e = evo.id()
        evo.set(e, p, 21)
        evo.set(e, evo.pair(p, s), 42)
        assert(set_count == 2)
        assert(insert_count == 2)
        assert(remove_count == 0)
        evo.remove(e, p)
        assert(set_count == 2)
        assert(insert_count == 2)
        assert(remove_count == 1)
        evo.remove(e, evo.pair(p, s))
        assert(set_count == 2)
        assert(insert_count == 2)
        assert(remove_count == 2)
    end

    do
        set_count, insert_count, remove_count = 0, 0, 0
        local e = evo.id()
        evo.set(e, p, 21)
        evo.set(e, evo.pair(p, s), 42)
        assert(set_count == 2)
        assert(insert_count == 2)
        assert(remove_count == 0)
        evo.destroy(e)
        assert(set_count == 2)
        assert(insert_count == 2)
        assert(remove_count == 2)
    end
end

do
    do
        local f, p, s = evo.id(3)
        evo.set(p, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

        local e = evo.builder()
            :set(f, 21)
            :set(evo.pair(p, s), 42)
            :spawn()

        evo.destroy(p)

        assert(not evo.alive(e) and evo.empty(e))
        assert(not evo.has(e, f) and evo.get(e, f) == nil)
        assert(not evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == nil)
    end

    do
        local f, p, s = evo.id(3)
        evo.set(p, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

        local e = evo.builder()
            :set(f, 21)
            :set(evo.pair(p, s), 42)
            :spawn()

        evo.destroy(s)

        assert(evo.alive(e) and not evo.empty(e))
        assert(evo.has(e, f) and evo.get(e, f) == 21)
        assert(not evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == nil)
    end

    do
        local f, p, s = evo.id(3)
        evo.set(p, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)

        local e = evo.builder()
            :set(f, 21)
            :set(evo.pair(p, s), 42)
            :spawn()

        evo.destroy(p)

        assert(evo.alive(e) and not evo.empty(e))
        assert(evo.has(e, f) and evo.get(e, f) == 21)
        assert(not evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == nil)
    end

    do
        local f, p, s = evo.id(3)
        evo.set(p, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)

        local e = evo.builder()
            :set(f, 21)
            :set(evo.pair(p, s), 42)
            :spawn()

        evo.destroy(s)

        assert(evo.alive(e) and not evo.empty(e))
        assert(evo.has(e, f) and evo.get(e, f) == 21)
        assert(not evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == nil)
    end

    do
        local f, p, s = evo.id(3)
        evo.set(p, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)
        evo.set(s, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

        local e = evo.builder()
            :set(f, 21)
            :set(evo.pair(p, s), 42)
            :spawn()

        evo.destroy(p)

        assert(evo.alive(e) and not evo.empty(e))
        assert(evo.has(e, f) and evo.get(e, f) == 21)
        assert(not evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == nil)
    end

    do
        local f, p, s = evo.id(3)
        evo.set(p, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)
        evo.set(s, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)

        local e = evo.builder()
            :set(f, 21)
            :set(evo.pair(p, s), 42)
            :spawn()

        evo.destroy(s)

        assert(not evo.alive(e) and evo.empty(e))
        assert(not evo.has(e, f) and evo.get(e, f) == nil)
        assert(not evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == nil)
    end
end

do
    do
        local p, s = evo.id(2)
        evo.set(p, evo.DEFAULT, 42)

        do
            local e = evo.id()
            evo.set(e, evo.pair(p, s))
            assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == 42)
        end

        do
            local e = evo.builder():set(evo.pair(p, s)):spawn()
            assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == 42)
        end
    end

    do
        local p, s = evo.id(2)
        evo.set(s, evo.DEFAULT, 21)

        do
            local e = evo.id()
            evo.set(e, evo.pair(p, s))
            assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == true)
        end

        do
            local e = evo.builder():set(evo.pair(p, s)):spawn()
            assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == true)
        end
    end

    do
        local p, s = evo.id(2)
        evo.set(p, evo.DEFAULT, 42)
        evo.set(s, evo.DEFAULT, 21)

        do
            local e = evo.id()
            evo.set(e, evo.pair(p, s))
            assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == 42)
        end

        do
            local e = evo.builder():set(evo.pair(p, s)):spawn()
            assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == 42)
        end
    end
end

do
    do
        local f, p, s = evo.id(3)
        evo.set(p, evo.REQUIRES, { f })

        do
            local e = evo.id()
            evo.set(e, evo.pair(p, s))
            assert(evo.has(e, f) and evo.get(e, f) == true)
            assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == true)
        end

        do
            local e = evo.builder():set(evo.pair(p, s)):spawn()
            assert(evo.has(e, f) and evo.get(e, f) == true)
            assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == true)
        end
    end

    do
        local f, p, s = evo.id(3)
        evo.set(s, evo.REQUIRES, { f })

        do
            local e = evo.id()
            evo.set(e, evo.pair(p, s))
            assert(not evo.has(e, f) and evo.get(e, f) == nil)
            assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == true)
        end

        do
            local e = evo.builder():set(evo.pair(p, s)):spawn()
            assert(not evo.has(e, f) and evo.get(e, f) == nil)
            assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == true)
        end
    end

    do
        local f, p, s = evo.id(3)
        evo.set(p, evo.REQUIRES, { f })
        evo.set(f, evo.REQUIRES, { evo.pair(s, p) })
        evo.set(s, evo.REQUIRES, { p })

        do
            local e = evo.id()
            evo.set(e, evo.pair(p, s))
            assert(evo.has(e, f) and evo.get(e, f) == true)
            assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == true)
            assert(evo.has(e, evo.pair(s, p)) and evo.get(e, evo.pair(s, p)) == true)
            assert(evo.has(e, p) and evo.get(e, p) == true)
        end

        do
            local e = evo.builder():set(evo.pair(p, s)):spawn()
            assert(evo.has(e, f) and evo.get(e, f) == true)
            assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == true)
            assert(evo.has(e, evo.pair(s, p)) and evo.get(e, evo.pair(s, p)) == true)
            assert(evo.has(e, p) and evo.get(e, p) == true)
        end
    end
end

do
    do
        local p, s = evo.id(2)

        local e = evo.builder():set(p, 21):set(evo.pair(p, s), 42):spawn()
        assert(evo.has(e, p) and evo.get(e, p) == 21)
        assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == 42)

        evo.set(s, evo.TAG)
        assert(evo.has(e, p) and evo.get(e, p) == 21)
        assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == 42)

        evo.set(p, evo.TAG)
        assert(evo.has(e, p) and evo.get(e, p) == nil)
        assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == nil)
    end

    do
        local p, s = evo.id(2)

        local e = evo.builder():set(evo.pair(p, s), 42):spawn()
        assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == 42)

        evo.set(s, evo.TAG)
        assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == 42)

        evo.set(p, evo.TAG)
        assert(evo.has(e, evo.pair(p, s)) and evo.get(e, evo.pair(p, s)) == nil)
    end
end

do
    local p1, p2, s1, s2 = evo.id(4)

    do
        local b = evo.builder()

        b:set(evo.pair(p1, s1), 11)
        b:set(evo.pair(p1, s2), 12)
        b:set(evo.pair(p2, s1), 21)
        b:set(evo.pair(p2, s2), 22)

        b:remove(evo.pair(evo.ANY, evo.ANY))

        assert(not b:has(evo.pair(p1, s1)))
        assert(not b:has(evo.pair(p1, s2)))
        assert(not b:has(evo.pair(p2, s1)))
        assert(not b:has(evo.pair(p2, s2)))

        assert(not b:has(evo.pair(p1, evo.ANY)))
        assert(not b:has(evo.pair(p2, evo.ANY)))
        assert(not b:has(evo.pair(evo.ANY, s1)))
        assert(not b:has(evo.pair(evo.ANY, s2)))

        assert(not b:has(evo.pair(evo.ANY, evo.ANY)))
    end

    do
        local b = evo.builder()

        b:set(evo.pair(p1, s1), 11)
        b:set(evo.pair(p1, s2), 12)
        b:set(evo.pair(p2, s1), 21)
        b:set(evo.pair(p2, s2), 22)

        b:remove(evo.pair(p2, evo.ANY))

        assert(b:has(evo.pair(p1, s1)))
        assert(b:has(evo.pair(p1, s2)))
        assert(not b:has(evo.pair(p2, s1)))
        assert(not b:has(evo.pair(p2, s2)))

        assert(b:has(evo.pair(p1, evo.ANY)))
        assert(not b:has(evo.pair(p2, evo.ANY)))
        assert(b:has(evo.pair(evo.ANY, s1)))
        assert(b:has(evo.pair(evo.ANY, s2)))

        assert(b:has(evo.pair(evo.ANY, evo.ANY)))
    end

    do
        local b = evo.builder()

        b:set(evo.pair(p1, s1), 11)
        b:set(evo.pair(p1, s2), 12)
        b:set(evo.pair(p2, s1), 21)
        b:set(evo.pair(p2, s2), 22)

        b:remove(evo.pair(p2, evo.ANY))

        assert(b:has_all(evo.pair(p1, s1)))
        assert(b:has_all(evo.pair(p1, s1), evo.pair(p1, s2)))
        assert(not b:has_all(evo.pair(p1, s1), evo.pair(p2, s1)))
        assert(not b:has_all(evo.pair(p2, s1), evo.pair(p1, s2)))
        assert(not b:has_all(evo.pair(p2, s1), evo.pair(p2, s2)))

        assert(b:has_all(evo.pair(p1, evo.ANY)))
        assert(b:has_all(evo.pair(p1, evo.ANY), evo.pair(evo.ANY, s1)))
        assert(not b:has_all(evo.pair(p2, evo.ANY), evo.pair(evo.ANY, s1)))
        assert(not b:has_all(evo.pair(p2, evo.ANY), evo.pair(evo.ANY, p1)))

        assert(b:has_all(evo.pair(evo.ANY, evo.ANY)))

        assert(b:has_all(
            evo.pair(p1, s1),
            evo.pair(p1, s2),
            evo.pair(evo.ANY, s1),
            evo.pair(p1, evo.ANY),
            evo.pair(evo.ANY, evo.ANY)))

        assert(not b:has_all(
            evo.pair(p1, s1),
            evo.pair(p1, s2),
            evo.pair(evo.ANY, s1),
            evo.pair(p1, evo.ANY),
            evo.pair(evo.ANY, evo.ANY),
            evo.pair(p2, evo.ANY)))
    end

    do
        local b = evo.builder()

        b:set(evo.pair(p1, s1), 11)
        b:set(evo.pair(p1, s2), 12)
        b:set(evo.pair(p2, s1), 21)
        b:set(evo.pair(p2, s2), 22)

        b:remove(evo.pair(p2, evo.ANY))

        assert(b:has_any(evo.pair(p1, s1)))
        assert(b:has_any(evo.pair(p1, s1), evo.pair(p1, s2)))
        assert(b:has_any(evo.pair(p1, s1), evo.pair(p2, s1)))
        assert(b:has_any(evo.pair(p2, s1), evo.pair(p1, s2)))
        assert(not b:has_any(evo.pair(p2, s1), evo.pair(p2, s2)))

        assert(b:has_any(evo.pair(p1, evo.ANY)))
        assert(b:has_any(evo.pair(p1, evo.ANY), evo.pair(evo.ANY, s1)))
        assert(b:has_any(evo.pair(p2, evo.ANY), evo.pair(evo.ANY, s1)))
        assert(not b:has_any(evo.pair(p2, evo.ANY), evo.pair(evo.ANY, p1)))

        assert(b:has_any(evo.pair(evo.ANY, evo.ANY)))

        assert(b:has_any(
            evo.pair(p1, s1),
            evo.pair(p1, s2),
            evo.pair(evo.ANY, s1),
            evo.pair(p1, evo.ANY),
            evo.pair(evo.ANY, evo.ANY)))

        assert(not b:has_any(
            evo.pair(p2, s1),
            evo.pair(p2, s2),
            evo.pair(p2, evo.ANY),
            evo.pair(evo.ANY, p1),
            evo.pair(evo.ANY, p2)))

        assert(b:has_any(
            evo.pair(p2, s1),
            evo.pair(p2, s2),
            evo.pair(p2, evo.ANY),
            evo.pair(evo.ANY, p1),
            evo.pair(evo.ANY, p2),
            evo.pair(p1, evo.ANY)))
    end

    do
        local b = evo.builder()

        b:set(evo.pair(p1, s1), 11)
        b:set(evo.pair(p1, s2), 12)
        b:set(evo.pair(p2, s1), 21)
        b:set(evo.pair(p2, s2), 22)

        b:remove(evo.pair(p1, evo.ANY))
        b:remove(evo.pair(p1, evo.ANY))

        b:remove(evo.pair(p2, evo.ANY))
        b:remove(evo.pair(p2, evo.ANY))

        b:remove(evo.pair(evo.ANY, s1))
        b:remove(evo.pair(evo.ANY, s1))

        b:remove(evo.pair(evo.ANY, s2))
        b:remove(evo.pair(evo.ANY, s2))

        assert(not b:has(evo.pair(evo.ANY, evo.ANY)))
    end
end

do
    local p, s = evo.id(2)
    evo.set(p, evo.NAME, 'p')
    evo.set(s, evo.NAME, 's')
    assert(evo.name(evo.pair(p, s)) == '${p,s}')
    assert(evo.name(evo.pair(evo.ANY, s)) == '${ANY,s}')
    assert(evo.name(evo.pair(p, evo.ANY)) == '${p,ANY}')
    assert(evo.name(evo.pair(evo.ANY, evo.ANY)) == '${ANY,ANY}')
end

do
    do
        local p, s = evo.id(2)
        assert(evo.alive(evo.pair(p, s)))
    end

    do
        local p, s = evo.id(2)
        evo.destroy(p)
        assert(not evo.alive(evo.pair(p, s)))
    end

    do
        local p, s = evo.id(2)
        evo.destroy(s)
        assert(not evo.alive(evo.pair(p, s)))
    end

    do
        local p, s = evo.id(2)
        evo.destroy(p, s)
        assert(not evo.alive(evo.pair(p, s)))
    end
end

do
    do
        local p1, p2, p3, s = evo.id(4)
        local prefab = evo.builder()
            :set(evo.pair(p1, s), 42)
            :set(evo.pair(p2, s), 21)
            :set(evo.pair(p3, s), 84)
            :spawn()
        local clone = evo.clone(prefab)
        assert(evo.has(clone, evo.pair(p1, s)) and evo.get(clone, evo.pair(p1, s)) == 42)
        assert(evo.has(clone, evo.pair(p2, s)) and evo.get(clone, evo.pair(p2, s)) == 21)
        assert(evo.has(clone, evo.pair(p3, s)) and evo.get(clone, evo.pair(p3, s)) == 84)
    end

    do
        local p1, p2, p3, s = evo.id(4)
        evo.set(p1, evo.UNIQUE)
        evo.set(p2, evo.UNIQUE)
        local prefab = evo.builder()
            :set(evo.pair(p1, s), 42)
            :set(evo.pair(p2, s), 21)
            :set(evo.pair(p3, s), 84)
            :spawn()
        local clone = evo.clone(prefab)
        assert(not evo.has(clone, evo.pair(p1, s)) and evo.get(clone, evo.pair(p1, s)) == nil)
        assert(not evo.has(clone, evo.pair(p2, s)) and evo.get(clone, evo.pair(p2, s)) == nil)
        assert(evo.has(clone, evo.pair(p3, s)) and evo.get(clone, evo.pair(p3, s)) == 84)
    end
end

do
    ---@generic T1, T2
    ---@param first T1
    ---@param second T2
    ---@return T1
    ---@diagnostic disable-next-line: unused-local
    local function fst(first, second)
        return first
    end

    ---@generic T1, T2
    ---@param first T1
    ---@param second T2
    ---@return T2
    ---@diagnostic disable-next-line: unused-local
    local function snd(first, second)
        return second
    end

    do
        local p, s1, s2, f = evo.id(4)

        local e = evo.builder()
            :set(evo.pair(p, s1), 21)
            :set(evo.pair(p, s2), 42)
            :spawn()

        assert(fst(evo.primary(e, s1)) == p)
        assert(snd(evo.primary(e, s1)) == 21)
        assert(fst(evo.primary(e, s2)) == p)
        assert(snd(evo.primary(e, s2)) == 42)
        assert(fst(evo.primary(e, s1, 1)) == p)
        assert(snd(evo.primary(e, s1, 1)) == 21)
        assert(fst(evo.primary(e, s2, 1)) == p)
        assert(snd(evo.primary(e, s2, 1)) == 42)
        assert(fst(evo.primary(e, s1, 2)) == nil)
        assert(snd(evo.primary(e, s1, 2)) == nil)
        assert(fst(evo.primary(e, s2, 2)) == nil)
        assert(snd(evo.primary(e, s2, 2)) == nil)

        assert(fst(evo.primary(evo.pair(e, f), s1)) == nil)
        assert(fst(evo.primary(evo.pair(e, f), s2)) == nil)
        assert(fst(evo.primary(evo.pair(e, f), s1, 1)) == nil)
        assert(fst(evo.primary(evo.pair(e, f), s2, 1)) == nil)
        assert(fst(evo.primary(evo.pair(e, f), s1, 2)) == nil)
        assert(fst(evo.primary(evo.pair(e, f), s2, 2)) == nil)

        assert(fst(evo.secondary(e, p)) == s1)
        assert(fst(evo.secondary(e, p, 1)) == s1)
        assert(fst(evo.secondary(e, p, 2)) == s2)
        assert(fst(evo.secondary(e, p, 3)) == nil)

        assert(fst(evo.secondary(evo.pair(e, f), p)) == nil)
        assert(fst(evo.secondary(evo.pair(e, f), p, 1)) == nil)
        assert(fst(evo.secondary(evo.pair(e, f), p, 2)) == nil)
        assert(fst(evo.secondary(evo.pair(e, f), p, 3)) == nil)

        assert(fst(evo.primary(evo.pair(f, e), s1)) == nil)
        assert(fst(evo.primary(evo.pair(f, e), s2)) == nil)
        assert(fst(evo.secondary(evo.pair(f, e), p)) == nil)
    end

    do
        local p, s1, s2, f = evo.id(4)

        local e = evo.builder()
            :set(evo.pair(p, s1), 21)
            :set(evo.pair(p, s2), 42)
            :spawn()

        assert(evo.primary_count(e, p) == 0)
        assert(evo.primary_count(e, s1) == 1)
        assert(evo.primary_count(e, s2) == 1)
        assert(evo.secondary_count(e, p) == 2)
        assert(evo.secondary_count(e, s1) == 0)
        assert(evo.secondary_count(e, s2) == 0)

        assert(evo.primary_count(evo.pair(e, f), p) == 0)
        assert(evo.primary_count(evo.pair(e, f), s1) == 0)
        assert(evo.primary_count(evo.pair(e, f), s2) == 0)
        assert(evo.secondary_count(evo.pair(e, f), p) == 0)
        assert(evo.secondary_count(evo.pair(e, f), s1) == 0)
        assert(evo.secondary_count(evo.pair(e, f), s2) == 0)

        assert(evo.primary_count(evo.pair(f, e), p) == 0)
        assert(evo.primary_count(evo.pair(f, e), s1) == 0)
        assert(evo.primary_count(evo.pair(f, e), s2) == 0)
        assert(evo.secondary_count(evo.pair(f, e), p) == 0)
        assert(evo.secondary_count(evo.pair(f, e), s1) == 0)
        assert(evo.secondary_count(evo.pair(f, e), s2) == 0)
    end

    do
        local p, s1, s2, f = evo.id(4)

        local e = evo.builder()
            :set(evo.pair(p, s1), 21)
            :set(evo.pair(p, s2), 42)
            :spawn()

        do
            local iter, state = evo.primaries(e, p)
            local fragment, component = iter(state)
            assert(fragment == nil and component == nil)


            iter, state = evo.primaries(evo.pair(e, f), p)
            fragment, component = iter(state)
            assert(fragment == nil and component == nil)
        end

        do
            local iter, state = evo.primaries(e, s1)
            local fragment, component = iter(state)
            assert(fragment == p and component == 21)
            fragment, component = iter(state)
            assert(fragment == nil and component == nil)

            iter, state = evo.primaries(evo.pair(e, f), s1)
            fragment, component = iter(state)
            assert(fragment == nil and component == nil)
        end

        do
            local iter, state = evo.primaries(e, s2)
            local fragment, component = iter(state)
            assert(fragment == p and component == 42)
            fragment, component = iter(state)
            assert(fragment == nil and component == nil)

            iter, state = evo.primaries(evo.pair(e, f), s2)
            fragment, component = iter(state)
            assert(fragment == nil and component == nil)
        end
    end

    do
        local p, s1, s2, f = evo.id(4)

        local e = evo.builder()
            :set(evo.pair(p, s1), 21)
            :set(evo.pair(p, s2), 42)
            :spawn()

        do
            local iter, state = evo.secondaries(e, s1)
            local fragment, component = iter(state)
            assert(fragment == nil and component == nil)

            iter, state = evo.secondaries(evo.pair(e, f), s1)
            fragment, component = iter(state)
            assert(fragment == nil and component == nil)
        end

        do
            local iter, state = evo.secondaries(e, p)
            local fragment, component = iter(state)
            assert(fragment == s1 and component == 21)
            fragment, component = iter(state)
            assert(fragment == s2 and component == 42)
            fragment, component = iter(state)
            assert(fragment == nil and component == nil)

            iter, state = evo.secondaries(evo.pair(e, f), p)
            fragment, component = iter(state)
            assert(fragment == nil and component == nil)
        end
    end

    do
        local p, s1, s2 = evo.id(3)

        local e = evo.builder()
            :set(evo.pair(p, s1), 21)
            :set(evo.pair(p, s2), 42)
            :spawn()

        do
            local iter, state = evo.each(e)
            local fragment, component = iter(state)
            assert(fragment == evo.pair(p, s1) and component == 21)
            fragment, component = iter(state)
            assert(fragment == evo.pair(p, s2) and component == 42)
            fragment, component = iter(state)
            assert(fragment == nil and component == nil)
        end
    end
end

do
    do
        local p, s1, s2 = evo.id(3)

        local e = evo.spawn {
            [evo.pair(p, s1)] = 21,
            [evo.pair(p, s2)] = 42,
        }

        assert(evo.has(e, evo.pair(p, s1)) and evo.get(e, evo.pair(p, s1)) == 21)
        assert(evo.has(e, evo.pair(p, s2)) and evo.get(e, evo.pair(p, s2)) == 42)

        evo.destroy(p)

        assert(not evo.has(e, evo.pair(p, s1)) and evo.get(e, evo.pair(p, s1)) == nil)
        assert(not evo.has(e, evo.pair(p, s2)) and evo.get(e, evo.pair(p, s2)) == nil)
    end

    do
        local p, s1, s2 = evo.id(3)

        local e = evo.spawn {
            [evo.pair(p, s1)] = 21,
            [evo.pair(p, s2)] = 42,
        }

        assert(evo.has(e, evo.pair(p, s1)) and evo.get(e, evo.pair(p, s1)) == 21)
        assert(evo.has(e, evo.pair(p, s2)) and evo.get(e, evo.pair(p, s2)) == 42)

        evo.destroy(s1)

        assert(not evo.has(e, evo.pair(p, s1)) and evo.get(e, evo.pair(p, s1)) == nil)
        assert(evo.has(e, evo.pair(p, s2)) and evo.get(e, evo.pair(p, s2)) == 42)

        evo.destroy(s2)

        assert(not evo.has(e, evo.pair(p, s1)) and evo.get(e, evo.pair(p, s1)) == nil)
        assert(not evo.has(e, evo.pair(p, s2)) and evo.get(e, evo.pair(p, s2)) == nil)
    end
end

-- TODO
-- process evo.ANY as single wildcard
-- should we provide an evolved.pair type?
-- we should not add any wildcards to chunk `with` edges, lol
-- edges `without` to nil don't work because they are cannot be found
