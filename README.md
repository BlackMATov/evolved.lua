# evolved.lua

## Module `idpools`

```
idpools.idpool -> (idpool)
idpools.pack -> integer -> integer -> (id)
idpools.unpack -> id -> (integer, integer)
idpools.alive -> idpool -> id -> (boolean)
idpools.acquire -> idpool -> (id)
idpools.release -> idpool -> id -> ()
```

### Instance `idpool`

```
idpool.pack -> integer -> integer -> (id)
idpool.unpack -> id -> (integer, integer)
idpool:alive -> id -> (boolean)
idpool:acquire -> (id)
idpool:release -> id -> ()
```

## Module `registry`

```
registry.entity -> (entity)
registry.guid -> entity -> (id)
registry.alive -> entity -> (boolean)
registry.del -> entity -> entity... -> (entity)
registry.set -> entity -> entity -> any -> (entity)
registry.get -> entity -> entity... -> (any...)
registry.get_or -> entity -> entity -> any -> (any)
registry.has -> entity -> entity -> (boolean)
registry.has_all -> entity -> entity... -> (boolean)
registry.has_any -> entity -> entity... -> (boolean)
registry.apply -> entity -> {any -> any} -> entity -> (boolean)
registry.batch_apply -> query -> {any -> any} -> entity -> (integer)
registry.assign -> entity -> entity -> any -> (boolean)
registry.batch_assign -> query -> entity -> any -> (integer)
registry.insert -> entity -> entity -> any -> (boolean)
registry.batch_insert -> query -> entity -> any -> (integer)
registry.remove -> entity -> entity... -> (boolean)
registry.batch_remove -> query -> entity... -> (integer)
registry.detach -> entity -> (boolean)
registry.batch_detach -> query -> (integer)
registry.destroy -> entity -> (boolean)
registry.batch_destroy -> query -> (integer)
registry.query -> entity... -> (query)
registry.include -> query -> entity... -> query
registry.exclude -> query -> entity... -> query
registry.execute -> query -> ({execution_state? -> chunk?}, execution_state?)
registry.chunk -> entity -> entity... -> (chunk)
registry.entities -> chunk -> entity -> (entity[])
registry.components -> chunk -> entity... -> (any[]...)
```

### Instance `entity`

```
entity:guid -> (id)
entity:alive -> (boolean)
entity:del -> entity... -> (entity)
entity:set -> entity -> any -> (entity)
entity:get -> entity... -> (any...)
entity:get_or -> entity -> any -> (any)
entity:has -> entity -> (boolean)
entity:has_all -> entity... -> (boolean)
entity:has_any -> entity... -> (boolean)
entity:apply -> {any -> any} -> entity -> (boolean)
entity:assign -> entity -> any -> (boolean)
entity:insert -> entity -> any -> (boolean)
entity:remove -> entity... -> (boolean)
entity:detach -> (entity)
entity:destroy -> (boolean)
```

### Instance `query`

```
query:include -> entity... -> query
query:exclude -> entity... -> query
query:execute -> ({execution_state? -> chunk?}, execution_state?)
query:batch_apply -> {any -> any} -> entity -> (integer)
query:batch_assign -> entity -> any -> (integer)
query:batch_insert -> entity -> any -> (integer)
query:batch_remove -> entity... -> (integer)
query:batch_detach -> (integer)
query:batch_destroy -> (integer)
```

### Instance `chunk`

```
chunk:entities -> entity -> (entity[])
chunk:components -> entity... -> (any[]...)
```

## Module `singles`

```
singles.single -> any -> (entity)
singles.set -> entity -> any -> (entity)
singles.get -> entity -> (any)
singles.has -> entity -> (boolean)
```

## Module `vectors`

```
vectors.vector2 -> number -> number -> (vector2)
vectors.is_vector2 -> any -> (boolean)
```

## [License (MIT)](./LICENSE.md)
