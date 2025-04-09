-----------------------------------------------------------------------------------------------------------------------
-- Lulu: Exercising the `lulu.paths` module.
--
-- Full Documentation:     https://nessan.github.io/lulu
-- Source Repository:      https://github.com/nessan/lulu
-- SPDX-FileCopyrightText: 2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------

-- Add "." and ".." to the package path for relative requires.
local dot      = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]] or "./"
package.path   = dot .. "?.lua;" .. dot .. "../?.lua;" .. package.path

local paths = require('lulu.paths')
local putln = require('lulu.scribe').putln

local path = [[/Users/Jorge/Dev/lua/test.lua]]
local dir, base, ext = paths.components(path)
local filename = paths.filename(path)
local script_name = paths.script_name()

putln("Script:    %s", script_name)
putln('')
putln("Path:      %s", path)
putln("Directory: %s", dir)
putln("Basename:  %s", base)
putln("Filename:  %s", filename)
putln("Extension: %s", ext)

path = [[C:\Users\Jorge\Dev\lua\test.lua]]
dir, base, ext = paths.components(path)
filename = paths.filename(path)
script_name = paths.script_name()

putln('')
putln("Path:      %s", path)
putln("Directory: %s", dir)
putln("Basename:  %s", base)
putln("Filename:  %s", filename)
putln("Extension: %s", ext)
