# evolved.lua (work in progress)

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

## Requirements

- [lua](https://www.lua.org/) **>= 5.1**
- [luajit](https://luajit.org/) **>= 2.0**

## Predefs

```
TAG :: fragment
NAME :: fragment
DEFAULT :: fragment
DUPLICATE :: fragment

INCLUDES :: fragment
EXCLUDES :: fragment

ON_SET :: fragment
ON_ASSIGN :: fragment
ON_INSERT :: fragment
ON_REMOVE :: fragment

GROUP :: fragment

QUERY :: fragment
EXECUTE :: fragment

PROLOGUE :: fragment
EPILOGUE :: fragment

DISABLED :: fragment

DESTROY_POLICY :: fragment
DESTROY_POLICY_DESTROY_ENTITY :: id
DESTROY_POLICY_REMOVE_FRAGMENT :: id
```

## Functions

```
id :: integer? -> id...

pack :: integer, integer -> id
unpack :: id -> integer, integer

defer :: boolean
commit :: boolean

is_alive :: chunk | entity -> boolean
is_alive_all :: chunk | entity... -> boolean
is_alive_any :: chunk | entity... -> boolean

is_empty :: chunk | entity -> boolean
is_empty_all :: chunk | entity... -> boolean
is_empty_any :: chunk | entity... -> boolean

has :: chunk | entity, fragment -> boolean
has_all :: chunk | entity, fragment... -> boolean
has_any :: chunk | entity, fragment... -> boolean

get :: entity, fragment...  -> component...

set :: entity, fragment, component -> ()
remove :: entity, fragment... -> ()
clear :: entity... -> ()
destroy :: entity... -> ()

multi_set :: entity, fragment[], component[]? -> ()
multi_remove :: entity, fragment[] -> ()

batch_set :: query, fragment, component -> ()
batch_remove :: query, fragment... -> ()
batch_clear :: query... -> ()
batch_destroy :: query... -> ()

batch_multi_set :: query, fragment[], component[]? -> ()
batch_multi_remove :: query, fragment[] -> ()

chunk :: fragment, fragment... -> chunk, entity[], integer

entities :: chunk -> entity[], integer
fragments :: chunk -> fragment[], integer
components :: chunk, fragment... -> component[]...

each :: entity -> {each_state? -> fragment?, component?}, each_state?
execute :: query -> {execute_state? -> chunk?, entity[]?, integer?}, execute_state?

process :: system... -> ()

spawn_at :: chunk?, fragment[]?, component[]? -> entity
spawn_as :: entity?, fragment[]?, component[]? -> entity
spawn_with :: fragment[]?, component[]? -> entity

debug_mode :: boolean -> ()
collect_garbage :: ()
```

## Builders

```
entity :: entity_builder
entity_builder:set :: fragment, component -> entity_builder
entity_builder:build :: entity
```

```
fragment :: fragment_builder
fragment_builder:tag :: fragment_builder
fragment_builder:name :: string -> fragment_builder
fragment_builder:single :: component -> fragment_builder
fragment_builder:default :: component -> fragment_builder
fragment_builder:duplicate :: {component -> component} -> fragment_builder
fragment_builder:on_set :: {entity, fragment, component, component?} -> fragment_builder
fragment_builder:on_assign :: {entity, fragment, component, component} -> fragment_builder
fragment_builder:on_insert :: {entity, fragment, component} -> fragment_builder
fragment_builder:on_remove :: {entity, fragment} -> fragment_builder
fragment_builder:destroy_policy :: id -> fragment_builder
fragment_builder:build :: fragment
```

```
query :: query_builder
query_builder:name :: string -> query_builder
query_builder:single :: component -> query_builder
query_builder:include :: fragment... -> query_builder
query_builder:exclude :: fragment... -> query_builder
query_builder:build :: query
```

```
system :: system_builder
system_builder:name :: string -> system_builder
system_builder:single :: component -> system_builder
system_builder:group :: system -> system_builder
system_builder:query :: query -> system_builder
system_builder:execute :: {chunk, entity[], integer} -> system_builder
system_builder:prologue :: {} -> system_builder
system_builder:epilogue :: {} -> system_builder
system_builder:disabled :: system_builder
system_builder:build :: system
```

## [License (MIT)](./LICENSE.md)
