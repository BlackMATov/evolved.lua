local record Evolved
    interface Id end

    type Entity = Id
    type Fragment = Id
    type Query = Id
    type System = Id

    interface EachState end
    interface ExecuteState end

    type EachIterator = function(state?: EachState): Fragment, any
    type ExecuteIterator = function(state?: ExecuteState): Chunk, { Entity }, integer

    interface Chunk
        alive: function(self: Chunk): boolean
        empty: function(self: Chunk): boolean

        has: function(self: Chunk, fragment: Fragment): boolean
        has_all: function(self: Chunk, ...: Fragment): boolean
        has_any: function(self: Chunk, ...: Fragment): boolean

        entities: function(self: Chunk): { Entity }, integer
        fragments: function(self: Chunk): { Fragment }, integer

        components: function(self: Chunk)
        components: function<C1>(self: Chunk, f1: Fragment): { C1 }
        components: function<C1, C2>(self: Chunk, f1: Fragment, f2: Fragment): { C1 }, { C2 }
        components: function<C1, C2, C3>(self: Chunk, f1: Fragment, f2: Fragment, f3: Fragment): { C1 }, { C2 }, { C3 }
        components: function<C1, C2, C3, C4>(self: Chunk, f1: Fragment, f2: Fragment, f3: Fragment, f4: Fragment): { C1 }, { C2 }, { C3 }, { C4 }
    end

    interface Builder
        build: function(self: Builder, prefab?: Entity): Entity
        multi_build: function(self: Builder, entity_count: integer, prefab?: Entity): { Entity }, integer

        spawn: function(self: Builder): Entity
        multi_spawn: function(self: Builder, entity_count: integer): { Entity }, integer

        clone: function(self: Builder, prefab: Entity): Entity
        multi_clone: function(self: Builder, entity_count: integer, prefab: Entity): { Entity }, integer

        has: function(self: Builder, fragment: Fragment): boolean
        has_all: function(self: Builder, ...: Fragment): boolean
        has_any: function(self: Builder, ...: Fragment): boolean

        get: function(self: Builder)
        get: function<C1>(self: Builder, f1: Fragment): C1 | nil
        get: function<C1, C2>(self: Builder, f1: Fragment, f2: Fragment): C1 | nil, C2 | nil
        get: function<C1, C2, C3>(self: Builder, f1: Fragment, f2: Fragment, f3: Fragment): C1 | nil, C2 | nil, C3 | nil
        get: function<C1, C2, C3, C4>(self: Builder, f1: Fragment, f2: Fragment, f3: Fragment, f4: Fragment): C1 | nil, C2 | nil, C3 | nil, C4 | nil

        set: function<Component>(self: Builder, fragment: Fragment, component?: Component): Builder
        remove: function(self: Builder, ...: Fragment): Builder
        clear: function(self: Builder): Builder

        tag: function(self: Builder): Builder
        name: function(self: Builder, name: string): Builder

        unique: function(self: Builder): Builder
        explicit: function(self: Builder): Builder
        internal: function(self: Builder): Builder

        default: function<Component>(self: Builder, default: Component): Builder
        duplicate: function<Component>(self: Builder, duplicate: function(Component): Component): Builder

        realloc: function<Component>(self: Builder, realloc: function({ Component } | nil, integer, integer): { Component } | nil): Builder
        compmove: function<Component>(self: Builder, compmove: function({ Component }, integer, integer, integer, { Component })): Builder

        prefab: function(self: Builder): Builder
        disabled: function(self: Builder): Builder

        include: function(self: Builder, ...: Fragment): Builder
        exclude: function(self: Builder, ...: Fragment): Builder
        variant: function(self: Builder, ...: Fragment): Builder
        require: function(self: Builder, ...: Fragment): Builder

        on_set: function<Component>(self: Builder, on_set: function(Entity, Fragment, ? Component, ? Component)): Builder
        on_assign: function<Component>(self: Builder, on_assign: function(Entity, Fragment, ? Component, ? Component)): Builder
        on_insert: function<Component>(self: Builder, on_insert: function(Entity, Fragment, ? Component)): Builder
        on_remove: function<Component>(self: Builder, on_remove: function(Entity, Fragment, ? Component)): Builder

        group: function(self: Builder, group: System): Builder

        query: function(self: Builder, query: Query): Builder
        execute: function(self: Builder, execute: function(Chunk, {Entity}, integer, ...: any)): Builder

        prologue: function(self: Builder, prologue: function(...: any)): Builder
        epilogue: function(self: Builder, epilogue: function(...: any)): Builder

        destruction_policy: function(self: Builder, destruction_policy: Id): Builder
    end

    TAG: Fragment
    NAME: Fragment

    UNIQUE: Fragment
    EXPLICIT: Fragment
    INTERNAL: Fragment

    DEFAULT: Fragment
    DUPLICATE: Fragment

    REALLOC: Fragment
    COMPMOVE: Fragment

    PREFAB: Fragment
    DISABLED: Fragment

    INCLUDES: Fragment
    EXCLUDES: Fragment
    VARIANTS: Fragment
    REQUIRES: Fragment

    ON_SET: Fragment
    ON_ASSIGN: Fragment
    ON_INSERT: Fragment
    ON_REMOVE: Fragment

    GROUP: Fragment

    QUERY: Fragment
    EXECUTE: Fragment
    PROLOGUE: Fragment
    EPILOGUE: Fragment

    DESTRUCTION_POLICY: Fragment
    DESTRUCTION_POLICY_DESTROY_ENTITY: Id
    DESTRUCTION_POLICY_REMOVE_FRAGMENT: Id

    id: function(count?: integer): Id...
    name: function(...: Id): string...

    pack: function(primary: integer, secondary: integer): Id
    unpack: function(id: Id): integer, integer

    defer: function(): boolean
    depth: function(): integer
    commit: function(): boolean
    cancel: function(): boolean

    spawn: function(components?: { Fragment: any }): Entity
    multi_spawn: function(entity_count: integer, components?: { Fragment: any }): { Entity }, integer

    clone: function(prefab: Entity, components?: { Fragment: any }): Entity
    multi_clone: function(entity_count: integer, prefab: Entity, components?: { Fragment: any }): { Entity }, integer

    alive: function(entity: Entity): boolean
    alive_all: function(...: Entity): boolean
    alive_any: function(...: Entity): boolean

    empty: function(entity: Entity): boolean
    empty_all: function(...: Entity): boolean
    empty_any: function(...: Entity): boolean

    has: function(entity: Entity, fragment: Fragment): boolean
    has_all: function(entity: Entity, ...: Fragment): boolean
    has_any: function(entity: Entity, ...: Fragment): boolean

    get: function(entity: Entity)
    get: function<C1>(entity: Entity, f1: Fragment): C1 | nil
    get: function<C1, C2>(entity: Entity, f1: Fragment, f2: Fragment): C1 | nil, C2 | nil
    get: function<C1, C2, C3>(entity: Entity, f1: Fragment, f2: Fragment, f3: Fragment): C1 | nil, C2 | nil, C3 | nil
    get: function<C1, C2, C3, C4>(entity: Entity, f1: Fragment, f2: Fragment, f3: Fragment, f4: Fragment): C1 | nil, C2 | nil, C3 | nil, C4 | nil

    set: function<Component>(entity: Entity, fragment: Fragment, component?: Component)
    remove: function(entity: Entity, ...: Fragment)
    clear: function(...: Entity)
    destroy: function(...: Entity)

    batch_set: function<Component>(query: Query, fragment: Fragment, component?: Component)
    batch_remove: function(query: Query, ...: Fragment)
    batch_clear: function(...: Query)
    batch_destroy: function(...: Query)

    each: function(entity: Entity): EachIterator, EachState | nil
    execute: function(query: Query): ExecuteIterator, ExecuteState | nil

    locate: function(entity: Entity): Chunk | nil, integer

    process: function(...: System)
    process_with: function(system: System, ...: any)

    debug_mode: function(yesno: boolean)
    collect_garbage: function()

    chunk: function(fragment: Fragment, ...: Fragment): Chunk, { Entity }, integer
    builder: function(): Builder
end

return Evolved
