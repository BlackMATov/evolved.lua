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
    local fragment = evo.builder()
        :default(42)
        :spawn()
    all_fragment_list[i] = fragment
end

for _, fragment in ipairs(all_fragment_list) do
    if math.random(1, 2) == 1 then
        for _ = 0, math.random(0, #all_fragment_list) do
            local require_list = evo.get(fragment, evo.REQUIRES) or {}
            require_list[#require_list + 1] = all_fragment_list[math.random(1, #all_fragment_list)]
            evo.set(fragment, evo.REQUIRES, require_list)
        end
    end
end

local all_entity_list = {} ---@type evolved.entity[]

for i = 1, math.random(1, 10) do
    local entity = evo.id()
    all_entity_list[i] = entity

    for _ = 0, math.random(0, #all_fragment_list) do
        local fragment = all_fragment_list[math.random(1, #all_fragment_list)]

        if math.random(1, 2) == 1 then
            evo.set(entity, fragment, 42)
        else
            local query = evo.builder()
                :include(all_fragment_list[math.random(1, #all_fragment_list)])
                :spawn()
            evo.batch_set(query, fragment, 42)
            evo.destroy(query)
        end
    end
end

for _ = 1, math.random(1, #all_entity_list) do
    local components = {}
    for _ = 1, math.random(1, #all_fragment_list) do
        local fragment = all_fragment_list[math.random(1, #all_fragment_list)]
        components[fragment] = 42
    end
    all_entity_list[#all_entity_list + 1] = evo.spawn(components)
end

for _ = 1, math.random(1, #all_entity_list) do
    local prefab = all_entity_list[math.random(1, #all_entity_list)]
    all_entity_list[#all_entity_list + 1] = evo.clone(prefab)
end

---
---
---
---
---

local function collect_required_fragments_for(fragment, req_fragment_set, req_fragment_list)
    local fragment_requires = evo.get(fragment, evo.REQUIRES) or {}
    for _, required_fragment in ipairs(fragment_requires) do
        if not req_fragment_set[required_fragment] then
            req_fragment_set[required_fragment] = true
            req_fragment_list[#req_fragment_list + 1] = required_fragment
            collect_required_fragments_for(required_fragment, req_fragment_set, req_fragment_list)
        end
    end
end

for _, entity in ipairs(all_entity_list) do
    for fragment in evo.each(entity) do
        local req_fragment_list = {}
        collect_required_fragments_for(fragment, {}, req_fragment_list)
        for _, required_fragment in ipairs(req_fragment_list) do
            assert(evo.has(entity, required_fragment))
            local required_component = evo.get(entity, required_fragment)
            assert(required_component == 42)
        end
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
        evo.collect_garbage(math.random(1, 2) == 1)
    end
    evo.destroy(__table_unpack(all_fragment_list))
else
    evo.destroy(__table_unpack(all_fragment_list))
    if math.random(1, 2) == 1 then
        evo.collect_garbage(math.random(1, 2) == 1)
    end
    evo.destroy(__table_unpack(all_entity_list))
end

if math.random(1, 2) == 1 then
    evo.collect_garbage(math.random(1, 2) == 1)
end
