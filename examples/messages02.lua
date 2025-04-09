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
local warn     = messages.warn
local info     = messages.info
local fatal    = messages.fatal

local scribe   = require("lulu.scribe")
local putln    = scribe.putln
local eputln   = scribe.eputln

-- Check if all elements in an array are positive & report any negative elements.
local function is_positive(arr)
    local ok = true
    for i = 1, #arr do
        local a = arr[i]
        if a < 0 then
            warn("Element at index %d in array %t is %d, which is not positive!", i, arr, a)
            ok = false
        end
    end
    return ok
end

-- Run the check and report the result as coming from the caller of this function.
local function check_info(arr)
    if is_positive(arr) then
        info(1, "All elements in array %t are positive!", arr)
    else
        info(1, "Array %t has negative elements!", arr)
    end
end

-- Run the check and error out if any elements are negative.
local function check_fatal(arr)
    if not is_positive(arr) then
        fatal(1, "Array %t has negative elements!", arr)
    end
end

-- Run the checks with some test data.
putln("\nExpect an info message...")
check_info({ 1, 2, 3, 4, 5 })

putln("\nExpect warning messages...")
check_info({ 1, 2, -3, 4, -5 })


putln("\nExpect warning messages...")
eputln("\nExpect a  fatal error...")
check_fatal({ 1, 2, -3, 4, -5 })
