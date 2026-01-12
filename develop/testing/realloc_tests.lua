local evo = require 'evolved'

---@type ffilib?
local ffi = (function()
    local ffi_loader = package and package.preload and package.preload['ffi']
    local ffi = ffi_loader and ffi_loader()
    return ffi
end)()

if not ffi then
    return
end

local FLOAT_TYPEOF = ffi.typeof('float')
local FLOAT_SIZEOF = ffi.sizeof(FLOAT_TYPEOF)
local FLOAT_STORAGE_TYPEOF = ffi.typeof('$[?]', FLOAT_TYPEOF)

local DOUBLE_TYPEOF = ffi.typeof('double')
local DOUBLE_SIZEOF = ffi.sizeof(DOUBLE_TYPEOF)
local DOUBLE_STORAGE_TYPEOF = ffi.typeof('$[?]', DOUBLE_TYPEOF)

---@type evolved.realloc
local function float_realloc(old_storage, old_size, new_size)
    local new_storage = ffi.new(FLOAT_STORAGE_TYPEOF, new_size + 1)

    if old_storage then
        ffi.copy(new_storage + 1, old_storage + 1, math.min(old_size, new_size) * FLOAT_SIZEOF)
    end

    return new_storage
end

---@type evolved.realloc
local function double_realloc(old_storage, old_size, new_size)
    local new_storage = ffi.new(DOUBLE_STORAGE_TYPEOF, new_size + 1)

    if old_storage then
        ffi.copy(new_storage + 1, old_storage + 1, math.min(old_size, new_size) * DOUBLE_SIZEOF)
    end

    return new_storage
end

---@type evolved.compmove
local function double_compmove(src, f, e, t, dst)
    ffi.copy(dst + t, src + f, (e - f + 1) * DOUBLE_SIZEOF)
end

do
    local f1 = evo.builder():realloc(double_realloc):build()

    local e1 = evo.builder():set(f1, 21):build()
    assert(evo.has(e1, f1) and evo.get(e1, f1) == 21)

    local e2 = evo.builder():set(f1, 42):build()
    assert(evo.has(e1, f1) and evo.get(e1, f1) == 21)
    assert(evo.has(e2, f1) and evo.get(e2, f1) == 42)

    local e3 = evo.builder():set(f1, 84):build()
    assert(evo.has(e1, f1) and evo.get(e1, f1) == 21)
    assert(evo.has(e2, f1) and evo.get(e2, f1) == 42)
    assert(evo.has(e3, f1) and evo.get(e3, f1) == 84)

    evo.destroy(e1)
    assert(not evo.has(e1, f1))
    assert(evo.has(e2, f1) and evo.get(e2, f1) == 42)
    assert(evo.has(e3, f1) and evo.get(e3, f1) == 84)

    evo.destroy(e3)
    assert(not evo.has(e1, f1))
    assert(evo.has(e2, f1) and evo.get(e2, f1) == 42)
    assert(not evo.has(e3, f1))

    evo.destroy(e2)
    assert(not evo.has(e1, f1))
    assert(not evo.has(e2, f1))
    assert(not evo.has(e3, f1))
end

do
    local f1 = evo.builder():realloc(double_realloc):build()
    local q1 = evo.builder():include(f1):build()

    do
        local es, ec = {}, 10
        for i = 1, ec do es[i] = evo.spawn({ [f1] = i }) end
        for i = 1, ec do assert(evo.has(es[i], f1) and evo.get(es[i], f1) == i) end
    end

    do
        local p = evo.builder():set(f1, 42):build()
        local es, ec = {}, 10
        for i = 1, ec do es[i] = evo.clone(p) end
        for i = 1, ec do assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 42) end
    end

    do
        local es1, ec1 = evo.multi_spawn(10, { [f1] = 42 })
        for i = 1, ec1 do assert(evo.has(es1[i], f1) and evo.get(es1[i], f1) == 42) end

        local es2, ec2 = evo.multi_spawn(20, { [f1] = 84 })
        for i = 1, ec1 do assert(evo.has(es1[i], f1) and evo.get(es1[i], f1) == 42) end
        for i = 1, ec2 do assert(evo.has(es2[i], f1) and evo.get(es2[i], f1) == 84) end
    end

    do
        local p = evo.builder():set(f1, 21):build()

        local es1, ec1 = evo.multi_clone(10, p)
        for i = 1, ec1 do assert(evo.has(es1[i], f1) and evo.get(es1[i], f1) == 21) end

        local es2, ec2 = evo.multi_clone(20, p)
        for i = 1, ec1 do assert(evo.has(es1[i], f1) and evo.get(es1[i], f1) == 21) end
        for i = 1, ec2 do assert(evo.has(es2[i], f1) and evo.get(es2[i], f1) == 21) end
    end

    evo.batch_destroy(q1)
end

do
    local f1 = evo.builder():realloc(double_realloc):build()
    local f2 = evo.builder():realloc(double_realloc):build()

    local q1 = evo.builder():include(f1):build()
    local q2 = evo.builder():include(f2):build()

    do
        local e = evo.builder():set(f1, 21):set(f2, 42):build()
        assert(evo.has(e, f1) and evo.get(e, f1) == 21)
        assert(evo.has(e, f2) and evo.get(e, f2) == 42)

        evo.remove(e, f1)

        assert(not evo.has(e, f1))
        assert(evo.has(e, f2) and evo.get(e, f2) == 42)
    end

    do
        local e = evo.builder():set(f1, 21):set(f2, 42):build()
        assert(evo.has(e, f1) and evo.get(e, f1) == 21)
        assert(evo.has(e, f2) and evo.get(e, f2) == 42)

        evo.clear(e)

        assert(not evo.has(e, f1))
        assert(not evo.has(e, f2))
    end

    do
        local es, ec = evo.multi_spawn(10, { [f1] = 21, [f2] = 42 })

        for i = 1, ec do
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 21)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 42)
        end

        evo.batch_remove(q1, f1)

        local e12 = evo.builder():set(f1, 1):set(f2, 2):build()
        assert(evo.has(e12, f1) and evo.get(e12, f1) == 1)
        assert(evo.has(e12, f2) and evo.get(e12, f2) == 2)

        for i = 1, ec do
            assert(not evo.has(es[i], f1))
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 42)
        end

        evo.batch_set(q2, f1, 84)

        assert(evo.has(e12, f1) and evo.get(e12, f1) == 84)
        assert(evo.has(e12, f2) and evo.get(e12, f2) == 2)

        for i = 1, ec do
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 84)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 42)
        end

        evo.batch_set(q2, f1, 21)

        assert(evo.has(e12, f1) and evo.get(e12, f1) == 21)
        assert(evo.has(e12, f2) and evo.get(e12, f2) == 2)

        for i = 1, ec do
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 21)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 42)
        end
    end
end

do
    local f1 = evo.builder():realloc(double_realloc):compmove(double_compmove):build()
    local f2 = evo.builder():realloc(double_realloc):compmove(double_compmove):build()

    local q1 = evo.builder():include(f1):build()
    local q2 = evo.builder():include(f2):build()

    do
        local es1, ec1 = evo.multi_spawn(10, { [f1] = 1, [f2] = 2 })

        for i = 1, ec1 do
            assert(evo.has(es1[i], f1) and evo.get(es1[i], f1) == 1)
            assert(evo.has(es1[i], f2) and evo.get(es1[i], f2) == 2)
        end

        local es2, ec2 = evo.multi_spawn(20, { [f1] = 3, [f2] = 4 })

        for i = 1, ec1 do
            assert(evo.has(es1[i], f1) and evo.get(es1[i], f1) == 1)
            assert(evo.has(es1[i], f2) and evo.get(es1[i], f2) == 2)
        end

        for i = 1, ec2 do
            assert(evo.has(es2[i], f1) and evo.get(es2[i], f1) == 3)
            assert(evo.has(es2[i], f2) and evo.get(es2[i], f2) == 4)
        end

        local e2 = evo.builder():set(f2, 42):build()
        assert(evo.has(e2, f2) and evo.get(e2, f2) == 42)

        evo.batch_remove(q1, f1)

        assert(evo.has(e2, f2) and evo.get(e2, f2) == 42)

        for i = 1, ec1 do
            assert(not evo.has(es1[i], f1))
            assert(evo.has(es1[i], f2) and evo.get(es1[i], f2) == 2)
        end

        for i = 1, ec2 do
            assert(not evo.has(es2[i], f1))
            assert(evo.has(es2[i], f2) and evo.get(es2[i], f2) == 4)
        end

        local e12 = evo.builder():set(f1, 21):set(f2, 42):build()

        assert(evo.has(e2, f2) and evo.get(e2, f2) == 42)
        assert(evo.has(e12, f1) and evo.get(e12, f1) == 21)
        assert(evo.has(e12, f2) and evo.get(e12, f2) == 42)

        evo.batch_set(q2, f1, 84)

        assert(evo.has(e2, f2) and evo.get(e2, f2) == 42)
        assert(evo.has(e12, f1) and evo.get(e12, f1) == 84)
        assert(evo.has(e12, f2) and evo.get(e12, f2) == 42)

        for i = 1, ec1 do
            assert(evo.has(es1[i], f1) and evo.get(es1[i], f1) == 84)
            assert(evo.has(es1[i], f2) and evo.get(es1[i], f2) == 2)
        end

        for i = 1, ec2 do
            assert(evo.has(es2[i], f1) and evo.get(es2[i], f1) == 84)
            assert(evo.has(es2[i], f2) and evo.get(es2[i], f2) == 4)
        end
    end
end

do
    local f1 = evo.builder():default(42):build()

    local es, ec = evo.multi_spawn(10, { [f1] = 21 })
    for i = 1, ec do assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 21) end

    evo.set(f1, evo.TAG)
    for i = 1, ec do assert(evo.has(es[i], f1) and evo.get(es[i], f1) == nil) end

    evo.remove(f1, evo.TAG)
    for i = 1, ec do assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 42) end
end

do
    local f1 = evo.builder():realloc(float_realloc):build()

    local e1 = evo.builder():set(f1, 3):build()
    assert(evo.has(e1, f1) and evo.get(e1, f1) == 3)

    evo.set(f1, evo.REALLOC, double_realloc)
    assert(evo.has(e1, f1) and evo.get(e1, f1) == 3)

    evo.remove(f1, evo.REALLOC)
    assert(evo.has(e1, f1) and evo.get(e1, f1) == 3)

    evo.set(f1, evo.REALLOC, double_realloc)
    assert(evo.has(e1, f1) and evo.get(e1, f1) == 3)
end

do
    local f1 = evo.builder():realloc(double_realloc):build()

    local es, ec = evo.multi_spawn(20, { [f1] = 42 })

    for i = 1, ec / 2 do
        evo.destroy(es[ec - i + 1])
    end

    evo.collect_garbage()

    for i = 1, ec / 2 do
        assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 42)
    end
end
