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

local all_value_list = {
    1, 2, 1048577, 2 ^ 40 + 1, 0.5, -1,
    'a', 'b', 'c', true, false, {}, {},
}

local all_map_key_list = { 1, 2, 3, 'x', 'y' }

local all_index_policy_list = {
    evo.INDEX_POLICY_SELF,
    evo.INDEX_POLICY_LIST,
    evo.INDEX_POLICY_KEYS,
    evo.INDEX_POLICY_VALUES,
}

local function random_value()
    return all_value_list[math.random(1, #all_value_list)]
end

local function random_map_key()
    return all_map_key_list[math.random(1, #all_map_key_list)]
end

local all_index_fragment_list = {} ---@type evolved.fragment[]

for i = 1, math.random(1, 3) do
    local builder = evo.builder():index()

    local index_policy = all_index_policy_list[math.random(1, #all_index_policy_list)]

    if index_policy ~= evo.INDEX_POLICY_SELF or math.random(1, 2) == 1 then
        builder:index_policy(index_policy)
    end

    all_index_fragment_list[i] = builder:build()
end

local all_entity_list = {} ---@type evolved.entity[]

for i = 1, math.random(1, 20) do
    all_entity_list[i] = evo.id()
end

---
---
---
---
---

local function random_entity()
    return all_entity_list[math.random(1, #all_entity_list)]
end

local function random_index_fragment()
    return all_index_fragment_list[math.random(1, #all_index_fragment_list)]
end

---@param fragment evolved.fragment
---@return evolved.id
local function index_policy_of(fragment)
    return evo.get(fragment, evo.INDEX_POLICY) or evo.INDEX_POLICY_SELF
end

---@param fragment evolved.fragment
---@return evolved.component
local function random_component(fragment)
    local index_policy = index_policy_of(fragment)

    if index_policy == evo.INDEX_POLICY_SELF then
        return math.random(1, 10) == 1 and 0 / 0 or random_value()
    end

    local component = {}

    for i = 1, math.random(0, 8) do
        if index_policy == evo.INDEX_POLICY_LIST then
            component[i] = math.random(1, 10) == 1 and 0 / 0 or random_value()
        elseif index_policy == evo.INDEX_POLICY_KEYS then
            component[random_value()] = math.random(1, 2) == 1
        else
            component[random_map_key()] = math.random(1, 10) == 1 and 0 / 0 or random_value()
        end
    end

    return component
end

---@param fragment evolved.fragment
---@param component table
local function mutate_component(fragment, component)
    local index_policy = index_policy_of(fragment)

    if index_policy == evo.INDEX_POLICY_LIST then
        if math.random(1, 2) == 1 then
            component[#component + 1] = random_value()
        else
            component[#component] = nil
        end
    elseif index_policy == evo.INDEX_POLICY_KEYS then
        component[random_value()] = math.random(1, 2) == 1 or nil
    else
        component[random_map_key()] = math.random(1, 2) == 1 and random_value() or nil
    end
end

---@param fragment evolved.fragment
---@param component evolved.component
---@param value evolved.component
---@return boolean
local function component_has_value(fragment, component, value)
    local index_policy = index_policy_of(fragment)

    if index_policy == evo.INDEX_POLICY_SELF then
        return component == value
    end

    if index_policy == evo.INDEX_POLICY_KEYS then
        return component[value] ~= nil
    end

    for _, component_value in pairs(component) do
        if component_value == value then
            return true
        end
    end

    return false
end

---
---
---
---
---

for _, entity in ipairs(all_entity_list) do
    for _, fragment in ipairs(all_index_fragment_list) do
        if math.random(1, 2) == 1 then
            evo.set(entity, fragment, random_component(fragment))
        end
    end
end

for _ = 1, math.random(0, 4 * #all_entity_list) do
    local entity = random_entity()
    local fragment = random_index_fragment()

    local r = math.random(1, 8)

    if not evo.alive(entity) and r ~= 6 and r ~= 7 then
        -- nothing to do with destroyed entities
    elseif r <= 3 then
        evo.set(entity, fragment, random_component(fragment))
    elseif r == 4 then
        evo.remove(entity, fragment)
    elseif r == 5 then
        local component = evo.get(entity, fragment)

        if component ~= nil and index_policy_of(fragment) ~= evo.INDEX_POLICY_SELF then
            mutate_component(fragment, component)
            evo.reindex(fragment)
        end
    elseif r == 6 then
        if math.random(1, 2) == 1 then
            evo.set(fragment, evo.INDEX_POLICY, index_policy_of(fragment))
        else
            evo.remove(fragment, evo.INDEX)
            evo.set(fragment, evo.INDEX)
        end
    elseif r == 7 then
        local q = evo.builder():include(fragment):build()
        evo.batch_set(q, fragment, random_component(fragment))
        evo.destroy(q)
    else
        evo.destroy(entity)
    end
end

---
---
---
---
---

for _, fragment in ipairs(all_index_fragment_list) do
    for _, value in ipairs(all_value_list) do
        local expected_set = {} ---@type table<evolved.entity, boolean>
        local expected_count = 0

        for _, entity in ipairs(all_entity_list) do
            if evo.alive(entity) and evo.has(entity, fragment)
                and component_has_value(fragment, evo.get(entity, fragment), value)
            then
                expected_set[entity] = true
                expected_count = expected_count + 1
            end
        end

        local entity_list, entity_count = evo.multi_search(fragment, value)
        assert(entity_count == expected_count)

        for i = 1, entity_count do
            assert(expected_set[entity_list[i]])
            expected_set[entity_list[i]] = nil
        end

        assert(evo.search(fragment, value) == entity_list[1])
    end

    assert(evo.search(fragment, 0 / 0) == nil)
end

---
---
---
---
---

if math.random(1, 2) == 1 then
    evo.collect_garbage(math.random(1, 2) == 1)
end

evo.destroy(__table_unpack(all_entity_list))

for _, fragment in ipairs(all_index_fragment_list) do
    for _, value in ipairs(all_value_list) do
        assert(evo.search(fragment, value) == nil)
    end
end

evo.destroy(__table_unpack(all_index_fragment_list))

if math.random(1, 2) == 1 then
    evo.collect_garbage(math.random(1, 2) == 1)
end
