# Roadmap

## Backlog

- observers and events
- add INDEX fragment trait
- use compact prefix-tree for chunks
- optional ffi component storages

## Thoughts

- We can create component storages on-demand rather than in advance
- We should have a way to not copy components on deferred spawn/clone
- Not all assoc_list_remove operations need to keep order, we can have an unordered variant also
- We still have several places where we use __lua_next without deterministic order, we should fix that

## Known Issues

- Errors in hooks are cannot be handled properly right now
