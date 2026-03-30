local evo = require 'evolved'

evo.debug_mode(true)

do
    local f1, f2 = evo.id(2)

    local insert_hook_calls = 0

    if f1 < f2 then
        evo.set(f1, evo.ON_INSERT, function()
            insert_hook_calls = insert_hook_calls + 1
        end)
    else
        evo.set(f2, evo.ON_INSERT, function()
            insert_hook_calls = insert_hook_calls + 1
        end)
    end

    do
        insert_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        assert(insert_hook_calls == 1)
        evo.destroy(e)
    end

    evo.remove(f1, evo.ON_INSERT)
    evo.remove(f2, evo.ON_INSERT)

    do
        insert_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        assert(insert_hook_calls == 0)
        evo.destroy(e)
    end

    if f1 < f2 then
        evo.set(f1, evo.ON_INSERT, function()
            insert_hook_calls = insert_hook_calls + 2
        end)
    else
        evo.set(f2, evo.ON_INSERT, function()
            insert_hook_calls = insert_hook_calls + 2
        end)
    end

    do
        insert_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        assert(insert_hook_calls == 2)
        evo.destroy(e)
    end
end

do
    local f1, f2 = evo.id(2)

    local insert_hook_calls = 0

    if f1 > f2 then
        evo.set(f1, evo.ON_INSERT, function()
            insert_hook_calls = insert_hook_calls + 1
        end)
    else
        evo.set(f2, evo.ON_INSERT, function()
            insert_hook_calls = insert_hook_calls + 1
        end)
    end

    do
        insert_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        assert(insert_hook_calls == 1)
        evo.destroy(e)
    end

    evo.remove(f1, evo.ON_INSERT)
    evo.remove(f2, evo.ON_INSERT)

    do
        insert_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        assert(insert_hook_calls == 0)
        evo.destroy(e)
    end

    if f1 > f2 then
        evo.set(f1, evo.ON_INSERT, function()
            insert_hook_calls = insert_hook_calls + 2
        end)
    else
        evo.set(f2, evo.ON_INSERT, function()
            insert_hook_calls = insert_hook_calls + 2
        end)
    end

    do
        insert_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        assert(insert_hook_calls == 2)
        evo.destroy(e)
    end
end

do
    local f1, f2 = evo.id(2)

    local remove_hook_calls = 0

    if f1 < f2 then
        evo.set(f1, evo.ON_REMOVE, function()
            remove_hook_calls = remove_hook_calls + 1
        end)
    else
        evo.set(f2, evo.ON_REMOVE, function()
            remove_hook_calls = remove_hook_calls + 1
        end)
    end

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.destroy(e)
        assert(remove_hook_calls == 1)
    end

    evo.remove(f1, evo.ON_REMOVE)
    evo.remove(f2, evo.ON_REMOVE)

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.destroy(e)
        assert(remove_hook_calls == 0)
    end

    if f1 < f2 then
        evo.set(f1, evo.ON_REMOVE, function()
            remove_hook_calls = remove_hook_calls + 2
        end)
    else
        evo.set(f2, evo.ON_REMOVE, function()
            remove_hook_calls = remove_hook_calls + 2
        end)
    end

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.destroy(e)
        assert(remove_hook_calls == 2)
    end
end

do
    local f1, f2 = evo.id(2)

    local remove_hook_calls = 0

    if f1 > f2 then
        evo.set(f1, evo.ON_REMOVE, function()
            remove_hook_calls = remove_hook_calls + 1
        end)
    else
        evo.set(f2, evo.ON_REMOVE, function()
            remove_hook_calls = remove_hook_calls + 1
        end)
    end

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.destroy(e)
        assert(remove_hook_calls == 1)
    end

    evo.remove(f1, evo.ON_REMOVE)
    evo.remove(f2, evo.ON_REMOVE)

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.destroy(e)
        assert(remove_hook_calls == 0)
    end

    if f1 > f2 then
        evo.set(f1, evo.ON_REMOVE, function()
            remove_hook_calls = remove_hook_calls + 2
        end)
    else
        evo.set(f2, evo.ON_REMOVE, function()
            remove_hook_calls = remove_hook_calls + 2
        end)
    end

    do
        remove_hook_calls = 0
        local e = evo.spawn { [f1] = 42, [f2] = 'hello' }
        evo.destroy(e)
        assert(remove_hook_calls == 2)
    end
end
