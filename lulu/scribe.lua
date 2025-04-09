-----------------------------------------------------------------------------------------------------------------------
-- scribe: Functions to convert Lua objects to readable strings along with output methods that use those functions.
--
-- Scribe's `object` -> `string` conversion functions can handle complex tables including ones with shared and
-- cyclical references. The strings for those tables have their structure shown in as readable a way as possible.
-- The output can be customized with a set of formatting options but we also provide many pre-defined formats.
--
-- The principal `object` -> `string` methods are:
-- 1. `scribe`:      Returns a string for any Lua object. Can be passed a table of custom formatting options.
-- 2. `inline`:      One-line string: arrays are delimited as "[...]" and general tables as "{...}".
-- 3. `pretty`:      Multiline string: uses the same delimiters as `inline`. Simple tables are inlined.
-- 6. `classic`:     Multiline string: all tables are delimited "{...}". Nothing is inlined
-- 7. `alt`:         Alternate multi-line string representation where there are no table delimiters shown.
-- 8. `json`:        JSON-like multi-line string representation of any Lua table.
-- 9. `inline_json`: Compact JSON-like one-line string representation of any Lua table.
--
-- We also provide a set of output methods that use `scribe` to format strings with placeholders for tables.
-- For example if `tbl = {1, 2, 3}` then `put("Table: %t", tbl)` will print "Table: {1, 2, 3}" to `stdout`.
--
-- The principal formatted output methods are:
-- 1. `format`:      Extends `string.format` to handle extra format specifiers for tables (see description below).
-- 2. `put`:         Prints a formatted string to `stdout`.
-- 3. `putln`:       Prints a formatted string followed by a newline to `stdout`.
-- 4. `eput`:        Prints a formatted string to `stderr`.
-- 5. `eputln`:      Prints a formatted string followed by a newline to `stderr`.
-- 6. `fput`:        Prints a formatted string to a file `f`.
-- 7. `fputln`:      Prints a formatted string followed by a newline to a file `f`.
--
-- The extra format specifiers recognized for tables are:
-- 1. `%t`  One-line: arrays delimited as `[...]`, general tables delimited as `{ ... }`.
-- 2. `%T`  Multiline: arrays delimited as `[...]`, general tables delimited as `{ ... }`. Simple ones are inlined.
-- 3. `%2T` Classic multiline string with all tables delimited as { ... ]. Nothing is inlined.
-- 4. `%3T` Alternate multiline string without delimiters. Structure shown only by indentation.
-- 7. `%9T` A debug string showing the table as a primitive AST (mostly for internal use).
-- 8. `%j`  Format the table as a compact one-line JSON string.
-- 9. `%J`  Format the table as an multiline JSON string.
--
-- Full Documentation:      https://nessan.github.io/scribe
-- Source Repository:       https://github.com/nessan/scribe
-- SPDX-FileCopyrightText:  2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------
local insert, sort, unpack = table.insert, table.sort, table.unpack

-----------------------------------------------------------------------------------------------------------------------
--- Private functions: Some of the workhorse methods for the publicly exported `scribe` and friends later.
-----------------------------------------------------------------------------------------------------------------------

--- Private function: Returns a copy of the potentially multiline input string `str` indented line by line.
--- @param str               string     The string to indent which may have multiple lines.
--- @param indent            string     The "tab" to use for indentation.
--- @param ignore_first_line boolean?   If `true` we don not indent the first line. Default is `false`.
--- @return string retval    A string with the same number of lines as `str` and each indented by `indent`
local function indent_string(str, indent, ignore_first_line)
    -- By default we indent all the input lines
    ignore_first_line = ignore_first_line or false

    -- Handle some edge cases ...
    if not indent or indent == "" or not str or str == "" then return str end

    -- Does the input string finish with a newline character?
    local ends_with_newline = str:sub(-1) == "\n"

    -- Build up the indented copy line by line in a table.
    local lines = {}
    local first_line = true
    for line in str:gmatch("[^\r\n]+") do
        local tab = first_line and ignore_first_line and '' or indent
        table.insert(lines, tab .. line)
        first_line = false
    end
    local retval = table.concat(lines, "\n")
    if ends_with_newline then retval = retval .. "\n" end
    return retval
end

--- Private function: Returns a simple string representation of any Lua `obj`.
--- @param obj any The object to convert to a string which we expect is *not* a `table`.
--- @return string str A string representation of `obj`.
--- - If `obj` is a table, we return its address as a string. <br>
--- - If `obj` is a string, we return a quoted version.
local function simple_string(obj)
    if obj == nil then return 'nil' end
    local obj_type = type(obj)
    if obj_type == 'number' or obj_type == 'boolean' or obj_type == nil then
        return tostring(obj)
    elseif obj_type == 'string' then
        return string.format("%q", obj)
    elseif obj_type == 'table' then
        return string.format("%p", obj)
    elseif obj_type == 'function' then
        return '<function>'
    elseif obj_type == 'userdata' then
        return '<userdata>'
    elseif obj_type == 'thread' then
        return '<thread>'
    else
        -- Just in case future Lua adds a ninth type ...
        return '<UNKNOWN type: ' .. tostring(obj) .. '>'
    end
end

--- Private function: Returns a string like `{}` that is appropriate for an empty table.
--- @param opts table  The formatting options. We use just two of the fields.
--- @return string str A string like `{}`.
local function empty_table_string(opts)
    -- The Lua pattern matches all white space both horizontal and vertical.
    local retval = (opts.table_begin .. opts.table_end):gsub('%s+', '')
    return retval
end

--- Private function: Default comparator we use to sort keys in tables -- first by type and then by value.
--- @param a any The first object to compare.
--- @param b any The second object to compare.
--- @return boolean `true` if `a` should come before `b`.
local function compare(a, b)
    -- First compare types and then by value. Happily the `number` type comes alphabetically before `string`.
    local ta, tb = type(a), type(b)
    if ta ~= tb then
        return ta < tb
    elseif ta == 'table' or ta == 'boolean' or ta == 'function' then
        return tostring(a) < tostring(b)
    else
        return a < b
    end
end

--- Private function: Returns three pieces of data about the top-level in a table
--- @param tbl         table    The table of interest.
--- @param comparator? function A comparator used to sort the keys if needed. The default sorts by type and then value.
--- @return boolean  array This is `true` if `tbl` is a Lua array.
--- @return number   size  The number of top-level elements in `tbl`.
--- @return function iter  A suitable iterator for this table.
--- **Note** The iterator for a Lua array will always be `ipairs`.
local function top_level_metadata(tbl, comparator)
    -- Perhaps we weren't asked to provide an ordered iterator? We can skip collecting keys in that case.
    if comparator == false then
        local array, size = true, 0
        for _ in pairs(tbl) do
            size = size + 1
            if array and tbl[size] == nil then array = false end
        end
        -- Pick the appropriate iterator for this table depending on whether it is an array or not.
        local iter = array and ipairs or pairs
        return array, size, iter
    end

    -- Otherwise, for a general table we will need to capture the table's keys in an array.
    local array, size, keys = true, 0, {}
    for k, _ in pairs(tbl) do
        size = size + 1
        if array and tbl[size] == nil then array = false end
        insert(keys, k)
    end

    -- If the table is an array we always use the the `ipairs` iterator. Forget about the keys.
    if array then return array, size, ipairs end

    -- Have a general key-value table: Sort the keys, either using the default comparator or a custom one.
    if comparator == nil then comparator = compare end
    sort(keys, comparator)

    -- Create a custom iterator as a closure that captures that sorted array of keys.
    local iter = function(t)
        local i = 0
        return function()
            i = i + 1
            return keys[i], t[keys[i]]
        end
    end

    -- Return the trio of top-level metadata items that includes the custom iterator.
    return array, size, iter
end

--- Private function: Returns a table of metadata for the argument and all its sub-table.
--- @param root_tbl table       The table to examine.
--- @param comparator? function The comparator to use for sorting the keys. The default sorts by type and then value.
--- @return table md A table with a sub-table `md[t]` for each sub-table `t` encountered in `tbl` including itself.
--- - `md[t].array`  Boolean that is `true` if `t` is a Lua array (i.e., indexed from 1 with no holes).
--- - `md[t].size`   Number of elements in `t`. This is the number of key-value pairs in `t`.
--- - `md[t].iter`   A suitable iterator that takes into account the `comparator` (always `ipairs` for a Lua array).
--- - `md[t].subs`   Number of sub-tables in `t`. Path references do not count to this total.
--- - `map[t].refs`  Number of references to `t`. Greater than 1 if `t` is shared.
local function metadata(root_tbl, comparator)
    -- Space for all the metadata.
    local md = {}

    -- All tables have at least one reference. Add one for the root in case it is referenced by an immediate child.
    md[root_tbl] = { refs = 1 }

    -- The recursive workhorse processes a `tbl` using a breadth first traversal.
    local function process(tbl)
        -- Grab the top-level data for this table.
        md[tbl].array, md[tbl].size, md[tbl].iter = top_level_metadata(tbl, comparator)

        -- Breath first traversal so keep track of any unprocessed children to process later.
        local subs, sub_tables = 0, {}
        local iter = md[tbl].iter
        for _, v in iter(tbl) do
            -- From the metadata perspective, we only care about elements that are tables.
            if type(v) == 'table' then
                if md[v] then
                    -- Seen `v` before so increment the reference count -- `v` will be output as a path reference.
                    md[v].refs = md[v].refs + 1
                else
                    -- Haven't seen `v` before so it's a genuine sub-table.
                    subs = subs + 1
                    -- Add `v` to the array of tables to process later.
                    table.insert(sub_tables, v)
                    -- Give `v` a metadata entry in case an immediate sibling has a reference to it.
                    md[v] = { refs = 1 }
                end
            end
        end
        md[tbl].subs = subs

        -- Process all the sub-tables. Next time it will the grandchildren etc.
        for _, sub_table in ipairs(sub_tables) do process(sub_table) end
    end

    -- Kick things off by processing the root table.
    process(root_tbl)
    return md
end

--- Private function: Converts a table to a readable string base on a table of format options.
--- @param root_tbl table The table to convert to a string.
--- @param opts     table The formatting options to use in that conversion.
--- @return string retval The string representation of the `root_tbl`
local function table_string(root_tbl, opts)
    -- Compute the metadata for `root_tbl`.
    local md = metadata(root_tbl, opts.comparator)

    -- Localise some format fields that do not depend on context.
    local kb, ke = opts.key_begin, opts.key_end
    local pb, pe = opts.path_begin, opts.path_end

    -- The main recursive workhorse that build up a string representation of a table`tbl`.
    local function process(tbl, path)
        -- Perhaps `tbl` has a custom `__tostring` method we are allowed to use?
        if opts.use_metatable then
            local mt = getmetatable(tbl)
            if mt and mt.__tostring then return mt.__tostring(tbl) end
        end

        -- We will add a string `path` field to the metadata for `tbl`.
        -- If we see multiple references to `tbl` this is the string we use after it gets defined.
        md[tbl].path = path
        local path_prefix = path == opts.path_root and '' or path .. opts.path_sep

        -- If `tbl` is empty we can exit early.
        local size = md[tbl].size
        if size == 0 then return empty_table_string(opts) end

        -- If `tbl` is a Lua array then typically we suppress showing the indices/keys.
        local array = md[tbl].array
        local show_keys = not array and true or opts.show_indices

        -- If `tbl` has no sub-tables and is "small", we will inline it no matter what `opts.indent` is set to.
        local simple = md[tbl].subs == 0 and size < opts.inline_size
        local indent = simple and '' or opts.indent

        -- Localise some delimiters to values that may depend on the type of `tbl`.
        local tb = array and opts.array_begin or opts.table_begin
        local te = array and opts.array_end or opts.table_end

        -- If there is no indentation then the newline parameter `nl` is just the blank string.
        local nl = indent == '' and opts.inline_spacer or '\n'
        local sep = opts.sep .. nl

        -- Generally in multiline output there are new lines after the table delimiters.
        -- That is not the case if those delimiters are just empty strings.
        local delims = tb ~= ''
        if delims then tb, te = tb .. nl, nl .. te else indent = '' end

        -- We will traverse `tbl` breadth first and keep track of unprocessed sub-tables in `children`
        local children = {}

        -- We will build up the `content` string for `tbl` element by element
        local content = ''

        -- Grab the appropriate iterator used to traverse the top-level elements in `tbl`
        local i, iter = 0, md[tbl].iter
        for k, v in iter(tbl) do
            i = i + 1

            -- Generally we do not show array indices but may need to if the associated value is shared.
            local show_key = show_keys

            -- The value string associated with this key/index:
            local v_string = ''
            if type(v) == 'table' then
                if md[v].path then
                    -- `v` is a shared table with a known reference path that we use here.
                    v_string = pb .. md[v].path .. pe
                else
                    -- We do not have a reference path for `v` so we create one and store it in `md[tbl]`
                    local v_path = path_prefix .. tostring(k)
                    md[v].path = v_path

                    -- `v` hasn't been processed so add it to the table of things to do later:
                    children[v] = v_path

                    -- Until `v` is defined with a proper string we use its address as  placeholder to replace later.
                    v_string = simple_string(v)

                    -- If `v` is a shared table we better show the associated key no matter what
                    if md[v].refs > 1 then show_key = true end

                    -- In multiline formats we generally put a new line between the key and value:
                    if delims == false and show_key then v_string = nl .. v_string end
                end
            else
                -- `v` is a non-table object that we process with `simple_string`
                v_string = v_string .. simple_string(v)
            end

            -- If `v` is shared and we are going to define it here we better also show the associate key.
            local k_string = show_key and kb .. tostring(k) .. ke or ''

            -- Append this full element with the indent to the table content.
            content = content .. indent .. k_string .. v_string

            -- If this isn't the final element we add an element separator.
            if i < size then content = content .. sep end
        end

        -- Wrap the full table content in table begin and end delimiters.
        local retval = tb .. content .. te

        -- Handle unprocessed child tables.
        for child_table, child_path in pairs(children) do
            -- Recurse to get a full definition string for this child.
            local child_string = process(child_table, child_path)

            -- Its a sub-table so we need to indent it appropriately.
            child_string = indent_string(child_string, opts.indent, delims)

            -- The child is currently just an address placeholder in the table string that needs replacing.
            local placeholder = simple_string(child_table)
            retval = retval:gsub(placeholder, child_string)
        end

        -- Finished with `tbl`
        return retval
    end

    -- Kick things off by processing the root table.
    local retval = process(root_tbl, opts.path_root)

    -- If there is a self-reference to the root table we prepend something like "<table> = " to the output.
    if md[root_tbl].refs > 1 then
        -- Make sure not to add the prefix if it is already there.
        local self_ref_prefix = pb .. opts.path_root .. pe .. ' = '
        if not retval:find('^' .. self_ref_prefix) then
            retval = self_ref_prefix .. retval
        end
    end

    -- All done.
    return retval
end

--- Private function: Fills the formatting options table `opts` from the *complete* formatting table `from`.
--- @param opts  table The potentially incomplete table of formatting options.
--- @params from table A complete table formatting options. Missing fields in `opts` get filled from here.
--- **Note** This is a private function so we *assume* `from` is complete. No check is done.
local function complete_options_table(opts, from)
    for k, v in pairs(from) do
        if opts[k] == nil then opts[k] = v end
    end
end

-----------------------------------------------------------------------------------------------------------------------
--- The publicly exported `scribe` function and friends
-----------------------------------------------------------------------------------------------------------------------
local M = {}

--- Returns a shallow clone of the argument. This is useful for copying tables of formatting options.
--- @param tbl table The object to clone which we expect to be a table.
function M.clone(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local retval = {}
    for k, v in pairs(tbl) do retval[k] = v end
    return retval
end

-- We store 'standard' tables of formatting options inside this module under the parent key `options`.
M.options = {}

--- Formatting options used to turn a table into a "pretty" multiline string (see `M.pretty`).
M.options.pretty = {
    indent        = '    ',    -- Indent elements by four spaces.
    table_begin   = '{',       -- Left delimiter for general tables. Classically tables look like "{ ... }"
    table_end     = '}',       -- Right delimiter for general tables.
    array_begin   = '[',       -- Left delimiter for tables that are Lua arrays.
    array_end     = ']',       -- Right delimiter for tables that are Lua arrays.
    key_begin     = '',        -- Key left delimiter. E.g., JSON uses double quotes for keys.
    key_end       = ' = ',     -- Key right delimiter including any assignment operator.
    sep           = ',',       -- How to separate table "elements" (i.e. how to separate key-value pairs).
    inline_spacer = ' ',       -- Extra space between inline table/array delims and contents: "{ ... }" vs. "{...}".
    show_indices  = false,     -- Whether to show the boring index keys [1], [2], ...  for Lua arrays.
    inline_size   = math.huge, -- If indenting, still inline simple tables with no sub-tables and less than this size.
    comparator    = compare,   -- The function used to sort table keys. Set to `false` to disable sorting.
    path_root     = 'table',   -- Name for the ultimate parent anchoring references to shared tables.
    path_sep      = '.',       -- The separator used in paths for shared tables e.g. "<foo.bar.baz>"
    path_begin    = '<',       -- Left delimiter for any path references.
    path_end      = '>',       -- Right delimiter for any path references.
    use_metatable = true,      -- Whether we should invoke any custom  `__tostring` metamethod.
    COMPLETE      = true       -- This marker indicates that the format options table is fully defined.
}

--- Formatting options used to turn a table into a one-line string (see `M.inline`).
M.options.inline = M.clone(M.options.pretty)
M.options.inline.indent = ''

--- Formatting options used to turn a table into a "classic" multiline string (see `M.classic`).
--- All tables are delimited using curly braces, and all elements are on separate lines.
M.options.classic = M.clone(M.options.pretty)
M.options.classic.array_begin = '{'
M.options.classic.array_end = '}'
M.options.classic.inline_size = 0

--- Formatting options used to turn a table into an "alternate" multiline string (see `M.alt`).
--- In this format, table structure is shown by indentation alone and no table delimiters are used.
M.options.alt = M.clone(M.options.pretty)
M.options.alt.table_begin = ''
M.options.alt.table_end = ''
M.options.alt.array_begin = ''
M.options.alt.array_end = ''
M.options.alt.key_end = ': '
M.options.alt.inline_size = 0

--- Formatting options used to turn a table into a "JSON" multiline string (see `M.json`).
M.options.json = M.clone(M.options.pretty)
M.options.json.key_begin = '"'
M.options.json.key_end = '": '
M.options.json.inline_size = 0

--- Formatting options used to turn a table into a compact one-line JSON-like string (see `M.inline_json`).
M.options.inline_json = M.clone(M.options.json)
M.options.inline_json.indent = ''
M.options.inline_json.key_end = '":'
M.options.inline_json.inline_spacer = ''

--- Formatting options used to turn a table into a multiline "Abstract Syntax Tree" string (see `M.debug`).
--- This format exposes how our main `table_string` function sees the structure ot a table.
--- Can be useful if you are developing your own table of custom formatting options.
M.options.debug = M.clone(M.options.pretty)
M.options.debug.indent = ' INDENT '
M.options.debug.table_begin = 'TABLE_BEGIN'
M.options.debug.table_end = 'TABLE_END'
M.options.debug.array_begin = 'ARRAY_BEGIN'
M.options.debug.array_end = 'ARRAY_END'
M.options.debug.key_begin = ' KEY_BEGIN "'
M.options.debug.key_end = '" KEY_END = '
M.options.debug.sep = ' SEP '
M.options.debug.show_indices = true
M.options.debug.inline_size = 0

--- The default format spec used by the module on blind calls like `scribe(obj)` is the inline format.
M.options.default = M.options.inline

--- Returns a string representation of any Lua object.
--- @param obj        any     The Lua object in question.
--- @param opts?      table   Optional table of formatting parameters (default is `M.options.default`).
--- @param overrides? table   Optional table of overrides for the formatting parameters.
--- @return string    str     The string representation of the object.
--- **Note:** If we are passed `overrides` it will come back as a full set of formatting parameters.
function M.scribe(obj, opts, overrides)
    -- Handle non-table objects up-front.
    if type(obj) ~= 'table' then return simple_string(obj) end

    -- Second and third args missing we use whatever has been set as the default format for tables.
    if opts == nil then return table_string(obj, M.options.default) end

    -- Second arg is present, so better check the formatting parameters in that arg are complete,
    if not opts.COMPLETE then
        -- Fill missing fields from the default inline/multiline choices
        local from = opts.indent == '' and M.options.inline or M.options.pretty
        complete_options_table(opts, from)
    end

    -- If there were no overrides we can go ahead and use our now sure-to-be-full `opts` parameters.
    if overrides == nil then return table_string(obj, opts) end

    -- Third arg is present, so fill it out if needed from the now complete second arg. Then use it.
    if not overrides.COMPLETE then complete_options_table(overrides, opts) end
    return table_string(obj, overrides)
end

--- Returns an inline string representation of any Lua object.
--- @param obj        any The object to convert to a string.
--- @param overrides? any Optional table of overrides for the default formatting options.
--- @param name?      any Optional name for the object which we embed in the string if present
--- @return string    str     The string representation of the object.
--- **Note:** If we are passed `overrides` it will come back as a full set of formatting parameters.
function M.inline(obj, overrides, name)
    if type(overrides) == 'string' then name, overrides = overrides, name end
    local str = M.scribe(obj, M.options.inline, overrides)
    if name then str = name .. str end
    return str
end

--- Returns a "pretty" multiline string representation of any object.
--- @param obj        any The object to convert to a string.
--- @param overrides? any Optional table of overrides for the default formatting options.
--- @param name?      any Optional name for the object which we embed in the string if present
--- @return string str A "pretty" string representation of the object.
--- **Note:** If we are passed `overrides` it will come back as a full set of formatting options.
function M.pretty(obj, overrides, name)
    if type(overrides) == 'string' then name, overrides = overrides, name end
    local str = M.scribe(obj, M.options.pretty, overrides)
    if name then str = name .. str end
    return str
end

--- Returns the "classic" multiline string representation of any object.
--- @param obj        any The object to convert to a string.
--- @param overrides? any Optional table of overrides for the default formatting options.
--- @param name?      any Optional name for the object which we embed in the string if present
--- @return string str The "classic" string representation of the object.
--- **Note:** If we are passed `overrides` it will come back as a full set of formatting options.
function M.classic(obj, overrides, name)
    if type(overrides) == 'string' then name, overrides = overrides, name end
    local str = M.scribe(obj, M.options.classic, overrides)
    if name then str = name .. str end
    return str
end

--- Returns an multiline string representation of any object.
--- @param obj        any The object to convert to a string.
--- @param overrides? any Optional table of overrides for the default formatting options.
--- @param name?      any Optional name for the object which we embed in the string if present
--- @return string str  The alternate string representation of the object.
--- **Note:** If we are passed `overrides` it will come back as a full set of formatting options.
function M.alt(obj, overrides, name)
    if type(overrides) == 'string' then name, overrides = overrides, name end
    local str = M.scribe(obj, M.options.alt, overrides)
    if name then str = name .. str end
    return str
end

--- Returns a JSON string representation of the object `obj` with an optional embedded `name`.
--- @param obj        any The object to convert to a string.
--- @param overrides? any Optional table of overrides for the default formatting options.
--- @param name?      any Optional name for the object which we embed in the string if present
--- @return string str The JSON string representation of the object.
--- **Note:** If we are passed `overrides` it will come back as a full set of formatting options.
function M.json(obj, overrides, name)
    if type(overrides) == 'string' then name, overrides = overrides, name end
    local str = M.scribe(obj, M.options.json, overrides)
    if name then str = '{"' .. name .. '": ' .. str .. '}' end
    return str
end

--- Returns an inline JSON string representation of the object `obj` with an optional embedded `name`.
--- @param obj        any The object to convert to a string.
--- @param overrides? any Optional table of overrides for the default formatting options.
--- @param name?      any Optional name for the object which we embed in the string if present
--- @return string str The JSON string representation of the object.
--- **Note:** If we are passed `overrides` it will come back as a full set of formatting options.
function M.inline_json(obj, overrides, name)
    if type(overrides) == 'string' then name, overrides = overrides, name end
    local str = M.scribe(obj, M.options.inline_json, overrides)
    if name then str = '{"' .. name .. '": ' .. str .. '}' end
    return str
end

--- Returns a string representation of the object `obj` with the table structure exposed.
--- @param obj        any The object to convert to a string.
--- @param overrides? any Optional table of overrides for the default formatting options.
--- @param name?      any Optional name for the object which we embed in the string if present
--- @return string str The "debug" string representation of the object.
--- **Note:** If we are passed `overrides` it will come back as a full set of formatting options.
function M.debug(obj, overrides, name)
    if type(overrides) == 'string' then name, overrides = overrides, name end
    local str = M.scribe(obj, M.options.debug, overrides)
    if name then str = name .. str end
    return str
end

-----------------------------------------------------------------------------------------------------------------------
--- Formatted output methods that use `scribe`.
--- We add "%t", "%T", "%j", and "%J" as formatting specifiers for printing inline and multiline tables.
-----------------------------------------------------------------------------------------------------------------------

--- The workhorse that extends `string.format` with the ability to format tables.
--- @param template string? The "recipe"" we fill out with formatted values (e.g. "Hello, %s!").
--- @param ...      any     Trailing args should be the values for the placeholders in `template`.
--- @return string str      The fully formatted string or an error string if something is mis-specified.
--- Simple usage: `format("Hello, %s!", "world")` returns "Hello, world!".      <br>
--- Table usage:  `format("Table: %t", {1, 2, 3})` returns "Table: {1, 2, 3}".
--- #### Format Specifiers for Tables:
--- - `%t`  One-line:  Arrays delimited by `[...]`, name-value tables delimited by `{ ... }`.
--- - `%T`  Multiline: Same delimiters as `%t`. Simple tables are inlined.
--- - `%2T` Multiline: All tables delimited as `{ ... }`. Nothing is inlined.
--- - `%3T` Multiline: No table delimiters. Structure shown only by indentation.
--- - `%9T` Multiline: A debug string showing the table as a primitive AST (mostly for internal use).
--- - `%j`  One-line:  Format the table as a compact one-line JSON string.
--- - `%J`  Multiline: Format the table as a readable multiline JSON string.
function M.format(template, ...)
    -- Edge case:
    if template == nil then return "" end

    -- Regular expressions that match on the placeholders in a format string like "%5.2f" or "%s".
    -- Format strings all have the form %[modifiers][specifier] where the specifier is 's' for string etc.
    -- We extend this to allow for table placeholders in the form %[modifiers][table_specifier]
    -- This regex found on web and may not cover all edge cases that can exist in format specifiers.
    local percent_rx = '%%+'
    local modifier_rx = '[%-%+ #0]?%d*%.?[%d%*]*[hljztL]?[hl]?'
    local specifier_rx = '[diuoxXfFeEgGaAcspqtTjJ]'
    local placeholder_rx = string.format('%s(%s)(%s)', percent_rx, modifier_rx, specifier_rx)
    local table_rx = percent_rx .. '%d*[tTjJ]'

    -- Perhaps we can just punt the whole thing to `string.format` and return early?
    if not template:find(table_rx) then return string.format(template, ...) end

    -- There are some table placeholders in the template that we need to handle.
    local table_placeholders = {}
    local n_placeholders = 0
    for mod, spec in template:gmatch(placeholder_rx) do
        n_placeholders = n_placeholders + 1
        if spec == 't' or spec == 'T' or spec == 'j' or spec == 'J' then
            insert(table_placeholders, { n_placeholders, mod, spec })
        end
    end

    -- Check that the total number of placeholders is equal to the number of trailing arguments.
    local args = { ... }
    if #args ~= n_placeholders then
        return string.format("[FORMAT ERROR]: %q -- needs %d args but you sent %d!\n", template, n_placeholders, #args)
    end

    -- Replace trailing table arguments associated with table placeholders by appropriate strings.
    for i = 1, #table_placeholders do
        local index, mod, spec = unpack(table_placeholders[i])
        local full_spec = mod .. spec
        local tbl = args[index]

        -- How we format the table depends on the full specifier.
        -- If the table has its own `inline` method then we use that, otherwise we use the `scribe.inline` method, etc.
        if full_spec == 't' then
            args[index] = tbl.inline and tbl:inline() or M.inline(tbl)
        elseif full_spec == 'T' then
            args[index] = tbl.pretty and tbl:pretty() or M.pretty(tbl)
        elseif full_spec == '2T' then
            args[index] = tbl.classic and tbl:classic() or M.classic(tbl)
        elseif full_spec == '3T' then
            args[index] = tbl.alt and tbl:alt() or M.alt(tbl)
        elseif full_spec == 'J' then
            args[index] = tbl.json and tbl:json() or M.json(tbl)
        elseif full_spec == 'j' then
            args[index] = tbl.inline_json and tbl:inline_json() or M.inline_json(tbl)
        elseif full_spec == '9T' then
            args[index] = tbl.debug and tbl:debug() or M.debug(tbl)
        else
            return string.format("[FORMAT ERROR]: %q -- unknown table specifier: %q\n", template, full_spec)
        end
    end

    -- In the template itself we can now replace the '%t' and '%T' placeholders etc. with a simple '%s'.
    template = template:gsub(table_rx, '%%s')
    return string.format(template, unpack(args))
end

--- @class string
--- @field scribe function Converts a template string with placeholders into a formatted string.

--- We add the extended format method to Lua's `string` object under the name `scribe`.
--- @param self string The template we fill out with formatted values (e.g. "Hello, %s!").
--- @param ... any     Trailing args should be the values for the placeholders in `template`.
--- @return string str The fully formatted string or an error string if something is mis-specified.
function string:scribe(...)
    return M.format(self, ...)
end

--- Prints a formatted string to `stdout`.
--- @param template string? The template we fill out with formatted values (e.g. "Hello, %s!").
--- @param ...      any:    The arguments to all the referenced placeholders in the template string.
--- Simple usage: `put("Hello, %s!", "world")`  prints "Hello, world!". <br>
--- Table usage:  `put("Table: %t", {1, 2, 3})` prints "Table: { 1, 2, 3 }".
function M.put(template, ...)
    io.stdout:write(M.format(template, ...))
end

--- Prints a formatted string followed by a newline to `stdout`.
--- @param template string? The template we fill out with formatted values (e.g. "Hello, %s!").
--- @param ...      any:    The arguments to all the referenced placeholders in the template string.
--- Simple usage: `putln("Hello, %s!", "world")`  prints "Hello, world!\n". <br>
--- Table usage:  `putln("Table: %t", {1, 2, 3})` prints "Table: { 1, 2, 3 }\n".
function M.putln(template, ...)
    io.stdout:write(M.format(template, ...), '\n')
end

--- Prints a formatted string to `stderr`.
--- @param template string? The template we fill out with formatted values (e.g. "Hello, %s!").
--- @param ...      any:    The arguments to all the referenced placeholders in the template string.
--- Simple usage: `eput("Hello, %s!", "world")`  prints "Hello, world!" to `stderr` <br>
--- Table usage:  `eput("Table: %t", {1, 2, 3})` prints "Table: { 1, 2, 3 }" to `stderr`.
function M.eput(template, ...)
    io.stderr:write(M.format(template, ...))
end

--- Prints a formatted string followed by a newline to `stderr`.
--- @param template string? The template we fill out with formatted values (e.g. "Hello, %s!").
--- @param ...      any:    The arguments to all the referenced placeholders in the template string.
--- Simple usage: `eputln("Hello, %s!", "world")`  prints "Hello, world!\n". <br>
--- Table usage:  `eputln("Table: %t", {1, 2, 3})` prints "Table: { 1, 2, 3 }\n".
function M.eputln(template, ...)
    io.stderr:write(M.format(template, ...), '\n')
end

--- Prints a formatted string to a file `f`.
--- @param f        file*:  The file handle we write to.
--- @param template string? The template we fill out with formatted values (e.g. "Hello, %s!").
--- @param ...      any:    The arguments to all the referenced placeholders in the template string.
--- Simple usage: `fput(f, "Hello, %s!", "world")`  prints "Hello, world!" to the file `f` <br>
--- Table usage:  `fput(f, "Table: %t", {1, 2, 3})` prints "Table: { 1, 2, 3 }" to the file `f`.
function M.fput(f, template, ...)
    f:write(M.format(template, ...))
end

--- Prints a formatted string followed by a newline  to a file `f`.
--- @param f file* The file we write to.
--- @param template string? The template we fill out with formatted values (e.g. "Hello, %s!").
--- @param ...      any:    The arguments to all the referenced placeholders in the template string.
--- Simple usage: `fputln(f, "Hello, %s!", "world")`  prints "Hello, world!\n" to the file `f` <br>
--- Table usage:  `fputln(f, "Table: %t", {1, 2, 3})` prints "Table: { 1, 2, 3 }\n" to the file `f`.
function M.fputln(f, template, ...)
    f:write(M.format(template, ...), '\n')
end

--- We also add the formatted output methods to Lua's `file*` handles.
--- This is done by adding the methods to the `index` metatable of the `io.stdout` object.
--- @class file*
--- @field put   function Prints a formatted string to a file.
--- @field putln function Prints a formatted string followed by a newline to a file.
local io_index_table = getmetatable(io.stdout).__index

--- Prints a formatted string to a Lua `file` handle.
--- @param self file*       The file we write to.
--- @param template string? The template we fill out with formatted values (e.g. "Hello, %s!").
--- @param ...      any:    The arguments to all the referenced placeholders in the template string.
--- Simple usage: `f:put(f, "Hello, %s!", "world")`  prints "Hello, world!" to the file `f` <br>
--- Table usage:  `f:put(f, "Table: %t", {1, 2, 3})` prints "Table: { 1, 2, 3 }" to the file `f`.
function io_index_table:put(template, ...)
    self:write(M.format(template, ...))
end

--- Prints a formatted string followed by a newline to a Lua `file` handle.
--- @param self file*       The file we write to.
--- @param template string? The template we fill out with formatted values (e.g. "Hello, %s!").
--- @param ...      any:    The arguments to all the referenced placeholders in the template string.
--- Simple usage: `f:putln("Hello, %s!", "world")`  prints "Hello, world!\n" to the file `f` <br>
--- Table usage:  `f:putln("Table: %t", {1, 2, 3})` prints "Table: { 1, 2, 3 }\n" to the file `f`.
function io_index_table:putln(template, ...)
    self:write(M.format(template, ...), '\n')
end

--- If we have `local scribe = require 'scribe'` then we want to also use `scribe` as a function.
--- We make the call to `scribe(obj, ...)` be the same as calling `scribe.scribe(obj, ...)`.
local mt = {}
function mt.__call(_, ...) return M.scribe(...) end

setmetatable(M, mt)

return M
