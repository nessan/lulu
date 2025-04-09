-----------------------------------------------------------------------------------------------------------------------
-- Lulu: Anonymous string operator & lambda utilities that attempt to convert strings into functions.
--
-- Acknowledgement:         https://github.com/lunarmodules/Penlight
-- Full Documentation:      https://nessan.github.io/lulu
-- Source Repository:       https://github.com/nessan/lulu
-- SPDX-FileCopyrightText:  2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------
local warn = require("lulu.messages").warn

local M = {}

--- Map the string version of each standard Lua operator to a corresponding trivial Lua function.
M.operators = {
    ['+']   = function(a, b) return a + b end,
    ['-']   = function(a, b) return a - b end,
    ['*']   = function(a, b) return a * b end,
    ['/']   = function(a, b) return a / b end,
    ['%']   = function(a, b) return a % b end,
    ['^']   = function(a, b) return a ^ b end,
    ['==']  = function(a, b) return a == b end,
    ['~=']  = function(a, b) return a ~= b end,
    ['<']   = function(a, b) return a < b end,
    ['<=']  = function(a, b) return a <= b end,
    ['>']   = function(a, b) return a > b end,
    ['>=']  = function(a, b) return a >= b end,
    ['and'] = function(a, b) return a and b end,
    ['or']  = function(a, b) return a or b end,
    ['()']  = function(fn, ...) return fn(...) end,
    ['{}']  = function(...) return { ... } end,
    ['[]']  = function(t, k) return t[k] end,
    ['#']   = function(a) return #a end,
    ['..']  = function(a, b) return a .. b end,
    ['~']   = function(a, b) return string.find(a, b) ~= nil end,
    ['']    = function(...) return ... end
}

--- Create a function from a lambda string using either named or anonymous arguments.
--- @param str            string  The lambda string to convert into a function.
--- @param issue_warning? boolean Issue warnings if the lambda string cannot be parsed? (Default `true`)
--- @return function|nil f The function from the lambda string or `nil` if the lambda string could not be parsed.
--- Syntax: `|args| body` or `body` with `_` marking a single argument. Similar to anonymous functions in Rust.
--- ### Examples:
--- - `lambda("|a| a + 1")` -> `function(a) return a + 1 end`
--- - `lambda("|a,b| a * b")` -> `function(a, b) return a * b end`
--- - `lambda("_ + 1")` -> `function(_) return _ + 1 end`
function M.lambda(str, issue_warning)
    if issue_warning == nil then issue_warning = true end
    local lambda_rx = '|([^|]*)|(.+)'

    -- Extract the arguments and body of the lambda.
    local args, body = nil, nil
    if str:find('_') then
        args, body = '_', str
    else
        args, body = str:match(lambda_rx)
    end

    -- Can't do anything if the lambda hasn't any arguments
    if not args then
        if issue_warning then warn(1, "Failed to parse '%s' as a lambda.", str) end
        return nil
    end

    -- Attempt to turn the lambda into a Lua function.
    local lua_str = 'return function(' .. args .. ') return ' .. body .. ' end'
    local fun_maker, err = load(lua_str)
    if fun_maker then return fun_maker() end

    -- Conversion failed.
    if issue_warning then warn(1, 'Loading "%s" as a lambda raised error:\n%s.', str, tostring(err)) end
    return nil
end

--- Create a callable function from an actual function, a callable table, a string operator, or a string lambda.
--- @param fun       any     A Lua function, a callable table, or a string lambda.
--- @param warnings? boolean Issue a warning if the arg cannot be interpreted as a function? (Default `true`)
function M.callable(fun, warnings)
    local fun_type = type(fun)
    if fun_type == 'function' then
        -- Trivial case: `fun` is already a function.
        return fun
    elseif fun_type == 'table' or fun_type == 'userdata' then
        -- A table with a `__call` metamethod is callable.
        local mt = getmetatable(fun)
        if mt and mt.__call then return fun end
    elseif fun_type == 'string' then
        -- A string can be an operator (e.g. "+")
        if M.operators[fun] then return M.operators[fun] end

        -- A string can be a lambda (e.g. "|a| a + 1")
        local f = M.lambda(fun, false)
        if f then return f end
    end

    -- Anything else is an error which by default we shout about.
    if warnings == nil then warnings = true end
    if warnings then warn(1, "'%s' argument '%s' is not interpretable as a function.", fun_type, tostring(fun)) end
    return nil
end

--- Returns true if the argument is callable as a function (no warnings are issued).
function M.is_callable(fun)
    return M.callable(fun, false) and true or false
end

--- If we have `local callable = require 'callable'` then we want to also use `callable` as a function.
--- We make the call to `callable(obj, ...)` be the same as calling `callable.callable(obj, ...)`.
local mt = {}
function mt.__call(_, ...) return M.callable(...) end
setmetatable(M, mt)

return M
