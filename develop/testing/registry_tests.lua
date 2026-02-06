local evo = require 'evolved'

do
    local id1 = evo.register("TestEntity1")
    assert(id1, "evolved.register should return an ID")

    local found_id1 = evo.find("TestEntity1")
    assert(found_id1 == id1, "evolved.find should return the registered ID")
end

do
    local id2, id3 = evo.register_many("TestEntity2", "TestEntity3")
    assert(id2 and id3, "register_many should return IDs")
    assert(evo.find("TestEntity2") == id2, "Find TestEntity2")
    assert(evo.find("TestEntity3") == id3, "Find TestEntity3")
end

do
    local id_initial = evo.register("TestCollision")
    local id_overwrite = evo.register("TestCollision", nil)

    assert(evo.find("TestCollision") == id_overwrite, "Name should point to new ID")
    assert(id_initial ~= id_overwrite, "IDs should be different")
end

do
    local id_remove = evo.register("TestRemoval")
    assert(evo.find("TestRemoval"), "Should exist initially")

    evo.remove(id_remove, evo.NAME)
    assert(evo.find("TestRemoval") == nil, "Should be nil after removing name component")
end

do
    local id_destroy = evo.register("TestDestruction")
    assert(evo.find("TestDestruction"), "Should exist initially")

    evo.destroy(id_destroy)
    assert(evo.find("TestDestruction") == nil, "Should be nil after destroying entity")
end

do
    local my_id = evo.id()
    local ret_id = evo.register("SpecificID", my_id)
    assert(ret_id == my_id, "Should return the passed ID")
    assert(evo.find("SpecificID") == my_id, "Should find by name")
end
