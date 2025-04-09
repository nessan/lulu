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

local orig = { a = { 'alpha' }, b = { 'beta' } }
local deep = table.copy(orig)
local shallow = table.clone(orig)

putln("original     = %t", orig)
putln("deep copy    = %t", deep)
putln("shallow copy = %t", shallow)

deep.a[1] = "GAMMA"
putln("After setting `deep.a[1] to '%s'`", deep.a[1])
putln("original     = %t", orig)
putln("deep copy    = %t", deep)
putln("shallow copy = %t", shallow)

shallow.b[1] = "RHO"
putln("After setting `shallow.b[1] to '%s'`", shallow.b[1])
putln("original     = %t", orig)
putln("deep copy    = %t", deep)
putln("shallow copy = %t", shallow)
