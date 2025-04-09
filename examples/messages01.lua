-----------------------------------------------------------------------------------------------------------------------
-- Lulu: Exercising the `lulu.messages` module.
--
-- Full Documentation:     https://nessan.github.io/lulu
-- Source Repository:      https://github.com/nessan/lulu
-- SPDX-FileCopyrightText: 2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------

-- Add "." and ".." to the package path for relative requires.
local dot      = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]] or "./"
package.path   = dot .. "?.lua;" .. dot .. "../?.lua;" .. package.path

-- The module we are exercising.
local messages = require("lulu.messages")
local scribe   = require("lulu.scribe")
local putln    = scribe.putln

-- Print the output from `messages.source_info`
local function source_info(offset)
    local func, file, line = messages.source_info(offset)
    putln("Source info at offset %d: Function '%s' (%s:%d)", offset, func, file, line)
end

-- Add a level of indirection.
local function call_source_info()
    source_info(-1)
    source_info(0)
    source_info(1)
    source_info(2)
    source_info(3)
    source_info(4)
end

-- Do the deed.
call_source_info()
