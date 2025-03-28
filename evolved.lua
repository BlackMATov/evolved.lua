local evolved = {
    __HOMEPAGE = 'https://github.com/BlackMATov/evolved.lua',
    __DESCRIPTION = 'Evolved ECS (Entity-Component-System) for Lua',
    __VERSION = '0.0.1',
    __LICENSE = [[
        MIT License

        Copyright (C) 2024-2025, by Matvey Cherevko (blackmatov@gmail.com)

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

---@class evolved.id

---@alias evolved.entity evolved.id
---@alias evolved.fragment evolved.id
---@alias evolved.query evolved.id
---@alias evolved.group evolved.id
---@alias evolved.phase evolved.id
---@alias evolved.system evolved.id

---@alias evolved.component any
---@alias evolved.storage evolved.component[]

---@alias evolved.default evolved.component
---@alias evolved.duplicate fun(c: evolved.component): evolved.component

---@alias evolved.execute fun(c: evolved.chunk, es: evolved.entity[], ec: integer)
---@alias evolved.prologue fun()
---@alias evolved.epilogue fun()

---@alias evolved.set_hook fun(e: evolved.entity, f: evolved.fragment, nc: evolved.component, oc?: evolved.component)
---@alias evolved.assign_hook fun(e: evolved.entity, f: evolved.fragment, nc: evolved.component, oc: evolved.component)
---@alias evolved.insert_hook fun(e: evolved.entity, f: evolved.fragment, nc: evolved.component)
---@alias evolved.remove_hook fun(e: evolved.entity, f: evolved.fragment, c: evolved.component)

---@class (exact) evolved.chunk
---@field package __parent? evolved.chunk
---@field package __child_set table<evolved.chunk, integer>
---@field package __child_list evolved.chunk[]
---@field package __child_count integer
---@field package __entity_list evolved.entity[]
---@field package __entity_count integer
---@field package __fragment evolved.fragment
---@field package __fragment_set table<evolved.fragment, integer>
---@field package __fragment_list evolved.fragment[]
---@field package __fragment_count integer
---@field package __component_count integer
---@field package __component_indices table<evolved.fragment, integer>
---@field package __component_storages evolved.storage[]
---@field package __component_fragments evolved.fragment[]
---@field package __with_fragment_edges table<evolved.fragment, evolved.chunk>
---@field package __without_fragment_edges table<evolved.fragment, evolved.chunk>
---@field package __unreachable_or_collected boolean
---@field package __has_setup_hooks boolean
---@field package __has_assign_hooks boolean
---@field package __has_insert_hooks boolean
---@field package __has_remove_hooks boolean

---@class (exact) evolved.each_state
---@field package [1] integer structural_changes
---@field package [2] evolved.chunk entity_chunk
---@field package [3] integer entity_place
---@field package [4] integer chunk_fragment_index

---@class (exact) evolved.execute_state
---@field package [1] integer structural_changes
---@field package [2] evolved.chunk[] chunk_stack
---@field package [3] integer chunk_stack_size
---@field package [4] table<evolved.fragment, integer>? exclude_set

---@alias evolved.each_iterator fun(state: evolved.each_state?): evolved.fragment?, evolved.component?
---@alias evolved.execute_iterator fun(state: evolved.execute_state?): evolved.chunk?, evolved.entity[]?, integer?

---
---
---
---
---

local __debug_mode = false ---@type boolean

local __freelist_ids = {} ---@type integer[]
local __acquired_count = 0 ---@type integer
local __available_index = 0 ---@type integer

local __defer_depth = 0 ---@type integer
local __defer_length = 0 ---@type integer
local __defer_bytecode = {} ---@type any[]

local __root_chunks = {} ---@type table<evolved.fragment, evolved.chunk>
local __major_chunks = {} ---@type table<evolved.fragment, evolved.assoc_list>
local __minor_chunks = {} ---@type table<evolved.fragment, evolved.assoc_list>

local __pinned_chunks = {} ---@type table<evolved.chunk, integer>

local __entity_chunks = {} ---@type table<integer, evolved.chunk>
local __entity_places = {} ---@type table<integer, integer>

local __structural_changes = 0 ---@type integer

local __phase_groups = {} ---@type table<evolved.phase, evolved.assoc_list>
local __group_systems = {} ---@type table<evolved.group, evolved.assoc_list>
local __group_dependencies = {} ---@type table<evolved.group, evolved.assoc_list>

local __query_sorted_includes = {} ---@type table<evolved.query, evolved.assoc_list>
local __query_sorted_excludes = {} ---@type table<evolved.query, evolved.assoc_list>

---
---
---
---
---

local __lua_next = next
local __lua_pcall = pcall
local __lua_select = select
local __lua_setmetatable = setmetatable
local __lua_table_sort = table.sort
local __lua_type = type

---@type fun(narray: integer, nhash: integer): table
local __lua_table_new = (function()
    -- https://luajit.org/extensions.html
    -- https://create.roblox.com/docs/reference/engine/libraries/table#create
    -- https://forum.defold.com/t/solved-is-luajit-table-new-function-available-in-defold/78623

    do
        ---@diagnostic disable-next-line: undefined-field
        local table_new = table and table.new
        if table_new then
            ---@cast table_new fun(narray: integer, nhash: integer): table
            return table_new
        end
    end

    do
        ---@diagnostic disable-next-line: undefined-field
        local table_create = table and table.create
        if table_create then
            ---@cast table_create fun(count: integer, value: any): table
            return function(narray)
                return table_create(narray)
            end
        end
    end

    do
        local table_new_loader = package and package.preload and package.preload['table.new']
        local table_new = table_new_loader and table_new_loader()
        if table_new then
            ---@cast table_new fun(narray: integer, nhash: integer): table
            return table_new
        end
    end

    ---@return table
    return function()
        return {}
    end
end)()

---@type fun(tab: table)
local __lua_table_clear = (function()
    -- https://luajit.org/extensions.html
    -- https://create.roblox.com/docs/reference/engine/libraries/table#clear
    -- https://forum.defold.com/t/solved-is-luajit-table-new-function-available-in-defold/78623

    do
        ---@diagnostic disable-next-line: undefined-field
        local table_clear = table and table.clear
        if table_clear then
            ---@cast table_clear fun(tab: table)
            return table_clear
        end
    end

    do
        local table_clear_loader = package and package.preload and package.preload['table.clear']
        local table_clear = table_clear_loader and table_clear_loader()
        if table_clear then
            ---@cast table_clear fun(tab: table)
            return table_clear
        end
    end

    ---@param tab table
    return function(tab)
        for i = 1, #tab do tab[i] = nil end
        for k in __lua_next, tab do tab[k] = nil end
    end
end)()

---@type fun(a1: table, f: integer, e: integer, t: integer, a2?: table): table
local __lua_table_move = (function()
    -- https://luajit.org/extensions.html
    -- https://github.com/LuaJIT/LuaJIT/blob/v2.1/src/lib_table.c#L132
    -- https://create.roblox.com/docs/reference/engine/libraries/table#move

    do
        ---@diagnostic disable-next-line: deprecated
        local table_move = table and table.move
        if table_move then
            ---@cast table_move fun(a1: table, f: integer, e: integer, t: integer, a2?: table): table
            return table_move
        end
    end

    ---@type fun(a1: table, f: integer, e: integer, t: integer, a2?: table): table
    return function(a1, f, e, t, a2)
        if a2 == nil then
            a2 = a1
        end

        if e < f then
            return a2
        end

        local d = t - f

        if t > e or t <= f or a2 ~= a1 then
            for i = f, e do
                a2[i + d] = a1[i]
            end
        else
            for i = e, f, -1 do
                a2[i + d] = a1[i]
            end
        end

        return a2
    end
end)()

---@type fun(lst: table, i: integer, j: integer): ...
local __lua_table_unpack = (function()
    do
        ---@diagnostic disable-next-line: deprecated
        local table_unpack = unpack
        if table_unpack then return table_unpack end
    end

    do
        ---@diagnostic disable-next-line: deprecated
        local table_unpack = table and table.unpack
        if table_unpack then return table_unpack end
    end
end)()

---
---
---
---
---

---@param fmt string
---@param ... any
local function __error_fmt(fmt, ...)
    error(string.format('| evolved.lua | %s',
        string.format(fmt, ...)))
end

---@param fmt string
---@param ... any
local function __warning_fmt(fmt, ...)
    print(string.format('| evolved.lua | %s',
        string.format(fmt, ...)))
end

---
---
---
---
---

---@return evolved.id
---@nodiscard
local function __acquire_id()
    local freelist_ids = __freelist_ids
    local available_index = __available_index

    if available_index ~= 0 then
        local acquired_index = available_index
        local freelist_id = freelist_ids[acquired_index]

        local next_available_index = freelist_id % 0x100000
        local shifted_version = freelist_id - next_available_index

        __available_index = next_available_index

        local acquired_id = acquired_index + shifted_version
        freelist_ids[acquired_index] = acquired_id

        return acquired_id --[[@as evolved.id]]
    else
        local acquired_count = __acquired_count

        if acquired_count == 0xFFFFF then
            __error_fmt('id index overflow')
        end

        acquired_count = acquired_count + 1
        __acquired_count = acquired_count

        local acquired_index = acquired_count
        local shifted_version = 0x100000

        local acquired_id = acquired_index + shifted_version
        freelist_ids[acquired_index] = acquired_id

        return acquired_id --[[@as evolved.id]]
    end
end

---@param id evolved.id
local function __release_id(id)
    local acquired_index = id % 0x100000
    local shifted_version = id - acquired_index

    local freelist_ids = __freelist_ids

    if freelist_ids[acquired_index] ~= id then
        __error_fmt('id is not acquired or already released')
    end

    shifted_version = shifted_version == 0xFFFFF * 0x100000
        and 0x100000
        or shifted_version + 0x100000

    freelist_ids[acquired_index] = __available_index + shifted_version
    __available_index = acquired_index
end

---
---
---
---
---

---@enum evolved.table_pool_tag
local __table_pool_tag = {
    bytecode = 1,
    chunk_stack = 2,
    each_state = 3,
    execute_state = 4,
    fragment_set = 5,
    fragment_list = 6,
    component_list = 7,
    group_list = 8,
    sorting_stack = 9,
    sorting_marks = 10,
    __count = 10,
}

---@class (exact) evolved.table_pool
---@field package __size integer
---@field package [integer] table

---@type table<evolved.table_pool_tag, evolved.table_pool>
local __tagged_table_pools = (function()
    local table_pools = __lua_table_new(__table_pool_tag.__count, 0)
    local table_pool_reserve = 16

    for tag = 1, __table_pool_tag.__count do
        ---@type evolved.table_pool
        local table_pool = __lua_table_new(table_pool_reserve, 1)
        for i = 1, table_pool_reserve do table_pool[i] = {} end
        table_pool.__size = table_pool_reserve
        table_pools[tag] = table_pool
    end

    return table_pools
end)()

---@param tag evolved.table_pool_tag
---@return table
---@nodiscard
local function __acquire_table(tag)
    local table_pool = __tagged_table_pools[tag]
    local table_pool_size = table_pool.__size

    if table_pool_size == 0 then
        return {}
    end

    local table = table_pool[table_pool_size]

    table_pool[table_pool_size] = nil
    table_pool_size = table_pool_size - 1

    table_pool.__size = table_pool_size
    return table
end

---@param tag evolved.table_pool_tag
---@param table table
---@param no_clear? boolean
local function __release_table(tag, table, no_clear)
    local table_pool = __tagged_table_pools[tag]
    local table_pool_size = table_pool.__size

    if not no_clear then
        __lua_table_clear(table)
    end

    table_pool_size = table_pool_size + 1
    table_pool[table_pool_size] = table

    table_pool.__size = table_pool_size
end

---
---
---
---
---

---@class (exact) evolved.assoc_list
---@field package __item_set table<any, integer>
---@field package __item_list any[]
---@field package __item_count integer

local __assoc_list_new
local __assoc_list_sort
local __assoc_list_sort_ex
local __assoc_list_insert
local __assoc_list_insert_ex
local __assoc_list_remove
local __assoc_list_remove_ex

---@param reserve? integer
---@return evolved.assoc_list
---@nodiscard
__assoc_list_new = function(reserve)
    ---@type evolved.assoc_list
    return {
        __item_set = __lua_table_new(0, reserve or 0),
        __item_list = __lua_table_new(reserve or 0, 0),
        __item_count = 0,
    }
end

---@generic K
---@param al evolved.assoc_list<K>
---@param comp? fun(a: K, b: K): boolean
__assoc_list_sort = function(al, comp)
    __assoc_list_sort_ex(
        al.__item_set, al.__item_list, al.__item_count,
        comp)
end

---@generic K
---@param al_item_set table<K, integer>
---@param al_item_list K[]
---@param al_item_count integer
---@param comp? fun(a: K, b: K): boolean
__assoc_list_sort_ex = function(al_item_set, al_item_list, al_item_count, comp)
    if al_item_count < 2 then
        return
    end

    __lua_table_sort(al_item_list, comp)

    for al_item_index = 1, al_item_count do
        local al_item = al_item_list[al_item_index]
        al_item_set[al_item] = al_item_index
    end
end

---@generic K
---@param al evolved.assoc_list<K>
---@param item K
__assoc_list_insert = function(al, item)
    al.__item_count = __assoc_list_insert_ex(
        al.__item_set, al.__item_list, al.__item_count,
        item)
end

---@generic K
---@param al_item_set table<K, integer>
---@param al_item_list K[]
---@param al_item_count integer
---@param item K
---@return integer new_al_count
---@nodiscard
__assoc_list_insert_ex = function(al_item_set, al_item_list, al_item_count, item)
    local item_index = al_item_set[item]

    if item_index then
        return al_item_count
    end

    al_item_count = al_item_count + 1
    al_item_set[item] = al_item_count
    al_item_list[al_item_count] = item

    return al_item_count
end

---@generic K
---@param al evolved.assoc_list<K>
---@param item K
__assoc_list_remove = function(al, item)
    al.__item_count = __assoc_list_remove_ex(
        al.__item_set, al.__item_list, al.__item_count,
        item)
end

---@generic K
---@param al_item_set table<K, integer>
---@param al_item_list K[]
---@param al_item_count integer
---@param item K
---@return integer new_al_count
---@nodiscard
__assoc_list_remove_ex = function(al_item_set, al_item_list, al_item_count, item)
    local item_index = al_item_set[item]

    if not item_index then
        return al_item_count
    end

    for al_item_index = item_index, al_item_count - 1 do
        local al_next_item = al_item_list[al_item_index + 1]
        al_item_set[al_next_item] = al_item_index
        al_item_list[al_item_index] = al_next_item
    end

    al_item_set[item] = nil
    al_item_list[al_item_count] = nil
    al_item_count = al_item_count - 1

    return al_item_count
end

---
---
---
---
---

---@type evolved.each_iterator
local function __each_iterator(each_state)
    if not each_state then return end

    local structural_changes = each_state[1]
    local entity_chunk = each_state[2]
    local entity_place = each_state[3]
    local chunk_fragment_index = each_state[4]

    if structural_changes ~= __structural_changes then
        __error_fmt('structural changes are prohibited during iteration')
    end

    local chunk_fragment_list = entity_chunk.__fragment_list
    local chunk_fragment_count = entity_chunk.__fragment_count
    local chunk_component_indices = entity_chunk.__component_indices
    local chunk_component_storages = entity_chunk.__component_storages

    if chunk_fragment_index <= chunk_fragment_count then
        each_state[4] = chunk_fragment_index + 1
        local fragment = chunk_fragment_list[chunk_fragment_index]
        local component_index = chunk_component_indices[fragment]
        local component_storage = chunk_component_storages[component_index]
        return fragment, component_storage and component_storage[entity_place]
    end

    __release_table(__table_pool_tag.each_state, each_state, true)
end

---@type evolved.execute_iterator
local function __execute_iterator(execute_state)
    if not execute_state then return end

    local structural_changes = execute_state[1]
    local chunk_stack = execute_state[2]
    local chunk_stack_size = execute_state[3]
    local exclude_set = execute_state[4]

    if structural_changes ~= __structural_changes then
        __error_fmt('structural changes are prohibited during iteration')
    end

    while chunk_stack_size > 0 do
        local chunk = chunk_stack[chunk_stack_size]

        chunk_stack[chunk_stack_size] = nil
        chunk_stack_size = chunk_stack_size - 1

        local chunk_child_list = chunk.__child_list
        local chunk_child_count = chunk.__child_count

        if exclude_set then
            for i = 1, chunk_child_count do
                local chunk_child = chunk_child_list[i]
                local chunk_child_fragment = chunk_child.__fragment

                if not exclude_set[chunk_child_fragment] then
                    chunk_stack_size = chunk_stack_size + 1
                    chunk_stack[chunk_stack_size] = chunk_child
                end
            end
        else
            __lua_table_move(
                chunk_child_list, 1, chunk_child_count,
                chunk_stack_size + 1, chunk_stack)

            chunk_stack_size = chunk_stack_size + chunk_child_count
        end

        local chunk_entity_list = chunk.__entity_list
        local chunk_entity_count = chunk.__entity_count

        if chunk_entity_count > 0 then
            execute_state[3] = chunk_stack_size
            return chunk, chunk_entity_list, chunk_entity_count
        end
    end

    __release_table(__table_pool_tag.chunk_stack, chunk_stack, true)
    __release_table(__table_pool_tag.execute_state, execute_state, true)
end

---
---
---
---
---

local __TAG = __acquire_id()
local __NAME = __acquire_id()
local __DEFAULT = __acquire_id()
local __DUPLICATE = __acquire_id()

local __INCLUDES = __acquire_id()
local __EXCLUDES = __acquire_id()

local __ON_SET = __acquire_id()
local __ON_ASSIGN = __acquire_id()
local __ON_INSERT = __acquire_id()
local __ON_REMOVE = __acquire_id()

local __PHASE = __acquire_id()
local __GROUP = __acquire_id()
local __AFTER = __acquire_id()

local __QUERY = __acquire_id()
local __EXECUTE = __acquire_id()

local __PROLOGUE = __acquire_id()
local __EPILOGUE = __acquire_id()

local __DISABLED = __acquire_id()

local __DESTROY_POLICY = __acquire_id()
local __DESTROY_POLICY_DESTROY_ENTITY = __acquire_id()
local __DESTROY_POLICY_REMOVE_FRAGMENT = __acquire_id()

---
---
---
---
---

local __safe_tbls = {
    ---@type table<evolved.fragment, integer>
    __EMPTY_FRAGMENT_SET = __lua_setmetatable({}, {
        __newindex = function() __error_fmt('attempt to modify empty fragment set') end
    }),

    ---@type evolved.fragment[]
    __EMPTY_FRAGMENT_LIST = __lua_setmetatable({}, {
        __newindex = function() __error_fmt('attempt to modify empty fragment list') end
    }),

    ---@type evolved.component[]
    __EMPTY_COMPONENT_LIST = __lua_setmetatable({}, {
        __newindex = function() __error_fmt('attempt to modify empty component list') end
    }),

    ---@type evolved.component[]
    __EMPTY_COMPONENT_STORAGE = __lua_setmetatable({}, {
        __newindex = function() __error_fmt('attempt to modify empty component storage') end
    }),
}

---
---
---
---
---

local __evolved_id

local __evolved_pack
local __evolved_unpack

local __evolved_defer
local __evolved_commit

local __evolved_is_alive
local __evolved_is_alive_all
local __evolved_is_alive_any

local __evolved_is_empty
local __evolved_is_empty_all
local __evolved_is_empty_any

local __evolved_has
local __evolved_has_all
local __evolved_has_any

local __evolved_get

local __evolved_set
local __evolved_remove
local __evolved_clear
local __evolved_destroy

local __evolved_multi_set
local __evolved_multi_remove

local __evolved_batch_set
local __evolved_batch_remove
local __evolved_batch_clear
local __evolved_batch_destroy

local __evolved_batch_multi_set
local __evolved_batch_multi_remove

local __evolved_chunk

local __evolved_entities
local __evolved_fragments
local __evolved_components

local __evolved_each
local __evolved_execute

local __evolved_process

local __evolved_spawn_at
local __evolved_spawn_with

local __evolved_debug_mode
local __evolved_collect_garbage

local __evolved_entity
local __evolved_fragment
local __evolved_query
local __evolved_group
local __evolved_phase
local __evolved_system

---
---
---
---
---

---@param id evolved.id
---@return string
---@nodiscard
local function __id_name(id)
    ---@type string?
    local id_name = __evolved_get(id, __NAME)

    if id_name then
        return id_name
    end

    local id_index, id_version = __evolved_unpack(id)
    return string.format('$%d#%d:%d', id, id_index, id_version)
end

---@generic K
---@param old_list K[]
---@return K[]
---@nodiscard
local function __list_copy(old_list)
    local old_list_size = #old_list

    if old_list_size == 0 then
        return {}
    end

    local new_list = __lua_table_new(old_list_size, 0)

    __lua_table_move(
        old_list, 1, old_list_size,
        1, new_list)

    return new_list
end

---@param fragment evolved.fragment
---@return evolved.storage
---@nodiscard
---@diagnostic disable-next-line: unused-local
local function __component_storage(fragment)
    return {}
end

---@param fragment evolved.fragment
---@param trace fun(chunk: evolved.chunk, ...: any): boolean
---@param ... any additional trace arguments
local function __trace_fragment_chunks(fragment, trace, ...)
    ---@type evolved.chunk[]
    local chunk_stack = __acquire_table(__table_pool_tag.chunk_stack)
    local chunk_stack_size = 0

    do
        local major_chunks = __major_chunks[fragment]
        local major_chunk_list = major_chunks and major_chunks.__item_list --[=[@as evolved.chunk[]]=]
        local major_chunk_count = major_chunks and major_chunks.__item_count or 0 --[[@as integer]]

        if major_chunk_count > 0 then
            __lua_table_move(
                major_chunk_list, 1, major_chunk_count,
                chunk_stack_size + 1, chunk_stack)

            chunk_stack_size = chunk_stack_size + major_chunk_count
        end
    end

    while chunk_stack_size > 0 do
        local chunk = chunk_stack[chunk_stack_size]

        chunk_stack[chunk_stack_size] = nil
        chunk_stack_size = chunk_stack_size - 1

        if trace(chunk, ...) then
            local chunk_child_list = chunk.__child_list
            local chunk_child_count = chunk.__child_count

            __lua_table_move(
                chunk_child_list, 1, chunk_child_count,
                chunk_stack_size + 1, chunk_stack)

            chunk_stack_size = chunk_stack_size + chunk_child_count
        end
    end

    __release_table(__table_pool_tag.chunk_stack, chunk_stack, true)
end

---
---
---
---
---

local __debug_fns = {}

---@type metatable
__debug_fns.chunk_mt = {}
__debug_fns.chunk_mt.__index = __debug_fns.chunk_mt

---@type metatable
__debug_fns.chunk_fragment_set_mt = {}
__debug_fns.chunk_fragment_set_mt.__index = __debug_fns.chunk_fragment_set_mt

---@type metatable
__debug_fns.chunk_fragment_list_mt = {}
__debug_fns.chunk_fragment_list_mt.__index = __debug_fns.chunk_fragment_list_mt

---@type metatable
__debug_fns.chunk_component_indices_mt = {}
__debug_fns.chunk_component_indices_mt.__index = __debug_fns.chunk_component_indices_mt

---@type metatable
__debug_fns.chunk_component_storages_mt = {}
__debug_fns.chunk_component_storages_mt.__index = __debug_fns.chunk_component_storages_mt

---@type metatable
__debug_fns.chunk_component_fragments_mt = {}
__debug_fns.chunk_component_fragments_mt.__index = __debug_fns.chunk_component_fragments_mt

---
---
---
---
---

---@param self evolved.chunk
function __debug_fns.chunk_mt.__tostring(self)
    local items = {} ---@type string[]

    for fragment_index, fragment in ipairs(self.__fragment_list) do
        items[fragment_index] = __id_name(fragment)
    end

    return string.format('<%s>', table.concat(items, ', '))
end

---@param self table<evolved.fragment, integer>
function __debug_fns.chunk_fragment_set_mt.__tostring(self)
    local items = {} ---@type string[]

    for fragment, fragment_index in pairs(self) do
        items[fragment_index] = string.format('(%s -> %d)',
            __id_name(fragment), fragment_index)
    end

    return string.format('{%s}', table.concat(items, ', '))
end

---@param self evolved.fragment[]
function __debug_fns.chunk_fragment_list_mt.__tostring(self)
    local items = {} ---@type string[]

    for fragment_index, fragment in ipairs(self) do
        items[fragment_index] = string.format('(%d -> %s)',
            fragment_index, __id_name(fragment))
    end

    return string.format('[%s]', table.concat(items, ', '))
end

---@param self table<evolved.fragment, integer>
function __debug_fns.chunk_component_indices_mt.__tostring(self)
    local items = {} ---@type string[]

    for component_fragment, component_index in pairs(self) do
        items[component_index] = string.format('(%s -> %d)',
            __id_name(component_fragment), component_index)
    end

    return string.format('{%s}', table.concat(items, ', '))
end

---@param self evolved.storage[]
function __debug_fns.chunk_component_storages_mt.__tostring(self)
    local items = {} ---@type string[]

    for component_index, component_storage in ipairs(self) do
        items[component_index] = string.format('(%d -> #%d)',
            component_index, #component_storage)
    end

    return string.format('[%s]', table.concat(items, ', '))
end

---@param self evolved.fragment[]
function __debug_fns.chunk_component_fragments_mt.__tostring(self)
    local items = {} ---@type string[]

    for component_index, component_fragment in ipairs(self) do
        items[component_index] = string.format('(%d -> %s)',
            component_index, __id_name(component_fragment))
    end

    return string.format('[%s]', table.concat(items, ', '))
end

---
---
---
---
---

---@param chunk evolved.chunk
function __debug_fns.validate_chunk(chunk)
    if chunk.__unreachable_or_collected then
        __error_fmt('the chunk (%s) is unreachable or collected and cannot be used',
            chunk)
    end
end

---@param entity evolved.entity
function __debug_fns.validate_entity(entity)
    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        __error_fmt('the entity (%s) is not alive and cannot be used',
            __id_name(entity))
    end
end

---@param ... evolved.entity entities
function __debug_fns.validate_entities(...)
    for i = 1, __lua_select('#', ...) do
        __debug_fns.validate_entity(__lua_select(i, ...))
    end
end

---@param fragment evolved.fragment
function __debug_fns.validate_fragment(fragment)
    local fragment_index = fragment % 0x100000

    if __freelist_ids[fragment_index] ~= fragment then
        __error_fmt('the fragment (%s) is not alive and cannot be used',
            __id_name(fragment))
    end
end

---@param ... evolved.fragment fragments
function __debug_fns.validate_fragments(...)
    for i = 1, __lua_select('#', ...) do
        __debug_fns.validate_fragment(__lua_select(i, ...))
    end
end

---@param fragment_list evolved.fragment[]
---@param fragment_count integer
function __debug_fns.validate_fragment_list(fragment_list, fragment_count)
    for i = 1, fragment_count do
        __debug_fns.validate_fragment(fragment_list[i])
    end
end

---@param query evolved.query
function __debug_fns.validate_query(query)
    local query_index = query % 0x100000

    if __freelist_ids[query_index] ~= query then
        __error_fmt('the query (%s) is not alive and cannot be used',
            __id_name(query))
    end
end

---@param phase evolved.phase
function __debug_fns.validate_phase(phase)
    local phase_index = phase % 0x100000

    if __freelist_ids[phase_index] ~= phase then
        __error_fmt('the phase (%s) is not alive and cannot be used',
            __id_name(phase))
    end
end

---@param ... evolved.phase phases
function __debug_fns.validate_phases(...)
    for i = 1, __lua_select('#', ...) do
        __debug_fns.validate_phase(__lua_select(i, ...))
    end
end

---
---
---
---
---

---@param chunk_parent? evolved.chunk
---@param chunk_fragment evolved.fragment
---@return evolved.chunk
---@nodiscard
local function __new_chunk(chunk_parent, chunk_fragment)
    ---@type table<evolved.fragment, integer>
    local chunk_fragment_set = __lua_setmetatable({}, __debug_fns.chunk_fragment_set_mt)

    ---@type evolved.fragment[]
    local chunk_fragment_list = __lua_setmetatable({}, __debug_fns.chunk_fragment_list_mt)

    ---@type integer
    local chunk_fragment_count = 0

    ---@type integer
    local chunk_component_count = 0

    ---@type table<evolved.fragment, integer>
    local chunk_component_indices = __lua_setmetatable({}, __debug_fns.chunk_component_indices_mt)

    ---@type evolved.storage[]
    local chunk_component_storages = __lua_setmetatable({}, __debug_fns.chunk_component_storages_mt)

    ---@type evolved.fragment[]
    local chunk_component_fragments = __lua_setmetatable({}, __debug_fns.chunk_component_fragments_mt)

    local has_setup_hooks = (chunk_parent and chunk_parent.__has_setup_hooks)
        or __evolved_has_any(chunk_fragment, __DEFAULT, __DUPLICATE)

    local has_assign_hooks = (chunk_parent and chunk_parent.__has_assign_hooks)
        or __evolved_has_any(chunk_fragment, __ON_SET, __ON_ASSIGN)

    local has_insert_hooks = (chunk_parent and chunk_parent.__has_insert_hooks)
        or __evolved_has_any(chunk_fragment, __ON_SET, __ON_INSERT)

    local has_remove_hooks = (chunk_parent and chunk_parent.__has_remove_hooks)
        or __evolved_has(chunk_fragment, __ON_REMOVE)

    ---@type evolved.chunk
    local chunk = __lua_setmetatable({
        __parent = nil,
        __child_set = {},
        __child_list = {},
        __child_count = 0,
        __entity_list = {},
        __entity_count = 0,
        __fragment = chunk_fragment,
        __fragment_set = chunk_fragment_set,
        __fragment_list = chunk_fragment_list,
        __fragment_count = chunk_fragment_count,
        __component_count = chunk_component_count,
        __component_indices = chunk_component_indices,
        __component_storages = chunk_component_storages,
        __component_fragments = chunk_component_fragments,
        __with_fragment_edges = {},
        __without_fragment_edges = {},
        __unreachable_or_collected = false,
        __has_setup_hooks = has_setup_hooks,
        __has_assign_hooks = has_assign_hooks,
        __has_insert_hooks = has_insert_hooks,
        __has_remove_hooks = has_remove_hooks,
    }, __debug_fns.chunk_mt)

    if chunk_parent then
        local parent_fragment_list = chunk_parent.__fragment_list
        local parent_fragment_count = chunk_parent.__fragment_count

        for parent_fragment_index = 1, parent_fragment_count do
            local parent_fragment = parent_fragment_list[parent_fragment_index]

            chunk_fragment_count = __assoc_list_insert_ex(
                chunk_fragment_set, chunk_fragment_list, chunk_fragment_count,
                parent_fragment)

            if not __evolved_has(parent_fragment, __TAG) then
                chunk_component_count = chunk_component_count + 1
                local component_storage = __component_storage(parent_fragment)
                local component_storage_index = chunk_component_count
                chunk_component_indices[parent_fragment] = component_storage_index
                chunk_component_storages[component_storage_index] = component_storage
                chunk_component_fragments[component_storage_index] = parent_fragment
            end
        end

        chunk.__parent, chunk_parent.__child_count = chunk_parent, __assoc_list_insert_ex(
            chunk_parent.__child_set, chunk_parent.__child_list, chunk_parent.__child_count,
            chunk)

        chunk_parent.__with_fragment_edges[chunk_fragment] = chunk
        chunk.__without_fragment_edges[chunk_fragment] = chunk_parent
    end

    do
        chunk_fragment_count = __assoc_list_insert_ex(
            chunk_fragment_set, chunk_fragment_list, chunk_fragment_count,
            chunk_fragment)

        if not __evolved_has(chunk_fragment, __TAG) then
            chunk_component_count = chunk_component_count + 1
            local component_storage = __component_storage(chunk_fragment)
            local component_storage_index = chunk_component_count
            chunk_component_indices[chunk_fragment] = component_storage_index
            chunk_component_storages[component_storage_index] = component_storage
            chunk_component_fragments[component_storage_index] = chunk_fragment
        end
    end

    do
        chunk.__fragment_count = chunk_fragment_count
        chunk.__component_count = chunk_component_count
    end

    if not chunk_parent then
        local root_fragment = chunk_fragment
        __root_chunks[root_fragment] = chunk
    end

    do
        local major_fragment = chunk_fragment
        local major_chunks = __major_chunks[major_fragment]

        if not major_chunks then
            major_chunks = __assoc_list_new(4)
            __major_chunks[major_fragment] = major_chunks
        end

        __assoc_list_insert(major_chunks, chunk)
    end

    for i = 1, chunk_fragment_count do
        local minor_fragment = chunk_fragment_list[i]
        local minor_chunks = __minor_chunks[minor_fragment]

        if not minor_chunks then
            minor_chunks = __assoc_list_new(4)
            __minor_chunks[minor_fragment] = minor_chunks
        end

        __assoc_list_insert(minor_chunks, chunk)
    end

    return chunk
end

---@param chunk? evolved.chunk
---@param fragment evolved.fragment
---@return evolved.chunk
---@nodiscard
local function __chunk_with_fragment(chunk, fragment)
    if not chunk then
        local root_chunk = __root_chunks[fragment]
        return root_chunk or __new_chunk(nil, fragment)
    end

    if chunk.__fragment_set[fragment] then
        return chunk
    end

    do
        local with_fragment_edge = chunk.__with_fragment_edges[fragment]
        if with_fragment_edge then return with_fragment_edge end
    end

    if fragment < chunk.__fragment then
        local sibling_chunk = __chunk_with_fragment(
            __chunk_with_fragment(chunk.__parent, fragment),
            chunk.__fragment)

        chunk.__with_fragment_edges[fragment] = sibling_chunk
        sibling_chunk.__without_fragment_edges[fragment] = chunk

        return sibling_chunk
    end

    return __new_chunk(chunk, fragment)
end

---@param chunk? evolved.chunk
---@param fragment_list evolved.fragment[]
---@param fragment_count integer
---@return evolved.chunk?
---@nodiscard
local function __chunk_with_fragment_list(chunk, fragment_list, fragment_count)
    if fragment_count == 0 then
        return chunk
    end

    for i = 1, fragment_count do
        local fragment = fragment_list[i]
        chunk = __chunk_with_fragment(chunk, fragment)
    end

    return chunk
end

---@param chunk? evolved.chunk
---@param fragment evolved.fragment
---@return evolved.chunk?
---@nodiscard
local function __chunk_without_fragment(chunk, fragment)
    if not chunk then
        return nil
    end

    if not chunk.__fragment_set[fragment] then
        return chunk
    end

    if fragment == chunk.__fragment then
        return chunk.__parent
    end

    do
        local without_fragment_edge = chunk.__without_fragment_edges[fragment]
        if without_fragment_edge then return without_fragment_edge end
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
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return chunk
    end

    for i = 1, fragment_count do
        ---@type evolved.fragment
        local fragment = __lua_select(i, ...)
        chunk = __chunk_without_fragment(chunk, fragment)
    end

    return chunk
end

---@param chunk? evolved.chunk
---@param fragment_list evolved.fragment[]
---@param fragment_count integer
---@return evolved.chunk?
---@nodiscard
local function __chunk_without_fragment_list(chunk, fragment_list, fragment_count)
    if fragment_count == 0 then
        return chunk
    end

    for i = 1, fragment_count do
        local fragment = fragment_list[i]
        chunk = __chunk_without_fragment(chunk, fragment)
    end

    return chunk
end

---
---
---
---
---

---@param chunk evolved.chunk
---@return evolved.chunk chunk
local function __chunk_pin(chunk)
    local chunk_pin_count = __pinned_chunks[chunk] or 0

    __pinned_chunks[chunk] = chunk_pin_count + 1

    return chunk
end

---@param chunk evolved.chunk
---@return evolved.chunk
local function __chunk_unpin(chunk)
    local chunk_pin_count = __pinned_chunks[chunk] or 0

    if chunk_pin_count <= 0 then
        __error_fmt('unbalanced pin/unpin')
    end

    __pinned_chunks[chunk] = chunk_pin_count > 1 and chunk_pin_count - 1 or nil

    return chunk
end

---
---
---
---
---

---@param head_fragment evolved.fragment
---@param ... evolved.fragment tail_fragments
---@return evolved.chunk
---@nodiscard
local function __chunk_fragments(head_fragment, ...)
    local chunk = __root_chunks[head_fragment]
        or __chunk_with_fragment(nil, head_fragment)

    for i = 1, __lua_select('#', ...) do
        ---@type evolved.fragment
        local tail_fragment = __lua_select(i, ...)
        chunk = chunk.__with_fragment_edges[tail_fragment]
            or __chunk_with_fragment(chunk, tail_fragment)
    end

    return chunk
end

---@param fragment_list evolved.fragment[]
---@param fragment_count integer
---@return evolved.chunk?
---@nodiscard
local function __chunk_fragment_list(fragment_list, fragment_count)
    if fragment_count == 0 then
        return
    end

    local root_fragment = fragment_list[1]
    local chunk = __root_chunks[root_fragment]
        or __chunk_with_fragment(nil, root_fragment)

    for i = 2, fragment_count do
        local child_fragment = fragment_list[i]
        chunk = chunk.__with_fragment_edges[child_fragment]
            or __chunk_with_fragment(chunk, child_fragment)
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
    return chunk.__fragment_set[fragment] ~= nil
end

---@param chunk evolved.chunk
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
local function __chunk_has_all_fragments(chunk, ...)
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return true
    end

    local fs = chunk.__fragment_set

    if fragment_count == 1 then
        local f1 = ...
        return fs[f1] ~= nil
    end

    if fragment_count == 2 then
        local f1, f2 = ...
        return fs[f1] ~= nil and fs[f2] ~= nil
    end

    if fragment_count == 3 then
        local f1, f2, f3 = ...
        return fs[f1] ~= nil and fs[f2] ~= nil and fs[f3] ~= nil
    end

    if fragment_count == 4 then
        local f1, f2, f3, f4 = ...
        return fs[f1] ~= nil and fs[f2] ~= nil and fs[f3] ~= nil and fs[f4] ~= nil
    end

    do
        local f1, f2, f3, f4 = ...
        return fs[f1] ~= nil and fs[f2] ~= nil and fs[f3] ~= nil and fs[f4] ~= nil and
            __chunk_has_all_fragments(chunk, __lua_select(5, ...))
    end
end

---@param chunk evolved.chunk
---@param fragment_list evolved.fragment[]
---@param fragment_count integer
---@return boolean
---@nodiscard
local function __chunk_has_all_fragment_list(chunk, fragment_list, fragment_count)
    local fragment_set = chunk.__fragment_set

    for i = 1, fragment_count do
        local fragment = fragment_list[i]
        if not fragment_set[fragment] then
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
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return false
    end

    local fs = chunk.__fragment_set

    if fragment_count == 1 then
        local f1 = ...
        return fs[f1] ~= nil
    end

    if fragment_count == 2 then
        local f1, f2 = ...
        return fs[f1] ~= nil or fs[f2] ~= nil
    end

    if fragment_count == 3 then
        local f1, f2, f3 = ...
        return fs[f1] ~= nil or fs[f2] ~= nil or fs[f3] ~= nil
    end

    if fragment_count == 4 then
        local f1, f2, f3, f4 = ...
        return fs[f1] ~= nil or fs[f2] ~= nil or fs[f3] ~= nil or fs[f4] ~= nil
    end

    do
        local f1, f2, f3, f4 = ...
        return fs[f1] ~= nil or fs[f2] ~= nil or fs[f3] ~= nil or fs[f4] ~= nil or
            __chunk_has_any_fragments(chunk, __lua_select(5, ...))
    end
end

---@param chunk evolved.chunk
---@param fragment_list evolved.fragment[]
---@param fragment_count integer
---@return boolean
---@nodiscard
local function __chunk_has_any_fragment_list(chunk, fragment_list, fragment_count)
    local fragment_set = chunk.__fragment_set

    for i = 1, fragment_count do
        local fragment = fragment_list[i]
        if fragment_set[fragment] then
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
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return
    end

    local indices = chunk.__component_indices
    local storages = chunk.__component_storages

    if fragment_count == 1 then
        local f1 = ...
        local i1 = indices[f1]
        return
            i1 and storages[i1][place]
    end

    if fragment_count == 2 then
        local f1, f2 = ...
        local i1, i2 = indices[f1], indices[f2]
        return
            i1 and storages[i1][place],
            i2 and storages[i2][place]
    end

    if fragment_count == 3 then
        local f1, f2, f3 = ...
        local i1, i2, i3 = indices[f1], indices[f2], indices[f3]
        return
            i1 and storages[i1][place],
            i2 and storages[i2][place],
            i3 and storages[i3][place]
    end

    if fragment_count == 4 then
        local f1, f2, f3, f4 = ...
        local i1, i2, i3, i4 = indices[f1], indices[f2], indices[f3], indices[f4]
        return
            i1 and storages[i1][place],
            i2 and storages[i2][place],
            i3 and storages[i3][place],
            i4 and storages[i4][place]
    end

    do
        local f1, f2, f3, f4 = ...
        local i1, i2, i3, i4 = indices[f1], indices[f2], indices[f3], indices[f4]
        return
            i1 and storages[i1][place],
            i2 and storages[i2][place],
            i3 and storages[i3][place],
            i4 and storages[i4][place],
            __chunk_get_components(chunk, place, __lua_select(5, ...))
    end
end

---
---
---
---
---

local __defer_set
local __defer_remove
local __defer_clear
local __defer_destroy

local __defer_multi_set
local __defer_multi_remove

local __defer_batch_set
local __defer_batch_remove
local __defer_batch_clear
local __defer_batch_destroy

local __defer_batch_multi_set
local __defer_batch_multi_remove

local __defer_spawn_entity_at
local __defer_spawn_entity_with

local __defer_call_hook

---
---
---
---
---

---@param chunk evolved.chunk
---@param place integer
local function __detach_entity(chunk, place)
    local entity_list = chunk.__entity_list
    local entity_count = chunk.__entity_count

    local component_count = chunk.__component_count
    local component_storages = chunk.__component_storages

    if place == entity_count then
        entity_list[place] = nil

        for component_index = 1, component_count do
            local component_storage = component_storages[component_index]
            component_storage[place] = nil
        end
    else
        local last_entity = entity_list[entity_count]
        local last_entity_index = last_entity % 0x100000
        __entity_places[last_entity_index] = place

        entity_list[place] = last_entity
        entity_list[entity_count] = nil

        for component_index = 1, component_count do
            local component_storage = component_storages[component_index]
            local last_component = component_storage[entity_count]
            component_storage[place] = last_component
            component_storage[entity_count] = nil
        end
    end

    chunk.__entity_count = entity_count - 1
end

---@param chunk evolved.chunk
local function __detach_all_entities(chunk)
    local entity_list = chunk.__entity_list

    local component_count = chunk.__component_count
    local component_storages = chunk.__component_storages

    __lua_table_clear(entity_list)

    for component_index = 1, component_count do
        __lua_table_clear(component_storages[component_index])
    end

    chunk.__entity_count = 0
end

---@param entity evolved.entity
---@param chunk evolved.chunk
---@param fragment_list evolved.fragment[]
---@param fragment_count integer
---@param component_list evolved.component[]
local function __spawn_entity_at(entity, chunk, fragment_list, fragment_count, component_list)
    if __defer_depth <= 0 then
        __error_fmt('spawn entity operations should be deferred')
    end

    local chunk_entity_list = chunk.__entity_list
    local chunk_entity_count = chunk.__entity_count

    local chunk_component_count = chunk.__component_count
    local chunk_component_indices = chunk.__component_indices
    local chunk_component_storages = chunk.__component_storages
    local chunk_component_fragments = chunk.__component_fragments

    local chunk_has_setup_hooks = chunk.__has_setup_hooks
    local chunk_has_insert_hooks = chunk.__has_insert_hooks

    local place = chunk_entity_count + 1
    chunk.__entity_count = place

    chunk_entity_list[place] = entity

    do
        local entity_index = entity % 0x100000

        __entity_chunks[entity_index] = chunk
        __entity_places[entity_index] = place

        __structural_changes = __structural_changes + 1
    end

    if chunk_has_setup_hooks then
        for component_index = 1, chunk_component_count do
            local fragment = chunk_component_fragments[component_index]

            ---@type evolved.default?, evolved.duplicate?
            local fragment_default, fragment_duplicate =
                __evolved_get(fragment, __DEFAULT, __DUPLICATE)

            local new_component = fragment_default

            if new_component ~= nil and fragment_duplicate then
                new_component = fragment_duplicate(new_component)
            end

            if new_component == nil then
                new_component = true
            end

            local component_storage = chunk_component_storages[component_index]

            component_storage[place] = new_component
        end
    else
        for component_index = 1, chunk_component_count do
            local new_component = true

            local component_storage = chunk_component_storages[component_index]

            component_storage[place] = new_component
        end
    end

    if chunk_has_setup_hooks then
        for i = 1, fragment_count do
            local fragment = fragment_list[i]
            local component_index = chunk_component_indices[fragment]

            if component_index then
                ---@type evolved.duplicate?
                local fragment_duplicate =
                    __evolved_get(fragment, __DUPLICATE)

                local new_component = component_list[i]

                if new_component ~= nil and fragment_duplicate then
                    new_component = fragment_duplicate(new_component)
                end

                if new_component ~= nil then
                    local component_storage = chunk_component_storages[component_index]

                    component_storage[place] = new_component
                end
            end
        end
    else
        for i = 1, fragment_count do
            local fragment = fragment_list[i]
            local component_index = chunk_component_indices[fragment]

            if component_index then
                local new_component = component_list[i]

                if new_component ~= nil then
                    local component_storage = chunk_component_storages[component_index]

                    component_storage[place] = new_component
                end
            end
        end
    end

    if chunk_has_insert_hooks then
        local chunk_fragment_list = chunk.__fragment_list
        local chunk_fragment_count = chunk.__fragment_count

        for chunk_fragment_index = 1, chunk_fragment_count do
            local fragment = chunk_fragment_list[chunk_fragment_index]

            ---@type evolved.set_hook?, evolved.insert_hook?
            local fragment_on_set, fragment_on_insert =
                __evolved_get(fragment, __ON_SET, __ON_INSERT)

            local component_index = chunk_component_indices[fragment]

            if component_index then
                local component_storage = chunk_component_storages[component_index]

                local new_component = component_storage[place]

                if fragment_on_set then
                    __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                end

                if fragment_on_insert then
                    __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                end
            else
                if fragment_on_set then
                    __defer_call_hook(fragment_on_set, entity, fragment)
                end

                if fragment_on_insert then
                    __defer_call_hook(fragment_on_insert, entity, fragment)
                end
            end
        end
    end
end

---@param entity evolved.entity
---@param chunk evolved.chunk
---@param fragment_list evolved.fragment[]
---@param fragment_count integer
---@param component_list evolved.component[]
local function __spawn_entity_with(entity, chunk, fragment_list, fragment_count, component_list)
    if __defer_depth <= 0 then
        __error_fmt('spawn entity operations should be deferred')
    end

    local chunk_entity_list = chunk.__entity_list
    local chunk_entity_count = chunk.__entity_count

    local chunk_component_indices = chunk.__component_indices
    local chunk_component_storages = chunk.__component_storages

    local chunk_has_setup_hooks = chunk.__has_setup_hooks
    local chunk_has_insert_hooks = chunk.__has_insert_hooks

    local place = chunk_entity_count + 1
    chunk.__entity_count = place

    chunk_entity_list[place] = entity

    do
        local entity_index = entity % 0x100000

        __entity_chunks[entity_index] = chunk
        __entity_places[entity_index] = place

        __structural_changes = __structural_changes + 1
    end

    if chunk_has_setup_hooks then
        for i = 1, fragment_count do
            local fragment = fragment_list[i]
            local component_index = chunk_component_indices[fragment]

            if component_index then
                ---@type evolved.default?, evolved.duplicate?
                local fragment_default, fragment_duplicate =
                    __evolved_get(fragment, __DEFAULT, __DUPLICATE)

                local new_component = component_list[i]

                if new_component == nil then
                    new_component = fragment_default
                end

                if new_component ~= nil and fragment_duplicate then
                    new_component = fragment_duplicate(new_component)
                end

                if new_component == nil then
                    new_component = true
                end

                local component_storage = chunk_component_storages[component_index]

                component_storage[place] = new_component
            end
        end
    else
        for i = 1, fragment_count do
            local fragment = fragment_list[i]
            local component_index = chunk_component_indices[fragment]

            if component_index then
                local new_component = component_list[i]

                if new_component == nil then
                    new_component = true
                end

                local component_storage = chunk_component_storages[component_index]

                component_storage[place] = new_component
            end
        end
    end

    if chunk_has_insert_hooks then
        local chunk_fragment_list = chunk.__fragment_list
        local chunk_fragment_count = chunk.__fragment_count

        for chunk_fragment_index = 1, chunk_fragment_count do
            local fragment = chunk_fragment_list[chunk_fragment_index]

            ---@type evolved.set_hook?, evolved.insert_hook?
            local fragment_on_set, fragment_on_insert =
                __evolved_get(fragment, __ON_SET, __ON_INSERT)

            local component_index = chunk_component_indices[fragment]

            if component_index then
                local component_storage = chunk_component_storages[component_index]

                local new_component = component_storage[place]

                if fragment_on_set then
                    __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                end

                if fragment_on_insert then
                    __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                end
            else
                if fragment_on_set then
                    __defer_call_hook(fragment_on_set, entity, fragment)
                end

                if fragment_on_insert then
                    __defer_call_hook(fragment_on_insert, entity, fragment)
                end
            end
        end
    end
end

---
---
---
---
---

local __chunk_set
local __chunk_remove
local __chunk_clear
local __chunk_destroy

local __chunk_multi_set
local __chunk_multi_remove

---
---
---
---
---

---@param chunk evolved.chunk
local function __purge_chunk(chunk)
    if __defer_depth <= 0 then
        __error_fmt('purge operations should be deferred')
    end

    if chunk.__child_count > 0 or chunk.__entity_count > 0 then
        __error_fmt('chunk should be empty before purging')
    end

    local chunk_parent = chunk.__parent
    local chunk_fragment = chunk.__fragment

    local major_chunks = __major_chunks[chunk_fragment]
    local minor_chunks = __minor_chunks[chunk_fragment]

    local with_fragment_edges = chunk.__with_fragment_edges
    local without_fragment_edges = chunk.__without_fragment_edges

    if __root_chunks[chunk_fragment] == chunk then
        __root_chunks[chunk_fragment] = nil
    end

    if major_chunks then
        __assoc_list_remove(major_chunks, chunk)

        if major_chunks.__item_count == 0 then
            __major_chunks[chunk_fragment] = nil
        end
    end

    if minor_chunks then
        __assoc_list_remove(minor_chunks, chunk)

        if minor_chunks.__item_count == 0 then
            __minor_chunks[chunk_fragment] = nil
        end
    end

    if chunk_parent then
        chunk.__parent, chunk_parent.__child_count = nil, __assoc_list_remove_ex(
            chunk_parent.__child_set, chunk_parent.__child_list, chunk_parent.__child_count,
            chunk)
    end

    for with_fragment, with_fragment_edge in __lua_next, with_fragment_edges do
        with_fragment_edges[with_fragment] = nil
        with_fragment_edge.__without_fragment_edges[with_fragment] = nil
    end

    for without_fragment, without_fragment_edge in __lua_next, without_fragment_edges do
        without_fragment_edges[without_fragment] = nil
        without_fragment_edge.__with_fragment_edges[without_fragment] = nil
    end

    chunk.__unreachable_or_collected = true
end

---@param fragment evolved.fragment
---@param policy evolved.id
local function __purge_fragment(fragment, policy)
    if __defer_depth <= 0 then
        __error_fmt('purge operations should be deferred')
    end

    local minor_chunks = __minor_chunks[fragment]
    local minor_chunk_list = minor_chunks and minor_chunks.__item_list --[=[@as evolved.chunk[]]=]
    local minor_chunk_count = minor_chunks and minor_chunks.__item_count or 0 --[[@as integer]]

    if policy == __DESTROY_POLICY_DESTROY_ENTITY then
        for minor_chunk_index = minor_chunk_count, 1, -1 do
            local minor_chunk = minor_chunk_list[minor_chunk_index]
            _ = __chunk_destroy(minor_chunk)
        end
    elseif policy == __DESTROY_POLICY_REMOVE_FRAGMENT then
        for minor_chunk_index = minor_chunk_count, 1, -1 do
            local minor_chunk = minor_chunk_list[minor_chunk_index]
            _ = __chunk_remove(minor_chunk, fragment)
        end
    else
        __warning_fmt('unknown DESTROY_POLICY policy (%s) on (%s)',
            __id_name(policy), __id_name(fragment))
    end
end

---
---
---
---
---

---@param old_chunk evolved.chunk
---@param fragment evolved.fragment
---@param component evolved.component
__chunk_set = function(old_chunk, fragment, component)
    if __defer_depth <= 0 then
        __error_fmt('batched chunk operations should be deferred')
    end

    local new_chunk = __chunk_with_fragment(old_chunk, fragment)

    if not new_chunk then
        return
    end

    local old_entity_list = old_chunk.__entity_list
    local old_entity_count = old_chunk.__entity_count

    if old_entity_count == 0 then
        return
    end

    local old_component_count = old_chunk.__component_count
    local old_component_indices = old_chunk.__component_indices
    local old_component_storages = old_chunk.__component_storages
    local old_component_fragments = old_chunk.__component_fragments

    if old_chunk == new_chunk then
        local old_chunk_has_setup_hooks = old_chunk.__has_setup_hooks
        local old_chunk_has_assign_hooks = old_chunk.__has_assign_hooks

        ---@type evolved.default?, evolved.duplicate?, evolved.set_hook?, evolved.assign_hook?
        local fragment_default, fragment_duplicate, fragment_on_set, fragment_on_assign

        if old_chunk_has_setup_hooks or old_chunk_has_assign_hooks then
            fragment_default, fragment_duplicate, fragment_on_set, fragment_on_assign =
                __evolved_get(fragment, __DEFAULT, __DUPLICATE, __ON_SET, __ON_ASSIGN)
        end

        if fragment_on_set or fragment_on_assign then
            local old_component_index = old_component_indices[fragment]

            if old_component_index then
                local old_component_storage = old_component_storages[old_component_index]

                if fragment_duplicate then
                    for old_place = 1, old_entity_count do
                        local entity = old_entity_list[old_place]

                        local new_component = component
                        if new_component == nil then new_component = fragment_default end
                        if new_component ~= nil then new_component = fragment_duplicate(new_component) end
                        if new_component == nil then new_component = true end

                        local old_component = old_component_storage[old_place]
                        old_component_storage[old_place] = new_component

                        if fragment_on_set then
                            __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                        end

                        if fragment_on_assign then
                            __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                        end
                    end
                else
                    local new_component = component
                    if new_component == nil then new_component = fragment_default end
                    if new_component == nil then new_component = true end

                    for old_place = 1, old_entity_count do
                        local entity = old_entity_list[old_place]

                        local old_component = old_component_storage[old_place]
                        old_component_storage[old_place] = new_component

                        if fragment_on_set then
                            __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                        end

                        if fragment_on_assign then
                            __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                        end
                    end
                end
            else
                for old_place = 1, old_entity_count do
                    local entity = old_entity_list[old_place]

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment)
                    end

                    if fragment_on_assign then
                        __defer_call_hook(fragment_on_assign, entity, fragment)
                    end
                end
            end
        else
            local old_component_index = old_component_indices[fragment]

            if old_component_index then
                local old_component_storage = old_component_storages[old_component_index]

                if fragment_duplicate then
                    for old_place = 1, old_entity_count do
                        local new_component = component
                        if new_component == nil then new_component = fragment_default end
                        if new_component ~= nil then new_component = fragment_duplicate(new_component) end
                        if new_component == nil then new_component = true end
                        old_component_storage[old_place] = new_component
                    end
                else
                    local new_component = component
                    if new_component == nil then new_component = fragment_default end
                    if new_component == nil then new_component = true end
                    for old_place = 1, old_entity_count do
                        old_component_storage[old_place] = new_component
                    end
                end
            else
                -- nothing
            end
        end
    else
        local new_entity_list = new_chunk.__entity_list
        local new_entity_count = new_chunk.__entity_count

        local new_component_indices = new_chunk.__component_indices
        local new_component_storages = new_chunk.__component_storages

        local new_chunk_has_setup_hooks = new_chunk.__has_setup_hooks
        local new_chunk_has_insert_hooks = new_chunk.__has_insert_hooks

        ---@type evolved.default?, evolved.duplicate?, evolved.set_hook?, evolved.insert_hook?
        local fragment_default, fragment_duplicate, fragment_on_set, fragment_on_insert

        if new_chunk_has_setup_hooks or new_chunk_has_insert_hooks then
            fragment_default, fragment_duplicate, fragment_on_set, fragment_on_insert =
                __evolved_get(fragment, __DEFAULT, __DUPLICATE, __ON_SET, __ON_INSERT)
        end

        if new_entity_count == 0 then
            old_chunk.__entity_list, new_chunk.__entity_list =
                new_entity_list, old_entity_list

            old_entity_list, new_entity_list =
                new_entity_list, old_entity_list

            for old_ci = 1, old_component_count do
                local old_f = old_component_fragments[old_ci]
                local new_ci = new_component_indices[old_f]
                old_component_storages[old_ci], new_component_storages[new_ci] =
                    new_component_storages[new_ci], old_component_storages[old_ci]
            end

            new_chunk.__entity_count = old_entity_count
        else
            __lua_table_move(
                old_entity_list, 1, old_entity_count,
                new_entity_count + 1, new_entity_list)

            for old_ci = 1, old_component_count do
                local old_f = old_component_fragments[old_ci]
                local old_cs = old_component_storages[old_ci]
                local new_ci = new_component_indices[old_f]
                local new_cs = new_component_storages[new_ci]
                __lua_table_move(old_cs, 1, old_entity_count, new_entity_count + 1, new_cs)
            end

            new_chunk.__entity_count = new_entity_count + old_entity_count
        end

        do
            local entity_chunks = __entity_chunks
            local entity_places = __entity_places

            for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                local entity = new_entity_list[new_place]
                local entity_index = entity % 0x100000
                entity_chunks[entity_index] = new_chunk
                entity_places[entity_index] = new_place
            end

            __detach_all_entities(old_chunk)
        end

        if fragment_on_set or fragment_on_insert then
            local new_component_index = new_component_indices[fragment]

            if new_component_index then
                local new_component_storage = new_component_storages[new_component_index]

                if fragment_duplicate then
                    for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                        local entity = new_entity_list[new_place]

                        local new_component = component
                        if new_component == nil then new_component = fragment_default end
                        if new_component ~= nil then new_component = fragment_duplicate(new_component) end
                        if new_component == nil then new_component = true end

                        new_component_storage[new_place] = new_component

                        if fragment_on_set then
                            __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                        end

                        if fragment_on_insert then
                            __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                        end
                    end
                else
                    local new_component = component
                    if new_component == nil then new_component = fragment_default end
                    if new_component == nil then new_component = true end

                    for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                        local entity = new_entity_list[new_place]

                        new_component_storage[new_place] = new_component

                        if fragment_on_set then
                            __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                        end

                        if fragment_on_insert then
                            __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                        end
                    end
                end
            else
                for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                    local entity = new_entity_list[new_place]

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment)
                    end

                    if fragment_on_insert then
                        __defer_call_hook(fragment_on_insert, entity, fragment)
                    end
                end
            end
        else
            local new_component_index = new_component_indices[fragment]

            if new_component_index then
                local new_component_storage = new_component_storages[new_component_index]

                if fragment_duplicate then
                    for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                        local new_component = component
                        if new_component == nil then new_component = fragment_default end
                        if new_component ~= nil then new_component = fragment_duplicate(new_component) end
                        if new_component == nil then new_component = true end
                        new_component_storage[new_place] = new_component
                    end
                else
                    local new_component = component
                    if new_component == nil then new_component = fragment_default end
                    if new_component == nil then new_component = true end
                    for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                        new_component_storage[new_place] = new_component
                    end
                end
            else
                -- nothing
            end
        end

        __structural_changes = __structural_changes + 1
    end
end

---@param old_chunk evolved.chunk
---@param ... evolved.fragment fragments
__chunk_remove = function(old_chunk, ...)
    if __defer_depth <= 0 then
        __error_fmt('batched chunk operations should be deferred')
    end

    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return
    end

    local new_chunk = __chunk_without_fragments(old_chunk, ...)

    if old_chunk == new_chunk then
        return
    end

    local old_entity_list = old_chunk.__entity_list
    local old_entity_count = old_chunk.__entity_count

    if old_entity_count == 0 then
        return
    end

    local old_fragment_set = old_chunk.__fragment_set
    local old_component_indices = old_chunk.__component_indices
    local old_component_storages = old_chunk.__component_storages

    if old_chunk.__has_remove_hooks then
        ---@type table<evolved.fragment, boolean>
        local removed_set = __acquire_table(__table_pool_tag.fragment_set)

        for i = 1, fragment_count do
            ---@type evolved.fragment
            local fragment = __lua_select(i, ...)

            if not removed_set[fragment] and old_fragment_set[fragment] then
                removed_set[fragment] = true

                ---@type evolved.remove_hook?
                local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

                if fragment_on_remove then
                    local old_component_index = old_component_indices[fragment]

                    if old_component_index then
                        local old_component_storage = old_component_storages[old_component_index]

                        for old_place = 1, old_entity_count do
                            local entity = old_entity_list[old_place]
                            local old_component = old_component_storage[old_place]
                            __defer_call_hook(fragment_on_remove, entity, fragment, old_component)
                        end
                    else
                        for old_place = 1, old_entity_count do
                            local entity = old_entity_list[old_place]
                            __defer_call_hook(fragment_on_remove, entity, fragment)
                        end
                    end
                end
            end
        end

        __release_table(__table_pool_tag.fragment_set, removed_set)
    end

    if new_chunk then
        local new_entity_list = new_chunk.__entity_list
        local new_entity_count = new_chunk.__entity_count

        local new_component_count = new_chunk.__component_count
        local new_component_storages = new_chunk.__component_storages
        local new_component_fragments = new_chunk.__component_fragments

        if new_entity_count == 0 then
            old_chunk.__entity_list, new_chunk.__entity_list =
                new_entity_list, old_entity_list

            old_entity_list, new_entity_list =
                new_entity_list, old_entity_list

            for new_ci = 1, new_component_count do
                local new_f = new_component_fragments[new_ci]
                local old_ci = old_component_indices[new_f]
                old_component_storages[old_ci], new_component_storages[new_ci] =
                    new_component_storages[new_ci], old_component_storages[old_ci]
            end

            new_chunk.__entity_count = old_entity_count
        else
            __lua_table_move(
                old_entity_list, 1, old_entity_count,
                new_entity_count + 1, new_entity_list)

            for new_ci = 1, new_component_count do
                local new_f = new_component_fragments[new_ci]
                local new_cs = new_component_storages[new_ci]
                local old_ci = old_component_indices[new_f]
                local old_cs = old_component_storages[old_ci]
                __lua_table_move(old_cs, 1, old_entity_count, new_entity_count + 1, new_cs)
            end

            new_chunk.__entity_count = new_entity_count + old_entity_count
        end

        do
            local entity_chunks = __entity_chunks
            local entity_places = __entity_places

            for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                local entity = new_entity_list[new_place]
                local entity_index = entity % 0x100000
                entity_chunks[entity_index] = new_chunk
                entity_places[entity_index] = new_place
            end

            __detach_all_entities(old_chunk)
        end
    else
        local entity_chunks = __entity_chunks
        local entity_places = __entity_places

        for old_place = 1, old_entity_count do
            local entity = old_entity_list[old_place]
            local entity_index = entity % 0x100000
            entity_chunks[entity_index] = nil
            entity_places[entity_index] = nil
        end

        __detach_all_entities(old_chunk)
    end

    __structural_changes = __structural_changes + 1
end

---@param chunk evolved.chunk
__chunk_clear = function(chunk)
    if __defer_depth <= 0 then
        __error_fmt('batched chunk operations should be deferred')
    end

    local chunk_entity_list = chunk.__entity_list
    local chunk_entity_count = chunk.__entity_count

    if chunk_entity_count == 0 then
        return
    end

    if chunk.__has_remove_hooks then
        local chunk_fragment_list = chunk.__fragment_list
        local chunk_fragment_count = chunk.__fragment_count
        local chunk_component_indices = chunk.__component_indices
        local chunk_component_storages = chunk.__component_storages

        for chunk_fragment_index = 1, chunk_fragment_count do
            local fragment = chunk_fragment_list[chunk_fragment_index]

            ---@type evolved.remove_hook?
            local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

            if fragment_on_remove then
                local component_index = chunk_component_indices[fragment]

                if component_index then
                    local component_storage = chunk_component_storages[component_index]

                    for place = 1, chunk_entity_count do
                        local entity = chunk_entity_list[place]
                        local old_component = component_storage[place]
                        __defer_call_hook(fragment_on_remove, entity, fragment, old_component)
                    end
                else
                    for place = 1, chunk_entity_count do
                        local entity = chunk_entity_list[place]
                        __defer_call_hook(fragment_on_remove, entity, fragment)
                    end
                end
            end
        end
    end

    do
        local entity_chunks = __entity_chunks
        local entity_places = __entity_places

        for place = 1, chunk_entity_count do
            local entity = chunk_entity_list[place]
            local entity_index = entity % 0x100000
            entity_chunks[entity_index] = nil
            entity_places[entity_index] = nil
        end

        __detach_all_entities(chunk)
    end

    __structural_changes = __structural_changes + 1
end

---@param chunk evolved.chunk
__chunk_destroy = function(chunk)
    if __defer_depth <= 0 then
        __error_fmt('batched chunk operations should be deferred')
    end

    local chunk_entity_list = chunk.__entity_list
    local chunk_entity_count = chunk.__entity_count

    if chunk_entity_count == 0 then
        return
    end

    if chunk.__has_remove_hooks then
        local chunk_fragment_list = chunk.__fragment_list
        local chunk_fragment_count = chunk.__fragment_count
        local chunk_component_indices = chunk.__component_indices
        local chunk_component_storages = chunk.__component_storages

        for chunk_fragment_index = 1, chunk_fragment_count do
            local fragment = chunk_fragment_list[chunk_fragment_index]

            ---@type evolved.remove_hook?
            local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

            if fragment_on_remove then
                local component_index = chunk_component_indices[fragment]

                if component_index then
                    local component_storage = chunk_component_storages[component_index]

                    for place = 1, chunk_entity_count do
                        local entity = chunk_entity_list[place]
                        local old_component = component_storage[place]
                        __defer_call_hook(fragment_on_remove, entity, fragment, old_component)
                    end
                else
                    for place = 1, chunk_entity_count do
                        local entity = chunk_entity_list[place]
                        __defer_call_hook(fragment_on_remove, entity, fragment)
                    end
                end
            end
        end
    end

    do
        ---@type integer
        local purging_count = 0

        ---@type evolved.fragment[]
        local purging_fragments = __acquire_table(__table_pool_tag.fragment_list)

        ---@type evolved.fragment[]
        local purging_policies = __acquire_table(__table_pool_tag.fragment_list)

        local entity_chunks = __entity_chunks
        local entity_places = __entity_places

        for place = 1, chunk_entity_count do
            local entity = chunk_entity_list[place]
            local entity_index = entity % 0x100000

            if __minor_chunks[entity] then
                purging_count = purging_count + 1
                purging_fragments[purging_count] = entity
                purging_policies[purging_count] = __chunk_get_components(chunk, place, __DESTROY_POLICY)
                    or __DESTROY_POLICY_REMOVE_FRAGMENT
            end

            entity_chunks[entity_index] = nil
            entity_places[entity_index] = nil

            __release_id(entity)
        end

        __detach_all_entities(chunk)

        for purging_index = 1, purging_count do
            local purging_fragment = purging_fragments[purging_index]
            local purging_policy = purging_policies[purging_index]
            __purge_fragment(purging_fragment, purging_policy)
        end

        __release_table(__table_pool_tag.fragment_list, purging_fragments)
        __release_table(__table_pool_tag.fragment_list, purging_policies)
    end

    __structural_changes = __structural_changes + 1
end

---@param old_chunk evolved.chunk
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@param components evolved.component[]
__chunk_multi_set = function(old_chunk, fragments, fragment_count, components)
    if __defer_depth <= 0 then
        __error_fmt('batched chunk operations should be deferred')
    end

    if fragment_count == 0 then
        return
    end

    local new_chunk = __chunk_with_fragment_list(old_chunk, fragments, fragment_count)

    if not new_chunk then
        return
    end

    local old_entity_list = old_chunk.__entity_list
    local old_entity_count = old_chunk.__entity_count

    if old_entity_count == 0 then
        return
    end

    local old_fragment_set = old_chunk.__fragment_set
    local old_component_count = old_chunk.__component_count
    local old_component_indices = old_chunk.__component_indices
    local old_component_storages = old_chunk.__component_storages
    local old_component_fragments = old_chunk.__component_fragments

    if old_chunk == new_chunk then
        local old_chunk_has_setup_hooks = old_chunk.__has_setup_hooks
        local old_chunk_has_assign_hooks = old_chunk.__has_assign_hooks

        for i = 1, fragment_count do
            local fragment = fragments[i]

            ---@type evolved.default?, evolved.duplicate?, evolved.set_hook?, evolved.assign_hook?
            local fragment_default, fragment_duplicate, fragment_on_set, fragment_on_assign

            if old_chunk_has_setup_hooks or old_chunk_has_assign_hooks then
                fragment_default, fragment_duplicate, fragment_on_set, fragment_on_assign =
                    __evolved_get(fragment, __DEFAULT, __DUPLICATE, __ON_SET, __ON_ASSIGN)
            end

            if fragment_on_set or fragment_on_assign then
                local old_component_index = old_component_indices[fragment]

                if old_component_index then
                    local old_component_storage = old_component_storages[old_component_index]

                    if fragment_duplicate then
                        for old_place = 1, old_entity_count do
                            local entity = old_entity_list[old_place]

                            local new_component = components[i]
                            if new_component == nil then new_component = fragment_default end
                            if new_component ~= nil then new_component = fragment_duplicate(new_component) end
                            if new_component == nil then new_component = true end

                            local old_component = old_component_storage[old_place]
                            old_component_storage[old_place] = new_component

                            if fragment_on_set then
                                __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                            end

                            if fragment_on_assign then
                                __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                            end
                        end
                    else
                        local new_component = components[i]
                        if new_component == nil then new_component = fragment_default end
                        if new_component == nil then new_component = true end

                        for old_place = 1, old_entity_count do
                            local entity = old_entity_list[old_place]

                            local old_component = old_component_storage[old_place]
                            old_component_storage[old_place] = new_component

                            if fragment_on_set then
                                __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                            end

                            if fragment_on_assign then
                                __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                            end
                        end
                    end
                else
                    for old_place = 1, old_entity_count do
                        local entity = old_entity_list[old_place]

                        if fragment_on_set then
                            __defer_call_hook(fragment_on_set, entity, fragment)
                        end

                        if fragment_on_assign then
                            __defer_call_hook(fragment_on_assign, entity, fragment)
                        end
                    end
                end
            else
                local old_component_index = old_component_indices[fragment]

                if old_component_index then
                    local old_component_storage = old_component_storages[old_component_index]

                    if fragment_duplicate then
                        for old_place = 1, old_entity_count do
                            local new_component = components[i]
                            if new_component == nil then new_component = fragment_default end
                            if new_component ~= nil then new_component = fragment_duplicate(new_component) end
                            if new_component == nil then new_component = true end
                            old_component_storage[old_place] = new_component
                        end
                    else
                        local new_component = components[i]
                        if new_component == nil then new_component = fragment_default end
                        if new_component == nil then new_component = true end
                        for old_place = 1, old_entity_count do
                            old_component_storage[old_place] = new_component
                        end
                    end
                else
                    -- nothing
                end
            end
        end
    else
        local new_entity_list = new_chunk.__entity_list
        local new_entity_count = new_chunk.__entity_count

        local new_component_indices = new_chunk.__component_indices
        local new_component_storages = new_chunk.__component_storages

        local new_chunk_has_setup_hooks = new_chunk.__has_setup_hooks
        local new_chunk_has_assign_hooks = new_chunk.__has_assign_hooks
        local new_chunk_has_insert_hooks = new_chunk.__has_insert_hooks

        if new_entity_count == 0 then
            old_chunk.__entity_list, new_chunk.__entity_list =
                new_entity_list, old_entity_list

            old_entity_list, new_entity_list =
                new_entity_list, old_entity_list

            for old_ci = 1, old_component_count do
                local old_f = old_component_fragments[old_ci]
                local new_ci = new_component_indices[old_f]
                old_component_storages[old_ci], new_component_storages[new_ci] =
                    new_component_storages[new_ci], old_component_storages[old_ci]
            end

            new_chunk.__entity_count = old_entity_count
        else
            __lua_table_move(
                old_entity_list, 1, old_entity_count,
                new_entity_count + 1, new_entity_list)

            for old_ci = 1, old_component_count do
                local old_f = old_component_fragments[old_ci]
                local old_cs = old_component_storages[old_ci]
                local new_ci = new_component_indices[old_f]
                local new_cs = new_component_storages[new_ci]
                __lua_table_move(old_cs, 1, old_entity_count, new_entity_count + 1, new_cs)
            end

            new_chunk.__entity_count = new_entity_count + old_entity_count
        end

        do
            local entity_chunks = __entity_chunks
            local entity_places = __entity_places

            for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                local entity = new_entity_list[new_place]
                local entity_index = entity % 0x100000
                entity_chunks[entity_index] = new_chunk
                entity_places[entity_index] = new_place
            end

            __detach_all_entities(old_chunk)
        end

        ---@type table<evolved.fragment, boolean>
        local inserted_set = __acquire_table(__table_pool_tag.fragment_set)

        for i = 1, fragment_count do
            local fragment = fragments[i]

            ---@type evolved.default?, evolved.duplicate?, evolved.set_hook?, evolved.assign_hook?, evolved.insert_hook?
            local fragment_default, fragment_duplicate, fragment_on_set, fragment_on_assign, fragment_on_insert

            if new_chunk_has_setup_hooks or new_chunk_has_assign_hooks or new_chunk_has_insert_hooks then
                fragment_default, fragment_duplicate, fragment_on_set, fragment_on_assign, fragment_on_insert =
                    __evolved_get(fragment, __DEFAULT, __DUPLICATE, __ON_SET, __ON_ASSIGN, __ON_INSERT)
            end

            if inserted_set[fragment] or old_fragment_set[fragment] then
                if fragment_on_set or fragment_on_assign then
                    local new_component_index = new_component_indices[fragment]

                    if new_component_index then
                        local new_component_storage = new_component_storages[new_component_index]

                        if fragment_duplicate then
                            for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                                local entity = new_entity_list[new_place]

                                local new_component = components[i]
                                if new_component == nil then new_component = fragment_default end
                                if new_component ~= nil then new_component = fragment_duplicate(new_component) end
                                if new_component == nil then new_component = true end

                                local old_component = new_component_storage[new_place]
                                new_component_storage[new_place] = new_component

                                if fragment_on_set then
                                    __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                                end

                                if fragment_on_assign then
                                    __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                                end
                            end
                        else
                            local new_component = components[i]
                            if new_component == nil then new_component = fragment_default end
                            if new_component == nil then new_component = true end

                            for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                                local entity = new_entity_list[new_place]

                                local old_component = new_component_storage[new_place]
                                new_component_storage[new_place] = new_component

                                if fragment_on_set then
                                    __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                                end

                                if fragment_on_assign then
                                    __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                                end
                            end
                        end
                    else
                        for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                            local entity = new_entity_list[new_place]

                            if fragment_on_set then
                                __defer_call_hook(fragment_on_set, entity, fragment)
                            end

                            if fragment_on_assign then
                                __defer_call_hook(fragment_on_assign, entity, fragment)
                            end
                        end
                    end
                else
                    local new_component_index = new_component_indices[fragment]

                    if new_component_index then
                        local new_component_storage = new_component_storages[new_component_index]

                        if fragment_duplicate then
                            for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                                local new_component = components[i]
                                if new_component == nil then new_component = fragment_default end
                                if new_component ~= nil then new_component = fragment_duplicate(new_component) end
                                if new_component == nil then new_component = true end
                                new_component_storage[new_place] = new_component
                            end
                        else
                            local new_component = components[i]
                            if new_component == nil then new_component = fragment_default end
                            if new_component == nil then new_component = true end
                            for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                                new_component_storage[new_place] = new_component
                            end
                        end
                    else
                        -- nothing
                    end
                end
            else
                inserted_set[fragment] = true

                if fragment_on_set or fragment_on_insert then
                    local new_component_index = new_component_indices[fragment]

                    if new_component_index then
                        local new_component_storage = new_component_storages[new_component_index]

                        if fragment_duplicate then
                            for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                                local entity = new_entity_list[new_place]

                                local new_component = components[i]
                                if new_component == nil then new_component = fragment_default end
                                if new_component ~= nil then new_component = fragment_duplicate(new_component) end
                                if new_component == nil then new_component = true end

                                new_component_storage[new_place] = new_component

                                if fragment_on_set then
                                    __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                                end

                                if fragment_on_insert then
                                    __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                                end
                            end
                        else
                            local new_component = components[i]
                            if new_component == nil then new_component = fragment_default end
                            if new_component == nil then new_component = true end

                            for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                                local entity = new_entity_list[new_place]

                                new_component_storage[new_place] = new_component

                                if fragment_on_set then
                                    __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                                end

                                if fragment_on_insert then
                                    __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                                end
                            end
                        end
                    else
                        for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                            local entity = new_entity_list[new_place]

                            if fragment_on_set then
                                __defer_call_hook(fragment_on_set, entity, fragment)
                            end

                            if fragment_on_insert then
                                __defer_call_hook(fragment_on_insert, entity, fragment)
                            end
                        end
                    end
                else
                    local new_component_index = new_component_indices[fragment]

                    if new_component_index then
                        local new_component_storage = new_component_storages[new_component_index]

                        if fragment_duplicate then
                            for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                                local new_component = components[i]
                                if new_component == nil then new_component = fragment_default end
                                if new_component ~= nil then new_component = fragment_duplicate(new_component) end
                                if new_component == nil then new_component = true end
                                new_component_storage[new_place] = new_component
                            end
                        else
                            local new_component = components[i]
                            if new_component == nil then new_component = fragment_default end
                            if new_component == nil then new_component = true end
                            for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                                new_component_storage[new_place] = new_component
                            end
                        end
                    else
                        -- nothing
                    end
                end
            end
        end

        __release_table(__table_pool_tag.fragment_set, inserted_set)

        __structural_changes = __structural_changes + 1
    end
end

---@param old_chunk evolved.chunk
---@param fragments evolved.fragment[]
---@param fragment_count integer
__chunk_multi_remove = function(old_chunk, fragments, fragment_count)
    if __defer_depth <= 0 then
        __error_fmt('batched chunk operations should be deferred')
    end

    if fragment_count == 0 then
        return
    end

    local new_chunk = __chunk_without_fragment_list(old_chunk, fragments, fragment_count)

    if old_chunk == new_chunk then
        return
    end

    local old_entity_list = old_chunk.__entity_list
    local old_entity_count = old_chunk.__entity_count

    if old_entity_count == 0 then
        return
    end

    local old_fragment_set = old_chunk.__fragment_set
    local old_component_indices = old_chunk.__component_indices
    local old_component_storages = old_chunk.__component_storages

    if old_chunk.__has_remove_hooks then
        ---@type table<evolved.fragment, boolean>
        local removed_set = __acquire_table(__table_pool_tag.fragment_set)

        for i = 1, fragment_count do
            local fragment = fragments[i]

            if not removed_set[fragment] and old_fragment_set[fragment] then
                removed_set[fragment] = true

                ---@type evolved.remove_hook?
                local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

                if fragment_on_remove then
                    local old_component_index = old_component_indices[fragment]

                    if old_component_index then
                        local old_component_storage = old_component_storages[old_component_index]

                        for old_place = 1, old_entity_count do
                            local entity = old_entity_list[old_place]
                            local old_component = old_component_storage[old_place]
                            __defer_call_hook(fragment_on_remove, entity, fragment, old_component)
                        end
                    else
                        for old_place = 1, old_entity_count do
                            local entity = old_entity_list[old_place]
                            __defer_call_hook(fragment_on_remove, entity, fragment)
                        end
                    end
                end
            end
        end

        __release_table(__table_pool_tag.fragment_set, removed_set)
    end

    if new_chunk then
        local new_entity_list = new_chunk.__entity_list
        local new_entity_count = new_chunk.__entity_count

        local new_component_count = new_chunk.__component_count
        local new_component_storages = new_chunk.__component_storages
        local new_component_fragments = new_chunk.__component_fragments

        if new_entity_count == 0 then
            old_chunk.__entity_list, new_chunk.__entity_list =
                new_entity_list, old_entity_list

            old_entity_list, new_entity_list =
                new_entity_list, old_entity_list

            for new_ci = 1, new_component_count do
                local new_f = new_component_fragments[new_ci]
                local old_ci = old_component_indices[new_f]
                old_component_storages[old_ci], new_component_storages[new_ci] =
                    new_component_storages[new_ci], old_component_storages[old_ci]
            end

            new_chunk.__entity_count = old_entity_count
        else
            __lua_table_move(
                old_entity_list, 1, old_entity_count,
                new_entity_count + 1, new_entity_list)

            for new_ci = 1, new_component_count do
                local new_f = new_component_fragments[new_ci]
                local new_cs = new_component_storages[new_ci]
                local old_ci = old_component_indices[new_f]
                local old_cs = old_component_storages[old_ci]
                __lua_table_move(old_cs, 1, old_entity_count, new_entity_count + 1, new_cs)
            end

            new_chunk.__entity_count = new_entity_count + old_entity_count
        end

        do
            local entity_chunks = __entity_chunks
            local entity_places = __entity_places

            for new_place = new_entity_count + 1, new_entity_count + old_entity_count do
                local entity = new_entity_list[new_place]
                local entity_index = entity % 0x100000
                entity_chunks[entity_index] = new_chunk
                entity_places[entity_index] = new_place
            end

            __detach_all_entities(old_chunk)
        end
    else
        local entity_chunks = __entity_chunks
        local entity_places = __entity_places

        for old_place = 1, old_entity_count do
            local entity = old_entity_list[old_place]
            local entity_index = entity % 0x100000
            entity_chunks[entity_index] = nil
            entity_places[entity_index] = nil
        end

        __detach_all_entities(old_chunk)
    end

    __structural_changes = __structural_changes + 1
end

---
---
---
---
---

---@param system evolved.system
local function __system_process(system)
    local query, execute, prologue, epilogue = __evolved_get(system,
        __QUERY, __EXECUTE, __PROLOGUE, __EPILOGUE)

    if prologue then
        local success, result = __lua_pcall(prologue)

        if not success then
            __error_fmt('system prologue failed: %s', result)
        end
    end

    if query and execute then
        __evolved_defer()
        do
            for chunk, entity_list, entity_count in __evolved_execute(query) do
                local success, result = __lua_pcall(execute, chunk, entity_list, entity_count)

                if not success then
                    __evolved_commit()
                    __error_fmt('system execution failed: %s', result)
                end
            end
        end
        __evolved_commit()
    end

    if epilogue then
        local success, result = __lua_pcall(epilogue)

        if not success then
            __error_fmt('system epilogue failed: %s', result)
        end
    end
end

---@param group evolved.group
local function __group_process(group)
    ---@type evolved.prologue?, evolved.epilogue?
    local prologue, epilogue = __evolved_get(group,
        __PROLOGUE, __EPILOGUE)

    if prologue then
        local success, result = __lua_pcall(prologue)

        if not success then
            __error_fmt('group prologue failed: %s', result)
        end
    end

    do
        local group_systems = __group_systems[group]
        local group_system_list = group_systems and group_systems.__item_list --[=[@as evolved.system[]]=]
        local group_system_count = group_systems and group_systems.__item_count or 0 --[[@as integer]]

        for group_system_index = 1, group_system_count do
            local group_system = group_system_list[group_system_index]
            if not __evolved_has(group_system, __DISABLED) then
                __system_process(group_system)
            end
        end
    end

    if epilogue then
        local success, result = __lua_pcall(epilogue)

        if not success then
            __error_fmt('group epilogue failed: %s', result)
        end
    end
end

---@param phase evolved.phase
local function __phase_process(phase)
    ---@type evolved.prologue?, evolved.epilogue?
    local prologue, epilogue = __evolved_get(phase,
        __PROLOGUE, __EPILOGUE)

    if prologue then
        local success, result = __lua_pcall(prologue)

        if not success then
            __error_fmt('phase prologue failed: %s', result)
        end
    end

    do
        local phase_groups = __phase_groups[phase]
        local phase_group_set = phase_groups and phase_groups.__item_set --[[@as table<evolved.group, integer>]]
        local phase_group_list = phase_groups and phase_groups.__item_list --[=[@as evolved.group[]]=]
        local phase_group_count = phase_groups and phase_groups.__item_count or 0 --[[@as integer]]

        ---@type evolved.group[]
        local sorted_group_list = __acquire_table(__table_pool_tag.group_list)
        local sorted_group_count = 0

        ---@type integer[]
        local sorting_marks = __acquire_table(__table_pool_tag.sorting_marks)

        ---@type evolved.group[]
        local sorting_stack = __acquire_table(__table_pool_tag.sorting_stack)
        local sorting_stack_size = phase_group_count

        for phase_group_index = 1, phase_group_count do
            sorting_marks[phase_group_index] = 0
            local phase_group_rev_index = phase_group_count - phase_group_index + 1
            sorting_stack[phase_group_index] = phase_group_list[phase_group_rev_index]
        end

        while sorting_stack_size > 0 do
            local group = sorting_stack[sorting_stack_size]

            local group_mark_index = phase_group_set[group]
            local group_mark = sorting_marks[group_mark_index]

            if not group_mark then
                -- the group has already been added to the sorted list
                sorting_stack[sorting_stack_size] = nil
                sorting_stack_size = sorting_stack_size - 1
            elseif group_mark == 0 then
                sorting_marks[group_mark_index] = 1

                local dependencies = __group_dependencies[group]
                local dependency_list = dependencies and dependencies.__item_list --[=[@as evolved.group[]]=]
                local dependency_count = dependencies and dependencies.__item_count or 0 --[[@as integer]]

                for dependency_index = dependency_count, 1, -1 do
                    local dependency = dependency_list[dependency_index]
                    local dependency_mark_index = phase_group_set[dependency]

                    if not dependency_mark_index then
                        -- the dependency is not from this phase
                    else
                        local dependency_mark = sorting_marks[dependency_mark_index]

                        if not dependency_mark then
                            -- the dependency has already been added to the sorted list
                        elseif dependency_mark == 0 then
                            sorting_stack_size = sorting_stack_size + 1
                            sorting_stack[sorting_stack_size] = dependency
                        elseif dependency_mark == 1 then
                            local sorting_cycle_path = '' .. __id_name(dependency)

                            for cycled_group_index = sorting_stack_size, 1, -1 do
                                local cycled_group = sorting_stack[cycled_group_index]

                                local cycled_group_mark_index = phase_group_set[cycled_group]
                                local cycled_group_mark = sorting_marks[cycled_group_mark_index]

                                if cycled_group_mark == 1 then
                                    sorting_cycle_path = string.format('%s -> %s',
                                        sorting_cycle_path, __id_name(cycled_group))

                                    if cycled_group == dependency then
                                        break
                                    end
                                end
                            end

                            __error_fmt('cyclic dependency detected: %s', sorting_cycle_path)
                        end
                    end
                end
            elseif group_mark == 1 then
                sorting_marks[group_mark_index] = nil

                sorted_group_count = sorted_group_count + 1
                sorted_group_list[sorted_group_count] = group

                sorting_stack[sorting_stack_size] = nil
                sorting_stack_size = sorting_stack_size - 1
            end
        end

        for sorted_group_index = 1, sorted_group_count do
            local sorted_group = sorted_group_list[sorted_group_index]
            if not __evolved_has(sorted_group, __DISABLED) then
                __group_process(sorted_group)
            end
        end

        __release_table(__table_pool_tag.group_list, sorted_group_list)
        __release_table(__table_pool_tag.sorting_marks, sorting_marks, true)
        __release_table(__table_pool_tag.sorting_stack, sorting_stack, true)
    end

    if epilogue then
        local success, result = __lua_pcall(epilogue)

        if not success then
            __error_fmt('phase epilogue failed: %s', result)
        end
    end
end

---
---
---
---
---

---@enum evolved.defer_op
local __defer_op = {
    set = 1,
    remove = 2,
    clear = 3,
    destroy = 4,

    multi_set = 5,
    multi_remove = 6,

    batch_set = 7,
    batch_remove = 8,
    batch_clear = 9,
    batch_destroy = 10,

    batch_multi_set = 11,
    batch_multi_remove = 12,

    spawn_entity_at = 13,
    spawn_entity_with = 14,

    call_hook = 15,

    __count = 15,
}

---@type table<evolved.defer_op, fun(bytes: any[], index: integer): integer>
local __defer_ops = __lua_table_new(__defer_op.__count, 0)

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
__defer_set = function(entity, fragment, component)
    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.set
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment
    bytecode[length + 4] = component

    __defer_length = length + 4
end

__defer_ops[__defer_op.set] = function(bytes, index)
    local entity = bytes[index + 0]
    local fragment = bytes[index + 1]
    local component = bytes[index + 2]

    __evolved_set(entity, fragment, component)

    return 3
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
__defer_remove = function(entity, ...)
    local fragment_count = __lua_select('#', ...)
    if fragment_count == 0 then return end

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.remove
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment_count

    if fragment_count == 0 then
        -- nothing
    elseif fragment_count == 1 then
        local f1 = ...
        bytecode[length + 4] = f1
    elseif fragment_count == 2 then
        local f1, f2 = ...
        bytecode[length + 4] = f1
        bytecode[length + 5] = f2
    elseif fragment_count == 3 then
        local f1, f2, f3 = ...
        bytecode[length + 4] = f1
        bytecode[length + 5] = f2
        bytecode[length + 6] = f3
    elseif fragment_count == 4 then
        local f1, f2, f3, f4 = ...
        bytecode[length + 4] = f1
        bytecode[length + 5] = f2
        bytecode[length + 6] = f3
        bytecode[length + 7] = f4
    else
        local f1, f2, f3, f4 = ...
        bytecode[length + 4] = f1
        bytecode[length + 5] = f2
        bytecode[length + 6] = f3
        bytecode[length + 7] = f4
        for i = 5, fragment_count do
            bytecode[length + 3 + i] = __lua_select(i, ...)
        end
    end

    __defer_length = length + 3 + fragment_count
end

__defer_ops[__defer_op.remove] = function(bytes, index)
    local entity = bytes[index + 0]
    local fragment_count = bytes[index + 1]

    if fragment_count == 0 then
        -- nothing
    elseif fragment_count == 1 then
        local f1 = bytes[index + 2]
        __evolved_remove(entity, f1)
    elseif fragment_count == 2 then
        local f1, f2 = bytes[index + 2], bytes[index + 3]
        __evolved_remove(entity, f1, f2)
    elseif fragment_count == 3 then
        local f1, f2, f3 = bytes[index + 2], bytes[index + 3], bytes[index + 4]
        __evolved_remove(entity, f1, f2, f3)
    elseif fragment_count == 4 then
        local f1, f2, f3, f4 = bytes[index + 2], bytes[index + 3], bytes[index + 4], bytes[index + 5]
        __evolved_remove(entity, f1, f2, f3, f4)
    else
        local f1, f2, f3, f4 = bytes[index + 2], bytes[index + 3], bytes[index + 4], bytes[index + 5]
        __evolved_remove(entity, f1, f2, f3, f4,
            __lua_table_unpack(bytes, index + 6, index + 1 + fragment_count))
    end

    return 2 + fragment_count
end

---@param ... evolved.entity entities
__defer_clear = function(...)
    local entity_count = __lua_select('#', ...)
    if entity_count == 0 then return end

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.clear
    bytecode[length + 2] = entity_count

    if entity_count == 0 then
        -- nothing
    elseif entity_count == 1 then
        local e1 = ...
        bytecode[length + 3] = e1
    elseif entity_count == 2 then
        local e1, e2 = ...
        bytecode[length + 3] = e1
        bytecode[length + 4] = e2
    elseif entity_count == 3 then
        local e1, e2, e3 = ...
        bytecode[length + 3] = e1
        bytecode[length + 4] = e2
        bytecode[length + 5] = e3
    elseif entity_count == 4 then
        local e1, e2, e3, e4 = ...
        bytecode[length + 3] = e1
        bytecode[length + 4] = e2
        bytecode[length + 5] = e3
        bytecode[length + 6] = e4
    else
        local e1, e2, e3, e4 = ...
        bytecode[length + 3] = e1
        bytecode[length + 4] = e2
        bytecode[length + 5] = e3
        bytecode[length + 6] = e4
        for i = 5, entity_count do
            bytecode[length + 2 + i] = __lua_select(i, ...)
        end
    end

    __defer_length = length + 2 + entity_count
end

__defer_ops[__defer_op.clear] = function(bytes, index)
    local entity_count = bytes[index + 0]

    if entity_count == 0 then
        -- nothing
    elseif entity_count == 1 then
        local e1 = bytes[index + 1]
        __evolved_clear(e1)
    elseif entity_count == 2 then
        local e1, e2 = bytes[index + 1], bytes[index + 2]
        __evolved_clear(e1, e2)
    elseif entity_count == 3 then
        local e1, e2, e3 = bytes[index + 1], bytes[index + 2], bytes[index + 3]
        __evolved_clear(e1, e2, e3)
    elseif entity_count == 4 then
        local e1, e2, e3, e4 = bytes[index + 1], bytes[index + 2], bytes[index + 3], bytes[index + 4]
        __evolved_clear(e1, e2, e3, e4)
    else
        local e1, e2, e3, e4 = bytes[index + 1], bytes[index + 2], bytes[index + 3], bytes[index + 4]
        __evolved_clear(e1, e2, e3, e4,
            __lua_table_unpack(bytes, index + 5, index + 0 + entity_count))
    end

    return 1 + entity_count
end

---@param ... evolved.entity entities
__defer_destroy = function(...)
    local entity_count = __lua_select('#', ...)
    if entity_count == 0 then return end

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.destroy
    bytecode[length + 2] = entity_count

    if entity_count == 0 then
        -- nothing
    elseif entity_count == 1 then
        local e1 = ...
        bytecode[length + 3] = e1
    elseif entity_count == 2 then
        local e1, e2 = ...
        bytecode[length + 3] = e1
        bytecode[length + 4] = e2
    elseif entity_count == 3 then
        local e1, e2, e3 = ...
        bytecode[length + 3] = e1
        bytecode[length + 4] = e2
        bytecode[length + 5] = e3
    elseif entity_count == 4 then
        local e1, e2, e3, e4 = ...
        bytecode[length + 3] = e1
        bytecode[length + 4] = e2
        bytecode[length + 5] = e3
        bytecode[length + 6] = e4
    else
        local e1, e2, e3, e4 = ...
        bytecode[length + 3] = e1
        bytecode[length + 4] = e2
        bytecode[length + 5] = e3
        bytecode[length + 6] = e4
        for i = 5, entity_count do
            bytecode[length + 2 + i] = __lua_select(i, ...)
        end
    end

    __defer_length = length + 2 + entity_count
end

__defer_ops[__defer_op.destroy] = function(bytes, index)
    local entity_count = bytes[index + 0]

    if entity_count == 0 then
        -- nothing
    elseif entity_count == 1 then
        local e1 = bytes[index + 1]
        __evolved_destroy(e1)
    elseif entity_count == 2 then
        local e1, e2 = bytes[index + 1], bytes[index + 2]
        __evolved_destroy(e1, e2)
    elseif entity_count == 3 then
        local e1, e2, e3 = bytes[index + 1], bytes[index + 2], bytes[index + 3]
        __evolved_destroy(e1, e2, e3)
    elseif entity_count == 4 then
        local e1, e2, e3, e4 = bytes[index + 1], bytes[index + 2], bytes[index + 3], bytes[index + 4]
        __evolved_destroy(e1, e2, e3, e4)
    else
        local e1, e2, e3, e4 = bytes[index + 1], bytes[index + 2], bytes[index + 3], bytes[index + 4]
        __evolved_destroy(e1, e2, e3, e4,
            __lua_table_unpack(bytes, index + 5, index + 0 + entity_count))
    end

    return 1 + entity_count
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@param components evolved.component[]
---@param component_count integer
__defer_multi_set = function(entity, fragments, fragment_count, components, component_count)
    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    __lua_table_move(fragments, 1, fragment_count, 1, fragment_list)

    ---@type evolved.component[]
    local component_list = __acquire_table(__table_pool_tag.component_list)
    __lua_table_move(components, 1, component_count, 1, component_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.multi_set
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment_list
    bytecode[length + 4] = component_list

    __defer_length = length + 4
end

__defer_ops[__defer_op.multi_set] = function(bytes, index)
    local entity = bytes[index + 0]
    local fragments = bytes[index + 1]
    local components = bytes[index + 2]

    __evolved_multi_set(entity, fragments, components)
    __release_table(__table_pool_tag.fragment_list, fragments)
    __release_table(__table_pool_tag.component_list, components)

    return 3
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@param fragment_count integer
__defer_multi_remove = function(entity, fragments, fragment_count)
    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    __lua_table_move(fragments, 1, fragment_count, 1, fragment_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.multi_remove
    bytecode[length + 2] = entity
    bytecode[length + 3] = fragment_list

    __defer_length = length + 3
end

__defer_ops[__defer_op.multi_remove] = function(bytes, index)
    local entity = bytes[index + 0]
    local fragments = bytes[index + 1]

    __evolved_multi_remove(entity, fragments)
    __release_table(__table_pool_tag.fragment_list, fragments)

    return 2
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param component evolved.component
__defer_batch_set = function(query, fragment, component)
    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_set
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment
    bytecode[length + 4] = component

    __defer_length = length + 4
end

__defer_ops[__defer_op.batch_set] = function(bytes, index)
    local query = bytes[index + 0]
    local fragment = bytes[index + 1]
    local component = bytes[index + 2]

    __evolved_batch_set(query, fragment, component)

    return 3
end

---@param query evolved.query
---@param ... evolved.fragment fragments
__defer_batch_remove = function(query, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local fragment_count = __lua_select('#', ...)

    bytecode[length + 1] = __defer_op.batch_remove
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment_count

    if fragment_count == 0 then
        -- nothing
    elseif fragment_count == 1 then
        local f1 = ...
        bytecode[length + 4] = f1
    elseif fragment_count == 2 then
        local f1, f2 = ...
        bytecode[length + 4] = f1
        bytecode[length + 5] = f2
    elseif fragment_count == 3 then
        local f1, f2, f3 = ...
        bytecode[length + 4] = f1
        bytecode[length + 5] = f2
        bytecode[length + 6] = f3
    elseif fragment_count == 4 then
        local f1, f2, f3, f4 = ...
        bytecode[length + 4] = f1
        bytecode[length + 5] = f2
        bytecode[length + 6] = f3
        bytecode[length + 7] = f4
    else
        local f1, f2, f3, f4 = ...
        bytecode[length + 4] = f1
        bytecode[length + 5] = f2
        bytecode[length + 6] = f3
        bytecode[length + 7] = f4
        for i = 5, fragment_count do
            bytecode[length + 3 + i] = __lua_select(i, ...)
        end
    end

    __defer_length = length + 3 + fragment_count
end

__defer_ops[__defer_op.batch_remove] = function(bytes, index)
    local query = bytes[index + 0]
    local fragment_count = bytes[index + 1]

    if fragment_count == 0 then
        -- nothing
    elseif fragment_count == 1 then
        local f1 = bytes[index + 2]
        __evolved_batch_remove(query, f1)
    elseif fragment_count == 2 then
        local f1, f2 = bytes[index + 2], bytes[index + 3]
        __evolved_batch_remove(query, f1, f2)
    elseif fragment_count == 3 then
        local f1, f2, f3 = bytes[index + 2], bytes[index + 3], bytes[index + 4]
        __evolved_batch_remove(query, f1, f2, f3)
    elseif fragment_count == 4 then
        local f1, f2, f3, f4 = bytes[index + 2], bytes[index + 3], bytes[index + 4], bytes[index + 5]
        __evolved_batch_remove(query, f1, f2, f3, f4)
    else
        local f1, f2, f3, f4 = bytes[index + 2], bytes[index + 3], bytes[index + 4], bytes[index + 5]
        __evolved_batch_remove(query, f1, f2, f3, f4,
            __lua_table_unpack(bytes, index + 6, index + 1 + fragment_count))
    end

    return 2 + fragment_count
end

---@param ... evolved.query chunks_or_queries
__defer_batch_clear = function(...)
    local argument_count = __lua_select('#', ...)
    if argument_count == 0 then return end

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_clear
    bytecode[length + 2] = argument_count

    if argument_count == 0 then
        -- nothing
    elseif argument_count == 1 then
        local a1 = ...
        bytecode[length + 3] = a1
    elseif argument_count == 2 then
        local a1, a2 = ...
        bytecode[length + 3] = a1
        bytecode[length + 4] = a2
    elseif argument_count == 3 then
        local a1, a2, a3 = ...
        bytecode[length + 3] = a1
        bytecode[length + 4] = a2
        bytecode[length + 5] = a3
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = ...
        bytecode[length + 3] = a1
        bytecode[length + 4] = a2
        bytecode[length + 5] = a3
        bytecode[length + 6] = a4
    else
        local a1, a2, a3, a4 = ...
        bytecode[length + 3] = a1
        bytecode[length + 4] = a2
        bytecode[length + 5] = a3
        bytecode[length + 6] = a4
        for i = 5, argument_count do
            bytecode[length + 2 + i] = __lua_select(i, ...)
        end
    end

    __defer_length = length + 2 + argument_count
end

__defer_ops[__defer_op.batch_clear] = function(bytes, index)
    local argument_count = bytes[index + 0]

    if argument_count == 0 then
        -- nothing
    elseif argument_count == 1 then
        local a1 = bytes[index + 1]
        __evolved_batch_clear(a1)
    elseif argument_count == 2 then
        local a1, a2 = bytes[index + 1], bytes[index + 2]
        __evolved_batch_clear(a1, a2)
    elseif argument_count == 3 then
        local a1, a2, a3 = bytes[index + 1], bytes[index + 2], bytes[index + 3]
        __evolved_batch_clear(a1, a2, a3)
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = bytes[index + 1], bytes[index + 2], bytes[index + 3], bytes[index + 4]
        __evolved_batch_clear(a1, a2, a3, a4)
    else
        local a1, a2, a3, a4 = bytes[index + 1], bytes[index + 2], bytes[index + 3], bytes[index + 4]
        __evolved_batch_clear(a1, a2, a3, a4,
            __lua_table_unpack(bytes, index + 5, index + 0 + argument_count))
    end

    return 1 + argument_count
end

---@param ... evolved.query chunks_or_queries
__defer_batch_destroy = function(...)
    local argument_count = __lua_select('#', ...)
    if argument_count == 0 then return end

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_destroy
    bytecode[length + 2] = argument_count

    if argument_count == 0 then
        -- nothing
    elseif argument_count == 1 then
        local a1 = ...
        bytecode[length + 3] = a1
    elseif argument_count == 2 then
        local a1, a2 = ...
        bytecode[length + 3] = a1
        bytecode[length + 4] = a2
    elseif argument_count == 3 then
        local a1, a2, a3 = ...
        bytecode[length + 3] = a1
        bytecode[length + 4] = a2
        bytecode[length + 5] = a3
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = ...
        bytecode[length + 3] = a1
        bytecode[length + 4] = a2
        bytecode[length + 5] = a3
        bytecode[length + 6] = a4
    else
        local a1, a2, a3, a4 = ...
        bytecode[length + 3] = a1
        bytecode[length + 4] = a2
        bytecode[length + 5] = a3
        bytecode[length + 6] = a4
        for i = 5, argument_count do
            bytecode[length + 2 + i] = __lua_select(i, ...)
        end
    end

    __defer_length = length + 2 + argument_count
end

__defer_ops[__defer_op.batch_destroy] = function(bytes, index)
    local argument_count = bytes[index + 0]

    if argument_count == 0 then
        -- nothing
    elseif argument_count == 1 then
        local a1 = bytes[index + 1]
        __evolved_batch_destroy(a1)
    elseif argument_count == 2 then
        local a1, a2 = bytes[index + 1], bytes[index + 2]
        __evolved_batch_destroy(a1, a2)
    elseif argument_count == 3 then
        local a1, a2, a3 = bytes[index + 1], bytes[index + 2], bytes[index + 3]
        __evolved_batch_destroy(a1, a2, a3)
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = bytes[index + 1], bytes[index + 2], bytes[index + 3], bytes[index + 4]
        __evolved_batch_destroy(a1, a2, a3, a4)
    else
        local a1, a2, a3, a4 = bytes[index + 1], bytes[index + 2], bytes[index + 3], bytes[index + 4]
        __evolved_batch_destroy(a1, a2, a3, a4,
            __lua_table_unpack(bytes, index + 5, index + 0 + argument_count))
    end

    return 1 + argument_count
end

---@param query evolved.query
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@param components evolved.component[]
---@param component_count integer
__defer_batch_multi_set = function(query, fragments, fragment_count, components, component_count)
    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    __lua_table_move(fragments, 1, fragment_count, 1, fragment_list)

    ---@type evolved.component[]
    local component_list = __acquire_table(__table_pool_tag.component_list)
    __lua_table_move(components, 1, component_count, 1, component_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_multi_set
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment_list
    bytecode[length + 4] = component_list

    __defer_length = length + 4
end

__defer_ops[__defer_op.batch_multi_set] = function(bytes, index)
    local query = bytes[index + 0]
    local fragments = bytes[index + 1]
    local components = bytes[index + 2]

    __evolved_batch_multi_set(query, fragments, components)
    __release_table(__table_pool_tag.fragment_list, fragments)
    __release_table(__table_pool_tag.component_list, components)

    return 3
end

---@param query evolved.query
---@param fragments evolved.fragment[]
---@param fragment_count integer
__defer_batch_multi_remove = function(query, fragments, fragment_count)
    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    __lua_table_move(fragments, 1, fragment_count, 1, fragment_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.batch_multi_remove
    bytecode[length + 2] = query
    bytecode[length + 3] = fragment_list

    __defer_length = length + 3
end

__defer_ops[__defer_op.batch_multi_remove] = function(bytes, index)
    local query = bytes[index + 0]
    local fragments = bytes[index + 1]

    __evolved_batch_multi_remove(query, fragments)
    __release_table(__table_pool_tag.fragment_list, fragments)

    return 2
end

---@param entity evolved.entity
---@param chunk evolved.chunk
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@param components evolved.component[]
---@param component_count integer
__defer_spawn_entity_at = function(entity, chunk, fragments, fragment_count, components, component_count)
    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    __lua_table_move(fragments, 1, fragment_count, 1, fragment_list)

    ---@type evolved.component[]
    local component_list = __acquire_table(__table_pool_tag.component_list)
    __lua_table_move(components, 1, component_count, 1, component_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.spawn_entity_at
    bytecode[length + 2] = entity
    bytecode[length + 3] = __chunk_pin(chunk)
    bytecode[length + 4] = fragment_list
    bytecode[length + 5] = fragment_count
    bytecode[length + 6] = component_list

    __defer_length = length + 6
end

__defer_ops[__defer_op.spawn_entity_at] = function(bytes, index)
    local entity = bytes[index + 0]
    local chunk = __chunk_unpin(bytes[index + 1])
    local fragment_list = bytes[index + 2]
    local fragment_count = bytes[index + 3]
    local component_list = bytes[index + 4]

    if __debug_mode then
        __debug_fns.validate_chunk(chunk)
        __debug_fns.validate_fragment_list(fragment_list, fragment_count)
    end

    __evolved_defer()
    do
        __spawn_entity_at(entity, chunk, fragment_list, fragment_count, component_list)
        __release_table(__table_pool_tag.fragment_list, fragment_list)
        __release_table(__table_pool_tag.component_list, component_list)
    end
    __evolved_commit()

    return 5
end

---@param entity evolved.entity
---@param chunk evolved.chunk
---@param fragments evolved.fragment[]
---@param fragment_count integer
---@param components evolved.component[]
---@param component_count integer
__defer_spawn_entity_with = function(entity, chunk, fragments, fragment_count, components, component_count)
    ---@type evolved.fragment[]
    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    __lua_table_move(fragments, 1, fragment_count, 1, fragment_list)

    ---@type evolved.component[]
    local component_list = __acquire_table(__table_pool_tag.component_list)
    __lua_table_move(components, 1, component_count, 1, component_list)

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.spawn_entity_with
    bytecode[length + 2] = entity
    bytecode[length + 3] = __chunk_pin(chunk)
    bytecode[length + 4] = fragment_list
    bytecode[length + 5] = fragment_count
    bytecode[length + 6] = component_list

    __defer_length = length + 6
end

__defer_ops[__defer_op.spawn_entity_with] = function(bytes, index)
    local entity = bytes[index + 0]
    local chunk = __chunk_unpin(bytes[index + 1])
    local fragment_list = bytes[index + 2]
    local fragment_count = bytes[index + 3]
    local component_list = bytes[index + 4]

    if __debug_mode then
        __debug_fns.validate_chunk(chunk)
        __debug_fns.validate_fragment_list(fragment_list, fragment_count)
    end

    __evolved_defer()
    do
        __spawn_entity_with(entity, chunk, fragment_list, fragment_count, component_list)
        __release_table(__table_pool_tag.fragment_list, fragment_list)
        __release_table(__table_pool_tag.component_list, component_list)
    end
    __evolved_commit()

    return 5
end

---@param hook fun(...)
---@param ... any hook arguments
__defer_call_hook = function(hook, ...)
    local length = __defer_length
    local bytecode = __defer_bytecode

    local argument_count = __lua_select('#', ...)

    bytecode[length + 1] = __defer_op.call_hook
    bytecode[length + 2] = hook
    bytecode[length + 3] = argument_count

    if argument_count == 0 then
        -- nothing
    elseif argument_count == 1 then
        local a1 = ...
        bytecode[length + 4] = a1
    elseif argument_count == 2 then
        local a1, a2 = ...
        bytecode[length + 4] = a1
        bytecode[length + 5] = a2
    elseif argument_count == 3 then
        local a1, a2, a3 = ...
        bytecode[length + 4] = a1
        bytecode[length + 5] = a2
        bytecode[length + 6] = a3
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = ...
        bytecode[length + 4] = a1
        bytecode[length + 5] = a2
        bytecode[length + 6] = a3
        bytecode[length + 7] = a4
    else
        local a1, a2, a3, a4 = ...
        bytecode[length + 4] = a1
        bytecode[length + 5] = a2
        bytecode[length + 6] = a3
        bytecode[length + 7] = a4
        for i = 5, argument_count do
            bytecode[length + 3 + i] = __lua_select(i, ...)
        end
    end

    __defer_length = length + 3 + argument_count
end

__defer_ops[__defer_op.call_hook] = function(bytes, index)
    local hook = bytes[index + 0]
    local argument_count = bytes[index + 1]

    if argument_count == 0 then
        hook()
    elseif argument_count == 1 then
        local a1 = bytes[index + 2]
        hook(a1)
    elseif argument_count == 2 then
        local a1, a2 = bytes[index + 2], bytes[index + 3]
        hook(a1, a2)
    elseif argument_count == 3 then
        local a1, a2, a3 = bytes[index + 2], bytes[index + 3], bytes[index + 4]
        hook(a1, a2, a3)
    elseif argument_count == 4 then
        local a1, a2, a3, a4 = bytes[index + 2], bytes[index + 3], bytes[index + 4], bytes[index + 5]
        hook(a1, a2, a3, a4)
    else
        local a1, a2, a3, a4 = bytes[index + 2], bytes[index + 3], bytes[index + 4], bytes[index + 5]
        hook(a1, a2, a3, a4,
            __lua_table_unpack(bytes, index + 6, index + 1 + argument_count))
    end

    return 2 + argument_count
end

---
---
---
---
---

---@param count? integer
---@return evolved.id ... ids
---@nodiscard
__evolved_id = function(count)
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

    if count == 4 then
        return __acquire_id(), __acquire_id(), __acquire_id(), __acquire_id()
    end

    do
        return __acquire_id(), __acquire_id(), __acquire_id(), __acquire_id(),
            __evolved_id(count - 4)
    end
end

---@param index integer
---@param version integer
---@return evolved.id id
---@nodiscard
__evolved_pack = function(index, version)
    if index < 1 or index > 0xFFFFF then
        __error_fmt('id index out of range [1;0xFFFFF]')
    end

    if version < 1 or version > 0xFFFFF then
        __error_fmt('id version out of range [1;0xFFFFF]')
    end

    local shifted_version = version * 0x100000
    return index + shifted_version --[[@as evolved.id]]
end

---@param id evolved.id
---@return integer index
---@return integer version
---@nodiscard
__evolved_unpack = function(id)
    local index = id % 0x100000
    local version = (id - index) / 0x100000
    return index, version
end

---@return boolean started
__evolved_defer = function()
    __defer_depth = __defer_depth + 1
    return __defer_depth == 1
end

---@return boolean committed
__evolved_commit = function()
    if __defer_depth <= 0 then
        __error_fmt('unbalanced defer/commit')
    end

    __defer_depth = __defer_depth - 1

    if __defer_depth > 0 then
        return false
    end

    if __defer_length == 0 then
        return true
    end

    local length = __defer_length
    local bytecode = __defer_bytecode

    __defer_length = 0
    __defer_bytecode = __acquire_table(__table_pool_tag.bytecode)

    local bytecode_index = 1
    while bytecode_index <= length do
        local op = __defer_ops[bytecode[bytecode_index]]
        bytecode_index = bytecode_index + op(bytecode, bytecode_index + 1) + 1
    end

    __release_table(__table_pool_tag.bytecode, bytecode, true)
    return true
end

---@param chunk_or_entity evolved.chunk | evolved.entity
---@return boolean
---@nodiscard
__evolved_is_alive = function(chunk_or_entity)
    if __lua_type(chunk_or_entity) ~= 'number' then
        local chunk = chunk_or_entity --[[@as evolved.chunk]]
        return not chunk.__unreachable_or_collected
    else
        local entity = chunk_or_entity --[[@as evolved.entity]]
        local entity_index = entity % 0x100000
        return __freelist_ids[entity_index] == entity
    end
end

---@param ... evolved.chunk | evolved.entity chunks_or_entities
---@return boolean
---@nodiscard
__evolved_is_alive_all = function(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return true
    end

    local freelist_ids = __freelist_ids

    for argument_index = 1, argument_count do
        ---@type evolved.chunk | evolved.entity
        local chunk_or_entity = __lua_select(argument_index, ...)

        if __lua_type(chunk_or_entity) ~= 'number' then
            local chunk = chunk_or_entity --[[@as evolved.chunk]]
            if chunk.__unreachable_or_collected then
                return false
            end
        else
            local entity = chunk_or_entity --[[@as evolved.entity]]
            local entity_index = entity % 0x100000
            if freelist_ids[entity_index] ~= entity then
                return false
            end
        end
    end

    return true
end

---@param ... evolved.chunk | evolved.entity chunks_or_entities
---@return boolean
---@nodiscard
__evolved_is_alive_any = function(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return false
    end

    local freelist_ids = __freelist_ids

    for argument_index = 1, argument_count do
        ---@type evolved.chunk | evolved.entity
        local chunk_or_entity = __lua_select(argument_index, ...)

        if __lua_type(chunk_or_entity) ~= 'number' then
            local chunk = chunk_or_entity --[[@as evolved.chunk]]
            if not chunk.__unreachable_or_collected then
                return true
            end
        else
            local entity = chunk_or_entity --[[@as evolved.entity]]
            local entity_index = entity % 0x100000
            if freelist_ids[entity_index] == entity then
                return true
            end
        end
    end

    return false
end

---@param chunk_or_entity evolved.chunk | evolved.entity
---@return boolean
---@nodiscard
__evolved_is_empty = function(chunk_or_entity)
    if __lua_type(chunk_or_entity) ~= 'number' then
        local chunk = chunk_or_entity --[[@as evolved.chunk]]
        return chunk.__unreachable_or_collected or chunk.__entity_count == 0
    else
        local entity = chunk_or_entity --[[@as evolved.entity]]
        local entity_index = entity % 0x100000
        return __freelist_ids[entity_index] ~= entity or not __entity_chunks[entity_index]
    end
end

---@param ... evolved.chunk | evolved.entity chunks_or_entities
---@return boolean
---@nodiscard
__evolved_is_empty_all = function(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return true
    end

    local freelist_ids = __freelist_ids

    for argument_index = 1, argument_count do
        ---@type evolved.chunk | evolved.entity
        local chunk_or_entity = __lua_select(argument_index, ...)

        if __lua_type(chunk_or_entity) ~= 'number' then
            local chunk = chunk_or_entity --[[@as evolved.chunk]]
            if not chunk.__unreachable_or_collected and chunk.__entity_count > 0 then
                return false
            end
        else
            local entity = chunk_or_entity --[[@as evolved.entity]]
            local entity_index = entity % 0x100000
            if freelist_ids[entity_index] == entity and __entity_chunks[entity_index] then
                return false
            end
        end
    end

    return true
end

---@param ... evolved.chunk | evolved.entity chunks_or_entities
---@return boolean
---@nodiscard
__evolved_is_empty_any = function(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return false
    end

    local freelist_ids = __freelist_ids

    for argument_index = 1, argument_count do
        ---@type evolved.chunk | evolved.entity
        local chunk_or_entity = __lua_select(argument_index, ...)

        if __lua_type(chunk_or_entity) ~= 'number' then
            local chunk = chunk_or_entity --[[@as evolved.chunk]]
            if chunk.__unreachable_or_collected or chunk.__entity_count == 0 then
                return true
            end
        else
            local entity = chunk_or_entity --[[@as evolved.entity]]
            local entity_index = entity % 0x100000
            if freelist_ids[entity_index] ~= entity or not __entity_chunks[entity_index] then
                return true
            end
        end
    end

    return false
end

---@param chunk_or_entity evolved.chunk | evolved.entity
---@param fragment evolved.fragment
---@return boolean
---@nodiscard
__evolved_has = function(chunk_or_entity, fragment)
    if __lua_type(chunk_or_entity) ~= 'number' then
        local chunk = chunk_or_entity --[[@as evolved.chunk]]
        return __chunk_has_fragment(chunk, fragment)
    else
        local entity = chunk_or_entity --[[@as evolved.entity]]

        local entity_index = entity % 0x100000

        if __freelist_ids[entity_index] ~= entity then
            return false
        end

        local chunk = __entity_chunks[entity_index]

        if not chunk then
            return false
        end

        return __chunk_has_fragment(chunk, fragment)
    end
end

---@param chunk_or_entity evolved.chunk | evolved.entity
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
__evolved_has_all = function(chunk_or_entity, ...)
    if __lua_type(chunk_or_entity) ~= 'number' then
        local chunk = chunk_or_entity --[[@as evolved.chunk]]
        return __chunk_has_all_fragments(chunk, ...)
    else
        local entity = chunk_or_entity --[[@as evolved.entity]]

        local entity_index = entity % 0x100000

        if __freelist_ids[entity_index] ~= entity then
            return __lua_select('#', ...) == 0
        end

        local chunk = __entity_chunks[entity_index]

        if not chunk then
            return __lua_select('#', ...) == 0
        end

        return __chunk_has_all_fragments(chunk, ...)
    end
end

---@param chunk_or_entity evolved.chunk | evolved.entity
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
__evolved_has_any = function(chunk_or_entity, ...)
    if __lua_type(chunk_or_entity) ~= 'number' then
        local chunk = chunk_or_entity --[[@as evolved.chunk]]
        return __chunk_has_any_fragments(chunk, ...)
    else
        local entity = chunk_or_entity --[[@as evolved.entity]]

        local entity_index = entity % 0x100000

        if __freelist_ids[entity_index] ~= entity then
            return false
        end

        local chunk = __entity_chunks[entity_index]

        if not chunk then
            return false
        end

        return __chunk_has_any_fragments(chunk, ...)
    end
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return evolved.component ... components
---@nodiscard
__evolved_get = function(entity, ...)
    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return
    end

    local chunk = __entity_chunks[entity_index]

    if not chunk then
        return
    end

    local place = __entity_places[entity_index]
    return __chunk_get_components(chunk, place, ...)
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
__evolved_set = function(entity, fragment, component)
    if __debug_mode then
        __debug_fns.validate_entity(entity)
        __debug_fns.validate_fragment(fragment)
    end

    if __defer_depth > 0 then
        __defer_set(entity, fragment, component)
        return
    end

    local entity_index = entity % 0x100000

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local old_chunk = entity_chunks[entity_index]
    local old_place = entity_places[entity_index]

    local new_chunk = __chunk_with_fragment(old_chunk, fragment)

    if not new_chunk then
        return
    end

    __evolved_defer()

    if old_chunk == new_chunk then
        local old_component_indices = old_chunk.__component_indices
        local old_component_storages = old_chunk.__component_storages

        local old_chunk_has_setup_hooks = old_chunk.__has_setup_hooks
        local old_chunk_has_assign_hooks = old_chunk.__has_assign_hooks

        ---@type evolved.default?, evolved.duplicate?, evolved.set_hook?, evolved.assign_hook?
        local fragment_default, fragment_duplicate, fragment_on_set, fragment_on_assign

        if old_chunk_has_setup_hooks or old_chunk_has_assign_hooks then
            fragment_default, fragment_duplicate, fragment_on_set, fragment_on_assign =
                __evolved_get(fragment, __DEFAULT, __DUPLICATE, __ON_SET, __ON_ASSIGN)
        end

        local old_component_index = old_component_indices[fragment]

        if old_component_index then
            local old_component_storage = old_component_storages[old_component_index]

            local new_component = component
            if new_component == nil then new_component = fragment_default end
            if new_component ~= nil and fragment_duplicate then new_component = fragment_duplicate(new_component) end
            if new_component == nil then new_component = true end

            local old_component = old_component_storage[old_place]
            old_component_storage[old_place] = new_component

            if fragment_on_set then
                __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
            end

            if fragment_on_assign then
                __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
            end
        else
            if fragment_on_set then
                __defer_call_hook(fragment_on_set, entity, fragment)
            end

            if fragment_on_assign then
                __defer_call_hook(fragment_on_assign, entity, fragment)
            end
        end
    else
        local new_entity_list = new_chunk.__entity_list
        local new_entity_count = new_chunk.__entity_count

        local new_component_indices = new_chunk.__component_indices
        local new_component_storages = new_chunk.__component_storages

        local new_chunk_has_setup_hooks = new_chunk.__has_setup_hooks
        local new_chunk_has_insert_hooks = new_chunk.__has_insert_hooks

        ---@type evolved.default?, evolved.duplicate?, evolved.set_hook?, evolved.insert_hook?
        local fragment_default, fragment_duplicate, fragment_on_set, fragment_on_insert

        if new_chunk_has_setup_hooks or new_chunk_has_insert_hooks then
            fragment_default, fragment_duplicate, fragment_on_set, fragment_on_insert =
                __evolved_get(fragment, __DEFAULT, __DUPLICATE, __ON_SET, __ON_INSERT)
        end

        local new_place = new_entity_count + 1
        new_chunk.__entity_count = new_place

        new_entity_list[new_place] = entity

        if old_chunk then
            local old_component_count = old_chunk.__component_count
            local old_component_storages = old_chunk.__component_storages
            local old_component_fragments = old_chunk.__component_fragments

            for old_ci = 1, old_component_count do
                local old_f = old_component_fragments[old_ci]
                local old_cs = old_component_storages[old_ci]
                local new_ci = new_component_indices[old_f]
                local new_cs = new_component_storages[new_ci]
                new_cs[new_place] = old_cs[old_place]
            end

            __detach_entity(old_chunk, old_place)
        end

        do
            entity_chunks[entity_index] = new_chunk
            entity_places[entity_index] = new_place

            __structural_changes = __structural_changes + 1
        end

        do
            local new_component_index = new_component_indices[fragment]

            if new_component_index then
                local new_component_storage = new_component_storages[new_component_index]

                local new_component = component
                if new_component == nil then new_component = fragment_default end
                if new_component ~= nil and fragment_duplicate then new_component = fragment_duplicate(new_component) end
                if new_component == nil then new_component = true end

                new_component_storage[new_place] = new_component

                if fragment_on_set then
                    __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                end

                if fragment_on_insert then
                    __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                end
            else
                if fragment_on_set then
                    __defer_call_hook(fragment_on_set, entity, fragment)
                end

                if fragment_on_insert then
                    __defer_call_hook(fragment_on_insert, entity, fragment)
                end
            end
        end
    end

    __evolved_commit()
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
__evolved_remove = function(entity, ...)
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        -- this entity is not alive, nothing to remove
        return
    end

    if __defer_depth > 0 then
        __defer_remove(entity, ...)
        return
    end

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local old_chunk = entity_chunks[entity_index]
    local old_place = entity_places[entity_index]

    local new_chunk = __chunk_without_fragments(old_chunk, ...)

    if old_chunk == new_chunk then
        return
    end

    __evolved_defer()

    do
        local old_fragment_set = old_chunk.__fragment_set
        local old_component_indices = old_chunk.__component_indices
        local old_component_storages = old_chunk.__component_storages

        if old_chunk.__has_remove_hooks then
            ---@type table<evolved.fragment, boolean>
            local removed_set = __acquire_table(__table_pool_tag.fragment_set)

            for i = 1, fragment_count do
                ---@type evolved.fragment
                local fragment = __lua_select(i, ...)

                if not removed_set[fragment] and old_fragment_set[fragment] then
                    removed_set[fragment] = true

                    ---@type evolved.remove_hook?
                    local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

                    if fragment_on_remove then
                        local old_component_index = old_component_indices[fragment]

                        if old_component_index then
                            local old_component_storage = old_component_storages[old_component_index]
                            local old_component = old_component_storage[old_place]
                            __defer_call_hook(fragment_on_remove, entity, fragment, old_component)
                        else
                            __defer_call_hook(fragment_on_remove, entity, fragment)
                        end
                    end
                end
            end

            __release_table(__table_pool_tag.fragment_set, removed_set)
        end

        if new_chunk then
            local new_entity_list = new_chunk.__entity_list
            local new_entity_count = new_chunk.__entity_count

            local new_component_count = new_chunk.__component_count
            local new_component_storages = new_chunk.__component_storages
            local new_component_fragments = new_chunk.__component_fragments

            local new_place = new_entity_count + 1
            new_chunk.__entity_count = new_place

            new_entity_list[new_place] = entity

            for new_ci = 1, new_component_count do
                local new_f = new_component_fragments[new_ci]
                local new_cs = new_component_storages[new_ci]
                local old_ci = old_component_indices[new_f]
                local old_cs = old_component_storages[old_ci]
                new_cs[new_place] = old_cs[old_place]
            end
        end

        do
            __detach_entity(old_chunk, old_place)

            entity_chunks[entity_index] = new_chunk
            entity_places[entity_index] = new_chunk and new_chunk.__entity_count

            __structural_changes = __structural_changes + 1
        end
    end

    __evolved_commit()
end

---@param ... evolved.entity entities
__evolved_clear = function(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return
    end

    if __defer_depth > 0 then
        __defer_clear(...)
        return
    end

    __evolved_defer()

    do
        local entity_chunks = __entity_chunks
        local entity_places = __entity_places

        for argument_index = 1, argument_count do
            ---@type evolved.entity
            local entity = __lua_select(argument_index, ...)
            local entity_index = entity % 0x100000

            if __freelist_ids[entity_index] ~= entity then
                -- this entity is not alive, nothing to clear
            else
                local chunk = entity_chunks[entity_index]
                local place = entity_places[entity_index]

                if chunk and chunk.__has_remove_hooks then
                    local chunk_fragment_list = chunk.__fragment_list
                    local chunk_fragment_count = chunk.__fragment_count
                    local chunk_component_indices = chunk.__component_indices
                    local chunk_component_storages = chunk.__component_storages

                    for chunk_fragment_index = 1, chunk_fragment_count do
                        local fragment = chunk_fragment_list[chunk_fragment_index]

                        ---@type evolved.remove_hook?
                        local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

                        if fragment_on_remove then
                            local component_index = chunk_component_indices[fragment]

                            if component_index then
                                local component_storage = chunk_component_storages[component_index]
                                local old_component = component_storage[place]
                                __defer_call_hook(fragment_on_remove, entity, fragment, old_component)
                            else
                                __defer_call_hook(fragment_on_remove, entity, fragment)
                            end
                        end
                    end
                end

                if chunk then
                    __detach_entity(chunk, place)

                    entity_chunks[entity_index] = nil
                    entity_places[entity_index] = nil

                    __structural_changes = __structural_changes + 1
                end
            end
        end
    end

    __evolved_commit()
end

---@param ... evolved.entity entities
__evolved_destroy = function(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return
    end

    if __defer_depth > 0 then
        __defer_destroy(...)
        return
    end

    __evolved_defer()

    do
        local entity_chunks = __entity_chunks
        local entity_places = __entity_places

        for argument_index = 1, argument_count do
            ---@type evolved.entity
            local entity = __lua_select(argument_index, ...)
            local entity_index = entity % 0x100000

            if __freelist_ids[entity_index] ~= entity then
                -- this entity is not alive, nothing to destroy
            else
                local chunk = entity_chunks[entity_index]
                local place = entity_places[entity_index]

                if chunk and chunk.__has_remove_hooks then
                    local chunk_fragment_list = chunk.__fragment_list
                    local chunk_fragment_count = chunk.__fragment_count
                    local chunk_component_indices = chunk.__component_indices
                    local chunk_component_storages = chunk.__component_storages

                    for chunk_fragment_index = 1, chunk_fragment_count do
                        local fragment = chunk_fragment_list[chunk_fragment_index]

                        ---@type evolved.remove_hook?
                        local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

                        if fragment_on_remove then
                            local component_index = chunk_component_indices[fragment]

                            if component_index then
                                local component_storage = chunk_component_storages[component_index]
                                local old_component = component_storage[place]
                                __defer_call_hook(fragment_on_remove, entity, fragment, old_component)
                            else
                                __defer_call_hook(fragment_on_remove, entity, fragment)
                            end
                        end
                    end
                end

                local purging_fragment ---@type evolved.fragment?
                local purging_policy ---@type evolved.id?

                if __minor_chunks[entity] then
                    purging_fragment = entity
                    purging_policy = chunk and __chunk_get_components(chunk, place, __DESTROY_POLICY)
                        or __DESTROY_POLICY_REMOVE_FRAGMENT
                end

                if chunk then
                    __detach_entity(chunk, place)

                    entity_chunks[entity_index] = nil
                    entity_places[entity_index] = nil

                    __structural_changes = __structural_changes + 1
                end

                __release_id(entity)

                if purging_fragment then
                    __purge_fragment(purging_fragment, purging_policy)
                end
            end
        end
    end

    __evolved_commit()
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
---@param components? evolved.component[]
__evolved_multi_set = function(entity, fragments, components)
    local fragment_count = #fragments

    if fragment_count == 0 then
        return
    end

    if not components then
        components = __safe_tbls.__EMPTY_COMPONENT_LIST
    end

    if __debug_mode then
        __debug_fns.validate_entity(entity)
        __debug_fns.validate_fragment_list(fragments, fragment_count)
    end

    if __defer_depth > 0 then
        __defer_multi_set(entity, fragments, fragment_count, components, #components)
        return
    end

    local entity_index = entity % 0x100000

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local old_chunk = entity_chunks[entity_index]
    local old_place = entity_places[entity_index]

    local new_chunk = __chunk_with_fragment_list(old_chunk, fragments, fragment_count)

    if not new_chunk then
        return
    end

    __evolved_defer()

    if old_chunk == new_chunk then
        local old_component_indices = old_chunk.__component_indices
        local old_component_storages = old_chunk.__component_storages

        local old_chunk_has_setup_hooks = old_chunk.__has_setup_hooks
        local old_chunk_has_assign_hooks = old_chunk.__has_assign_hooks

        for i = 1, fragment_count do
            local fragment = fragments[i]

            ---@type evolved.default?, evolved.duplicate?, evolved.set_hook?, evolved.assign_hook?
            local fragment_default, fragment_duplicate, fragment_on_set, fragment_on_assign

            if old_chunk_has_setup_hooks or old_chunk_has_assign_hooks then
                fragment_default, fragment_duplicate, fragment_on_set, fragment_on_assign =
                    __evolved_get(fragment, __DEFAULT, __DUPLICATE, __ON_SET, __ON_ASSIGN)
            end

            local old_component_index = old_component_indices[fragment]

            if old_component_index then
                local old_component_storage = old_component_storages[old_component_index]

                local new_component = components[i]
                if new_component == nil then new_component = fragment_default end
                if new_component ~= nil and fragment_duplicate then new_component = fragment_duplicate(new_component) end
                if new_component == nil then new_component = true end

                if fragment_on_set or fragment_on_assign then
                    local old_component = old_component_storage[old_place]
                    old_component_storage[old_place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                    end

                    if fragment_on_assign then
                        __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                    end
                else
                    old_component_storage[old_place] = new_component
                end
            else
                if fragment_on_set then
                    __defer_call_hook(fragment_on_set, entity, fragment)
                end

                if fragment_on_assign then
                    __defer_call_hook(fragment_on_assign, entity, fragment)
                end
            end
        end
    else
        local new_entity_list = new_chunk.__entity_list
        local new_entity_count = new_chunk.__entity_count

        local new_component_indices = new_chunk.__component_indices
        local new_component_storages = new_chunk.__component_storages

        local new_chunk_has_setup_hooks = new_chunk.__has_setup_hooks
        local new_chunk_has_assign_hooks = new_chunk.__has_assign_hooks
        local new_chunk_has_insert_hooks = new_chunk.__has_insert_hooks

        local old_fragment_set = old_chunk and old_chunk.__fragment_set or __safe_tbls.__EMPTY_FRAGMENT_SET

        local new_place = new_entity_count + 1
        new_chunk.__entity_count = new_place

        new_entity_list[new_place] = entity

        if old_chunk then
            local old_component_count = old_chunk.__component_count
            local old_component_storages = old_chunk.__component_storages
            local old_component_fragments = old_chunk.__component_fragments

            for old_ci = 1, old_component_count do
                local old_f = old_component_fragments[old_ci]
                local old_cs = old_component_storages[old_ci]
                local new_ci = new_component_indices[old_f]
                local new_cs = new_component_storages[new_ci]
                new_cs[new_place] = old_cs[old_place]
            end

            __detach_entity(old_chunk, old_place)
        end

        do
            entity_chunks[entity_index] = new_chunk
            entity_places[entity_index] = new_place

            __structural_changes = __structural_changes + 1
        end

        ---@type table<evolved.fragment, boolean>
        local inserted_set = __acquire_table(__table_pool_tag.fragment_set)

        for i = 1, fragment_count do
            local fragment = fragments[i]

            ---@type evolved.default?, evolved.duplicate?, evolved.set_hook?, evolved.assign_hook?, evolved.insert_hook?
            local fragment_default, fragment_duplicate, fragment_on_set, fragment_on_assign, fragment_on_insert

            if new_chunk_has_setup_hooks or new_chunk_has_assign_hooks or new_chunk_has_insert_hooks then
                fragment_default, fragment_duplicate, fragment_on_set, fragment_on_assign, fragment_on_insert =
                    __evolved_get(fragment, __DEFAULT, __DUPLICATE, __ON_SET, __ON_ASSIGN, __ON_INSERT)
            end

            if inserted_set[fragment] or old_fragment_set[fragment] then
                local new_component_index = new_component_indices[fragment]

                if new_component_index then
                    local new_component_storage = new_component_storages[new_component_index]

                    local new_component = components[i]
                    if new_component == nil then new_component = fragment_default end
                    if new_component ~= nil and fragment_duplicate then new_component = fragment_duplicate(new_component) end
                    if new_component == nil then new_component = true end

                    if fragment_on_set or fragment_on_assign then
                        local old_component = new_component_storage[new_place]
                        new_component_storage[new_place] = new_component

                        if fragment_on_set then
                            __defer_call_hook(fragment_on_set, entity, fragment, new_component, old_component)
                        end

                        if fragment_on_assign then
                            __defer_call_hook(fragment_on_assign, entity, fragment, new_component, old_component)
                        end
                    else
                        new_component_storage[new_place] = new_component
                    end
                else
                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment)
                    end

                    if fragment_on_assign then
                        __defer_call_hook(fragment_on_assign, entity, fragment)
                    end
                end
            else
                inserted_set[fragment] = true

                local new_component_index = new_component_indices[fragment]

                if new_component_index then
                    local new_component_storage = new_component_storages[new_component_index]

                    local new_component = components[i]
                    if new_component == nil then new_component = fragment_default end
                    if new_component ~= nil and fragment_duplicate then new_component = fragment_duplicate(new_component) end
                    if new_component == nil then new_component = true end

                    new_component_storage[new_place] = new_component

                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment, new_component)
                    end

                    if fragment_on_insert then
                        __defer_call_hook(fragment_on_insert, entity, fragment, new_component)
                    end
                else
                    if fragment_on_set then
                        __defer_call_hook(fragment_on_set, entity, fragment)
                    end

                    if fragment_on_insert then
                        __defer_call_hook(fragment_on_insert, entity, fragment)
                    end
                end
            end
        end

        __release_table(__table_pool_tag.fragment_set, inserted_set)
    end

    __evolved_commit()
end

---@param entity evolved.entity
---@param fragments evolved.fragment[]
__evolved_multi_remove = function(entity, fragments)
    local fragment_count = #fragments

    if fragment_count == 0 then
        return
    end

    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        -- this entity is not alive, nothing to remove
        return
    end

    if __defer_depth > 0 then
        __defer_multi_remove(entity, fragments, fragment_count)
        return
    end

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local old_chunk = entity_chunks[entity_index]
    local old_place = entity_places[entity_index]

    local new_chunk = __chunk_without_fragment_list(old_chunk, fragments, fragment_count)

    if old_chunk == new_chunk then
        return
    end

    __evolved_defer()

    do
        local old_fragment_set = old_chunk.__fragment_set
        local old_component_indices = old_chunk.__component_indices
        local old_component_storages = old_chunk.__component_storages

        if old_chunk.__has_remove_hooks then
            ---@type table<evolved.fragment, boolean>
            local removed_set = __acquire_table(__table_pool_tag.fragment_set)

            for i = 1, fragment_count do
                local fragment = fragments[i]

                if not removed_set[fragment] and old_fragment_set[fragment] then
                    removed_set[fragment] = true

                    ---@type evolved.remove_hook?
                    local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

                    if fragment_on_remove then
                        local old_component_index = old_component_indices[fragment]

                        if old_component_index then
                            local old_component_storage = old_component_storages[old_component_index]
                            local old_component = old_component_storage[old_place]
                            __defer_call_hook(fragment_on_remove, entity, fragment, old_component)
                        else
                            __defer_call_hook(fragment_on_remove, entity, fragment)
                        end
                    end
                end
            end

            __release_table(__table_pool_tag.fragment_set, removed_set)
        end

        if new_chunk then
            local new_entity_list = new_chunk.__entity_list
            local new_entity_count = new_chunk.__entity_count

            local new_component_count = new_chunk.__component_count
            local new_component_storages = new_chunk.__component_storages
            local new_component_fragments = new_chunk.__component_fragments

            local new_place = new_entity_count + 1
            new_chunk.__entity_count = new_place

            new_entity_list[new_place] = entity

            for new_ci = 1, new_component_count do
                local new_f = new_component_fragments[new_ci]
                local new_cs = new_component_storages[new_ci]
                local old_ci = old_component_indices[new_f]
                local old_cs = old_component_storages[old_ci]
                new_cs[new_place] = old_cs[old_place]
            end
        end

        do
            __detach_entity(old_chunk, old_place)

            entity_chunks[entity_index] = new_chunk
            entity_places[entity_index] = new_chunk and new_chunk.__entity_count

            __structural_changes = __structural_changes + 1
        end
    end

    __evolved_commit()
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param component evolved.component
__evolved_batch_set = function(query, fragment, component)
    if __debug_mode then
        __debug_fns.validate_query(query)
        __debug_fns.validate_fragment(fragment)
    end

    if __defer_depth > 0 then
        __defer_batch_set(query, fragment, component)
        return
    end

    __evolved_defer()

    do
        ---@type evolved.chunk[]
        local chunk_list = __acquire_table(__table_pool_tag.chunk_stack)
        local chunk_count = 0

        for chunk in __evolved_execute(query) do
            chunk_count = chunk_count + 1
            chunk_list[chunk_count] = chunk
        end

        for chunk_index = 1, chunk_count do
            local chunk = chunk_list[chunk_index]
            __chunk_set(chunk, fragment, component)
        end

        __release_table(__table_pool_tag.chunk_stack, chunk_list)
    end

    __evolved_commit()
end

---@param query evolved.query
---@param ... evolved.fragment fragments
__evolved_batch_remove = function(query, ...)
    local fragment_count = select('#', ...)

    if fragment_count == 0 then
        return
    end

    local query_index = query % 0x100000

    if __freelist_ids[query_index] ~= query then
        -- this query is not alive, nothing to remove
        return
    end

    if __defer_depth > 0 then
        __defer_batch_remove(query, ...)
        return
    end

    __evolved_defer()

    do
        ---@type evolved.chunk[]
        local chunk_list = __acquire_table(__table_pool_tag.chunk_stack)
        local chunk_count = 0

        for chunk in __evolved_execute(query) do
            chunk_count = chunk_count + 1
            chunk_list[chunk_count] = chunk
        end

        for chunk_index = 1, chunk_count do
            local chunk = chunk_list[chunk_index]
            __chunk_remove(chunk, ...)
        end

        __release_table(__table_pool_tag.chunk_stack, chunk_list)
    end

    __evolved_commit()
end

---@param ... evolved.query queries
__evolved_batch_clear = function(...)
    local argument_count = select('#', ...)

    if argument_count == 0 then
        return
    end

    if __defer_depth > 0 then
        __defer_batch_clear(...)
        return
    end

    __evolved_defer()

    do
        ---@type evolved.chunk[]
        local chunk_list = __acquire_table(__table_pool_tag.chunk_stack)
        local chunk_count = 0

        for argument_index = 1, argument_count do
            ---@type evolved.query
            local query = __lua_select(argument_index, ...)
            local query_index = query % 0x100000

            if __freelist_ids[query_index] ~= query then
                -- this query is not alive, nothing to remove
            else
                for chunk in __evolved_execute(query) do
                    chunk_count = chunk_count + 1
                    chunk_list[chunk_count] = chunk
                end
            end
        end

        for chunk_index = 1, chunk_count do
            local chunk = chunk_list[chunk_index]
            __chunk_clear(chunk)
        end

        __release_table(__table_pool_tag.chunk_stack, chunk_list)
    end

    __evolved_commit()
end

---@param ... evolved.query queries
__evolved_batch_destroy = function(...)
    local argument_count = select('#', ...)

    if argument_count == 0 then
        return
    end

    if __defer_depth > 0 then
        __defer_batch_destroy(...)
        return
    end

    __evolved_defer()

    do
        ---@type evolved.chunk[]
        local chunk_list = __acquire_table(__table_pool_tag.chunk_stack)
        local chunk_count = 0

        for argument_index = 1, argument_count do
            ---@type evolved.query
            local query = __lua_select(argument_index, ...)
            local query_index = query % 0x100000

            if __freelist_ids[query_index] ~= query then
                -- this query is not alive, nothing to destroy
            else
                for chunk in __evolved_execute(query) do
                    chunk_count = chunk_count + 1
                    chunk_list[chunk_count] = chunk
                end
            end
        end

        for chunk_index = 1, chunk_count do
            local chunk = chunk_list[chunk_index]
            __chunk_destroy(chunk)
        end

        __release_table(__table_pool_tag.chunk_stack, chunk_list)
    end

    __evolved_commit()
end

---@param query evolved.query
---@param fragments evolved.fragment[]
---@param components? evolved.component[]
__evolved_batch_multi_set = function(query, fragments, components)
    local fragment_count = #fragments

    if fragment_count == 0 then
        return
    end

    if not components then
        components = __safe_tbls.__EMPTY_COMPONENT_LIST
    end

    if __debug_mode then
        __debug_fns.validate_query(query)
        __debug_fns.validate_fragment_list(fragments, fragment_count)
    end

    if __defer_depth > 0 then
        __defer_batch_multi_set(query, fragments, fragment_count, components, #components)
        return
    end

    __evolved_defer()

    do
        ---@type evolved.chunk[]
        local chunk_list = __acquire_table(__table_pool_tag.chunk_stack)
        local chunk_count = 0

        for chunk in __evolved_execute(query) do
            chunk_count = chunk_count + 1
            chunk_list[chunk_count] = chunk
        end

        for chunk_index = 1, chunk_count do
            local chunk = chunk_list[chunk_index]
            __chunk_multi_set(chunk, fragments, fragment_count, components)
        end

        __release_table(__table_pool_tag.chunk_stack, chunk_list)
    end

    __evolved_commit()
end

---@param query evolved.query
---@param fragments evolved.fragment[]
__evolved_batch_multi_remove = function(query, fragments)
    local fragment_count = #fragments

    if fragment_count == 0 then
        return
    end

    local query_index = query % 0x100000

    if __freelist_ids[query_index] ~= query then
        -- this query is not alive, nothing to remove
        return
    end

    if __defer_depth > 0 then
        __defer_batch_multi_remove(query, fragments, fragment_count)
        return
    end

    __evolved_defer()

    do
        ---@type evolved.chunk[]
        local chunk_list = __acquire_table(__table_pool_tag.chunk_stack)
        local chunk_count = 0

        for chunk in __evolved_execute(query) do
            chunk_count = chunk_count + 1
            chunk_list[chunk_count] = chunk
        end

        for chunk_index = 1, chunk_count do
            local chunk = chunk_list[chunk_index]
            __chunk_multi_remove(chunk, fragments, fragment_count)
        end

        __release_table(__table_pool_tag.chunk_stack, chunk_list)
    end

    __evolved_commit()
end

---
---
---
---
---

---@param head_fragment evolved.fragment
---@param ... evolved.fragment tail_fragments
---@return evolved.chunk chunk
---@return evolved.entity[] entity_list
---@return integer entity_count
---@nodiscard
__evolved_chunk = function(head_fragment, ...)
    local chunk = __chunk_fragments(head_fragment, ...)
    return chunk, chunk.__entity_list, chunk.__entity_count
end

---@param chunk evolved.chunk
---@return evolved.entity[] entity_list
---@return integer entity_count
---@nodiscard
__evolved_entities = function(chunk)
    return chunk.__entity_list, chunk.__entity_count
end

---@param chunk evolved.chunk
---@return evolved.fragment[] fragments
---@return integer fragment_count
---@nodiscard
__evolved_fragments = function(chunk)
    return chunk.__fragment_list, chunk.__fragment_count
end

---@param chunk evolved.chunk
---@param ... evolved.fragment fragments
---@return evolved.storage ... storages
---@nodiscard
__evolved_components = function(chunk, ...)
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return
    end

    local indices = chunk.__component_indices
    local storages = chunk.__component_storages

    local empty_component_storage = __safe_tbls.__EMPTY_COMPONENT_STORAGE

    if fragment_count == 1 then
        local f1 = ...
        local i1 = indices[f1]
        return
            i1 and storages[i1] or empty_component_storage
    end

    if fragment_count == 2 then
        local f1, f2 = ...
        local i1, i2 = indices[f1], indices[f2]
        return
            i1 and storages[i1] or empty_component_storage,
            i2 and storages[i2] or empty_component_storage
    end

    if fragment_count == 3 then
        local f1, f2, f3 = ...
        local i1, i2, i3 = indices[f1], indices[f2], indices[f3]
        return
            i1 and storages[i1] or empty_component_storage,
            i2 and storages[i2] or empty_component_storage,
            i3 and storages[i3] or empty_component_storage
    end

    if fragment_count == 4 then
        local f1, f2, f3, f4 = ...
        local i1, i2, i3, i4 = indices[f1], indices[f2], indices[f3], indices[f4]
        return
            i1 and storages[i1] or empty_component_storage,
            i2 and storages[i2] or empty_component_storage,
            i3 and storages[i3] or empty_component_storage,
            i4 and storages[i4] or empty_component_storage
    end

    do
        local f1, f2, f3, f4 = ...
        local i1, i2, i3, i4 = indices[f1], indices[f2], indices[f3], indices[f4]
        return
            i1 and storages[i1] or empty_component_storage,
            i2 and storages[i2] or empty_component_storage,
            i3 and storages[i3] or empty_component_storage,
            i4 and storages[i4] or empty_component_storage,
            __evolved_components(chunk, __lua_select(5, ...))
    end
end

---@param entity evolved.entity
---@return evolved.each_iterator iterator
---@return evolved.each_state? iterator_state
---@nodiscard
__evolved_each = function(entity)
    local entity_index = entity % 0x100000

    if __freelist_ids[entity_index] ~= entity then
        return __each_iterator
    end

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local chunk = entity_chunks[entity_index]
    local place = entity_places[entity_index]

    if not chunk then
        return __each_iterator
    end

    ---@type evolved.each_state
    local each_state = __acquire_table(__table_pool_tag.each_state)

    each_state[1] = __structural_changes
    each_state[2] = chunk
    each_state[3] = place
    each_state[4] = 1

    return __each_iterator, each_state
end

---@param query evolved.query
---@return evolved.execute_iterator iterator
---@return evolved.execute_state? iterator_state
---@nodiscard
__evolved_execute = function(query)
    local query_index = query % 0x100000

    if __freelist_ids[query_index] ~= query then
        return __execute_iterator
    end

    ---@type evolved.chunk[]
    local chunk_stack = __acquire_table(__table_pool_tag.chunk_stack)
    local chunk_stack_size = 0

    local query_includes = __query_sorted_includes[query]
    local query_include_list = query_includes and query_includes.__item_list --[=[@as evolved.fragment[]]=]
    local query_include_count = query_includes and query_includes.__item_count or 0 --[[@as integer]]

    local query_excludes = __query_sorted_excludes[query]
    local query_exclude_set = query_excludes and query_excludes.__item_set --[[@as table<evolved.fragment, integer>]]
    local query_exclude_list = query_excludes and query_excludes.__item_list --[=[@as evolved.fragment[]]=]
    local query_exclude_count = query_excludes and query_excludes.__item_count or 0 --[[@as integer]]

    if query_include_count > 0 then
        local major_fragment = query_include_list[query_include_count]

        local major_chunks = __major_chunks[major_fragment]
        local major_chunk_list = major_chunks and major_chunks.__item_list --[=[@as evolved.chunk[]]=]
        local major_chunk_count = major_chunks and major_chunks.__item_count or 0 --[[@as integer]]

        for major_chunk_index = 1, major_chunk_count do
            local major_chunk = major_chunk_list[major_chunk_index]

            local is_major_chunk_matched =
                (query_include_count == 1 or __chunk_has_all_fragment_list(
                    major_chunk, query_include_list, query_include_count - 1)) and
                (query_exclude_count == 0 or not __chunk_has_any_fragment_list(
                    major_chunk, query_exclude_list, query_exclude_count))

            if is_major_chunk_matched then
                chunk_stack_size = chunk_stack_size + 1
                chunk_stack[chunk_stack_size] = major_chunk
            end
        end
    elseif query_exclude_count > 0 then
        for root_fragment, root_chunk in __lua_next, __root_chunks do
            if not query_exclude_set[root_fragment] then
                chunk_stack_size = chunk_stack_size + 1
                chunk_stack[chunk_stack_size] = root_chunk
            end
        end
    else
        for _, root_chunk in __lua_next, __root_chunks do
            chunk_stack_size = chunk_stack_size + 1
            chunk_stack[chunk_stack_size] = root_chunk
        end
    end

    ---@type evolved.execute_state
    local execute_state = __acquire_table(__table_pool_tag.execute_state)

    execute_state[1] = __structural_changes
    execute_state[2] = chunk_stack
    execute_state[3] = chunk_stack_size
    execute_state[4] = query_exclude_set

    return __execute_iterator, execute_state
end

---@param ... evolved.phase phases
__evolved_process = function(...)
    for i = 1, __lua_select('#', ...) do
        ---@type evolved.phase
        local phase = __lua_select(i, ...)
        if not __evolved_has(phase, __DISABLED) then
            __phase_process(phase)
        end
    end
end

---
---
---
---
---

---@param chunk? evolved.chunk
---@param fragments? evolved.fragment[]
---@param components? evolved.component[]
---@return evolved.entity entity
__evolved_spawn_at = function(chunk, fragments, components)
    if not fragments then
        fragments = __safe_tbls.__EMPTY_FRAGMENT_LIST
    end

    if not components then
        components = __safe_tbls.__EMPTY_COMPONENT_LIST
    end

    local fragment_count = #fragments
    local component_count = #components

    if __debug_mode then
        if chunk then __debug_fns.validate_chunk(chunk) end
        __debug_fns.validate_fragment_list(fragments, fragment_count)
    end

    local entity = __acquire_id()

    if not chunk then
        return entity
    end

    if __defer_depth > 0 then
        __defer_spawn_entity_at(entity, chunk,
            fragments, fragment_count,
            components, component_count)
        return entity
    end

    __evolved_defer()
    do
        __spawn_entity_at(entity, chunk, fragments, fragment_count, components)
    end
    __evolved_commit()

    return entity
end

---@param fragments? evolved.fragment[]
---@param components? evolved.component[]
---@return evolved.entity entity
__evolved_spawn_with = function(fragments, components)
    if not fragments then
        fragments = __safe_tbls.__EMPTY_FRAGMENT_LIST
    end

    if not components then
        components = __safe_tbls.__EMPTY_COMPONENT_LIST
    end

    local fragment_count = #fragments
    local component_count = #components

    if __debug_mode then
        __debug_fns.validate_fragment_list(fragments, fragment_count)
    end

    local entity, chunk = __acquire_id(), __chunk_fragment_list(fragments, fragment_count)

    if not chunk then
        return entity
    end

    if __defer_depth > 0 then
        __defer_spawn_entity_with(entity, chunk,
            fragments, fragment_count,
            components, component_count)
        return entity
    end

    __evolved_defer()
    do
        __spawn_entity_with(entity, chunk, fragments, fragment_count, components)
    end
    __evolved_commit()

    return entity
end

---
---
---
---
---

---@param yesno boolean
__evolved_debug_mode = function(yesno)
    __debug_mode = yesno
end

__evolved_collect_garbage = function()
    if __defer_depth > 0 then
        __defer_call_hook(__evolved_collect_garbage)
        return
    end

    __evolved_defer()

    do
        ---@type evolved.chunk[]
        local working_chunk_stack = __acquire_table(__table_pool_tag.chunk_stack)
        local working_chunk_stack_size = 0

        ---@type evolved.chunk[]
        local postorder_chunk_stack = __acquire_table(__table_pool_tag.chunk_stack)
        local postorder_chunk_stack_size = 0

        for _, root_chunk in __lua_next, __root_chunks do
            working_chunk_stack_size = working_chunk_stack_size + 1
            working_chunk_stack[working_chunk_stack_size] = root_chunk

            while working_chunk_stack_size > 0 do
                local working_chunk = working_chunk_stack[working_chunk_stack_size]

                working_chunk_stack[working_chunk_stack_size] = nil
                working_chunk_stack_size = working_chunk_stack_size - 1

                do
                    local working_chunk_child_list = working_chunk.__child_list
                    local working_chunk_child_count = working_chunk.__child_count

                    __lua_table_move(
                        working_chunk_child_list, 1, working_chunk_child_count,
                        working_chunk_stack_size + 1, working_chunk_stack)

                    working_chunk_stack_size = working_chunk_stack_size + working_chunk_child_count
                end

                postorder_chunk_stack_size = postorder_chunk_stack_size + 1
                postorder_chunk_stack[postorder_chunk_stack_size] = working_chunk
            end
        end

        for postorder_chunk_index = postorder_chunk_stack_size, 1, -1 do
            local postorder_chunk = postorder_chunk_stack[postorder_chunk_index]
            local postorder_chunk_pins = __pinned_chunks[postorder_chunk] or 0

            local is_not_pinned =
                postorder_chunk_pins == 0

            local should_be_purged =
                postorder_chunk.__child_count == 0 and
                postorder_chunk.__entity_count == 0

            if is_not_pinned and should_be_purged then
                __purge_chunk(postorder_chunk)
            end
        end

        __release_table(__table_pool_tag.chunk_stack, working_chunk_stack)
        __release_table(__table_pool_tag.chunk_stack, postorder_chunk_stack)
    end

    __evolved_commit()
end

---
---
---
---
---

local __builder_fns = {}

---@class evolved.entity_builder
---@field package __fragment_list? evolved.fragment[]
---@field package __component_list? evolved.component[]
---@field package __component_count? integer
__builder_fns.entity_builder = {}
__builder_fns.entity_builder.__index = __builder_fns.entity_builder

---@class evolved.fragment_builder
---@field package __tag? boolean
---@field package __name? string
---@field package __single? evolved.component
---@field package __default? evolved.component
---@field package __duplicate? evolved.duplicate
---@field package __on_set? evolved.set_hook
---@field package __on_assign? evolved.set_hook
---@field package __on_insert? evolved.set_hook
---@field package __on_remove? evolved.remove_hook
---@field package __destroy_policy? evolved.id
__builder_fns.fragment_builder = {}
__builder_fns.fragment_builder.__index = __builder_fns.fragment_builder

---@class evolved.query_builder
---@field package __name? string
---@field package __single? evolved.component
---@field package __include_list? evolved.fragment[]
---@field package __exclude_list? evolved.fragment[]
__builder_fns.query_builder = {}
__builder_fns.query_builder.__index = __builder_fns.query_builder

---@class evolved.group_builder
---@field package __name? string
---@field package __single? evolved.component
---@field package __disable? boolean
---@field package __phase? evolved.phase
---@field package __after? evolved.group[]
---@field package __prologue? evolved.prologue
---@field package __epilogue? evolved.epilogue
__builder_fns.group_builder = {}
__builder_fns.group_builder.__index = __builder_fns.group_builder

---@class evolved.phase_builder
---@field package __name? string
---@field package __single? evolved.component
---@field package __disable? boolean
---@field package __prologue? evolved.prologue
---@field package __epilogue? evolved.epilogue
__builder_fns.phase_builder = {}
__builder_fns.phase_builder.__index = __builder_fns.phase_builder

---@class evolved.system_builder
---@field package __name? string
---@field package __single? evolved.component
---@field package __disable? boolean
---@field package __group? evolved.group
---@field package __query? evolved.query
---@field package __execute? evolved.execute
---@field package __prologue? evolved.prologue
---@field package __epilogue? evolved.epilogue
__builder_fns.system_builder = {}
__builder_fns.system_builder.__index = __builder_fns.system_builder

---
---
---
---
---

---@return evolved.entity_builder builder
---@nodiscard
__evolved_entity = function()
    return __lua_setmetatable({}, __builder_fns.entity_builder)
end

---@param fragment evolved.fragment
---@param component evolved.component
---@return evolved.entity_builder builder
function __builder_fns.entity_builder:set(fragment, component)
    local fragment_list = self.__fragment_list
    local component_list = self.__component_list
    local component_count = self.__component_count or 0

    if component_count == 0 then
        fragment_list = __acquire_table(__table_pool_tag.fragment_list)
        component_list = __acquire_table(__table_pool_tag.component_list)
        self.__fragment_list = fragment_list
        self.__component_list = component_list
    end

    ---@cast fragment_list -?
    ---@cast component_list -?

    component_count = component_count + 1
    self.__component_count = component_count

    fragment_list[component_count] = fragment
    component_list[component_count] = component

    return self
end

---@return evolved.entity entity
function __builder_fns.entity_builder:build()
    local fragment_list = self.__fragment_list
    local component_list = self.__component_list
    local component_count = self.__component_count or 0

    self.__fragment_list = nil
    self.__component_list = nil
    self.__component_count = nil

    if component_count == 0 then
        return __evolved_id()
    end

    ---@cast fragment_list -?
    ---@cast component_list -?

    local entity = __evolved_spawn_with(fragment_list, component_list)

    __release_table(__table_pool_tag.fragment_list, fragment_list)
    __release_table(__table_pool_tag.component_list, component_list)

    return entity
end

---
---
---
---
---

---@return evolved.fragment_builder builder
---@nodiscard
__evolved_fragment = function()
    return __lua_setmetatable({}, __builder_fns.fragment_builder)
end

---@return evolved.fragment_builder builder
function __builder_fns.fragment_builder:tag()
    self.__tag = true
    return self
end

---@param name string
---@return evolved.fragment_builder builder
function __builder_fns.fragment_builder:name(name)
    self.__name = name
    return self
end

---@param single evolved.component
---@return evolved.fragment_builder builder
function __builder_fns.fragment_builder:single(single)
    self.__single = single
    return self
end

---@param default evolved.component
---@return evolved.fragment_builder builder
function __builder_fns.fragment_builder:default(default)
    self.__default = default
    return self
end

---@param duplicate evolved.duplicate
---@return evolved.fragment_builder builder
function __builder_fns.fragment_builder:duplicate(duplicate)
    self.__duplicate = duplicate
    return self
end

---@param on_set evolved.set_hook
---@return evolved.fragment_builder builder
function __builder_fns.fragment_builder:on_set(on_set)
    self.__on_set = on_set
    return self
end

---@param on_assign evolved.assign_hook
---@return evolved.fragment_builder builder
function __builder_fns.fragment_builder:on_assign(on_assign)
    self.__on_assign = on_assign
    return self
end

---@param on_insert evolved.insert_hook
---@return evolved.fragment_builder builder
function __builder_fns.fragment_builder:on_insert(on_insert)
    self.__on_insert = on_insert
    return self
end

---@param on_remove evolved.remove_hook
---@return evolved.fragment_builder builder
function __builder_fns.fragment_builder:on_remove(on_remove)
    self.__on_remove = on_remove
    return self
end

---@param destroy_policy evolved.id
---@return evolved.fragment_builder builder
function __builder_fns.fragment_builder:destroy_policy(destroy_policy)
    self.__destroy_policy = destroy_policy
    return self
end

---@return evolved.fragment fragment
function __builder_fns.fragment_builder:build()
    local tag = self.__tag
    local name = self.__name
    local single = self.__single
    local default = self.__default
    local duplicate = self.__duplicate
    local on_set = self.__on_set
    local on_assign = self.__on_assign
    local on_insert = self.__on_insert
    local on_remove = self.__on_remove
    local destroy_policy = self.__destroy_policy

    self.__tag = nil
    self.__name = nil
    self.__single = nil
    self.__default = nil
    self.__duplicate = nil
    self.__on_set = nil
    self.__on_assign = nil
    self.__on_insert = nil
    self.__on_remove = nil
    self.__destroy_policy = nil

    local fragment = __evolved_id()

    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    local component_list = __acquire_table(__table_pool_tag.component_list)
    local component_count = 0

    if tag then
        component_count = component_count + 1
        fragment_list[component_count] = __TAG
        component_list[component_count] = true
    end

    if name then
        component_count = component_count + 1
        fragment_list[component_count] = __NAME
        component_list[component_count] = name
    end

    if single ~= nil then
        component_count = component_count + 1
        fragment_list[component_count] = fragment
        component_list[component_count] = single
    end

    if default ~= nil then
        component_count = component_count + 1
        fragment_list[component_count] = __DEFAULT
        component_list[component_count] = default
    end

    if duplicate then
        component_count = component_count + 1
        fragment_list[component_count] = __DUPLICATE
        component_list[component_count] = duplicate
    end

    if on_set then
        component_count = component_count + 1
        fragment_list[component_count] = __ON_SET
        component_list[component_count] = on_set
    end

    if on_assign then
        component_count = component_count + 1
        fragment_list[component_count] = __ON_ASSIGN
        component_list[component_count] = on_assign
    end

    if on_insert then
        component_count = component_count + 1
        fragment_list[component_count] = __ON_INSERT
        component_list[component_count] = on_insert
    end

    if on_remove then
        component_count = component_count + 1
        fragment_list[component_count] = __ON_REMOVE
        component_list[component_count] = on_remove
    end

    if destroy_policy then
        component_count = component_count + 1
        fragment_list[component_count] = __DESTROY_POLICY
        component_list[component_count] = destroy_policy
    end

    __evolved_multi_set(fragment, fragment_list, component_list)

    __release_table(__table_pool_tag.fragment_list, fragment_list)
    __release_table(__table_pool_tag.component_list, component_list)

    return fragment
end

---
---
---
---
---

---@return evolved.query_builder builder
---@nodiscard
__evolved_query = function()
    return __lua_setmetatable({}, __builder_fns.query_builder)
end

---@param name string
---@return evolved.query_builder builder
function __builder_fns.query_builder:name(name)
    self.__name = name
    return self
end

---@param single evolved.component
---@return evolved.query_builder builder
function __builder_fns.query_builder:single(single)
    self.__single = single
    return self
end

---@param ... evolved.fragment fragments
---@return evolved.query_builder builder
function __builder_fns.query_builder:include(...)
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return self
    end

    local include_list = self.__include_list

    if not include_list then
        include_list = __lua_table_new(fragment_count, 0)
        self.__include_list = include_list
    end

    local include_count = #include_list

    for i = 1, fragment_count do
        ---@type evolved.fragment
        local fragment = __lua_select(i, ...)
        include_list[include_count + i] = fragment
    end

    return self
end

---@param ... evolved.fragment fragments
---@return evolved.query_builder builder
function __builder_fns.query_builder:exclude(...)
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return self
    end

    local exclude_list = self.__exclude_list

    if not exclude_list then
        exclude_list = __lua_table_new(fragment_count, 0)
        self.__exclude_list = exclude_list
    end

    local exclude_count = #exclude_list

    for i = 1, fragment_count do
        ---@type evolved.fragment
        local fragment = __lua_select(i, ...)
        exclude_list[exclude_count + i] = fragment
    end

    return self
end

---@return evolved.query query
function __builder_fns.query_builder:build()
    local name = self.__name
    local single = self.__single
    local include_list = self.__include_list
    local exclude_list = self.__exclude_list

    self.__name = nil
    self.__single = nil
    self.__include_list = nil
    self.__exclude_list = nil

    local query = __evolved_id()

    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    local component_list = __acquire_table(__table_pool_tag.component_list)
    local component_count = 0

    if name then
        component_count = component_count + 1
        fragment_list[component_count] = __NAME
        component_list[component_count] = name
    end

    if single ~= nil then
        component_count = component_count + 1
        fragment_list[component_count] = query
        component_list[component_count] = single
    end

    if include_list then
        component_count = component_count + 1
        fragment_list[component_count] = __INCLUDES
        component_list[component_count] = include_list
    end

    if exclude_list then
        component_count = component_count + 1
        fragment_list[component_count] = __EXCLUDES
        component_list[component_count] = exclude_list
    end

    __evolved_multi_set(query, fragment_list, component_list)

    __release_table(__table_pool_tag.fragment_list, fragment_list)
    __release_table(__table_pool_tag.component_list, component_list)

    return query
end

---
---
---
---
---

---@return evolved.group_builder builder
---@nodiscard
__evolved_group = function()
    return __lua_setmetatable({}, __builder_fns.group_builder)
end

---@param name string
---@return evolved.group_builder builder
function __builder_fns.group_builder:name(name)
    self.__name = name
    return self
end

---@param single evolved.component
---@return evolved.group_builder builder
function __builder_fns.group_builder:single(single)
    self.__single = single
    return self
end

---@return evolved.group_builder builder
function __builder_fns.group_builder:disable()
    self.__disable = true
    return self
end

---@param phase evolved.phase
---@return evolved.group_builder builder
function __builder_fns.group_builder:phase(phase)
    self.__phase = phase
    return self
end

---@param ... evolved.group groups
---@return evolved.group_builder builder
function __builder_fns.group_builder:after(...)
    local group_count = __lua_select('#', ...)

    if group_count == 0 then
        return self
    end

    local after = self.__after

    if not after then
        after = __lua_table_new(group_count, 0)
        self.__after = after
    end

    local after_count = #after

    for i = 1, group_count do
        after_count = after_count + 1
        after[after_count] = __lua_select(i, ...)
    end

    return self
end

---@param prologue evolved.prologue
---@return evolved.group_builder builder
function __builder_fns.group_builder:prologue(prologue)
    self.__prologue = prologue
    return self
end

---@param epilogue evolved.epilogue
---@return evolved.group_builder builder
function __builder_fns.group_builder:epilogue(epilogue)
    self.__epilogue = epilogue
    return self
end

---@return evolved.group group
function __builder_fns.group_builder:build()
    local name = self.__name
    local single = self.__single
    local disable = self.__disable
    local phase = self.__phase
    local after = self.__after
    local prologue = self.__prologue
    local epilogue = self.__epilogue

    self.__name = nil
    self.__single = nil
    self.__disable = nil
    self.__phase = nil
    self.__after = nil
    self.__prologue = nil
    self.__epilogue = nil

    local group = __evolved_id()

    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    local component_list = __acquire_table(__table_pool_tag.component_list)
    local component_count = 0

    if name then
        component_count = component_count + 1
        fragment_list[component_count] = __NAME
        component_list[component_count] = name
    end

    if single ~= nil then
        component_count = component_count + 1
        fragment_list[component_count] = group
        component_list[component_count] = single
    end

    if disable then
        component_count = component_count + 1
        fragment_list[component_count] = __DISABLED
        component_list[component_count] = true
    end

    if phase then
        component_count = component_count + 1
        fragment_list[component_count] = __PHASE
        component_list[component_count] = phase
    end

    if after then
        component_count = component_count + 1
        fragment_list[component_count] = __AFTER
        component_list[component_count] = after
    end

    if prologue then
        component_count = component_count + 1
        fragment_list[component_count] = __PROLOGUE
        component_list[component_count] = prologue
    end

    if epilogue then
        component_count = component_count + 1
        fragment_list[component_count] = __EPILOGUE
        component_list[component_count] = epilogue
    end

    __evolved_multi_set(group, fragment_list, component_list)

    __release_table(__table_pool_tag.fragment_list, fragment_list)
    __release_table(__table_pool_tag.component_list, component_list)

    return group
end

---
---
---
---
---

---@return evolved.phase_builder builder
---@nodiscard
__evolved_phase = function()
    return __lua_setmetatable({}, __builder_fns.phase_builder)
end

---@param name string
---@return evolved.phase_builder builder
function __builder_fns.phase_builder:name(name)
    self.__name = name
    return self
end

---@param single evolved.component
---@return evolved.phase_builder builder
function __builder_fns.phase_builder:single(single)
    self.__single = single
    return self
end

---@return evolved.phase_builder builder
function __builder_fns.phase_builder:disable()
    self.__disable = true
    return self
end

---@param prologue evolved.prologue
---@return evolved.phase_builder builder
function __builder_fns.phase_builder:prologue(prologue)
    self.__prologue = prologue
    return self
end

---@param epilogue evolved.epilogue
---@return evolved.phase_builder builder
function __builder_fns.phase_builder:epilogue(epilogue)
    self.__epilogue = epilogue
    return self
end

---@return evolved.phase phase
function __builder_fns.phase_builder:build()
    local name = self.__name
    local single = self.__single
    local disable = self.__disable
    local prologue = self.__prologue
    local epilogue = self.__epilogue

    self.__name = nil
    self.__single = nil
    self.__disable = nil
    self.__prologue = nil
    self.__epilogue = nil

    local phase = __evolved_id()

    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    local component_list = __acquire_table(__table_pool_tag.component_list)
    local component_count = 0

    if name then
        component_count = component_count + 1
        fragment_list[component_count] = __NAME
        component_list[component_count] = name
    end

    if single ~= nil then
        component_count = component_count + 1
        fragment_list[component_count] = phase
        component_list[component_count] = single
    end

    if disable then
        component_count = component_count + 1
        fragment_list[component_count] = __DISABLED
        component_list[component_count] = true
    end

    if prologue then
        component_count = component_count + 1
        fragment_list[component_count] = __PROLOGUE
        component_list[component_count] = prologue
    end

    if epilogue then
        component_count = component_count + 1
        fragment_list[component_count] = __EPILOGUE
        component_list[component_count] = epilogue
    end

    __evolved_multi_set(phase, fragment_list, component_list)

    __release_table(__table_pool_tag.fragment_list, fragment_list)
    __release_table(__table_pool_tag.component_list, component_list)

    return phase
end

---
---
---
---
---

---@return evolved.system_builder builder
---@nodiscard
__evolved_system = function()
    return __lua_setmetatable({}, __builder_fns.system_builder)
end

---@param name string
---@return evolved.system_builder builder
function __builder_fns.system_builder:name(name)
    self.__name = name
    return self
end

---@param single evolved.component
---@return evolved.system_builder builder
function __builder_fns.system_builder:single(single)
    self.__single = single
    return self
end

---@return evolved.system_builder builder
function __builder_fns.system_builder:disable()
    self.__disable = true
    return self
end

---@param group evolved.group
---@return evolved.system_builder builder
function __builder_fns.system_builder:group(group)
    self.__group = group
    return self
end

---@param query evolved.query
---@return evolved.system_builder builder
function __builder_fns.system_builder:query(query)
    self.__query = query
    return self
end

---@param execute evolved.execute
---@return evolved.system_builder builder
function __builder_fns.system_builder:execute(execute)
    self.__execute = execute
    return self
end

---@param prologue evolved.prologue
---@return evolved.system_builder builder
function __builder_fns.system_builder:prologue(prologue)
    self.__prologue = prologue
    return self
end

---@param epilogue evolved.epilogue
---@return evolved.system_builder builder
function __builder_fns.system_builder:epilogue(epilogue)
    self.__epilogue = epilogue
    return self
end

---@return evolved.system system
function __builder_fns.system_builder:build()
    local name = self.__name
    local single = self.__single
    local disable = self.__disable
    local group = self.__group
    local query = self.__query
    local execute = self.__execute
    local prologue = self.__prologue
    local epilogue = self.__epilogue

    self.__name = nil
    self.__single = nil
    self.__disable = nil
    self.__group = nil
    self.__query = nil
    self.__execute = nil
    self.__prologue = nil
    self.__epilogue = nil

    local system = __evolved_id()

    local fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    local component_list = __acquire_table(__table_pool_tag.component_list)
    local component_count = 0

    if name then
        component_count = component_count + 1
        fragment_list[component_count] = __NAME
        component_list[component_count] = name
    end

    if single ~= nil then
        component_count = component_count + 1
        fragment_list[component_count] = system
        component_list[component_count] = single
    end

    if disable then
        component_count = component_count + 1
        fragment_list[component_count] = __DISABLED
        component_list[component_count] = true
    end

    if group then
        component_count = component_count + 1
        fragment_list[component_count] = __GROUP
        component_list[component_count] = group
    end

    if query then
        component_count = component_count + 1
        fragment_list[component_count] = __QUERY
        component_list[component_count] = query
    end

    if execute then
        component_count = component_count + 1
        fragment_list[component_count] = __EXECUTE
        component_list[component_count] = execute
    end

    if prologue then
        component_count = component_count + 1
        fragment_list[component_count] = __PROLOGUE
        component_list[component_count] = prologue
    end

    if epilogue then
        component_count = component_count + 1
        fragment_list[component_count] = __EPILOGUE
        component_list[component_count] = epilogue
    end

    __evolved_multi_set(system, fragment_list, component_list)

    __release_table(__table_pool_tag.fragment_list, fragment_list)
    __release_table(__table_pool_tag.component_list, component_list)

    return system
end

---
---
---
---
---

---@param chunk evolved.chunk
---@return boolean
local function __update_chunk_caches_trace(chunk)
    local chunk_parent, chunk_fragment = chunk.__parent, chunk.__fragment

    local has_setup_hooks = (chunk_parent and chunk_parent.__has_setup_hooks)
        or __evolved_has_any(chunk_fragment, __DEFAULT, __DUPLICATE)

    local has_assign_hooks = (chunk_parent and chunk_parent.__has_assign_hooks)
        or __evolved_has_any(chunk_fragment, __ON_SET, __ON_ASSIGN)

    local has_insert_hooks = (chunk_parent and chunk_parent.__has_insert_hooks)
        or __evolved_has_any(chunk_fragment, __ON_SET, __ON_INSERT)

    local has_remove_hooks = (chunk_parent and chunk_parent.__has_remove_hooks)
        or __evolved_has(chunk_fragment, __ON_REMOVE)

    chunk.__has_setup_hooks = has_setup_hooks
    chunk.__has_assign_hooks = has_assign_hooks
    chunk.__has_insert_hooks = has_insert_hooks
    chunk.__has_remove_hooks = has_remove_hooks

    return true
end

---@param fragment evolved.fragment
local function __update_fragment_hooks(fragment)
    __trace_fragment_chunks(fragment, __update_chunk_caches_trace, fragment)
end

__evolved_set(__ON_SET, __ON_INSERT, __update_fragment_hooks)
__evolved_set(__ON_ASSIGN, __ON_INSERT, __update_fragment_hooks)
__evolved_set(__ON_INSERT, __ON_INSERT, __update_fragment_hooks)
__evolved_set(__ON_REMOVE, __ON_INSERT, __update_fragment_hooks)

__evolved_set(__ON_SET, __ON_REMOVE, __update_fragment_hooks)
__evolved_set(__ON_ASSIGN, __ON_REMOVE, __update_fragment_hooks)
__evolved_set(__ON_INSERT, __ON_REMOVE, __update_fragment_hooks)
__evolved_set(__ON_REMOVE, __ON_REMOVE, __update_fragment_hooks)

---
---
---
---
---

---@param chunk evolved.chunk
---@param fragment evolved.fragment
---@return boolean
local function __update_chunk_tags_trace(chunk, fragment)
    local component_count = chunk.__component_count
    local component_indices = chunk.__component_indices
    local component_storages = chunk.__component_storages
    local component_fragments = chunk.__component_fragments

    local component_index = component_indices[fragment]

    if component_index and __evolved_has(fragment, __TAG) then
        if component_index ~= component_count then
            local last_component_storage = component_storages[component_count]
            local last_component_fragment = component_fragments[component_count]
            component_indices[last_component_fragment] = component_index
            component_storages[component_index] = last_component_storage
            component_fragments[component_index] = last_component_fragment
        end

        component_indices[fragment] = nil
        component_storages[component_count] = nil
        component_fragments[component_count] = nil

        component_count = component_count - 1
        chunk.__component_count = component_count
    end

    if not component_index and not __evolved_has(fragment, __TAG) then
        component_count = component_count + 1
        chunk.__component_count = component_count

        local component_storage = __component_storage(fragment)
        local component_storage_index = component_count

        component_indices[fragment] = component_storage_index
        component_storages[component_storage_index] = component_storage
        component_fragments[component_storage_index] = fragment

        ---@type evolved.default?, evolved.duplicate?
        local fragment_default, fragment_duplicate =
            __evolved_get(fragment, __DEFAULT, __DUPLICATE)

        if fragment_duplicate then
            for place = 1, chunk.__entity_count do
                local new_component = fragment_default
                if new_component ~= nil then new_component = fragment_duplicate(new_component) end
                if new_component == nil then new_component = true end
                component_storage[place] = new_component
            end
        else
            local new_component = fragment_default
            if new_component == nil then new_component = true end
            for place = 1, chunk.__entity_count do
                component_storage[place] = new_component
            end
        end
    end

    return true
end

local function __update_fragment_tags(fragment)
    __trace_fragment_chunks(fragment, __update_chunk_tags_trace, fragment)
end

---@param fragment evolved.fragment
local function __update_fragment_defaults(fragment)
    __trace_fragment_chunks(fragment, __update_chunk_caches_trace, fragment)
end

---@param fragment evolved.fragment
local function __update_fragment_duplicates(fragment)
    __trace_fragment_chunks(fragment, __update_chunk_caches_trace, fragment)
end

__evolved_set(__TAG, __ON_INSERT, __update_fragment_tags)
__evolved_set(__TAG, __ON_REMOVE, __update_fragment_tags)

__evolved_set(__DEFAULT, __ON_INSERT, __update_fragment_defaults)
__evolved_set(__DEFAULT, __ON_REMOVE, __update_fragment_defaults)

__evolved_set(__DUPLICATE, __ON_INSERT, __update_fragment_duplicates)
__evolved_set(__DUPLICATE, __ON_REMOVE, __update_fragment_duplicates)

---
---
---
---
---

__evolved_set(__TAG, __NAME, 'TAG')
__evolved_set(__NAME, __NAME, 'NAME')
__evolved_set(__DEFAULT, __NAME, 'DEFAULT')
__evolved_set(__DUPLICATE, __NAME, 'DUPLICATE')

__evolved_set(__INCLUDES, __NAME, 'INCLUDES')
__evolved_set(__EXCLUDES, __NAME, 'EXCLUDES')

__evolved_set(__ON_SET, __NAME, 'ON_SET')
__evolved_set(__ON_ASSIGN, __NAME, 'ON_ASSIGN')
__evolved_set(__ON_INSERT, __NAME, 'ON_INSERT')
__evolved_set(__ON_REMOVE, __NAME, 'ON_REMOVE')

__evolved_set(__PHASE, __NAME, 'PHASE')
__evolved_set(__GROUP, __NAME, 'GROUP')
__evolved_set(__AFTER, __NAME, 'AFTER')

__evolved_set(__QUERY, __NAME, 'QUERY')
__evolved_set(__EXECUTE, __NAME, 'EXECUTE')

__evolved_set(__PROLOGUE, __NAME, 'PROLOGUE')
__evolved_set(__EPILOGUE, __NAME, 'EPILOGUE')

__evolved_set(__DISABLED, __NAME, 'DISABLED')

__evolved_set(__DESTROY_POLICY, __NAME, 'DESTROY_POLICY')
__evolved_set(__DESTROY_POLICY_DESTROY_ENTITY, __NAME, 'DESTROY_POLICY_DESTROY_ENTITY')
__evolved_set(__DESTROY_POLICY_REMOVE_FRAGMENT, __NAME, 'DESTROY_POLICY_REMOVE_FRAGMENT')

---
---
---
---
---

__evolved_set(__TAG, __TAG)

__evolved_set(__INCLUDES, __DEFAULT, {})
__evolved_set(__INCLUDES, __DUPLICATE, __list_copy)

__evolved_set(__EXCLUDES, __DEFAULT, {})
__evolved_set(__EXCLUDES, __DUPLICATE, __list_copy)

__evolved_set(__AFTER, __DEFAULT, {})
__evolved_set(__AFTER, __DUPLICATE, __list_copy)

__evolved_set(__DISABLED, __TAG)

---
---
---
---
---

---@param query evolved.query
---@param include_list evolved.fragment[]
__evolved_set(__INCLUDES, __ON_SET, function(query, _, include_list)
    local include_count = #include_list

    if include_count == 0 then
        __query_sorted_includes[query] = nil
        return
    end

    local sorted_includes = __assoc_list_new(include_count)

    for include_index = 1, include_count do
        local include = include_list[include_index]
        __assoc_list_insert(sorted_includes, include)
    end

    __assoc_list_sort(sorted_includes)
    __query_sorted_includes[query] = sorted_includes
end)

__evolved_set(__INCLUDES, __ON_REMOVE, function(query)
    __query_sorted_includes[query] = nil
end)

---
---
---
---
---

---@param query evolved.query
---@param exclude_list evolved.fragment[]
__evolved_set(__EXCLUDES, __ON_SET, function(query, _, exclude_list)
    local exclude_count = #exclude_list

    if exclude_count == 0 then
        __query_sorted_excludes[query] = nil
        return
    end

    local sorted_excludes = __assoc_list_new(exclude_count)

    for exclude_index = 1, exclude_count do
        local exclude = exclude_list[exclude_index]
        __assoc_list_insert(sorted_excludes, exclude)
    end

    __assoc_list_sort(sorted_excludes)
    __query_sorted_excludes[query] = sorted_excludes
end)

__evolved_set(__EXCLUDES, __ON_REMOVE, function(query)
    __query_sorted_excludes[query] = nil
end)

---
---
---
---
---

---@param group evolved.group
---@param new_phase evolved.phase
---@param old_phase? evolved.phase
__evolved_set(__PHASE, __ON_SET, function(group, _, new_phase, old_phase)
    if new_phase == old_phase then
        return
    end

    if old_phase then
        local old_phase_groups = __phase_groups[old_phase]

        if old_phase_groups then
            __assoc_list_remove(old_phase_groups, group)

            if old_phase_groups.__item_count == 0 then
                __phase_groups[old_phase] = nil
            end
        end
    end

    local new_phase_groups = __phase_groups[new_phase]

    if not new_phase_groups then
        new_phase_groups = __assoc_list_new(4)
        __phase_groups[new_phase] = new_phase_groups
    end

    __assoc_list_insert(new_phase_groups, group)
end)

---@param group evolved.group
---@param old_phase evolved.phase
__evolved_set(__PHASE, __ON_REMOVE, function(group, _, old_phase)
    local old_phase_groups = __phase_groups[old_phase]

    if old_phase_groups then
        __assoc_list_remove(old_phase_groups, group)

        if old_phase_groups.__item_count == 0 then
            __phase_groups[old_phase] = nil
        end
    end
end)

---
---
---
---
---

---@param system evolved.system
---@param new_group evolved.group
---@param old_group? evolved.group
__evolved_set(__GROUP, __ON_SET, function(system, _, new_group, old_group)
    if new_group == old_group then
        return
    end

    if old_group then
        local old_group_systems = __group_systems[old_group]

        if old_group_systems then
            __assoc_list_remove(old_group_systems, system)

            if old_group_systems.__item_count == 0 then
                __group_systems[old_group] = nil
            end
        end
    end

    local new_group_systems = __group_systems[new_group]

    if not new_group_systems then
        new_group_systems = __assoc_list_new(4)
        __group_systems[new_group] = new_group_systems
    end

    __assoc_list_insert(new_group_systems, system)
end)

---@param system evolved.system
---@param old_group evolved.group
__evolved_set(__GROUP, __ON_REMOVE, function(system, _, old_group)
    local old_group_systems = __group_systems[old_group]

    if old_group_systems then
        __assoc_list_remove(old_group_systems, system)

        if old_group_systems.__item_count == 0 then
            __group_systems[old_group] = nil
        end
    end
end)

---
---
---
---
---

---@param group evolved.group
---@param new_after_list evolved.group[]
__evolved_set(__AFTER, __ON_SET, function(group, _, new_after_list)
    local new_after_count = #new_after_list

    if new_after_count == 0 then
        __group_dependencies[group] = nil
        return
    end

    local new_dependencies = __assoc_list_new(new_after_count)

    for new_after_index = 1, new_after_count do
        local new_after = new_after_list[new_after_index]
        __assoc_list_insert(new_dependencies, new_after)
    end

    __group_dependencies[group] = new_dependencies
end)

---@param group evolved.group
__evolved_set(__AFTER, __ON_REMOVE, function(group)
    __group_dependencies[group] = nil
end)

---
---
---
---
---

evolved.TAG = __TAG
evolved.NAME = __NAME
evolved.DEFAULT = __DEFAULT
evolved.DUPLICATE = __DUPLICATE

evolved.INCLUDES = __INCLUDES
evolved.EXCLUDES = __EXCLUDES

evolved.ON_SET = __ON_SET
evolved.ON_ASSIGN = __ON_ASSIGN
evolved.ON_INSERT = __ON_INSERT
evolved.ON_REMOVE = __ON_REMOVE

evolved.PHASE = __PHASE
evolved.GROUP = __GROUP
evolved.AFTER = __AFTER

evolved.QUERY = __QUERY
evolved.EXECUTE = __EXECUTE

evolved.PROLOGUE = __PROLOGUE
evolved.EPILOGUE = __EPILOGUE

evolved.DISABLED = __DISABLED

evolved.DESTROY_POLICY = __DESTROY_POLICY
evolved.DESTROY_POLICY_DESTROY_ENTITY = __DESTROY_POLICY_DESTROY_ENTITY
evolved.DESTROY_POLICY_REMOVE_FRAGMENT = __DESTROY_POLICY_REMOVE_FRAGMENT

evolved.id = __evolved_id

evolved.pack = __evolved_pack
evolved.unpack = __evolved_unpack

evolved.defer = __evolved_defer
evolved.commit = __evolved_commit

evolved.is_alive = __evolved_is_alive
evolved.is_alive_all = __evolved_is_alive_all
evolved.is_alive_any = __evolved_is_alive_any

evolved.is_empty = __evolved_is_empty
evolved.is_empty_all = __evolved_is_empty_all
evolved.is_empty_any = __evolved_is_empty_any

evolved.get = __evolved_get
evolved.has = __evolved_has
evolved.has_all = __evolved_has_all
evolved.has_any = __evolved_has_any

evolved.set = __evolved_set
evolved.remove = __evolved_remove
evolved.clear = __evolved_clear
evolved.destroy = __evolved_destroy

evolved.multi_set = __evolved_multi_set
evolved.multi_remove = __evolved_multi_remove

evolved.batch_set = __evolved_batch_set
evolved.batch_remove = __evolved_batch_remove
evolved.batch_clear = __evolved_batch_clear
evolved.batch_destroy = __evolved_batch_destroy

evolved.batch_multi_set = __evolved_batch_multi_set
evolved.batch_multi_remove = __evolved_batch_multi_remove

evolved.chunk = __evolved_chunk

evolved.entities = __evolved_entities
evolved.fragments = __evolved_fragments
evolved.components = __evolved_components

evolved.each = __evolved_each
evolved.execute = __evolved_execute

evolved.process = __evolved_process

evolved.spawn_at = __evolved_spawn_at
evolved.spawn_with = __evolved_spawn_with

evolved.debug_mode = __evolved_debug_mode
evolved.collect_garbage = __evolved_collect_garbage

evolved.entity = __evolved_entity
evolved.fragment = __evolved_fragment
evolved.query = __evolved_query
evolved.group = __evolved_group
evolved.phase = __evolved_phase
evolved.system = __evolved_system

evolved.collect_garbage()

return evolved
