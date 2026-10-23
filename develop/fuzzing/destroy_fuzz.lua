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

local remove_hook_calls = {} ---@type table<evolved.entity, table<evolved.fragment, integer>>
local hooked_fragment_set = {} ---@type table<evolved.fragment, boolean>

---@param entity evolved.entity
---@param fragment evolved.fragment
local function remove_hook(entity, fragment)
    assert(evo.alive(entity) and evo.alive(fragment))

    local entity_calls = remove_hook_calls[entity]

    if not entity_calls then
        entity_calls = {}
        remove_hook_calls[entity] = entity_calls
    end

    entity_calls[fragment] = (entity_calls[fragment] or 0) + 1
end

for _, fragment in ipairs(all_fragment_list) do
    for _ = 0, math.random(0, #all_fragment_list) do
        local other_fragment = all_fragment_list[math.random(1, #all_fragment_list)]
        evo.set(fragment, other_fragment)
    end

    if math.random(1, 5) == 1 then
        evo.set(fragment, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
    end

    if math.random(1, 5) == 1 then
        evo.set(fragment, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)
    end

    if math.random(1, 3) == 1 then
        evo.set(fragment, evo.ON_REMOVE, remove_hook)
        hooked_fragment_set[fragment] = true
    end
end

local all_entity_list = {} ---@type evolved.entity[]

for i, fragment in ipairs(all_fragment_list) do
    all_entity_list[i] = fragment
end

for _ = 1, math.random(0, #all_fragment_list) do
    local prefab = all_fragment_list[math.random(1, #all_fragment_list)]
    all_entity_list[#all_entity_list + 1] = evo.clone(prefab)
end

---
---
---
---
---

local entity_fragment_sets = {} ---@type table<evolved.entity, table<evolved.fragment, boolean>>
local fragment_destruction_policies = {} ---@type table<evolved.fragment, evolved.id>

for _, entity in ipairs(all_entity_list) do
    local entity_fragment_set = {}

    for _, fragment in ipairs(all_fragment_list) do
        if evo.has(entity, fragment) then
            entity_fragment_set[fragment] = true
        end
    end

    entity_fragment_sets[entity] = entity_fragment_set
end

for _, fragment in ipairs(all_fragment_list) do
    fragment_destruction_policies[fragment] = evo.get(fragment, evo.DESTRUCTION_POLICY)
        or evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT
end

local destroying_entity_list = {} ---@type evolved.entity[]
local should_be_destroyed_entity_set = {} ---@type table<evolved.entity, boolean>

for i = 1, math.random(1, #all_entity_list) do
    local destroying_entity = all_entity_list[math.random(1, #all_entity_list)]
    destroying_entity_list[i] = destroying_entity
    should_be_destroyed_entity_set[destroying_entity] = true
end

repeat
    local has_new_destroyed_entities = false

    for _, entity in ipairs(all_entity_list) do
        if not should_be_destroyed_entity_set[entity] then
            for fragment in pairs(entity_fragment_sets[entity]) do
                if should_be_destroyed_entity_set[fragment]
                    and fragment_destruction_policies[fragment] == evo.DESTRUCTION_POLICY_DESTROY_ENTITY
                then
                    should_be_destroyed_entity_set[entity] = true
                    has_new_destroyed_entities = true
                    break
                end
            end
        end
    end
until not has_new_destroyed_entities

---
---
---
---
---

do
    local r = math.random(1, 4)

    if r == 1 then
        evo.destroy(__table_unpack(destroying_entity_list))
    elseif r == 2 then
        assert(evo.defer())
        evo.destroy(__table_unpack(destroying_entity_list))
        assert(evo.commit())
    elseif r == 3 then
        for _, destroying_entity in ipairs(destroying_entity_list) do
            evo.destroy(destroying_entity)
        end
    elseif r == 4 then
        assert(evo.defer())
        for _, destroying_entity in ipairs(destroying_entity_list) do
            evo.destroy(destroying_entity)
        end
        assert(evo.commit())
    end
end

---
---
---
---
---

local all_chunk_query = evo.spawn()

for chunk in evo.execute(all_chunk_query) do
    for _, fragment in ipairs(all_fragment_list) do
        if should_be_destroyed_entity_set[fragment] then
            assert(not chunk:has(fragment))
        end
    end
end

for _, entity in ipairs(all_entity_list) do
    assert(evo.alive(entity) == not should_be_destroyed_entity_set[entity])
end

for _, entity in ipairs(all_entity_list) do
    if evo.alive(entity) then
        for fragment in pairs(entity_fragment_sets[entity]) do
            assert(evo.has(entity, fragment) == not should_be_destroyed_entity_set[fragment])
        end
    end
end

for _, entity in ipairs(all_entity_list) do
    local entity_calls = remove_hook_calls[entity] or {}

    for fragment in pairs(entity_fragment_sets[entity]) do
        local expected_call_count = 0

        if hooked_fragment_set[fragment] then
            if should_be_destroyed_entity_set[entity] or should_be_destroyed_entity_set[fragment] then
                expected_call_count = 1
            end
        end

        assert((entity_calls[fragment] or 0) == expected_call_count)
    end

    for fragment in pairs(entity_calls) do
        assert(entity_fragment_sets[entity][fragment])
    end
end

for entity in pairs(remove_hook_calls) do
    assert(entity_fragment_sets[entity])
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

if math.random(1, 2) == 1 then
    evo.collect_garbage(math.random(1, 2) == 1)
end
