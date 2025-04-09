-----------------------------------------------------------------------------------------------------------------------
-- Lulu: Rudimentary path query methods.
--
-- Full Documentation:     https://nessan.github.io/lulu
-- Source Repository:      https://github.com/nessan/lulu
-- SPDX-FileCopyrightText: 2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------
local M = {}

-- The directory separator for the current platform.
local os_sep = package.config:sub(1, 1)

--- Returns the directory separator for the current platform.
function M.os_directory_separator()
    return os_sep
end

--- Returns `true` if the current platform is Windows, `false` otherwise.
function M.is_windows()
    return os_sep == '\\'
end

--- Returns `true` if the current platform is Unix, `false` otherwise.
function M.is_unix()
    return os_sep == '/'
end

--- Returns `true` if the current platform is POSIX, `false` otherwise.
function M.is_posix()
    return os_sep == '/'
end

--- Splits a path into its directory, basename, and file extension components.
--- @param path string  The path to split:                     e.g. `/Users/Jorge/test.lua`.
--- @return string dir  The directory part of the path:        e.g. `/Users/Jorge/`.
--- @return string base The filename part of the path:         e.g. `test.lua`.
--- @return string ext  The file extension part of the path:   e.g. `lua`.
--- **Note**: We ignore that fact that Unix files can have `\` in their names (rarely/never seen in practice).
function M.components(path)
    if not path or type(path) ~= 'string' then return "", "", "" end

    local pattern = "(.-)([^\\/]-%.?([^%.\\/]*))$"
    local dir, base, ext = path:match(pattern)
    if not dir then return "", "", "" end
    if dir == '' then dir = '.' .. os_sep end
    if ext == base then ext = '' end
    return dir, base, ext
end

--- Returns the directory part of a path.
--- @param path string The path to extract the directory from.
--- @return string dir The directory part of the path.
--- **Note**: We ignore that fact that Unix files can have `\` in their names (rarely/never seen in practice).
function M.dirname(path)
    local dir, _, _ = M.components(path)
    return dir
end

--- Returns the basename part of a path.
--- @param path string The path to extract the basename from.
--- @return string dir The directory part of the path.
--- **Note**: We ignore that fact that Unix files can have `\` in their names (rarely/never seen in practice).
function M.basename(path)
    local _, base, _ = M.components(path)
    return base
end

--- Returns the extension part of a path.
--- @param path string The path to extract the extension from.
--- @return string dir The directory part of the path.
--- **Note**: We ignore that fact that Unix files can have `\` in their names (rarely/never seen in practice).
function M.extension(path)
    local _, _, ext = M.components(path)
    return ext
end

--- Returns the basename for the path without its extension if there is one.
--- @param path string The path to extract the filename from.
--- @return string name The filename without its extension.
--- **Note**: We ignore that fact that Unix files can have `\` in their names (rarely/never seen in practice).
function M.filename(path)
    local _, base, ext = M.components(path)
    return #ext > 2 and base:sub(1, - #ext - 2) or base
end

--- Returns the path for the current script.
--- @return string path The path for the current script.
function M.script_path()
    return arg[0] or debug.getinfo(2, 'S').source:match("^@(.+)$")
end

--- Returns the name for the current script w/o any `.lua` extension.
--- @return string script_name The name of the current script without any extension.
function M.script_name()
    return M.filename(M.script_path())
end

--- Returns a path from a list of path segments.
--- @vararg string Path segments to join
--- @return string path The joined path
function M.join(...)
    local args = {...}
    if #args == 0 then return "" end

    local retval = args[1]
    for i = 2, #args do
        local segment = args[i]
        if segment:sub(1, 1) == os_sep then
            retval = segment
        else
            -- Add separator if needed
            if retval:sub(-1) ~= os_sep then
                retval = retval .. os_sep
            end
            retval = retval .. segment
        end
    end
    return retval
end

--- Returns `true` if a path exists in the filesystem.
--- @param path string The path to check
function M.exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

---  Returns `true` if a path exists in the filesystem and is a directory.
--- @param path string The path to check
function M.is_directory(path)
    -- Implementation depends on platform, but could use lfs or os.execute
    -- This is a simplified example
    if not M.exists(path) then return false end
    local success = os.execute('cd "' .. path .. '" 2>/dev/null')
    return success ~= nil
end

return M
