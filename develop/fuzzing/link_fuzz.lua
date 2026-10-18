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

local destroying_mark = evo.builder():tag():build()
local destroying_query = evo.builder():include(destroying_mark):build()

local all_link_fragment_list = {} ---@type evolved.fragment[]

for i = 1, math.random(1, 4) do
    local builder = evo.builder():link()

    local r = math.random(1, 3)

    if r == 1 then
        builder:link_policy(evo.LINK_POLICY_DESTROY_ENTITY)
    elseif r == 2 then
        builder:link_policy(evo.LINK_POLICY_REMOVE_FRAGMENT)
    end

    if math.random(1, 2) == 1 then
        builder:index()
    end

    all_link_fragment_list[i] = builder:build()
end

local all_entity_list = {} ---@type evolved.entity[]

for i = 1, math.random(1, 20) do
    local entity = evo.id()
    all_entity_list[i] = entity
end

---
---
---
---
---

local function random_entity()
    return all_entity_list[math.random(1, #all_entity_list)]
end

for _, entity in ipairs(all_entity_list) do
    for _, link_fragment in ipairs(all_link_fragment_list) do
        if math.random(1, 2) == 1 then
            evo.set(entity, link_fragment, random_entity())
        end
    end
end

for _ = 1, math.random(0, #all_entity_list) do
    local entity = random_entity()
    local link_fragment = all_link_fragment_list[math.random(1, #all_link_fragment_list)]

    local r = math.random(1, 3)

    if r == 1 then
        evo.set(entity, link_fragment, random_entity())
    elseif r == 2 then
        evo.remove(entity, link_fragment)
    else
        evo.remove(link_fragment, evo.LINK)
        evo.set(link_fragment, evo.LINK)
    end
end

for _, link_fragment in ipairs(all_link_fragment_list) do
    if math.random(1, 4) == 1 then
        if evo.has(link_fragment, evo.INDEX) then
            evo.remove(link_fragment, evo.INDEX)
        else
            evo.set(link_fragment, evo.INDEX)
        end
    end
end

---
---
---
---
---

local should_be_destroyed_entity_set = {} ---@type table<evolved.entity, boolean>

local destroying_entity_list = {} ---@type evolved.entity[]

for i = 1, math.random(1, #all_entity_list) do
    local destroying_entity = random_entity()
    destroying_entity_list[i] = destroying_entity
    should_be_destroyed_entity_set[destroying_entity] = true
end

repeat
    local has_new_destroyed_entities = false

    for _, entity in ipairs(all_entity_list) do
        if not should_be_destroyed_entity_set[entity] then
            for _, link_fragment in ipairs(all_link_fragment_list) do
                local link_policy = evo.get(link_fragment, evo.LINK_POLICY)
                    or evo.LINK_POLICY_REMOVE_FRAGMENT

                if link_policy == evo.LINK_POLICY_DESTROY_ENTITY then
                    local link_target = evo.get(entity, link_fragment)

                    if link_target and should_be_destroyed_entity_set[link_target] then
                        should_be_destroyed_entity_set[entity] = true
                        has_new_destroyed_entities = true
                        break
                    end
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
    local r = math.random(1, 6)

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
    elseif r == 5 then
        for _, destroying_entity in ipairs(destroying_entity_list) do
            evo.set(destroying_entity, destroying_mark)
        end
        evo.batch_destroy(destroying_query)
    elseif r == 6 then
        for _, destroying_entity in ipairs(destroying_entity_list) do
            evo.set(destroying_entity, destroying_mark)
        end
        assert(evo.defer())
        evo.batch_destroy(destroying_query)
        assert(evo.commit())
    end
end

---
---
---
---
---

for _, entity in ipairs(all_entity_list) do
    assert(evo.alive(entity) == not should_be_destroyed_entity_set[entity])
end

for _, entity in ipairs(all_entity_list) do
    if evo.alive(entity) then
        for _, link_fragment in ipairs(all_link_fragment_list) do
            local link_target = evo.get(entity, link_fragment)
            assert(link_target == nil or evo.alive(link_target))
        end
    end
end

for _, entity in ipairs(all_entity_list) do
    if not evo.alive(entity) then
        for _, link_fragment in ipairs(all_link_fragment_list) do
            assert(evo.search(link_fragment, entity) == nil)
        end
    end
end

for _, link_fragment in ipairs(all_link_fragment_list) do
    for _, entity in ipairs(all_entity_list) do
        if evo.alive(entity) then
            local link_target = evo.get(entity, link_fragment)

            if link_target then
                local referrer_list, referrer_count = evo.multi_search(link_fragment, link_target)

                local is_referrer_found = false

                for i = 1, referrer_count do
                    if referrer_list[i] == entity then
                        is_referrer_found = true
                        break
                    end
                end

                assert(is_referrer_found)
            end
        end
    end
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
evo.destroy(__table_unpack(all_link_fragment_list))
evo.destroy(destroying_query, destroying_mark)

if math.random(1, 2) == 1 then
    evo.collect_garbage(math.random(1, 2) == 1)
end
