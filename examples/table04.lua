-----------------------------------------------------------------------------------------------------------------------
-- Lulu: Some examples of using the `lulu.table` module.
--
-- Full Documentation:     https://nessan.github.io/lulu
-- Source Repository:      https://github.com/nessan/lulu
-- SPDX-FileCopyrightText: 2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------

-- Make sure that `require` works for the current directory and the parent directory.
local function add_relative_paths(...)
    local here = debug.getinfo(2, 'S').source:match [[^@?(.*[\/])[^\/]-$]]
    for _, path in ipairs({ ... }) do package.path = here .. path .. "/?.lua;" .. package.path end
end
add_relative_paths(".", "..")

-- Load the `lulu.table` module.
require("lulu.table")
local putln = require("lulu.scribe").putln

local tbl = { frog = 1, badger = 2, eagle = 3 }
print(table.concat(table.keys(tbl,false), ", "))    -- <1>
print(table.concat(table.keys(tbl),       ", "))    -- <2>

print(table.concat(table.values(tbl,false), ", "))
print(table.concat(table.values(tbl),       ", "))
print(table.concat(table.values(tbl, "<"),  ", "))

tbl =  {frog = "kermit", badger = "kermit", eagle = "eddie"}
local counts = table.counts(tbl)
for k,v in pairs(counts) do print(k,v) end


local key_set = table.set_of_keys(tbl)
local value_set = table.set_of_values(tbl)
print("key_set:")
for k in pairs(key_set) do print(k) end
print("value_set:")
for v in pairs(value_set) do print(v) end
    