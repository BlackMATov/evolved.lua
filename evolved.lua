local evolved = {
    __HOMEPAGE = 'https://github.com/BlackMATov/evolved.lua',
    __DESCRIPTION = 'Evolved ECS (Entity-Component-System) for Lua',
    __VERSION = '1.5.0',
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
---@alias evolved.system evolved.id

---@alias evolved.component any
---@alias evolved.storage evolved.component[]

---@alias evolved.default evolved.component
---@alias evolved.duplicate fun(component: evolved.component): evolved.component

---@alias evolved.execute fun(
---  chunk: evolved.chunk,
---  entity_list: evolved.entity[],
---  entity_count: integer)

---@alias evolved.prologue fun()
---@alias evolved.epilogue fun()

---@alias evolved.set_hook fun(
---  entity: evolved.entity,
---  fragment: evolved.fragment,
---  new_component: evolved.component,
---  old_component: evolved.component)

---@alias evolved.assign_hook fun(
---  entity: evolved.entity,
---  fragment: evolved.fragment,
---  new_component: evolved.component,
---  old_component: evolved.component)

---@alias evolved.insert_hook fun(
---  entity: evolved.entity,
---  fragment: evolved.fragment,
---  new_component: evolved.component)

---@alias evolved.remove_hook fun(
---  entity: evolved.entity,
---  fragment: evolved.fragment,
---  old_component: evolved.component)

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

---@alias evolved.each_iterator fun(
---  state: evolved.each_state?):
---    evolved.fragment?, evolved.component?

---@alias evolved.execute_iterator fun(
---  state: evolved.execute_state?):
---    evolved.chunk?, evolved.entity[]?, integer?

---
---
---
---
---

--[=[------------------------------------------------------------------\
  |              |-------- OPTIONS --------|- SECONDARY -|-- PRIMARY --|
  | IDENTIFIER'S |                         |             |             |
  |    ANATOMY   |         12 bits         |   20 bits   |   20 bits   |
  |              |                         |             |             |
  |--------------|-------------------------|-------------|-------------|
  |           ID |         RESERVED        |   version   |    index    |
  \------------------------------------------------------------------]=]

---
---
---
---
---

local __debug_mode = false ---@type boolean

local __freelist_ids = {} ---@type integer[]
local __acquired_count = 0 ---@type integer
local __available_primary = 0 ---@type integer

local __defer_depth = 0 ---@type integer
local __defer_points = {} ---@type integer[]
local __defer_length = 0 ---@type integer
local __defer_bytecode = {} ---@type any[]

local __root_chunks = {} ---@type table<evolved.fragment, evolved.chunk>
local __major_chunks = {} ---@type table<evolved.fragment, evolved.assoc_list<evolved.chunk>>
local __minor_chunks = {} ---@type table<evolved.fragment, evolved.assoc_list<evolved.chunk>>

local __query_chunks = {} ---@type table<evolved.query, evolved.assoc_list<evolved.chunk>>
local __major_queries = {} ---@type table<evolved.fragment, evolved.assoc_list<evolved.query>>

local __entity_chunks = {} ---@type table<integer, evolved.chunk>
local __entity_places = {} ---@type table<integer, integer>

local __structural_changes = 0 ---@type integer

local __sorted_includes = {} ---@type table<evolved.query, evolved.assoc_list<evolved.fragment>>
local __sorted_excludes = {} ---@type table<evolved.query, evolved.assoc_list<evolved.fragment>>
local __sorted_requires = {} ---@type table<evolved.fragment, evolved.assoc_list<evolved.fragment>>

local __subsystem_groups = {} ---@type table<evolved.system, evolved.system>
local __group_subsystems = {} ---@type table<evolved.system, evolved.assoc_list<evolved.system>>

---
---
---
---
---

---@class evolved.chunk
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
---@field package __component_defaults evolved.default[]
---@field package __component_duplicates evolved.duplicate[]
---@field package __with_fragment_edges table<evolved.fragment, evolved.chunk>
---@field package __without_fragment_edges table<evolved.fragment, evolved.chunk>
---@field package __without_unique_fragments? evolved.chunk
---@field package __unreachable_or_collected boolean
---@field package __has_setup_hooks boolean
---@field package __has_assign_hooks boolean
---@field package __has_insert_hooks boolean
---@field package __has_remove_hooks boolean
---@field package __has_unique_major boolean
---@field package __has_unique_minors boolean
---@field package __has_unique_fragments boolean
---@field package __has_explicit_major boolean
---@field package __has_explicit_minors boolean
---@field package __has_explicit_fragments boolean
---@field package __has_internal_major boolean
---@field package __has_internal_minors boolean
---@field package __has_internal_fragments boolean
---@field package __has_required_fragments boolean
local __chunk_mt = {}
__chunk_mt.__index = __chunk_mt

---@class evolved.builder
---@field package __chunk? evolved.chunk
---@field package __components table<evolved.fragment, evolved.component>
local __builder_mt = {}
__builder_mt.__index = __builder_mt

---
---
---
---
---

local __lua_error = error
local __lua_next = next
local __lua_print = print
local __lua_select = select
local __lua_setmetatable = setmetatable
local __lua_string_format = string.format
local __lua_table_concat = table.concat
local __lua_table_sort = table.sort
local __lua_tostring = tostring
local __lua_xpcall = xpcall

---@type fun(narray: integer, nhash: integer): table
local __lua_table_new = (function()
    -- https://luajit.org/extensions.html
    -- https://create.roblox.com/docs/reference/engine/libraries/table#create
    -- https://forum.defold.com/t/solved-is-luajit-table-new-function-available-in-defold/78623

    do
        ---@diagnostic disable-next-line: deprecated, undefined-field
        local table_new = table and table.new
        if table_new then
            ---@cast table_new fun(narray: integer, nhash: integer): table
            return table_new
        end
    end

    do
        ---@diagnostic disable-next-line: deprecated, undefined-field
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
        ---@diagnostic disable-next-line: deprecated, undefined-field
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
        ---@diagnostic disable-next-line: deprecated, undefined-field
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
        ---@diagnostic disable-next-line: deprecated, undefined-field
        local table_unpack = unpack
        if table_unpack then return table_unpack end
    end

    do
        ---@diagnostic disable-next-line: deprecated, undefined-field
        local table_unpack = table and table.unpack
        if table_unpack then return table_unpack end
    end
end)()

---@type fun(message?: any, level?: integer): string
local __lua_debug_traceback = (function()
    do
        ---@diagnostic disable-next-line: deprecated, undefined-field
        local debug_traceback = debug and debug.traceback
        if debug_traceback then
            return debug_traceback
        end
    end

    ---@type fun(message?: any, level?: integer): string
    return function(message)
        return __lua_tostring(message)
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
    __lua_error(__lua_string_format('| evolved.lua (e) | %s',
        __lua_string_format(fmt, ...)))
end

---@param fmt string
---@param ... any
local function __warning_fmt(fmt, ...)
    __lua_print(__lua_debug_traceback(__lua_string_format('| evolved.lua (w) | %s',
        __lua_string_format(fmt, ...))))
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
    local available_primary = __available_primary

    if available_primary ~= 0 then
        local acquired_primary = available_primary
        local freelist_id = freelist_ids[acquired_primary]

        local next_available_primary = freelist_id % 2 ^ 20
        local shifted_secondary = freelist_id - next_available_primary

        __available_primary = next_available_primary

        local acquired_id = acquired_primary + shifted_secondary
        freelist_ids[acquired_primary] = acquired_id

        return acquired_id --[[@as evolved.id]]
    else
        local acquired_count = __acquired_count

        if acquired_count == 2 ^ 20 - 1 then
            __error_fmt('id index overflow')
        end

        acquired_count = acquired_count + 1
        __acquired_count = acquired_count

        local acquired_primary = acquired_count
        local shifted_secondary = 2 ^ 20

        local acquired_id = acquired_primary + shifted_secondary
        freelist_ids[acquired_primary] = acquired_id

        return acquired_id --[[@as evolved.id]]
    end
end

---@param id evolved.id
local function __release_id(id)
    local acquired_primary = id % 2 ^ 20
    local shifted_secondary = id - acquired_primary

    local freelist_ids = __freelist_ids

    if freelist_ids[acquired_primary] ~= id then
        __error_fmt('the id (%d) is not acquired or already released', id)
    end

    shifted_secondary = shifted_secondary == 2 ^ 40 - 2 ^ 20
        and 2 ^ 20
        or shifted_secondary + 2 ^ 20

    freelist_ids[acquired_primary] = __available_primary + shifted_secondary
    __available_primary = acquired_primary
end

---
---
---
---
---

---@enum evolved.table_pool_tag
local __table_pool_tag = {
    bytecode = 1,
    chunk_list = 2,
    system_list = 3,
    each_state = 4,
    execute_state = 5,
    entity_set = 6,
    entity_list = 7,
    fragment_set = 8,
    fragment_list = 9,
    component_map = 10,
    component_list = 11,
    __count = 11,
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

local __list_new
local __list_dup

---@param reserve? integer
---@return any[]
---@nodiscard
function __list_new(reserve)
    return __lua_table_new(reserve or 0, 0)
end

---@generic V
---@param list V[]
---@return V[]
---@nodiscard
function __list_dup(list)
    local list_size = #list

    if list_size == 0 then
        return {}
    end

    local dup_list = __list_new(list_size)

    __lua_table_move(
        list, 1, list_size,
        1, dup_list)

    return dup_list
end

---
---
---
---
---

---@class (exact) evolved.assoc_list<K>: {
---  __item_set: { [K]: integer },
---  __item_list: K[],
---  __item_count: integer,
--- }

local __assoc_list_new
local __assoc_list_move
local __assoc_list_move_ex
local __assoc_list_sort
local __assoc_list_sort_ex
local __assoc_list_insert
local __assoc_list_insert_ex
local __assoc_list_remove
local __assoc_list_remove_ex

---@param reserve? integer
---@return evolved.assoc_list
---@nodiscard
function __assoc_list_new(reserve)
    ---@type evolved.assoc_list
    return {
        __item_set = __lua_table_new(0, reserve or 0),
        __item_list = __lua_table_new(reserve or 0, 0),
        __item_count = 0,
    }
end

---@generic K
---@param src_item_list K[]
---@param src_item_first integer
---@param src_item_last integer
---@param dst_al evolved.assoc_list<K>
---@return integer new_dst_item_count
function __assoc_list_move(src_item_list, src_item_first, src_item_last, dst_al)
    local new_dst_item_count = __assoc_list_move_ex(
        src_item_list, src_item_first, src_item_last,
        dst_al.__item_set, dst_al.__item_list, dst_al.__item_count)

    dst_al.__item_count = new_dst_item_count
    return new_dst_item_count
end

---@generic K
---@param src_item_list K[]
---@param src_item_first integer
---@param src_item_last integer
---@param dst_item_set table<K, integer>
---@param dst_item_list K[]
---@param dst_item_count integer
---@return integer new_dst_item_count
---@nodiscard
function __assoc_list_move_ex(src_item_list, src_item_first, src_item_last,
                              dst_item_set, dst_item_list, dst_item_count)
    if src_item_last < src_item_first then
        return dst_item_count
    end

    for src_item_index = src_item_first, src_item_last do
        local src_item = src_item_list[src_item_index]
        if not dst_item_set[src_item] then
            dst_item_count = dst_item_count + 1
            dst_item_set[src_item] = dst_item_count
            dst_item_list[dst_item_count] = src_item
        end
    end

    return dst_item_count
end

---@generic K
---@param al evolved.assoc_list<K>
---@param comp? fun(a: K, b: K): boolean
function __assoc_list_sort(al, comp)
    __assoc_list_sort_ex(
        al.__item_set, al.__item_list, al.__item_count,
        comp)
end

---@generic K
---@param al_item_set table<K, integer>
---@param al_item_list K[]
---@param al_item_count integer
---@param comp? fun(a: K, b: K): boolean
function __assoc_list_sort_ex(al_item_set, al_item_list, al_item_count, comp)
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
---@return integer new_al_count
function __assoc_list_insert(al, item)
    local new_al_count = __assoc_list_insert_ex(
        al.__item_set, al.__item_list, al.__item_count,
        item)

    al.__item_count = new_al_count
    return new_al_count
end

---@generic K
---@param al_item_set table<K, integer>
---@param al_item_list K[]
---@param al_item_count integer
---@param item K
---@return integer new_al_count
---@nodiscard
function __assoc_list_insert_ex(al_item_set, al_item_list, al_item_count, item)
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
---@return integer new_al_count
function __assoc_list_remove(al, item)
    local new_al_count = __assoc_list_remove_ex(
        al.__item_set, al.__item_list, al.__item_count,
        item)

    al.__item_count = new_al_count
    return new_al_count
end

---@generic K
---@param al_item_set table<K, integer>
---@param al_item_list K[]
---@param al_item_count integer
---@param item K
---@return integer new_al_count
---@nodiscard
function __assoc_list_remove_ex(al_item_set, al_item_list, al_item_count, item)
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

local __TAG = __acquire_id()
local __NAME = __acquire_id()

local __UNIQUE = __acquire_id()
local __EXPLICIT = __acquire_id()
local __INTERNAL = __acquire_id()

local __DEFAULT = __acquire_id()
local __DUPLICATE = __acquire_id()

local __PREFAB = __acquire_id()
local __DISABLED = __acquire_id()

local __INCLUDES = __acquire_id()
local __EXCLUDES = __acquire_id()
local __REQUIRES = __acquire_id()

local __ON_SET = __acquire_id()
local __ON_ASSIGN = __acquire_id()
local __ON_INSERT = __acquire_id()
local __ON_REMOVE = __acquire_id()

local __GROUP = __acquire_id()

local __QUERY = __acquire_id()
local __EXECUTE = __acquire_id()

local __PROLOGUE = __acquire_id()
local __EPILOGUE = __acquire_id()

local __DESTRUCTION_POLICY = __acquire_id()
local __DESTRUCTION_POLICY_DESTROY_ENTITY = __acquire_id()
local __DESTRUCTION_POLICY_REMOVE_FRAGMENT = __acquire_id()

---
---
---
---
---

local __safe_tbls = {
    __EMPTY_FRAGMENT_SET = __lua_setmetatable({}, {
        __tostring = function() return 'empty fragment set' end,
        __newindex = function() __error_fmt 'attempt to modify empty fragment set' end
    }) --[[@as table<evolved.fragment, integer>]],

    __EMPTY_FRAGMENT_LIST = __lua_setmetatable({}, {
        __tostring = function() return 'empty fragment list' end,
        __newindex = function() __error_fmt 'attempt to modify empty fragment list' end
    }) --[=[@as evolved.fragment[]]=],

    __EMPTY_COMPONENT_MAP = __lua_setmetatable({}, {
        __tostring = function() return 'empty component map' end,
        __newindex = function() __error_fmt 'attempt to modify empty component map' end
    }) --[[@as table<evolved.fragment, evolved.component>]],

    __EMPTY_COMPONENT_LIST = __lua_setmetatable({}, {
        __tostring = function() return 'empty component list' end,
        __newindex = function() __error_fmt 'attempt to modify empty component list' end
    }) --[=[@as evolved.component[]]=],

    __EMPTY_COMPONENT_STORAGE = __lua_setmetatable({}, {
        __tostring = function() return 'empty component storage' end,
        __newindex = function() __error_fmt 'attempt to modify empty component storage' end
    }) --[=[@as evolved.component[]]=],
}

---
---
---
---
---

local __evolved_id
local __evolved_name

local __evolved_pack
local __evolved_unpack

local __evolved_defer
local __evolved_commit
local __evolved_cancel

local __evolved_spawn
local __evolved_multi_spawn

local __evolved_clone
local __evolved_multi_clone

local __evolved_alive
local __evolved_alive_all
local __evolved_alive_any

local __evolved_empty
local __evolved_empty_all
local __evolved_empty_any

local __evolved_has
local __evolved_has_all
local __evolved_has_any

local __evolved_get

local __evolved_set
local __evolved_remove
local __evolved_clear
local __evolved_destroy

local __evolved_batch_set
local __evolved_batch_remove
local __evolved_batch_clear
local __evolved_batch_destroy

local __evolved_each
local __evolved_execute

local __evolved_locate

local __evolved_process

local __evolved_debug_mode
local __evolved_collect_garbage

local __evolved_chunk
local __evolved_builder

---
---
---
---
---

local __id_name

local __new_chunk

local __update_chunk_caches
local __update_chunk_queries
local __update_chunk_storages

local __trace_major_chunks
local __trace_minor_chunks

local __cache_query_chunks
local __reset_query_chunks

local __update_major_chunks
local __update_major_chunks_trace

local __chunk_with_fragment
local __chunk_with_components
local __chunk_without_fragment
local __chunk_without_fragments
local __chunk_without_unique_fragments

local __chunk_matches
local __chunk_fragments
local __chunk_components

local __chunk_has_fragment
local __chunk_has_all_fragments
local __chunk_has_all_fragment_list
local __chunk_has_any_fragments
local __chunk_has_any_fragment_list

local __chunk_get_all_components

local __chunk_required_fragments
local __fragment_required_fragments

local __detach_entity
local __detach_all_entities

local __spawn_entity
local __multi_spawn_entity

local __clone_entity
local __multi_clone_entity

local __purge_chunk
local __clear_chunk_list
local __destroy_entity_list
local __destroy_fragment_list

local __chunk_set
local __chunk_remove
local __chunk_clear

local __defer_call_hook

local __defer_spawn_entity
local __defer_multi_spawn_entity

local __defer_clone_entity
local __defer_multi_clone_entity

---
---
---
---
---

---@param id evolved.id
---@return string
---@nodiscard
function __id_name(id)
    local id_primary, id_secondary = __evolved_unpack(id)

    ---@type string?
    local id_name = __evolved_get(id, __NAME)

    if id_name then
        return id_name
    end

    return __lua_string_format('$%d#%d:%d', id, id_primary, id_secondary)
end

---@param chunk_parent? evolved.chunk
---@param chunk_fragment evolved.fragment
---@return evolved.chunk
---@nodiscard
function __new_chunk(chunk_parent, chunk_fragment)
    local chunk_fragment_primary = chunk_fragment % 2 ^ 20

    if __freelist_ids[chunk_fragment_primary] ~= chunk_fragment then
        __error_fmt('the id (%s) is not alive and cannot be used for a new chunk',
            __id_name(chunk_fragment))
    end

    local chunk_fragment_set = {} ---@type table<evolved.fragment, integer>
    local chunk_fragment_list = {} ---@type evolved.fragment[]
    local chunk_fragment_count = 0 ---@type integer

    if chunk_parent then
        local chunk_parent_fragment_list = chunk_parent.__fragment_list
        local chunk_parent_fragment_count = chunk_parent.__fragment_count

        chunk_fragment_count = __assoc_list_move_ex(
            chunk_parent_fragment_list, 1, chunk_parent_fragment_count,
            chunk_fragment_set, chunk_fragment_list, chunk_fragment_count)
    end

    do
        chunk_fragment_count = chunk_fragment_count + 1
        chunk_fragment_set[chunk_fragment] = chunk_fragment_count
        chunk_fragment_list[chunk_fragment_count] = chunk_fragment
    end

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
        __component_count = 0,
        __component_indices = {},
        __component_storages = {},
        __component_fragments = {},
        __component_defaults = {},
        __component_duplicates = {},
        __with_fragment_edges = {},
        __without_fragment_edges = {},
        __without_unique_fragments = nil,
        __unreachable_or_collected = false,
        __has_setup_hooks = false,
        __has_assign_hooks = false,
        __has_insert_hooks = false,
        __has_remove_hooks = false,
        __has_unique_major = false,
        __has_unique_minors = false,
        __has_unique_fragments = false,
        __has_explicit_major = false,
        __has_explicit_minors = false,
        __has_explicit_fragments = false,
        __has_internal_major = false,
        __has_internal_minors = false,
        __has_internal_fragments = false,
        __has_required_fragments = false,
    }, __chunk_mt)

    if chunk_parent then
        chunk.__parent = chunk_parent

        chunk_parent.__child_count = __assoc_list_insert_ex(
            chunk_parent.__child_set, chunk_parent.__child_list, chunk_parent.__child_count,
            chunk)

        chunk_parent.__with_fragment_edges[chunk_fragment] = chunk
        chunk.__without_fragment_edges[chunk_fragment] = chunk_parent
    end

    if not chunk_parent then
        if __root_chunks[chunk_fragment] ~= nil then
            __error_fmt('unexpected root chunk %s',
                __lua_tostring(__root_chunks[chunk_fragment]))
        end
        __root_chunks[chunk_fragment] = chunk
    end

    do
        local major = chunk_fragment
        local major_chunks = __major_chunks[major]

        if not major_chunks then
            ---@type evolved.assoc_list<evolved.chunk>
            major_chunks = __assoc_list_new(4)
            __major_chunks[major] = major_chunks
        end

        __assoc_list_insert(major_chunks, chunk)
    end

    for chunk_fragment_index = 1, chunk_fragment_count do
        local minor = chunk_fragment_list[chunk_fragment_index]
        local minor_chunks = __minor_chunks[minor]

        if not minor_chunks then
            ---@type evolved.assoc_list<evolved.chunk>
            minor_chunks = __assoc_list_new(4)
            __minor_chunks[minor] = minor_chunks
        end

        __assoc_list_insert(minor_chunks, chunk)
    end

    __update_chunk_caches(chunk)
    __update_chunk_queries(chunk)
    __update_chunk_storages(chunk)

    return chunk
end

---@param chunk evolved.chunk
function __update_chunk_caches(chunk)
    local chunk_parent = chunk.__parent
    local chunk_fragment = chunk.__fragment

    local has_setup_hooks = chunk_parent ~= nil and chunk_parent.__has_setup_hooks
        or __evolved_has_any(chunk_fragment, __DEFAULT, __DUPLICATE)

    local has_assign_hooks = chunk_parent ~= nil and chunk_parent.__has_assign_hooks
        or __evolved_has_any(chunk_fragment, __ON_SET, __ON_ASSIGN)

    local has_insert_hooks = chunk_parent ~= nil and chunk_parent.__has_insert_hooks
        or __evolved_has_any(chunk_fragment, __ON_SET, __ON_INSERT)

    local has_remove_hooks = chunk_parent ~= nil and chunk_parent.__has_remove_hooks
        or __evolved_has(chunk_fragment, __ON_REMOVE)

    local has_unique_major = __evolved_has(chunk_fragment, __UNIQUE)
    local has_unique_minors = chunk_parent ~= nil and chunk_parent.__has_unique_fragments
    local has_unique_fragments = has_unique_major or has_unique_minors

    local has_explicit_major = __evolved_has(chunk_fragment, __EXPLICIT)
    local has_explicit_minors = chunk_parent ~= nil and chunk_parent.__has_explicit_fragments
    local has_explicit_fragments = has_explicit_major or has_explicit_minors

    local has_internal_major = __evolved_has(chunk_fragment, __INTERNAL)
    local has_internal_minors = chunk_parent ~= nil and chunk_parent.__has_internal_fragments
    local has_internal_fragments = has_internal_major or has_internal_minors

    local has_required_fragments = chunk_parent ~= nil and chunk_parent.__has_required_fragments
        or __evolved_has(chunk_fragment, __REQUIRES)

    chunk.__has_setup_hooks = has_setup_hooks
    chunk.__has_assign_hooks = has_assign_hooks
    chunk.__has_insert_hooks = has_insert_hooks
    chunk.__has_remove_hooks = has_remove_hooks

    chunk.__has_unique_major = has_unique_major
    chunk.__has_unique_minors = has_unique_minors
    chunk.__has_unique_fragments = has_unique_fragments

    chunk.__has_explicit_major = has_explicit_major
    chunk.__has_explicit_minors = has_explicit_minors
    chunk.__has_explicit_fragments = has_explicit_fragments

    chunk.__has_internal_major = has_internal_major
    chunk.__has_internal_minors = has_internal_minors
    chunk.__has_internal_fragments = has_internal_fragments

    chunk.__has_required_fragments = has_required_fragments

    if has_unique_fragments then
        chunk.__without_unique_fragments = nil
    else
        chunk.__without_unique_fragments = chunk
    end
end

---@param chunk evolved.chunk
function __update_chunk_queries(chunk)
    local major_queries = __major_queries[chunk.__fragment]
    local major_query_list = major_queries and major_queries.__item_list
    local major_query_count = major_queries and major_queries.__item_count or 0

    for major_query_index = 1, major_query_count do
        local major_query = major_query_list[major_query_index]
        local major_query_chunks = __query_chunks[major_query]

        if major_query_chunks then
            if __chunk_matches(chunk, major_query) then
                __assoc_list_insert(major_query_chunks, chunk)
            else
                __assoc_list_remove(major_query_chunks, chunk)
            end
        end
    end
end

---@param chunk evolved.chunk
function __update_chunk_storages(chunk)
    local entity_count = chunk.__entity_count

    local fragment_list = chunk.__fragment_list
    local fragment_count = chunk.__fragment_count

    local component_count = chunk.__component_count
    local component_indices = chunk.__component_indices
    local component_storages = chunk.__component_storages
    local component_fragments = chunk.__component_fragments
    local component_defaults = chunk.__component_defaults
    local component_duplicates = chunk.__component_duplicates

    for fragment_index = 1, fragment_count do
        local fragment = fragment_list[fragment_index]
        local component_index = component_indices[fragment]

        ---@type evolved.default?, evolved.duplicate?
        local fragment_default, fragment_duplicate =
            __evolved_get(fragment, __DEFAULT, __DUPLICATE)

        local is_fragment_tag = __evolved_has(fragment, __TAG)

        if component_index and is_fragment_tag then
            if component_index ~= component_count then
                local last_component_storage = component_storages[component_count]
                local last_component_fragment = component_fragments[component_count]
                local last_component_default = component_defaults[component_count]
                local last_component_duplicate = component_duplicates[component_count]

                component_indices[last_component_fragment] = component_index
                component_storages[component_index] = last_component_storage
                component_fragments[component_index] = last_component_fragment
                component_defaults[component_index] = last_component_default
                component_duplicates[component_index] = last_component_duplicate
            end

            component_indices[fragment] = nil
            component_storages[component_count] = nil
            component_fragments[component_count] = nil
            component_defaults[component_count] = nil
            component_duplicates[component_count] = nil

            component_count = component_count - 1
            chunk.__component_count = component_count
        elseif not component_index and not is_fragment_tag then
            component_count = component_count + 1
            chunk.__component_count = component_count

            local component_storage = __lua_table_new(entity_count, 0)
            local component_storage_index = component_count

            component_indices[fragment] = component_storage_index
            component_storages[component_storage_index] = component_storage
            component_fragments[component_storage_index] = fragment
            component_defaults[component_storage_index] = fragment_default
            component_duplicates[component_storage_index] = fragment_duplicate

            if fragment_duplicate then
                for place = 1, entity_count do
                    local new_component = fragment_default
                    if new_component ~= nil then new_component = fragment_duplicate(new_component) end
                    if new_component == nil then new_component = true end
                    component_storage[place] = new_component
                end
            else
                local new_component = fragment_default
                if new_component == nil then new_component = true end
                for place = 1, entity_count do
                    component_storage[place] = new_component
                end
            end
        elseif component_index then
            component_defaults[component_index] = fragment_default
            component_duplicates[component_index] = fragment_duplicate
        end
    end
end

---@param major evolved.fragment
---@param trace fun(chunk: evolved.chunk, ...: any)
---@param ... any additional trace arguments
function __trace_major_chunks(major, trace, ...)
    ---@type evolved.chunk[]
    local chunk_stack = __acquire_table(__table_pool_tag.chunk_list)
    local chunk_stack_size = 0

    do
        local major_chunks = __major_chunks[major]
        local major_chunk_list = major_chunks and major_chunks.__item_list
        local major_chunk_count = major_chunks and major_chunks.__item_count or 0

        if major_chunk_count > 0 then
            __lua_table_move(
                major_chunk_list, 1, major_chunk_count,
                chunk_stack_size + 1, chunk_stack)

            chunk_stack_size = chunk_stack_size + major_chunk_count
        end
    end

    while chunk_stack_size > 0 do
        local chunk = chunk_stack[chunk_stack_size]

        trace(chunk, ...)

        chunk_stack[chunk_stack_size] = nil
        chunk_stack_size = chunk_stack_size - 1

        do
            local chunk_child_list = chunk.__child_list
            local chunk_child_count = chunk.__child_count

            __lua_table_move(
                chunk_child_list, 1, chunk_child_count,
                chunk_stack_size + 1, chunk_stack)

            chunk_stack_size = chunk_stack_size + chunk_child_count
        end
    end

    __release_table(__table_pool_tag.chunk_list, chunk_stack, true)
end

---@param minor evolved.fragment
---@param trace fun(chunk: evolved.chunk, ...: any)
---@param ... any additional trace arguments
function __trace_minor_chunks(minor, trace, ...)
    ---@type evolved.chunk[]
    local chunk_stack = __acquire_table(__table_pool_tag.chunk_list)
    local chunk_stack_size = 0

    do
        local minor_chunks = __minor_chunks[minor]
        local minor_chunk_list = minor_chunks and minor_chunks.__item_list
        local minor_chunk_count = minor_chunks and minor_chunks.__item_count or 0

        if minor_chunk_count > 0 then
            __lua_table_move(
                minor_chunk_list, 1, minor_chunk_count,
                chunk_stack_size + 1, chunk_stack)

            chunk_stack_size = chunk_stack_size + minor_chunk_count
        end
    end

    while chunk_stack_size > 0 do
        local chunk = chunk_stack[chunk_stack_size]

        trace(chunk, ...)

        chunk_stack[chunk_stack_size] = nil
        chunk_stack_size = chunk_stack_size - 1
    end

    __release_table(__table_pool_tag.chunk_list, chunk_stack, true)
end

---@param query evolved.query
---@return evolved.assoc_list<evolved.chunk>
function __cache_query_chunks(query)
    __reset_query_chunks(query)

    local query_includes = __sorted_includes[query]
    local query_include_list = query_includes and query_includes.__item_list
    local query_include_count = query_includes and query_includes.__item_count or 0

    if query_include_count == 0 then
        __error_fmt('the query (%s) has no include fragments and cannot be cached',
            __id_name(query))
    end

    ---@type evolved.assoc_list<evolved.chunk>
    local query_chunks = __assoc_list_new(4)
    __query_chunks[query] = query_chunks

    do
        local query_major = query_include_list[query_include_count]

        local major_chunks = __major_chunks[query_major]
        local major_chunk_list = major_chunks and major_chunks.__item_list
        local major_chunk_count = major_chunks and major_chunks.__item_count or 0

        for major_chunk_index = 1, major_chunk_count do
            local major_chunk = major_chunk_list[major_chunk_index]

            if __chunk_matches(major_chunk, query) then
                __assoc_list_insert(query_chunks, major_chunk)
            end
        end
    end

    return query_chunks
end

---@param query evolved.query
function __reset_query_chunks(query)
    __query_chunks[query] = nil
end

---@param major evolved.fragment
function __update_major_chunks(major)
    if __defer_depth > 0 then
        __defer_call_hook(__update_major_chunks, major)
    else
        __trace_major_chunks(major, __update_major_chunks_trace)
    end
end

---@param chunk evolved.chunk
function __update_major_chunks_trace(chunk)
    __update_chunk_caches(chunk)
    __update_chunk_queries(chunk)
    __update_chunk_storages(chunk)
end

---@param chunk? evolved.chunk
---@param fragment evolved.fragment
---@return evolved.chunk
---@nodiscard
function __chunk_with_fragment(chunk, fragment)
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
        local sib_chunk = chunk.__parent

        while sib_chunk and fragment < sib_chunk.__fragment do
            sib_chunk = sib_chunk.__parent
        end

        sib_chunk = __chunk_with_fragment(sib_chunk, fragment)

        local ini_fragment_list = chunk.__fragment_list
        local ini_fragment_count = chunk.__fragment_count

        local lst_fragment_index = sib_chunk and sib_chunk.__fragment_count or 1

        for ini_fragment_index = lst_fragment_index, ini_fragment_count do
            local ini_fragment = ini_fragment_list[ini_fragment_index]
            sib_chunk = __chunk_with_fragment(sib_chunk, ini_fragment)
        end

        chunk.__with_fragment_edges[fragment] = sib_chunk
        sib_chunk.__without_fragment_edges[fragment] = chunk

        return sib_chunk
    end

    return __new_chunk(chunk, fragment)
end

---@param chunk? evolved.chunk
---@param components table<evolved.fragment, evolved.component>
---@return evolved.chunk?
---@nodiscard
function __chunk_with_components(chunk, components)
    for fragment in __lua_next, components do
        chunk = __chunk_with_fragment(chunk, fragment)
    end

    return chunk
end

---@param chunk? evolved.chunk
---@param fragment evolved.fragment
---@return evolved.chunk?
---@nodiscard
function __chunk_without_fragment(chunk, fragment)
    if not chunk then
        return nil
    end

    if fragment == chunk.__fragment then
        return chunk.__parent
    end

    do
        local without_fragment_edge = chunk.__without_fragment_edges[fragment]
        if without_fragment_edge then return without_fragment_edge end
    end

    if fragment > chunk.__fragment or not chunk.__fragment_set[fragment] then
        return chunk
    end

    do
        local sib_chunk = chunk.__parent

        while sib_chunk and fragment <= sib_chunk.__fragment do
            sib_chunk = sib_chunk.__parent
        end

        local ini_fragment_list = chunk.__fragment_list
        local ini_fragment_count = chunk.__fragment_count

        local lst_fragment_index = sib_chunk and sib_chunk.__fragment_count + 2 or 2

        for ini_fragment_index = lst_fragment_index, ini_fragment_count do
            local ini_fragment = ini_fragment_list[ini_fragment_index]
            sib_chunk = __chunk_with_fragment(sib_chunk, ini_fragment)
        end

        if sib_chunk then
            chunk.__without_fragment_edges[fragment] = sib_chunk
            sib_chunk.__with_fragment_edges[fragment] = chunk
        end

        return sib_chunk
    end
end

---@param chunk? evolved.chunk
---@param ... evolved.fragment fragments
---@return evolved.chunk?
---@nodiscard
function __chunk_without_fragments(chunk, ...)
    if not chunk then
        return nil
    end

    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return chunk
    end

    for fragment_index = 1, fragment_count do
        ---@type evolved.fragment
        local fragment = __lua_select(fragment_index, ...)
        chunk = __chunk_without_fragment(chunk, fragment)
    end

    return chunk
end

---@param chunk? evolved.chunk
---@return evolved.chunk?
---@nodiscard
function __chunk_without_unique_fragments(chunk)
    while chunk and chunk.__has_unique_major do
        chunk = chunk.__parent
    end

    if not chunk or not chunk.__has_unique_fragments then
        return chunk
    end

    local sib_chunk = chunk.__parent

    while sib_chunk and sib_chunk.__has_unique_fragments do
        sib_chunk = sib_chunk.__parent
    end

    local ini_fragment_list = chunk.__fragment_list
    local ini_fragment_count = chunk.__fragment_count

    local lst_fragment_index = sib_chunk and sib_chunk.__fragment_count + 2 or 2

    for ini_fragment_index = lst_fragment_index, ini_fragment_count do
        local ini_fragment = ini_fragment_list[ini_fragment_index]
        if not __evolved_has(ini_fragment, __UNIQUE) then
            sib_chunk = __chunk_with_fragment(sib_chunk, ini_fragment)
        end
    end

    return sib_chunk
end

---@param chunk evolved.chunk
---@param query evolved.query
---@return boolean
---@nodiscard
function __chunk_matches(chunk, query)
    local query_includes = __sorted_includes[query]
    local query_include_set = query_includes and query_includes.__item_set
    local query_include_list = query_includes and query_includes.__item_list
    local query_include_count = query_includes and query_includes.__item_count or 0

    if query_include_count > 0 then
        if not __chunk_has_all_fragment_list(chunk, query_include_list, query_include_count) then
            return false
        end
    elseif chunk.__has_explicit_fragments then
        return false
    end

    local query_excludes = __sorted_excludes[query]
    local query_exclude_list = query_excludes and query_excludes.__item_list
    local query_exclude_count = query_excludes and query_excludes.__item_count or 0

    if query_exclude_count > 0 then
        if __chunk_has_any_fragment_list(chunk, query_exclude_list, query_exclude_count) then
            return false
        end
    end

    if chunk.__has_explicit_fragments then
        local chunk_fragment_list = chunk.__fragment_list
        local chunk_fragment_count = chunk.__fragment_count

        for chunk_fragment_index = 1, chunk_fragment_count do
            local chunk_fragment = chunk_fragment_list[chunk_fragment_index]

            if not query_include_set[chunk_fragment] and __evolved_has(chunk_fragment, __EXPLICIT) then
                return false
            end
        end
    end

    return true
end

---@param head_fragment evolved.fragment
---@param ... evolved.fragment tail_fragments
---@return evolved.chunk
---@nodiscard
function __chunk_fragments(head_fragment, ...)
    local chunk = __root_chunks[head_fragment]
        or __new_chunk(nil, head_fragment)

    for tail_fragment_index = 1, __lua_select('#', ...) do
        ---@type evolved.fragment
        local tail_fragment = __lua_select(tail_fragment_index, ...)
        chunk = chunk.__with_fragment_edges[tail_fragment]
            or __chunk_with_fragment(chunk, tail_fragment)
    end

    return chunk
end

---@param components table<evolved.fragment, evolved.component>
---@return evolved.chunk?
---@nodiscard
function __chunk_components(components)
    local head_fragment = __lua_next(components)

    if not head_fragment then
        return
    end

    local chunk = __root_chunks[head_fragment]
        or __new_chunk(nil, head_fragment)

    for tail_fragment in __lua_next, components, head_fragment do
        chunk = chunk.__with_fragment_edges[tail_fragment]
            or __chunk_with_fragment(chunk, tail_fragment)
    end

    return chunk
end

---@param chunk evolved.chunk
---@param fragment evolved.fragment
---@return boolean
---@nodiscard
function __chunk_has_fragment(chunk, fragment)
    if chunk.__fragment_set[fragment] then
        return true
    end

    return false
end

---@param chunk evolved.chunk
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function __chunk_has_all_fragments(chunk, ...)
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
        return fs[f1] ~= nil and fs[f2] ~= nil and fs[f3] ~= nil and fs[f4] ~= nil
            and __chunk_has_all_fragments(chunk, __lua_select(5, ...))
    end
end

---@param chunk evolved.chunk
---@param fragment_list evolved.fragment[]
---@param fragment_count integer
---@return boolean
---@nodiscard
function __chunk_has_all_fragment_list(chunk, fragment_list, fragment_count)
    if fragment_count == 0 then
        return true
    end

    local fs = chunk.__fragment_set

    for fragment_index = 1, fragment_count do
        local f = fragment_list[fragment_index]
        if fs[f] == nil then
            return false
        end
    end

    return true
end

---@param chunk evolved.chunk
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function __chunk_has_any_fragments(chunk, ...)
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
        return fs[f1] ~= nil or fs[f2] ~= nil or fs[f3] ~= nil or fs[f4] ~= nil
            or __chunk_has_any_fragments(chunk, __lua_select(5, ...))
    end
end

---@param chunk evolved.chunk
---@param fragment_list evolved.fragment[]
---@param fragment_count integer
---@return boolean
---@nodiscard
function __chunk_has_any_fragment_list(chunk, fragment_list, fragment_count)
    if fragment_count == 0 then
        return false
    end

    local fs = chunk.__fragment_set

    for fragment_index = 1, fragment_count do
        local f = fragment_list[fragment_index]
        if fs[f] ~= nil then
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
function __chunk_get_all_components(chunk, place, ...)
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
            __chunk_get_all_components(chunk, place, __lua_select(5, ...))
    end
end

---@param ini_chunk evolved.chunk
---@param req_fragment_set table<evolved.fragment, integer>
---@param req_fragment_list evolved.fragment[]
---@param req_fragment_count integer
---@return integer
---@nodiscard
function __chunk_required_fragments(ini_chunk, req_fragment_set, req_fragment_list, req_fragment_count)
    ---@type evolved.fragment[]
    local fragment_stack = __acquire_table(__table_pool_tag.fragment_list)
    local fragment_stack_size = 0

    local ini_fragment_set = ini_chunk.__fragment_set
    local ini_fragment_list = ini_chunk.__fragment_list
    local ini_fragment_count = ini_chunk.__fragment_count

    for ini_fragment_index = 1, ini_fragment_count do
        local ini_fragment = ini_fragment_list[ini_fragment_index]

        local ini_fragment_requires = __sorted_requires[ini_fragment]
        local ini_fragment_require_list = ini_fragment_requires and ini_fragment_requires.__item_list
        local ini_fragment_require_count = ini_fragment_requires and ini_fragment_requires.__item_count or 0

        for required_fragment_index = 1, ini_fragment_require_count do
            local required_fragment = ini_fragment_require_list[required_fragment_index]

            if ini_fragment_set[required_fragment] or req_fragment_set[required_fragment] then
                -- this fragment has already been gathered
            else
                req_fragment_count = req_fragment_count + 1
                req_fragment_set[required_fragment] = req_fragment_count
                req_fragment_list[req_fragment_count] = required_fragment

                if __sorted_requires[required_fragment] then
                    fragment_stack_size = fragment_stack_size + 1
                    fragment_stack[fragment_stack_size] = required_fragment
                end
            end
        end
    end

    while fragment_stack_size > 0 do
        local stack_fragment = fragment_stack[fragment_stack_size]

        fragment_stack[fragment_stack_size] = nil
        fragment_stack_size = fragment_stack_size - 1

        local fragment_requires = __sorted_requires[stack_fragment]
        local fragment_require_list = fragment_requires and fragment_requires.__item_list
        local fragment_require_count = fragment_requires and fragment_requires.__item_count or 0

        for fragment_require_index = 1, fragment_require_count do
            local required_fragment = fragment_require_list[fragment_require_index]

            if ini_fragment_set[required_fragment] or req_fragment_set[required_fragment] then
                -- this fragment has already been gathered
            else
                req_fragment_count = req_fragment_count + 1
                req_fragment_set[required_fragment] = req_fragment_count
                req_fragment_list[req_fragment_count] = required_fragment

                if __sorted_requires[required_fragment] then
                    fragment_stack_size = fragment_stack_size + 1
                    fragment_stack[fragment_stack_size] = required_fragment
                end
            end
        end
    end

    __release_table(__table_pool_tag.fragment_list, fragment_stack, true)
    return req_fragment_count
end

---@param ini_chunk evolved.chunk
---@param ini_fragment evolved.fragment
---@param req_fragment_set table<evolved.fragment, integer>
---@param req_fragment_list evolved.fragment[]
---@param req_fragment_count integer
---@return integer
---@nodiscard
function __fragment_required_fragments(ini_chunk, ini_fragment, req_fragment_set, req_fragment_list, req_fragment_count)
    ---@type evolved.fragment[]
    local fragment_stack = __acquire_table(__table_pool_tag.fragment_list)
    local fragment_stack_size = 0

    local ini_fragment_set = ini_chunk.__fragment_set

    do
        local ini_fragment_requires = __sorted_requires[ini_fragment]
        local ini_fragment_require_list = ini_fragment_requires and ini_fragment_requires.__item_list
        local ini_fragment_require_count = ini_fragment_requires and ini_fragment_requires.__item_count or 0

        for required_fragment_index = 1, ini_fragment_require_count do
            local required_fragment = ini_fragment_require_list[required_fragment_index]

            if ini_fragment_set[required_fragment] or req_fragment_set[required_fragment] then
                -- this fragment has already been gathered
            else
                req_fragment_count = req_fragment_count + 1
                req_fragment_set[required_fragment] = req_fragment_count
                req_fragment_list[req_fragment_count] = required_fragment

                if __sorted_requires[required_fragment] then
                    fragment_stack_size = fragment_stack_size + 1
                    fragment_stack[fragment_stack_size] = required_fragment
                end
            end
        end
    end

    while fragment_stack_size > 0 do
        local stack_fragment = fragment_stack[fragment_stack_size]

        fragment_stack[fragment_stack_size] = nil
        fragment_stack_size = fragment_stack_size - 1

        local fragment_requires = __sorted_requires[stack_fragment]
        local fragment_require_list = fragment_requires and fragment_requires.__item_list
        local fragment_require_count = fragment_requires and fragment_requires.__item_count or 0

        for fragment_require_index = 1, fragment_require_count do
            local required_fragment = fragment_require_list[fragment_require_index]

            if ini_fragment_set[required_fragment] or req_fragment_set[required_fragment] then
                -- this fragment has already been gathered
            else
                req_fragment_count = req_fragment_count + 1
                req_fragment_set[required_fragment] = req_fragment_count
                req_fragment_list[req_fragment_count] = required_fragment

                if __sorted_requires[required_fragment] then
                    fragment_stack_size = fragment_stack_size + 1
                    fragment_stack[fragment_stack_size] = required_fragment
                end
            end
        end
    end

    __release_table(__table_pool_tag.fragment_list, fragment_stack, true)
    return req_fragment_count
end

---@param chunk evolved.chunk
---@param place integer
function __detach_entity(chunk, place)
    local entity_list = chunk.__entity_list
    local entity_count = chunk.__entity_count

    local component_count = chunk.__component_count
    local component_storages = chunk.__component_storages

    if place == entity_count then
        entity_list[entity_count] = nil

        for component_index = 1, component_count do
            local component_storage = component_storages[component_index]
            component_storage[entity_count] = nil
        end
    else
        local last_entity = entity_list[entity_count]
        local last_entity_primary = last_entity % 2 ^ 20

        __entity_places[last_entity_primary] = place

        entity_list[place] = last_entity
        entity_list[entity_count] = nil

        for component_index = 1, component_count do
            local component_storage = component_storages[component_index]
            local last_entity_component = component_storage[entity_count]
            component_storage[place] = last_entity_component
            component_storage[entity_count] = nil
        end
    end

    chunk.__entity_count = entity_count - 1
end

---@param chunk evolved.chunk
function __detach_all_entities(chunk)
    local entity_list = chunk.__entity_list

    local component_count = chunk.__component_count
    local component_storages = chunk.__component_storages

    __lua_table_clear(entity_list)

    for component_index = 1, component_count do
        local component_storage = component_storages[component_index]
        __lua_table_clear(component_storage)
    end

    chunk.__entity_count = 0
end

---@param chunk? evolved.chunk
---@param entity evolved.entity
---@param components table<evolved.fragment, evolved.component>
function __spawn_entity(chunk, entity, components)
    if __defer_depth <= 0 then
        __error_fmt('spawn entity operations should be deferred')
    end

    if not chunk or chunk.__unreachable_or_collected then
        chunk = __chunk_components(components)
    end

    if not chunk then
        return
    end

    local req_fragment_set
    local req_fragment_list
    local req_fragment_count = 0

    if chunk.__has_required_fragments then
        ---@type table<evolved.fragment, integer>
        req_fragment_set = __acquire_table(__table_pool_tag.fragment_set)

        ---@type evolved.fragment[]
        req_fragment_list = __acquire_table(__table_pool_tag.fragment_list)

        req_fragment_count = __chunk_required_fragments(chunk,
            req_fragment_set, req_fragment_list, req_fragment_count)

        for req_fragment_index = 1, req_fragment_count do
            local req_fragment = req_fragment_list[req_fragment_index]
            chunk = __chunk_with_fragment(chunk, req_fragment)
        end
    end

    local chunk_entity_list = chunk.__entity_list
    local chunk_entity_count = chunk.__entity_count

    local chunk_component_count = chunk.__component_count
    local chunk_component_indices = chunk.__component_indices
    local chunk_component_storages = chunk.__component_storages
    local chunk_component_fragments = chunk.__component_fragments
    local chunk_component_defaults = chunk.__component_defaults
    local chunk_component_duplicates = chunk.__component_duplicates

    local place = chunk_entity_count + 1

    do
        chunk.__entity_count = place
        __structural_changes = __structural_changes + 1

        chunk_entity_list[place] = entity

        local entity_primary = entity % 2 ^ 20
        __entity_chunks[entity_primary] = chunk
        __entity_places[entity_primary] = place
    end

    for component_index = 1, chunk_component_count do
        local component_storage = chunk_component_storages[component_index]
        local component_fragment = chunk_component_fragments[component_index]
        local component_duplicate = chunk_component_duplicates[component_index]

        local ini_component = components[component_fragment]

        if ini_component == nil then
            ini_component = chunk_component_defaults[component_index]
        end

        if ini_component ~= nil and component_duplicate then
            local new_component = component_duplicate(ini_component)

            if new_component == nil then
                new_component = true
            end

            component_storage[place] = new_component
        else
            if ini_component == nil then
                ini_component = true
            end

            component_storage[place] = ini_component
        end
    end

    if chunk.__has_insert_hooks then
        local chunk_fragment_list = chunk.__fragment_list
        local chunk_fragment_count = chunk.__fragment_count

        for chunk_fragment_index = 1, chunk_fragment_count do
            local fragment = chunk_fragment_list[chunk_fragment_index]

            ---@type evolved.set_hook?, evolved.insert_hook?
            local fragment_on_set, fragment_on_insert =
                __evolved_get(fragment, __ON_SET, __ON_INSERT)

            if fragment_on_set or fragment_on_insert then
                local component_index = chunk_component_indices[fragment]

                if component_index then
                    local component_storage = chunk_component_storages[component_index]

                    local new_component = component_storage[place]

                    if fragment_on_set then
                        fragment_on_set(entity, fragment, new_component)
                    end

                    if fragment_on_insert then
                        fragment_on_insert(entity, fragment, new_component)
                    end
                else
                    if fragment_on_set then
                        fragment_on_set(entity, fragment)
                    end

                    if fragment_on_insert then
                        fragment_on_insert(entity, fragment)
                    end
                end
            end
        end
    end

    if req_fragment_set then
        __release_table(__table_pool_tag.fragment_set, req_fragment_set)
    end

    if req_fragment_list then
        __release_table(__table_pool_tag.fragment_list, req_fragment_list)
    end
end

---@param chunk? evolved.chunk
---@param entity_list evolved.entity[]
---@param entity_count integer
---@param components table<evolved.fragment, evolved.component>
function __multi_spawn_entity(chunk, entity_list, entity_count, components)
    if __defer_depth <= 0 then
        __error_fmt('spawn entity operations should be deferred')
    end

    if not chunk or chunk.__unreachable_or_collected then
        chunk = __chunk_components(components)
    end

    if not chunk then
        return
    end

    local req_fragment_set
    local req_fragment_list
    local req_fragment_count = 0

    if chunk.__has_required_fragments then
        ---@type table<evolved.fragment, integer>
        req_fragment_set = __acquire_table(__table_pool_tag.fragment_set)

        ---@type evolved.fragment[]
        req_fragment_list = __acquire_table(__table_pool_tag.fragment_list)

        req_fragment_count = __chunk_required_fragments(chunk,
            req_fragment_set, req_fragment_list, req_fragment_count)

        for req_fragment_index = 1, req_fragment_count do
            local req_fragment = req_fragment_list[req_fragment_index]
            chunk = __chunk_with_fragment(chunk, req_fragment)
        end
    end

    local chunk_entity_list = chunk.__entity_list
    local chunk_entity_count = chunk.__entity_count

    local chunk_component_count = chunk.__component_count
    local chunk_component_indices = chunk.__component_indices
    local chunk_component_storages = chunk.__component_storages
    local chunk_component_fragments = chunk.__component_fragments
    local chunk_component_defaults = chunk.__component_defaults
    local chunk_component_duplicates = chunk.__component_duplicates

    local b_place = chunk_entity_count + 1
    local e_place = chunk_entity_count + entity_count

    do
        chunk.__entity_count = e_place
        __structural_changes = __structural_changes + 1

        local entity_chunks = __entity_chunks
        local entity_places = __entity_places

        for place = b_place, e_place do
            local entity = entity_list[place - b_place + 1]
            chunk_entity_list[place] = entity

            local entity_primary = entity % 2 ^ 20
            entity_chunks[entity_primary] = chunk
            entity_places[entity_primary] = place
        end
    end

    for component_index = 1, chunk_component_count do
        local component_storage = chunk_component_storages[component_index]
        local component_fragment = chunk_component_fragments[component_index]
        local component_duplicate = chunk_component_duplicates[component_index]

        local ini_component = components[component_fragment]

        if ini_component == nil then
            ini_component = chunk_component_defaults[component_index]
        end

        if ini_component ~= nil and component_duplicate then
            for place = b_place, e_place do
                local new_component = component_duplicate(ini_component)

                if new_component == nil then
                    new_component = true
                end

                component_storage[place] = new_component
            end
        else
            if ini_component == nil then
                ini_component = true
            end

            for place = b_place, e_place do
                component_storage[place] = ini_component
            end
        end
    end

    if chunk.__has_insert_hooks then
        local chunk_fragment_list = chunk.__fragment_list
        local chunk_fragment_count = chunk.__fragment_count

        for chunk_fragment_index = 1, chunk_fragment_count do
            local fragment = chunk_fragment_list[chunk_fragment_index]

            ---@type evolved.set_hook?, evolved.insert_hook?
            local fragment_on_set, fragment_on_insert =
                __evolved_get(fragment, __ON_SET, __ON_INSERT)

            if fragment_on_set or fragment_on_insert then
                local component_index = chunk_component_indices[fragment]

                if component_index then
                    local component_storage = chunk_component_storages[component_index]

                    for place = b_place, e_place do
                        local entity = chunk_entity_list[place]

                        local new_component = component_storage[place]

                        if fragment_on_set then
                            fragment_on_set(entity, fragment, new_component)
                        end

                        if fragment_on_insert then
                            fragment_on_insert(entity, fragment, new_component)
                        end
                    end
                else
                    for place = b_place, e_place do
                        local entity = chunk_entity_list[place]

                        if fragment_on_set then
                            fragment_on_set(entity, fragment)
                        end

                        if fragment_on_insert then
                            fragment_on_insert(entity, fragment)
                        end
                    end
                end
            end
        end
    end

    if req_fragment_set then
        __release_table(__table_pool_tag.fragment_set, req_fragment_set)
    end

    if req_fragment_list then
        __release_table(__table_pool_tag.fragment_list, req_fragment_list)
    end
end

---@param prefab evolved.entity
---@param entity evolved.entity
---@param components table<evolved.fragment, evolved.component>
function __clone_entity(prefab, entity, components)
    if __defer_depth <= 0 then
        __error_fmt('clone entity operations should be deferred')
    end

    local prefab_chunk, prefab_place = __evolved_locate(prefab)

    if prefab_chunk and prefab_chunk.__has_unique_fragments and not prefab_chunk.__without_unique_fragments then
        prefab_chunk.__without_unique_fragments = __chunk_without_unique_fragments(prefab_chunk)
    end

    if not prefab_chunk or not prefab_chunk.__without_unique_fragments then
        return __spawn_entity(nil, entity, components)
    end

    local chunk = __chunk_with_components(
        prefab_chunk.__without_unique_fragments,
        components)

    if not chunk then
        return
    end

    local req_fragment_set
    local req_fragment_list
    local req_fragment_count = 0

    if chunk.__has_required_fragments then
        ---@type table<evolved.fragment, integer>
        req_fragment_set = __acquire_table(__table_pool_tag.fragment_set)

        ---@type evolved.fragment[]
        req_fragment_list = __acquire_table(__table_pool_tag.fragment_list)

        req_fragment_count = __chunk_required_fragments(chunk,
            req_fragment_set, req_fragment_list, req_fragment_count)

        for req_fragment_index = 1, req_fragment_count do
            local req_fragment = req_fragment_list[req_fragment_index]
            chunk = __chunk_with_fragment(chunk, req_fragment)
        end
    end

    local chunk_entity_list = chunk.__entity_list
    local chunk_entity_count = chunk.__entity_count

    local chunk_component_count = chunk.__component_count
    local chunk_component_indices = chunk.__component_indices
    local chunk_component_storages = chunk.__component_storages
    local chunk_component_fragments = chunk.__component_fragments
    local chunk_component_defaults = chunk.__component_defaults
    local chunk_component_duplicates = chunk.__component_duplicates

    local prefab_component_indices = prefab_chunk.__component_indices
    local prefab_component_storages = prefab_chunk.__component_storages

    local place = chunk_entity_count + 1

    do
        chunk.__entity_count = place
        __structural_changes = __structural_changes + 1

        chunk_entity_list[place] = entity

        local entity_primary = entity % 2 ^ 20
        __entity_chunks[entity_primary] = chunk
        __entity_places[entity_primary] = place
    end

    for component_index = 1, chunk_component_count do
        local component_storage = chunk_component_storages[component_index]
        local component_fragment = chunk_component_fragments[component_index]
        local component_duplicate = chunk_component_duplicates[component_index]

        local ini_component = components[component_fragment]

        if ini_component == nil then
            if chunk == prefab_chunk then
                ini_component = component_storage[prefab_place]
            else
                local prefab_component_index = prefab_component_indices[component_fragment]
                if prefab_component_index then
                    local prefab_component_storage = prefab_component_storages[prefab_component_index]
                    ini_component = prefab_component_storage[prefab_place]
                else
                    ini_component = chunk_component_defaults[component_index]
                end
            end
        end

        if ini_component ~= nil and component_duplicate then
            local new_component = component_duplicate(ini_component)

            if new_component == nil then
                new_component = true
            end

            component_storage[place] = new_component
        else
            if ini_component == nil then
                ini_component = true
            end

            component_storage[place] = ini_component
        end
    end

    if chunk.__has_insert_hooks then
        local chunk_fragment_list = chunk.__fragment_list
        local chunk_fragment_count = chunk.__fragment_count

        for chunk_fragment_index = 1, chunk_fragment_count do
            local fragment = chunk_fragment_list[chunk_fragment_index]

            ---@type evolved.set_hook?, evolved.insert_hook?
            local fragment_on_set, fragment_on_insert =
                __evolved_get(fragment, __ON_SET, __ON_INSERT)

            if fragment_on_set or fragment_on_insert then
                local component_index = chunk_component_indices[fragment]

                if component_index then
                    local component_storage = chunk_component_storages[component_index]

                    local new_component = component_storage[place]

                    if fragment_on_set then
                        fragment_on_set(entity, fragment, new_component)
                    end

                    if fragment_on_insert then
                        fragment_on_insert(entity, fragment, new_component)
                    end
                else
                    if fragment_on_set then
                        fragment_on_set(entity, fragment)
                    end

                    if fragment_on_insert then
                        fragment_on_insert(entity, fragment)
                    end
                end
            end
        end
    end

    if req_fragment_set then
        __release_table(__table_pool_tag.fragment_set, req_fragment_set)
    end

    if req_fragment_list then
        __release_table(__table_pool_tag.fragment_list, req_fragment_list)
    end
end

---@param prefab evolved.entity
---@param entity_list evolved.entity[]
---@param entity_count integer
---@param components table<evolved.fragment, evolved.component>
function __multi_clone_entity(prefab, entity_list, entity_count, components)
    if __defer_depth <= 0 then
        __error_fmt('clone entity operations should be deferred')
    end

    local prefab_chunk, prefab_place = __evolved_locate(prefab)

    if prefab_chunk and prefab_chunk.__has_unique_fragments and not prefab_chunk.__without_unique_fragments then
        prefab_chunk.__without_unique_fragments = __chunk_without_unique_fragments(prefab_chunk)
    end

    if not prefab_chunk or not prefab_chunk.__without_unique_fragments then
        return __multi_spawn_entity(nil, entity_list, entity_count, components)
    end

    local chunk = __chunk_with_components(
        prefab_chunk.__without_unique_fragments,
        components)

    if not chunk then
        return
    end

    local req_fragment_set
    local req_fragment_list
    local req_fragment_count = 0

    if chunk.__has_required_fragments then
        ---@type table<evolved.fragment, integer>
        req_fragment_set = __acquire_table(__table_pool_tag.fragment_set)

        ---@type evolved.fragment[]
        req_fragment_list = __acquire_table(__table_pool_tag.fragment_list)

        req_fragment_count = __chunk_required_fragments(chunk,
            req_fragment_set, req_fragment_list, req_fragment_count)

        for req_fragment_index = 1, req_fragment_count do
            local req_fragment = req_fragment_list[req_fragment_index]
            chunk = __chunk_with_fragment(chunk, req_fragment)
        end
    end

    local chunk_entity_list = chunk.__entity_list
    local chunk_entity_count = chunk.__entity_count

    local chunk_component_count = chunk.__component_count
    local chunk_component_indices = chunk.__component_indices
    local chunk_component_storages = chunk.__component_storages
    local chunk_component_fragments = chunk.__component_fragments
    local chunk_component_defaults = chunk.__component_defaults
    local chunk_component_duplicates = chunk.__component_duplicates

    local prefab_component_indices = prefab_chunk.__component_indices
    local prefab_component_storages = prefab_chunk.__component_storages

    local b_place = chunk_entity_count + 1
    local e_place = chunk_entity_count + entity_count

    do
        chunk.__entity_count = e_place
        __structural_changes = __structural_changes + 1

        local entity_chunks = __entity_chunks
        local entity_places = __entity_places

        for place = b_place, e_place do
            local entity = entity_list[place - b_place + 1]
            chunk_entity_list[place] = entity

            local entity_primary = entity % 2 ^ 20
            entity_chunks[entity_primary] = chunk
            entity_places[entity_primary] = place
        end
    end

    for component_index = 1, chunk_component_count do
        local component_storage = chunk_component_storages[component_index]
        local component_fragment = chunk_component_fragments[component_index]
        local component_duplicate = chunk_component_duplicates[component_index]

        local ini_component = components[component_fragment]

        if ini_component == nil then
            if chunk == prefab_chunk then
                ini_component = component_storage[prefab_place]
            else
                local prefab_component_index = prefab_component_indices[component_fragment]
                if prefab_component_index then
                    local prefab_component_storage = prefab_component_storages[prefab_component_index]
                    ini_component = prefab_component_storage[prefab_place]
                else
                    ini_component = chunk_component_defaults[component_index]
                end
            end
        end

        if ini_component ~= nil and component_duplicate then
            for place = b_place, e_place do
                local new_component = component_duplicate(ini_component)

                if new_component == nil then
                    new_component = true
                end

                component_storage[place] = new_component
            end
        else
            if ini_component == nil then
                ini_component = true
            end

            for place = b_place, e_place do
                component_storage[place] = ini_component
            end
        end
    end

    if chunk.__has_insert_hooks then
        local chunk_fragment_list = chunk.__fragment_list
        local chunk_fragment_count = chunk.__fragment_count

        for chunk_fragment_index = 1, chunk_fragment_count do
            local fragment = chunk_fragment_list[chunk_fragment_index]

            ---@type evolved.set_hook?, evolved.insert_hook?
            local fragment_on_set, fragment_on_insert =
                __evolved_get(fragment, __ON_SET, __ON_INSERT)

            if fragment_on_set or fragment_on_insert then
                local component_index = chunk_component_indices[fragment]

                if component_index then
                    local component_storage = chunk_component_storages[component_index]

                    for place = b_place, e_place do
                        local entity = chunk_entity_list[place]

                        local new_component = component_storage[place]

                        if fragment_on_set then
                            fragment_on_set(entity, fragment, new_component)
                        end

                        if fragment_on_insert then
                            fragment_on_insert(entity, fragment, new_component)
                        end
                    end
                else
                    for place = b_place, e_place do
                        local entity = chunk_entity_list[place]

                        if fragment_on_set then
                            fragment_on_set(entity, fragment)
                        end

                        if fragment_on_insert then
                            fragment_on_insert(entity, fragment)
                        end
                    end
                end
            end
        end
    end

    if req_fragment_set then
        __release_table(__table_pool_tag.fragment_set, req_fragment_set)
    end

    if req_fragment_list then
        __release_table(__table_pool_tag.fragment_list, req_fragment_list)
    end
end

---@param chunk evolved.chunk
function __purge_chunk(chunk)
    if __defer_depth <= 0 then
        __error_fmt('this operation should be deferred')
    end

    if chunk.__child_count > 0 or chunk.__entity_count > 0 then
        __error_fmt('chunk should be empty before purging')
    end

    local chunk_parent = chunk.__parent
    local chunk_fragment = chunk.__fragment

    local chunk_fragment_list = chunk.__fragment_list
    local chunk_fragment_count = chunk.__fragment_count

    local with_fragment_edges = chunk.__with_fragment_edges
    local without_fragment_edges = chunk.__without_fragment_edges

    if not chunk_parent then
        if __root_chunks[chunk_fragment] ~= chunk then
            __error_fmt('unexpected root chunk %s',
                __lua_tostring(__root_chunks[chunk_fragment]))
        end
        __root_chunks[chunk_fragment] = nil
    end

    do
        local major = chunk_fragment
        local major_chunks = __major_chunks[major]

        if major_chunks and __assoc_list_remove(major_chunks, chunk) == 0 then
            __major_chunks[major] = nil
        end
    end

    for chunk_fragment_index = 1, chunk_fragment_count do
        local minor = chunk_fragment_list[chunk_fragment_index]
        local minor_chunks = __minor_chunks[minor]

        if minor_chunks and __assoc_list_remove(minor_chunks, chunk) == 0 then
            __minor_chunks[minor] = nil
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

---@param chunk_list evolved.chunk[]
---@param chunk_count integer
function __clear_chunk_list(chunk_list, chunk_count)
    if __defer_depth <= 0 then
        __error_fmt('this operation should be deferred')
    end

    if chunk_count == 0 then
        return
    end

    for chunk_index = 1, chunk_count do
        local chunk = chunk_list[chunk_index]
        __chunk_clear(chunk)
    end
end

---@param entity_list evolved.entity[]
---@param entity_count integer
function __destroy_entity_list(entity_list, entity_count)
    if __defer_depth <= 0 then
        __error_fmt('this operation should be deferred')
    end

    if entity_count == 0 then
        return
    end

    for entity_index = 1, entity_count do
        local entity = entity_list[entity_index]
        local entity_primary = entity % 2 ^ 20

        if __freelist_ids[entity_primary] ~= entity then
            -- this entity is not alive, nothing to purge
        else
            local chunk = __entity_chunks[entity_primary]
            local place = __entity_places[entity_primary]

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
                            fragment_on_remove(entity, fragment, old_component)
                        else
                            fragment_on_remove(entity, fragment)
                        end
                    end
                end
            end

            if chunk then
                __detach_entity(chunk, place)

                __entity_chunks[entity_primary] = nil
                __entity_places[entity_primary] = nil

                __structural_changes = __structural_changes + 1
            end

            __release_id(entity)
        end
    end
end

---@param fragment_list evolved.fragment[]
---@param fragment_count integer
function __destroy_fragment_list(fragment_list, fragment_count)
    if __defer_depth <= 0 then
        __error_fmt('this operation should be deferred')
    end

    if fragment_count == 0 then
        return
    end

    local processed_fragment_set = __acquire_table(__table_pool_tag.fragment_set)
    local processing_fragment_stack = __acquire_table(__table_pool_tag.fragment_list)
    local processing_fragment_stack_size = 0

    do
        __lua_table_move(
            fragment_list, 1, fragment_count,
            processing_fragment_stack_size + 1, processing_fragment_stack)

        processing_fragment_stack_size = processing_fragment_stack_size + fragment_count
    end

    local releasing_fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    local releasing_fragment_count = 0

    local destroy_entity_policy_fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    local destroy_entity_policy_fragment_count = 0

    local remove_fragment_policy_fragment_list = __acquire_table(__table_pool_tag.fragment_list)
    local remove_fragment_policy_fragment_count = 0

    while processing_fragment_stack_size > 0 do
        local processing_fragment = processing_fragment_stack[processing_fragment_stack_size]

        processing_fragment_stack[processing_fragment_stack_size] = nil
        processing_fragment_stack_size = processing_fragment_stack_size - 1

        if processed_fragment_set[processing_fragment] then
            -- this fragment has already beed processed
        else
            processed_fragment_set[processing_fragment] = true

            releasing_fragment_count = releasing_fragment_count + 1
            releasing_fragment_list[releasing_fragment_count] = processing_fragment

            local processing_fragment_destruction_policy = __evolved_get(processing_fragment, __DESTRUCTION_POLICY)
                or __DESTRUCTION_POLICY_REMOVE_FRAGMENT

            if processing_fragment_destruction_policy == __DESTRUCTION_POLICY_DESTROY_ENTITY then
                destroy_entity_policy_fragment_count = destroy_entity_policy_fragment_count + 1
                destroy_entity_policy_fragment_list[destroy_entity_policy_fragment_count] = processing_fragment

                __trace_minor_chunks(processing_fragment, function(chunk)
                    local chunk_entity_list = chunk.__entity_list
                    local chunk_entity_count = chunk.__entity_count

                    __lua_table_move(
                        chunk_entity_list, 1, chunk_entity_count,
                        processing_fragment_stack_size + 1, processing_fragment_stack)

                    processing_fragment_stack_size = processing_fragment_stack_size + chunk_entity_count
                end)
            elseif processing_fragment_destruction_policy == __DESTRUCTION_POLICY_REMOVE_FRAGMENT then
                remove_fragment_policy_fragment_count = remove_fragment_policy_fragment_count + 1
                remove_fragment_policy_fragment_list[remove_fragment_policy_fragment_count] = processing_fragment
            else
                __error_fmt('unknown DESTRUCTION_POLICY (%s) on (%s)',
                    __id_name(processing_fragment_destruction_policy), __id_name(processing_fragment))
            end
        end
    end

    __release_table(__table_pool_tag.fragment_set, processed_fragment_set)
    __release_table(__table_pool_tag.fragment_list, processing_fragment_stack, true)

    if destroy_entity_policy_fragment_count > 0 then
        for i = 1, destroy_entity_policy_fragment_count do
            local fragment = destroy_entity_policy_fragment_list[i]

            __trace_minor_chunks(fragment, __chunk_clear)
        end

        __release_table(__table_pool_tag.fragment_list, destroy_entity_policy_fragment_list)
    else
        __release_table(__table_pool_tag.fragment_list, destroy_entity_policy_fragment_list, true)
    end

    if remove_fragment_policy_fragment_count > 0 then
        for i = 1, remove_fragment_policy_fragment_count do
            local fragment = remove_fragment_policy_fragment_list[i]

            __trace_minor_chunks(fragment, __chunk_remove, fragment)
        end

        __release_table(__table_pool_tag.fragment_list, remove_fragment_policy_fragment_list)
    else
        __release_table(__table_pool_tag.fragment_list, remove_fragment_policy_fragment_list, true)
    end

    if releasing_fragment_count > 0 then
        __destroy_entity_list(releasing_fragment_list, releasing_fragment_count)
        __release_table(__table_pool_tag.fragment_list, releasing_fragment_list)
    else
        __release_table(__table_pool_tag.fragment_list, releasing_fragment_list, true)
    end
end

---@param old_chunk evolved.chunk
---@param fragment evolved.fragment
---@param component evolved.component
function __chunk_set(old_chunk, fragment, component)
    if __defer_depth <= 0 then
        __error_fmt('batched chunk operations should be deferred')
    end

    local old_entity_list = old_chunk.__entity_list
    local old_entity_count = old_chunk.__entity_count

    local old_component_count = old_chunk.__component_count
    local old_component_indices = old_chunk.__component_indices
    local old_component_storages = old_chunk.__component_storages
    local old_component_fragments = old_chunk.__component_fragments

    if old_entity_count == 0 then
        return
    end

    local new_chunk = __chunk_with_fragment(old_chunk, fragment)

    if not new_chunk then
        return
    end

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
                -- nothing
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
        local req_fragment_set
        local req_fragment_list
        local req_fragment_count = 0

        local ini_new_chunk = new_chunk
        local ini_fragment_set = ini_new_chunk.__fragment_set

        if new_chunk.__has_required_fragments then
            ---@type table<evolved.fragment, integer>
            req_fragment_set = __acquire_table(__table_pool_tag.fragment_set)

            ---@type evolved.fragment[]
            req_fragment_list = __acquire_table(__table_pool_tag.fragment_list)

            req_fragment_count = __fragment_required_fragments(ini_new_chunk, fragment,
                req_fragment_set, req_fragment_list, req_fragment_count)

            for req_fragment_index = 1, req_fragment_count do
                local req_fragment = req_fragment_list[req_fragment_index]
                new_chunk = __chunk_with_fragment(new_chunk, req_fragment)
            end
        end

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

        local sum_entity_count = old_entity_count + new_entity_count

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

            new_chunk.__entity_count = sum_entity_count
        else
            for old_ci = 1, old_component_count do
                local old_f = old_component_fragments[old_ci]
                local old_cs = old_component_storages[old_ci]

                local new_ci = new_component_indices[old_f]
                local new_cs = new_component_storages[new_ci]

                __lua_table_move(
                    old_cs, 1, old_entity_count,
                    new_entity_count + 1, new_cs)
            end

            __lua_table_move(
                old_entity_list, 1, old_entity_count,
                new_entity_count + 1, new_entity_list)

            new_chunk.__entity_count = sum_entity_count
        end

        do
            local entity_chunks = __entity_chunks
            local entity_places = __entity_places

            for new_place = new_entity_count + 1, sum_entity_count do
                local entity = new_entity_list[new_place]
                local entity_primary = entity % 2 ^ 20
                entity_chunks[entity_primary] = new_chunk
                entity_places[entity_primary] = new_place
            end

            __detach_all_entities(old_chunk)
        end

        if fragment_on_set or fragment_on_insert then
            local new_component_index = new_component_indices[fragment]

            if new_component_index then
                local new_component_storage = new_component_storages[new_component_index]

                if fragment_duplicate then
                    for new_place = new_entity_count + 1, sum_entity_count do
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

                    for new_place = new_entity_count + 1, sum_entity_count do
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
                for new_place = new_entity_count + 1, sum_entity_count do
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
                    for new_place = new_entity_count + 1, sum_entity_count do
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
                    for new_place = new_entity_count + 1, sum_entity_count do
                        new_component_storage[new_place] = new_component
                    end
                end
            else
                -- nothing
            end
        end

        for req_fragment_index = 1, req_fragment_count do
            local req_fragment = req_fragment_list[req_fragment_index]

            if ini_fragment_set[req_fragment] then
                -- this fragment has already been initialized
            else
                ---@type evolved.default?, evolved.duplicate?, evolved.set_hook?, evolved.insert_hook?
                local req_fragment_default, req_fragment_duplicate, req_fragment_on_set, req_fragment_on_insert

                if new_chunk_has_setup_hooks or new_chunk_has_insert_hooks then
                    req_fragment_default, req_fragment_duplicate, req_fragment_on_set, req_fragment_on_insert =
                        __evolved_get(req_fragment, __DEFAULT, __DUPLICATE, __ON_SET, __ON_INSERT)
                end

                if req_fragment_on_set or req_fragment_on_insert then
                    local req_component_index = new_component_indices[req_fragment]

                    if req_component_index then
                        local req_component_storage = new_component_storages[req_component_index]

                        if req_fragment_duplicate then
                            for new_place = new_entity_count + 1, sum_entity_count do
                                local entity = new_entity_list[new_place]

                                local req_component = req_fragment_default
                                if req_component ~= nil then req_component = req_fragment_duplicate(req_component) end
                                if req_component == nil then req_component = true end

                                req_component_storage[new_place] = req_component

                                if req_fragment_on_set then
                                    __defer_call_hook(req_fragment_on_set, entity, req_fragment, req_component)
                                end

                                if req_fragment_on_insert then
                                    __defer_call_hook(req_fragment_on_insert, entity, req_fragment, req_component)
                                end
                            end
                        else
                            local req_component = req_fragment_default
                            if req_component == nil then req_component = true end

                            for new_place = new_entity_count + 1, sum_entity_count do
                                local entity = new_entity_list[new_place]

                                req_component_storage[new_place] = req_component

                                if req_fragment_on_set then
                                    __defer_call_hook(req_fragment_on_set, entity, req_fragment, req_component)
                                end

                                if req_fragment_on_insert then
                                    __defer_call_hook(req_fragment_on_insert, entity, req_fragment, req_component)
                                end
                            end
                        end
                    else
                        for new_place = new_entity_count + 1, sum_entity_count do
                            local entity = new_entity_list[new_place]

                            if req_fragment_on_set then
                                __defer_call_hook(req_fragment_on_set, entity, req_fragment)
                            end

                            if req_fragment_on_insert then
                                __defer_call_hook(req_fragment_on_insert, entity, req_fragment)
                            end
                        end
                    end
                else
                    local req_component_index = new_component_indices[req_fragment]

                    if req_component_index then
                        local req_component_storage = new_component_storages[req_component_index]

                        if req_fragment_duplicate then
                            for new_place = new_entity_count + 1, sum_entity_count do
                                local req_component = req_fragment_default
                                if req_component ~= nil then req_component = req_fragment_duplicate(req_component) end
                                if req_component == nil then req_component = true end
                                req_component_storage[new_place] = req_component
                            end
                        else
                            local req_component = req_fragment_default
                            if req_component == nil then req_component = true end
                            for new_place = new_entity_count + 1, sum_entity_count do
                                req_component_storage[new_place] = req_component
                            end
                        end
                    else
                        -- nothing
                    end
                end
            end
        end

        if req_fragment_set then
            __release_table(__table_pool_tag.fragment_set, req_fragment_set)
        end

        if req_fragment_list then
            __release_table(__table_pool_tag.fragment_list, req_fragment_list)
        end

        __structural_changes = __structural_changes + 1
    end
end

---@param old_chunk evolved.chunk
---@param ... evolved.fragment fragments
function __chunk_remove(old_chunk, ...)
    if __defer_depth <= 0 then
        __error_fmt('batched chunk operations should be deferred')
    end

    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return
    end

    local old_entity_list = old_chunk.__entity_list
    local old_entity_count = old_chunk.__entity_count

    local old_fragment_list = old_chunk.__fragment_list
    local old_fragment_count = old_chunk.__fragment_count
    local old_component_indices = old_chunk.__component_indices
    local old_component_storages = old_chunk.__component_storages

    if old_entity_count == 0 then
        return
    end

    local new_chunk = __chunk_without_fragments(old_chunk, ...)

    if old_chunk == new_chunk then
        return
    end

    if old_chunk.__has_remove_hooks then
        local new_fragment_set = new_chunk and new_chunk.__fragment_set
            or __safe_tbls.__EMPTY_FRAGMENT_SET

        for old_fragment_index = 1, old_fragment_count do
            local fragment = old_fragment_list[old_fragment_index]

            if not new_fragment_set[fragment] then
                ---@type evolved.remove_hook?
                local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

                if fragment_on_remove then
                    local old_component_index = old_component_indices[fragment]

                    if old_component_index then
                        local old_component_storage = old_component_storages[old_component_index]

                        for old_place = 1, old_entity_count do
                            local entity = old_entity_list[old_place]
                            local old_component = old_component_storage[old_place]
                            fragment_on_remove(entity, fragment, old_component)
                        end
                    else
                        for old_place = 1, old_entity_count do
                            local entity = old_entity_list[old_place]
                            fragment_on_remove(entity, fragment)
                        end
                    end
                end
            end
        end
    end

    if new_chunk then
        local new_entity_list = new_chunk.__entity_list
        local new_entity_count = new_chunk.__entity_count

        local new_component_count = new_chunk.__component_count
        local new_component_storages = new_chunk.__component_storages
        local new_component_fragments = new_chunk.__component_fragments

        local sum_entity_count = old_entity_count + new_entity_count

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

            new_chunk.__entity_count = sum_entity_count
        else
            for new_ci = 1, new_component_count do
                local new_f = new_component_fragments[new_ci]
                local new_cs = new_component_storages[new_ci]

                local old_ci = old_component_indices[new_f]
                local old_cs = old_component_storages[old_ci]

                __lua_table_move(
                    old_cs, 1, old_entity_count,
                    new_entity_count + 1, new_cs)
            end

            __lua_table_move(
                old_entity_list, 1, old_entity_count,
                new_entity_count + 1, new_entity_list)

            new_chunk.__entity_count = sum_entity_count
        end

        do
            local entity_chunks = __entity_chunks
            local entity_places = __entity_places

            for new_place = new_entity_count + 1, sum_entity_count do
                local entity = new_entity_list[new_place]
                local entity_primary = entity % 2 ^ 20
                entity_chunks[entity_primary] = new_chunk
                entity_places[entity_primary] = new_place
            end

            __detach_all_entities(old_chunk)
        end
    else
        local entity_chunks = __entity_chunks
        local entity_places = __entity_places

        for old_place = 1, old_entity_count do
            local entity = old_entity_list[old_place]
            local entity_primary = entity % 2 ^ 20
            entity_chunks[entity_primary] = nil
            entity_places[entity_primary] = nil
        end

        __detach_all_entities(old_chunk)
    end

    __structural_changes = __structural_changes + 1
end

---@param chunk evolved.chunk
function __chunk_clear(chunk)
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
                        fragment_on_remove(entity, fragment, old_component)
                    end
                else
                    for place = 1, chunk_entity_count do
                        local entity = chunk_entity_list[place]
                        fragment_on_remove(entity, fragment)
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
            local entity_primary = entity % 2 ^ 20
            entity_chunks[entity_primary] = nil
            entity_places[entity_primary] = nil
        end

        __detach_all_entities(chunk)
    end

    __structural_changes = __structural_changes + 1
end

---
---
---
---
---

---@enum evolved.defer_op
local __defer_op = {
    call_hook = 1,

    spawn_entity = 2,
    multi_spawn_entity = 3,

    clone_entity = 4,
    multi_clone_entity = 5,

    __count = 5,
}

---@type table<evolved.defer_op, fun(bytes: any[], index: integer): integer>
local __defer_ops = __list_new(__defer_op.__count)

---@param hook fun(...)
---@param ... any hook arguments
function __defer_call_hook(hook, ...)
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

---@param chunk? evolved.chunk
---@param entity evolved.entity
---@param component_map table<evolved.fragment, evolved.component>
function __defer_spawn_entity(chunk, entity, component_map)
    ---@type table<evolved.fragment, evolved.component>
    local component_map_dup = __acquire_table(__table_pool_tag.component_map)

    for fragment, component in __lua_next, component_map do
        component_map_dup[fragment] = component
    end

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.spawn_entity
    bytecode[length + 2] = chunk
    bytecode[length + 3] = entity
    bytecode[length + 4] = component_map_dup

    __defer_length = length + 4
end

__defer_ops[__defer_op.spawn_entity] = function(bytes, index)
    local chunk = bytes[index + 0]
    local entity = bytes[index + 1]
    local component_map_dup = bytes[index + 2]

    __evolved_defer()
    do
        __spawn_entity(chunk, entity, component_map_dup)
        __release_table(__table_pool_tag.component_map, component_map_dup)
    end
    __evolved_commit()

    return 3
end

---@param chunk? evolved.chunk
---@param entity_list evolved.entity[]
---@param entity_count integer
---@param component_map table<evolved.fragment, evolved.component>
function __defer_multi_spawn_entity(chunk, entity_list, entity_count, component_map)
    ---@type evolved.entity[]
    local entity_list_dup = __acquire_table(__table_pool_tag.entity_list)

    __lua_table_move(
        entity_list, 1, entity_count,
        1, entity_list_dup)

    ---@type table<evolved.fragment, evolved.component>
    local component_map_dup = __acquire_table(__table_pool_tag.component_map)

    for fragment, component in __lua_next, component_map do
        component_map_dup[fragment] = component
    end

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.multi_spawn_entity
    bytecode[length + 2] = chunk
    bytecode[length + 3] = entity_count
    bytecode[length + 4] = entity_list_dup
    bytecode[length + 5] = component_map_dup

    __defer_length = length + 5
end

__defer_ops[__defer_op.multi_spawn_entity] = function(bytes, index)
    local chunk = bytes[index + 0]
    local entity_count = bytes[index + 1]
    local entity_list_dup = bytes[index + 2]
    local component_map_dup = bytes[index + 3]

    __evolved_defer()
    do
        __multi_spawn_entity(chunk, entity_list_dup, entity_count, component_map_dup)
        __release_table(__table_pool_tag.entity_list, entity_list_dup)
        __release_table(__table_pool_tag.component_map, component_map_dup)
    end
    __evolved_commit()

    return 4
end

---@param prefab evolved.entity
---@param entity evolved.entity
---@param component_map table<evolved.fragment, evolved.component>
function __defer_clone_entity(prefab, entity, component_map)
    ---@type table<evolved.fragment, evolved.component>
    local component_map_dup = __acquire_table(__table_pool_tag.component_map)

    for fragment, component in __lua_next, component_map do
        component_map_dup[fragment] = component
    end

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.clone_entity
    bytecode[length + 2] = prefab
    bytecode[length + 3] = entity
    bytecode[length + 4] = component_map_dup

    __defer_length = length + 4
end

__defer_ops[__defer_op.clone_entity] = function(bytes, index)
    local prefab = bytes[index + 0]
    local entity = bytes[index + 1]
    local component_map_dup = bytes[index + 2]

    __evolved_defer()
    do
        __clone_entity(prefab, entity, component_map_dup)
        __release_table(__table_pool_tag.component_map, component_map_dup)
    end
    __evolved_commit()

    return 3
end

---@param prefab evolved.entity
---@param entity_list evolved.entity[]
---@param entity_count integer
---@param component_map table<evolved.fragment, evolved.component>
function __defer_multi_clone_entity(prefab, entity_list, entity_count, component_map)
    ---@type evolved.entity[]
    local entity_list_dup = __acquire_table(__table_pool_tag.entity_list)

    __lua_table_move(
        entity_list, 1, entity_count,
        1, entity_list_dup)

    ---@type table<evolved.fragment, evolved.component>
    local component_map_dup = __acquire_table(__table_pool_tag.component_map)

    for fragment, component in __lua_next, component_map do
        component_map_dup[fragment] = component
    end

    local length = __defer_length
    local bytecode = __defer_bytecode

    bytecode[length + 1] = __defer_op.multi_clone_entity
    bytecode[length + 2] = prefab
    bytecode[length + 3] = entity_count
    bytecode[length + 4] = entity_list_dup
    bytecode[length + 5] = component_map_dup

    __defer_length = length + 5
end

__defer_ops[__defer_op.multi_clone_entity] = function(bytes, index)
    local prefab = bytes[index + 0]
    local entity_count = bytes[index + 1]
    local entity_list_dup = bytes[index + 2]
    local component_map_dup = bytes[index + 3]

    __evolved_defer()
    do
        __multi_clone_entity(prefab, entity_list_dup, entity_count, component_map_dup)
        __release_table(__table_pool_tag.entity_list, entity_list_dup)
        __release_table(__table_pool_tag.component_map, component_map_dup)
    end
    __evolved_commit()

    return 4
end

---
---
---
---
---

local __iterator_fns = {}

---@type evolved.each_iterator
function __iterator_fns.__each_iterator(each_state)
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
function __iterator_fns.__execute_iterator(execute_state)
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

        for chunk_child_index = 1, chunk_child_count do
            local chunk_child = chunk_child_list[chunk_child_index]
            local chunk_child_fragment = chunk_child.__fragment

            local is_chunk_child_matched =
                (not chunk_child.__has_explicit_major) and
                (not exclude_set or not exclude_set[chunk_child_fragment])

            if is_chunk_child_matched then
                chunk_stack_size = chunk_stack_size + 1
                chunk_stack[chunk_stack_size] = chunk_child
            end
        end

        local chunk_entity_list = chunk.__entity_list
        local chunk_entity_count = chunk.__entity_count

        if chunk_entity_count > 0 then
            execute_state[3] = chunk_stack_size
            return chunk, chunk_entity_list, chunk_entity_count
        end
    end

    __release_table(__table_pool_tag.chunk_list, chunk_stack, true)
    __release_table(__table_pool_tag.execute_state, execute_state, true)
end

---@type { [1]: evolved.query, [2]: evolved.execute }
local __query_execute_external_arguments = {}

---@param query? evolved.query
---@param execute? evolved.execute
local function __query_execute(query, execute)
    -- we use the external arguments here to support lua 5.1 xpcall (which does not support argument passing)
    -- also, we can not use upvalues directly, because the function may be called recursively in that case
    -- storing the arguments in local variables makes them invulnerable to changes during recursive calls

    query = query or __query_execute_external_arguments[1]
    execute = execute or __query_execute_external_arguments[2]

    for chunk, entity_list, entity_count in __evolved_execute(query) do
        execute(chunk, entity_list, entity_count)
    end
end

---@param system evolved.system
local function __system_process(system)
    ---@type evolved.query?, evolved.execute?, evolved.prologue?, evolved.epilogue?
    local query, execute, prologue, epilogue = __evolved_get(system,
        __QUERY, __EXECUTE, __PROLOGUE, __EPILOGUE)

    if prologue then
        local success, result = __lua_xpcall(prologue, __lua_debug_traceback)

        if not success then
            __error_fmt('system prologue failed: %s', result)
        end
    end

    if execute then
        __evolved_defer()
        do
            __query_execute_external_arguments[1], __query_execute_external_arguments[2] = query or system, execute
            local success, result = __lua_xpcall(__query_execute, __lua_debug_traceback, query or system, execute)

            if not success then
                __evolved_cancel()
                __error_fmt('system execution failed: %s', result)
            end
        end
        __evolved_commit()
    end

    do
        local group_subsystems = __group_subsystems[system]
        local group_subsystem_list = group_subsystems and group_subsystems.__item_list
        local group_subsystem_count = group_subsystems and group_subsystems.__item_count or 0

        if group_subsystem_count > 0 then
            local subsystem_list = __acquire_table(__table_pool_tag.system_list)

            __lua_table_move(
                group_subsystem_list, 1, group_subsystem_count,
                1, subsystem_list)

            for subsystem_index = 1, group_subsystem_count do
                local subsystem = subsystem_list[subsystem_index]
                if not __evolved_has(subsystem, __DISABLED) then
                    __system_process(subsystem)
                end
            end

            __release_table(__table_pool_tag.system_list, subsystem_list)
        end
    end

    if epilogue then
        local success, result = __lua_xpcall(epilogue, __lua_debug_traceback)

        if not success then
            __error_fmt('system epilogue failed: %s', result)
        end
    end
end

---
---
---
---
---

---@param count? integer
---@return evolved.id ... ids
---@nodiscard
function __evolved_id(count)
    count = count or 1

    if count <= 0 then
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

---@param ... evolved.id ids
---@return string ... names
---@nodiscard
function __evolved_name(...)
    local id_count = __lua_select('#', ...)

    if id_count == 0 then
        return
    end

    if id_count == 1 then
        local id1 = ...
        return __id_name(id1)
    end

    if id_count == 2 then
        local id1, id2 = ...
        return __id_name(id1), __id_name(id2)
    end

    if id_count == 3 then
        local id1, id2, id3 = ...
        return __id_name(id1), __id_name(id2), __id_name(id3)
    end

    if id_count == 4 then
        local id1, id2, id3, id4 = ...
        return __id_name(id1), __id_name(id2), __id_name(id3), __id_name(id4)
    end

    do
        local id1, id2, id3, id4 = ...
        return __id_name(id1), __id_name(id2), __id_name(id3), __id_name(id4),
            __evolved_name(__lua_select(5, ...))
    end
end

---@param primary integer
---@param secondary integer
---@return evolved.id id
---@nodiscard
function __evolved_pack(primary, secondary)
    if primary < 1 or primary > 2 ^ 20 - 1 then
        __error_fmt('the primary (%d) is out of range [1, 2 ^ 20 - 1]', primary)
    end

    if secondary < 1 or secondary > 2 ^ 20 - 1 then
        __error_fmt('the secondary (%d) is out of range [1, 2 ^ 20 - 1]', secondary)
    end

    return primary + secondary * 2 ^ 20 --[[@as evolved.id]]
end

---@param id evolved.id
---@return integer primary
---@return integer secondary
---@nodiscard
function __evolved_unpack(id)
    return id % 2 ^ 20,
        (id - id % 2 ^ 20) / 2 ^ 20 % 2 ^ 20
end

---@return boolean started
function __evolved_defer()
    __defer_depth = __defer_depth + 1
    __defer_points[__defer_depth] = __defer_length
    return __defer_depth == 1
end

---@return boolean committed
function __evolved_commit()
    if __defer_depth <= 0 then
        __error_fmt('unbalanced defer/commit/cancel')
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

---@return boolean cancelled
function __evolved_cancel()
    if __defer_depth <= 0 then
        __error_fmt('unbalanced defer/commit/cancel')
    end

    __defer_length = __defer_points[__defer_depth]

    return __evolved_commit()
end

---@param components? table<evolved.fragment, evolved.component>
---@return evolved.entity entity
function __evolved_spawn(components)
    if not components then
        components = __safe_tbls.__EMPTY_COMPONENT_MAP
    end

    if __debug_mode then
        for fragment in __lua_next, components do
            if not __evolved_alive(fragment) then
                __error_fmt('the fragment (%s) is not alive and cannot be used',
                    __id_name(fragment))
            end
        end
    end

    local entity = __acquire_id()

    if __defer_depth > 0 then
        __defer_spawn_entity(nil, entity, components)
    else
        __evolved_defer()
        do
            __spawn_entity(nil, entity, components)
        end
        __evolved_commit()
    end

    return entity
end

---@param entity_count integer
---@param components? table<evolved.fragment, evolved.component>
---@return evolved.entity[] entity_list
---@return integer entity_count
function __evolved_multi_spawn(entity_count, components)
    if entity_count <= 0 then
        return {}, 0
    end

    if not components then
        components = __safe_tbls.__EMPTY_COMPONENT_MAP
    end

    if __debug_mode then
        for fragment in __lua_next, components do
            if not __evolved_alive(fragment) then
                __error_fmt('the fragment (%s) is not alive and cannot be used',
                    __id_name(fragment))
            end
        end
    end

    local entity_list = __list_new(entity_count)

    for entity_index = 1, entity_count do
        entity_list[entity_index] = __acquire_id()
    end

    if __defer_depth > 0 then
        __defer_multi_spawn_entity(nil, entity_list, entity_count, components)
    else
        __evolved_defer()
        do
            __multi_spawn_entity(nil, entity_list, entity_count, components)
        end
        __evolved_commit()
    end

    return entity_list, entity_count
end

---@param prefab evolved.entity
---@param components? table<evolved.fragment, evolved.component>
---@return evolved.entity entity
function __evolved_clone(prefab, components)
    if not components then
        components = __safe_tbls.__EMPTY_COMPONENT_MAP
    end

    if __debug_mode then
        if not __evolved_alive(prefab) then
            __error_fmt('the prefab (%s) is not alive and cannot be used',
                __id_name(prefab))
        end

        for fragment in __lua_next, components do
            if not __evolved_alive(fragment) then
                __error_fmt('the fragment (%s) is not alive and cannot be used',
                    __id_name(fragment))
            end
        end
    end

    local entity = __acquire_id()

    if __defer_depth > 0 then
        __defer_clone_entity(prefab, entity, components)
    else
        __evolved_defer()
        do
            __clone_entity(prefab, entity, components)
        end
        __evolved_commit()
    end

    return entity
end

---@param entity_count integer
---@param prefab evolved.entity
---@param components? table<evolved.fragment, evolved.component>
---@return evolved.entity[] entity_list
---@return integer entity_count
function __evolved_multi_clone(entity_count, prefab, components)
    if entity_count <= 0 then
        return {}, 0
    end

    if not components then
        components = __safe_tbls.__EMPTY_COMPONENT_MAP
    end

    if __debug_mode then
        if not __evolved_alive(prefab) then
            __error_fmt('the prefab (%s) is not alive and cannot be used',
                __id_name(prefab))
        end

        for fragment in __lua_next, components do
            if not __evolved_alive(fragment) then
                __error_fmt('the fragment (%s) is not alive and cannot be used',
                    __id_name(fragment))
            end
        end
    end

    local entity_list = __list_new(entity_count)

    for entity_index = 1, entity_count do
        entity_list[entity_index] = __acquire_id()
    end

    if __defer_depth > 0 then
        __defer_multi_clone_entity(prefab, entity_list, entity_count, components)
    else
        __evolved_defer()
        do
            __multi_clone_entity(prefab, entity_list, entity_count, components)
        end
        __evolved_commit()
    end

    return entity_list, entity_count
end

---@param entity evolved.entity
---@return boolean
---@nodiscard
function __evolved_alive(entity)
    local entity_primary = entity % 2 ^ 20

    if __freelist_ids[entity_primary] ~= entity then
        return false
    end

    return true
end

---@param ... evolved.entity entities
---@return boolean
---@nodiscard
function __evolved_alive_all(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return true
    end

    for argument_index = 1, argument_count do
        ---@type evolved.entity
        local entity = __lua_select(argument_index, ...)
        if not __evolved_alive(entity) then
            return false
        end
    end

    return true
end

---@param ... evolved.entity entities
---@return boolean
---@nodiscard
function __evolved_alive_any(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return false
    end

    for argument_index = 1, argument_count do
        ---@type evolved.entity
        local entity = __lua_select(argument_index, ...)
        if __evolved_alive(entity) then
            return true
        end
    end

    return false
end

---@param entity evolved.entity
---@return boolean
---@nodiscard
function __evolved_empty(entity)
    local entity_primary = entity % 2 ^ 20

    if __freelist_ids[entity_primary] ~= entity then
        return true
    end

    return not __entity_chunks[entity_primary]
end

---@param ... evolved.entity entities
---@return boolean
---@nodiscard
function __evolved_empty_all(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return true
    end

    for argument_index = 1, argument_count do
        ---@type evolved.entity
        local entity = __lua_select(argument_index, ...)
        if not __evolved_empty(entity) then
            return false
        end
    end

    return true
end

---@param ... evolved.entity entities
---@return boolean
---@nodiscard
function __evolved_empty_any(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return false
    end

    for argument_index = 1, argument_count do
        ---@type evolved.entity
        local entity = __lua_select(argument_index, ...)
        if __evolved_empty(entity) then
            return true
        end
    end

    return false
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@return boolean
---@nodiscard
function __evolved_has(entity, fragment)
    local entity_primary = entity % 2 ^ 20

    if __freelist_ids[entity_primary] ~= entity then
        return false
    end

    local entity_chunk = __entity_chunks[entity_primary]

    return entity_chunk and __chunk_has_fragment(entity_chunk, fragment) or false
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function __evolved_has_all(entity, ...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return true
    end

    local entity_primary = entity % 2 ^ 20

    if __freelist_ids[entity_primary] ~= entity then
        return false
    end

    local entity_chunk = __entity_chunks[entity_primary]

    return entity_chunk and __chunk_has_all_fragments(entity_chunk, ...) or false
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function __evolved_has_any(entity, ...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return false
    end

    local entity_primary = entity % 2 ^ 20

    if __freelist_ids[entity_primary] ~= entity then
        return false
    end

    local entity_chunk = __entity_chunks[entity_primary]

    return entity_chunk and __chunk_has_any_fragments(entity_chunk, ...) or false
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return evolved.component ... components
---@nodiscard
function __evolved_get(entity, ...)
    local entity_primary = entity % 2 ^ 20

    if __freelist_ids[entity_primary] ~= entity then
        return
    end

    local entity_chunk = __entity_chunks[entity_primary]

    if not entity_chunk then
        return
    end

    local entity_place = __entity_places[entity_primary]
    return __chunk_get_all_components(entity_chunk, entity_place, ...)
end

---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
function __evolved_set(entity, fragment, component)
    local entity_primary = entity % 2 ^ 20

    if __freelist_ids[entity_primary] ~= entity then
        __error_fmt('the id (%s) is not alive and cannot be changed',
            __id_name(entity))
    end

    local fragment_primary = fragment % 2 ^ 20

    if __debug_mode then
        if __freelist_ids[fragment_primary] ~= fragment then
            __error_fmt('the id (%s) is not alive and cannot be set',
                __id_name(fragment))
        end
    end

    if __defer_depth > 0 then
        __defer_call_hook(__evolved_set, entity, fragment, component)
        return
    end

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local old_chunk = entity_chunks[entity_primary]
    local old_place = entity_places[entity_primary]

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
            -- nothing
        end
    else
        local req_fragment_set
        local req_fragment_list
        local req_fragment_count = 0

        local ini_new_chunk = new_chunk
        local ini_fragment_set = ini_new_chunk.__fragment_set

        if new_chunk.__has_required_fragments then
            ---@type table<evolved.fragment, integer>
            req_fragment_set = __acquire_table(__table_pool_tag.fragment_set)

            ---@type evolved.fragment[]
            req_fragment_list = __acquire_table(__table_pool_tag.fragment_list)

            req_fragment_count = __fragment_required_fragments(ini_new_chunk, fragment,
                req_fragment_set, req_fragment_list, req_fragment_count)

            for req_fragment_index = 1, req_fragment_count do
                local req_fragment = req_fragment_list[req_fragment_index]
                new_chunk = __chunk_with_fragment(new_chunk, req_fragment)
            end
        end

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
            entity_chunks[entity_primary] = new_chunk
            entity_places[entity_primary] = new_place

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

        for req_fragment_index = 1, req_fragment_count do
            local req_fragment = req_fragment_list[req_fragment_index]

            if ini_fragment_set[req_fragment] then
                -- this fragment has already been initialized
            else
                ---@type evolved.default?, evolved.duplicate?, evolved.set_hook?, evolved.insert_hook?
                local req_fragment_default, req_fragment_duplicate, req_fragment_on_set, req_fragment_on_insert

                if new_chunk_has_setup_hooks or new_chunk_has_insert_hooks then
                    req_fragment_default, req_fragment_duplicate, req_fragment_on_set, req_fragment_on_insert =
                        __evolved_get(req_fragment, __DEFAULT, __DUPLICATE, __ON_SET, __ON_INSERT)
                end

                local req_component_index = new_component_indices[req_fragment]

                if req_component_index then
                    local req_component_storage = new_component_storages[req_component_index]

                    local req_component = req_fragment_default

                    if req_component ~= nil and req_fragment_duplicate then
                        req_component = req_fragment_duplicate(req_component)
                    end

                    if req_component == nil then
                        req_component = true
                    end

                    req_component_storage[new_place] = req_component

                    if req_fragment_on_set then
                        __defer_call_hook(req_fragment_on_set, entity, req_fragment, req_component)
                    end

                    if req_fragment_on_insert then
                        __defer_call_hook(req_fragment_on_insert, entity, req_fragment, req_component)
                    end
                else
                    if req_fragment_on_set then
                        __defer_call_hook(req_fragment_on_set, entity, req_fragment)
                    end

                    if req_fragment_on_insert then
                        __defer_call_hook(req_fragment_on_insert, entity, req_fragment)
                    end
                end
            end
        end

        if req_fragment_set then
            __release_table(__table_pool_tag.fragment_set, req_fragment_set)
        end

        if req_fragment_list then
            __release_table(__table_pool_tag.fragment_list, req_fragment_list)
        end
    end

    __evolved_commit()
end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
function __evolved_remove(entity, ...)
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return
    end

    local entity_primary = entity % 2 ^ 20

    if __freelist_ids[entity_primary] ~= entity then
        -- the id is not alive, nothing to remove
        return
    end

    if __defer_depth > 0 then
        __defer_call_hook(__evolved_remove, entity, ...)
        return
    end

    local entity_chunks = __entity_chunks
    local entity_places = __entity_places

    local old_chunk = entity_chunks[entity_primary]
    local old_place = entity_places[entity_primary]

    local new_chunk = __chunk_without_fragments(old_chunk, ...)

    if old_chunk == new_chunk then
        return
    end

    __evolved_defer()

    do
        local old_fragment_list = old_chunk.__fragment_list
        local old_fragment_count = old_chunk.__fragment_count
        local old_component_indices = old_chunk.__component_indices
        local old_component_storages = old_chunk.__component_storages

        if old_chunk.__has_remove_hooks then
            local new_fragment_set = new_chunk and new_chunk.__fragment_set
                or __safe_tbls.__EMPTY_FRAGMENT_SET

            for old_fragment_index = 1, old_fragment_count do
                local fragment = old_fragment_list[old_fragment_index]

                if not new_fragment_set[fragment] then
                    ---@type evolved.remove_hook?
                    local fragment_on_remove = __evolved_get(fragment, __ON_REMOVE)

                    if fragment_on_remove then
                        local old_component_index = old_component_indices[fragment]

                        if old_component_index then
                            local old_component_storage = old_component_storages[old_component_index]
                            local old_component = old_component_storage[old_place]
                            fragment_on_remove(entity, fragment, old_component)
                        else
                            fragment_on_remove(entity, fragment)
                        end
                    end
                end
            end
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

            entity_chunks[entity_primary] = new_chunk
            entity_places[entity_primary] = new_chunk and new_chunk.__entity_count

            __structural_changes = __structural_changes + 1
        end
    end

    __evolved_commit()
end

---@param ... evolved.entity entities
function __evolved_clear(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return
    end

    if __defer_depth > 0 then
        __defer_call_hook(__evolved_clear, ...)
        return
    end

    __evolved_defer()

    do
        local entity_chunks = __entity_chunks
        local entity_places = __entity_places

        for argument_index = 1, argument_count do
            ---@type evolved.entity
            local entity = __lua_select(argument_index, ...)
            local entity_primary = entity % 2 ^ 20

            if __freelist_ids[entity_primary] ~= entity then
                -- the id is not alive, nothing to clear
            else
                local chunk = entity_chunks[entity_primary]
                local place = entity_places[entity_primary]

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
                                fragment_on_remove(entity, fragment, old_component)
                            else
                                fragment_on_remove(entity, fragment)
                            end
                        end
                    end
                end

                if chunk then
                    __detach_entity(chunk, place)

                    entity_chunks[entity_primary] = nil
                    entity_places[entity_primary] = nil

                    __structural_changes = __structural_changes + 1
                end
            end
        end
    end

    __evolved_commit()
end

---@param ... evolved.entity entities
function __evolved_destroy(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return
    end

    if __defer_depth > 0 then
        __defer_call_hook(__evolved_destroy, ...)
        return
    end

    __evolved_defer()

    do
        local minor_chunks = __minor_chunks

        local purging_entity_list = __acquire_table(__table_pool_tag.entity_list)
        local purging_entity_count = 0

        local purging_fragment_list = __acquire_table(__table_pool_tag.fragment_list)
        local purging_fragment_count = 0

        for argument_index = 1, argument_count do
            ---@type evolved.entity
            local entity = __lua_select(argument_index, ...)
            local entity_primary = entity % 2 ^ 20

            if __freelist_ids[entity_primary] ~= entity then
                -- the id is not alive, nothing to destroy
            else
                local is_fragment = minor_chunks[entity]

                if not is_fragment then
                    purging_entity_count = purging_entity_count + 1
                    purging_entity_list[purging_entity_count] = entity
                else
                    purging_fragment_count = purging_fragment_count + 1
                    purging_fragment_list[purging_fragment_count] = entity
                end
            end
        end

        if purging_fragment_count > 0 then
            __destroy_fragment_list(purging_fragment_list, purging_fragment_count)
            __release_table(__table_pool_tag.fragment_list, purging_fragment_list)
        else
            __release_table(__table_pool_tag.fragment_list, purging_fragment_list, true)
        end

        if purging_entity_count > 0 then
            __destroy_entity_list(purging_entity_list, purging_entity_count)
            __release_table(__table_pool_tag.entity_list, purging_entity_list)
        else
            __release_table(__table_pool_tag.entity_list, purging_entity_list, true)
        end
    end

    __evolved_commit()
end

---@param query evolved.query
---@param fragment evolved.fragment
---@param component evolved.component
function __evolved_batch_set(query, fragment, component)
    local query_primary = query % 2 ^ 20

    if __freelist_ids[query_primary] ~= query then
        __error_fmt('the id (%s) is not alive and cannot be queried',
            __id_name(query))
    end

    if __debug_mode then
        local fragment_primary = fragment % 2 ^ 20

        if __freelist_ids[fragment_primary] ~= fragment then
            __error_fmt('the id (%s) is not alive and cannot be set',
                __id_name(fragment))
        end
    end

    if __defer_depth > 0 then
        __defer_call_hook(__evolved_batch_set, query, fragment, component)
        return
    end

    __evolved_defer()

    do
        ---@type evolved.chunk[]
        local chunk_list = __acquire_table(__table_pool_tag.chunk_list)
        local chunk_count = 0

        for chunk in __evolved_execute(query) do
            chunk_count = chunk_count + 1
            chunk_list[chunk_count] = chunk
        end

        for chunk_index = 1, chunk_count do
            local chunk = chunk_list[chunk_index]
            __chunk_set(chunk, fragment, component)
        end

        __release_table(__table_pool_tag.chunk_list, chunk_list)
    end

    __evolved_commit()
end

---@param query evolved.query
---@param ... evolved.fragment fragments
function __evolved_batch_remove(query, ...)
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return
    end

    local query_primary = query % 2 ^ 20

    if __freelist_ids[query_primary] ~= query then
        __error_fmt('the id (%s) is not alive and cannot be queried',
            __id_name(query))
    end

    if __defer_depth > 0 then
        __defer_call_hook(__evolved_batch_remove, query, ...)
        return
    end

    __evolved_defer()

    do
        ---@type evolved.chunk[]
        local chunk_list = __acquire_table(__table_pool_tag.chunk_list)
        local chunk_count = 0

        for chunk in __evolved_execute(query) do
            chunk_count = chunk_count + 1
            chunk_list[chunk_count] = chunk
        end

        for chunk_index = 1, chunk_count do
            local chunk = chunk_list[chunk_index]
            __chunk_remove(chunk, ...)
        end

        __release_table(__table_pool_tag.chunk_list, chunk_list)
    end

    __evolved_commit()
end

---@param ... evolved.query queries
function __evolved_batch_clear(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return
    end

    if __defer_depth > 0 then
        __defer_call_hook(__evolved_batch_clear, ...)
        return
    end

    __evolved_defer()

    do
        ---@type evolved.chunk[]
        local chunk_list = __acquire_table(__table_pool_tag.chunk_list)
        local chunk_count = 0

        for argument_index = 1, argument_count do
            ---@type evolved.query
            local query = __lua_select(argument_index, ...)
            local query_primary = query % 2 ^ 20

            if __freelist_ids[query_primary] ~= query then
                __warning_fmt('the id (%s) is not alive and cannot be queried',
                    __id_name(query))
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

        __release_table(__table_pool_tag.chunk_list, chunk_list)
    end

    __evolved_commit()
end

---@param ... evolved.query queries
function __evolved_batch_destroy(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return
    end

    if __defer_depth > 0 then
        __defer_call_hook(__evolved_batch_destroy, ...)
        return
    end

    __evolved_defer()

    do
        local minor_chunks = __minor_chunks

        local clearing_chunk_list = __acquire_table(__table_pool_tag.chunk_list)
        local clearing_chunk_count = 0

        local purging_entity_list = __acquire_table(__table_pool_tag.entity_list)
        local purging_entity_count = 0

        local purging_fragment_list = __acquire_table(__table_pool_tag.fragment_list)
        local purging_fragment_count = 0

        for argument_index = 1, argument_count do
            ---@type evolved.query
            local query = __lua_select(argument_index, ...)
            local query_primary = query % 2 ^ 20

            if __freelist_ids[query_primary] ~= query then
                __warning_fmt('the id (%s) is not alive and cannot be queried',
                    __id_name(query))
            else
                for chunk, entity_list, entity_count in __evolved_execute(query) do
                    clearing_chunk_count = clearing_chunk_count + 1
                    clearing_chunk_list[clearing_chunk_count] = chunk

                    for i = 1, entity_count do
                        local entity = entity_list[i]

                        local is_fragment = minor_chunks[entity]

                        if not is_fragment then
                            purging_entity_count = purging_entity_count + 1
                            purging_entity_list[purging_entity_count] = entity
                        else
                            purging_fragment_count = purging_fragment_count + 1
                            purging_fragment_list[purging_fragment_count] = entity
                        end
                    end
                end
            end
        end

        if purging_fragment_count > 0 then
            __destroy_fragment_list(purging_fragment_list, purging_fragment_count)
            __release_table(__table_pool_tag.fragment_list, purging_fragment_list)
        else
            __release_table(__table_pool_tag.fragment_list, purging_fragment_list, true)
        end

        if clearing_chunk_count > 0 then
            __clear_chunk_list(clearing_chunk_list, clearing_chunk_count)
            __release_table(__table_pool_tag.chunk_list, clearing_chunk_list)
        else
            __release_table(__table_pool_tag.chunk_list, clearing_chunk_list, true)
        end

        if purging_entity_count > 0 then
            __destroy_entity_list(purging_entity_list, purging_entity_count)
            __release_table(__table_pool_tag.entity_list, purging_entity_list)
        else
            __release_table(__table_pool_tag.entity_list, purging_entity_list, true)
        end
    end

    __evolved_commit()
end

---@param entity evolved.entity
---@return evolved.each_iterator iterator
---@return evolved.each_state? iterator_state
---@nodiscard
function __evolved_each(entity)
    local entity_primary = entity % 2 ^ 20

    if __freelist_ids[entity_primary] ~= entity then
        __error_fmt('the id (%s) is not alive and cannot be iterated',
            __id_name(entity))
    end

    local entity_chunk = __entity_chunks[entity_primary]

    if not entity_chunk then
        return __iterator_fns.__each_iterator
    end

    ---@type evolved.each_state
    local each_state = __acquire_table(__table_pool_tag.each_state)

    each_state[1] = __structural_changes
    each_state[2] = entity_chunk
    each_state[3] = __entity_places[entity_primary]
    each_state[4] = 1

    return __iterator_fns.__each_iterator, each_state
end

---@param query evolved.query
---@return evolved.execute_iterator iterator
---@return evolved.execute_state? iterator_state
---@nodiscard
function __evolved_execute(query)
    local query_primary = query % 2 ^ 20

    if __freelist_ids[query_primary] ~= query then
        __error_fmt('the id (%s) is not alive and cannot be executed',
            __id_name(query))
    end

    ---@type evolved.chunk[]
    local chunk_stack = __acquire_table(__table_pool_tag.chunk_list)
    local chunk_stack_size = 0

    local query_includes = __sorted_includes[query]
    local query_include_count = query_includes and query_includes.__item_count or 0

    local query_excludes = __sorted_excludes[query]
    local query_exclude_set = query_excludes and query_excludes.__item_set
    local query_exclude_count = query_excludes and query_excludes.__item_count or 0

    if query_include_count > 0 then
        local query_chunks = __query_chunks[query] or __cache_query_chunks(query)
        local query_chunk_list = query_chunks and query_chunks.__item_list
        local query_chunk_count = query_chunks and query_chunks.__item_count or 0

        if query_chunk_count > 0 then
            __lua_table_move(
                query_chunk_list, 1, query_chunk_count,
                chunk_stack_size + 1, chunk_stack)

            chunk_stack_size = chunk_stack_size + query_chunk_count
        end
    elseif query_exclude_count > 0 then
        for _, root_chunk in __lua_next, __root_chunks do
            local is_root_chunk_matched =
                not root_chunk.__has_explicit_fragments and
                not query_exclude_set[root_chunk.__fragment]

            if is_root_chunk_matched then
                chunk_stack_size = chunk_stack_size + 1
                chunk_stack[chunk_stack_size] = root_chunk
            end
        end
    else
        for _, root_chunk in __lua_next, __root_chunks do
            local is_root_chunk_matched =
                not root_chunk.__has_explicit_fragments

            if is_root_chunk_matched then
                chunk_stack_size = chunk_stack_size + 1
                chunk_stack[chunk_stack_size] = root_chunk
            end
        end
    end

    ---@type evolved.execute_state
    local execute_state = __acquire_table(__table_pool_tag.execute_state)

    execute_state[1] = __structural_changes
    execute_state[2] = chunk_stack
    execute_state[3] = chunk_stack_size
    execute_state[4] = query_exclude_set

    return __iterator_fns.__execute_iterator, execute_state
end

---@param entity evolved.entity
---@return evolved.chunk? chunk
---@return integer place
---@nodiscard
function __evolved_locate(entity)
    local entity_primary = entity % 2 ^ 20

    if __freelist_ids[entity_primary] ~= entity then
        return nil, 0
    end

    local entity_chunk = __entity_chunks[entity_primary]

    if not entity_chunk then
        return nil, 0
    end

    return entity_chunk, __entity_places[entity_primary]
end

---@param ... evolved.system systems
function __evolved_process(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return
    end

    for argument_index = 1, argument_count do
        ---@type evolved.system
        local system = __lua_select(argument_index, ...)
        local system_primary = system % 2 ^ 20

        if __freelist_ids[system_primary] ~= system then
            __warning_fmt('the id (%s) is not alive and cannot be processed',
                __id_name(system))
        elseif __evolved_has(system, __DISABLED) then
            -- the system is disabled, nothing to process
        else
            __system_process(system)
        end
    end
end

---@param yesno boolean
function __evolved_debug_mode(yesno)
    __debug_mode = yesno
end

function __evolved_collect_garbage()
    if __defer_depth > 0 then
        __defer_call_hook(__evolved_collect_garbage)
        return
    end

    __evolved_defer()

    do
        ---@type evolved.chunk[]
        local working_chunk_stack = __acquire_table(__table_pool_tag.chunk_list)
        local working_chunk_stack_size = 0

        ---@type evolved.chunk[]
        local postorder_chunk_stack = __acquire_table(__table_pool_tag.chunk_list)
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

            local should_be_purged =
                postorder_chunk.__child_count == 0 and
                postorder_chunk.__entity_count == 0

            if should_be_purged then
                __purge_chunk(postorder_chunk)
            end
        end

        __release_table(__table_pool_tag.chunk_list, working_chunk_stack)
        __release_table(__table_pool_tag.chunk_list, postorder_chunk_stack)
    end

    for table_tag = 1, __table_pool_tag.__count do
        local table_pool = __tagged_table_pools[table_tag]
        for pool_index = 1, table_pool.__size do
            table_pool[pool_index] = {}
        end
    end

    do
        ---@type table<integer, evolved.chunk>
        local new_entity_chunks = {}

        for entity_primary, entity_chunk in __lua_next, __entity_chunks do
            new_entity_chunks[entity_primary] = entity_chunk
        end

        __entity_chunks = new_entity_chunks
    end

    do
        ---@type table<integer, integer>
        local new_entity_places = {}

        for entity_primary, entity_place in __lua_next, __entity_places do
            new_entity_places[entity_primary] = entity_place
        end

        __entity_places = new_entity_places
    end

    do
        ---@type integer[]
        local new_defer_points = __lua_table_new(__defer_depth, 0)

        __lua_table_move(
            __defer_points, 1, __defer_depth,
            1, new_defer_points)

        __defer_points = new_defer_points
    end

    do
        ---@type any[]
        local new_defer_bytecode = __lua_table_new(__defer_length, 0)

        __lua_table_move(
            __defer_bytecode, 1, __defer_length,
            1, new_defer_bytecode)

        __defer_bytecode = new_defer_bytecode
    end


    __evolved_commit()
end

---
---
---
---
---

---@param fragment evolved.fragment
---@param ... evolved.fragment fragments
---@return evolved.chunk chunk
---@return evolved.entity[] entity_list
---@return integer entity_count
---@nodiscard
function __evolved_chunk(fragment, ...)
    local chunk = __chunk_fragments(fragment, ...)
    return chunk, chunk.__entity_list, chunk.__entity_count
end

function __chunk_mt:__tostring()
    local fragment_names = {} ---@type string[]

    for fragment_index = 1, self.__fragment_count do
        fragment_names[fragment_index] = __id_name(self.__fragment_list[fragment_index])
    end

    return __lua_string_format('<%s>', __lua_table_concat(fragment_names, ', '))
end

---@return boolean
---@nodiscard
function __chunk_mt:alive()
    return not self.__unreachable_or_collected
end

---@return boolean
---@nodiscard
function __chunk_mt:empty()
    return self.__unreachable_or_collected or self.__entity_count == 0
end

---@param fragment evolved.fragment
---@return boolean
---@nodiscard
function __chunk_mt:has(fragment)
    return __chunk_has_fragment(self, fragment)
end

---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function __chunk_mt:has_all(...)
    return __chunk_has_all_fragments(self, ...)
end

---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function __chunk_mt:has_any(...)
    return __chunk_has_any_fragments(self, ...)
end

---@return evolved.entity[] entity_list
---@return integer entity_count
---@nodiscard
function __chunk_mt:entities()
    return self.__entity_list, self.__entity_count
end

---@return evolved.fragment[] fragment_list
---@return integer fragment_count
---@nodiscard
function __chunk_mt:fragments()
    return self.__fragment_list, self.__fragment_count
end

---@param ... evolved.fragment fragments
---@return evolved.storage ... storages
---@nodiscard
function __chunk_mt:components(...)
    local fragment_count = __lua_select('#', ...)

    if fragment_count == 0 then
        return
    end

    local indices = self.__component_indices
    local storages = self.__component_storages

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
            self:components(__lua_select(5, ...))
    end
end

---
---
---
---
---

---@return evolved.builder builder
---@nodiscard
function __evolved_builder()
    return __lua_setmetatable({
        __components = {},
    }, __builder_mt)
end

function __builder_mt:__tostring()
    local fragment_list = {} ---@type evolved.fragment[]
    local fragment_count = 0 ---@type integer

    for fragment in __lua_next, self.__components do
        fragment_count = fragment_count + 1
        fragment_list[fragment_count] = fragment
    end

    __lua_table_sort(fragment_list)

    local fragment_names = {} ---@type string[]

    for fragment_index = 1, fragment_count do
        fragment_names[fragment_index] = __id_name(fragment_list[fragment_index])
    end

    return __lua_string_format('<%s>', __lua_table_concat(fragment_names, ', '))
end

---@param prefab? evolved.entity
---@return evolved.entity entity
function __builder_mt:build(prefab)
    if prefab then
        return self:clone(prefab)
    else
        return self:spawn()
    end
end

---@param entity_count integer
---@param prefab? evolved.entity
---@return evolved.entity[] entity_list
---@return integer entity_count
function __builder_mt:multi_build(entity_count, prefab)
    if prefab then
        return self:multi_clone(entity_count, prefab)
    else
        return self:multi_spawn(entity_count)
    end
end

---@return evolved.entity entity
function __builder_mt:spawn()
    local chunk = self.__chunk
    local components = self.__components

    if __debug_mode then
        for fragment in __lua_next, components do
            if not __evolved_alive(fragment) then
                __error_fmt('the fragment (%s) is not alive and cannot be used',
                    __id_name(fragment))
            end
        end
    end

    local entity = __acquire_id()

    if __defer_depth > 0 then
        __defer_spawn_entity(chunk, entity, components)
    else
        __evolved_defer()
        do
            __spawn_entity(chunk, entity, components)
        end
        __evolved_commit()
    end

    return entity
end

---@param entity_count integer
---@return evolved.entity[] entity_list
---@return integer entity_count
function __builder_mt:multi_spawn(entity_count)
    if entity_count <= 0 then
        return {}, 0
    end

    local chunk = self.__chunk
    local components = self.__components

    if __debug_mode then
        for fragment in __lua_next, components do
            if not __evolved_alive(fragment) then
                __error_fmt('the fragment (%s) is not alive and cannot be used',
                    __id_name(fragment))
            end
        end
    end

    local entity_list = __list_new(entity_count)

    for entity_index = 1, entity_count do
        entity_list[entity_index] = __acquire_id()
    end

    if __defer_depth > 0 then
        __defer_multi_spawn_entity(chunk, entity_list, entity_count, components)
    else
        __evolved_defer()
        do
            __multi_spawn_entity(chunk, entity_list, entity_count, components)
        end
        __evolved_commit()
    end

    return entity_list, entity_count
end

---@param prefab evolved.entity
---@return evolved.entity entity
function __builder_mt:clone(prefab)
    local components = self.__components

    if __debug_mode then
        if not __evolved_alive(prefab) then
            __error_fmt('the prefab (%s) is not alive and cannot be used',
                __id_name(prefab))
        end

        for fragment in __lua_next, components do
            if not __evolved_alive(fragment) then
                __error_fmt('the fragment (%s) is not alive and cannot be used',
                    __id_name(fragment))
            end
        end
    end

    local entity = __acquire_id()

    if __defer_depth > 0 then
        __defer_clone_entity(prefab, entity, components)
    else
        __evolved_defer()
        do
            __clone_entity(prefab, entity, components)
        end
        __evolved_commit()
    end

    return entity
end

---@param entity_count integer
---@param prefab evolved.entity
---@return evolved.entity[] entity_list
---@return integer entity_count
function __builder_mt:multi_clone(entity_count, prefab)
    if entity_count <= 0 then
        return {}, 0
    end

    local components = self.__components

    if __debug_mode then
        if not __evolved_alive(prefab) then
            __error_fmt('the prefab (%s) is not alive and cannot be used',
                __id_name(prefab))
        end

        for fragment in __lua_next, components do
            if not __evolved_alive(fragment) then
                __error_fmt('the fragment (%s) is not alive and cannot be used',
                    __id_name(fragment))
            end
        end
    end

    local entity_list = __list_new(entity_count)

    for entity_index = 1, entity_count do
        entity_list[entity_index] = __acquire_id()
    end

    if __defer_depth > 0 then
        __defer_multi_clone_entity(prefab, entity_list, entity_count, components)
    else
        __evolved_defer()
        do
            __multi_clone_entity(prefab, entity_list, entity_count, components)
        end
        __evolved_commit()
    end

    return entity_list, entity_count
end

---@param fragment evolved.fragment
---@return boolean
---@nodiscard
function __builder_mt:has(fragment)
    local chunk = self.__chunk

    if chunk and __chunk_has_fragment(chunk, fragment) then
        return true
    end

    return false
end

---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function __builder_mt:has_all(...)
    local chunk = self.__chunk

    if chunk and __chunk_has_all_fragments(chunk, ...) then
        return true
    end

    return __lua_select("#", ...) == 0
end

---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function __builder_mt:has_any(...)
    local chunk = self.__chunk

    if chunk and __chunk_has_any_fragments(chunk, ...) then
        return true
    end

    return false
end

---@param ... evolved.fragment fragments
---@return evolved.component ... components
---@nodiscard
function __builder_mt:get(...)
    local fragment_count = __lua_select("#", ...)

    if fragment_count == 0 then
        return
    end

    local cs = self.__components

    if fragment_count == 1 then
        local f1 = ...
        return cs[f1]
    end

    if fragment_count == 2 then
        local f1, f2 = ...
        return cs[f1], cs[f2]
    end

    if fragment_count == 3 then
        local f1, f2, f3 = ...
        return cs[f1], cs[f2], cs[f3]
    end

    if fragment_count == 4 then
        local f1, f2, f3, f4 = ...
        return cs[f1], cs[f2], cs[f3], cs[f4]
    end

    do
        local f1, f2, f3, f4 = ...
        return cs[f1], cs[f2], cs[f3], cs[f4],
            self:get(__lua_select(5, ...))
    end
end

---@param fragment evolved.fragment
---@param component evolved.component
---@return evolved.builder builder
function __builder_mt:set(fragment, component)
    local fragment_primary = fragment % 2 ^ 20

    if __debug_mode then
        if __freelist_ids[fragment_primary] ~= fragment then
            __error_fmt('the id (%s) is not alive and cannot be set',
                __id_name(fragment))
        end
    end

    local new_chunk = __chunk_with_fragment(self.__chunk, fragment)
    local components = self.__components

    if new_chunk.__has_setup_hooks then
        ---@type evolved.default?, evolved.duplicate?
        local fragment_default, fragment_duplicate =
            __evolved_get(fragment, __DEFAULT, __DUPLICATE)

        local new_component = component
        if new_component == nil then new_component = fragment_default end
        if new_component ~= nil and fragment_duplicate then new_component = fragment_duplicate(new_component) end
        if new_component == nil then new_component = true end

        components[fragment] = new_component
    else
        local new_component = component
        if new_component == nil then new_component = true end

        components[fragment] = new_component
    end

    self.__chunk = new_chunk
    return self
end

---@param ... evolved.fragment fragments
---@return evolved.builder builder
function __builder_mt:remove(...)
    local fragment_count = __lua_select("#", ...)

    if fragment_count == 0 then
        return self
    end

    local new_chunk = self.__chunk
    local components = self.__components

    for fragment_index = 1, fragment_count do
        ---@type evolved.fragment
        local fragment = __lua_select(fragment_index, ...)
        new_chunk, components[fragment] = __chunk_without_fragment(new_chunk, fragment), nil
    end

    self.__chunk = new_chunk
    return self
end

---@return evolved.builder builder
function __builder_mt:clear()
    self.__chunk = nil
    __lua_table_clear(self.__components)
    return self
end

---@return evolved.builder builder
function __builder_mt:tag()
    return self:set(__TAG)
end

---@param name string
---@return evolved.builder builder
function __builder_mt:name(name)
    return self:set(__NAME, name)
end

---@return evolved.builder builder
function __builder_mt:unique()
    return self:set(__UNIQUE)
end

---@return evolved.builder builder
function __builder_mt:explicit()
    return self:set(__EXPLICIT)
end

---@return evolved.builder builder
function __builder_mt:internal()
    return self:set(__INTERNAL)
end

---@param default evolved.default
---@return evolved.builder builder
function __builder_mt:default(default)
    return self:set(__DEFAULT, default)
end

---@param duplicate evolved.duplicate
---@return evolved.builder builder
function __builder_mt:duplicate(duplicate)
    return self:set(__DUPLICATE, duplicate)
end

---@return evolved.builder builder
function __builder_mt:prefab()
    return self:set(__PREFAB)
end

---@return evolved.builder builder
function __builder_mt:disabled()
    return self:set(__DISABLED)
end

---@param ... evolved.fragment fragments
---@return evolved.builder builder
function __builder_mt:include(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return self
    end

    local include_list = self:get(__INCLUDES)
    local include_count = include_list and #include_list or 0

    if include_count == 0 then
        include_list = __list_new(argument_count)
    end

    for argument_index = 1, argument_count do
        ---@type evolved.fragment
        local fragment = __lua_select(argument_index, ...)
        include_list[include_count + argument_index] = fragment
    end

    return self:set(__INCLUDES, include_list)
end

---@param ... evolved.fragment fragments
---@return evolved.builder builder
function __builder_mt:exclude(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return self
    end

    local exclude_list = self:get(__EXCLUDES)
    local exclude_count = exclude_list and #exclude_list or 0

    if exclude_count == 0 then
        exclude_list = __list_new(argument_count)
    end

    for argument_index = 1, argument_count do
        ---@type evolved.fragment
        local fragment = __lua_select(argument_index, ...)
        exclude_list[exclude_count + argument_index] = fragment
    end

    return self:set(__EXCLUDES, exclude_list)
end

---@param ... evolved.fragment fragments
---@return evolved.builder builder
function __builder_mt:require(...)
    local argument_count = __lua_select('#', ...)

    if argument_count == 0 then
        return self
    end

    local require_list = self:get(__REQUIRES)
    local require_count = require_list and #require_list or 0

    if require_count == 0 then
        require_list = __list_new(argument_count)
    end

    for argument_index = 1, argument_count do
        ---@type evolved.fragment
        local fragment = __lua_select(argument_index, ...)
        require_list[require_count + argument_index] = fragment
    end

    return self:set(__REQUIRES, require_list)
end

---@param on_set evolved.set_hook
---@return evolved.builder builder
function __builder_mt:on_set(on_set)
    return self:set(__ON_SET, on_set)
end

---@param on_assign evolved.assign_hook
---@return evolved.builder builder
function __builder_mt:on_assign(on_assign)
    return self:set(__ON_ASSIGN, on_assign)
end

---@param on_insert evolved.insert_hook
---@return evolved.builder builder
function __builder_mt:on_insert(on_insert)
    return self:set(__ON_INSERT, on_insert)
end

---@param on_remove evolved.remove_hook
---@return evolved.builder builder
function __builder_mt:on_remove(on_remove)
    return self:set(__ON_REMOVE, on_remove)
end

---@param group evolved.system
---@return evolved.builder builder
function __builder_mt:group(group)
    return self:set(__GROUP, group)
end

---@param query evolved.query
---@return evolved.builder builder
function __builder_mt:query(query)
    return self:set(__QUERY, query)
end

---@param execute evolved.execute
---@return evolved.builder builder
function __builder_mt:execute(execute)
    return self:set(__EXECUTE, execute)
end

---@param prologue evolved.prologue
---@return evolved.builder builder
function __builder_mt:prologue(prologue)
    return self:set(__PROLOGUE, prologue)
end

---@param epilogue evolved.epilogue
---@return evolved.builder builder
function __builder_mt:epilogue(epilogue)
    return self:set(__EPILOGUE, epilogue)
end

---@param destruction_policy evolved.id
---@return evolved.builder builder
function __builder_mt:destruction_policy(destruction_policy)
    return self:set(__DESTRUCTION_POLICY, destruction_policy)
end

---
---
---
---
---

__evolved_set(__ON_SET, __ON_INSERT, __update_major_chunks)
__evolved_set(__ON_SET, __ON_REMOVE, __update_major_chunks)

__evolved_set(__ON_ASSIGN, __ON_INSERT, __update_major_chunks)
__evolved_set(__ON_ASSIGN, __ON_REMOVE, __update_major_chunks)

__evolved_set(__ON_INSERT, __ON_INSERT, __update_major_chunks)
__evolved_set(__ON_INSERT, __ON_REMOVE, __update_major_chunks)

__evolved_set(__ON_REMOVE, __ON_INSERT, __update_major_chunks)
__evolved_set(__ON_REMOVE, __ON_REMOVE, __update_major_chunks)

---
---
---
---
---

__evolved_set(__TAG, __ON_INSERT, __update_major_chunks)
__evolved_set(__TAG, __ON_REMOVE, __update_major_chunks)

__evolved_set(__UNIQUE, __ON_INSERT, __update_major_chunks)
__evolved_set(__UNIQUE, __ON_REMOVE, __update_major_chunks)

__evolved_set(__EXPLICIT, __ON_INSERT, __update_major_chunks)
__evolved_set(__EXPLICIT, __ON_REMOVE, __update_major_chunks)

__evolved_set(__INTERNAL, __ON_INSERT, __update_major_chunks)
__evolved_set(__INTERNAL, __ON_REMOVE, __update_major_chunks)

__evolved_set(__DEFAULT, __ON_INSERT, __update_major_chunks)
__evolved_set(__DEFAULT, __ON_REMOVE, __update_major_chunks)

__evolved_set(__DUPLICATE, __ON_INSERT, __update_major_chunks)
__evolved_set(__DUPLICATE, __ON_REMOVE, __update_major_chunks)

__evolved_set(__REQUIRES, __ON_INSERT, __update_major_chunks)
__evolved_set(__REQUIRES, __ON_REMOVE, __update_major_chunks)

---
---
---
---
---

__evolved_set(__TAG, __NAME, 'TAG')
__evolved_set(__NAME, __NAME, 'NAME')

__evolved_set(__UNIQUE, __NAME, 'UNIQUE')
__evolved_set(__EXPLICIT, __NAME, 'EXPLICIT')
__evolved_set(__INTERNAL, __NAME, 'INTERNAL')

__evolved_set(__DEFAULT, __NAME, 'DEFAULT')
__evolved_set(__DUPLICATE, __NAME, 'DUPLICATE')

__evolved_set(__PREFAB, __NAME, 'PREFAB')
__evolved_set(__DISABLED, __NAME, 'DISABLED')

__evolved_set(__INCLUDES, __NAME, 'INCLUDES')
__evolved_set(__EXCLUDES, __NAME, 'EXCLUDES')
__evolved_set(__REQUIRES, __NAME, 'REQUIRES')

__evolved_set(__ON_SET, __NAME, 'ON_SET')
__evolved_set(__ON_ASSIGN, __NAME, 'ON_ASSIGN')
__evolved_set(__ON_INSERT, __NAME, 'ON_INSERT')
__evolved_set(__ON_REMOVE, __NAME, 'ON_REMOVE')

__evolved_set(__GROUP, __NAME, 'GROUP')

__evolved_set(__QUERY, __NAME, 'QUERY')
__evolved_set(__EXECUTE, __NAME, 'EXECUTE')

__evolved_set(__PROLOGUE, __NAME, 'PROLOGUE')
__evolved_set(__EPILOGUE, __NAME, 'EPILOGUE')

__evolved_set(__DESTRUCTION_POLICY, __NAME, 'DESTRUCTION_POLICY')
__evolved_set(__DESTRUCTION_POLICY_DESTROY_ENTITY, __NAME, 'DESTRUCTION_POLICY_DESTROY_ENTITY')
__evolved_set(__DESTRUCTION_POLICY_REMOVE_FRAGMENT, __NAME, 'DESTRUCTION_POLICY_REMOVE_FRAGMENT')

---
---
---
---
---

__evolved_set(__TAG, __INTERNAL)
__evolved_set(__NAME, __INTERNAL)

__evolved_set(__UNIQUE, __INTERNAL)
__evolved_set(__EXPLICIT, __INTERNAL)
__evolved_set(__INTERNAL, __INTERNAL)

__evolved_set(__DEFAULT, __INTERNAL)
__evolved_set(__DUPLICATE, __INTERNAL)

__evolved_set(__PREFAB, __INTERNAL)
__evolved_set(__DISABLED, __INTERNAL)

__evolved_set(__INCLUDES, __INTERNAL)
__evolved_set(__EXCLUDES, __INTERNAL)
__evolved_set(__REQUIRES, __INTERNAL)

__evolved_set(__ON_SET, __INTERNAL)
__evolved_set(__ON_ASSIGN, __INTERNAL)
__evolved_set(__ON_INSERT, __INTERNAL)
__evolved_set(__ON_REMOVE, __INTERNAL)

__evolved_set(__GROUP, __INTERNAL)

__evolved_set(__QUERY, __INTERNAL)
__evolved_set(__EXECUTE, __INTERNAL)

__evolved_set(__PROLOGUE, __INTERNAL)
__evolved_set(__EPILOGUE, __INTERNAL)

__evolved_set(__DESTRUCTION_POLICY, __INTERNAL)
__evolved_set(__DESTRUCTION_POLICY_DESTROY_ENTITY, __INTERNAL)
__evolved_set(__DESTRUCTION_POLICY_REMOVE_FRAGMENT, __INTERNAL)

---
---
---
---
---

__evolved_set(__TAG, __TAG)

__evolved_set(__UNIQUE, __TAG)

__evolved_set(__EXPLICIT, __TAG)

__evolved_set(__INTERNAL, __TAG)
__evolved_set(__INTERNAL, __UNIQUE)
__evolved_set(__INTERNAL, __EXPLICIT)

__evolved_set(__PREFAB, __TAG)
__evolved_set(__PREFAB, __UNIQUE)
__evolved_set(__PREFAB, __EXPLICIT)

__evolved_set(__DISABLED, __TAG)
__evolved_set(__DISABLED, __UNIQUE)
__evolved_set(__DISABLED, __EXPLICIT)

__evolved_set(__INCLUDES, __DEFAULT, __list_new())
__evolved_set(__INCLUDES, __DUPLICATE, __list_dup)

__evolved_set(__EXCLUDES, __DEFAULT, __list_new())
__evolved_set(__EXCLUDES, __DUPLICATE, __list_dup)

__evolved_set(__REQUIRES, __DEFAULT, __list_new())
__evolved_set(__REQUIRES, __DUPLICATE, __list_dup)

__evolved_set(__ON_SET, __UNIQUE)
__evolved_set(__ON_ASSIGN, __UNIQUE)
__evolved_set(__ON_INSERT, __UNIQUE)
__evolved_set(__ON_REMOVE, __UNIQUE)

---
---
---
---
---

---@param query evolved.query
local function __insert_query(query)
    local query_includes = __sorted_includes[query]
    local query_include_list = query_includes and query_includes.__item_list
    local query_include_count = query_includes and query_includes.__item_count or 0

    if query_include_count > 0 then
        local query_major = query_include_list[query_include_count]
        local major_queries = __major_queries[query_major]

        if not major_queries then
            major_queries = __assoc_list_new(4)
            __major_queries[query_major] = major_queries
        end

        __assoc_list_insert(major_queries, query)
    end
end

---@param query evolved.query
local function __remove_query(query)
    local query_includes = __sorted_includes[query]
    local query_include_list = query_includes and query_includes.__item_list
    local query_include_count = query_includes and query_includes.__item_count or 0

    if query_include_count > 0 then
        local query_major = query_include_list[query_include_count]
        local major_queries = __major_queries[query_major]

        if major_queries and __assoc_list_remove(major_queries, query) == 0 then
            __major_queries[query_major] = nil
        end
    end

    __reset_query_chunks(query)
end

---@param query evolved.query
---@param include_list evolved.fragment[]
__evolved_set(__INCLUDES, __ON_SET, function(query, _, include_list)
    __remove_query(query)

    local include_count = #include_list

    if include_count > 0 then
        ---@type evolved.assoc_list<evolved.fragment>
        local sorted_includes = __assoc_list_new(include_count)

        __assoc_list_move(include_list, 1, include_count, sorted_includes)
        __assoc_list_sort(sorted_includes)

        __sorted_includes[query] = sorted_includes
    else
        __sorted_includes[query] = nil
    end

    __insert_query(query)
end)

__evolved_set(__INCLUDES, __ON_REMOVE, function(query)
    __remove_query(query)

    __sorted_includes[query] = nil

    __insert_query(query)
end)

---
---
---
---
---

---@param query evolved.query
---@param exclude_list evolved.fragment[]
__evolved_set(__EXCLUDES, __ON_SET, function(query, _, exclude_list)
    __remove_query(query)

    local exclude_count = #exclude_list

    if exclude_count > 0 then
        ---@type evolved.assoc_list<evolved.fragment>
        local sorted_excludes = __assoc_list_new(exclude_count)

        __assoc_list_move(exclude_list, 1, exclude_count, sorted_excludes)
        __assoc_list_sort(sorted_excludes)

        __sorted_excludes[query] = sorted_excludes
    else
        __sorted_excludes[query] = nil
    end

    __insert_query(query)
end)

__evolved_set(__EXCLUDES, __ON_REMOVE, function(query)
    __remove_query(query)

    __sorted_excludes[query] = nil

    __insert_query(query)
end)

---
---
---
---
---

---@param fragment evolved.fragment
---@param require_list evolved.fragment[]
__evolved_set(__REQUIRES, __ON_SET, function(fragment, _, require_list)
    local require_count = #require_list

    if require_count > 0 then
        ---@type evolved.assoc_list<evolved.fragment>
        local sorted_requires = __assoc_list_new(require_count)

        __assoc_list_move(require_list, 1, require_count, sorted_requires)
        __assoc_list_sort(sorted_requires)

        __sorted_requires[fragment] = sorted_requires
    else
        __sorted_requires[fragment] = nil
    end
end)

__evolved_set(__REQUIRES, __ON_REMOVE, function(fragment)
    __sorted_requires[fragment] = nil
end)

---
---
---
---
---

---@param subsystem evolved.system
local function __add_subsystem(subsystem)
    local subsystem_group = __subsystem_groups[subsystem]

    if subsystem_group then
        local group_subsystems = __group_subsystems[subsystem_group]

        if not group_subsystems then
            ---@type evolved.assoc_list<evolved.system>
            group_subsystems = __assoc_list_new(4)
            __group_subsystems[subsystem_group] = group_subsystems
        end

        __assoc_list_insert(group_subsystems, subsystem)
    end
end

---@param subsystem evolved.system
local function __remove_subsystem(subsystem)
    local subsystem_group = __subsystem_groups[subsystem]

    if subsystem_group then
        local group_subsystems = __group_subsystems[subsystem_group]

        if group_subsystems and __assoc_list_remove(group_subsystems, subsystem) == 0 then
            __group_subsystems[subsystem_group] = nil
        end
    end
end

---@param system evolved.system
__evolved_set(__GROUP, __ON_SET, function(system, _, group)
    __remove_subsystem(system)

    __subsystem_groups[system] = group

    __add_subsystem(system)
end)

---@param system evolved.system
__evolved_set(__GROUP, __ON_REMOVE, function(system)
    __remove_subsystem(system)

    __subsystem_groups[system] = nil

    __add_subsystem(system)
end)

---
---
--- Predefs
---
---

evolved.TAG = __TAG
evolved.NAME = __NAME

evolved.UNIQUE = __UNIQUE
evolved.EXPLICIT = __EXPLICIT
evolved.INTERNAL = __INTERNAL

evolved.DEFAULT = __DEFAULT
evolved.DUPLICATE = __DUPLICATE

evolved.PREFAB = __PREFAB
evolved.DISABLED = __DISABLED

evolved.INCLUDES = __INCLUDES
evolved.EXCLUDES = __EXCLUDES
evolved.REQUIRES = __REQUIRES

evolved.ON_SET = __ON_SET
evolved.ON_ASSIGN = __ON_ASSIGN
evolved.ON_INSERT = __ON_INSERT
evolved.ON_REMOVE = __ON_REMOVE

evolved.GROUP = __GROUP

evolved.QUERY = __QUERY
evolved.EXECUTE = __EXECUTE

evolved.PROLOGUE = __PROLOGUE
evolved.EPILOGUE = __EPILOGUE

evolved.DESTRUCTION_POLICY = __DESTRUCTION_POLICY
evolved.DESTRUCTION_POLICY_DESTROY_ENTITY = __DESTRUCTION_POLICY_DESTROY_ENTITY
evolved.DESTRUCTION_POLICY_REMOVE_FRAGMENT = __DESTRUCTION_POLICY_REMOVE_FRAGMENT

---
---
--- Functions
---
---

evolved.id = __evolved_id
evolved.name = __evolved_name

evolved.pack = __evolved_pack
evolved.unpack = __evolved_unpack

evolved.defer = __evolved_defer
evolved.commit = __evolved_commit
evolved.cancel = __evolved_cancel

evolved.spawn = __evolved_spawn
evolved.multi_spawn = __evolved_multi_spawn

evolved.clone = __evolved_clone
evolved.multi_clone = __evolved_multi_clone

evolved.alive = __evolved_alive
evolved.alive_all = __evolved_alive_all
evolved.alive_any = __evolved_alive_any

evolved.empty = __evolved_empty
evolved.empty_all = __evolved_empty_all
evolved.empty_any = __evolved_empty_any

evolved.has = __evolved_has
evolved.has_all = __evolved_has_all
evolved.has_any = __evolved_has_any

evolved.get = __evolved_get

evolved.set = __evolved_set
evolved.remove = __evolved_remove
evolved.clear = __evolved_clear
evolved.destroy = __evolved_destroy

evolved.batch_set = __evolved_batch_set
evolved.batch_remove = __evolved_batch_remove
evolved.batch_clear = __evolved_batch_clear
evolved.batch_destroy = __evolved_batch_destroy

evolved.each = __evolved_each
evolved.execute = __evolved_execute

evolved.locate = __evolved_locate

evolved.process = __evolved_process

evolved.debug_mode = __evolved_debug_mode
evolved.collect_garbage = __evolved_collect_garbage

evolved.chunk = __evolved_chunk
evolved.builder = __evolved_builder

---
---
---
---
---

evolved.collect_garbage()

return evolved
