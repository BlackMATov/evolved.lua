local idpools = require 'evolved.idpools'

---@class evolved.registry
local registry = {}

---
---
---
---
---

local __guids = idpools.idpool()
local __roots = {} ---@type table<evolved.entity, evolved.chunk>
local __chunks = {} ---@type table<evolved.entity, evolved.chunk[]>
local __changes = 0 ---@type integer

---
---
---
---
---

---@class evolved.entity
---@field package __guid evolved.id
---@field package __chunk? evolved.chunk
---@field package __index_in_chunk integer
local evolved_entity_mt = {}
evolved_entity_mt.__index = evolved_entity_mt

---@class evolved.query
---@field package __changes integer
---@field package __include_list evolved.entity[]
---@field package __exclude_list evolved.entity[]
---@field package __include_set table<evolved.entity, boolean>
---@field package __exclude_set table<evolved.entity, boolean>
local evolved_query_mt = {}
evolved_query_mt.__index = evolved_query_mt

---@class evolved.chunk
---@field package __changes integer
---@field package __parent? evolved.chunk
---@field package __fragment evolved.entity
---@field package __children evolved.chunk[]
---@field package __entities evolved.entity[]
---@field package __components table<evolved.entity, any[]>
---@field package __with_fragment_cache table<evolved.entity, evolved.chunk>
---@field package __without_fragment_cache table<evolved.entity, evolved.chunk>
local evolved_chunk_mt = {}
evolved_chunk_mt.__index = evolved_chunk_mt

---
---
---
---
---

---@param entity evolved.entity
local function __detach_entity(entity)
    local chunk = assert(entity.__chunk)
    local index_in_chunk = entity.__index_in_chunk

    __changes = __changes + 1
    chunk.__changes = chunk.__changes + 1

    if index_in_chunk == #chunk.__entities then
        chunk.__entities[index_in_chunk] = nil

        for _, cs in pairs(chunk.__components) do
            cs[index_in_chunk] = nil
        end
    else
        chunk.__entities[index_in_chunk] = chunk.__entities[#chunk.__entities]
        chunk.__entities[index_in_chunk].__index_in_chunk = index_in_chunk
        chunk.__entities[#chunk.__entities] = nil

        for _, cs in pairs(chunk.__components) do
            cs[index_in_chunk] = cs[#cs]
            cs[#cs] = nil
        end
    end

    entity.__chunk = nil
    entity.__index_in_chunk = 0
end

---@param chunk evolved.chunk
---@param fragment evolved.entity
---@return boolean
---@nodiscard
local function __chunk_has_fragment(chunk, fragment)
    return chunk.__components[fragment] ~= nil
end

---@param chunk evolved.chunk
---@param ... evolved.entity fragments
---@return boolean
---@nodiscard
local function __chunk_has_all_fragments(chunk, ...)
    local components = chunk.__components

    for i = 1, select('#', ...) do
        if components[select(i, ...)] == nil then
            return false
        end
    end

    return true
end

---@param chunk evolved.chunk
---@param fragment_list evolved.entity[]
---@return boolean
---@nodiscard
local function __chunk_has_all_fragment_list(chunk, fragment_list)
    local components = chunk.__components

    for i = 1, #fragment_list do
        if components[fragment_list[i]] == nil then
            return false
        end
    end

    return true
end

---@param chunk evolved.chunk
---@param ... evolved.entity fragments
---@return boolean
---@nodiscard
local function __chunk_has_any_fragments(chunk, ...)
    local components = chunk.__components

    for i = 1, select('#', ...) do
        if components[select(i, ...)] ~= nil then
            return true
        end
    end

    return false
end

---@param chunk evolved.chunk
---@param fragment_list evolved.entity[]
---@return boolean
---@nodiscard
local function __chunk_has_any_fragment_list(chunk, fragment_list)
    local components = chunk.__components

    for i = 1, #fragment_list do
        if components[fragment_list[i]] ~= nil then
            return true
        end
    end

    return false
end

---@param fragment evolved.entity
---@return evolved.chunk
---@nodiscard
local function __root_chunk(fragment)
    do
        local root_chunk = __roots[fragment]
        if root_chunk then return root_chunk end
    end

    ---@type evolved.chunk
    local root_chunk = {
        __changes = 0,
        __parent = nil,
        __fragment = fragment,
        __children = {},
        __entities = {},
        __components = { [fragment] = {} },
        __with_fragment_cache = {},
        __without_fragment_cache = {},
    }

    setmetatable(root_chunk, evolved_chunk_mt)

    do
        __roots[fragment] = root_chunk
    end

    do
        local fragment_chunks = __chunks[fragment] or {}
        fragment_chunks[#fragment_chunks + 1] = root_chunk
        __chunks[fragment] = fragment_chunks
        __changes = __changes + 1
    end

    return root_chunk
end

---@param chunk? evolved.chunk
---@param fragment evolved.entity
---@return evolved.chunk
---@nodiscard
local function __chunk_with_fragment(chunk, fragment)
    if chunk == nil then
        return __root_chunk(fragment)
    end

    if chunk.__components[fragment] ~= nil then
        return chunk
    end

    do
        local cached_chunk = chunk.__with_fragment_cache[fragment]
        if cached_chunk then return cached_chunk end
    end

    if fragment.__guid == chunk.__fragment.__guid then
        return chunk
    end

    if fragment.__guid < chunk.__fragment.__guid then
        local sibling_chunk = __chunk_with_fragment(
            __chunk_with_fragment(chunk.__parent, fragment),
            chunk.__fragment)

        chunk.__changes = chunk.__changes + 1
        sibling_chunk.__changes = sibling_chunk.__changes + 1

        chunk.__with_fragment_cache[fragment] = sibling_chunk
        sibling_chunk.__without_fragment_cache[fragment] = chunk

        return sibling_chunk
    end

    ---@type evolved.chunk
    local child_chunk = {
        __changes = 0,
        __parent = chunk,
        __fragment = fragment,
        __children = {},
        __entities = {},
        __components = { [fragment] = {} },
        __with_fragment_cache = {},
        __without_fragment_cache = {},
    }

    for f, _ in pairs(chunk.__components) do
        child_chunk.__components[f] = {}
    end

    setmetatable(child_chunk, evolved_chunk_mt)

    do
        local chunk_children = chunk.__children
        chunk_children[#chunk_children + 1] = child_chunk
    end

    do
        chunk.__changes = chunk.__changes + 1
        child_chunk.__changes = child_chunk.__changes + 1

        chunk.__with_fragment_cache[fragment] = child_chunk
        child_chunk.__without_fragment_cache[fragment] = chunk
    end

    do
        local fragment_chunks = __chunks[fragment] or {}
        fragment_chunks[#fragment_chunks + 1] = child_chunk
        __chunks[fragment] = fragment_chunks
        __changes = __changes + 1
    end

    return child_chunk
end

---@param chunk? evolved.chunk
---@param fragment evolved.entity
---@return evolved.chunk?
---@nodiscard
local function __chunk_without_fragment(chunk, fragment)
    if chunk == nil then
        return nil
    end

    if chunk.__components[fragment] == nil then
        return chunk
    end

    do
        local cached_chunk = chunk.__without_fragment_cache[fragment]
        if cached_chunk then return cached_chunk end
    end

    if fragment.__guid == chunk.__fragment.__guid then
        return chunk.__parent
    end

    if fragment.__guid < chunk.__fragment.__guid then
        local sibling_chunk = __chunk_with_fragment(
            __chunk_without_fragment(chunk.__parent, fragment),
            chunk.__fragment)

        chunk.__changes = chunk.__changes + 1
        sibling_chunk.__changes = sibling_chunk.__changes + 1

        chunk.__without_fragment_cache[fragment] = sibling_chunk
        sibling_chunk.__with_fragment_cache[fragment] = chunk

        return sibling_chunk
    end

    return chunk
end

---@param chunk? evolved.chunk
---@param ... evolved.entity fragments
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

---@return evolved.entity
---@nodiscard
function registry.entity()
    local guid = idpools.acquire(__guids)

    ---@type evolved.entity
    local entity = {
        __guid = guid,
        __chunk = nil,
        __index_in_chunk = 0,
    }

    return setmetatable(entity, evolved_entity_mt)
end

---@param entity evolved.entity
---@return evolved.id
---@nodiscard
function registry.guid(entity)
    return entity.__guid
end

---@param entity evolved.entity
---@return boolean
---@nodiscard
function registry.alive(entity)
    return idpools.alive(__guids, entity.__guid)
end

---@param entity evolved.entity
---@return boolean is_destroyed
function registry.destroy(entity)
    if not idpools.alive(__guids, entity.__guid) then
        return false
    end

    if entity.__chunk ~= nil then
        __detach_entity(entity)
    end

    idpools.release(__guids, entity.__guid)
    return true
end

---@param query evolved.query
---@return integer destroyed_count
function registry.batch_destroy(query)
    error('not impl yet', 2)
end

---@param entity evolved.entity
---@param ... evolved.entity fragments
---@return evolved.entity
function registry.del(entity, ...)
    registry.remove(entity, ...)
    return entity
end

---@param entity evolved.entity
---@param fragment evolved.entity
---@param component any
---@return evolved.entity
function registry.set(entity, fragment, component)
    if registry.has(entity, fragment) then
        registry.assign(entity, fragment, component)
    else
        registry.insert(entity, fragment, component)
    end
    return entity
end

---@param entity evolved.entity
---@param ... evolved.entity fragments
---@return any ... components
---@nodiscard
function registry.get(entity, ...)
    local chunk = entity.__chunk
    if chunk == nil then return end

    local components = chunk.__components
    if components == nil then return end

    local fragment_count = select('#', ...)
    if fragment_count == 0 then return end

    local index_in_chunk = entity.__index_in_chunk

    if fragment_count == 1 then
        local f1 = ...
        local cs1 = components[f1]
        return cs1 and cs1[index_in_chunk]
    end

    if fragment_count == 2 then
        local f1, f2 = ...
        local cs1, cs2 = components[f1], components[f2]
        return cs1 and cs1[index_in_chunk], cs2 and cs2[index_in_chunk]
    end

    if fragment_count == 3 then
        local f1, f2, f3 = ...
        local cs1, cs2, cs3 = components[f1], components[f2], components[f3]
        return cs1 and cs1[index_in_chunk], cs2 and cs2[index_in_chunk], cs3 and cs3[index_in_chunk]
    end

    do
        local f1, f2, f3 = ...
        local cs1, cs2, cs3 = components[f1], components[f2], components[f3]
        return cs1 and cs1[index_in_chunk], cs2 and cs2[index_in_chunk], cs3 and cs3[index_in_chunk],
            registry.get(entity, select(4, ...))
    end
end

---@param entity evolved.entity
---@param fragment evolved.entity
---@param default any
---@return any
---@nodiscard
function registry.get_or(entity, fragment, default)
    local chunk = entity.__chunk
    if chunk == nil then return default end

    local components = chunk.__components[fragment]
    if components == nil then return default end

    return components[entity.__index_in_chunk]
end

---@param entity evolved.entity
---@param fragment evolved.entity
---@return boolean
---@nodiscard
function registry.has(entity, fragment)
    local cur_chunk = entity.__chunk
    if cur_chunk == nil then return false end
    return __chunk_has_fragment(cur_chunk, fragment)
end

---@param entity evolved.entity
---@param ... evolved.entity fragments
---@return boolean
---@nodiscard
function registry.has_all(entity, ...)
    local cur_chunk = entity.__chunk
    if cur_chunk == nil then return select('#', ...) == 0 end
    return __chunk_has_all_fragments(cur_chunk, ...)
end

---@param entity evolved.entity
---@param ... evolved.entity fragments
---@return boolean
---@nodiscard
function registry.has_any(entity, ...)
    local cur_chunk = entity.__chunk
    if cur_chunk == nil then return false end
    return __chunk_has_any_fragments(cur_chunk, ...)
end

---@param entity evolved.entity
---@param fragment evolved.entity
---@param transform fun(any): any
---@return boolean is_applied
function registry.apply(entity, fragment, transform)
    error('not impl yet', 2)
end

---@param query evolved.query
---@param fragment evolved.entity
---@param transform fun(any): any
---@return integer applied_count
function registry.batch_apply(query, fragment, transform)
    error('not impl yet', 2)
end

---@param entity evolved.entity
---@param fragment evolved.entity
---@param component any
---@return boolean is_assigned
function registry.assign(entity, fragment, component)
    component = component == nil and true or component

    if not idpools.alive(__guids, entity.__guid) then
        return false
    end

    local chunk = entity.__chunk
    if chunk == nil then return false end

    local components = chunk.__components[fragment]
    if components == nil then return false end

    components[entity.__index_in_chunk] = component
    return true
end

---@param query evolved.query
---@param fragment evolved.entity
---@param component any
---@return integer assigned_count
function registry.batch_assign(query, fragment, component)
    error('not impl yet', 2)
end

---@param entity evolved.entity
---@param fragment evolved.entity
---@param component any
---@return boolean is_inserted
function registry.insert(entity, fragment, component)
    component = component == nil and true or component

    if not idpools.alive(__guids, entity.__guid) then
        return false
    end

    local old_chunk = entity.__chunk
    local new_chunk = __chunk_with_fragment(old_chunk, fragment)

    if old_chunk == new_chunk then
        return false
    end

    local old_index_in_chunk = entity.__index_in_chunk
    local new_index_in_chunk = #new_chunk.__entities + 1

    __changes = __changes + 1
    new_chunk.__changes = new_chunk.__changes + 1

    new_chunk.__entities[new_index_in_chunk] = entity
    new_chunk.__components[fragment][new_index_in_chunk] = component

    if old_chunk ~= nil then
        for old_f, old_cs in pairs(old_chunk.__components) do
            local new_cs = new_chunk.__components[old_f]
            new_cs[new_index_in_chunk] = old_cs[old_index_in_chunk]
        end

        __detach_entity(entity)
    end

    entity.__chunk = new_chunk
    entity.__index_in_chunk = new_index_in_chunk

    return true
end

---@param query evolved.query
---@param fragment evolved.entity
---@param component any
---@return integer inserted_count
function registry.batch_insert(query, fragment, component)
    error('not impl yet', 2)
end


---@param entity evolved.entity
---@param ... evolved.entity fragments
---@return boolean is_removed
function registry.remove(entity, ...)
    if not idpools.alive(__guids, entity.__guid) then
        return false
    end

    local old_chunk = entity.__chunk
    local new_chunk = __chunk_without_fragments(old_chunk, ...)

    if old_chunk == new_chunk then
        return false
    end

    if new_chunk == nil then
        __detach_entity(entity)
        return true
    end

    local old_index_in_chunk = entity.__index_in_chunk
    local new_index_in_chunk = #new_chunk.__entities + 1

    __changes = __changes + 1
    new_chunk.__changes = new_chunk.__changes + 1

    new_chunk.__entities[new_index_in_chunk] = entity

    if old_chunk ~= nil then
        for new_f, new_cs in pairs(new_chunk.__components) do
            local old_cs = old_chunk.__components[new_f]
            new_cs[new_index_in_chunk] = old_cs[old_index_in_chunk]
        end

        __detach_entity(entity)
    end

    entity.__chunk = new_chunk
    entity.__index_in_chunk = new_index_in_chunk

    return true
end

---@param query evolved.query
---@param ... evolved.entity fragments
---@return boolean removed_count
function registry.batch_remove(query, ...)
    error('not impl yet', 2)
end

---@param entity evolved.entity
---@return boolean is_detached
function registry.detach(entity)
    if not idpools.alive(__guids, entity.__guid) then
        return false
    end

    if entity.__chunk == nil then
        return false
    end

    __detach_entity(entity)
    return true
end

---@param query evolved.query
---@return boolean detached_count
function registry.batch_detach(query)
    error('not impl yet', 2)
end

---@param ... evolved.entity fragments
---@return evolved.query
---@nodiscard
function registry.query(...)
    local include_list = {}
    local include_set = {}

    for i = 1, select('#', ...) do
        local f = select(i, ...)
        if not include_set[f] then
            include_set[f] = true
            include_list[#include_list + 1] = f
        end
    end

    table.sort(include_list, function(a, b)
        return a.__guid < b.__guid
    end)

    ---@type evolved.query
    local query = {
        __changes = 0,
        __include_list = include_list,
        __exclude_list = {},
        __include_set = include_set,
        __exclude_set = {},
    }

    return setmetatable(query, evolved_query_mt)
end

---@param query evolved.query
---@param ... evolved.entity fragments
---@return evolved.query
function registry.include(query, ...)
    local include_list = query.__include_list
    local include_set = query.__include_set

    for i = 1, select('#', ...) do
        local f = select(i, ...)
        if not include_set[f] then
            include_set[f] = true
            include_list[#include_list + 1] = f
        end
    end

    query.__changes = query.__changes + 1

    table.sort(include_list, function(a, b)
        return a.__guid < b.__guid
    end)

    return query
end

---@param query evolved.query
---@param ... evolved.entity fragments
---@return evolved.query
function registry.exclude(query, ...)
    local exclude_list = query.__exclude_list
    local exclude_set = query.__exclude_set

    for i = 1, select('#', ...) do
        local f = select(i, ...)
        if not exclude_set[f] then
            exclude_set[f] = true
            exclude_list[#exclude_list + 1] = f
        end
    end

    query.__changes = query.__changes + 1

    table.sort(exclude_list, function(a, b)
        return a.__guid < b.__guid
    end)

    return query
end

---@param query evolved.query
---@return fun(): evolved.chunk?
---@nodiscard
function registry.execute(query)
    local include_list, exclude_list, exclude_set =
        query.__include_list, query.__exclude_list, query.__exclude_set

    if #include_list == 0 then
        return function() end
    end

    local main_fragment = include_list[#include_list]
    local main_fragment_chunks = __chunks[main_fragment]

    if main_fragment_chunks == nil or #main_fragment_chunks == 0 then
        return function() end
    end

    ---@type evolved.chunk[]
    local matched_chunk_stack = {}

    for _, main_fragment_chunk in ipairs(main_fragment_chunks) do
        if __chunk_has_all_fragment_list(main_fragment_chunk, include_list) then
            if not __chunk_has_any_fragment_list(main_fragment_chunk, exclude_list) then
                matched_chunk_stack[#matched_chunk_stack + 1] = main_fragment_chunk
            end
        end
    end

    local chunk_changes = __changes
    local query_changes = query.__changes

    return function()
        if chunk_changes ~= __changes then
            error('chunks have been modified during query execution', 2)
        end

        if query_changes ~= query.__changes then
            error('query has been modified during query execution', 2)
        end

        while #matched_chunk_stack > 0 do
            local matched_chunk = matched_chunk_stack[#matched_chunk_stack]
            matched_chunk_stack[#matched_chunk_stack] = nil

            for _, matched_chunk_child in ipairs(matched_chunk.__children) do
                if not exclude_set[matched_chunk_child.__fragment] then
                    matched_chunk_stack[#matched_chunk_stack + 1] = matched_chunk_child
                end
            end

            return matched_chunk
        end
    end
end

---@param fragment evolved.entity
---@param ... evolved.entity fragments
---@return evolved.chunk
---@nodiscard
function registry.chunk(fragment, ...)
    local fragments = { fragment, ... }

    table.sort(fragments, function(a, b)
        return a.__guid < b.__guid
    end)

    local chunk = __root_chunk(fragments[1])

    for i = 2, #fragments do
        chunk = __chunk_with_fragment(chunk, fragments[i])
    end

    return chunk
end

---@param chunk evolved.chunk
---@return evolved.entity[]
---@nodiscard
function registry.entities(chunk)
    return chunk.__entities
end

---@param chunk evolved.chunk
---@param ... evolved.entity fragments
---@return any[] ... components
---@nodiscard
function registry.components(chunk, ...)
    local components = chunk.__components

    local fragment_count = select('#', ...)
    if fragment_count == 0 then return end

    if fragment_count == 1 then
        local f1 = ...
        return components[f1]
    end

    if fragment_count == 2 then
        local f1, f2 = ...
        return components[f1], components[f2]
    end

    if fragment_count == 3 then
        local f1, f2, f3 = ...
        return components[f1], components[f2], components[f3]
    end

    do
        local f1, f2, f3 = ...
        return components[f1], components[f2], components[f3],
            registry.components(chunk, select(4, ...))
    end
end

---
---
---
---
---

function evolved_entity_mt:__tostring()
    local index, version = idpools.unpack(self.__guid)

    return string.format('[%d;%d]', index, version)
end

evolved_entity_mt.guid = registry.guid
evolved_entity_mt.alive = registry.alive
evolved_entity_mt.destroy = registry.destroy
evolved_entity_mt.del = registry.del
evolved_entity_mt.set = registry.set
evolved_entity_mt.get = registry.get
evolved_entity_mt.get_or = registry.get_or
evolved_entity_mt.has = registry.has
evolved_entity_mt.has_all = registry.has_all
evolved_entity_mt.has_any = registry.has_any
evolved_entity_mt.apply = registry.apply
evolved_entity_mt.assign = registry.assign
evolved_entity_mt.insert = registry.insert
evolved_entity_mt.remove = registry.remove
evolved_entity_mt.detach = registry.detach

---
---
---
---
---

function evolved_query_mt:__tostring()
    local str = ''

    for i, f in ipairs(self.__include_list) do
        str = string.format('%s%s%s', str, i > 1 and '+' or '', f)
    end

    for _, f in ipairs(self.__exclude_list) do
        str = string.format('%s-%s', str, f)
    end

    return string.format('(%s)', str)
end

evolved_query_mt.include = registry.include
evolved_query_mt.exclude = registry.exclude
evolved_query_mt.execute = registry.execute

---
---
---
---
---

function evolved_chunk_mt:__tostring()
    local str = ''

    local chunk_iter = self; while chunk_iter do
        str = string.format('%s%s', chunk_iter.__fragment, str)
        chunk_iter = chunk_iter.__parent
    end

    return string.format('{%s}', str)
end

evolved_chunk_mt.entities = registry.entities
evolved_chunk_mt.components = registry.components

---
---
---
---
---

return registry
