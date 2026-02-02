local evo = require 'evolved'

---@type ffilib?
local ffi = (function()
    if package and package.loaded then
        local loaded_ffi = package.loaded.ffi
        if loaded_ffi then return loaded_ffi end
    end

    if package and package.preload then
        local ffi_loader = package.preload.ffi
        if ffi_loader then return ffi_loader() end
    end
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

local STORAGE_SIZES = {}

---@type evolved.realloc
local function float_realloc(src, src_size, dst_size)
    if dst_size == 0 then
        assert(src and src_size > 0)
        local expected_src_size = STORAGE_SIZES[src]
        assert(expected_src_size == src_size)
        STORAGE_SIZES[src] = nil
        return
    else
        if src then
            assert(src_size > 0)
            local expected_src_size = STORAGE_SIZES[src]
            assert(expected_src_size == src_size)
        else
            assert(src_size == 0)
        end

        local dst = ffi.new(FLOAT_STORAGE_TYPEOF, dst_size + 1)
        STORAGE_SIZES[dst] = dst_size

        if src then
            ffi.copy(dst + 1, src + 1, math.min(src_size, dst_size) * FLOAT_SIZEOF)
        end

        return dst
    end
end

---@type evolved.realloc
local function double_realloc(src, src_size, dst_size)
    if dst_size == 0 then
        assert(src and src_size > 0)
        local expected_src_size = STORAGE_SIZES[src]
        assert(expected_src_size == src_size)
        STORAGE_SIZES[src] = nil
        return
    else
        if src then
            assert(src_size > 0)
            local expected_src_size = STORAGE_SIZES[src]
            assert(expected_src_size == src_size)
        else
            assert(src_size == 0)
        end

        local dst = ffi.new(DOUBLE_STORAGE_TYPEOF, dst_size + 1)
        STORAGE_SIZES[dst] = dst_size

        if src then
            ffi.copy(dst + 1, src + 1, math.min(src_size, dst_size) * DOUBLE_SIZEOF)
        end

        return dst
    end
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

do
    evo.collect_garbage()

    local f1 = evo.builder():name('f1'):realloc(double_realloc):compmove(double_compmove):build()
    local f2 = evo.builder():name('f2'):realloc(double_realloc):compmove(double_compmove):build()

    local q1 = evo.builder():include(f1):build()
    local q2 = evo.builder():include(f2):build()

    do
        local es, ec = evo.multi_spawn(40, { [f2] = 2 })
        for i = 1, ec do
            assert(not evo.has(es[i], f1))
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 2)
        end
        evo.batch_destroy(q2)
    end

    do
        local es, ec = evo.multi_spawn(50, { [f1] = 1, [f2] = 2 })
        for i = 1, ec do
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 1)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 2)
        end

        evo.batch_remove(q1, f1)
        for i = 1, ec do
            assert(not evo.has(es[i], f1))
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 2)
        end

        evo.batch_destroy(q1, q2)
    end

    do
        evo.spawn({ [f1] = 1 })
        evo.spawn({ [f2] = 2 })
        evo.spawn({ [f1] = 1, [f2] = 2 })
    end

    evo.collect_garbage()
end

do
    evo.collect_garbage()

    local f1 = evo.builder():name('f1'):realloc(double_realloc):compmove(double_compmove):build()
    local f2 = evo.builder():name('f2'):realloc(double_realloc):compmove(double_compmove):build()

    local q1 = evo.builder():include(f1):build()
    local q2 = evo.builder():include(f2):build()

    do
        local es, ec = evo.multi_spawn(40, { [f1] = 1, [f2] = 2 })
        for i = 1, ec do
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 1)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 2)
        end
        evo.batch_destroy(q2)
    end

    do
        local es, ec = evo.multi_spawn(50, { [f1] = 1 })
        for i = 1, ec do
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 1)
            assert(not evo.has(es[i], f2))
        end

        evo.batch_set(q1, f2, 2)
        for i = 1, ec do
            assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 1)
            assert(evo.has(es[i], f2) and evo.get(es[i], f2) == 2)
        end

        evo.batch_destroy(q1, q2)
    end

    do
        evo.spawn({ [f1] = 1 })
        evo.spawn({ [f2] = 2 })
        evo.spawn({ [f1] = 1, [f2] = 2 })
    end

    evo.collect_garbage()
end

do
    evo.collect_garbage()

    local alloc_call_count = 0
    local free_call_count = 0
    local resize_call_count = 0

    local function ctor_realloc()
        ---@type evolved.realloc
        return function(src, src_size, dst_size)
            if dst_size == 0 then
                assert(src and src_size > 0)
                free_call_count = free_call_count + 1
                return
            else
                if src then
                    assert(src_size > 0)
                    resize_call_count = resize_call_count + 1
                else
                    assert(src_size == 0)
                    alloc_call_count = alloc_call_count + 1
                end

                local dst = {}

                if src then
                    for i = 1, math.min(src_size, dst_size) do
                        dst[i] = src[i]
                    end
                end

                return dst
            end
        end
    end

    do
        local realloc1 = ctor_realloc()
        local realloc2 = ctor_realloc()

        local f1 = evo.builder():default(44):realloc(realloc1):build()

        alloc_call_count, free_call_count, resize_call_count = 0, 0, 0

        do
            local e1 = evo.builder():set(f1, 21):build()
            assert(evo.has(e1, f1) and evo.get(e1, f1) == 21)
            assert(alloc_call_count == 1 and free_call_count == 0)

            local e2 = evo.builder():set(f1, 42):build()
            assert(evo.has(e1, f1) and evo.get(e1, f1) == 21)
            assert(evo.has(e2, f1) and evo.get(e2, f1) == 42)
            assert(alloc_call_count == 1 and free_call_count == 0)

            evo.collect_garbage()
            assert(alloc_call_count == 1 and free_call_count == 0 and resize_call_count == 0)

            evo.destroy(e1)
            assert(alloc_call_count == 1 and free_call_count == 0 and resize_call_count == 0)

            evo.collect_garbage()
            assert(alloc_call_count == 1 and free_call_count == 0 and resize_call_count == 0)

            evo.destroy(e2)
            assert(alloc_call_count == 1 and free_call_count == 0 and resize_call_count == 0)

            evo.collect_garbage()
            assert(alloc_call_count == 1 and free_call_count == 1 and resize_call_count == 0)
        end

        alloc_call_count, free_call_count, resize_call_count = 0, 0, 0

        do
            local es, ec = evo.multi_spawn(10, { [f1] = 84 })
            assert(alloc_call_count == 1 and free_call_count == 0 and resize_call_count == 0)

            for i = 1, ec / 2 do evo.destroy(es[i]) end
            assert(alloc_call_count == 1 and free_call_count == 0 and resize_call_count == 0)

            evo.collect_garbage()
            assert(alloc_call_count == 1 and free_call_count == 0 and resize_call_count == 1)

            evo.set(f1, evo.REALLOC, realloc2)
            assert(alloc_call_count == 2 and free_call_count == 1 and resize_call_count == 1)

            for i = 1, ec do evo.destroy(es[i]) end
            evo.collect_garbage()
            assert(alloc_call_count == 2 and free_call_count == 2 and resize_call_count == 1)
        end

        alloc_call_count, free_call_count, resize_call_count = 0, 0, 0

        do
            local e1 = evo.builder():set(f1, 24):build()
            assert(evo.has(e1, f1) and evo.get(e1, f1) == 24)
            assert(alloc_call_count == 1 and free_call_count == 0 and resize_call_count == 0)

            evo.set(f1, evo.TAG)
            assert(evo.has(e1, f1) and evo.get(e1, f1) == nil)
            assert(alloc_call_count == 1 and free_call_count == 1 and resize_call_count == 0)

            local es, ec = evo.multi_spawn(20, { [f1] = 48 })
            for i = 1, ec do assert(evo.has(es[i], f1) and evo.get(es[i], f1) == nil) end
            assert(alloc_call_count == 1 and free_call_count == 1 and resize_call_count == 0)

            evo.remove(f1, evo.TAG)
            assert(evo.has(e1, f1) and evo.get(e1, f1) == 44)
            for i = 1, ec do assert(evo.has(es[i], f1) and evo.get(es[i], f1) == 44) end
            assert(alloc_call_count == 2 and free_call_count == 1 and resize_call_count == 0)

            evo.destroy(e1)
            for i = 1, ec do evo.destroy(es[i]) end
            assert(alloc_call_count == 2 and free_call_count == 1 and resize_call_count == 0)

            evo.collect_garbage()
            assert(alloc_call_count == 2 and free_call_count == 2 and resize_call_count == 0)
        end

        alloc_call_count, free_call_count, resize_call_count = 0, 0, 0

        do
            local e1 = evo.builder():set(f1, 100):build()
            assert(evo.has(e1, f1) and evo.get(e1, f1) == 100)
            assert(alloc_call_count == 1 and free_call_count == 0 and resize_call_count == 0)

            evo.set(f1, evo.TAG)
            assert(evo.has(e1, f1) and evo.get(e1, f1) == nil)
            assert(alloc_call_count == 1 and free_call_count == 1 and resize_call_count == 0)

            local es, ec = evo.multi_spawn(20, { [f1] = 48 })
            for i = 1, ec do assert(evo.has(es[i], f1) and evo.get(es[i], f1) == nil) end
            assert(alloc_call_count == 1 and free_call_count == 1 and resize_call_count == 0)

            evo.destroy(e1)
            for i = 1, ec do evo.destroy(es[i]) end
            assert(alloc_call_count == 1 and free_call_count == 1 and resize_call_count == 0)

            evo.collect_garbage()
            assert(alloc_call_count == 1 and free_call_count == 1 and resize_call_count == 0)
        end
    end


    do
        local realloc = ctor_realloc()

        local f1 = evo.builder():realloc(realloc):build()

        alloc_call_count, free_call_count, resize_call_count = 0, 0, 0

        do
            local e1 = evo.builder():set(f1, 42):build()
            assert(evo.has(e1, f1) and evo.get(e1, f1) == 42)
            assert(alloc_call_count == 1 and free_call_count == 0 and resize_call_count == 0)

            evo.destroy(e1)
            assert(not evo.has(e1, f1) and evo.get(e1, f1) == nil)
            assert(alloc_call_count == 1 and free_call_count == 0 and resize_call_count == 0)

            evo.set(f1, evo.TAG)
            assert(alloc_call_count == 1 and free_call_count == 1 and resize_call_count == 0)
        end
    end
end
