local evo = require 'evolved'

do
    local f1, f2 = evo.id(2)
    evo.set(f1, evo.REQUIRES)
    evo.set(f2, evo.REQUIRES, evo.get(f1, evo.REQUIRES))
    local f1_rs = evo.get(f1, evo.REQUIRES)
    local f2_rs = evo.get(f2, evo.REQUIRES)
    assert(f1_rs and f2_rs and #f1_rs == 0 and #f2_rs == 0 and f1_rs ~= f2_rs)
end

do
    local f1, f2 = evo.id(2)
    local f3 = evo.builder():require(f1):require(f2):spawn()
    local f3_rs = evo.get(f3, evo.REQUIRES)
    assert(f3_rs and #f3_rs == 2 and f3_rs[1] == f1 and f3_rs[2] == f2)
end

do
    local f1, f2 = evo.id(2)
    local f3 = evo.builder():require(f1, f2):spawn()
    local f3_rs = evo.get(f3, evo.REQUIRES)
    assert(f3_rs and #f3_rs == 2 and f3_rs[1] == f1 and f3_rs[2] == f2)
end

do
    local f1, f2, f3 = evo.id(3)
    evo.set(f1, evo.REQUIRES, { f2 })
    evo.set(f3, evo.REQUIRES, { f1, f2 })

    do
        local e = evo.id()
        evo.set(e, f1)
        assert(evo.has(e, f2))
        assert(evo.get(e, f2) == true)
    end

    do
        local e = evo.builder():set(f1):spawn()
        assert(evo.has(e, f2))
        assert(evo.get(e, f2) == true)
    end

    do
        local e = evo.spawn { [f1] = true }
        assert(evo.has(e, f2))
        assert(evo.get(e, f2) == true)

        evo.remove(e, f2)
        assert(not evo.has(e, f2))

        local e2 = evo.clone(e)
        assert(evo.has(e2, f2))
        assert(evo.get(e2, f2) == true)

        local e3 = evo.clone(e, { [f3] = true })
        assert(evo.has(e3, f2))
        assert(evo.get(e3, f2) == true)
    end

    do
        local f0 = evo.id()
        local q0 = evo.builder():include(f0):spawn()

        local e1 = evo.builder():set(f0):spawn()
        local e2 = evo.builder():set(f0):spawn()
        local e3 = evo.builder():set(f0):set(f2, false):spawn()

        evo.batch_set(q0, f1)

        assert(evo.has(e1, f2) and evo.get(e1, f2) == true)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == true)
        assert(evo.has(e3, f2) and evo.get(e3, f2) == false)
    end
end

do
    local f1, f2, f3 = evo.id(3)
    evo.set(f1, evo.REQUIRES, { f2 })
    evo.set(f2, evo.DEFAULT, 42)
    evo.set(f3, evo.REQUIRES, { f1, f2 })

    do
        local e = evo.id()
        evo.set(e, f1)
        assert(evo.has(e, f2))
        assert(evo.get(e, f2) == 42)
    end

    do
        local e = evo.builder():set(f1):spawn()
        assert(evo.has(e, f2))
        assert(evo.get(e, f2) == 42)
    end

    do
        local e = evo.spawn { [f1] = true, }
        assert(evo.has(e, f2))
        assert(evo.get(e, f2) == 42)

        evo.remove(e, f2)
        assert(not evo.has(e, f2))

        local e2 = evo.clone(e)
        assert(evo.has(e2, f2))
        assert(evo.get(e2, f2) == 42)

        local e3 = evo.clone(e, { [f3] = true })
        assert(evo.has(e3, f2))
        assert(evo.get(e3, f2) == 42)
    end

    do
        local f0 = evo.id()
        local q0 = evo.builder():include(f0):spawn()

        local e1 = evo.builder():set(f0):spawn()
        local e2 = evo.builder():set(f0):spawn()
        local e3 = evo.builder():set(f0):set(f2, 21):spawn()

        evo.batch_set(q0, f1)

        assert(evo.has(e1, f2) and evo.get(e1, f2) == 42)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == 42)
        assert(evo.has(e3, f2) and evo.get(e3, f2) == 21)
    end
end

do
    local f1, f2, f3 = evo.id(3)
    evo.set(f1, evo.REQUIRES, { f2 })
    evo.set(f2, evo.REQUIRES, { f3 })
    evo.set(f3, evo.DEFAULT, 42)
    evo.set(f3, evo.REQUIRES, { f1, f2 })

    do
        local e = evo.id()
        evo.set(e, f1)
        assert(evo.has(e, f2))
        assert(evo.get(e, f2) == true)
        assert(evo.has(e, f3))
        assert(evo.get(e, f3) == 42)
    end

    do
        local e = evo.builder():set(f1):spawn()
        assert(evo.has(e, f2))
        assert(evo.get(e, f2) == true)
        assert(evo.has(e, f3))
        assert(evo.get(e, f3) == 42)
    end

    do
        local e = evo.spawn { [f1] = true }
        assert(evo.has(e, f2))
        assert(evo.get(e, f2) == true)
        assert(evo.has(e, f3))
        assert(evo.get(e, f3) == 42)

        evo.remove(e, f2, f3)
        assert(not evo.has(e, f2))
        assert(not evo.has(e, f3))

        local e2 = evo.clone(e, { [f1] = 21 })
        assert(evo.has(e2, f1) and evo.get(e2, f1) == 21)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == true)
        assert(evo.has(e2, f3) and evo.get(e2, f3) == 42)

        local e3 = evo.clone(e, { [f3] = 21 })
        assert(evo.has(e3, f1) and evo.get(e3, f1) == true)
        assert(evo.has(e3, f2) and evo.get(e3, f2) == true)
        assert(evo.has(e3, f3) and evo.get(e3, f3) == 21)
    end
end

do
    local f1, f2, f3 = evo.id(3)
    evo.set(f1, evo.REQUIRES, { f2 })
    evo.set(f2, evo.REQUIRES, { f3 })
    evo.set(f3, evo.REQUIRES, { f1, f2, f3 })

    do
        local e = evo.id()
        evo.set(e, f1, 42)
        assert(evo.has(e, f1) and evo.get(e, f1) == 42)
        assert(evo.has(e, f2) and evo.get(e, f2) == true)
        assert(evo.has(e, f3) and evo.get(e, f3) == true)
    end

    do
        local e = evo.builder():set(f1, 42):spawn()
        assert(evo.has(e, f1) and evo.get(e, f1) == 42)
        assert(evo.has(e, f2) and evo.get(e, f2) == true)
        assert(evo.has(e, f3) and evo.get(e, f3) == true)
    end

    do
        local e = evo.spawn { [f1] = 42 }
        assert(evo.has(e, f1) and evo.get(e, f1) == 42)
        assert(evo.has(e, f2) and evo.get(e, f2) == true)
        assert(evo.has(e, f3) and evo.get(e, f3) == true)

        evo.remove(e, f2, f3)
        assert(not evo.has(e, f2))
        assert(not evo.has(e, f3))

        local e2 = evo.clone(e, { [f1] = 21 })
        assert(evo.has(e2, f1) and evo.get(e2, f1) == 21)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == true)
        assert(evo.has(e2, f3) and evo.get(e2, f3) == true)

        local e3 = evo.clone(e, { [f3] = 21 })
        assert(evo.has(e3, f1) and evo.get(e3, f1) == 42)
        assert(evo.has(e3, f2) and evo.get(e3, f2) == true)
        assert(evo.has(e3, f3) and evo.get(e3, f3) == 21)
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)

    do
        evo.set(f1, evo.REQUIRES, { f2 })
        do
            local e = evo.id()
            evo.set(e, f1)
            assert(evo.has(e, f2) and evo.get(e, f2) == true)
        end
        evo.set(f1, evo.REQUIRES, { f2, f3 })
        do
            local e = evo.id()
            evo.set(e, f1)
            assert(evo.has(e, f2) and evo.get(e, f2) == true)
            assert(evo.has(e, f3) and evo.get(e, f3) == true)
        end
        evo.set(f3, evo.REQUIRES, { f4 })
        do
            local e = evo.id()
            evo.set(e, f1)
            assert(evo.has(e, f2) and evo.get(e, f2) == true)
            assert(evo.has(e, f3) and evo.get(e, f3) == true)
            assert(evo.has(e, f4) and evo.get(e, f4) == true)
        end
    end
end

do
    local f1, f2, f3, f4 = evo.id(4)
    evo.set(f1, evo.REQUIRES, { f2 })
    evo.set(f2, evo.REQUIRES, { f3 })
    evo.set(f3, evo.REQUIRES, { f4 })

    do
        local e1 = evo.builder():set(f1):spawn()
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == true)
        assert(evo.has(e1, f3) and evo.get(e1, f3) == true)
        assert(evo.has(e1, f4) and evo.get(e1, f4) == true)

        local e2 = evo.builder():set(f2):spawn()
        assert(not evo.has(e2, f1) and evo.get(e2, f1) == nil)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == true)
        assert(evo.has(e2, f3) and evo.get(e2, f3) == true)
        assert(evo.has(e2, f4) and evo.get(e2, f4) == true)

        local e3 = evo.builder():set(f3):spawn()
        assert(not evo.has(e3, f1) and evo.get(e3, f1) == nil)
        assert(not evo.has(e3, f2) and evo.get(e3, f2) == nil)
        assert(evo.has(e3, f3) and evo.get(e3, f3) == true)
        assert(evo.has(e3, f4) and evo.get(e3, f4) == true)
    end

    do
        local e1 = evo.id()
        evo.set(e1, f1)
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == true)
        assert(evo.has(e1, f3) and evo.get(e1, f3) == true)
        assert(evo.has(e1, f4) and evo.get(e1, f4) == true)

        local e2 = evo.id()
        evo.set(e2, f2)
        assert(not evo.has(e2, f1) and evo.get(e2, f1) == nil)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == true)
        assert(evo.has(e2, f3) and evo.get(e2, f3) == true)
        assert(evo.has(e2, f4) and evo.get(e2, f4) == true)

        local e3 = evo.id()
        evo.set(e3, f3)
        assert(not evo.has(e3, f1) and evo.get(e3, f1) == nil)
        assert(not evo.has(e3, f2) and evo.get(e3, f2) == nil)
        assert(evo.has(e3, f3) and evo.get(e3, f3) == true)
        assert(evo.has(e3, f4) and evo.get(e3, f4) == true)
    end

    evo.remove(f2, evo.REQUIRES)

    do
        local e1 = evo.builder():set(f1):spawn()
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == true)
        assert(not evo.has(e1, f3) and evo.get(e1, f3) == nil)
        assert(not evo.has(e1, f4) and evo.get(e1, f4) == nil)

        local e2 = evo.builder():set(f2):spawn()
        assert(not evo.has(e2, f1) and evo.get(e2, f1) == nil)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == true)
        assert(not evo.has(e2, f3) and evo.get(e2, f3) == nil)
        assert(not evo.has(e2, f4) and evo.get(e2, f4) == nil)

        local e3 = evo.builder():set(f3):spawn()
        assert(not evo.has(e3, f1) and evo.get(e3, f1) == nil)
        assert(not evo.has(e3, f2) and evo.get(e3, f2) == nil)
        assert(evo.has(e3, f3) and evo.get(e3, f3) == true)
        assert(evo.has(e3, f4) and evo.get(e3, f4) == true)
    end

    do
        local e1 = evo.id()
        evo.set(e1, f1)
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == true)
        assert(not evo.has(e1, f3) and evo.get(e1, f3) == nil)
        assert(not evo.has(e1, f4) and evo.get(e1, f4) == nil)

        local e2 = evo.id()
        evo.set(e2, f2)
        assert(not evo.has(e2, f1) and evo.get(e2, f1) == nil)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == true)
        assert(not evo.has(e2, f3) and evo.get(e2, f3) == nil)
        assert(not evo.has(e2, f4) and evo.get(e2, f4) == nil)

        local e3 = evo.id()
        evo.set(e3, f3)
        assert(not evo.has(e3, f1) and evo.get(e3, f1) == nil)
        assert(not evo.has(e3, f2) and evo.get(e3, f2) == nil)
        assert(evo.has(e3, f3) and evo.get(e3, f3) == true)
        assert(evo.has(e3, f4) and evo.get(e3, f4) == true)
    end

    evo.set(f2, evo.REQUIRES, { f4 })

    do
        local e1 = evo.builder():set(f1):spawn()
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == true)
        assert(not evo.has(e1, f3) and evo.get(e1, f3) == nil)
        assert(evo.has(e1, f4) and evo.get(e1, f4) == true)

        local e2 = evo.builder():set(f2):spawn()
        assert(not evo.has(e2, f1) and evo.get(e2, f1) == nil)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == true)
        assert(not evo.has(e2, f3) and evo.get(e2, f3) == nil)
        assert(evo.has(e2, f4) and evo.get(e2, f4) == true)

        local e3 = evo.builder():set(f3):spawn()
        assert(not evo.has(e3, f1) and evo.get(e3, f1) == nil)
        assert(not evo.has(e3, f2) and evo.get(e3, f2) == nil)
        assert(evo.has(e3, f3) and evo.get(e3, f3) == true)
        assert(evo.has(e3, f4) and evo.get(e3, f4) == true)
    end

    do
        local e1 = evo.id()
        evo.set(e1, f1)
        assert(evo.has(e1, f1) and evo.get(e1, f1) == true)
        assert(evo.has(e1, f2) and evo.get(e1, f2) == true)
        assert(not evo.has(e1, f3) and evo.get(e1, f3) == nil)
        assert(evo.has(e1, f4) and evo.get(e1, f4) == true)

        local e2 = evo.id()
        evo.set(e2, f2)
        assert(not evo.has(e2, f1) and evo.get(e2, f1) == nil)
        assert(evo.has(e2, f2) and evo.get(e2, f2) == true)
        assert(not evo.has(e2, f3) and evo.get(e2, f3) == nil)
        assert(evo.has(e2, f4) and evo.get(e2, f4) == true)

        local e3 = evo.id()
        evo.set(e3, f3)
        assert(not evo.has(e3, f1) and evo.get(e3, f1) == nil)
        assert(not evo.has(e3, f2) and evo.get(e3, f2) == nil)
        assert(evo.has(e3, f3) and evo.get(e3, f3) == true)
        assert(evo.has(e3, f4) and evo.get(e3, f4) == true)
    end
end
