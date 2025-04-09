-----------------------------------------------------------------------------------------------------------------------
-- Lulu: Exercising the `lulu.callable` module.
--
-- Full Documentation:      https://nessan.github.io/lulu
-- Source Repository:       https://github.com/nessan/lulu
-- SPDX-FileCopyrightText:  2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------

-- Add "." and ".." to the package path for relative requires.
local dot      = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]] or "./"
package.path   = dot .. "?.lua;" .. dot .. "../?.lua;" .. package.path

local callable = require('lulu.callable')
local putln    = require('lulu.scribe').putln

local f        = callable.lambda("|a| a + 1")
local g        = callable.lambda("|a,b| a * b")
local h        = callable.lambda("_ + 1")

print(f(10), g(10, 11), h(10))
