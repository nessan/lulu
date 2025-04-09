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

local p1 = {first = 'Joan', second = 'Doe'}
local p2 = {first = 'John', second = 'Doe'}
local p3 = {first = 'John', second = 'Smith'}
putln("p1:            %t", p1)  -- <1>
putln("p2:            %t", p2)
putln("p3:            %t", p3)
putln("Merged Values: %t", table.merged_values(p1,p2,p3))
putln("Merged Keys:   %t", table.merged_keys(p1,p2,p3))
putln("----------------------------------------------------------------")

local a1 = {1,2,3,4}
local a2 = {4,5,6,7}
local a3 = {7,8,9,0}
putln("a1:            %t", a1)
putln("a2:            %t", a2)
putln("a3:            %t", a3)
putln("Merged Values: %t", table.merged_values(a1,a2,a3))
putln("Merged Keys:   %t", table.merged_keys(a1,a2,a3))
putln("----------------------------------------------------------------")

putln("Common Values: p1, p2:     %t", table.common_values(p1, p2))
putln("Common Values: p2, p3:     %t", table.common_values(p2, p3))
putln("Common Values: p3, p1:     %t", table.common_values(p3, p1))
putln("Common Values: p1, p2, p3: %t", table.common_values(p1, p2, p3))
putln("----------------------------------------------------------------")

putln("Common Keys: p1, p2:     %t", table.common_keys(p1, p2))
putln("Common Keys: p2, p3:     %t", table.common_keys(p2, p3))
putln("Common Keys: p3, p1:     %t", table.common_keys(p3, p1))
putln("Common Keys: p1, p2, p3: %t", table.common_keys(p1, p2, p3))
putln("----------------------------------------------------------------")

putln("a1:                    %t", a1)
putln("a2:                    %t", a2)
putln("Common Values: a1, a2: %t", table.common_values(a1, a2))
putln("Common Keys:   a1, a2: %t", table.common_keys(a1, a2))
putln("----------------------------------------------------------------")

a1 = {1,2,3,4}
a2 = {5,6,7,4}
putln("a1:                    %t", a1)
putln("a2:                    %t", a2)
putln("Common Values: a1, a2: %t", table.common_values(a1, a2))
putln("Common Keys:   a1, a2: %t", table.common_keys(a1, a2))
putln("----------------------------------------------------------------")

p1 = {a = 'alpha', b = 'beta'}
p2 = {a = 'gamma', b = 'beta'}        -- <1>
putln("p1:                     %t", p1)
putln("p2:                     %t", p2)
putln("Unique Values: p1 - p2: %t", table.unique_values(p1, p2))
putln("Unique Values: p2 - p1: %t", table.unique_values(p2, p1))
putln("Unique Keys:   p1 - p2: %t", table.unique_keys(p1, p2))
putln("Unique Keys:   p2 - p1: %t", table.unique_keys(p2, p1))
putln("----------------------------------------------------------------")

p1 = {a = 'alpha', b = 'beta'}
p2 = {a = 'gamma', b = 'beta'}
putln("p1:                                 %t", p1)
putln("p2:                                 %t", p2)
putln("Values only in one of p1 **or** p2: %t", table.unique_values(p1, p2, true))
putln("Values only in one of p2 **or** p1: %t", table.unique_values(p2, p1, true))
putln("Keys only in one of p1 **or** p2:   %t", table.unique_keys(p1, p2, true))
putln("Keys only in one of p2 **or** p1:   %t", table.unique_keys(p2, p1, true))
putln("----------------------------------------------------------------")
