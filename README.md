# evolved.lua

> Evolved ECS (Entity-Component-System) for Lua

[![lua5.1][badge.lua5.1]][lua5.1]
[![lua5.4][badge.lua5.4]][lua5.4]
[![luajit][badge.luajit]][luajit]
[![license][badge.license]][license]

[badge.lua5.1]: https://img.shields.io/github/actions/workflow/status/BlackMATov/evolved.lua/.github/workflows/lua5.1.yml?label=Lua%205.1
[badge.lua5.4]: https://img.shields.io/github/actions/workflow/status/BlackMATov/evolved.lua/.github/workflows/lua5.4.yml?label=Lua%205.4
[badge.luajit]: https://img.shields.io/github/actions/workflow/status/BlackMATov/evolved.lua/.github/workflows/luajit.yml?label=LuaJIT
[badge.license]: https://img.shields.io/badge/license-MIT-blue

[lua5.1]: https://github.com/BlackMATov/evolved.lua/actions?query=workflow%3Alua5.1
[lua5.4]: https://github.com/BlackMATov/evolved.lua/actions?query=workflow%3Alua5.4
[luajit]: https://github.com/BlackMATov/evolved.lua/actions?query=workflow%3Aluajit
[license]: https://en.wikipedia.org/wiki/MIT_License

[evolved]: https://github.com/BlackMATov/evolved.lua

- [Introduction](#introduction)
  - [Performance](#performance)
  - [Simplicity](#simplicity)
  - [Flexibility](#flexibility)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Overview](#overview)
  - [Identifiers](#identifiers)
  - [Entities, Fragments, and Components](#entities-fragments-and-components)
    - [Traits](#traits)
    - [Singletons](#singletons)
  - [Chunks](#chunks)
  - [Structural Changes](#structural-changes)
    - [Spawning Entities](#spawning-entities)
    - [Entity Builders](#entity-builders)
  - [Access Operations](#access-operations)
  - [Iterating Over Fragments](#iterating-over-fragments)
  - [Modifying Operations](#modifying-operations)
  - [Debug Mode](#debug-mode)
  - [Queries](#queries)
    - [Deferred Operations](#deferred-operations)
    - [Batch Operations](#batch-operations)
  - [Systems](#systems)
  - [Predefined Traits](#predefined-traits)
    - [Fragment Tags](#fragment-tags)
    - [Fragment Hooks](#fragment-hooks)
    - [Unique Fragments](#unique-fragments)
    - [Explicit Fragments](#explicit-fragments)
    - [Shared Components](#shared-components)
    - [Fragment Requirements](#fragment-requirements)
    - [Destruction Policies](#destruction-policies)
- [Cheat Sheet](#cheat-sheet)
  - [Aliases](#aliases)
  - [Predefs](#predefs)
  - [Core Functions](#core-functions)
  - [Relation Functions](#relation-functions)
  - [Classes](#classes)
    - [Chunk](#chunk)
    - [Builder](#builder)
- [License](#license)

## Introduction

`evolved.lua` is a fast and flexible ECS (Entity-Component-System) library for Lua. It is designed to be simple and easy to use, while providing all the features needed to create complex systems with blazing performance. Before we start exploring the library, let's take a look at the main advantages of using `evolved.lua`:

### Performance

This library is designed to be fast. Many techniques are employed to achieve this. It uses an archetype-based approach to store entities and their components. Components are stored in contiguous arrays in a SoA (Structure of Arrays) manner, which allows for fast iteration and processing. Chunks are used to group entities with the same set of components together, enabling efficient filtering through queries. Additionally, all operations are designed to minimize GC (Garbage Collector) pressure and avoid unnecessary allocations. I have tried to take into account all the performance pitfalls of vanilla Lua and LuaJIT.

Not all the optimizations I want to implement are done yet, but I will be working on them. However, I can already say that the library is fast enough for most use cases.

### Simplicity

I have tried to keep the [API](#cheat-sheet) as simple and intuitive as possible. I also keep the number of functions under control. All the functions are self-explanatory and easy to use. After reading the [Overview](#overview) section, you should be able to use the library without any problems.

And yes, the library has some unusual concepts at its core, but once you get the hang of it, you will find it's very easy to use.

### Flexibility

`evolved.lua` is not just about keeping components in entities. It's a full-fledged ECS library that allows you to create complex [systems](#systems) and processes. You can create [queries](#queries) with filters, use [deferred operations](#deferred-operations), and [batch operations](#batch-operations). You can also create systems that process entities in a specific order. The library is designed to be flexible and extensible, so you can easily add your own features and functionality. Features like [fragment hooks](#fragment-hooks) allow you to manage your components in a more flexible way, synchronizing them with external systems or libraries. The library also provides syntactic sugar like the [entity builder](#entity-builders) for creating entities, fragments, and systems to make your life easier.

On the other hand, `evolved.lua` tries to be minimalistic and does not provide features that can be implemented outside the library. I'm trying to find a balance between minimalism and the number of possibilities, which forces me to make flexible decisions in the library's design. I hope you will find this balance acceptable.

## Installation

`evolved.lua` is a single-file pure Lua library and does not require any external dependencies. It is designed to work with [Lua 5.1](https://www.lua.org/) and later, [LuaJIT](https://luajit.org/), and [Luau](https://luau.org/) (Roblox).

All you need to start using the library is the [evolved.lua](./evolved.lua) source file. You can download it from the [releases](https://github.com/BlackMATov/evolved.lua/releases) page or clone the [repository](https://github.com/BlackMATov/evolved.lua) and copy the file to your project.

If you are using [LuaRocks](https://luarocks.org/), you can install the library using the following command:

```bash
luarocks install evolved.lua
```

## Quick Start

To get started with `evolved.lua`, read the [Overview](#overview) section to understand the basic concepts and how to use the library. After that, check the [Samples](develop/samples), which demonstrate complex usage of the library. Finally, refer to the [Cheat Sheet](#cheat-sheet) for a quick reference of all the functions and classes provided by the library.

## Overview

The library is designed to be simple and highly performant. It uses an archetype-based approach to store entities and their components. This allows you to filter and process your entities very efficiently, especially when you have many of them.

If you are familiar with the ECS (Entity-Component-System) pattern, you will feel right at home. If not, I highly recommend reading about it first. Here is a good starting point: [Entity Component System FAQ](https://github.com/SanderMertens/ecs-faq).

Let's get started! :godmode:

### Identifiers

An identifier is a packed 40-bit integer. The first 20 bits represent the index, and the last 20 bits represent the version. To create a new identifier, use the [`evolved.id`](#evolvedid) function.

```lua
---@param count? integer
---@return evolved.id ... ids
function evolved.id(count) end
```

The `count` parameter is optional and defaults to `1`. The function returns one or more identifiers depending on the `count` parameter. The maximum number of alive identifiers is `2^20-1` (1048575). After that, the function will throw an error: `| evolved.lua | id index overflow`.

Identifiers can be recycled. When an identifier is no longer needed, use the [`evolved.destroy`](#evolveddestroy) function to destroy it. This will free the identifier for reuse.

```lua
---@param ... evolved.id ids
function evolved.destroy(...) end
```

The [`evolved.destroy`](#evolveddestroy) function takes one or more identifiers as arguments. Destroyed identifiers will be added to the recycler free list. It is safe to call [`evolved.destroy`](#evolveddestroy) on identifiers that are not alive; the function will simply ignore them.

After destroying an identifier, it can be reused by calling the [`evolved.id`](#evolvedid) function again. The new identifier will have the same index as the destroyed one, but a different version. The version is incremented each time an identifier is destroyed. This mechanism allows us to reuse indices and to know whether an identifier is alive or not.

The set of [`evolved.alive`](#evolvedalive) functions can be used to check whether identifiers are alive.

```lua
---@param id evolved.id
---@return boolean
function evolved.alive(id) end

---@param ... evolved.id ids
---@return boolean
function evolved.alive_all(...) end

---@param ... evolved.id ids
---@return boolean
function evolved.alive_any(...) end
```

Sometimes (for debugging purposes, for example), it is necessary to extract the index and version from an identifier or to pack them back into an identifier. The [`evolved.pack`](#evolvedpack) and [`evolved.unpack`](#evolvedunpack) functions can be used for this purpose.

```lua
---@param index integer
---@param version integer
---@return evolved.id id
---@nodiscard
function evolved.pack(index, version) end

---@param id evolved.id
---@return integer primary
---@return integer secondary
---@return integer options
---@nodiscard
function evolved.unpack(id) end
```

Here is a short example of how to use identifiers:

```lua
local evolved = require 'evolved'

local id = evolved.id() -- create a new identifier
assert(evolved.alive(id)) -- check that the identifier is alive

local index, version = evolved.unpack(id) -- unpack the identifier
assert(evolved.pack(index, version) == id) -- pack it back

evolved.destroy(id) -- destroy the identifier
assert(not evolved.alive(id)) -- check that the identifier is not alive now
```

### Entities, Fragments, and Components

First, you need to understand that entities and fragments are just identifiers. The difference between them is purely semantic. Entities are used to represent objects in the world, while fragments are used to represent types of components that can be attached to entities. Components, on the other hand, are any data that is attached to entities through fragments.

```lua
---@alias evolved.entity evolved.id
---@alias evolved.fragment evolved.id
---@alias evolved.component any
```

Here is a simple example of how to attach a component to an entity:

```lua
local evolved = require 'evolved'

local entity, fragment = evolved.id(2)

evolved.set(entity, fragment, 100)
assert(evolved.get(entity, fragment) == 100)
```

I know it's not very clear yet, but don't worry, we'll get there. In the next example, I'm going to name the entity and fragment, so it will be easier to understand what's going on here.

```lua
local evolved = require 'evolved'

local player = evolved.id()

local health = evolved.id()
local stamina = evolved.id()

evolved.set(player, health, 100)
evolved.set(player, stamina, 50)

assert(evolved.get(player, health) == 100)
assert(evolved.get(player, stamina) == 50)
```

We created an entity called `player` and two fragments called `health` and `stamina`. We attached the components `100` and `50` to the entity through these fragments. After that, we can retrieve the components using the [`evolved.get`](#evolvedget) function.

We'll cover the [`evolved.set`](#evolvedset) and [`evolved.get`](#evolvedget) functions in more detail later in the section about [modifying operations](#modifying-operations). For now, let's just say that they are used to set and get components from entities through fragments.

The main thing to understand here is that you can attach any data to any identifier by using other identifiers.

#### Traits

Since fragments are just identifiers, you can use them as entities too! Fragments of fragments are usually called `traits`. This is very useful, for example, for marking fragments with some metadata.

```lua
local evolved = require 'evolved'

local serializable = evolved.id()

local position = evolved.id()
evolved.set(position, serializable, true)

local velocity = evolved.id()
evolved.set(velocity, serializable, true)

local player = evolved.id()
evolved.set(player, position, {x = 0, y = 0})
evolved.set(player, velocity, {x = 0, y = 0})
```

In this example, we create a trait called `serializable` and mark the fragments `position` and `velocity` as serializable. After that, you can write a function that will serialize entities, and this function will serialize only fragments that are marked as serializable. This is a very powerful feature of the library, and it allows you to create very flexible systems.

#### Singletons

Fragments can even be attached to themselves; this is called a singleton. Use this when you want to store some data without having a separate entity. For example, you can use it to store global data, like the game state or the current level.

```lua
local evolved = require 'evolved'

local gravity = evolved.id()
evolved.set(gravity, gravity, 10)

assert(evolved.get(gravity, gravity) == 10)
```

### Chunks

The next thing we need to understand is that all non-empty entities are stored in chunks. Chunks are just tables that store entities and their components together. Each unique combination of fragments is stored in a separate chunk. This means that if you have two entities with `health` and `stamina` fragments, they will be stored in the `<health, stamina>` chunk. If you have another entity with `health`, `stamina`, and `mana` fragments, it will be stored in the `<health, stamina, mana>` chunk. This is very useful for performance reasons, as it allows us to store entities with the same fragments together, making it easier to iterate, filter, and process them.

```lua
local evolved = require 'evolved'

local health, stamina, mana = evolved.id(3)

local entity1 = evolved.id()
evolved.set(entity1, health, 100)
evolved.set(entity1, stamina, 50)

local entity2 = evolved.id()
evolved.set(entity2, health, 75)
evolved.set(entity2, stamina, 40)

local entity3 = evolved.id()
evolved.set(entity3, health, 50)
evolved.set(entity3, stamina, 30)
evolved.set(entity3, mana, 20)
```

Here is what the chunks will look like after the code above has executed:

| chunk   | health | stamina |
| ------- | :----: | :-----: |
| entity1 |  100   |   50    |
| entity2 |   75   |   40    |

| chunk   | health | stamina | mana  |
| ------- | :----: | :-----: | :---: |
| entity3 |   50   |   30    |  20   |

Usually, you don't need to operate on chunks directly, but you can use the [`evolved.chunk`](#evolvedchunk) function to get the specific chunk.

```lua
---@param fragment evolved.fragment
---@param ... evolved.fragment fragments
---@return evolved.chunk chunk
function evolved.chunk(fragment, ...) end
```

The [`evolved.chunk`](#evolvedchunk) function takes one or more fragments as arguments and returns the chunk for this combination. After that, you can use the chunk's methods to retrieve their entities, fragments, and components.

```lua
---@return evolved.entity[] entity_list
---@return integer entity_count
function chunk_mt:entities() end

---@return evolved.fragment[] fragment_list
---@return integer fragment_count
function chunk_mt:fragments() end

---@param ... evolved.fragment fragments
---@return evolved.storage ... storages
function chunk_mt:components(...)
```

Full example:

```lua
local evolved = require 'evolved'

local health, stamina, mana = evolved.id(3)

local entity1 = evolved.id()
evolved.set(entity1, health, 100)
evolved.set(entity1, stamina, 50)

local entity2 = evolved.id()
evolved.set(entity2, health, 75)
evolved.set(entity2, stamina, 40)

local entity3 = evolved.id()
evolved.set(entity3, health, 50)
evolved.set(entity3, stamina, 30)
evolved.set(entity3, mana, 20)

-- get (or create if it doesn't exist) the chunk <health, stamina>
local chunk = evolved.chunk(health, stamina)

-- get the list of entities in the chunk and the number of them
local entity_list, entity_count = chunk:entities()

-- get the columns of components in the chunk
local health_components = chunk:components(health)
local stamina_components = chunk:components(stamina)

for i = 1, entity_count do
    local entity = entity_list[i]

    local entity_health = health_components[i]
    local entity_stamina = stamina_components[i]

    -- do something with the entity and its components
    print(string.format(
        'Entity: %d, Health: %d, Stamina: %d',
        entity, entity_health, entity_stamina))
end

-- Expected output:
-- Entity: 1048602, Health: 100, Stamina: 50
-- Entity: 1048603, Health: 75, Stamina: 40
```

### Structural Changes

Every time we insert or remove a fragment from an entity, the entity will be migrated to a new chunk. This is done automatically by the library, of course. However, you should be aware of this because it can affect performance, especially if you have many fragments on the entity. This is called a `structural change`.

You should try to avoid structural changes, especially in performance-critical code. For example, you can spawn entities with all the fragments they will ever need and avoid changing them during the entity's lifetime. Overriding existing components is not a structural change, so you can do it freely.

#### Spawning Entities

```lua
---@param components? table<evolved.fragment, evolved.component>
---@return evolved.entity
function evolved.spawn(components) end

---@param prefab evolved.entity
---@param components? table<evolved.fragment, evolved.component>
---@return evolved.entity
function evolved.clone(prefab, components) end
```

The [`evolved.spawn`](#evolvedspawn) function allows you to spawn an entity with all the necessary fragments. It takes a table of components as an argument, where the keys are fragments and the values are components. By the way, you don't need to create this `components` table every time; consider using a predefined table for maximum performance.

You can also use the [`evolved.clone`](#evolvedclone) function to clone an existing entity. This is useful for creating entities with the same fragments as an existing entity but with different components.

```lua
local evolved = require 'evolved'

local health, stamina = evolved.id(2)

-- spawn an entity with all the necessary fragments
local enemy1 = evolved.spawn {
    [health] = 100,
    [stamina] = 50,
}

-- spawn another entity with the same fragments,
-- but with a different component for some of them
local enemy2 = evolved.clone(enemy1, {
    [health] = 50,
})

-- there are no structural changes here,
-- we just override existing components
evolved.set(enemy1, health, 75)
evolved.set(enemy1, stamina, 42)
```

#### Entity Builders

Another way to avoid structural changes when spawning entities is to use the [`evolved.builder`](#evolvedbuilder) fluent interface. The [`evolved.builder`](#evolvedbuilder) function returns a builder object that allows you to spawn entities with a specific set of fragments and components without the necessity of setting them one by one with structural changes for each change.

```lua
local evolved = require 'evolved'

local health, stamina = evolved.id(2)

local enemy = evolved.builder()
    :set(health, 100)
    :set(stamina, 50)
    :spawn()
```

Builders can be reused, so you can create a builder with a specific set of fragments and components and then use it to spawn multiple entities with the same fragments and components.

### Access Operations

The library provides all the necessary functions to access entities and their components. I'm not going to cover all the accessor functions here, because they are pretty straightforward and self-explanatory. You can check the [API Reference](#api-reference) for all of them. Here are some of the most important ones:

```lua
---@param entity evolved.entity
---@return boolean
function evolved.alive(entity) end

---@param entity evolved.entity
---@return boolean
function evolved.empty(entity) end

---@param entity evolved.entity
---@param fragment evolved.fragment
function evolved.has(entity, fragment) end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return evolved.component ... components
function evolved.get(entity, ...) end
```

The [`evolved.alive`](#evolvedalive) function checks whether an entity is alive. The [`evolved.empty`](#evolvedempty) function checks whether an entity is empty (has no fragments). The [`evolved.has`](#evolvedhas) function checks whether an entity has a specific fragment. The [`evolved.get`](#evolvedget) function retrieves the components of an entity for the specified fragments. If the entity doesn't have some of the fragments or if the fragments are marked with the [`evolved.TAG`](#evolvedtag), the function will return `nil` for them.

All of these functions can be safely called on non-alive entities and non-alive fragments. Also, they do not cause any structural changes, because they do not modify anything.

### Iterating Over Fragments

Sometimes, you may need to iterate over all fragments attached to an entity. You can use the [`evolved.each`](#evolvedeach) function for this purpose.

```lua
local evolved = require 'evolved'

local health = evolved.builder()
    :name('health')
    :spawn()

local stamina = evolved.builder()
    :name('stamina')
    :spawn()

local player = evolved.builder()
    :set(health, 100)
    :set(stamina, 50)
    :spawn()

for fragment, component in evolved.each(player) do
    print(string.format('Fragment (%s) has value %d',
        evolved.name(fragment), component))
end
```

> [!NOTE]
> [Structural changes](#structural-changes) are not allowed during iteration. If you want to spawn new entities or insert/remove fragments while iterating, defer these operations until the iteration is complete. See the [Deferred Operations](#deferred-operations) section for more details.

### Modifying Operations

The library provides a classic set of functions for modifying entities. These functions are used to insert, override, and remove fragments from entities.

```lua
---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
function evolved.set(entity, fragment, component) end

---@param entity evolved.entity
---@param ... evolved.fragment fragments
function evolved.remove(entity, ...)

---@param ... evolved.entity entities
function evolved.clear(...)

---@param ... evolved.entity entities
function evolved.destroy(...)
```

The [`evolved.set`](#evolvedset) function is used to set a component on an entity. If the entity doesn't have this fragment, it will be inserted, with causing a structural change, of course. If the entity already has the fragment, the component will be overridden. The function should not be called on non-alive entities, because it is not possible to set any component on a destroyed entity, ignoring this can lead to errors. The [Debug Mode](#debug-mode) can be used to check this kind of error.

Use the [`evolved.remove`](#evolvedremove) function to remove fragments from an entity. If the entity doesn't have some of the fragments, they will be ignored. When one or more fragments are removed from an entity, the entity will be migrated to a new chunk, which is a structural change. When you want to remove more than one fragment, pass all of them as arguments. Do not remove fragments one by one, as this will cause a structural change for each fragment. The [`evolved.remove`](#evolvedremove) function will ignore non-alive entities, because post-conditions are satisfied (destroyed entities do not have any fragments, including those that we want to remove).

To remove all fragments from an entity, use the [`evolved.clear`](#evolvedclear) function. This function will remove all fragments at once, causing only one structural change. The [`evolved.clear`](#evolvedclear) function does not destroy the entity, it just removes all fragments from it. The entity after this operation will be empty, but it will still be alive. You can use this function to clear more than one entity at once, passing them as arguments. The function will ignore empty and non-alive entities.

To destroy an entity, use the [`evolved.destroy`](#evolveddestroy) function. This function will remove all fragments from the entity and free the identifier of the entity for reuse. The [`evolved.destroy`](#evolveddestroy) function will ignore non-alive entities. To destroy more than one entity, pass them as arguments.

### Debug Mode

The library has a debug mode that can be enabled by the [`evolved.debug_mode`](#evolveddebug_mode) function. When the debug mode is enabled, the library will check for incorrect usages of the API and throw errors when they are detected. This is very useful for debugging and development, but it can slow down performance a bit.

```lua
---@param yesno boolean
function evolved.debug_mode(yesno) end
```

The debug mode is disabled by default, so you need to enable it manually. I strongly recommend doing this in the development environment. You can even leave it enabled in production, but only if you are sure the performance is acceptable for your case.

```lua
local evolved = require 'evolved'

evolved.debug_mode(true)

local entity = evolved.id()

local fragment = evolved.id()
evolved.destroy(fragment)

-- try to use the destroyed fragment
evolved.set(entity, fragment, 42)

-- [error] | evolved.lua | the fragment ($1048599#23:1) is not alive and cannot be used
```

### Queries

One of the most important features of any ECS library is the ability to process entities by filters or queries. `evolved.lua` provides a simple and efficient way to do this.

First, you need to create a query that describes which entities you want to process. You can specify fragments you want to include, and fragments you want to exclude. Queries are just identifiers with a special predefined fragments: [`evolved.INCLUDES`](#evolvedincludes) and [`evolved.EXCLUDES`](#evolvedexcludes). These fragments expect a list of fragments as their components.

```lua
local evolved = require 'evolved'

local health, poisoned, resistant = evolved.id(3)

local query = evolved.id()
evolved.set(query, evolved.INCLUDES, { health, poisoned })
evolved.set(query, evolved.EXCLUDES, { resistant })
```

The builder interface can be used to create queries too. It is more convenient to use, because the builder has special methods for including and excluding fragments. Here is a simple example of this:

```lua
local query = evolved.builder()
    :include(health, poisoned)
    :exclude(resistant)
    :spawn()
```

We don't have to set both [`evolved.INCLUDES`](#evolvedincludes) and [`evolved.EXCLUDES`](#evolvedexcludes) fragments, we can even do it without filters at all, then the query will match all chunks in the world.

After the query is created, we are ready to process our filtered by this query entities. You can do this by using the [`evolved.execute`](#evolvedexecute) function. This function takes a query as an argument and returns an iterator that can be used to iterate over all matching with the query chunks.

```lua
---@param query evolved.query
---@return evolved.execute_iterator iterator
---@return evolved.execute_state? iterator_state
function evolved.execute(query) end
```

```lua
for chunk, entity_list, entity_count in evolved.execute(query) do
    ---@type number[]
    local health_components = chunk:components(health)

    for i = 1, entity_count do
        health_components[i] = math.max(
            health_components[i] - 1,
            0)
    end
end
```

As you can see, `evolved.execute_iterator` returns a chunk, a list of entities in the chunk, and the number of entities in this chunk. We [already know](#chunks) how to use chunks, so we can use the chunk's methods to retrieve the components of the entities in the chunk, change them, and so on.

> [!NOTE]
> But I haven't mentioned one important thing yet: [structural changes](#structural-changes) are not allowed during any iteration over chunks. This means that you cannot insert or remove fragments from entities while iterating. Also, you cannot destroy or spawn entities because this will cause structural changes too. This is done to avoid inconsistencies in the iteration process. If we allowed structural changes here, we might skip some entities during iteration, or process the same entity multiple times. The [debug mode](#debug-mode) can catch this kind of error.

#### Deferred Operations

Now we know that structural changes are not allowed during iteration, but what if we want to make some structural changes after the iteration is finished? For example, we might want to remove some fragments from entities after we have processed them, or we might want to spawn new entities while processing existing ones. To do all of this, we can use deferred operations.

```lua
---@return boolean started
function evolved.defer() end

---@return boolean committed
function evolved.commit() end
```

The [`evolved.defer`](#evolveddefer) function starts a deferred scope. This means that all changes made inside the scope will be queued and applied after leaving the scope. The [`evolved.commit`](#evolvedcommit) function closes the last deferred scope and applies all queued changes. These functions can be nested, so you can start a new deferred scope inside an existing one. The [`evolved.commit`](#evolvedcommit) function will apply all queued changes only when the last deferred scope is closed.

```lua
local evolved = require 'evolved'

local health, poisoned = evolved.id(2)

local player = evolved.builder()
    :set(health, 100)
    :set(poisoned, true)
    :spawn()

-- start a deferred scope
evolved.defer()

-- this removal will be queued, not applied immediately
evolved.remove(player, poisoned)

-- the player still has the poisoned fragment inside the deferred scope
assert(evolved.has(player, poisoned))

-- commit the deferred operations
evolved.commit()

-- now the poisoned fragment is removed
assert(not evolved.has(player, poisoned))
```

#### Batch Operations

The library provides a set of functions for batch operations. These functions are used to perform modifying operations on multiple chunks at once. This is very useful for performance reasons.

```lua
---@param query evolved.query
---@param fragment evolved.fragment
---@param component evolved.component
function evolved.batch_set(query, fragment, component) end

---@param query evolved.query
---@param ... evolved.fragment fragments
function evolved.batch_remove(query, ...) end

---@param ... evolved.query queries
function evolved.batch_clear(...) end

---@param ... evolved.query queries
function evolved.batch_destroy(...) end
```

These functions are similar to the common [modifying operations](#modifying-operations), but they take a query as an argument instead of an entity. Here is a classic example that provides a huge performance boost when applied.

```lua
local evolved = require 'evolved'

local destroying_mark = evolved.id()

local destroying_mark_query = evolved.builder()
    :include(destroying_mark)
    :spawn()

-- destroy all entities with the destroying_mark fragment
evolved.batch_destroy(destroying_mark_query)
```

> [!TIP]
> You should always prefer batch operations over common modifying operations when you need to perform simple operations like destroying or removing fragments from multiple entities at once. Instead of applying the operation to each entity one by one, batch operations will apply the operation chunk by chunk.

In all other respects, batch operations behave the same way as the common modifying operations that we have already covered. Of course, they can also be used with [deferred operations](#deferred-operations).

### Systems

Usually, we want to organize our processing of entities into systems that will be executed in a specific order. The library has a way to do this using special [`evolved.QUERY`](#evolvedquery) and [`evolved.EXECUTE`](#evolvedexecute) fragments that are used to specify the system's queries and execution callbacks. And yes, systems are just entities with special fragments.

```lua
local evolved = require 'evolved'

local health, max_health = evolved.id(2)

local query = evolved.builder()
    :include(health, max_health)
    :spawn()

local system = evolved.builder()
    :query(query)
    :execute(function(chunk, entity_list, entity_count)
        local health_components = chunk:components(health)
        local max_health_components = chunk:components(max_health)

        for i = 1, entity_count do
            health_components[i] = math.min(
                health_components[i] + 1,
                max_health_components[i])
        end
    end):spawn()
```

The [`evolved.process`](#evolvedprocess) function is used to process systems. It takes systems as arguments and executes them in the order they were passed.

```lua
---@param ... evolved.system systems
function evolved.process(...) end
```

If you don't specify a query for the system, the system itself will be treated as a query. This means the system can contain `evolved.INCLUDES` and `evolved.EXCLUDES` fragments, and it will be processed according to them. This is useful for creating systems with unique queries that don't need to be reused in other systems.

```lua
local evolved = require 'evolved'

local health = evolved.id()

local system = evolved.builder()
    :include(health)
    :execute(function(chunk, entity_list, entity_count)
        local health_components = chunk:components(health)

        for i = 1, entity_count do
            health_components[i] = math.max(
                health_components[i] - 1,
                0)
        end
    end):spawn()

evolved.process(system)
```

To group systems together, you can use the [`evolved.GROUP`](#evolvedgroup) fragment. Systems with a specified group will be processed when you call the [`evolved.process`](#evolvedprocess) function with this group. For example, you can group all physics systems together and process them in one [`evolved.process`](#evolvedprocess) call.

```lua
local evolved = require 'evolved'

local gravity_x = 0
local gravity_y = -9.81

local position_x, position_y = evolved.id(2)
local velocity_x, velocity_y = evolved.id(2)

local physical_body_query = evolved.builder()
    :include(position_x, position_y)
    :include(velocity_x, velocity_y)
    :spawn()

local physics_group = evolved.id()

evolved.builder()
    :group(physics_group)
    :query(physical_body_query)
    :execute(function(chunk, entity_list, entity_count)
        local vx = chunk:components(velocity_x)
        local vy = chunk:components(velocity_y)

        for i = 1, entity_count do
            vx[i] = vx[i] + gravity_x
            vy[i] = vy[i] + gravity_y
        end
    end):spawn()

evolved.builder()
    :group(physics_group)
    :query(physical_body_query)
    :execute(function(chunk, entity_list, entity_count)
        local px = chunk:components(position_x)
        local py = chunk:components(position_y)

        local vx = chunk:components(velocity_x)
        local vy = chunk:components(velocity_y)

        for i = 1, entity_count do
            px[i] = px[i] + vx[i]
            py[i] = py[i] + vy[i]
        end
    end):spawn()

evolved.process(physics_group)
```

Systems and groups also can have the [`evolved.PROLOGUE`](#evolvedprologue) and [`evolved.EPILOGUE`](#evolvedepilogue) fragments. These fragments are used to specify callbacks that will be executed before and after the system or group is processed. This is useful for setting up and tearing down systems or groups, or for performing some additional processing before or after the main processing.

```lua
local evolved = require 'evolved'

local system = evolved.builder()
    :prologue(function()
        print('Prologue')
    end)
    :epilogue(function()
        print('Epilogue')
    end)
    :spawn()

evolved.process(system)
```

The prologue and epilogue fragments do not require an explicit query. They will be executed before and after the system is processed, regardless of the query.

> [!NOTE]
> And one more thing about systems. Execution callbacks are called in the [deferred scope](#deferred-operations), which means that all modifying operations inside the callback will be queued and applied after the system has processed all chunks. But prologue and epilogue callbacks are not called in the deferred scope, so all modifying operations inside them will be applied immediately. This is done to avoid confusion and to make it clear that prologue and epilogue callbacks are not part of the chunk processing.

### Predefined Traits

#### Fragment Tags

Sometimes you want to have a fragment without a component. For example, you might want to have some marks that will be used to mark entities for processing. Fragments without components are called `tags`. Such fragments take up less memory, because they do not require any components to be stored. Migration of entities with tags is faster, because the library does not need to migrate components, only the tags themselves. To create a tag, mark the fragment with the [`evolved.TAG`](#evolvedtag) fragment.

```lua
local evolved = require 'evolved'

local player_tag = evolved.id()
evolved.set(player_tag, evolved.TAG)

local player = evolved.id()
evolved.set(player, player_tag)

-- player has the player_tag fragment
assert(evolved.has(player, player_tag))

-- player_tag is a tag, so it doesn't have a component
assert(evolved.get(player, player_tag) == nil)
```

#### Fragment Hooks

The library provides a way to execute callbacks when fragments are set, assigned, inserted, or removed from entities. This is done using special fragments: [`evolved.ON_SET`](#evolvedon_set), [`evolved.ON_ASSIGN`](#evolvedon_assign), [`evolved.ON_INSERT`](#evolvedon_insert), and [`evolved.ON_REMOVE`](#evolvedon_remove). These fragments are used to specify the callbacks that will be executed when the corresponding operation is performed on the fragment.

```lua
local evolved = require 'evolved'

local health = evolved.builder()
    :on_set(function(entity, fragment, component)
        print('health set to ' .. component)
    end):spawn()

local player = evolved.id()
evolved.set(player, health, 100) -- prints "health set to 100"
evolved.set(player, health, 200) -- prints "health set to 200"
```

Use [`evolved.ON_SET`](#evolvedon_set) for callbacks on fragment insert or override, [`evolved.ON_ASSIGN`](#evolvedon_assign) for overrides, and [`evolved.ON_INSERT`](#evolvedon_insert)/[`evolved.ON_REMOVE`](#evolvedon_remove) for insertions or removals.

#### Unique Fragments

Some fragments should not be cloned when cloning entities. For example, `evolved.lua` has a special fragment called `evolved.PREFAB`, which marks entities used as sources for cloning. This fragment should not be present on the cloned entities. To prevent a fragment from being cloned, mark it as unique using the [`evolved.UNIQUE`](#evolvedunique) fragment trait. This ensures the fragment will not be copied when cloning entities.

```lua
local evolved = require 'evolved'

local health, stamina = evolved.id(2)

local enemy_prefab = evolved.builder()
    :prefab()
    :set(health, 100)
    :set(stamina, 50)
    :spawn()

local enemy_clone = evolved.clone(enemy_prefab)

-- the enemy_prefab has the evolved.PREFAB fragment
assert(evolved.has(enemy_prefab, evolved.PREFAB))

-- but the enemy_clone doesn't have it, because it is marked as unique
assert(not evolved.has(enemy_clone, evolved.PREFAB))
```

#### Explicit Fragments

In some cases, you might want to hide chunks with certain fragments from queries by default. For example, the library has a special fragment called [`evolved.DISABLED`](#evolveddisabled) that behaves this way. This fragment is marked with the [`evolved.EXPLICIT`](#evolvedexplicit) fragment trait, which means it will be hidden from queries unless you explicitly include it. This is useful for fragments that are used for internal or editor purposes and should not be exposed to queries by default.

Additionally, the [`evolved.PREFAB`](#evolvedprefab) fragment is also marked with the [`evolved.EXPLICIT`](#evolvedexplicit) fragment trait. This prevents prefabs from being processed in queries at runtime. Prefabs are used only for cloning entities, so they should not be processed by default.

```lua
local evolved = require 'evolved'

local enemy_tag = evolved.builder()
    :tag()
    :spawn()

local only_enabled_enemies = evolved.builder()
    :include(enemy_tag)
    :spawn()

local all_enemies_including_disabled = evolved.builder()
    :include(enemy_tag)
    :include(evolved.DISABLED)
    :spawn()
```

#### Shared Components

Often, we want to store components as tables, and by default, these tables will be shared between entities. This means that if you modify the table in one entity, it will be modified in all entities that share this table. Sometimes this is what we want. For example, when we want to share a configuration or some resource between entities. But in other cases, we want each entity to have its own copy of the table. For example, if we want to store the position of an entity as a table, we don't want to share this table with other entities. Yes, we can copy the table manually, but the library provides a little bit of syntactic sugar for this.

```lua
local evolved = require 'evolved'

local initial_position = { x = 0, y = 0 }

local position = evolved.id()

local enemy1 = evolved.builder()
    :set(position, initial_position)
    :spawn()

local enemy2 = evolved.builder()
    :set(position, initial_position)
    :spawn()

-- the enemy1 and enemy2 share the same table,
-- and that's definitely not what we want in this case
assert(evolved.get(enemy1, position) == evolved.get(enemy2, position))
```

To avoid this, `evolved.lua` provides a fragment trait called [`evolved.DUPLICATE`](#evolvedduplicate). This trait expects a function that will be called when the component of this fragment is set. The function should return a new table to be used as the component for the entity. This way, each entity will have its own copy of the table, and modifying one entity will not affect the others.

To make this example clearer, we will also use the [`evolved.DEFAULT`](#evolveddefault) fragment trait. This trait is used to specify a default value for the component. The default value will be used when the component is not set explicitly.

```lua
local evolved = require 'evolved'

local function vector2(x, y)
    return { x = x, y = y }
end

local function vector2_duplicate(v)
    return { x = v.x, y = v.y }
end

local position = evolved.builder()
    :default(vector2(0, 0))
    :duplicate(vector2_duplicate)
    :spawn()

local enemy1 = evolved.builder()
    :set(position)
    :spawn()

local enemy2 = evolved.builder()
    :set(position)
    :spawn()

-- the enemy1 and enemy2 have different tables now
assert(evolved.get(enemy1, position) ~= evolved.get(enemy2, position))
```

#### Fragment Requirements

Sometimes you want to add additional fragments to an entity when it receives a specific fragment. For example, you might want to add `position` and `velocity` fragments when an entity is given a `physical` fragment. This can be done using the [`evolved.REQUIRES`](#evolvedrequires) fragment trait. This trait expects a list of fragments that will be added to the entity when the fragment is inserted.

```lua
local evolved = require 'evolved'

local position = evolved.builder()
    :default(vector2(0, 0))
    :duplicate(vector2_duplicate)
    :spawn()

local velocity = evolved.builder()
    :default(vector2(0, 0))
    :duplicate(vector2_duplicate)
    :spawn()

local physical = evolved.builder()
    :tag()
    :require(position, velocity)
    :spawn()

local enemy = evolved.builder()
    :set(physical)
    :spawn()

assert(evolved.has_all(enemy, position, velocity))
```

#### Destruction Policies

Typically, fragments remain alive for the entire lifetime of the program. However, in some cases, you might want to destroy fragments when they are no longer needed. For example, you can use some runtime entities as fragments for other entities. In this case, you might want to destroy such fragments even while they are still attached to other entities. Since entities cannot have destroyed fragments, a destruction policy must be applied to resolve this. By default, the library will remove the destroyed fragment from all entities that have it.

```lua
local evolved = require 'evolved'

local world = evolved.builder()
    :tag()
    :spawn()

local entity = evolved.builder()
    :set(world)
    :spawn()

-- destroy the world fragment that is attached to the entity
evolved.destroy(world)

-- the entity is still alive, but it no longer has the world fragment
assert(evolved.alive(entity) and not evolved.has(entity, world))
```

The default behavior works well in most cases, but you can change it by using the [`evolved.DESTRUCTION_POLICY`](#evolveddestruction_policy) fragment. This fragment expects one of the following predefined identifiers:

- [`evolved.DESTRUCTION_POLICY_DESTROY_ENTITY`](#evolveddestruction_policy_destroy_entity) will destroy any entity that has the destroyed fragment. This is useful for cases like the one above, where you want to destroy all entities when their world is destroyed.

- [`evolved.DESTRUCTION_POLICY_REMOVE_FRAGMENT`](#evolveddestruction_policy_remove_fragment) will remove the destroyed fragment from all entities that have it. This is the default behavior, so you don't have to set it explicitly, but you can if you want.

```lua
local evolved = require 'evolved'

local world = evolved.builder()
    :tag()
    :destruction_policy(evolved.DESTRUCTION_POLICY_DESTROY_ENTITY)
    :spawn()

local entity = evolved.builder()
    :set(world)
    :spawn()

-- destroy the world fragment that is attached to the entity
evolved.destroy(world)

-- the entity is destroyed together with the world fragment now
assert(not evolved.alive(entity))
```

## Cheat Sheet

### Aliases

```
id :: implementation-specific
pair :: id

entity :: id
fragment :: id
query :: id
system :: id

component :: any
storage :: component[]

default :: component
duplicate :: {component -> component}

execute :: {chunk, entity[], integer}
prologue :: {}
epilogue :: {}

set_hook :: {entity, fragment, component, component?}
assign_hook :: {entity, fragment, component, component}
insert_hook :: {entity, fragment, component}
remove_hook :: {entity, fragment, component}

each_state :: implementation-specific
execute_state :: implementation-specific
primaries_state :: implementation-specific
secondaries_state :: implementation-specific

each_iterator :: {each_state? -> fragment?, component?}
execute_iterator :: {execute_state? -> chunk?, entity[]?, integer?}
primaries_iterator :: {primaries_state? -> fragment?, component?}
secondaries_iterator :: {secondaries_state? -> fragment?, component?}
```

### Predefs

```
ANY :: fragment

TAG :: fragment
NAME :: fragment

UNIQUE :: fragment
EXPLICIT :: fragment
INTERNAL :: fragment

DEFAULT :: fragment
DUPLICATE :: fragment

PREFAB :: fragment
DISABLED :: fragment

INCLUDES :: fragment
EXCLUDES :: fragment
REQUIRES :: fragment

ON_SET :: fragment
ON_ASSIGN :: fragment
ON_INSERT :: fragment
ON_REMOVE :: fragment

GROUP :: fragment

QUERY :: fragment
EXECUTE :: fragment

PROLOGUE :: fragment
EPILOGUE :: fragment

DESTRUCTION_POLICY :: fragment
DESTRUCTION_POLICY_DESTROY_ENTITY :: id
DESTRUCTION_POLICY_REMOVE_FRAGMENT :: id
```

### Core Functions

```
id :: integer? -> id...
name :: id... -> string...

pack :: integer, integer -> id
unpack :: id -> integer, integer, integer

defer :: boolean
commit :: boolean

spawn :: <fragment, component>? -> entity
clone :: entity -> <fragment, component>? -> entity

alive :: entity -> boolean
alive_all :: entity... -> boolean
alive_any :: entity... -> boolean

empty :: entity -> boolean
empty_all :: entity... -> boolean
empty_any :: entity... -> boolean

has :: entity, fragment -> boolean
has_all :: entity, fragment... -> boolean
has_any :: entity, fragment... -> boolean

get :: entity, fragment...  -> component...

set :: entity, fragment, component -> ()
remove :: entity, fragment... -> ()
clear :: entity... -> ()
destroy :: entity... -> ()

batch_set :: query, fragment, component -> ()
batch_remove :: query, fragment... -> ()
batch_clear :: query... -> ()
batch_destroy :: query... -> ()

each :: entity -> {each_state? -> fragment?, component?}, each_state?
execute :: query -> {execute_state? -> chunk?, entity[]?, integer?}, execute_state?

process :: system... -> ()

debug_mode :: boolean -> ()
collect_garbage :: ()
```

### Relation Functions

```
pair :: id, id -> pair
unpair :: pair -> id, id

is_pair :: id -> boolean
is_wildcard :: id -> boolean

primary :: entity, fragment, integer? -> fragment?, component?
secondary :: entity, fragment, integer? -> fragment?, component?

primaries :: entity, fragment -> {primaries_state? -> fragment?, component?}, primaries_state?
secondaries :: entity, fragment -> {secondaries_state? -> fragment?, component?}, secondaries_state?

primary_count :: entity, fragment -> integer
secondary_count :: entity, fragment -> integer
```

### Classes

#### Chunk

```
chunk :: fragment, fragment... -> chunk, entity[], integer

chunk_mt:alive :: boolean
chunk_mt:empty :: boolean

chunk_mt:has :: fragment -> boolean
chunk_mt:has_all :: fragment... -> boolean
chunk_mt:has_any :: fragment... -> boolean

chunk_mt:entities :: entity[], integer
chunk_mt:fragments :: fragment[], integer
chunk_mt:components :: fragment... -> storage...
```

#### Builder

```
builder :: builder

builder_mt:spawn :: entity
builder_mt:clone :: entity -> entity

builder_mt:has :: fragment -> boolean
builder_mt:has_all :: fragment... -> boolean
builder_mt:has_any :: fragment... -> boolean

builder_mt:get :: fragment... -> component...

builder_mt:set :: fragment, component -> builder
builder_mt:remove :: fragment... -> builder
builder_mt:clear :: builder

builder_mt:tag :: builder
builder_mt:name :: string -> builder

builder_mt:unique :: builder
builder_mt:explicit :: builder
builder_mt:internal :: builder

builder_mt:default :: component -> builder
builder_mt:duplicate :: {component -> component} -> builder

builder_mt:prefab :: builder
builder_mt:disabled :: builder

builder_mt:include :: fragment... -> builder
builder_mt:exclude :: fragment... -> builder
builder_mt:require :: fragment... -> builder

builder_mt:on_set :: {entity, fragment, component, component?} -> builder
builder_mt:on_assign :: {entity, fragment, component, component} -> builder
builder_mt:on_insert :: {entity, fragment, component} -> builder
builder_mt:on_remove :: {entity, fragment} -> builder

builder_mt:group :: system -> builder

builder_mt:query :: query -> builder
builder_mt:execute :: {chunk, entity[], integer} -> builder

builder_mt:prologue :: {} -> builder
builder_mt:epilogue :: {} -> builder

builder_mt:destruction_policy :: id -> builder
```

## License

`evolved.lua` is licensed under the [MIT License][license]. For more details, see the [LICENSE.md](./LICENSE.md) file in the repository.

# Changelog

## vX.X.X

- Added the new [`evolved.name`](#evolvedname-1) function
- Added the new [`evolved.INTERNAL`](#evolvedinternal) fragment trait

## v1.1.0

- [`Systems`](#systems) can be queries themselves now
- Added the new [`evolved.REQUIRES`](#evolvedrequires) fragment trait

## v1.0.0

- Initial release

# API Reference

## Predefs

### `evolved.ANY`

### `evolved.TAG`

### `evolved.NAME`

### `evolved.UNIQUE`

### `evolved.EXPLICIT`

### `evolved.INTERNAL`

### `evolved.DEFAULT`

### `evolved.DUPLICATE`

### `evolved.PREFAB`

### `evolved.DISABLED`

### `evolved.INCLUDES`

### `evolved.EXCLUDES`

### `evolved.REQUIRES`

### `evolved.ON_SET`

### `evolved.ON_ASSIGN`

### `evolved.ON_INSERT`

### `evolved.ON_REMOVE`

### `evolved.GROUP`

### `evolved.QUERY`

### `evolved.EXECUTE`

### `evolved.PROLOGUE`

### `evolved.EPILOGUE`

### `evolved.DESTRUCTION_POLICY`

### `evolved.DESTRUCTION_POLICY_DESTROY_ENTITY`

### `evolved.DESTRUCTION_POLICY_REMOVE_FRAGMENT`

## Core Functions

### `evolved.id`

```lua
---@param count? integer
---@return evolved.id ... ids
---@nodiscard
function evolved.id(count) end
```

### `evolved.name`

```lua
---@param ... evolved.id ids
---@return string... names
---@nodiscard
function evolved.name(...) end
```

### `evolved.pack`

```lua
---@param index integer
---@param version integer
---@return evolved.id id
---@nodiscard
function evolved.pack(index, version) end
```

### `evolved.unpack`

```lua
---@param id evolved.id
---@return integer primary
---@return integer secondary
---@return integer options
---@nodiscard
function evolved.unpack(id) end
```

### `evolved.defer`

```lua
---@return boolean started
function evolved.defer() end
```

### `evolved.commit`

```lua
---@return boolean committed
function evolved.commit() end
```

### `evolved.spawn`

```lua
---@param components? table<evolved.fragment, evolved.component>
---@return evolved.entity
function evolved.spawn(components) end
```

### `evolved.clone`

```lua
---@param prefab evolved.entity
---@param components? table<evolved.fragment, evolved.component>
---@return evolved.entity
function evolved.clone(prefab, components) end
```

### `evolved.alive`

```lua
---@param entity evolved.entity
---@return boolean
---@nodiscard
function evolved.alive(entity) end
```

### `evolved.alive_all`

```lua
---@param ... evolved.entity entities
---@return boolean
---@nodiscard
function evolved.alive_all(...) end
```

### `evolved.alive_any`

```lua
---@param ... evolved.entity entities
---@return boolean
---@nodiscard
function evolved.alive_any(...) end
```

### `evolved.empty`

```lua
---@param entity evolved.entity
---@return boolean
---@nodiscard
function evolved.empty(entity) end
```

### `evolved.empty_all`

```lua
---@param ... evolved.entity entities
---@return boolean
---@nodiscard
function evolved.empty_all(...) end
```

### `evolved.empty_any`

```lua
---@param ... evolved.entity entities
---@return boolean
---@nodiscard
function evolved.empty_any(...) end
```

### `evolved.has`

```lua
---@param entity evolved.entity
---@param fragment evolved.fragment
---@return boolean
---@nodiscard
function evolved.has(entity, fragment) end
```

### `evolved.has_all`

```lua
---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function evolved.has_all(entity, ...) end
```

### `evolved.has_any`

```lua
---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function evolved.has_any(entity, ...) end
```

### `evolved.get`

```lua
---@param entity evolved.entity
---@param ... evolved.fragment fragments
---@return evolved.component ... components
---@nodiscard
function evolved.get(entity, ...) end
```

### `evolved.set`

```lua
---@param entity evolved.entity
---@param fragment evolved.fragment
---@param component evolved.component
function evolved.set(entity, fragment, component) end
```

### `evolved.remove`

```lua
---@param entity evolved.entity
---@param ... evolved.fragment fragments
function evolved.remove(entity, ...) end
```

### `evolved.clear`

```lua
---@param ... evolved.entity entities
function evolved.clear(...) end
```

### `evolved.destroy`

```lua
---@param ... evolved.entity entities
function evolved.destroy(...) end
```

### `evolved.batch_set`

```lua
---@param query evolved.query
---@param fragment evolved.fragment
---@param component evolved.component
function evolved.batch_set(query, fragment, component) end
```

### `evolved.batch_remove`

```lua
---@param query evolved.query
---@param ... evolved.fragment fragments
function evolved.batch_remove(query, ...) end
```

### `evolved.batch_clear`

```lua
---@param ... evolved.query queries
function evolved.batch_clear(...) end
```

### `evolved.batch_destroy`

```lua
---@param ... evolved.query queries
function evolved.batch_destroy(...) end
```

### `evolved.each`

```lua
---@param entity evolved.entity
---@return evolved.each_iterator iterator
---@return evolved.each_state? iterator_state
---@nodiscard
function evolved.each(entity) end
```

### `evolved.execute`

```lua
---@param query evolved.query
---@return evolved.execute_iterator iterator
---@return evolved.execute_state? iterator_state
---@nodiscard
function evolved.execute(query) end
```

### `evolved.process`

```lua
---@param ... evolved.system systems
function evolved.process(...) end
```

### `evolved.debug_mode`

```lua
---@param yesno boolean
function evolved.debug_mode(yesno) end
```

### `evolved.collect_garbage`

```lua
function evolved.collect_garbage() end
```

## Relation Functions

### `evolved.pair`

```lua
---@param primary evolved.id
---@param secondary evolved.id
---@return evolved.pair pair
---@nodiscard
function evolved.pair(primary, secondary) end
```

### `evolved.unpair`

```lua
---@param pair evolved.pair
---@return evolved.id primary
---@return evolved.id secondary
---@nodiscard
function evolved.unpair(pair) end
```

### `evolved.is_pair`

```lua
---@param id evolved.id
---@return boolean
---@nodiscard
function evolved.is_pair(id) end
```

### `evolved.is_wildcard`

```lua
---@param id evolved.id
---@return boolean
---@nodiscard
function evolved.is_wildcard(id) end
```

### `evolved.primary`

```lua
---@param entity evolved.entity
---@param secondary evolved.fragment
---@param index? integer
---@return evolved.fragment? primary
---@return evolved.component? component
---@nodiscard
function evolved.primary(entity, secondary, index) end
```

### `evolved.secondary`

```lua
---@param entity evolved.entity
---@param primary evolved.fragment
---@param index? integer
---@return evolved.fragment? secondary
---@return evolved.component? component
---@nodiscard
function evolved.secondary(entity, primary, index) end
```

### `evolved.primaries`

```lua
---@param entity evolved.entity
---@param secondary evolved.fragment
---@return evolved.primaries_iterator iterator
---@return evolved.primaries_state? iterator_state
---@nodiscard
function evolved.primaries(entity, secondary) end
```

### `evolved.secondaries`

```lua
---@param entity evolved.entity
---@param primary evolved.fragment
---@return evolved.secondaries_iterator iterator
---@return evolved.secondaries_state? iterator_state
---@nodiscard
function evolved.secondaries(entity, primary) end
```

### `evolved.primary_count`

```lua
---@param entity evolved.entity
---@param secondary evolved.fragment
---@return integer
---@nodiscard
function evolved.primary_count(entity, secondary) end
```

### `evolved.secondary_count`

```lua
---@param entity evolved.entity
---@param primary evolved.fragment
---@return integer
---@nodiscard
function evolved.secondary_count(entity, primary) end
```

## Classes

### Chunk

#### `evolved.chunk`

```lua
---@param fragment evolved.fragment
---@param ... evolved.fragment fragments
---@return evolved.chunk chunk
---@return evolved.entity[] entity_list
---@return integer entity_count
---@nodiscard
function evolved.chunk(fragment, ...) end
```

#### `evolved.chunk_mt:alive`

```lua
---@return boolean
---@nodiscard
function evolved.chunk_mt:alive() end
```

#### `evolved.chunk_mt:empty`

```lua
---@return boolean
---@nodiscard
function evolved.chunk_mt:empty() end
```

#### `evolved.chunk_mt:has`

```lua
---@param fragment evolved.fragment
---@return boolean
---@nodiscard
function evolved.chunk_mt:has(fragment) end
```

#### `evolved.chunk_mt:has_all`

```lua
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function evolved.chunk_mt:has_all(...) end
```

#### `evolved.chunk_mt:has_any`

```lua
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function evolved.chunk_mt:has_any(...) end
```

#### `evolved.chunk_mt:entities`

```lua
---@return evolved.entity[] entity_list
---@return integer entity_count
---@nodiscard
function evolved.chunk_mt:entities() end
```

#### `evolved.chunk_mt:fragments`

```lua
---@return evolved.fragment[] fragment_list
---@return integer fragment_count
---@nodiscard
function evolved.chunk_mt:fragments() end
```

#### `evolved.chunk_mt:components`

```lua
---@param ... evolved.fragment fragments
---@return evolved.storage ... storages
---@nodiscard
function evolved.chunk_mt:components(...) end
```

### Builder

#### `evolved.builder`

```lua
---@return evolved.builder builder
---@nodiscard
function evolved.builder() end
```

#### `evolved.builder_mt:spawn`

```lua
---@return evolved.entity
function evolved.builder_mt:spawn() end
```

#### `evolved.builder_mt:clone`

```lua
---@param prefab evolved.entity
---@return evolved.entity
function evolved.builder_mt:clone(prefab) end
```

#### `evolved.builder_mt:has`

```lua
---@param fragment evolved.fragment
---@return boolean
---@nodiscard
function evolved.builder_mt:has(fragment) end
```

#### `evolved.builder_mt:has_all`

```lua
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function evolved.builder_mt:has_all(...) end
```

#### `evolved.builder_mt:has_any`

```lua
---@param ... evolved.fragment fragments
---@return boolean
---@nodiscard
function evolved.builder_mt:has_any(...) end
```

#### `evolved.builder_mt:get`

```lua
---@param ... evolved.fragment fragments
---@return evolved.component ... components
---@nodiscard
function evolved.builder_mt:get(...) end
```

#### `evolved.builder_mt:set`

```lua
---@param fragment evolved.fragment
---@param component evolved.component
---@return evolved.builder builder
function evolved.builder_mt:set(fragment, component) end
```

#### `evolved.builder_mt:remove`

```lua
---@param ... evolved.fragment fragments
---@return evolved.builder builder
function evolved.builder_mt:remove(...) end
```

#### `evolved.builder_mt:clear`

```lua
---@return evolved.builder builder
function evolved.builder_mt:clear() end
```

#### `evolved.builder_mt:tag`

```lua
---@return evolved.builder builder
function evolved.builder_mt:tag() end
```

#### `evolved.builder_mt:name`

```lua
---@param name string
---@return evolved.builder builder
function evolved.builder_mt:name(name) end
```

#### `evolved.builder_mt:unique`

```lua
---@return evolved.builder builder
function evolved.builder_mt:unique() end
```

#### `evolved.builder_mt:explicit`

```lua
---@return evolved.builder builder
function evolved.builder_mt:explicit() end
```

#### `evolved.builder_mt:internal`

```lua
---@return evolved.builder builder
function evolved.builder_mt:internal() end
```

#### `evolved.builder_mt:default`

```lua
---@param default evolved.component
---@return evolved.builder builder
function evolved.builder_mt:default(default) end
```

#### `evolved.builder_mt:duplicate`

```lua
---@param duplicate evolved.duplicate
---@return evolved.builder builder
function evolved.builder_mt:duplicate(duplicate) end
```

#### `evolved.builder_mt:prefab`

```lua
---@return evolved.builder builder
function evolved.builder_mt:prefab() end
```

#### `evolved.builder_mt:disabled`

```lua
---@return evolved.builder builder
function evolved.builder_mt:disabled() end
```

#### `evolved.builder_mt:include`

```lua
---@param ... evolved.fragment fragments
---@return evolved.builder builder
function evolved.builder_mt:include(...) end
```

#### `evolved.builder_mt:exclude`

```lua
---@param ... evolved.fragment fragments
---@return evolved.builder builder
function evolved.builder_mt:exclude(...) end
```

### `evolved.builder_mt:require`

```lua
---@param ... evolved.fragment fragments
---@return evolved.builder builder
function evolved.builder_mt:require(...) end
```

#### `evolved.builder_mt:on_set`

```lua
---@param on_set evolved.set_hook
---@return evolved.builder builder
function evolved.builder_mt:on_set(on_set) end
```

#### `evolved.builder_mt:on_assign`

```lua
---@param on_assign evolved.assign_hook
---@return evolved.builder builder
function evolved.builder_mt:on_assign(on_assign) end
```

#### `evolved.builder_mt:on_insert`

```lua
---@param on_insert evolved.insert_hook
---@return evolved.builder builder
function evolved.builder_mt:on_insert(on_insert) end
```

#### `evolved.builder_mt:on_remove`

```lua
---@param on_remove evolved.remove_hook
---@return evolved.builder builder
function evolved.builder_mt:on_remove(on_remove) end
```

#### `evolved.builder_mt:group`

```lua
---@param group evolved.system
---@return evolved.builder builder
function evolved.builder_mt:group(group) end
```

#### `evolved.builder_mt:query`

```lua
---@param query evolved.query
---@return evolved.builder builder
function evolved.builder_mt:query(query) end
```

#### `evolved.builder_mt:execute`

```lua
---@param execute evolved.execute
---@return evolved.builder builder
function evolved.builder_mt:execute(execute) end
```

#### `evolved.builder_mt:prologue`

```lua
---@param prologue evolved.prologue
---@return evolved.builder builder
function evolved.builder_mt:prologue(prologue) end
```

#### `evolved.builder_mt:epilogue`

```lua
---@param epilogue evolved.epilogue
---@return evolved.builder builder
function evolved.builder_mt:epilogue(epilogue) end
```

#### `evolved.builder_mt:destruction_policy`

```lua
---@param destruction_policy evolved.id
---@return evolved.builder builder
function evolved.builder_mt:destruction_policy(destruction_policy) end
```
