local evo = require 'evolved'

evo.debug_mode(true)

do
    assert(evo.name(evo.TAG) == '__TAG')
    assert(evo.lookup('__TAG') == evo.TAG)
end

do
    local ALL_INTERNAL_FRAGMENTS = evo.builder()
        :include(evo.INTERNAL)
        :build()

    for _, entity_list, entity_count in evo.execute(ALL_INTERNAL_FRAGMENTS) do
        for i = 1, entity_count do
            local entity = entity_list[i]
            assert(type(evo.get(entity, evo.NAME)) == 'string')
            assert(evo.get(entity, evo.NAME):sub(1, 2) == '__')
            assert(evo.name(entity) == evo.get(entity, evo.NAME))
            assert(evo.lookup(evo.name(entity)) == entity)
        end
    end
end
