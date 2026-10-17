local evo = require 'evolved'

evo.debug_mode(true)

do
    local o = ''

    local f = evo.builder()
        :build()

    local m = evo.builder()
        :include(f)
        :observe(evo.ENTER, evo.LEAVE)
        :callback(function(ev)
            if ev == evo.ENTER then
                o = o .. 'e'
            elseif ev == evo.LEAVE then
                o = o .. 'l'
            end
        end)
        :build()

    do
        o = ''
        local e = evo.id()
        evo.set(e, f)
        assert(o == 'e')
        evo.remove(e, f)
        assert(o == 'el')
        evo.destroy(e)
        assert(o == 'el')
    end

    do
        o = ''
        local e = evo.spawn({ [f] = true })
        assert(o == 'e')
        evo.destroy(e)
        assert(o == 'el')
    end

    evo.destroy(m)

    do
        o = ''
        local e = evo.spawn({ [f] = true })
        evo.destroy(e)
        assert(o == '')
    end
end

do
    local o = ''

    local f = evo.builder()
        :build()

    local m = evo.builder()
        :include(f)
        :observe(evo.ENTER, evo.LEAVE)
        :callback(function(ev)
            if ev == evo.ENTER then
                o = o .. 'e'
            elseif ev == evo.LEAVE then
                o = o .. 'l'
            end
        end)
        :build()

    do
        o = ''
        local e = evo.id()
        evo.set(e, f)
        assert(o == 'e')
        evo.destroy(f)
        assert(o == 'el')
        evo.destroy(e)
        assert(o == 'el')
    end

    evo.destroy(m)
end

do
    local o = ''

    local f = evo.builder()
        :build()

    local m = evo.builder()
        :include(f)
        :observe(evo.ENTER, evo.LEAVE)
        :callback(function(ev)
            if ev == evo.ENTER then
                o = o .. 'e'
            elseif ev == evo.LEAVE then
                o = o .. 'l'
            end
        end)
        :build()

    do
        o = ''
        local e = evo.id()
        evo.set(e, f)
        assert(o == 'e')
        evo.destroy(m, e)
        assert(o == 'e')
        evo.destroy(f)
        assert(o == 'e')
    end
end

do
    local o = ''

    local f = evo.builder()
        :on_insert(function()
            o = o .. 'i'
        end)
        :on_remove(function()
            o = o .. 'r'
        end)
        :build()

    local m = evo.builder()
        :include(f)
        :observe(evo.ENTER, evo.LEAVE)
        :callback(function(ev)
            if ev == evo.ENTER then
                o = o .. 'e'
            elseif ev == evo.LEAVE then
                o = o .. 'l'
            end
        end)
        :build()

    do
        o = ''
        local e = evo.id()
        evo.set(e, f)
        assert(o == 'ie')
        evo.remove(e, f)
        assert(o == 'ielr')
        evo.destroy(e)
        assert(o == 'ielr')
    end

    do
        o = ''
        local e = evo.spawn({ [f] = true })
        assert(o == 'ie')
        evo.destroy(e)
        assert(o == 'ielr')
    end

    evo.destroy(m)

    do
        o = ''
        local e = evo.spawn({ [f] = true })
        assert(o == 'i')
        evo.destroy(e, f)
        assert(o == 'ir')
    end
end

do
    local o = ''

    local f = evo.builder()
        :on_insert(function(e, f)
            o = o .. 'i'
            evo.remove(e, f)
        end)
        :on_remove(function()
            o = o .. 'r'
        end)
        :build()

    local m = evo.builder()
        :include(f)
        :observe(evo.ENTER, evo.LEAVE)
        :callback(function(ev)
            if ev == evo.ENTER then
                o = o .. 'e'
            elseif ev == evo.LEAVE then
                o = o .. 'l'
            end
        end)
        :build()

    do
        o = ''
        local e = evo.id()
        evo.set(e, f)
        assert(o == 'ielr')
        evo.destroy(e)
        assert(o == 'ielr')
    end

    do
        o = ''
        local e = evo.spawn({ [f] = true })
        assert(o == 'ielr')
        evo.destroy(e, f)
        assert(o == 'ielr')
    end

    evo.destroy(m)
end

do
    local o = ''

    local r = evo.builder()
        :on_insert(function()
            o = o .. 'I'
        end)
        :on_remove(function()
            o = o .. 'R'
        end)
        :build()

    local f = evo.builder()
        :require(r)
        :on_insert(function()
            o = o .. 'i'
        end)
        :on_remove(function()
            o = o .. 'r'
        end)
        :build()

    local m = evo.builder()
        :include(r)
        :observe(evo.ENTER, evo.LEAVE)
        :callback(function(ev)
            if ev == evo.ENTER then
                o = o .. 'e'
            elseif ev == evo.LEAVE then
                o = o .. 'l'
            end
        end)
        :build()

    do
        o = ''
        local e = evo.id()
        evo.set(e, f)
        assert(o == 'Iie')
        evo.remove(e, f)
        assert(o == 'Iier')
        evo.destroy(e)
        assert(o == 'IierlR')
    end

    do
        o = ''
        local e = evo.id()
        evo.set(e, f)
        assert(o == 'Iie')
        evo.remove(e, r)
        assert(o == 'IielR')
        evo.destroy(e)
        assert(o == 'IielRr')
    end

    do
        o = ''
        local e = evo.id()
        evo.set(e, f)
        assert(o == 'Iie')
        evo.destroy(e)
        assert(o == 'IielRr')
    end

    do
        o = ''
        local e = evo.spawn({ [f] = true })
        assert(o == 'Iie')
        evo.destroy(f)
        assert(o == 'Iier')
        evo.destroy(r)
        assert(o == 'IierlR')
        evo.destroy(e)
        assert(o == 'IierlR')
    end

    evo.destroy(m)
end

do
    local o = ''

    local f1, f2 = evo.id(2)
    local hit, heal = evo.id(2)

    local m = evo.builder()
        :include(f1)
        :observe(hit)
        :callback(function(ev, e, a, b)
            assert(ev == hit)
            assert(evo.has(e, f1))
            o = o .. 'h' .. tostring(a) .. tostring(b)
        end)
        :build()

    do
        o = ''
        local e = evo.spawn({ [f1] = true })
        assert(o == '')
        evo.emit(hit, e, 1, 2)
        assert(o == 'h12')
        evo.emit(heal, e, 3, 4)
        assert(o == 'h12')
        evo.emit(hit, e)
        assert(o == 'h12hnilnil')
        evo.emit(hit, e, nil, 5)
        assert(o == 'h12hnilnilhnil5')
        evo.destroy(e)
        assert(o == 'h12hnilnilhnil5')
    end

    do
        o = ''
        local e = evo.spawn({ [f2] = true })
        evo.emit(hit, e, 1, 2)
        assert(o == '')
        evo.set(e, f1)
        evo.emit(hit, e, 1, 2)
        assert(o == 'h12')
        evo.remove(e, f1)
        evo.emit(hit, e, 1, 2)
        assert(o == 'h12')
    end

    do
        o = ''
        local e = evo.id()
        evo.emit(hit, e, 1, 2)
        assert(o == '')
        evo.destroy(e)
        evo.emit(hit, e, 1, 2)
        assert(o == '')
    end

    evo.destroy(m)

    do
        o = ''
        local e = evo.spawn({ [f1] = true })
        evo.emit(hit, e, 1, 2)
        assert(o == '')
    end
end

do
    local o = ''

    local f = evo.id()
    local hit, heal = evo.id(2)

    local m1 = evo.builder()
        :include(f)
        :observe(hit)
        :callback(function(ev)
            o = o .. (ev == hit and 'h' or '?')
        end)
        :build()

    local m2 = evo.builder()
        :include(f)
        :observe(heal, evo.ENTER)
        :callback(function(ev)
            o = o .. (ev == heal and 'H' or ev == evo.ENTER and 'E' or '?')
        end)
        :build()

    do
        o = ''
        local e = evo.spawn({ [f] = true })
        assert(o == 'E')
        evo.emit(hit, e)
        assert(o == 'Eh')
        evo.emit(heal, e)
        assert(o == 'EhH')
        evo.destroy(e)
        assert(o == 'EhH')
    end

    evo.destroy(m1, m2)
end

do
    local o = ''

    local f = evo.id()
    local hit = evo.id()

    local m = evo.builder()
        :include(f)
        :observe(hit)
        :callback(function()
            o = o .. 'h'
        end)
        :build()

    local e = evo.spawn({ [f] = true })

    do
        o = ''
        evo.set(m, evo.DISABLED)
        evo.emit(hit, e)
        assert(o == '')
        evo.remove(m, evo.DISABLED)
        evo.emit(hit, e)
        assert(o == 'h')
    end

    do
        o = ''
        evo.remove(m, evo.CALLBACK)
        evo.emit(hit, e)
        assert(o == '')
        evo.set(m, evo.CALLBACK, function() o = o .. 'H' end)
        evo.emit(hit, e)
        assert(o == 'H')
    end

    do
        o = ''
        evo.remove(m, evo.OBSERVES)
        evo.emit(hit, e)
        assert(o == '')
        evo.set(m, evo.OBSERVES, { hit })
        evo.emit(hit, e)
        assert(o == 'H')
        evo.set(m, evo.OBSERVES, {})
        evo.emit(hit, e)
        assert(o == 'H')
        evo.set(m, evo.OBSERVES, { evo.ENTER, hit })
        evo.emit(hit, e)
        assert(o == 'HH')
    end

    evo.destroy(m)
end

do
    local o = ''

    local f1, f2 = evo.id(2)
    local hit = evo.id()

    local m = evo.builder()
        :include(f2)
        :observe(hit, evo.LEAVE)
        :callback(function(ev, e, a)
            if ev == hit then
                o = o .. 'h' .. a
                evo.remove(e, f2)
                assert(evo.has(e, f2))
            elseif ev == evo.LEAVE then
                o = o .. 'l'
            end
        end)
        :build()

    do
        o = ''
        local e = evo.spawn({ [f1] = true })

        evo.defer()
        evo.set(e, f2)
        evo.emit(hit, e, 1)
        assert(o == '')
        evo.commit()

        assert(o == 'h1l')
        assert(not evo.has(e, f2))
    end

    do
        o = ''
        local e = evo.spawn({ [f1] = true, [f2] = true })

        evo.defer()
        evo.emit(hit, e, 1)
        evo.destroy(e)
        evo.emit(hit, e, 2)
        assert(o == '')
        evo.commit()

        assert(o == 'h1l')
        assert(not evo.alive(e))
    end

    evo.destroy(m)
end

do
    local o = ''

    local f, g = evo.id(2)
    local hit = evo.id()

    local q = evo.builder()
        :include(f)
        :build()

    local m = evo.builder()
        :include(g)
        :query(q)
        :observe(hit)
        :callback(function(_, _, a)
            o = o .. a
        end)
        :build()

    do
        o = ''
        local e = evo.spawn({ [f] = true })
        evo.emit(hit, e, 'a')
        assert(o == 'a')
        evo.remove(m, evo.QUERY)
        evo.emit(hit, e, 'b')
        assert(o == 'a')
        evo.set(m, evo.QUERY, q)
        evo.emit(hit, e, 'c')
        assert(o == 'ac')
    end

    evo.destroy(m, q)
end

do
    local o = ''

    local f1, f2 = evo.id(2)

    local m1 = evo.builder()
        :include(f1)
        :observe(evo.ENTER, evo.LEAVE)
        :callback(function(ev)
            o = o .. (ev == evo.ENTER and 'e' or 'l')
        end)
        :build()

    local m2 = evo.builder()
        :include(f1, f2)
        :observe(evo.ENTER, evo.LEAVE)
        :callback(function(ev)
            o = o .. (ev == evo.ENTER and 'E' or 'L')
        end)
        :build()

    local q1 = evo.builder():include(f1):build()
    local q2 = evo.builder():include(f2):build()

    do
        o = ''
        local es = evo.multi_spawn(3, { [f1] = true })
        assert(#es == 3 and o == 'eee')
        evo.batch_set(q1, f2)
        assert(o == 'eeeEEE')
        evo.batch_remove(q2, f2)
        assert(o == 'eeeEEELLL')
        evo.batch_set(q1, f2)
        assert(o == 'eeeEEELLLEEE')
        evo.batch_remove(q1, f1)
        assert(o == 'eeeEEELLLEEElllLLL')
        evo.batch_set(q2, f1)
        assert(o == 'eeeEEELLLEEElllLLLeeeEEE')
        evo.batch_destroy(q2)
        assert(o == 'eeeEEELLLEEElllLLLeeeEEElllLLL')
    end

    do
        o = ''
        local es = evo.multi_clone(2, evo.builder():set(f1):set(f2):build())
        assert(#es == 2 and o == 'eEeeEE')
        evo.destroy(f2)
        assert(o == 'eEeeEELLL')
        evo.destroy(f1)
        assert(o == 'eEeeEELLLlll')
    end

    evo.destroy(m1, m2, q1, q2)
end
