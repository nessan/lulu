-----------------------------------------------------------------------------------------------------------------------
-- Quarto extension to allow us to replace e.g. {{< var site >}} with the simpler {site}.
--
-- SPDX-FileCopyrightText:  2024 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
--- Helper functions
-----------------------------------------------------------------------------------------------------------------------
local stringify = pandoc.utils.stringify

--- Returns true if the string is nil or empty.
--- @param str string The string to check.
local function is_empty(str) return str == nil or str == '' end

--- Escapes all characters in a string so that it can be used literally in a regex.
--- @param str string The string to escape.
--- @return string str The escaped string.
--- @return number count The number of characters escaped.
--- #### Note
--- The character `%´ works as an escape for the various "magic" characters in a lua regex.
--- For example, in a regex '.' matches any character but '%.' matches a literal dot.
--- The escape `%´ can also be used for all ordinary characters so '%x' is just 'x'.
--- To ensure a string is interpreted as a literal pattern can just add those escapes everywhere.
local function literal(str) return str:gsub("([^%.])", "%%%1") end

--- Splits a string into a table of substrings.
--- @param str string The string to split.
--- @param sep string The separator to split on. Defaults to a space.
--- @param allow_empty? boolean If true, empty strings are allowed in the result.
--- @return string[] fields The array of substrings.
local function split(str, sep, allow_empty)
    sep = sep or " "
    local fields = {}
    local pattern
    if allow_empty == true then
        pattern = string.format("([^%s]*)", literal(sep))
    else
        pattern = string.format("([^%s]+)", literal(sep))
    end
    local _ignored = string.gsub(str, pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

--- Encode a string to hex.
--- @param str string The string to encode.
--- @return string hex The hex encoded string.
--- See: https://stackoverflow.com/questions/65476909/lua-string-to-hex-and-hex-to-string-formulas
local function hex_encode(str) return (str:gsub(".", function(char) return string.format("%02x", char:byte()) end)) end

--- Decode a string from hex.
--- @param hex string The hex encoded string to decode.
--- @return string str The decoded string.
--- See: https://stackoverflow.com/questions/65476909/lua-string-to-hex-and-hex-to-string-formulas
local function hex_decode(hex) return (hex:gsub("%x%x", function(digits) return string.char(tonumber(digits, 16)) end)) end

-----------------------------------------------------------------------------------------------------------------------
-- Functions that set parameters which effect how this filter works.
-----------------------------------------------------------------------------------------------------------------------

--- Quarto stores the values it reads from the  project's `_variables.yml` file under this metadata key. <br>
--- NOTE: This value could change as we're using an undocumented feature of Quarto.
local quarto_key = "_quarto-vars"

--- We keep our own handle to the Quarto variables table -- it gets set in the `init_filter(meta)` function.
local vars = {}

--- Variables are recognized in markup as a variable name surrounded by curly braces e.g. `{var}`.
--- In the future, we may let the user change this using a filter parameter but for now we hard code it.
local var_prefix = '{'
local var_suffix = '}'

--- Given the values for `var_prefix` and `var_suffix` return the Lua pattern used capture a variable name.
local function set_patterns()
    -- The var_prefix/var_suffix may have "magic" characters that we need to escape so we escape all their characters!
    local key_pattern = literal(var_prefix) .. '(.-)' .. literal(var_suffix)

    -- The full pattern we use to recognize a variable reference in a string allows for text before and after the name.
    -- For example, "({var})" or "{var}..." or "text-{var}" etc.
    local text_pattern = '(.*)' .. key_pattern .. '(.*)'

    -- We also need to handle the case where the variable is a URL: E.g.,`url: "https://google.com"`.
    -- In markup we might have a reference to such a variable as `[Google]({url})`.
    -- Pandoc turns that target into "%7Bhttps://google.com%7D" (i.e. hexes the braces and adds '%'s like HTML)
    -- This means we need to pattern match on the hex encoded and escaped version of our braced pattern
    local hex_prefix = '%' .. hex_encode(var_prefix)
    local hex_suffix = '%' .. hex_encode(var_suffix)
    local html_pattern = literal(hex_prefix) .. '(.-)' .. literal(hex_suffix)

    return text_pattern, html_pattern
end

--- Set the Lua pattern used to identify keys for replacement in markup.
--- The pattern is set based on the current values of `var_prefix` and `var_suffix`.
--- The pattern allows for text before and after the variable key itself.
local text_pattern, html_pattern = set_patterns()

--- Initialize the filter by grabbing the variables table from Quarto.
--- @param meta table The metadata table passed to the filter.
--- In the future, we may let the user change the way a variable key is recognized by using a filter parameter.
local function init_filter(meta)
    -- Grab the variables table from Quarto
    vars = meta[quarto_key]
    -- quarto.log.output(vars)

    -- Issue a warning if the variable table is empty.
    if not vars then
        local msg = "WARNING: Failed to find any variable definitions under the key: '" .. quarto_key .. "'\n"
        io.stderr:write(msg)
    end
end

-----------------------------------------------------------------------------------------------------------------------
-- Functions used to turn variable names into variable values.
-----------------------------------------------------------------------------------------------------------------------

--- Returns the replacement string for a `name` from our vars table or `nil` if `name` is not a var.
--- @param name string The name of the variable to look up.
--- @return string|nil The value of the variable or `nil` if the variable is not defined.
local function var(name)
    local keys = split(name, ".")
    local value = nil
    for _, key in ipairs(keys) do
        if value == nil then
            value = vars[key]
        else
            local k = tonumber(key) or key
            value = value[k]
        end
        -- No value found -- stop trying
        if value == nil then break end
    end
    return value
end

-- Handle variable references in Pandoc Str objects
local function process_Str(el)
    -- Check for a variable reference and capture any surrounding text/punctuation etc.
    local b, key, e = el.text:match(text_pattern)
    -- Did we get a hit?
    if key then
        -- Is that key really a variable reference?
        local val = var(key)
        if val then
            local retval = pandoc.Inlines(val)
            if not is_empty(b) then retval:insert(1, b) end
            if not is_empty(e) then retval:insert(e) end
            return retval
        end
    end
    return el
end

-- Handle variable references in Pandoc Link objects
local function process_Link(el)
    -- See if we get a hit on the hex encoded var pattern.
    local name = el.target:match(html_pattern)
    if name then
        -- Have something that might be a var so check whether it is.
        val = var(name)
        if val then el.target = stringify(val) end
    end
    return el
end

-----------------------------------------------------------------------------------------------------------------------
-- Invoke the various filter components in the appropriate order.
-- 1. Configure the filter itself.
-- 2. Replace any variable with its value handing Str & Link objects appropriately.
-----------------------------------------------------------------------------------------------------------------------
return { traverse = 'topdown', Meta = init_filter, Str = process_Str, Link = process_Link }
