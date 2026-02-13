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
        evo.set(entity, evo.UNIQUE)
    end
end

---
---
---
---
---

for _, entity in ipairs(all_entity_list) do
    local entity_clone = evo.clone(entity)

    for fragment in evo.each(entity_clone) do
        assert(not evo.has(fragment, evo.UNIQUE))
    end

    for fragment in evo.each(entity) do
        assert(evo.has(entity_clone, fragment) or evo.has(fragment, evo.UNIQUE))
    end

    evo.destroy(entity_clone)
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
