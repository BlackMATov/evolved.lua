---@diagnostic disable: unused-local

local evo = require 'evolved'

evo.debug_mode(true)

local fragments = {
    planet = evo.builder()
        :name('planet')
        :tag()
        :spawn(),
    spaceship = evo.builder()
        :name('spaceship')
        :tag()
        :spawn(),
}

local relations = {
    docked_to = evo.builder()
        :name('docked_to')
        :tag()
        :spawn(),
}

local planets = {
    mars = evo.builder()
        :name('Mars')
        :set(fragments.planet)
        :spawn(),
    venus = evo.builder()
        :name('Venus')
        :set(fragments.planet)
        :spawn(),
}

local spaceships = {
    falcon = evo.builder()
        :name('Millennium Falcon')
        :set(fragments.spaceship)
        :set(evo.pair(relations.docked_to, planets.mars))
        :spawn(),
    enterprise = evo.builder()
        :name('USS Enterprise')
        :set(fragments.spaceship)
        :set(evo.pair(relations.docked_to, planets.venus))
        :spawn(),
}

local queries = {
    all_docked_spaceships = evo.builder()
        :include(fragments.spaceship)
        :include(evo.pair(relations.docked_to, evo.ANY))
        :spawn(),
    docked_spaceships_to_mars = evo.builder()
        :include(fragments.spaceship)
        :include(evo.pair(relations.docked_to, planets.mars))
        :spawn(),

}

print '-= | All Docked Spaceships | =-'

for chunk, entity_list, entity_count in evo.execute(queries.all_docked_spaceships) do
    for i = 1, entity_count do
        local entity = entity_list[i]
        local planet = evo.secondary(entity, relations.docked_to)
        print(string.format('%s is docked to %s', evo.name(entity), evo.name(planet)))
    end
end

print '-= | Docked Spaceships to Mars | =-'

for chunk, entity_list, entity_count in evo.execute(queries.docked_spaceships_to_mars) do
    for i = 1, entity_count do
        local entity = entity_list[i]
        local planet = evo.secondary(entity, relations.docked_to)
        print(string.format('%s is docked to %s', evo.name(entity), evo.name(planet)))
    end
end
