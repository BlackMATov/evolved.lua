local evo = require 'evolved'

evo.debug_mode(true)

do
    local f = evo.id()
    local e = evo.builder():set(f, 42):spawn()

    local s = evo.builder()
        :include(f)
        :prologue(function(payload1, payload2, payload3)
            assert(payload1 == 11 and payload2 == 22 and payload3 == 33)
        end)
        :execute(function(chunk, entity_list, entity_count, payload1, payload2, payload3)
            assert(payload1 == 11 and payload2 == 22 and payload3 == 33)
            assert(chunk == evo.chunk(f) and entity_count == 1 and entity_list[1] == e)
        end)
        :epilogue(function(payload1, payload2, payload3)
            assert(payload1 == 11 and payload2 == 22 and payload3 == 33)
        end)
        :spawn()

    evo.process_with(s, 11, 22, 33)
end

do
    local f = evo.id()
    local e = evo.builder():set(f, 42):spawn()

    local s = evo.builder()
        :include(f)
        :prologue(function(payload1, payload2, payload3)
            assert(payload1 == nil and payload2 == 42 and payload3 == nil)
        end)
        :execute(function(chunk, entity_list, entity_count, payload1, payload2, payload3)
            assert(payload1 == nil and payload2 == 42 and payload3 == nil)
            assert(chunk == evo.chunk(f) and entity_count == 1 and entity_list[1] == e)
        end)
        :epilogue(function(payload1, payload2, payload3)
            assert(payload1 == nil and payload2 == 42 and payload3 == nil)
        end)
        :spawn()

    evo.process_with(s, nil, 42)
end

do
    local f = evo.id()
    local e = evo.builder():set(f, 42):spawn()

    local s = evo.builder()
        :include(f)
        :prologue(function(payload1, payload2, payload3)
            assert(payload1 == nil and payload2 == nil and payload3 == nil)
        end)
        :execute(function(chunk, entity_list, entity_count, payload1, payload2, payload3)
            assert(payload1 == nil and payload2 == nil and payload3 == nil)
            assert(chunk == evo.chunk(f) and entity_count == 1 and entity_list[1] == e)
        end)
        :epilogue(function(payload1, payload2, payload3)
            assert(payload1 == nil and payload2 == nil and payload3 == nil)
        end)
        :spawn()

    evo.process_with(s)
end

do
    local f = evo.id()
    local e = evo.builder():set(f, 42):spawn()

    local prologue_sum, execute_sum, epilogue_sum = 0, 0, 0

    local function sum(...)
        local s = 0
        for i = 1, select('#', ...) do
            s = s + select(i, ...)
        end
        return s
    end

    local function iota(n)
        if n == 0 then return end
        return n, iota(n - 1)
    end

    local s = evo.builder()
        :include(f)
        :prologue(function(...)
            prologue_sum = prologue_sum + sum(...)
        end)
        :execute(function(chunk, entity_list, entity_count, ...)
            execute_sum = execute_sum + sum(...)
            assert(chunk == evo.chunk(f) and entity_count == 1 and entity_list[1] == e)
        end)
        :epilogue(function(...)
            epilogue_sum = epilogue_sum + sum(...)
        end)
        :spawn()

    for n = 0, 50 do
        prologue_sum, execute_sum, epilogue_sum = 0, 0, 0
        evo.process_with(s, iota(n))
        local expect_sum = (n * (n + 1)) / 2
        assert(prologue_sum == expect_sum)
        assert(execute_sum == expect_sum)
        assert(epilogue_sum == expect_sum)
    end
end
