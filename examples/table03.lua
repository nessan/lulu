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

local a1, a2 = { 1,2,3 }, { 1,2,3 }
putln("%t == %t? returned: %s", a1, a2, a1 == a2)
putln("table.eq(%t,%t) returned: %s", a1, a2, table.eq(a1,a2))

local t1 = {p1 = {name = 'Alice'}, p2 = {name = 'Beth'}}
local t2 = {p2 = {name = 'Beth'}, p1 = {name = 'Alice'}}
putln("t1: %t", t1)
putln("t2: %t", t2)
putln("table.eq(t1, t2) returned: %s", table.eq(t1,t2))

t1 = {p1 = {name = 'Alice'}, p2 = {name = 'Beth'}}
t2 = {p2 = {name = 'Beth'}, p1 = {name = 'Alice'}}
t1.p1.next = t1.p2
t1.p2.prev = t1.p1
t2.p1.next = t2.p2
t2.p2.prev = t2.p1
putln("t1: %t", t1)
putln("t2: %t", t2)
putln("table.eq(t1, t2) returned: %s", table.eq(t1, t2))

t1.all = t1
t2.all = t2
putln("t1: %t", t1)
putln("t2: %t", t2)
putln("table.eq(t1, t2) returned: %s", table.eq(t1,t2))

t1 = {p1 = {name = 'Alice'}, p2 = {name = 'Beth'}}
t2 = {p2 = {name = 'Beth'}, p1 = {name = 'Alice'}}
t1[{}] = "hidden data"
t2[{}] = "hidden data"
putln("t1: %t", t1)
putln("t2: %t", t2)
putln("table.eq(t1,t2) returned: %s", table.eq(t1,t2))