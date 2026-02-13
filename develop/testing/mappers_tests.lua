local evo = require 'evolved'

evo.debug_mode(true)

do
    local f1, f2 = evo.id(2)

    local e1 = evo.spawn({ [f1] = 1, [f2] = 2 }, function(c, p)
        local f1s, f2s = c:components(f1, f2)
        f1s[p] = f1s[p] * 2
        f2s[p] = f2s[p] * 3
    end)

    local e2 = evo.spawn({ [f1] = 1, [f2] = 2 }, function(c, p)
        local f1s, f2s = c:components(f1, f2)
        f1s[p] = f1s[p] + 10
        f2s[p] = f2s[p] + 20
    end)

    assert(evo.has(e1, f1) and evo.get(e1, f1) == 2)
    assert(evo.has(e1, f2) and evo.get(e1, f2) == 6)
    assert(evo.has(e2, f1) and evo.get(e2, f1) == 11)
    assert(evo.has(e2, f2) and evo.get(e2, f2) == 22)

    local e11 = evo.clone(e1, nil, function(c, p)
        local f1s, f2s = c:components(f1, f2)
        f1s[p] = f1s[p] * 3
        f2s[p] = f2s[p] * 4
    end)

    local e22 = evo.clone(e2, nil, function(c, p)
        local f1s, f2s = c:components(f1, f2)
        f1s[p] = f1s[p] + 30
        f2s[p] = f2s[p] + 40
    end)

    assert(evo.has(e11, f1) and evo.get(e11, f1) == 6)
    assert(evo.has(e11, f2) and evo.get(e11, f2) == 24)
    assert(evo.has(e22, f1) and evo.get(e22, f1) == 41)
    assert(evo.has(e22, f2) and evo.get(e22, f2) == 62)
end

do
    local f1, f2 = evo.id(2)

    evo.defer()

    local e1 = evo.spawn({ [f1] = 1, [f2] = 2 }, function(c, p)
        local f1s, f2s = c:components(f1, f2)
        f1s[p] = f1s[p] * 2
        f2s[p] = f2s[p] * 3
    end)

    local e2 = evo.spawn({ [f1] = 1, [f2] = 2 }, function(c, p)
        local f1s, f2s = c:components(f1, f2)
        f1s[p] = f1s[p] + 10
        f2s[p] = f2s[p] + 20
    end)

    assert(not evo.has(e1, f1) and evo.get(e1, f1) == nil)
    assert(not evo.has(e1, f2) and evo.get(e1, f2) == nil)
    assert(not evo.has(e2, f1) and evo.get(e2, f1) == nil)
    assert(not evo.has(e2, f2) and evo.get(e2, f2) == nil)

    evo.commit()

    assert(evo.has(e1, f1) and evo.get(e1, f1) == 2)
    assert(evo.has(e1, f2) and evo.get(e1, f2) == 6)
    assert(evo.has(e2, f1) and evo.get(e2, f1) == 11)
    assert(evo.has(e2, f2) and evo.get(e2, f2) == 22)

    evo.defer()

    local e11 = evo.clone(e1, nil, function(c, p)
        local f1s, f2s = c:components(f1, f2)
        f1s[p] = f1s[p] * 3
        f2s[p] = f2s[p] * 4
    end)

    local e22 = evo.clone(e2, nil, function(c, p)
        local f1s, f2s = c:components(f1, f2)
        f1s[p] = f1s[p] + 30
        f2s[p] = f2s[p] + 40
    end)

    assert(not evo.has(e11, f1) and evo.get(e11, f1) == nil)
    assert(not evo.has(e11, f2) and evo.get(e11, f2) == nil)
    assert(not evo.has(e22, f1) and evo.get(e22, f1) == nil)
    assert(not evo.has(e22, f2) and evo.get(e22, f2) == nil)

    evo.commit()

    assert(evo.has(e11, f1) and evo.get(e11, f1) == 6)
    assert(evo.has(e11, f2) and evo.get(e11, f2) == 24)
    assert(evo.has(e22, f1) and evo.get(e22, f1) == 41)
    assert(evo.has(e22, f2) and evo.get(e22, f2) == 62)
end

do
    local f1, f2 = evo.id(2)

    local es, ec = evo.multi_spawn(10, { [f1] = 1, [f2] = 2 }, function(c, b, e)
        local f1s, f2s = c:components(f1, f2)
        for p = b, e do
            f1s[p] = f1s[p] * 2
            f2s[p] = f2s[p] * 3
        end
    end)

    for i = 1, ec do
        local e = es[i]
        assert(evo.has(e, f1) and evo.get(e, f1) == 2)
        assert(evo.has(e, f2) and evo.get(e, f2) == 6)
    end

    local es2, ec2 = evo.multi_clone(10, es[1], nil, function(c, b, e)
        local f1s, f2s = c:components(f1, f2)
        for p = b, e do
            f1s[p] = f1s[p] + 10
            f2s[p] = f2s[p] + 20
        end
    end)

    for i = 1, ec2 do
        local e = es2[i]
        assert(evo.has(e, f1) and evo.get(e, f1) == 12)
        assert(evo.has(e, f2) and evo.get(e, f2) == 26)
    end
end

do
    local f1, f2 = evo.id(2)

    evo.defer()

    local es, ec = evo.multi_spawn(10, { [f1] = 1, [f2] = 2 }, function(c, b, e)
        local f1s, f2s = c:components(f1, f2)
        for p = b, e do
            f1s[p] = f1s[p] * 2
            f2s[p] = f2s[p] * 3
        end
    end)

    for i = 1, ec do
        local e = es[i]
        assert(not evo.has(e, f1) and evo.get(e, f1) == nil)
        assert(not evo.has(e, f2) and evo.get(e, f2) == nil)
    end

    evo.commit()

    for i = 1, ec do
        local e = es[i]
        assert(evo.has(e, f1) and evo.get(e, f1) == 2)
        assert(evo.has(e, f2) and evo.get(e, f2) == 6)
    end

    evo.defer()

    local es2, ec2 = evo.multi_clone(10, es[1], nil, function(c, b, e)
        local f1s, f2s = c:components(f1, f2)
        for p = b, e do
            f1s[p] = f1s[p] + 10
            f2s[p] = f2s[p] + 20
        end
    end)

    for i = 1, ec2 do
        local e = es2[i]
        assert(not evo.has(e, f1) and evo.get(e, f1) == nil)
        assert(not evo.has(e, f2) and evo.get(e, f2) == nil)
    end

    evo.commit()

    for i = 1, ec2 do
        local e = es2[i]
        assert(evo.has(e, f1) and evo.get(e, f1) == 12)
        assert(evo.has(e, f2) and evo.get(e, f2) == 26)
    end
end

do
    local f1, f2 = evo.id(2)

    local e1 = evo.builder():set(f1, 1):set(f2, 2):build(nil, function(c, p)
        local f1s, f2s = c:components(f1, f2)
        f1s[p] = f1s[p] * 2
        f2s[p] = f2s[p] * 3
    end)

    assert(evo.has(e1, f1) and evo.get(e1, f1) == 2)
    assert(evo.has(e1, f2) and evo.get(e1, f2) == 6)

    local e2 = evo.builder():build(e1, function(c, p)
        local f1s, f2s = c:components(f1, f2)
        f1s[p] = f1s[p] + 10
        f2s[p] = f2s[p] + 20
    end)

    assert(evo.has(e2, f1) and evo.get(e2, f1) == 12)
    assert(evo.has(e2, f2) and evo.get(e2, f2) == 26)

    local e3 = evo.builder():set(f2, 3):build(e1, function(c, p)
        local f1s, f2s = c:components(f1, f2)
        f1s[p] = f1s[p] + 10
        f2s[p] = f2s[p] + 20
    end)

    assert(evo.has(e3, f1) and evo.get(e3, f1) == 12)
    assert(evo.has(e3, f2) and evo.get(e3, f2) == 23)
end

do
    local f1, f2 = evo.id(2)

    local es, ec = evo.builder():set(f1, 1):set(f2, 2):multi_build(10, nil, function(c, b, e)
        local f1s, f2s = c:components(f1, f2)
        for p = b, e do
            f1s[p] = f1s[p] * 2
            f2s[p] = f2s[p] * 3
        end
    end)

    for i = 1, ec do
        local e = es[i]
        assert(evo.has(e, f1) and evo.get(e, f1) == 2)
        assert(evo.has(e, f2) and evo.get(e, f2) == 6)
    end

    local es2, ec2 = evo.builder():multi_build(10, es[1], function(c, b, e)
        local f1s, f2s = c:components(f1, f2)
        for p = b, e do
            f1s[p] = f1s[p] + 10
            f2s[p] = f2s[p] + 20
        end
    end)

    for i = 1, ec2 do
        local e = es2[i]
        assert(evo.has(e, f1) and evo.get(e, f1) == 12)
        assert(evo.has(e, f2) and evo.get(e, f2) == 26)
    end
end
