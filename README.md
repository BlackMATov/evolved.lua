# evolved.lua

```
id :: id
pack :: integer, integer -> id
unpack :: id -> integer, integer
alive :: id -> boolean
get :: entity, fragment...  -> component...
has :: entity, fragment -> boolean
has_all :: entity, fragment... -> boolean
has_any :: entity, fragment... -> boolean
set :: entity, fragment, component, any... -> ()
assign :: entity, fragment, component, any... -> boolean
insert :: entity, fragment, component, any... -> boolean
remove :: entity, fragment... -> ()
clear :: entity -> ()
destroy :: entity -> ()
```

```
defer :: defer

defer:set :: entity, fragment, component, any... -> defer
defer:assign :: entity, fragment, component, any... -> defer
defer:insert :: entity, fragment, component, any... -> defer
defer:remove :: entity, fragment... -> defer
defer:clear :: entity -> defer
defer:destroy :: entity -> defer
defer:playback :: ()
```

## [License (MIT)](./LICENSE.md)
