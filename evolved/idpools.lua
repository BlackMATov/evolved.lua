---@class evolved.idpools
local idpools = {}

---@class evolved.idpool
---@field package __acquired_ids integer[]
---@field package __available_index integer
local evolved_idpool_mt = {}
evolved_idpool_mt.__index = evolved_idpool_mt

---@return evolved.idpool
function idpools.idpool()
    ---@type evolved.idpool
    local idpool = {
        __acquired_ids = {},
        __available_index = 0,
    }
    return setmetatable(idpool, evolved_idpool_mt)
end

---@param id integer
---@return integer index
---@return integer version
function idpools.unpack_id(id)
    local index = id % 0x100000
    local version = (id - index) / 0x100000
    return index, version
end

---@param idpool evolved.idpool
---@return integer
---@nodiscard
function idpools.acquire_id(idpool)
    if idpool.__available_index ~= 0 then
        local index = idpool.__available_index
        local available_id = idpool.__acquired_ids[index]
        idpool.__available_index = available_id % 0x100000
        local version = available_id - idpool.__available_index
        local acquired_id = index + version
        idpool.__acquired_ids[index] = acquired_id
        return acquired_id
    end

    if #idpool.__acquired_ids == 0xFFFFF then
        error('id index overflow', 2)
    end

    local index = #idpool.__acquired_ids + 1
    local version = 0x100000
    local acquired_id = index + version
    idpool.__acquired_ids[index] = acquired_id
    return acquired_id
end

---@param idpool evolved.idpool
---@param id integer
function idpools.release_id(idpool, id)
    local index = id % 0x100000
    local version = id - index

    if idpool.__acquired_ids[index] ~= id then
        error('id is not acquired or already released', 2)
    end

    version = version == 0x7FF00000
        and 0x100000
        or version + 0x100000

    idpool.__acquired_ids[index] = idpool.__available_index + version
    idpool.__available_index = index
end

---@param idpool evolved.idpool
---@param id integer
---@return boolean
---@nodiscard
function idpools.is_id_alive(idpool, id)
    local index = id % 0x100000
    return idpool.__acquired_ids[index] == id
end

return idpools
