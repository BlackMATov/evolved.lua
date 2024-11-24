local compat = require 'evolved.compat'
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
local __queries = {} ---@type table<evolved.entity, evolved.query[]>

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
---@field package __fragments evolved.entity[]
local evolved_query_mt = {}
evolved_query_mt.__index = evolved_query_mt

---@class evolved.chunk
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

---@param query evolved.query
local function __on_new_query(query)
    local main_fragment = query.__fragments[#query.__fragments]
    local main_fragment_queries = __queries[main_fragment] or {}
    main_fragment_queries[#main_fragment_queries + 1] = query
    __queries[main_fragment] = main_fragment_queries
end

---@param chunk evolved.chunk
local function __on_new_chunk(chunk)
    local main_fragment = chunk.__fragment
    local main_fragment_chunks = __chunks[main_fragment] or {}
    main_fragment_chunks[#main_fragment_chunks + 1] = chunk
    __chunks[main_fragment] = main_fragment_chunks
end

---
---
---
---
---

---@param entity evolved.entity
local function __detach_entity(entity)
    local chunk = assert(entity.__chunk)
    local index_in_chunk = entity.__index_in_chunk

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

    __on_new_chunk(root_chunk)
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
        chunk.__with_fragment_cache[fragment] = sibling_chunk
        sibling_chunk.__without_fragment_cache[fragment] = chunk
        return sibling_chunk
    end

    ---@type evolved.chunk
    local child_chunk = {
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
        table.insert(chunk.__children, child_chunk)
        chunk.__with_fragment_cache[fragment] = child_chunk
        child_chunk.__without_fragment_cache[fragment] = chunk
    end

    __on_new_chunk(child_chunk)
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
        chunk.__without_fragment_cache[fragment] = sibling_chunk
        sibling_chunk.__with_fragment_cache[fragment] = chunk
        return sibling_chunk
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
function registry.is_alive(entity)
    return idpools.is_alive(__guids, entity.__guid)
end

---@param entity evolved.entity
function registry.destroy(entity)
    if not registry.is_alive(entity) then
        error(string.format('entity %s is not alive', entity), 2)
    end

    if entity.__chunk ~= nil then
        __detach_entity(entity)
    end

    idpools.release(__guids, entity.__guid)
end

---@param entity evolved.entity
---@param fragment evolved.entity
---@param default any
---@return any
---@nodiscard
function registry.get(entity, fragment, default)
    local chunk_components = entity.__chunk and entity.__chunk.__components[fragment]

    if chunk_components == nil then
        return default
    end

    return chunk_components[entity.__index_in_chunk]
end

---@param entity evolved.entity
---@param fragment evolved.entity
---@return boolean
---@nodiscard
function registry.has(entity, fragment)
    if entity.__chunk == nil then return false end
    return __chunk_has_fragment(entity.__chunk, fragment)
end

---@param entity evolved.entity
---@param ... evolved.entity fragments
---@return boolean
---@nodiscard
function registry.has_all(entity, ...)
    if entity.__chunk == nil then return select('#', ...) == 0 end
    return __chunk_has_all_fragments(entity.__chunk, ...)
end

---@param entity evolved.entity
---@param ... evolved.entity fragments
---@return boolean
---@nodiscard
function registry.has_any(entity, ...)
    if entity.__chunk == nil then return false end
    return __chunk_has_any_fragments(entity.__chunk, ...)
end

---@param entity evolved.entity
---@param fragment evolved.entity
---@param component any
---@return boolean is_assigned
function registry.assign(entity, fragment, component)
    component = component == nil and true or component

    local chunk_components = entity.__chunk and entity.__chunk.__components[fragment]

    if chunk_components == nil then
        return false
    end

    chunk_components[entity.__index_in_chunk] = component
    return true
end

---@param entity evolved.entity
---@param fragment evolved.entity
---@param component any
---@return boolean is_inserted
function registry.insert(entity, fragment, component)
    component = component == nil and true or component

    local old_chunk = entity.__chunk
    local new_chunk = __chunk_with_fragment(old_chunk, fragment)

    if old_chunk == new_chunk then
        local chunk_components = new_chunk.__components[fragment]
        chunk_components[entity.__index_in_chunk] = component
        return false
    end

    local old_index_in_chunk = entity.__index_in_chunk
    local new_index_in_chunk = #new_chunk.__entities + 1

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

---@param entity evolved.entity
---@param ... evolved.entity fragments
---@return boolean is_removed
function registry.remove(entity, ...)
    local old_chunk = entity.__chunk
    local new_chunk = entity.__chunk

    for i = 1, select('#', ...) do
        local fragment = select(i, ...)
        new_chunk = __chunk_without_fragment(new_chunk, fragment)
    end

    if old_chunk == new_chunk then
        return false
    end

    if new_chunk == nil then
        __detach_entity(entity)
        return true
    end

    local old_index_in_chunk = entity.__index_in_chunk
    local new_index_in_chunk = #new_chunk.__entities + 1

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

---@param fragment evolved.entity
---@param ... evolved.entity
---@return evolved.query
---@nodiscard
function registry.query(fragment, ...)
    local fragments = { fragment, ... }

    table.sort(fragments, function(a, b)
        return a.__guid < b.__guid
    end)

    ---@type evolved.query
    local query = {
        __fragments = fragments,
    }

    setmetatable(query, evolved_query_mt)

    __on_new_query(query)
    return query
end

---@param query evolved.query
---@return fun(): evolved.chunk?
---@nodiscard
function registry.execute(query)
    local main_fragment = query.__fragments[#query.__fragments]
    local main_fragment_chunks = __chunks[main_fragment] or {}

    ---@type evolved.chunk[]
    local matched_chunk_stack = {}

    for _, main_fragment_chunk in ipairs(main_fragment_chunks) do
        if __chunk_has_all_fragments(main_fragment_chunk, compat.unpack(query.__fragments)) then
            matched_chunk_stack[#matched_chunk_stack + 1] = main_fragment_chunk
        end
    end

    return function()
        while #matched_chunk_stack > 0 do
            local matched_chunk = matched_chunk_stack[#matched_chunk_stack]
            matched_chunk_stack[#matched_chunk_stack] = nil

            for _, matched_chunk_child in ipairs(matched_chunk.__children) do
                matched_chunk_stack[#matched_chunk_stack + 1] = matched_chunk_child
            end

            return matched_chunk
        end
    end
end

---@param fragment evolved.entity
---@param ... evolved.entity
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
---@param fragment evolved.entity
---@return any[]
---@nodiscard
function registry.components(chunk, fragment)
    local components = chunk.__components[fragment]

    if components == nil then
        error(string.format('chunk %s does not have fragment %s', chunk, fragment), 2)
    end

    return components
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
evolved_entity_mt.is_alive = registry.is_alive
evolved_entity_mt.destroy = registry.destroy
evolved_entity_mt.get = registry.get
evolved_entity_mt.has = registry.has
evolved_entity_mt.has_all = registry.has_all
evolved_entity_mt.has_any = registry.has_any
evolved_entity_mt.assign = registry.assign
evolved_entity_mt.insert = registry.insert
evolved_entity_mt.remove = registry.remove

function evolved_query_mt:__tostring()
    local fragment_ids = ''

    for _, fragment in ipairs(self.__fragments) do
        fragment_ids = string.format('%s%s', fragment_ids, fragment)
    end

    return string.format('(%s)', fragment_ids)
end

evolved_query_mt.execute = registry.execute

function evolved_chunk_mt:__tostring()
    local fragment_ids = ''

    local chunk_iter = self; while chunk_iter do
        fragment_ids = string.format('%s%s', chunk_iter.__fragment, fragment_ids)
        chunk_iter = chunk_iter.__parent
    end

    return string.format('{%s}', fragment_ids)
end

evolved_chunk_mt.entities = registry.entities
evolved_chunk_mt.components = registry.components

---
---
---
---
---

return registry
