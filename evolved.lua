local evolved = {
    __HOMEPAGE = 'https://github.com/BlackMATov/evolved.lua',
    __DESCRIPTION = 'Evolved Entity-Component-System for Lua',
    __VERSION = '0.0.1',
    __LICENSE = [[
        MIT License

        Copyright (C) 2024, by Matvey Cherevko (blackmatov@gmail.com)

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    ]]
}

---@alias evolved.id integer
---@alias evolved.query evolved.id
---@alias evolved.entity evolved.id
---@alias evolved.fragment evolved.id
---@alias evolved.component any

---@class (exact) evolved.chunk
---@field package __parent? evolved.chunk
---@field package __children evolved.chunk[]
---@field package __fragment evolved.fragment
---@field package __entities evolved.entity[]
---@field package __fragments table<evolved.fragment, boolean>
---@field package __components table<evolved.fragment, evolved.component[]>
---@field package __with_fragment_edges table<evolved.fragment, evolved.chunk>
---@field package __without_fragment_edges table<evolved.fragment, evolved.chunk>

---@class (exact) evolved.each_state
---@field [1] integer structural_changes
---@field [2] evolved.chunk entity_chunk
---@field [3] integer entity_place
---@field [4] evolved.fragment? fragments_index

---@class (exact) evolved.execute_state
---@field [1] integer structural_changes
---@field [2] evolved.chunk[] chunk_stack
---@field [3] table<evolved.fragment, boolean> exclude_set

---@alias evolved.each_iterator fun(state: evolved.each_state?): evolved.fragment?, evolved.component?
---@alias evolved.execute_iterator fun(state: evolved.execute_state?): evolved.chunk?, evolved.entity[]?

---
---
---
---
---

local __freelist_ids = {} ---@type evolved.id[]
local __available_idx = 0 ---@type integer

local __defer_depth = 0 ---@type integer
local __defer_length = 0 ---@type integer
local __defer_bytecode = {} ---@type any[]

local __root_chunks = {} ---@type table<evolved.fragment, evolved.chunk>
local __major_chunks = {} ---@type table<evolved.fragment, evolved.chunk[]>

local __entity_chunks = {} ---@type table<integer, evolved.chunk>
local __entity_places = {} ---@type table<integer, integer>

local __chunk_lists = {} ---@type evolved.chunk[][]
local __fragment_lists = {} ---@type evolved.fragment[][]

local __each_states = {} ---@type evolved.each_state[]
local __execute_states = {} ---@type evolved.execute_state[]

local __structural_changes = 0 ---@type integer

---
---
---
---
---

---@diagnostic disable-next-line
local __table_move = table.move or function(a1, f, e, t, a2)
    if a2 == nil then
        a2 = a1
    end

    if e < f then
        return a2
    end

    local d = t - f

    if t > e or t <= f or a2 ~= a1 then
        for i = f, e do a2[i + d] = a1[i] end
    else
        for i = e, f, -1 do a2[i + d] = a1[i] end
    end

    return a2
end

---@diagnostic disable-next-line
local __table_unpack = table.unpack or unpack

---
---
---
---
---

---@param index integer
---@param version integer
---@return evolved.id
---@nodiscard
local function __pack_id(index, version)
    assert(index >= 1 and index <= 0xFFFFF, 'id index out of range [1;0xFFFFF]')
    assert(version >= 1 and version <= 0x7FF, 'id version out of range [1;0x7FF]')
    return index + version * 0x100000
end

---@param id evolved.id
---@return integer index
---@return integer version
---@nodiscard
local function __unpack_id(id)
    local index = id % 0x100000
    local version = (id - index) / 0x100000
    return index, version
end

---
---
---
---
---

---@return evolved.id
---@nodiscard
local function __acquire_id()
    if __available_idx ~= 0 then
        local index = __available_idx
        local freelist_id = __freelist_ids[index]
        __available_idx = freelist_id % 0x100000
        local version = freelist_id - __available_idx

        local acquired_id = index + version
        __freelist_ids[index] = acquired_id
        return acquired_id
    else
        if #__freelist_ids == 0xFFFFF then
            error('id index overflow', 2)
        end

        local index = #__freelist_ids + 1
        local version = 0x100000

        local acquired_id = index + version
        __freelist_ids[index] = acquired_id
        return acquired_id
    end
end

---@param id evolved.id
---@return boolean
---@nodiscard
local function __is_id_alive(id)
    local index = id % 0x100000
    return __freelist_ids[index] == id
end

---@param id evolved.id
local function __release_id(id)
    local index = id % 0x100000
    local version = id - index

    if __freelist_ids[index] ~= id then
        error('id is not acquired or already released', 2)
    end

    version = version == 0x7FF00000
        and 0x100000
        or version + 0x100000

    __freelist_ids[index] = __available_idx + version
    __available_idx = index
end

---
---
---
---
---

---@return evolved.chunk[]
---@nodiscard
local function __acquire_chunk_list()
    local chunk_list_count = #__chunk_lists

    if chunk_list_count == 0 then
        return {}
    end

    local list = __chunk_lists[chunk_list_count]
    __chunk_lists[chunk_list_count] = nil

    return list
end

---@param list evolved.chunk[]
local function __release_chunk_list(list)
    for i = #list, 1, -1 do list[i] = nil end
    __chunk_lists[#__chunk_lists + 1] = list
end

---
---
---
---
---

---@return evolved.fragment[]
---@nodiscard
local function __acquire_fragment_list()
    local fragment_list_count = #__fragment_lists

    if fragment_list_count == 0 then
        return {}
    end

    local list = __fragment_lists[fragment_list_count]
    __fragment_lists[fragment_list_count] = nil

    return list
end

---@param list evolved.fragment[]
local function __release_fragment_list(list)
    for i = #list, 1, -1 do list[i] = nil end
    __fragment_lists[#__fragment_lists + 1] = list
end

---
---
---
---
---

---@param chunk evolved.chunk
---@param place integer
---@return evolved.each_state
---@nodiscard
local function __acquire_each_state(chunk, place)
    local each_state_count = #__each_states

    if each_state_count == 0 then
        ---@type evolved.each_state
        return { __structural_changes, chunk, place }
    end

    local state = __each_states[each_state_count]
    __each_states[each_state_count] = nil

    state[1], state[2], state[3] =
        __structural_changes, chunk, place

    return state
end

---@param state evolved.each_state
local function __release_each_state(state)
    for i = #state, 1, -1 do state[i] = nil end
    __each_states[#__each_states + 1] = state
end

---@type evolved.each_iterator
local function __each_iterator(state)
    if not state then return end

    local structural_changes, chunk, place, fragment =
        state[1], state[2], state[3], state[4]

    if structural_changes ~= __structural_changes then
        error('structural changes are prohibited during iteration', 2)
    end

    fragment = next(chunk.__fragments, fragment)

    if fragment then
        state[4] = fragment
        local fragment_components = chunk.__components[fragment]
        return fragment, fragment_components and fragment_components[place]
    end

    __release_each_state(state)
end

---
---
---
---
---

---@param exclude_set table<evolved.fragment, boolean>
---@return evolved.execute_state
---@nodiscard
local function __acquire_execute_state(exclude_set)
    local execute_state_count = #__execute_states

    if execute_state_count == 0 then
        ---@type evolved.execute_state
        return { __structural_changes, __acquire_chunk_list(), exclude_set }
    end

    local state = __execute_states[execute_state_count]
    __execute_states[execute_state_count] = nil

    state[1], state[2], state[3] =
        __structural_changes, __acquire_chunk_list(), exclude_set

    return state
end

---@param state evolved.execute_state
local function __release_execute_state(state)
    __release_chunk_list(state[2]);
    for i = #state, 1, -1 do state[i] = nil end
    __execute_states[#__execute_states + 1] = state
end

---@type evolved.execute_iterator
local function __execute_iterator(state)
    if not state then return end

    local structural_changes, chunk_stack, exclude_set =
        state[1], state[2], state[3]

    if structural_changes ~= __structural_changes then
        error('structural changes are prohibited during iteration', 2)
    end

    while #chunk_stack > 0 do
        local chunk = chunk_stack[#chunk_stack]
        chunk_stack[#chunk_stack] = nil

        for _, chunk_child in ipairs(chunk.__children) do
            if not exclude_set[chunk_child.__fragment] then
                chunk_stack[#chunk_stack + 1] = chunk_child
            end
        end

        if #chunk.__entities > 0 then
            return chunk, chunk.__entities
        end
    end

    __release_execute_state(state)
end

---
---
---
---
---

evolved.TAG = __acquire_id()
evolved.DEFAULT = __acquire_id()
evolved.CONSTRUCT = __acquire_id()

evolved.ON_SET = __acquire_id()
evolved.ON_ASSIGN = __acquire_id()
evolved.ON_INSERT = __acquire_id()
evolved.ON_REMOVE = __acquire_id()

evolved.INCLUDE_LIST = __acquire_id()
evolved.EXCLUDE_LIST = __acquire_id()

---
---
---
---
---

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
---@return evolved.component
local function __component_construct(entity, fragment, ...)
    local default, construct = evolved.get(fragment, evolved.DEFAULT, evolved.CONSTRUCT)

    local component = ...

    if construct ~= nil then
        component = construct(entity, fragment, ...)
    end

    if component == nil then
        component = default
    end

    return component == nil and true or component
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param new_component evolved.component
---@param old_component evolved.component
local function __fragment_on_set_and_assign(entity, fragment, new_component, old_component)
    local on_set, on_assign = evolved.get(fragment, evolved.ON_SET, evolved.ON_ASSIGN)
    if on_set then on_set(entity, fragment, new_component, old_component) end
    if on_assign then on_assign(entity, fragment, new_component, old_component) end
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param new_component evolved.component
local function __fragment_on_set_and_insert(entity, fragment, new_component)
    local on_set, on_insert = evolved.get(fragment, evolved.ON_SET, evolved.ON_INSERT)
    if on_set then on_set(entity, fragment, new_component) end
    if on_insert then on_insert(entity, fragment, new_component) end
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param old_component evolved.component
local function __fragment_on_remove(entity, fragment, old_component)
    local on_remove = evolved.get(fragment, evolved.ON_REMOVE)
    if on_remove then on_remove(entity, fragment, old_component) end
end

---@param fragment evolved.fragment
---@return boolean
---@nodiscard
local function __fragment_has_default_or_construct(fragment)
    return evolved.has_any(fragment, evolved.DEFAULT, evolved.CONSTRUCT)
end

---@param fragment evolved.fragment
---@return boolean
---@nodiscard
local function __fragment_has_on_set_or_assign(fragment)
    return evolved.has_any(fragment, evolved.ON_SET, evolved.ON_ASSIGN)
end

---@param fragment evolved.fragment
---@return boolean
---@nodiscard
local function __fragment_has_on_set_or_insert(fragment)
    return evolved.has_any(fragment, evolved.ON_SET, evolved.ON_INSERT)
end

---@param fragment evolved.fragment
---@return boolean
---@nodiscard
local function __fragment_has_on_remove(fragment)
    return evolved.has(fragment, evolved.ON_REMOVE)
end

---
---
---
---
---

---@param fragment evolved.fragment
---@return evolved.chunk
---@nodiscard
local function __root_chunk(fragment)
    do
        local root_chunk = __root_chunks[fragment]
        if root_chunk then return root_chunk end
    end

    ---@type evolved.chunk
    local root_chunk = {
        __parent = nil,
        __children = {},
        __fragment = fragment,
        __entities = {},
        __fragments = {},
        __components = {},
        __with_fragment_edges = {},
        __without_fragment_edges = {},
    }

    do
        root_chunk.__fragments[fragment] = true

        if not evolved.has(fragment, evolved.TAG) then
            root_chunk.__components[fragment] = {}
        end
    end

    do
        __root_chunks[fragment] = root_chunk
    end

    do
        local fragment_chunks = __major_chunks[fragment]

        if not fragment_chunks then
            fragment_chunks = {}
            __major_chunks[fragment] = fragment_chunks
        end

        fragment_chunks[#fragment_chunks + 1] = root_chunk
    end

    __structural_changes = __structural_changes + 1
    return root_chunk
end

---@param chunk? evolved.chunk
---@param fragment evolved.fragment
---@return evolved.chunk
---@nodiscard
local function __chunk_with_fragment(chunk, fragment)
    if not chunk then
        return __root_chunk(fragment)
    end

    if chunk.__fragments[fragment] then
        return chunk
    end

    do
        local with_fragment_chunk = chunk.__with_fragment_edges[fragment]
        if with_fragment_chunk then return with_fragment_chunk end
    end

    if fragment == chunk.__fragment then
        return chunk
    end

    if fragment < chunk.__fragment then
        local sibling_chunk = __chunk_with_fragment(
            __chunk_with_fragment(chunk.__parent, fragment),
            chunk.__fragment)

        chunk.__with_fragment_edges[fragment] = sibling_chunk
        sibling_chunk.__without_fragment_edges[fragment] = chunk

        return sibling_chunk
    end

    ---@type evolved.chunk
    local child_chunk = {
        __parent = chunk,
        __children = {},
        __fragment = fragment,
        __entities = {},
        __fragments = {},
        __components = {},
        __with_fragment_edges = {},
        __without_fragment_edges = {},
    }

    do
        child_chunk.__fragments[fragment] = true

        if not evolved.has(fragment, evolved.TAG) then
            child_chunk.__components[fragment] = {}
        end
    end

    for parent_fragment, _ in pairs(chunk.__fragments) do
        child_chunk.__fragments[parent_fragment] = true

        if not evolved.has(parent_fragment, evolved.TAG) then
            child_chunk.__components[parent_fragment] = {}
        end
    end

    do
        local chunk_children = chunk.__children
        chunk_children[#chunk_children + 1] = child_chunk
    end

    do
        chunk.__with_fragment_edges[fragment] = child_chunk
        child_chunk.__without_fragment_edges[fragment] = chunk
    end

    do
        local fragment_chunks = __major_chunks[fragment]

        if not fragment_chunks then
            fragment_chunks = {}
            __major_chunks[fragment] = fragment_chunks
        end

        fragment_chunks[#fragment_chunks + 1] = child_chunk
    end

    __structural_changes = __structural_changes + 1
    return child_chunk
end

---@param chunk? evolved.chunk
---@param fragment evolved.fragment
---@return evolved.chunk?
---@nodiscard
local function __chunk_without_fragment(chunk, fragment)
    if not chunk then
        return nil
    end

    if not chunk.__fragments[fragment] then
        return chunk
    end

    do
        local without_fragment_edge = chunk.__without_fragment_edges[fragment]
        if without_fragment_edge then return without_fragment_edge end
    end

    if fragment == chunk.__fragment then
        return chunk.__parent
    end

    if fragment < chunk.__fragment then
        local sibling_chunk = __chunk_with_fragment(
            __chunk_without_fragment(chunk.__parent, fragment),
            chunk.__fragment)

        chunk.__without_fragment_edges[fragment] = sibling_chunk
        sibling_chunk.__with_fragment_edges[fragment] = chunk

        return sibling_chunk
    end

    return chunk
end

---@param chunk? evolved.chunk
---@param ... evolved.fragment fragments
---@return evolved.chunk?
---@nodiscard
local function __chunk_without_fragments(chunk, ...)
    local fragment_count = select('#', ...)

    if fragment_count == 0 then
        return chunk
    end

    for i = 1, fragment_count do
        chunk = __chunk_without_fragment(chunk, select(i, ...))
    end

    return chunk
end

---
---
---
---
---

---@param chunk evolved.chunk
---@param fragment evolved.fragment
---@return boolean
---@nodiscard
local function __chunk_has_fragment(chunk, fragment)
    return chunk.__fragments[fragment]
end

---@param chunk evolved.chunk
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
local function __chunk_has_all_fragments(chunk, ...)
    local fragments = chunk.__fragments

    for i = 1, select('#', ...) do
        if not fragments[select(i, ...)] then
            return false
        end
    end

    return true
end

---@param chunk evolved.chunk
---@param fragment_list evolved.fragment[]
---@return boolean
---@nodiscard
local function __chunk_has_all_fragment_list(chunk, fragment_list)
    local fragments = chunk.__fragments

    for i = 1, #fragment_list do
        if not fragments[fragment_list[i]] then
            return false
        end
    end

    return true
end

---@param chunk evolved.chunk
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
local function __chunk_has_any_fragments(chunk, ...)
    local fragments = chunk.__fragments

    for i = 1, select('#', ...) do
        if fragments[select(i, ...)] then
            return true
        end
    end

    return false
end

---@param chunk evolved.chunk
---@param fragment_list evolved.fragment[]
---@return boolean
---@nodiscard
local function __chunk_has_any_fragment_list(chunk, fragment_list)
    local fragments = chunk.__fragments

    for i = 1, #fragment_list do
        if fragments[fragment_list[i]] then
            return true
        end
    end

    return false
end

---@param chunk evolved.chunk
---@param place integer
---@param ... evolved.fragment fragments
---@return evolved.component ... components
---@nodiscard
local function __chunk_get_components(chunk, place, ...)
    local fragment_count = select('#', ...)

    if fragment_count == 0 then
        return
    end

    local components = chunk.__components

    if fragment_count == 1 then
        local f1 = ...
        local cs1 = components[f1]
        return cs1 and cs1[place]
    end

    if fragment_count == 2 then
        local f1, f2 = ...
        local cs1, cs2 = components[f1], components[f2]
        return cs1 and cs1[place], cs2 and cs2[place]
    end

    if fragment_count == 3 then
        local f1, f2, f3 = ...
        local cs1, cs2, cs3 = components[f1], components[f2], components[f3]
        return cs1 and cs1[place], cs2 and cs2[place], cs3 and cs3[place]
    end

    do
        local f1, f2, f3 = ...
        local cs1, cs2, cs3 = components[f1], components[f2], components[f3]
        return cs1 and cs1[place], cs2 and cs2[place], cs3 and cs3[place],
            __chunk_get_components(chunk, place, select(4, ...))
    end
end

---
---
---
---
---

---@param chunk evolved.chunk
---@param fragment evolved.fragment
---@param ... any component arguments
---@return integer assigned_count
---@nodiscard
local function __chunk_assign(chunk, fragment, ...)
    assert(__defer_depth > 0, 'batched chunk operations should be deferred')

    local chunk_entities = chunk.__entities
    local chunk_fragments = chunk.__fragments
    local chunk_components = chunk.__components

    if not chunk_fragments[fragment] then
        return 0
    end

    local chunk_size = #chunk_entities
    local chunk_fragment_components = chunk_components[fragment]

    if __fragment_has_on_set_or_assign(fragment) then
        if chunk_fragment_components then
            if __fragment_has_default_or_construct(fragment) then
                for place = 1, chunk_size do
                    local entity = chunk_entities[place]
                    local old_component = chunk_fragment_components[place]
                    local new_component = __component_construct(entity, fragment, ...)
                    chunk_fragment_components[place] = new_component
                    __fragment_on_set_and_assign(entity, fragment, new_component, old_component)
                end
            else
                local new_component = ...

                if new_component == nil then
                    new_component = true
                end

                for place = 1, chunk_size do
                    local entity = chunk_entities[place]
                    local old_component = chunk_fragment_components[place]
                    chunk_fragment_components[place] = new_component
                    __fragment_on_set_and_assign(entity, fragment, new_component, old_component)
                end
            end
        else
            for place = 1, chunk_size do
                local entity = chunk_entities[place]
                __fragment_on_set_and_assign(entity, fragment)
            end
        end
    else
        if chunk_fragment_components then
            if __fragment_has_default_or_construct(fragment) then
                for place = 1, chunk_size do
                    local entity = chunk_entities[place]
                    local new_component = __component_construct(entity, fragment, ...)
                    chunk_fragment_components[place] = new_component
                end
            else
                local new_component = ...

                if new_component == nil then
                    new_component = true
                end

                for place = 1, chunk_size do
                    chunk_fragment_components[place] = new_component
                end
            end
        else
            -- nothing
        end
    end

    return chunk_size
end

---@param chunk evolved.chunk
---@param fragment evolved.fragment
---@param ... any component arguments
---@return integer inserted_count
---@nodiscard
local function __chunk_insert(chunk, fragment, ...)
    assert(__defer_depth > 0, 'batched chunk operations should be deferred')

    local old_chunk = chunk
    local new_chunk = __chunk_with_fragment(old_chunk, fragment)

    if old_chunk == new_chunk then
        return 0
    end

    local old_chunk_entities = old_chunk.__entities
    local old_chunk_components = old_chunk.__components

    local new_chunk_entities = new_chunk.__entities
    local new_chunk_components = new_chunk.__components

    local old_chunk_size = #old_chunk_entities
    local new_chunk_size = #new_chunk_entities
    local new_chunk_fragment_components = new_chunk_components[fragment]

    __table_move(
        old_chunk_entities, 1, old_chunk_size,
        new_chunk_size + 1, new_chunk_entities)

    for old_f, old_cs in pairs(old_chunk_components) do
        local new_cs = new_chunk_components[old_f]
        if new_cs then
            __table_move(old_cs, 1, old_chunk_size, new_chunk_size + 1, new_cs)
        end
    end

    if __fragment_has_on_set_or_insert(fragment) then
        if new_chunk_fragment_components then
            if __fragment_has_default_or_construct(fragment) then
                for new_place = new_chunk_size + 1, new_chunk_size + old_chunk_size do
                    local entity = new_chunk_entities[new_place]
                    local new_component = __component_construct(entity, fragment, ...)
                    new_chunk_fragment_components[new_place] = new_component
                    __fragment_on_set_and_insert(entity, fragment, new_component)
                end
            else
                local new_component = ...

                if new_component == nil then
                    new_component = true
                end

                for new_place = new_chunk_size + 1, new_chunk_size + old_chunk_size do
                    local entity = new_chunk_entities[new_place]
                    new_chunk_fragment_components[new_place] = new_component
                    __fragment_on_set_and_insert(entity, fragment, new_component)
                end
            end
        else
            for new_place = new_chunk_size + 1, new_chunk_size + old_chunk_size do
                local entity = new_chunk_entities[new_place]
                __fragment_on_set_and_insert(entity, fragment)
            end
        end
    else
        if new_chunk_fragment_components then
            if __fragment_has_default_or_construct(fragment) then
                for new_place = new_chunk_size + 1, new_chunk_size + old_chunk_size do
                    local entity = new_chunk_entities[new_place]
                    local new_component = __component_construct(entity, fragment, ...)
                    new_chunk_fragment_components[new_place] = new_component
                end
            else
                local new_component = ...

                if new_component == nil then
                    new_component = true
                end

                for new_place = new_chunk_size + 1, new_chunk_size + old_chunk_size do
                    new_chunk_fragment_components[new_place] = new_component
                end
            end
        else
            -- nothing
        end
    end

    for new_place = new_chunk_size + 1, new_chunk_size + old_chunk_size do
        local entity = new_chunk_entities[new_place]
        local index = __unpack_id(entity)
        __entity_chunks[index] = new_chunk
        __entity_places[index] = new_place
    end

    do
        old_chunk.__entities = {}

        for old_f, _ in pairs(old_chunk_components) do
            old_chunk_components[old_f] = {}
        end
    end

    __structural_changes = __structural_changes + old_chunk_size
    return old_chunk_size
end

---@param chunk evolved.chunk
---@param ... evolved.fragment fragments
---@return integer removed_count
---@nodiscard
local function __chunk_remove(chunk, ...)
    assert(__defer_depth > 0, 'batched chunk operations should be deferred')

    local old_chunk = chunk
    local new_chunk = __chunk_without_fragments(chunk, ...)

    if old_chunk == new_chunk then
        return 0
    end

    local old_chunk_entities = old_chunk.__entities
    local old_chunk_fragments = old_chunk.__fragments
    local old_chunk_components = old_chunk.__components

    local old_chunk_size = #old_chunk_entities

    for i = 1, select('#', ...) do
        local fragment = select(i, ...)
        if old_chunk_fragments[fragment] and __fragment_has_on_remove(fragment) then
            local old_chunk_fragment_components = old_chunk_components[fragment]
            if old_chunk_fragment_components then
                for old_place = 1, old_chunk_size do
                    local entity = old_chunk_entities[old_place]
                    local old_component = old_chunk_fragment_components[old_place]
                    __fragment_on_remove(entity, fragment, old_component)
                end
            else
                for old_place = 1, old_chunk_size do
                    local entity = old_chunk_entities[old_place]
                    __fragment_on_remove(entity, fragment)
                end
            end
        end
    end

    if new_chunk then
        local new_chunk_entities = new_chunk.__entities
        local new_chunk_components = new_chunk.__components

        local new_chunk_size = #new_chunk.__entities

        __table_move(
            old_chunk_entities, 1, old_chunk_size,
            new_chunk_size + 1, new_chunk_entities)

        for new_f, new_cs in pairs(new_chunk_components) do
            local old_cs = old_chunk_components[new_f]
            if old_cs then
                __table_move(old_cs, 1, old_chunk_size, new_chunk_size + 1, new_cs)
            end
        end

        for new_place = new_chunk_size + 1, new_chunk_size + old_chunk_size do
            local entity = new_chunk_entities[new_place]
            local index = __unpack_id(entity)
            __entity_chunks[index] = new_chunk
            __entity_places[index] = new_place
        end
    else
        for old_place = 1, old_chunk_size do
            local entity = old_chunk_entities[old_place]
            local index = __unpack_id(entity)
            __entity_chunks[index] = nil
            __entity_places[index] = nil
        end
    end

    do
        old_chunk.__entities = {}

        for old_f, _ in pairs(old_chunk_components) do
            old_chunk_components[old_f] = {}
        end
    end

    __structural_changes = __structural_changes + old_chunk_size
    return old_chunk_size
end

---@param chunk evolved.chunk
---@return integer cleared_count
---@nodiscard
local function __chunk_clear(chunk)
    assert(__defer_depth > 0, 'batched chunk operations should be deferred')

    local chunk_entities = chunk.__entities
    local chunk_fragments = chunk.__fragments
    local chunk_components = chunk.__components

    local chunk_size = #chunk_entities

    for fragment, _ in pairs(chunk_fragments) do
        if __fragment_has_on_remove(fragment) then
            local chunk_fragment_components = chunk_components[fragment]
            if chunk_fragment_components then
                for place = 1, chunk_size do
                    local entity = chunk_entities[place]
                    local old_component = chunk_fragment_components[place]
                    __fragment_on_remove(entity, fragment, old_component)
                end
            else
                for place = 1, chunk_size do
                    local entity = chunk_entities[place]
                    __fragment_on_remove(entity, fragment)
                end
            end
        end
    end

    for place = 1, chunk_size do
        local entity = chunk_entities[place]
        local index = __unpack_id(entity)
        __entity_chunks[index] = nil
        __entity_places[index] = nil
    end

    do
        chunk.__entities = {}

        for f, _ in pairs(chunk_components) do
            chunk_components[f] = {}
        end
    end

    __structural_changes = __structural_changes + chunk_size
    return chunk_size
end

---@param chunk evolved.chunk
---@return integer destroyed_count
---@nodiscard
local function __chunk_destroy(chunk)
    assert(__defer_depth > 0, 'batched chunk operations should be deferred')

    local chunk_entities = chunk.__entities
    local chunk_fragments = chunk.__fragments
    local chunk_components = chunk.__components

    local chunk_size = #chunk_entities

    for fragment, _ in pairs(chunk_fragments) do
        if __fragment_has_on_remove(fragment) then
            local chunk_fragment_components = chunk_components[fragment]
            if chunk_fragment_components then
                for place = 1, chunk_size do
                    local entity = chunk_entities[place]
                    local old_component = chunk_fragment_components[place]
                    __fragment_on_remove(entity, fragment, old_component)
                end
            else
                for place = 1, chunk_size do
                    local entity = chunk_entities[place]
                    __fragment_on_remove(entity, fragment)
                end
            end
        end
    end

    for place = 1, chunk_size do
        local entity = chunk_entities[place]
        local index = __unpack_id(entity)
        __entity_chunks[index] = nil
        __entity_places[index] = nil
        __release_id(entity)
    end

    do
        chunk.__entities = {}

        for f, _ in pairs(chunk_components) do
            chunk_components[f] = {}
        end
    end

    __structural_changes = __structural_changes + chunk_size
    return chunk_size
end

---
---
---
---
---

---@param entity evolved.entity
local function __detach_entity(entity)
    local index = __unpack_id(entity)

    local old_chunk = __entity_chunks[index]

    if not old_chunk then
        return
    end

    local old_chunk_entities = old_chunk.__entities
    local old_chunk_components = old_chunk.__components

    local old_place = __entity_places[index]
    local old_chunk_size = #old_chunk_entities

    if old_place == old_chunk_size then
        old_chunk_entities[old_place] = nil

        for _, cs in pairs(old_chunk_components) do
            cs[old_place] = nil
        end
    else
        local last_chunk_entity = old_chunk_entities[old_chunk_size]
        __entity_places[__unpack_id(last_chunk_entity)] = old_place

        old_chunk_entities[old_place] = last_chunk_entity
        old_chunk_entities[old_chunk_size] = nil

        for _, cs in pairs(old_chunk_components) do
            local last_chunk_component = cs[old_chunk_size]
            cs[old_place] = last_chunk_component
            cs[old_chunk_size] = nil
        end
    end

    __entity_chunks[index] = nil
    __entity_places[index] = nil

    __structural_changes = __structural_changes + 1
end

---
---
---
---
---

---@enum evolved.defer_op
local __defer_op = {
    set = 1,
    assign = 2,
    insert = 3,
    remove = 4,
    clear = 5,
    destroy = 6,
    batch_set = 7,
    batch_assign = 8,
    batch_insert = 9,
    batch_remove = 10,
    batch_clear = 11,
    batch_destroy = 12,
}

---@type table<evolved.defer_op, fun(bytes: any[], index: integer): integer>
local __defer_ops = {
    [__defer_op.set] = function(bytes, index)
        local entity = bytes[index + 0]
        local fragment = bytes[index + 1]
        local argument_count = bytes[index + 2]
        evolved.set(entity, fragment, __table_unpack(bytes, index + 3, index + 2 + argument_count))
        return 3 + argument_count
    end,
    [__defer_op.assign] = function(bytes, index)
        local entity = bytes[index + 0]
        local fragment = bytes[index + 1]
        local argument_count = bytes[index + 2]
        evolved.assign(entity, fragment, __table_unpack(bytes, index + 3, index + 2 + argument_count))
        return 3 + argument_count
    end,
    [__defer_op.insert] = function(bytes, index)
        local entity = bytes[index + 0]
        local fragment = bytes[index + 1]
        local argument_count = bytes[index + 2]
        evolved.insert(entity, fragment, __table_unpack(bytes, index + 3, index + 2 + argument_count))
        return 3 + argument_count
    end,
    [__defer_op.remove] = function(bytes, index)
        local entity = bytes[index + 0]
        local fragment_count = bytes[index + 1]
        evolved.remove(entity, __table_unpack(bytes, index + 2, index + 1 + fragment_count))
        return 2 + fragment_count
    end,
    [__defer_op.clear] = function(bytes, index)
        local entity = bytes[index + 0]
        evolved.clear(entity)
        return 1
    end,
    [__defer_op.destroy] = function(bytes, index)
        local entity = bytes[index + 0]
        evolved.destroy(entity)
        return 1
    end,
    [__defer_op.batch_set] = function(bytes, index)
        local query = bytes[index + 0]
        local fragment = bytes[index + 1]
        local argument_count = bytes[index + 2]
        evolved.batch_set(query, fragment, __table_unpack(bytes, index + 3, index + 2 + argument_count))
        return 3 + argument_count
    end,
    [__defer_op.batch_assign] = function(bytes, index)
        local query = bytes[index + 0]
        local fragment = bytes[index + 1]
        local argument_count = bytes[index + 2]
        evolved.batch_assign(query, fragment, __table_unpack(bytes, index + 3, index + 2 + argument_count))
        return 3 + argument_count
    end,
    [__defer_op.batch_insert] = function(bytes, index)
        local query = bytes[index + 0]
        local fragment = bytes[index + 1]
        local argument_count = bytes[index + 2]
        evolved.batch_insert(query, fragment, __table_unpack(bytes, index + 3, index + 2 + argument_count))
        return 3 + argument_count
    end,
    [__defer_op.batch_remove] = function(bytes, index)
        local query = bytes[index + 0]
        local fragment_count = bytes[index + 1]
        evolved.batch_remove(query, __table_unpack(bytes, index + 2, index + 1 + fragment_count))
        return 2 + fragment_count
    end,
    [__defer_op.batch_clear] = function(bytes, index)
        local query = bytes[index + 0]
        evolved.batch_clear(query)
        return 1
    end,
    [__defer_op.batch_destroy] = function(bytes, index)
        local query = bytes[index + 0]
        evolved.batch_destroy(query)
        return 1
    end,
}

---@return boolean started
local function __defer()
    assert(__defer_depth >= 0, 'unbalanced defer/commit')
    __defer_depth = __defer_depth + 1
    return __defer_depth == 1
end

---@return boolean committed
local function __defer_commit()
    assert(__defer_depth > 0, 'unbalanced defer/commit')
    __defer_depth = __defer_depth - 1

    if __defer_depth > 0 then
        return false
    end

    local length = __defer_length
    local bytecode = __defer_bytecode

    __defer_length = 0
    __defer_bytecode = {}

    local bytecode_index = 1
    while bytecode_index <= length do
        local op = __defer_ops[bytecode[bytecode_index]]
        bytecode_index = bytecode_index + op(bytecode, bytecode_index + 1) + 1
    end

    return true
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
local function __defer_set(entity, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = select('#', ...)

    bytecode[length + 1] = __defer_op.set
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    for i = 1, argument_count do
        bytecode[length + 4 + i] = select(i, ...)
    end

    __defer_length = length + 4 + argument_count
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
local function __defer_assign(entity, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = select('#', ...)

    bytecode[length + 1] = __defer_op.assign
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    for i = 1, argument_count do
        bytecode[length + 4 + i] = select(i, ...)
    end

    __defer_length = length + 4 + argument_count
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
local function __defer_insert(entity, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = select('#', ...)

    bytecode[length + 1] = __defer_op.insert
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    for i = 1, argument_count do
        bytecode[length + 4 + i] = select(i, ...)
    end

    __defer_length = length + 4 + argument_count
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
local function __defer_remove(entity, ...)
    local fragment_count = select('#', ...)
    if fragment_count == 0 then return end

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.remove
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment_count

    for i = 1, fragment_count do
        bytecode[length + 3 + i] = select(i, ...)
    end

    __defer_length = length + 3 + fragment_count
end

---@param entity evolved.entity
local function __defer_clear(entity)
    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.clear
    bytecode[length + 2] = entity

    __defer_length = length + 2
end

---@param entity evolved.entity
local function __defer_destroy(entity)
    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.destroy
    bytecode[length + 2] = entity

    __defer_length = length + 2
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
local function __defer_batch_set(query, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = select('#', ...)

    bytecode[length + 1] = __defer_op.batch_set
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    for i = 1, argument_count do
        bytecode[length + 4 + i] = select(i, ...)
    end

    __defer_length = length + 4 + argument_count
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
local function __defer_batch_assign(query, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = select('#', ...)

    bytecode[length + 1] = __defer_op.batch_assign
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    for i = 1, argument_count do
        bytecode[length + 4 + i] = select(i, ...)
    end

    __defer_length = length + 4 + argument_count
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
local function __defer_batch_insert(query, fragment, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = select('#', ...)

    bytecode[length + 1] = __defer_op.batch_insert
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment
    bytecode[length + 4] = argument_count

    for i = 1, argument_count do
        bytecode[length + 4 + i] = select(i, ...)
    end

    __defer_length = length + 4 + argument_count
end

---@param query evolved.query
---@param ... evolved.fragment fragments
local function __defer_batch_remove(query, ...)
    local fragment_count = select('#', ...)
    if fragment_count == 0 then return end

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_remove
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment_count

    for i = 1, fragment_count do
        bytecode[length + 3 + i] = select(i, ...)
    end

    __defer_length = length + 3 + fragment_count
end

---@param query evolved.query
local function __defer_batch_clear(query)
    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_clear
    bytecode[length + 2] = query

    __defer_length = length + 2
end

---@param query evolved.query
local function __defer_batch_destroy(query)
    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_destroy
    bytecode[length + 2] = query

    __defer_length = length + 2
end

---
---
---
---
---

---@param count? integer
---@return evolved.id ... ids
---@nodiscard
function evolved.id(count)
    count = count or 1

    if count == 0 then
        return
    end

    if count == 1 then
        return __acquire_id()
    end

    if count == 2 then
        return __acquire_id(), __acquire_id()
    end

    if count == 3 then
        return __acquire_id(), __acquire_id(), __acquire_id()
    end

    do
        return __acquire_id(), __acquire_id(), __acquire_id(),
            evolved.id(count - 3)
    end
end

---@param index integer
---@param version integer
---@return evolved.id
---@nodiscard
function evolved.pack(index, version)
    return __pack_id(index, version)
end

---@param id evolved.id
---@return integer index
---@return integer version
---@nodiscard
function evolved.unpack(id)
    return __unpack_id(id)
end

---@return boolean started
function evolved.defer()
    return __defer()
end

---@return boolean committed
function evolved.commit()
    return __defer_commit()
end

---@param entity evolved.entity
---@return boolean
---@nodiscard
function evolved.is_alive(entity)
    return __is_id_alive(entity)
end

---@param entity evolved.entity
---@return boolean
---@nodiscard
function evolved.is_empty(entity)
    return not __is_id_alive(entity)
        or not __entity_chunks[__unpack_id(entity)]
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return evolved.component ... components
---@nodiscard
function evolved.get(entity, ...)
    if not __is_id_alive(entity) then
        return
    end

    local index = __unpack_id(entity)
    local chunk = __entity_chunks[index]

    if not chunk then
        return
    end

    local place = __entity_places[index]
    return __chunk_get_components(chunk, place, ...)
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@return boolean
---@nodiscard
function evolved.has(entity, fragment)
    if not __is_id_alive(entity) then
        return false
    end

    local index = __unpack_id(entity)
    local chunk = __entity_chunks[index]

    if not chunk then
        return false
    end

    return __chunk_has_fragment(chunk, fragment)
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function evolved.has_all(entity, ...)
    if not __is_id_alive(entity) then
        return false
    end

    local index = __unpack_id(entity)
    local chunk = __entity_chunks[index]

    if not chunk then
        return select('#', ...) == 0
    end

    return __chunk_has_all_fragments(chunk, ...)
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function evolved.has_any(entity, ...)
    if not __is_id_alive(entity) then
        return false
    end

    local index = __unpack_id(entity)
    local chunk = __entity_chunks[index]

    if not chunk then
        return false
    end

    return __chunk_has_any_fragments(chunk, ...)
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
---@return boolean is_set
---@return boolean is_deferred
function evolved.set(entity, fragment, ...)
    if __defer_depth > 0 then
        __defer_set(entity, fragment, ...)
        return false, true
    end

    if not __is_id_alive(entity) then
        return false, false
    end

    local index = __unpack_id(entity)

    local old_chunk = __entity_chunks[index]
    local old_place = __entity_places[index]

    local new_chunk = __chunk_with_fragment(old_chunk, fragment)
    local new_place = #new_chunk.__entities + 1

    if old_chunk == new_chunk then
        local old_chunk_components = old_chunk.__components
        local old_chunk_fragment_components = old_chunk_components[fragment]

        if old_chunk_fragment_components then
            local old_component = old_chunk_fragment_components[old_place]
            local new_component = __component_construct(entity, fragment, ...)
            old_chunk_fragment_components[old_place] = new_component
            __fragment_on_set_and_assign(entity, fragment, new_component, old_component)
        else
            __fragment_on_set_and_assign(entity, fragment)
        end

        return true, false
    end

    __defer()
    do
        local new_chunk_entities = new_chunk.__entities
        local new_chunk_components = new_chunk.__components
        local new_chunk_fragment_components = new_chunk_components[fragment]

        new_chunk_entities[new_place] = entity

        if new_chunk_fragment_components then
            local new_component = __component_construct(entity, fragment, ...)
            new_chunk_fragment_components[new_place] = new_component
            __fragment_on_set_and_insert(entity, fragment, new_component)
        else
            __fragment_on_set_and_insert(entity, fragment)
        end

        if old_chunk then
            local old_chunk_components = old_chunk.__components

            for old_f, old_cs in pairs(old_chunk_components) do
                local new_cs = new_chunk_components[old_f]
                if new_cs then
                    new_cs[new_place] = old_cs[old_place]
                end
            end

            __detach_entity(entity)
        end

        __entity_chunks[index] = new_chunk
        __entity_places[index] = new_place

        __structural_changes = __structural_changes + 1
    end
    __defer_commit()
    return true, false
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
---@return boolean is_assigned
---@return boolean is_deferred
function evolved.assign(entity, fragment, ...)
    if __defer_depth > 0 then
        __defer_assign(entity, fragment, ...)
        return false, true
    end

    if not __is_id_alive(entity) then
        return false, false
    end

    local index = __unpack_id(entity)

    local chunk = __entity_chunks[index]
    local place = __entity_places[index]

    if not chunk or not chunk.__fragments[fragment] then
        return false, false
    end

    local chunk_components = chunk.__components
    local chunk_fragment_components = chunk_components[fragment]

    if chunk_fragment_components then
        local old_component = chunk_fragment_components[place]
        local new_component = __component_construct(entity, fragment, ...)
        chunk_fragment_components[place] = new_component
        __fragment_on_set_and_assign(entity, fragment, new_component, old_component)
    else
        __fragment_on_set_and_assign(entity, fragment)
    end

    return true, false
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param ... any component arguments
---@return boolean is_inserted
---@return boolean is_deferred
function evolved.insert(entity, fragment, ...)
    if __defer_depth > 0 then
        __defer_insert(entity, fragment, ...)
        return false, true
    end

    if not __is_id_alive(entity) then
        return false, false
    end

    local index = __unpack_id(entity)

    local old_chunk = __entity_chunks[index]
    local old_place = __entity_places[index]

    local new_chunk = __chunk_with_fragment(old_chunk, fragment)
    local new_place = #new_chunk.__entities + 1

    if old_chunk == new_chunk then
        return false, false
    end

    __defer()
    do
        local new_chunk_entities = new_chunk.__entities
        local new_chunk_components = new_chunk.__components
        local new_chunk_fragment_components = new_chunk_components[fragment]

        new_chunk_entities[new_place] = entity

        if new_chunk_fragment_components then
            local new_component = __component_construct(entity, fragment, ...)
            new_chunk_fragment_components[new_place] = new_component
            __fragment_on_set_and_insert(entity, fragment, new_component)
        else
            __fragment_on_set_and_insert(entity, fragment)
        end

        if old_chunk then
            local old_chunk_components = old_chunk.__components

            for old_f, old_cs in pairs(old_chunk_components) do
                local new_cs = new_chunk_components[old_f]
                if new_cs then
                    new_cs[new_place] = old_cs[old_place]
                end
            end

            __detach_entity(entity)
        end

        __entity_chunks[index] = new_chunk
        __entity_places[index] = new_place

        __structural_changes = __structural_changes + 1
    end
    __defer_commit()
    return true, false
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return boolean is_removed
---@return boolean is_deferred
function evolved.remove(entity, ...)
    if __defer_depth > 0 then
        __defer_remove(entity, ...)
        return false, true
    end

    if not __is_id_alive(entity) then
        return false, false
    end

    local index = __unpack_id(entity)

    local old_chunk = __entity_chunks[index]
    local old_place = __entity_places[index]

    local new_chunk = __chunk_without_fragments(old_chunk, ...)

    if old_chunk == new_chunk then
        return true, false
    end

    __defer()
    do
        local old_chunk_fragments = old_chunk.__fragments
        local old_chunk_components = old_chunk.__components

        for i = 1, select('#', ...) do
            local fragment = select(i, ...)
            if old_chunk_fragments[fragment] and __fragment_has_on_remove(fragment) then
                local old_chunk_fragment_components = old_chunk_components[fragment]
                if old_chunk_fragment_components then
                    local old_component = old_chunk_fragment_components[old_place]
                    __fragment_on_remove(entity, fragment, old_component)
                else
                    __fragment_on_remove(entity, fragment)
                end
            end
        end

        if new_chunk then
            local new_chunk_entities = new_chunk.__entities
            local new_chunk_components = new_chunk.__components

            local new_place = #new_chunk_entities + 1

            new_chunk_entities[new_place] = entity

            for new_f, new_cs in pairs(new_chunk_components) do
                local old_cs = old_chunk_components[new_f]
                if old_cs then
                    new_cs[new_place] = old_cs[old_place]
                end
            end

            __detach_entity(entity)

            __entity_chunks[index] = new_chunk
            __entity_places[index] = new_place
        else
            __detach_entity(entity)
        end

        __structural_changes = __structural_changes + 1
    end
    __defer_commit()
    return true, false
end

---@param entity evolved.entity
---@return boolean is_cleared
---@return boolean is_deferred
function evolved.clear(entity)
    if __defer_depth > 0 then
        __defer_clear(entity)
        return false, true
    end

    if not __is_id_alive(entity) then
        return false, false
    end

    local index = __unpack_id(entity)

    local chunk = __entity_chunks[index]
    local place = __entity_places[index]

    if not chunk then
        return true, false
    end

    __defer()
    do
        local chunk_fragments = chunk.__fragments
        local chunk_components = chunk.__components

        for fragment, _ in pairs(chunk_fragments) do
            if __fragment_has_on_remove(fragment) then
                local chunk_fragment_components = chunk_components[fragment]
                if chunk_fragment_components then
                    local old_component = chunk_fragment_components[place]
                    __fragment_on_remove(entity, fragment, old_component)
                else
                    __fragment_on_remove(entity, fragment)
                end
            end
        end

        __detach_entity(entity)

        __structural_changes = __structural_changes + 1
    end
    __defer_commit()
    return true, false
end

---@param entity evolved.entity
---@return boolean is_destroyed
---@return boolean is_deferred
function evolved.destroy(entity)
    if __defer_depth > 0 then
        __defer_destroy(entity)
        return false, true
    end

    if not __is_id_alive(entity) then
        return true, false
    end

    local index = __unpack_id(entity)

    local chunk = __entity_chunks[index]
    local place = __entity_places[index]

    if not chunk then
        __release_id(entity)
        return true, false
    end

    __defer()
    do
        local chunk_fragments = chunk.__fragments
        local chunk_components = chunk.__components

        for fragment, _ in pairs(chunk_fragments) do
            if __fragment_has_on_remove(fragment) then
                local chunk_fragment_components = chunk_components[fragment]
                if chunk_fragment_components then
                    local old_component = chunk_fragment_components[place]
                    __fragment_on_remove(entity, fragment, old_component)
                else
                    __fragment_on_remove(entity, fragment)
                end
            end
        end

        __detach_entity(entity)
        __release_id(entity)

        __structural_changes = __structural_changes + 1
    end
    __defer_commit()
    return true, false
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
---@return integer set_count
---@return boolean is_deferred
function evolved.batch_set(query, fragment, ...)
    if __defer_depth > 0 then
        __defer_batch_set(query, fragment, ...)
        return 0, true
    end

    local chunk_list = __acquire_chunk_list()

    for chunk in evolved.execute(query) do
        chunk_list[#chunk_list + 1] = chunk
    end

    local set_count = 0

    __defer()
    do
        for _, chunk in ipairs(chunk_list) do
            if __chunk_has_fragment(chunk, fragment) then
                set_count = set_count + __chunk_assign(chunk, fragment, ...)
            else
                set_count = set_count + __chunk_insert(chunk, fragment, ...)
            end
        end
    end
    __defer_commit()
    __release_chunk_list(chunk_list)
    return set_count, false
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
---@return integer assigned_count
---@return boolean is_deferred
function evolved.batch_assign(query, fragment, ...)
    if __defer_depth > 0 then
        __defer_batch_assign(query, fragment, ...)
        return 0, true
    end

    local chunk_list = __acquire_chunk_list()

    for chunk in evolved.execute(query) do
        chunk_list[#chunk_list + 1] = chunk
    end

    local assigned_count = 0

    __defer()
    do
        for _, chunk in ipairs(chunk_list) do
            assigned_count = assigned_count + __chunk_assign(chunk, fragment, ...)
        end
    end
    __defer_commit()
    __release_chunk_list(chunk_list)
    return assigned_count, false
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param ... any component arguments
---@return integer inserted_count
---@return boolean is_deferred
function evolved.batch_insert(query, fragment, ...)
    if __defer_depth > 0 then
        __defer_batch_insert(query, fragment, ...)
        return 0, true
    end

    local chunk_list = __acquire_chunk_list()

    for chunk in evolved.execute(query) do
        chunk_list[#chunk_list + 1] = chunk
    end

    local inserted_count = 0

    __defer()
    do
        for _, chunk in ipairs(chunk_list) do
            inserted_count = inserted_count + __chunk_insert(chunk, fragment, ...)
        end
    end
    __defer_commit()
    __release_chunk_list(chunk_list)
    return inserted_count, false
end

---@param query evolved.query
---@param ... evolved.fragment fragments
---@return integer removed_count
---@return boolean is_deferred
function evolved.batch_remove(query, ...)
    if __defer_depth > 0 then
        __defer_batch_remove(query, ...)
        return 0, true
    end

    local chunk_list = __acquire_chunk_list()

    for chunk in evolved.execute(query) do
        chunk_list[#chunk_list + 1] = chunk
    end

    local removed_count = 0

    __defer()
    do
        for _, chunk in ipairs(chunk_list) do
            removed_count = removed_count + __chunk_remove(chunk, ...)
        end
    end
    __defer_commit()
    __release_chunk_list(chunk_list)
    return removed_count, false
end

---@param query evolved.query
---@return integer cleared_count
---@return boolean is_deferred
function evolved.batch_clear(query)
    if __defer_depth > 0 then
        __defer_batch_clear(query)
        return 0, true
    end

    local chunk_list = __acquire_chunk_list()

    for chunk in evolved.execute(query) do
        chunk_list[#chunk_list + 1] = chunk
    end

    local cleared_count = 0

    __defer()
    do
        for _, chunk in ipairs(chunk_list) do
            cleared_count = cleared_count + __chunk_clear(chunk)
        end
    end
    __defer_commit()
    __release_chunk_list(chunk_list)
    return cleared_count, false
end

---@param query evolved.query
---@return integer destroyed_count
---@return boolean is_deferred
function evolved.batch_destroy(query)
    if __defer_depth > 0 then
        __defer_batch_destroy(query)
        return 0, true
    end

    local chunk_list = __acquire_chunk_list()

    for chunk in evolved.execute(query) do
        chunk_list[#chunk_list + 1] = chunk
    end

    local destroyed_count = 0

    __defer()
    do
        for _, chunk in ipairs(chunk_list) do
            destroyed_count = destroyed_count + __chunk_destroy(chunk)
        end
    end
    __defer_commit()
    __release_chunk_list(chunk_list)
    return destroyed_count, false
end

---
---
---
---
---

local __INCLUDE_SET = __acquire_id()
local __EXCLUDE_SET = __acquire_id()
local __SORTED_INCLUDE_LIST = __acquire_id()
local __SORTED_EXCLUDE_LIST = __acquire_id()

assert(evolved.insert(evolved.TAG, evolved.TAG))

---@param ... evolved.fragment
assert(evolved.insert(evolved.INCLUDE_LIST, evolved.CONSTRUCT, function(_, _, ...)
    local include_list = {}

    for i = 1, select('#', ...) do
        include_list[i] = select(i, ...)
    end

    return include_list
end))

---@param query evolved.query
---@param include_list evolved.entity[]
assert(evolved.insert(evolved.INCLUDE_LIST, evolved.ON_SET, function(query, _, include_list)
    ---@type table<evolved.fragment, boolean>, evolved.fragment[]
    local include_set, sorted_include_list = {}, {}

    for _, f in ipairs(include_list) do
        include_set[f] = true
        sorted_include_list[#sorted_include_list + 1] = f
    end

    table.sort(sorted_include_list)

    evolved.set(query, __INCLUDE_SET, include_set)
    evolved.set(query, __SORTED_INCLUDE_LIST, sorted_include_list)
end))

assert(evolved.insert(evolved.INCLUDE_LIST, evolved.ON_REMOVE, function(query)
    evolved.remove(query, __INCLUDE_SET, __SORTED_INCLUDE_LIST)
end))

---@param ... evolved.fragment
assert(evolved.insert(evolved.EXCLUDE_LIST, evolved.CONSTRUCT, function(_, _, ...)
    local exclude_list = {}

    for i = 1, select('#', ...) do
        exclude_list[i] = select(i, ...)
    end

    return exclude_list
end))

---@param query evolved.query
---@param exclude_list evolved.entity[]
assert(evolved.insert(evolved.EXCLUDE_LIST, evolved.ON_SET, function(query, _, exclude_list)
    ---@type table<evolved.fragment, boolean>, evolved.fragment[]
    local exclude_set, sorted_exclude_list = {}, {}

    for _, f in ipairs(exclude_list) do
        exclude_set[f] = true
        sorted_exclude_list[#sorted_exclude_list + 1] = f
    end

    table.sort(sorted_exclude_list)

    evolved.set(query, __EXCLUDE_SET, exclude_set)
    evolved.set(query, __SORTED_EXCLUDE_LIST, sorted_exclude_list)
end))

assert(evolved.insert(evolved.EXCLUDE_LIST, evolved.ON_REMOVE, function(query)
    evolved.remove(query, __EXCLUDE_SET, __SORTED_EXCLUDE_LIST)
end))

---
---
---
---
---

---@type table<evolved.fragment, boolean>
local __EMPTY_FRAGMENT_SET = setmetatable({}, {
    __newindex = function() error('attempt to modify empty fragment set') end
})

---@type evolved.fragment[]
local __EMPTY_FRAGMENT_LIST = setmetatable({}, {
    __newindex = function() error('attempt to modify empty fragment list') end
})

---@type evolved.component[]
local __EMPTY_COMPONENT_STORAGE = setmetatable({}, {
    __newindex = function() error('attempt to modify empty component storage') end
})

---
---
---
---
---

---@param ... evolved.fragment fragments
---@return evolved.chunk?, evolved.entity[]?
function evolved.chunk(...)
    local fragment_count = select('#', ...)

    if fragment_count == 0 then
        return
    end

    local sorted_fragment_list = __acquire_fragment_list()

    for i = 1, fragment_count do
        local fragment = select(i, ...)
        sorted_fragment_list[#sorted_fragment_list + 1] = fragment
    end

    table.sort(sorted_fragment_list)

    local root_fragment = sorted_fragment_list[1]
    local chunk = __root_chunks[root_fragment]

    if not chunk then
        __release_fragment_list(sorted_fragment_list)
        return
    end

    for i = 2, fragment_count do
        local child_fragment = sorted_fragment_list[i]
        if child_fragment > sorted_fragment_list[i - 1] then
            chunk = chunk.__with_fragment_edges[child_fragment]

            if not chunk then
                __release_fragment_list(sorted_fragment_list)
                return
            end
        end
    end

    __release_fragment_list(sorted_fragment_list)
    return chunk, chunk.__entities
end

---@param chunk evolved.chunk
---@param ... evolved.fragment fragments
---@return evolved.component[] ... components
---@nodiscard
function evolved.select(chunk, ...)
    local fragment_count = select('#', ...)

    if fragment_count == 0 then
        return
    end

    local chunk_components = chunk.__components

    if fragment_count == 1 then
        local f1 = ...
        return
            chunk_components[f1] or __EMPTY_COMPONENT_STORAGE
    end

    if fragment_count == 2 then
        local f1, f2 = ...
        return
            chunk_components[f1] or __EMPTY_COMPONENT_STORAGE,
            chunk_components[f2] or __EMPTY_COMPONENT_STORAGE
    end

    if fragment_count == 3 then
        local f1, f2, f3 = ...
        return
            chunk_components[f1] or __EMPTY_COMPONENT_STORAGE,
            chunk_components[f2] or __EMPTY_COMPONENT_STORAGE,
            chunk_components[f3] or __EMPTY_COMPONENT_STORAGE
    end

    do
        local f1, f2, f3 = ...
        return
            chunk_components[f1] or __EMPTY_COMPONENT_STORAGE,
            chunk_components[f2] or __EMPTY_COMPONENT_STORAGE,
            chunk_components[f3] or __EMPTY_COMPONENT_STORAGE,
            evolved.select(chunk, select(4, ...))
    end
end

---@param entity evolved.entity
---@return evolved.each_iterator
---@return evolved.each_state?
---@nodiscard
function evolved.each(entity)
    if not __is_id_alive(entity) then
        return __each_iterator
    end

    local index = __unpack_id(entity)

    local chunk = __entity_chunks[index]
    local place = __entity_places[index]

    if not chunk then
        return __each_iterator
    end

    return __each_iterator, __acquire_each_state(chunk, place)
end

---@param query evolved.query
---@return evolved.execute_iterator
---@return evolved.execute_state?
---@nodiscard
function evolved.execute(query)
    if not __is_id_alive(query) then
        return __execute_iterator
    end

    ---@type table<evolved.fragment, boolean>?, evolved.fragment[]?, evolved.fragment[]?
    local exclude_set, include_list, exclude_list = evolved.get(query,
        __EXCLUDE_SET, __SORTED_INCLUDE_LIST, __SORTED_EXCLUDE_LIST)

    if not exclude_set then exclude_set = __EMPTY_FRAGMENT_SET end
    if not include_list then include_list = __EMPTY_FRAGMENT_LIST end
    if not exclude_list then exclude_list = __EMPTY_FRAGMENT_LIST end

    if #include_list == 0 then
        return __execute_iterator
    end

    local major_fragment = include_list[#include_list]
    local major_fragment_chunks = __major_chunks[major_fragment]

    if not major_fragment_chunks then
        return __execute_iterator
    end

    local execute_state = __acquire_execute_state(exclude_set)

    for _, major_fragment_chunk in ipairs(major_fragment_chunks) do
        if __chunk_has_all_fragment_list(major_fragment_chunk, include_list) then
            if not __chunk_has_any_fragment_list(major_fragment_chunk, exclude_list) then
                local chunk_stack = execute_state[2]
                chunk_stack[#chunk_stack + 1] = major_fragment_chunk
            end
        end
    end

    return __execute_iterator, execute_state
end

---
---
---
---
---

return evolved
