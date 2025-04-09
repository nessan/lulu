-----------------------------------------------------------------------------------------------------------------------
-- Lulu: Some type checks.
--
-- Full Documentation:     https://nessan.github.io/lulu
-- Source Repository:      https://github.com/nessan/lulu
-- SPDX-FileCopyrightText: 2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------
local M = {}

--- Enhanced version of the standard `type` method that returns the string `__name` field for tables if it exists.
--- Otherwise it just returns the type of the object as per the standard.
--- @param obj any The object to check.
--- @return string type. The type associated with `obj`.
function M.type(obj)
    local type_obj = type(obj)
    if type_obj ~= 'table' then return type_obj end
    return type(obj.__name) == 'string' and obj.__name or type_obj
end

--- Returns true if the input value is an integer.
function M.is_integer(value)
    return type(value) == 'number' and value % 1 == 0
end

--- Returns true if the input value is a positive integer.
function M.is_positive_integer(value)
    return type(value) == 'number' and value > 0 and value % 1 == 0
end

--- Returns true if the input value is a negative integer.
function M.is_negative_integer(value)
    return type(value) == 'number' and value < 0 and value % 1 == 0
end

--- Returns true if the input number is a NaN value.
function M.is_nan(value)
    return type(value) == 'number' and value ~= value
end

--- If we have `local types = require 'types'` then we want to also use `types` as a function.
--- We make the call to `types(obj, ...)` be the same as calling `types.types(obj, ...)`.
local mt = {}
function mt.__call(_, ...) return M.types(...) end

setmetatable(M, mt)

return M
