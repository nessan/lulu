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
local putln = require('lulu.scribe').putln
local Suit = Enum:new({
    Clubs    = { abbrev = 'C', color = 'black', icon = '♣', ordinal = 0 },
    Diamonds = { abbrev = 'D', color = 'red',   icon = '♦', ordinal = 1 },
    Hearts   = { abbrev = 'H', color = 'red',   icon = '♥', ordinal = 2 },
    Spades   = { abbrev = 'S', color = 'black', icon = '♠', ordinal = 3 }
})

for e in Suit:iter() do
    putln("%s: %s", e.abbrev, e.icon)
end
