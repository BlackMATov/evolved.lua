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

for i = 1, math.random(1, 10) do
    local entity = evo.id()
    all_entity_list[i] = entity
end

for _, entity in ipairs(all_entity_list) do
    for _ = 0, math.random(0, #all_entity_list) do
        local fragment = all_entity_list[math.random(1, #all_entity_list)]
        evo.set(entity, fragment)
    end

    if math.random(1, 5) == 1 then
        evo.set(entity, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
    end

    if math.random(1, 5) == 1 then
        evo.set(entity, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT)
    end
end

---
---
---
---
---

local should_be_destroyed_entity_set = {} ---@type table<evolved.entity, integer>
local should_be_destroyed_entity_list = {} ---@type evolved.entity[]
local should_be_destroyed_entity_count = 0 ---@type integer

local function collect_destroyed_entities_with(entity)
    local entity_destruction_policy = evo.get(entity, evo.DESTRUCTION_POLICY)
        or evo.DESTRUCTION_POLICY_REMOVE_FRAGMENT

    if entity_destruction_policy == evo.DESTRUCTION_POLICY_DESTROY_ENTITY then
        for _, other_entity in ipairs(all_entity_list) do
            if evo.has(other_entity, entity) and not should_be_destroyed_entity_set[other_entity] then
                should_be_destroyed_entity_count = should_be_destroyed_entity_count + 1
                should_be_destroyed_entity_list[should_be_destroyed_entity_count] = other_entity
                should_be_destroyed_entity_set[other_entity] = should_be_destroyed_entity_count
            end
        end
    end
end

local destroying_include_list = {} ---@type evolved.entity[]

for i = 1, math.random(1, #all_entity_list) do
    local destroying_include = all_entity_list[math.random(1, #all_entity_list)]
    destroying_include_list[i] = destroying_include
end

for _, entity in ipairs(all_entity_list) do
    if evo.has_all(entity, __table_unpack(destroying_include_list)) then
        collect_destroyed_entities_with(entity)
    end
end

do
    local r = math.random(1, 2)
    local q = evo.builder():include(__table_unpack(destroying_include_list)):spawn()

    if r == 1 then
        evo.batch_destroy(q)
    elseif r == 2 then
        assert(evo.defer())
        evo.batch_destroy(q)
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
    assert(not chunk:has_any(__table_unpack(should_be_destroyed_entity_list)))
    for _, fragment in ipairs(chunk:fragments()) do
        assert(not evo.has_all(fragment, __table_unpack(destroying_include_list)))
    end
end

for _, destroyed_entity in ipairs(should_be_destroyed_entity_list) do
    assert(not evo.alive(destroyed_entity))
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
