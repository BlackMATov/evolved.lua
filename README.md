# evolved.lua (work in progress)

> Evolved ECS (Entity-Component-System) for Lua

[![language][badge.language]][language]
[![license][badge.license]][license]

[badge.language]: https://img.shields.io/badge/language-Lua-orange
[badge.license]: https://img.shields.io/badge/license-MIT-blue

[language]: https://en.wikipedia.org/wiki/Lua_(programming_language)
[license]: https://en.wikipedia.org/wiki/MIT_License

[evolved]: https://github.com/BlackMATov/evolved.lua

## Requirements

- [lua](https://www.lua.org/) **>= 5.1**
- [luajit](https://luajit.org/) **>= 2.0**

## Predefs

```
TAG :: fragment

DEFAULT :: fragment
CONSTRUCT :: fragment

INCLUDES :: fragment
EXCLUDES :: fragment

ON_SET :: fragment
ON_ASSIGN :: fragment
ON_INSERT :: fragment
ON_REMOVE :: fragment
```

## Functions

```
id :: integer? -> id...

pack :: integer, integer -> id
unpack :: id -> integer, integer

defer :: boolean
commit :: boolean

is_alive :: entity -> boolean
is_empty :: entity -> boolean

get :: entity, fragment...  -> component...
has :: entity, fragment -> boolean
has_all :: entity, fragment... -> boolean
has_any :: entity, fragment... -> boolean

set :: entity, fragment, any... -> boolean, boolean
assign :: entity, fragment, any... -> boolean, boolean
insert :: entity, fragment, any... -> boolean, boolean
remove :: entity, fragment... -> boolean, boolean
clear :: entity -> boolean, boolean
destroy :: entity -> boolean, boolean

multi_set :: entity, fragment[], component[]? -> boolean, boolean
multi_assign :: entity, fragment[], component[]? -> boolean, boolean
multi_insert :: entity, fragment[], component[]? -> boolean, boolean
multi_remove :: entity, fragment[] -> boolean, boolean

batch_set :: query, fragment, any... -> integer, boolean
batch_assign :: query, fragment, any... -> integer, boolean
batch_insert :: query, fragment, any... -> integer, boolean
batch_remove :: query, fragment... -> integer, boolean
batch_clear :: query -> integer, boolean
batch_destroy :: query -> integer, boolean

batch_multi_set :: query, fragment[], component[]? -> integer, boolean
batch_multi_assign :: query, fragment[], component[]? -> integer, boolean
batch_multi_insert :: query, fragment[], component[]? -> integer, boolean
batch_multi_remove :: query, fragment[] -> integer, boolean

chunk :: fragment... -> chunk?, entity[]?
select :: chunk, fragment... -> component[]...

each :: entity -> {each_state? -> fragment?, component?}, each_state?
execute :: query -> {execute_state? -> chunk?, entity[]?}, execute_state?
```

```
spawn_at :: chunk?, fragment[]?, component[]? -> entity, boolean
spawn_with :: fragment[]?, component[]? -> entity, boolean
```

```
entity :: entity_builder
entity_builder:set :: fragment, any... -> entity_builder
entity_builder:build :: entity, boolean
```

```
fragment :: fragment_builder
fragment_builder:tag :: fragment_builder
fragment_builder:single :: component -> fragment_builder
fragment_builder:default :: component -> fragment_builder
fragment_builder:construct :: {any... -> component} -> fragment_builder
fragment_builder:on_set :: {entity, fragment, component, component?} -> fragment_builder
fragment_builder:on_assign :: {entity, fragment, component, component} -> fragment_builder
fragment_builder:on_insert :: {entity, fragment, component} -> fragment_builder
fragment_builder:on_remove :: {entity, fragment} -> fragment_builder
fragment_builder:build :: fragment, boolean
```

```
query :: query_builder
query_builder:include :: fragment... -> query_builder
query_builder:exclude :: fragment... -> query_builder
query_builder:build :: query, boolean
```

## [License (MIT)](./LICENSE.md)
