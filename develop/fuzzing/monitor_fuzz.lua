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

-- entities created before and during monitor setup can leave monitors without
-- entering them first, because monitors do not emit ENTER for existing entities
local setup_entity_set = {} ---@type table<evolved.entity, boolean>

local HIT = evo.id()
setup_entity_set[HIT] = true

local alive_fragment_list = {} ---@type evolved.fragment[]

for i = 1, math.random(2, 8) do
    local fragment = evo.id()
    alive_fragment_list[i] = fragment
    setup_entity_set[fragment] = true
end

for _, fragment in ipairs(alive_fragment_list) do
    if math.random(1, 4) == 1 then
        local require = alive_fragment_list[math.random(1, #alive_fragment_list)]

        if require ~= fragment then
            evo.set(fragment, evo.REQUIRES, { require })
        end
    end

    if math.random(1, 4) == 1 then
        evo.set(fragment, evo.DESTRUCTION_POLICY, evo.DESTRUCTION_POLICY_DESTROY_ENTITY)
    end
end

---@return evolved.fragment
local function random_fragment()
    return alive_fragment_list[math.random(1, #alive_fragment_list)]
end

---@param min_count integer
---@return evolved.fragment[]
local function random_fragment_list(min_count)
    local fragment_set = {} ---@type table<evolved.fragment, boolean>
    local fragment_list = {} ---@type evolved.fragment[]

    for _ = 1, math.random(min_count, #alive_fragment_list) do
        local fragment = random_fragment()

        if not fragment_set[fragment] then
            fragment_set[fragment] = true
            fragment_list[#fragment_list + 1] = fragment
        end
    end

    return fragment_list
end

---@return evolved.component_table
local function random_component_table()
    local component_table = {} ---@type evolved.component_table

    for _, fragment in ipairs(random_fragment_list(0)) do
        component_table[fragment] = true
    end

    return component_table
end

---@param query evolved.query
---@param with_includes boolean
local function generate_query(query, with_includes)
    local include_list = random_fragment_list(with_includes and 1 or 0)
    local exclude_list = random_fragment_list(0)
    local variant_list = random_fragment_list(0)

    if #include_list > 0 and (with_includes or math.random(1, 4) ~= 1) then
        evo.set(query, evo.INCLUDES, include_list)
    end

    if #exclude_list > 0 and math.random(1, 2) == 1 then
        evo.set(query, evo.EXCLUDES, exclude_list)
    end

    if #variant_list > 0 and math.random(1, 3) == 1 then
        evo.set(query, evo.VARIANTS, variant_list)
    end
end

---
---
---
---
---

local monitor_list = {} ---@type evolved.system[]
local monitor_inside_sets = {} ---@type table<evolved.system, table<evolved.entity, boolean>>
local monitor_observe_hits = {} ---@type table<evolved.system, boolean>

---@type table<evolved.system, table<evolved.entity, integer>>
local monitor_received_hits = {}

for i = 1, math.random(1, 6) do
    local monitor = evo.id()
    setup_entity_set[monitor] = true

    local inside_set = {} ---@type table<evolved.entity, boolean>
    local received_hits = {} ---@type table<evolved.entity, integer>

    monitor_list[i] = monitor
    monitor_inside_sets[monitor] = inside_set
    monitor_received_hits[monitor] = received_hits
    monitor_observe_hits[monitor] = math.random(1, 3) ~= 1

    if math.random(1, 3) == 1 then
        local query = evo.id()
        setup_entity_set[query] = true
        generate_query(query, false)
        evo.set(monitor, evo.QUERY, query)
    else
        generate_query(monitor, false)
    end

    if monitor_observe_hits[monitor] then
        evo.set(monitor, evo.OBSERVES, { evo.ENTER, evo.LEAVE, HIT })
    else
        evo.set(monitor, evo.OBSERVES, { evo.ENTER, evo.LEAVE })
    end

    evo.set(monitor, evo.CALLBACK, function(event, entity, payload)
        if setup_entity_set[entity] then
            assert(event == evo.ENTER or event == evo.LEAVE)
        elseif event == evo.ENTER then
            assert(not inside_set[entity])
            inside_set[entity] = true
        elseif event == evo.LEAVE then
            assert(inside_set[entity])
            inside_set[entity] = nil
        elseif event == HIT then
            assert(monitor_observe_hits[monitor])
            assert(inside_set[entity])
            assert(payload == entity)
            received_hits[entity] = (received_hits[entity] or 0) + 1
        else
            assert(false, 'unexpected event')
        end
    end)
end

---
---
---
---
---

local tracked_entity_set = {} ---@type table<evolved.entity, boolean>
local tracked_entity_list = {} ---@type evolved.entity[]

---@param entity evolved.entity
local function track_entity(entity)
    if not tracked_entity_set[entity] then
        tracked_entity_set[entity] = true
        tracked_entity_list[#tracked_entity_list + 1] = entity
    end
end

---@return evolved.entity?
local function random_alive_entity()
    local alive_entity_list = {} ---@type evolved.entity[]

    for _, entity in ipairs(tracked_entity_list) do
        if evo.alive(entity) then
            alive_entity_list[#alive_entity_list + 1] = entity
        end
    end

    if #alive_entity_list > 0 then
        return alive_entity_list[math.random(1, #alive_entity_list)]
    end
end

local function check_monitors()
    assert(evo.depth() == 0)

    for _, monitor in ipairs(monitor_list) do
        local inside_set = monitor_inside_sets[monitor]
        local expected_set = {} ---@type table<evolved.entity, boolean>

        for _, entity_list, entity_count in evo.execute(evo.get(monitor, evo.QUERY) or monitor) do
            for entity_index = 1, entity_count do
                local entity = entity_list[entity_index]

                if tracked_entity_set[entity] then
                    expected_set[entity] = true
                end
            end
        end

        for entity in pairs(expected_set) do
            assert(inside_set[entity])
        end

        for entity in pairs(inside_set) do
            assert(evo.alive(entity))

            if tracked_entity_set[entity] then
                assert(expected_set[entity])
            end
        end
    end
end

---
---
---
---
---

---@param no_destroy boolean
---@return boolean destroyed
local function random_operation(no_destroy)
    local operation = math.random(1, no_destroy and 3 or 15)

    if operation == 1 then
        track_entity(evo.spawn(random_component_table()))
    elseif operation == 2 then
        local entity_list = evo.multi_spawn(math.random(1, 4), random_component_table())

        for _, entity in ipairs(entity_list) do
            track_entity(entity)
        end
    elseif operation == 3 then
        local entity = random_alive_entity()

        if entity then
            evo.emit(HIT, entity, entity)
        end
    elseif operation == 4 then
        local prefab = random_alive_entity()

        if prefab then
            track_entity(evo.clone(prefab, random_component_table()))
        end
    elseif operation == 5 then
        local prefab = random_alive_entity()

        if prefab then
            local entity_list = evo.multi_clone(math.random(1, 4), prefab, random_component_table())

            for _, entity in ipairs(entity_list) do
                track_entity(entity)
            end
        end
    elseif operation == 6 or operation == 7 then
        local entity = random_alive_entity()

        if entity then
            evo.set(entity, random_fragment())
        end
    elseif operation == 8 then
        local entity = random_alive_entity()

        if entity then
            evo.remove(entity, __table_unpack(random_fragment_list(1)))
        end
    elseif operation == 9 then
        local query = evo.id()
        generate_query(query, true)
        evo.batch_set(query, random_fragment())
        evo.destroy(query)
    elseif operation == 10 then
        local query = evo.id()
        generate_query(query, true)
        evo.batch_remove(query, __table_unpack(random_fragment_list(1)))
        evo.destroy(query)
    elseif operation == 11 then
        local entity = random_alive_entity()

        if entity then
            evo.clear(entity)
        end
    elseif operation == 12 then
        local query = evo.id()
        generate_query(query, true)
        evo.batch_clear(query)
        evo.destroy(query)
    elseif operation == 13 then
        local entity = random_alive_entity()

        if entity then
            evo.destroy(entity)
            return true
        end
    elseif operation == 14 then
        local query = evo.id()
        generate_query(query, true)
        evo.batch_destroy(query)
        evo.destroy(query)
        return true
    elseif operation == 15 then
        if #alive_fragment_list > 1 then
            local fragment_index = math.random(1, #alive_fragment_list)
            local fragment = table.remove(alive_fragment_list, fragment_index)

            for _, other_fragment in ipairs(alive_fragment_list) do
                local require_list = evo.get(other_fragment, evo.REQUIRES)

                if require_list and require_list[1] == fragment then
                    evo.remove(other_fragment, evo.REQUIRES)
                end
            end

            evo.destroy(fragment)
            return true
        end
    end

    return false
end

for _ = 1, math.random(20, 80) do
    if math.random(1, 4) == 1 then
        evo.defer()

        local destroyed = false

        for _ = 1, math.random(1, 10) do
            if random_operation(destroyed) then
                destroyed = true
            end
        end

        evo.commit()
    else
        random_operation(false)
    end

    if math.random(1, 10) == 1 then
        evo.collect_garbage(math.random(1, 2) == 1)
    end

    check_monitors()

    do
        local entity = random_alive_entity()

        if entity then
            for _, monitor in ipairs(monitor_list) do
                monitor_received_hits[monitor][entity] = nil
            end

            evo.emit(HIT, entity, entity)

            for _, monitor in ipairs(monitor_list) do
                local expected_hits = monitor_observe_hits[monitor]
                    and monitor_inside_sets[monitor][entity] and 1 or nil

                assert(monitor_received_hits[monitor][entity] == expected_hits)
            end
        end
    end
end

---
---
---
---
---

evo.destroy(__table_unpack(tracked_entity_list))

check_monitors()

for _, monitor in ipairs(monitor_list) do
    for entity in pairs(monitor_inside_sets[monitor]) do
        assert(not tracked_entity_set[entity])
    end
end

evo.destroy(__table_unpack(monitor_list))
evo.destroy(__table_unpack(alive_fragment_list))

if math.random(1, 2) == 1 then
    evo.collect_garbage(math.random(1, 2) == 1)
end
