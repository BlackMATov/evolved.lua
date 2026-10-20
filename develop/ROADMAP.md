# Roadmap

## Backlog

- observers and events
- add batch hooks for fragments
- add component mapper for batch_set
- use compact prefix-tree for chunks

## Thoughts

- We should have a way to not copy components on deferred spawn/clone
- Basic default component value as true looks awful, should we use something else?

## Known Issues

- Errors in hooks or rellocs/compmoves/mappers are cannot be handled properly right now
