local evo = require 'evolved'

evo.debug_mode(true)

do
    local o = ''

    local f = evo.builder()
        :build()

    local m = evo.builder()
        :include(f)
        :enter(function()
            o = o .. 'e'
        end)
        :leave(function()
            o = o .. 'l'
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
        :enter(function()
            o = o .. 'e'
        end)
        :leave(function()
            o = o .. 'l'
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
        :enter(function()
            o = o .. 'e'
        end)
        :leave(function()
            o = o .. 'l'
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
        :enter(function()
            o = o .. 'e'
        end)
        :leave(function()
            o = o .. 'l'
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
        :enter(function()
            o = o .. 'e'
        end)
        :leave(function()
            o = o .. 'l'
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
        :enter(function()
            o = o .. 'e'
        end)
        :leave(function()
            o = o .. 'l'
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
