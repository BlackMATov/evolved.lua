rockspec_format = "3.0"
package = "evolved.lua"
version = "1.7.0-0"
source = {
   url = "git://github.com/BlackMATov/evolved.lua",
   tag = "v1.7.0",
}
description = {
   homepage = "https://github.com/BlackMATov/evolved.lua",
   summary = "Evolved ECS (Entity-Component-System) for Lua",
   detailed = [[
      `evolved.lua` is a fast and flexible ECS (Entity-Component-System) library for Lua.
      It is designed to be simple and easy to use, while providing all the features needed to create complex systems with blazing performance.
   ]],
   license = "MIT",
   labels = {
      "ecs",
      "entity",
      "entities",
      "component",
      "components",
      "entity-component",
      "entity-component-system",
   },
}
dependencies = {
   "lua >= 5.1",
}
build = {
   type = "builtin",
   modules = {
      evolved = "evolved.lua",
   }
}
