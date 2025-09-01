local evo = require 'evolved'

evo.debug_mode(true)

---
---
---
---
---

for _ = 1, 1000 do
    local initial_primary = math.random(1, 2 ^ 20 - 1)
    local initial_secondary = math.random(1, 2 ^ 20 - 1)

    local packed_id = evo.pack(initial_primary, initial_secondary)
    local unpacked_primary, unpacked_secondary, unpacked_options = evo.unpack(packed_id)

    assert(initial_primary == unpacked_primary)
    assert(initial_secondary == unpacked_secondary)
    assert(0 == unpacked_options)
end
