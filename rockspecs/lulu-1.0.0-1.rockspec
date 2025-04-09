package = "lulu"
version = "1.0.0-1"

source = {
  url = "git://github.com/nessan/lulu",
}

description = {
  summary = "lulu is a collection of Lua utility modules and classes..",
  detailed = [[
lulu is a collection of Lua utility modules and classes.
It includes a full-featured Array class, an Enum class, and a variety of other utility functions and extensions.
It also includes a copy of Scribe,, a Lua module for formatted output that gracefully handles Lua tables.
  ]],
  homepage = "https://nessan.github.io/lulu/",
  license = "MIT <http://opensource.org/licenses/MIT>"
}

dependencies = {
  "lua >= 5.1"
}

build = {
  type = "builtin",
  modules = {
    ["lulu.Array"] = "lulu/Array.lua",
    ["lulu.callable"] = "lulu/callable.lua",
    ["lulu.Enum"] = "lulu/Enum.lua",
    ["lulu.messages"] = "lulu/messages.lua",
    ["lulu.paths"] = "lulu/paths.lua",
    ["lulu.scribe"] = "lulu/scribe.lua",
    ["lulu.string"] = "lulu/string.lua",
    ["lulu.table"] = "lulu/table.lua",
    ["lulu.types"] = "lulu/types.lua"
    ["lulu.xpeg"] = "lulu/xpeg.lua",
  }
}
