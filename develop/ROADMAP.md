# Roadmap

## Backlog

- observers and events
- add INDEX fragment trait
- use compact prefix-tree for chunks

## Thoughts

- We should have a way to not copy components on deferred spawn/clone
- Having a light version of the gargabe collector can be useful for some use-cases
- We can shrink the table pool tables on garbage collection if they are too large
- Basic default component value as true looks awful, should we use something else?

## Known Issues

- Errors in hooks or rellocs/compmoves/mappers are cannot be handled properly right now
