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

local remove_hook_calls = {} ---@type table<evolved.entity, table<evolved.fragment, integer>>
local hooked_link_fragment_set = {} ---@type table<evolved.fragment, boolean>

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

local all_link_fragment_list = {} ---@type evolved.fragment[]

for i = 1, math.random(1, 4) do
    local builder = evo.builder():link()

    if math.random(1, 2) == 1 then
        builder:on_remove(remove_hook)
    end

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

    if evo.has(all_link_fragment_list[i], evo.ON_REMOVE) then
        hooked_link_fragment_set[all_link_fragment_list[i]] = true
    end
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

---@return evolved.entity | evolved.entity[]
local function random_link_component()
    if math.random(1, 2) == 1 then
        return random_entity()
    end

    local link_target_list = {}

    for i = 1, math.random(0, 3) do
        link_target_list[i] = random_entity()
    end

    return link_target_list
end

---@param link_component evolved.entity | evolved.entity[]
---@return evolved.entity[]
local function link_component_targets(link_component)
    if type(link_component) == 'table' then
        return link_component
    end

    return { link_component }
end

for _, entity in ipairs(all_entity_list) do
    for _, link_fragment in ipairs(all_link_fragment_list) do
        if math.random(1, 2) == 1 then
            evo.set(entity, link_fragment, random_link_component())
        end
    end
end

for _ = 1, math.random(0, #all_entity_list) do
    local entity = random_entity()
    local link_fragment = all_link_fragment_list[math.random(1, #all_link_fragment_list)]

    local r = math.random(1, 4)

    if r == 1 then
        evo.set(entity, link_fragment, random_link_component())
    elseif r == 2 then
        evo.remove(entity, link_fragment)
    elseif r == 3 then
        evo.remove(link_fragment, evo.LINK)
        evo.set(link_fragment, evo.LINK)
    else
        local link_component = evo.get(entity, link_fragment)

        if type(link_component) == 'table' then
            if math.random(1, 2) == 1 then
                link_component[#link_component + 1] = random_entity()
            else
                link_component[#link_component] = nil
            end

            evo.reindex(link_fragment)
        end
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
                    local link_component = evo.get(entity, link_fragment)

                    if link_component then
                        for _, link_target in ipairs(link_component_targets(link_component)) do
                            if should_be_destroyed_entity_set[link_target] then
                                should_be_destroyed_entity_set[entity] = true
                                has_new_destroyed_entities = true
                                break
                            end
                        end
                    end
                end

                if should_be_destroyed_entity_set[entity] then
                    break
                end
            end
        end
    end
until not has_new_destroyed_entities

local entity_link_target_lists = {} ---@type table<evolved.entity, table<evolved.fragment, evolved.entity[]>>

for _, entity in ipairs(all_entity_list) do
    local entity_link_target_list = {}

    for _, link_fragment in ipairs(all_link_fragment_list) do
        local link_component = evo.get(entity, link_fragment)

        if link_component then
            local link_target_list = {}

            for i, link_target in ipairs(link_component_targets(link_component)) do
                link_target_list[i] = link_target
            end

            entity_link_target_list[link_fragment] = link_target_list
        end
    end

    entity_link_target_lists[entity] = entity_link_target_list
end

remove_hook_calls = {}

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
            local link_component = evo.get(entity, link_fragment)

            if link_component then
                for _, link_target in ipairs(link_component_targets(link_component)) do
                    assert(evo.alive(link_target))
                end
            end
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
            local link_component = evo.get(entity, link_fragment)

            if link_component then
                for _, link_target in ipairs(link_component_targets(link_component)) do
                    local referrer_list, referrer_count = evo.multi_search(link_fragment, link_target)

                    local referrer_found_count = 0

                    for i = 1, referrer_count do
                        if referrer_list[i] == entity then
                            referrer_found_count = referrer_found_count + 1
                        end
                    end

                    assert(referrer_found_count == 1)
                end
            end
        end
    end
end

for _, link_fragment in ipairs(all_link_fragment_list) do
    for _, link_target in ipairs(all_entity_list) do
        if evo.alive(link_target) then
            local referrer_list, referrer_count = evo.multi_search(link_fragment, link_target)

            for i = 1, referrer_count do
                local referrer = referrer_list[i]
                local referrer_component = evo.get(referrer, link_fragment)

                local is_target_found = false

                if referrer_component then
                    for _, referrer_target in ipairs(link_component_targets(referrer_component)) do
                        if referrer_target == link_target then
                            is_target_found = true
                            break
                        end
                    end
                end

                assert(is_target_found)
            end
        end
    end
end

for _, entity in ipairs(all_entity_list) do
    local entity_calls = remove_hook_calls[entity] or {}

    for link_fragment, link_target_list in pairs(entity_link_target_lists[entity]) do
        local expected_call_count = 0

        if hooked_link_fragment_set[link_fragment] then
            local is_link_removed = should_be_destroyed_entity_set[entity]

            for _, link_target in ipairs(link_target_list) do
                if should_be_destroyed_entity_set[link_target] then
                    is_link_removed = true
                end
            end

            if is_link_removed then
                expected_call_count = 1
            end
        end

        assert((entity_calls[link_fragment] or 0) == expected_call_count)
    end

    for link_fragment in pairs(entity_calls) do
        assert(entity_link_target_lists[entity][link_fragment])
    end
end

for entity in pairs(remove_hook_calls) do
    assert(entity_link_target_lists[entity])
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
