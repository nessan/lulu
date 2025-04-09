-----------------------------------------------------------------------------------------------------------------------
-- Lulu: Exercising the `lulu.Enum` module.
--
-- Full Documentation:     https://nessan.github.io/lulu
-- Source Repository:      https://github.com/nessan/lulu
-- SPDX-FileCopyrightText: 2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------

-- Add "." and ".." to the package path for relative requires.
local dot    = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]] or "./"
package.path = dot .. "?.lua;" .. dot .. "../?.lua;" .. package.path

local Enum   = require('lulu.Enum')

ENUM 'FromArray01' { 'Clubs', 'Diamonds', 'Hearts', 'Spades' }
print(FromArray01)

ENUM 'FromArray02' { 'Clubs = 0', 'Diamonds', 'Hearts', 'Spades' }
print(FromArray02)

ENUM 'FromArray03' { 'Clubs = 0', 'Diamonds', 'Hearts = 3', 'Spades' }
print(FromArray03)

ENUM 'FromString01' [[Clubs, Diamonds, Hearts, Spades]]
print(FromString01)

ENUM 'FromString02' [[Clubs = 0, Diamonds, Hearts, Spades]]
print(FromString02)

ENUM 'FromString03' [[Clubs = 0, Diamonds = 1, Hearts = 3, Spades]]
print(FromString03)

ENUM 'FromTable01' { Clubs = 1, Diamonds = 2, Hearts = 3, Spades = 4 }
print(FromTable01)

ENUM 'FromTable02' {
    Clubs    = { abbrev = 'C', color = 'black', icon = '♣', },
    Diamonds = { abbrev = 'D', color = 'red', icon = '♦', },
    Hearts   = { abbrev = 'H', color = 'red', icon = '♥', },
    Spades   = { abbrev = 'S', color = 'black', icon = '♠' }
}
print(FromTable02:pretty())

ENUM 'FromTable03' {
    Clubs    = { abbrev = 'C', color = 'black', icon = '♣', ordinal = 0 },
    Diamonds = { abbrev = 'D', color = 'red', icon = '♦', ordinal = 1 },
    Hearts   = { abbrev = 'H', color = 'red', icon = '♥', ordinal = 2 },
    Spades   = { abbrev = 'S', color = 'black', icon = '♠', ordinal = 3 }
}
print(FromTable03:pretty())
