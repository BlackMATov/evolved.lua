local evo = require 'evolved'
local basics = require 'develop.basics'

evo.debug_mode(false)

local N = 100000
local Ps = { 0, 10 }

local f0 = evo.builder()
    :default(0)
    :build()

local f1 = evo.builder()
    :default(0)
    :build()

local f2 = evo.builder()
    :default(0)
    :build()

local f3 = evo.builder()
    :default(0)
    :build()

local ffi_ok, ffi = pcall(require, 'ffi')

if ffi_ok then
    local FFI_DOUBLE_TYPEOF = ffi.typeof('double')
    local FFI_DOUBLE_SIZEOF = ffi.sizeof(FFI_DOUBLE_TYPEOF)
    local FFI_DOUBLE_STORAGE_TYPEOF = ffi.typeof('double[?]')

    ---@param src ffi.cdata*?
    ---@param src_size integer
    ---@param dst_size integer
    ---@return ffi.cdata*?
    local function FFI_DOUBLE_STORAGE_REALLOC(src, src_size, dst_size)
        if dst_size == 0 then
            -- freeing the src storage, just let the GC handle it
            return
        end

        -- to support 1-based indexing, allocate one extra element
        local dst = ffi.new(FFI_DOUBLE_STORAGE_TYPEOF, dst_size + 1)

        if src and src_size > 0 then
            -- handle both expanding and shrinking
            local min_size = math.min(src_size, dst_size)
            ffi.copy(dst + 1, src + 1, min_size * FFI_DOUBLE_SIZEOF)
        end

        return dst
    end

    ---@param src ffi.cdata*
    ---@param f integer
    ---@param e integer
    ---@param t integer
    ---@param dst ffi.cdata*
    local function FFI_DOUBLE_STORAGE_COMPMOVE(src, f, e, t, dst)
        ffi.copy(dst + t, src + f, (e - f + 1) * FFI_DOUBLE_SIZEOF)
    end

    evo.set(f0, evo.REALLOC, FFI_DOUBLE_STORAGE_REALLOC)
    evo.set(f0, evo.COMPMOVE, FFI_DOUBLE_STORAGE_COMPMOVE)

    evo.set(f1, evo.REALLOC, FFI_DOUBLE_STORAGE_REALLOC)
    evo.set(f1, evo.COMPMOVE, FFI_DOUBLE_STORAGE_COMPMOVE)

    evo.set(f2, evo.REALLOC, FFI_DOUBLE_STORAGE_REALLOC)
    evo.set(f2, evo.COMPMOVE, FFI_DOUBLE_STORAGE_COMPMOVE)

    evo.set(f3, evo.REALLOC, FFI_DOUBLE_STORAGE_REALLOC)
    evo.set(f3, evo.COMPMOVE, FFI_DOUBLE_STORAGE_COMPMOVE)
end

print '----------------------------------------'

for _, P in ipairs(Ps) do
    basics.describe_bench(string.format('Other Benchmarks: SystemWith1Component, %d padding | %d entities', P, N),
        function(w)
            evo.process(w)
        end, function()
            local w = evo.builder()
                :set(evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
                :build()

            local count = 0

            while count < N do
                evo.spawn({ [w] = true, [f1] = 0, })
                count = count + 1

                for _ = 0, P - 1 do
                    evo.spawn({ [w] = true, [f0] = 0, })
                    count = count + 1
                    if count >= N then break end
                end
            end

            evo.builder():set(w):group(w):include(f1)
                :execute(function(chunk, _, entity_count)
                    local f1s = chunk:components(f1)

                    for i = 1, entity_count do
                        f1s[i] = f1s[i] + 1
                    end
                end):build()

            return w
        end, function(w)
            evo.destroy(w)
        end)
end

print '----------------------------------------'

for _, P in ipairs(Ps) do
    basics.describe_bench(string.format('Other Benchmarks: SystemWith2Component, %d padding | %d entities', P, N),
        function(w)
            evo.process(w)
        end, function()
            local w = evo.builder()
                :set(evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
                :build()

            local count = 0

            while count < N do
                evo.spawn({ [w] = true, [f1] = 0, [f2] = 1, })
                count = count + 1

                for j = 0, P - 1 do
                    local m = j % 2
                    if m == 0 then
                        evo.spawn({ [w] = true, [f1] = 0, })
                    elseif m == 1 then
                        evo.spawn({ [w] = true, [f2] = 0, })
                    else
                        assert(false)
                    end
                    count = count + 1
                    if count >= N then break end
                end
            end

            evo.builder():set(w):group(w):include(f1, f2)
                :execute(function(chunk, _, entity_count)
                    local f1s, f2s = chunk:components(f1, f2)

                    for i = 1, entity_count do
                        f1s[i] = f1s[i] + f2s[i]
                    end
                end):build()

            return w
        end, function(w)
            evo.destroy(w)
        end)
end

print '----------------------------------------'

for _, P in ipairs(Ps) do
    basics.describe_bench(string.format('Other Benchmarks: SystemWith3Component, %d padding | %d entities', P, N),
        function(w)
            evo.process(w)
        end, function()
            local w = evo.builder()
                :set(evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
                :build()

            local count = 0

            while count < N do
                evo.spawn({ [w] = true, [f1] = 0, [f2] = 1, [f3] = 1, })
                count = count + 1

                for j = 0, P - 1 do
                    local m = j % 3
                    if m == 0 then
                        evo.spawn({ [w] = true, [f1] = 0, })
                    elseif m == 1 then
                        evo.spawn({ [w] = true, [f2] = 0, })
                    elseif m == 2 then
                        evo.spawn({ [w] = true, [f3] = 0, })
                    else
                        assert(false)
                    end
                    count = count + 1
                    if count >= N then break end
                end
            end

            evo.builder():set(w):group(w):include(f1, f2, f3)
                :execute(function(chunk, _, entity_count)
                    local f1s, f2s, f3s = chunk:components(f1, f2, f3)

                    for i = 1, entity_count do
                        f1s[i] = f1s[i] + f2s[i] + f3s[i]
                    end
                end):build()

            return w
        end, function(w)
            evo.destroy(w)
        end)
end
