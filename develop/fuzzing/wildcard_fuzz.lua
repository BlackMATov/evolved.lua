local evo = require 'evolved'

evo.debug_mode(true)

---
---
---
---
---

local __table_unpack = (function()
    ---@diagnostic disable-next-line: deprecated
    return table.unpack or unpack
end)()

---
---
---
---
---

local all_entity_list = {} ---@type evolved.entity[]
local all_fragment_list = {} ---@type evolved.fragment[]

for i = 1, math.random(1, 5) do
    local fragment_builder = evo.builder()

    if math.random(1, 3) == 1 then
        fragment_builder:explicit()
    end

    if math.random(1, 3) == 1 then
        if math.random(1, 2) == 1 then
            fragment_builder:destruction_policy(evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
        else
            fragment_builder:destruction_policy(evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)
        end
    end

    all_fragment_list[i] = fragment_builder:spawn()
end

for i = 1, math.random(50, 100) do
    local entity_builder = evo.builder()

    for _ = 0, math.random(0, #all_fragment_list) do
        if math.random(1, 2) == 1 then
            local fragment = all_fragment_list[math.random(1, #all_fragment_list)]
            entity_builder:set(fragment)
        else
            local primary = all_fragment_list[math.random(1, #all_fragment_list)]
            local secondary = all_fragment_list[math.random(1, #all_fragment_list)]
            entity_builder:set(evo.pair(primary, secondary))
        end
    end

    all_entity_list[i] = entity_builder:spawn()
end

---
---
---
---
---

for _ = 1, math.random(1, 100) do
    local query_builder = evo.builder()

    local query_include_set = {} ---@type table<evolved.fragment, integer>
    local query_include_list = {} ---@type evolved.entity[]
    local query_include_count = 0 ---@type integer

    local query_exclude_set = {} ---@type table<evolved.fragment, integer>
    local query_exclude_list = {} ---@type evolved.entity[]
    local query_exclude_count = 0 ---@type integer

    for _ = 1, math.random(0, 2) do
        if math.random(1, 2) == 1 then
            local fragment = all_fragment_list[math.random(1, #all_fragment_list)]

            query_builder:include(fragment)

            if not query_include_set[fragment] then
                query_include_count = query_include_count + 1
                query_include_set[fragment] = query_include_count
                query_include_list[query_include_count] = fragment
            end
        else
            local primary = all_fragment_list[math.random(1, #all_fragment_list)]
            local secondary = all_fragment_list[math.random(1, #all_fragment_list)]

            if math.random(1, 3) == 1 then
                primary = evo.ANY
            end

            if math.random(1, 3) == 1 then
                secondary = evo.ANY
            end

            local pair = evo.pair(primary, secondary)

            query_builder:include(pair)

            if not query_include_set[pair] then
                query_include_count = query_include_count + 1
                query_include_set[pair] = query_include_count
                query_include_list[query_include_count] = pair
            end
        end
    end

    for _ = 1, math.random(0, 2) do
        if math.random(1, 2) == 1 then
            local fragment = all_fragment_list[math.random(1, #all_fragment_list)]

            query_builder:exclude(fragment)

            if not query_exclude_set[fragment] then
                query_exclude_count = query_exclude_count + 1
                query_exclude_set[fragment] = query_exclude_count
                query_exclude_list[query_exclude_count] = fragment
            end
        else
            local primary = all_fragment_list[math.random(1, #all_fragment_list)]
            local secondary = all_fragment_list[math.random(1, #all_fragment_list)]

            if math.random(1, 3) == 1 then
                primary = evo.ANY
            end

            if math.random(1, 3) == 1 then
                secondary = evo.ANY
            end

            local pair = evo.pair(primary, secondary)

            query_builder:exclude(pair)

            if not query_exclude_set[pair] then
                query_exclude_count = query_exclude_count + 1
                query_exclude_set[pair] = query_exclude_count
                query_exclude_list[query_exclude_count] = pair
            end
        end
    end

    local query_entity_set = {} ---@type table<evolved.entity, integer>
    local query_entity_count = 0 ---@type integer

    do
        local query = query_builder:spawn()

        for chunk, entity_list, entity_count in evo.execute(query) do
            if not chunk:has(evo.INTERNAL) then
                for i = 1, entity_count do
                    local entity = entity_list[i]
                    assert(not query_entity_set[entity])
                    query_entity_count = query_entity_count + 1
                    query_entity_set[entity] = query_entity_count
                end
            end
        end

        if query_entity_set[query] then
            query_entity_set[query] = nil
            query_entity_count = query_entity_count - 1
        end

        evo.destroy(query)
    end

    do
        local expected_entity_count = 0

        for _, entity in ipairs(all_entity_list) do
            local is_entity_expected =
                not evo.empty(entity) and
                evo.has_all(entity, __table_unpack(query_include_list)) and
                not evo.has_any(entity, __table_unpack(query_exclude_list))

            for fragment in evo.each(entity) do
                local is_fragment_explicit = false

                if not is_fragment_explicit and evo.is_pair(fragment) then
                    is_fragment_explicit = evo.has(evo.unpair(fragment), evo.EXPLICIT)
                end

                if not is_fragment_explicit and not evo.is_pair(fragment) then
                    is_fragment_explicit = evo.has(fragment, evo.EXPLICIT)
                end

                if is_fragment_explicit then
                    local is_fragment_included = false

                    if not is_fragment_included then
                        is_fragment_included = query_include_set[fragment] ~= nil
                    end

                    if not is_fragment_included and evo.is_pair(fragment) then
                        local fragment_primary = evo.unpair(fragment)
                        is_fragment_included = query_include_set[evo.pair(fragment_primary, evo.ANY)] ~= nil
                    end

                    if not is_fragment_included and not evo.is_pair(fragment) then
                        is_fragment_included = query_include_set[evo.pair(fragment, evo.ANY)] ~= nil
                    end

                    if not is_fragment_included then
                        is_entity_expected = false
                        break
                    end
                end
            end

            if is_entity_expected then
                assert(query_entity_set[entity])
                expected_entity_count = expected_entity_count + 1
            else
                assert(not query_entity_set[entity])
            end
        end

        for _, entity in ipairs(all_fragment_list) do
            local is_entity_expected =
                not evo.empty(entity) and
                evo.has_all(entity, __table_unpack(query_include_list)) and
                not evo.has_any(entity, __table_unpack(query_exclude_list))

            for fragment in evo.each(entity) do
                if evo.has(fragment, evo.EXPLICIT) then
                    is_entity_expected = is_entity_expected and
                        (query_include_set[fragment] ~= nil) or
                        (evo.is_pair(fragment) and query_include_set[evo.pair(fragment, evo.ANY)] ~= nil)
                end
            end

            if is_entity_expected then
                assert(query_entity_set[entity])
                expected_entity_count = expected_entity_count + 1
            else
                assert(not query_entity_set[entity])
            end
        end

        assert(query_entity_count == expected_entity_count)
    end
end

---
---
---
---
---

if math.random(1, 2) == 1 then
    evo.collect_garbage()
end

if math.random(1, 2) == 1 then
    evo.destroy(__table_unpack(all_entity_list))
    if math.random(1, 2) == 1 then
        evo.collect_garbage()
    end
    evo.destroy(__table_unpack(all_fragment_list))
else
    evo.destroy(__table_unpack(all_fragment_list))
    if math.random(1, 2) == 1 then
        evo.collect_garbage()
    end
    evo.destroy(__table_unpack(all_entity_list))
end

if math.random(1, 2) == 1 then
    evo.collect_garbage()
end
