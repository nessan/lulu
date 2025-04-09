-----------------------------------------------------------------------------------------------------------------------
-- Lulu: Exercising the `lulu.table` module.
--
-- Full Documentation:     https://nessan.github.io/lulu
-- Source Repository:      https://github.com/nessan/lulu
-- SPDX-FileCopyrightText: 2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------

-- Add "." and ".." to the package path for relative requires.
local dot      = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]] or "./"
package.path   = dot .. "?.lua;" .. dot .. "../?.lua;" .. package.path

require('lulu.table')
local putln = require('lulu.scribe').putln

local tbl = { frog = 1, badger = 2, eagle = 3 }
for k, v in pairs(tbl) do print(k, v) end
print("--------")
local iter = table.ordered_pairs()
for k, v in iter(tbl) do print(k, v) end
print("--------")
iter = table.ordered_pairs(">")
for k, v in iter(tbl) do print(k, v) end