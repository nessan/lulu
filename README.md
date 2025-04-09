# lulu

`lulu` is a collection of Lua utility modules and classes.
It includes a full-featured `Array` class, an `Enum` class, and a variety of utility functions and classes.

It also includes a copy of [`scribe`](https://nessan.github.io/scribe), a Lua module for formatted output that gracefully handles Lua tables.

## Available Modules

Module              | Purpose
------------------- | -----------------------------------------------------------------------------
`lulu.Array`        | A full-featured `Array` class for Lua.
`lulu.Enum`         | An `Enum` class for Lua.
`lulu.callable`     | Builds "anonymous" functions from strings etc.
`lulu.messages`     | Informational and error messages used throughout `lulu`.
`lulu.scribe`       | Converts Lua objects to strings. Gracefully handles recursive and shared tables.
`lulu.table`        | Lua `table` extensions that work on *any* table.
`lulu.string`       | Lua `string` extensions that are added to all string objects.
`lulu.xpeg`         | An extended `lpeg` module with predefined patterns and useful functions.
`lulu.paths`        | Some rudimentary path query methods.
`lulu.types`        | Type-checking methods.

## Installation & Use

`lulu` has no dependencies. Copy the `lulu` directory and start using it.

Released versions of `lulu` will be uploaded to [LuaRocks](https://luarocks.org), so you should be able to install the library using:

```bash
luarocks install lulu
```

Assuming your path allows it, you can `require('lulu.lulu')` and have access to all the modules:

```lua
require('lulu.lulu')
local Suit = Enum {
    Clubs    = { abbrev = 'C', color = 'black', icon = '♣', ordinal = 0 },
    Diamonds = { abbrev = 'D', color = 'red',   icon = '♦', ordinal = 1 },
    Hearts   = { abbrev = 'H', color = 'red',   icon = '♥', ordinal = 2 },
    Spades   = { abbrev = 'S', color = 'black', icon = '♠', ordinal = 3 }
}
Suit:set_type('Suit')
scribe.putln("%T", Suit)
```

That will output:

```txt
Suit:
 [0] Clubs = { abbrev = "C", color = "black", icon = "♣" },
 [1] Diamonds = { abbrev = "D", color = "red", icon = "♦" },
 [2] Hearts = { abbrev = "H", color = "red", icon = "♥" },
 [3] Spades = { abbrev = "S", color = "black", icon = "♠" }
```

## Documentation

`lulu` is fully documented [here](https://nessan.github.io/lulu/).
We built the documentation site using [Quarto](https://quarto.org).

## Acknowledgements

This library owes a lot to [Penlight](https://github.com/lunarmodules/Penlight) and the many questions that have been answered over the years on sites like StackOverflow and Reddit.

## Contact

You can contact me by email [here](mailto:nzznfitz+gh@icloud.com).

## Copyright and License

Copyright (c) 2025-present Nessan Fitzmaurice.
You can use this software under the [MIT license](https://opensource.org/license/mit).
