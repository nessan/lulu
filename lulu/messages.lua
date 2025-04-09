-----------------------------------------------------------------------------------------------------------------------
-- Lulu: Informational, warning, and error messages
--
-- Full Documentation:     https://nessan.github.io/lulu
-- Source Repository:      https://github.com/nessan/lulu
-- SPDX-FileCopyrightText: 2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------
local M        = {}

local scribe   = require("lulu.scribe")
local basename = require("lulu.paths").basename

--- Returns the function name, source file basename, and line number associated with a stack frame.
--- @param offset number? The offset of the required stack frame from *the caller* of `source_info`. Defaults to 0.
--- @return string func   The function name at that location.
--- @return string file   The basename for the source file that function can be found in.
--- @return number line   The line number in that file where we are looking at.
function M.source_info(offset)
    -- This method is in stack frame 1, the caller of this function is in stack frame 2, ...
    -- The offset is the number of desired frames above above the *caller* of this function.
    -- By default, we return information about the caller of this function, so the offset is 0.
    offset = offset and offset + 2 or 2
    local info = debug.getinfo(offset, "nlS")

    -- Can get an error if the offset is too high.
    if not info then return '<STACK-FRAME ERROR>', '<STACK-FRAME ERROR>', -1 end

    -- Otherwise we can return the function name, file name, and line number.
    local func = info.name or 'main'
    local file = basename(info.source) or M.script_basename()
    local line = info.currentline
    return func, file, line
end

--- Private function: Decorates a message with information about the source location of where that message came from.
--- @param ... any     The message that gets formatted using `string.format`. First arg. can be a numeric stack offset.
--- @return string msg The message decorated with the source location.
--- **Note**: This function is used internally by `message`, `info`, `warn`, and `fatal` to format the message.
local function decorate(...)
    local args = { ... }
    if #args == 0 then return 'LULU ERROR: `decorate()` called with no arguments!' end

    -- `decorate` is called from `M.message`, `M.info`, `M.warn`, or `M.fatal`. That is one level up from here.
    -- Those functions also have a caller, so we need to add 2 to the offset to get the minimum correct stack frame.
    -- In practice, `M.info`, `M.warn`, etc. may want to reference the stack frame of their own callers.
    -- They do that by passing a number as the first argument to `decorate` which will be used as additional offset.
    local has_offset = type(args[1]) == 'number'
    local offset = has_offset and args[1] + 2 or 2

    -- Grab the source info for the stack located at `offset` frames above us here.
    local func, file, line = M.source_info(offset)

    -- Perhaps we've used up all the arguments and there is no message to format -- just return the source info.
    if has_offset and #args == 1 then
        return string.format("'%s' (%s:%d)", func, file, line)
    end

    -- Otherwise we can format the message using the rest of the arguments, prepending the source info.
    local msg_index = has_offset and 2 or 1
    local msg = scribe.format(args[msg_index], table.unpack(args, msg_index + 1))
    return string.format("'%s' (%s:%d): %s\n", func, file, line, msg)
end

--- Write a general message to `stdout` decorated with the source location where the call was made from.
--- @param msg string|number The message to write *or* the stack offset of the caller.
--- @param ... any           Args to format the message if `msg` is a string or the whole message it is a number.
--- **Example:** `message("x = %d", 42)` -> "'main' (base.lua:61): x = 42"
function M.message(msg, ...)
    local str = decorate(msg, ...)
    io.stdout:write(str)
end

--- Write an informational message to `stdout` decorated with a tag & the source location where the call was made from.
--- @param msg string|number The message to write *or* the stack offset of the caller.
--- @param ... any           Args to format the message if `msg` is a string or the whole message it is a number.
--- **Example:** `info("x = %d", 42)` -> "[INFO] from 'main' (messages.lua:1): x = 42"
function M.info(msg, ...)
    local str = '[INFO] from ' .. decorate(msg, ...)
    io.stdout:write(str)
end

--- Write an warning message to `stdout` decorated with a tag & the source location where the call was made from.
--- @param msg string|number The message to write *or* the stack offset of the caller.
--- @param ... any           Args to format the message if `msg` is a string or the whole message it is a number.
---  **Example:** `warn("x = %d", 42)` -> "[WARNING] from 'main' (messages.lua:1): x = 42"
function M.warn(msg, ...)
    local str = '[WARNING] from ' .. decorate(msg, ...)
    io.stdout:write(str)
end

--- Write an fatal error message to `stderr` decorated with a tag & the source location where the call was made from.
--- @param msg string|number The message to write *or* the stack offset of the caller.
--- @param ... any           Args to format the message if `msg` is a string or the whole message it is a number.
--- **NOTE**: This function will exit the program after writing the message which is formatted to look important.
function M.fatal(msg, ...)
    local str = '[FATAL ERROR] from ' .. decorate(msg, ...)
    local line = string.rep("=", 100) .. '\n'
    io.stderr:write(line)
    io.stderr:write(str)
    io.stderr:write("The program will now exit ...\n")
    io.stderr:write(line)
    os.exit()
end

return M
