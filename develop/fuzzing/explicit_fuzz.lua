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
        evo.set(entity, evo.EXPLICIT)
    end
end

---
---
---
---
---

for _ = 1, 100 do
    local include_set = {} ---@type table<evolved.entity, integer>
    local include_list = {} ---@type evolved.entity[]
    local include_count = 0

    for _ = 1, math.random(1, #all_entity_list) do
        local include = all_entity_list[math.random(1, #all_entity_list)]

        if not include_set[include] then
            include_count = include_count + 1
            include_set[include] = include_count
            include_list[include_count] = include
        end
    end

    local q = evo.builder():include(__table_unpack(include_list)):spawn()

    for chunk in evo.execute(q) do
        local fragment_list, fragment_count = chunk:fragments()
        for i = 1, fragment_count do
            local fragment = fragment_list[i]
            assert(include_set[fragment] or not evo.has(fragment, evo.EXPLICIT))
        end
    end

    evo.destroy(q)
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
