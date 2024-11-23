# evolved.lua

## API Reference

### Module `registry`

```
registry.entity -> (entity)
registry.is_alive -> entity -> (boolean)
registry.destroy -> entity -> ()
registry.get -> entity -> entity -> (any)
registry.get_or -> entity -> entity -> any -> (any)
registry.has -> entity -> entity -> (boolean)
registry.has_all -> entity -> entity -> entity... -> (boolean)
registry.has_any -> entity -> entity -> entity... -> (boolean)
registry.assign -> entity -> entity -> any -> ()
registry.insert -> entity -> entity -> any -> ()
registry.remove -> entity -> entity -> ()
registry.query -> entity -> entity... -> (query)
registry.execute -> query -> (() -> (chunk?))
registry.chunk -> entity -> entity... -> (chunk)
```

### Module `singles`

```
singles.single -> any -> (entity)
singles.get -> entity -> (any)
singles.has -> entity -> (boolean)
singles.assign -> entity -> any -> ()
```

### Module `vectors`

```
vectors.vector2 -> number -> number -> (vector2)
vectors.is_vector2 -> any -> (boolean)
```

## [License (MIT)](./LICENSE.md)
