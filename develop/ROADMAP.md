# Roadmap

## Backlog

- observers and events
- add INDEX fragment trait
- use compact prefix-tree for chunks
- optional ffi component storages

## Thoughts

- We can return deferred status from modifying operations and spawn/clone methods.
- We should have a way to not copy components on deferred spawn/clone.

## Known Issues

- Required fragments are slower than they should be
- Errors in hooks are cannot be handled properly right now
