local evo = require 'evolved'

evo.debug_mode(true)

do
    local f1, f2 = evo.id(2)

    local q = evo.builder():include(f1, f2):build()
    local e = evo.spawn({ [f1] = true, [f2] = true })

    -- the query caches the chunk of the entity
    for _ in evo.execute(q) do end

    local weak_chunks = setmetatable({}, { __mode = 'v' })
    weak_chunks[1] = evo.chunk(f1, f2)

    -- the chunk becomes empty and is removed by the garbage collector
    evo.clear(e)
    evo.collect_garbage()

    collectgarbage('collect')

    -- nothing should keep a reference to the removed chunk
    assert(weak_chunks[1] == nil)
end
