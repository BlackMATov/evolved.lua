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

local all_fragment_list = {} ---@type evolved.fragment[]

for i = 1, math.random(1, 10) do
    local fragment = evo.id()
    all_fragment_list[i] = fragment
end

---@param query evolved.query
local function generate_query(query)
    local include_set = {}
    local include_list = {}
    local include_count = 0

    for _ = 1, math.random(0, #all_fragment_list) do
        local include = all_fragment_list[math.random(1, #all_fragment_list)]

        if not include_set[include] then
            include_count = include_count + 1
            include_set[include] = include_count
            include_list[include_count] = include
        end
    end

    local exclude_set = {}
    local exclude_list = {}
    local exclude_count = 0

    for _ = 1, math.random(0, #all_fragment_list) do
        local exclude = all_fragment_list[math.random(1, #all_fragment_list)]

        if not exclude_set[exclude] then
            exclude_count = exclude_count + 1
            exclude_set[exclude] = exclude_count
            exclude_list[exclude_count] = exclude
        end
    end

    local variant_set = {}
    local variant_list = {}
    local variant_count = 0

    for _ = 1, math.random(0, #all_fragment_list) do
        local variant = all_fragment_list[math.random(1, #all_fragment_list)]

        if not variant_set[variant] then
            variant_count = variant_count + 1
            variant_set[variant] = variant_count
            variant_list[variant_count] = variant
        end
    end

    if include_count > 0 then
        evo.set(query, evo.INCLUDES, include_list)
    end

    if exclude_count > 0 then
        evo.set(query, evo.EXCLUDES, exclude_list)
    end

    if variant_count > 0 then
        evo.set(query, evo.VARIANTS, variant_list)
    end
end

---@param query_count integer
---@return evolved.query[] query_list
---@return integer query_count
---@nodiscard
local function generate_queries(query_count)
    local query_list = {} ---@type evolved.query[]

    for i = 1, query_count do
        local query = evo.id()
        query_list[i] = query
        generate_query(query)
    end

    return query_list, query_count
end

---@param entity evolved.entity
local function generate_entity(entity)
    for _ = 0, math.random(0, #all_fragment_list) do
        local fragment = all_fragment_list[math.random(1, #all_fragment_list)]
        evo.set(entity, fragment)
    end
end

---@param entity_count integer
---@return evolved.entity[] entity_list
---@return integer entity_count
local function generate_entities(entity_count)
    local entity_list = {} ---@type evolved.entity[]

    for i = 1, entity_count do
        local entity = evo.id()
        entity_list[i] = entity
        generate_entity(entity)
    end

    return entity_list, entity_count
end

local pre_query_list, pre_query_count = generate_queries(math.random(1, 10))
local pre_entity_list, pre_entity_count = generate_entities(math.random(1, 10))

for _ = 1, math.random(1, 5) do
    local fragment = all_fragment_list[math.random(1, #all_fragment_list)]

    evo.set(fragment, evo.EXPLICIT)
end

for _ = 1, math.random(1, 5) do
    local query = pre_query_list[math.random(1, pre_query_count)]

    if math.random(1, 2) == 1 then
        generate_query(query)
    else
        if math.random(1, 2) == 1 then
            evo.remove(query, evo.INCLUDES)
        else
            evo.remove(query, evo.EXCLUDES)
        end
    end
end

local post_query_list, post_query_count = generate_queries(math.random(1, 10))
local post_entity_list, post_entity_count = generate_entities(math.random(1, 10))

---
---
---
---
---

local all_query_list = {}
local all_query_count = 0
local all_entity_list = {}
local all_entity_count = 0

for i = 1, pre_query_count do
    all_query_count = all_query_count + 1
    all_query_list[all_query_count] = pre_query_list[i]
end

for i = 1, post_query_count do
    all_query_count = all_query_count + 1
    all_query_list[all_query_count] = post_query_list[i]
end

for i = 1, pre_entity_count do
    all_entity_count = all_entity_count + 1
    all_entity_list[all_entity_count] = pre_entity_list[i]
end

for i = 1, post_entity_count do
    all_entity_count = all_entity_count + 1
    all_entity_list[all_entity_count] = post_entity_list[i]
end

---
---
---
---
---

local function execute_query(query)
    local query_chunk_set = {}
    local query_entity_set = {}

    local query_include_list = evo.get(query, evo.INCLUDES) or {}
    local query_exclude_list = evo.get(query, evo.EXCLUDES) or {}
    local query_variant_list = evo.get(query, evo.VARIANTS) or {}

    local query_include_count = #query_include_list
    local query_exclude_count = #query_exclude_list
    local query_variant_count = #query_variant_list

    local query_include_set = {}
    for _, include in ipairs(query_include_list) do
        query_include_set[include] = true
    end

    local query_variant_set = {}
    for _, variant in ipairs(query_variant_list) do
        query_variant_set[variant] = true
    end

    for chunk, entity_list, entity_count in evo.execute(query) do
        assert(not query_chunk_set[chunk])
        query_chunk_set[chunk] = true

        for i = 1, entity_count do
            local entity = entity_list[i]
            assert(not query_entity_set[entity])
            query_entity_set[entity] = true
        end

        if query_include_count > 0 then
            assert(chunk:has_all(__table_unpack(query_include_list)))
        end

        if query_exclude_count > 0 then
            assert(not chunk:has_any(__table_unpack(query_exclude_list)))
        end

        if query_variant_count > 0 then
            assert(chunk:has_any(__table_unpack(query_variant_list)))
        end
    end

    for i = 1, all_entity_count do
        local entity = all_entity_list[i]

        local is_entity_matched =
            (query_variant_count == 0 or evo.has_any(entity, __table_unpack(query_variant_list))) and
            (query_include_count == 0 or evo.has_all(entity, __table_unpack(query_include_list))) and
            (query_exclude_count == 0 or not evo.has_any(entity, __table_unpack(query_exclude_list)))

        for fragment in evo.each(entity) do
            if evo.has(fragment, evo.EXPLICIT) and not query_variant_set[fragment] and not query_include_set[fragment] then
                is_entity_matched = false
            end
        end

        if is_entity_matched then
            assert(query_entity_set[entity])
        else
            assert(not query_entity_set[entity])
        end
    end
end

for i = 1, all_query_count do
    execute_query(all_query_list[i])
end

---
---
---
---
---

for _ = 1, math.random(1, 5) do
    local fragment = all_fragment_list[math.random(1, #all_fragment_list)]

    evo.set(fragment, evo.EXPLICIT)
end

for _ = 1, math.random(1, 5) do
    local query = pre_query_list[math.random(1, pre_query_count)]

    if math.random(1, 2) == 1 then
        generate_query(query)
    else
        local r = math.random(1, 3)
        if r == 1 then
            evo.remove(query, evo.INCLUDES)
        elseif r == 2 then
            evo.remove(query, evo.EXCLUDES)
        else
            evo.remove(query, evo.VARIANTS)
        end
    end
end

for i = 1, all_query_count do
    execute_query(all_query_list[i])
end

---
---
---
---
---

if math.random(1, 2) == 1 then
    evo.collect_garbage(math.random(1, 2) == 1)
end

evo.destroy(__table_unpack(all_query_list))
evo.destroy(__table_unpack(all_entity_list))
evo.destroy(__table_unpack(all_fragment_list))

if math.random(1, 2) == 1 then
    evo.collect_garbage(math.random(1, 2) == 1)
end
