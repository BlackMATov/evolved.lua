local evo = require 'evolved'

evo.debug_mode(true)

do
    local f1, f2, f3 = evo.id(3)

    local q1e3 = evo.builder():include(f1):exclude(f3):spawn()
    local q2e3 = evo.builder():include(f2):exclude(f3):spawn()

    local e1 = evo.builder():set(f1, 1):spawn()
    local e12 = evo.builder():set(f1, 11):set(f2, 12):spawn()
    local e2 = evo.builder():set(f2, 2):spawn()
    local e23 = evo.builder():set(f2, 23):set(f3, 3):spawn()

    local c1 = evo.chunk(f1)
    local c12 = evo.chunk(f1, f2)
    local c2 = evo.chunk(f2)

    do
        local _, entity_list, entity_count = evo.chunk(f2, f3)
        assert(entity_count == 1 and entity_list[1] == e23)
    end

    do
        local entity_sum = 0

        local s = evo.builder()
            :query(q1e3)
            :execute(function(chunk, entity_list, entity_count)
                for i = 1, entity_count do
                    entity_sum = entity_sum + entity_list[i]
                end

                if chunk == c1 then
                    assert(entity_count == 1)
                    assert(entity_list[1] == e1)
                elseif chunk == c12 then
                    assert(entity_count == 1)
                    assert(entity_list[1] == e12)
                else
                    assert(false, "Unexpected chunk: " .. tostring(chunk))
                end
            end):spawn()

        evo.process(s)

        assert(entity_sum == e1 + e12)
    end

    do
        local entity_sum = 0

        local s = evo.builder()
            :query(q2e3)
            :execute(function(chunk, entity_list, entity_count)
                for i = 1, entity_count do
                    entity_sum = entity_sum + entity_list[i]
                end

                if chunk == c12 then
                    assert(entity_count == 1)
                    assert(entity_list[1] == e12)
                elseif chunk == c2 then
                    assert(entity_count == 1)
                    assert(entity_list[1] == e2)
                else
                    assert(false, "Unexpected chunk: " .. tostring(chunk))
                end
            end):spawn()

        evo.process(s)

        assert(entity_sum == e12 + e2)
    end

    do
        local entity_sum = 0

        local s = evo.builder()
            :include(f1)
            :exclude(f3)
            :execute(function(chunk, entity_list, entity_count)
                for i = 1, entity_count do
                    entity_sum = entity_sum + entity_list[i]
                end

                if chunk == c1 then
                    assert(entity_count == 1)
                    assert(entity_list[1] == e1)
                elseif chunk == c12 then
                    assert(entity_count == 1)
                    assert(entity_list[1] == e12)
                else
                    assert(false, "Unexpected chunk: " .. tostring(chunk))
                end
            end):spawn()

        evo.process(s)

        assert(entity_sum == e1 + e12)
    end

    do
        local entity_sum = 0

        local s = evo.builder()
            :include(f2)
            :exclude(f3)
            :execute(function(chunk, entity_list, entity_count)
                for i = 1, entity_count do
                    entity_sum = entity_sum + entity_list[i]
                end

                if chunk == c12 then
                    assert(entity_count == 1)
                    assert(entity_list[1] == e12)
                elseif chunk == c2 then
                    assert(entity_count == 1)
                    assert(entity_list[1] == e2)
                else
                    assert(false, "Unexpected chunk: " .. tostring(chunk))
                end
            end):spawn()

        evo.process(s)

        assert(entity_sum == e12 + e2)
    end
end
