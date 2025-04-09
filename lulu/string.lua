-----------------------------------------------------------------------------------------------------------------------
-- Lulu: Extra Lua string methods.
--
-- Full Documentation:     https://nessan.github.io/lulu
-- Source Repository:      https://github.com/nessan/lulu
-- SPDX-FileCopyrightText: 2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------
lpeg = require 'lulu.xpeg'

local insert = table.insert

--- Returns a string iterator that can be used in `for ... in` loops.
--- @param self string The string to iterate over.
--- @return function iterator The iterator function that can be used like `for c in self:iter() do ... end`.
--- **Note:** This iterator is Unicode aware and will iterate over multi-byte characters as a single entity.
function string:iter()
    -- \x00-\x7F: ASCII characters
    -- \xC2-\xF4: Characters in the 2-byte range of Unicode (excluding 255)
    -- \x80-\xBF: Continuation bytes for multi-byte characters
    return self:gmatch("[\0-\x7F\xC2-\xF4][\x80-\xBF]*")
end

--- Returns an array that contains the individual characters in the string.
--- @param self string The string to convert to an array of characters.
--- **Note:** This iterator is Unicode aware and will treat multi-byte characters as a single entity.
function string:to_array()
    local retval = {}
    for c in self:iter() do insert(retval, c) end
    return retval
end

--- Returns an array of "tokens" in the string split by a literal separator.
--- @param self string The string to tokenize.
--- @param sep? string The separator to split the string on (default is whitespace).
--- @return string[] tokens The array of tokens.
function string:split(sep)
    -- Pattern to match on (we escape all pattern characters in the `sep`). Default pattern is whitespace.
    local escaped_sep = sep and sep:gsub("[%[%]%(%)%.%%%+%-%*%?%^]", "%%%1") or '%s+'

    -- Build the array of tokens
    local tokens = {}

    -- Handle empty string or string with only separators
    if self:match("^" .. escaped_sep .. "*$") then return tokens end

    -- Split the string and filter out empty tokens
    for token in self:gmatch("([^" .. escaped_sep .. "]+)") do
        if token ~= "" then insert(tokens, token) end
    end
    return tokens
end

--- Returns `true` if the string is empty.
--- @param self string The string to check.
function string:is_empty()
    return self:len() == 0
end

--- Returns `true` if the string is not empty.
--- @param self string The string to check.
function string:is_non_empty()
    return self:len() > 0
end

--- Returns `true` if the string only contains alphabetic characters.
--- @param self string The string to check.
function string:is_alpha()
    return self:match("^%a+$") ~= nil
end

--- Returns `true` if the string only contains digit characters.
--- @param self string The string to check.
function string:is_digit()
    return self:match("^%d+$") ~= nil
end

--- Returns `true` if the string only contains alphanumeric characters.
--- @param self string The string to check.
function string:is_alphanumeric()
    return self:match("^%w+$") ~= nil
end

--- Returns `true` if the string consists of just whitespace characters.
--- @param self string The string to check.
function string:is_blank()
    return self:match("^%s*$") ~= nil
end

--- Returns `true` if the string only contains lowercase characters.
--- @param self string The string to check.
function string:is_lower()
    return self:match("^[%l%s]+$") ~= nil
end

--- Returns `true` if the string only contains uppercase characters.
--- @param self string The string to check.
function string:is_upper()
    return self:match("^[%u%s]+$") ~= nil
end

--- Returns `true` if the string starts with specified prefix.
--- @param self string The string to check.
function string:starts_with(prefix)
    return self:sub(0, prefix:len()) == prefix
end

--- Returns `true` if the string ends with specified prefix.
--- @param self string The string to check.
function string:ends_with(suffix)
    return self:sub(self:len() - suffix:len() + 1) == suffix
end

--- Returns a new string that is this one prepended by a prefix.
--- @param self string The string to prepend the prefix to.
--- @param prefix string The prefix to prepend.
function string:prepend(prefix)
    return prefix .. self
end

--- Returns a new string that is this one appended with a suffix.
--- @param self string The string to append the suffix to.
--- @param suffix string The suffix to append.
function string:append(suffix)
    return self .. suffix
end

--- Returns a new string that has `chars trimmed from the left side.
--- @param self string The string to trim.
--- @param chars? string The characters to trim which can be a Lua pattern (default matches whitespace).
function string:trim_start(chars)
    chars = chars or '%s'
    return self:gsub("^[" .. chars .. "]+", "")
end

--- Returns a new string that has `chars trimmed from the right side.
--- @param self string The string to trim.
--- @param chars? string The characters to trim which can be a Lua pattern (default matches whitespace).
function string:trim_end(chars)
    chars = chars or '%s'
    return self:gsub("[" .. chars .. "]+$", "")
end

--- Returns a new string that has `chars trimmed from both the left and the right side.
--- @param self string The string to trim.
--- @param chars? string The characters to trim which can be a Lua pattern (default matches whitespace).
function string:trim(chars)
    return self:trim_start(chars):trim_end(chars)
end

--- Returns a new string that has a specified minimum length by padding this one on the left.
--- @param self string The string to pad.
--- @param len number The minimum length of the string.
--- @param fill? string The character to use for padding (default is a space).
function string:pad_start(len, fill)
    fill = fill or " "
    local n = self:len()
    if n >= len then return self end
    local padding = fill:rep(math.ceil((len - n) / fill:len()))
    return padding:sub(1, len - n) .. self
end

--- Returns a new string that has a specified minimum length by padding this one on the right.
--- @param self string The string to pad.
--- @param len number The minimum length of the string.
--- @param fill? string The character to use for padding (default is a space).
function string:pad_end(len, fill)
    fill = fill or " "
    local n = self:len()
    if n >= len then return self end
    local padding = fill:rep(math.ceil((len - n) / fill:len()))
    return self .. padding:sub(1, len - n)
end

--- Return this string if it already starts with a specified prefix. <br>
--- Otherwise returns a new padded version that does indeed start with the required prefix.
--- @param self string The string to ensure starts with the prefix.
--- @param prefix string The prefix we ensure the returned string starts with.
--- @return string
function string:ensure_start(prefix)
    local n = prefix:len()
    if n > self:len() then return prefix:ensure_end(self) end
    local i, left = 1, self:sub(1, n)
    while not prefix:ends_with(left) and i <= n do
        i = i + 1
        left = left:sub(1, -2)
    end
    return prefix:sub(1, i - 1) .. self
end

--- Return this string if it already ends with a specified suffix. <br>
--- Otherwise we return a new padded version that does indeed end with the required suffix.
--- @param self string The string to ensure ends with the prefix.
--- @param suffix string The suffix we ensure the returned string ends with.
--- @return string
function string:ensure_end(suffix)
    local n = suffix:len()
    if n > self:len() then return suffix:ensure_start(self) end
    local i, right = n, self:sub(-n)
    while not suffix:starts_with(right) and i >= 1 do
        i = i - 1
        right = right:sub(2)
    end
    return self .. suffix:sub(i + 1)
end

--- Returns a copy of this string truncated after `len` characters followed by " ..."
--- @param self string The string to truncate.
--- @param len number The maximum length of the truncated string.
function string:ellipsis(len)
    local retval = self:sub(1, len)
    if retval:ends_with ' ' then return retval .. '...' end
    return retval .. ' ...'
end

-- Table of bool pairs as their commonly used strings (lower-case only).
local bool_pairs = { ["1"] = "0", ["true"] = "false", ["on"] = "off", ["yes"] = "no", ["y"] = "n" }

--- Returns the `boolean` value for various strings that are treated case-insensitively.
--- @param self string The string to convert to a boolean.
--- @return boolean|nil retval The boolean value of the string or `nil` if it is not a recognized boolean string.
function string:to_bool()
    local lowered = self:lower()
    for truthy, falsy in pairs(bool_pairs) do
        if lowered == truthy then
            return true
        elseif lowered == falsy then
            return false
        end
    end
    return nil
end

--- Returns a new string that has backslashes added before characters in the string that need 'escaping'.
--- @param self string The string to escape.
--- @param esc_str? string The escape character to use (default is a backslash).
--- @param specials? string[] The characters that need escaping (default is single/double quotes and backslash).
--- @return string retval The escaped string.
function string:add_escapes(esc_str, specials)
    esc_str = esc_str or "\\"
    specials = specials or { "\"", "'", "\\" }
    local function is_special(c)
        for _, s in ipairs(specials) do
            if c == s then return true end
        end
        return false
    end
    local retval = ""
    for c in self:iter() do
        retval = is_special(c) and retval .. esc_str .. c or retval .. c
    end
    return retval
end

--- Returns a new string that is a copy of this one with any escape characters removed.
--- @param self string The string to unescape.
--- @param esc? string The escape character to use (default is a backslash).
--- @return string retval The unescaped string.
function string:remove_escapes(esc)
    esc = esc or '\\'
    local i, retval = 0, ""
    while i <= #self do
        local c = self:sub(i, i)
        if c == esc then
            i = i + 1
            retval = retval .. self:sub(i, i)
        else
            retval = retval .. c
        end
        i = i + 1
    end
    return retval
end

--- Returns a hex-encoded version of this string which can be useful in HTML and other contexts.
--- @param self string The string to convert to hex.
--- For example, the string "hello" is converted to "68656c6c6f". <br>
--- See: https://stackoverflow.com/questions/65476909/lua-string-to-hex-and-hex-to-string-formulas
function string:to_hex()
    return self:gsub(".", function(char) return string.format("%02x", char:byte()) end)
end

--- Returns a string that is the decoded version of a hex-encoded string.
--- @param self string The hex encoded string to decode.
--- For example, the string "68656c6c6f" is converted to "hello". <br>
--- See: https://stackoverflow.com/questions/65476909/lua-string-to-hex-and-hex-to-string-formulas
function string:from_hex()
    return self:gsub("%x%x", function(digits) return string.char(tonumber(digits, 16)) end)
end

--- Returns a new version of this string that can be safely used in Lua's pattern matching functions.
--- @param self string The string to convert to a pattern.
--- @return string retval The pattern string which has all special characters "escaped" (e.g. '[' -> '%[' etc.). <br>
--- See: https://www.lua.org/manual/5.4/manual.html#6.4.1
function string:to_lua_pattern()
    --local pattern_characters_to_escape = { "(", ")", ".", "%", "+", "-", "*", "?", "[", "]", "^", "$" }
    --return self:add_escapes('%', pattern_characters_to_escape)
    local retval = self:gsub("[%[%]%(%)%.%%%+%-%*%?%^]", "%%%1")
    return retval
end

--- Returns a new string with all the '%' characters from a Lua pattern removed.
--- @param self string The pattern to convert to a string.
--- @return string retval The string version of the pattern.
function string:from_lua_pattern()
    return self:remove_escapes('%')
end

--- Adds line-by-line indentation to a string.
--- @param self              string    The string to indent which can be multiple lines.
--- @param indent            string    The "tab" to use for indentation.
--- @param ignore_first_line boolean?  If `true` we don not indent the first line. Default is `false`.
--- @return string indented  A string with the same number of lines as `self` and each indented by `indent`
function string:indent_lines(indent, ignore_first_line)
    -- By default we indent all the input lines
    ignore_first_line = ignore_first_line or false

    -- Handle some edge cases ...
    if not indent or indent == "" or self == "" then return self end

    -- Does the input string finish with a newline character?
    local ends_with_newline = self:sub(-1) == "\n"

    -- Build up the indented copy
    local indented_str = ""

    -- Iterate through the input string line by line using an appropriate Lua pattern for a line of text.
    local first_line = true
    for line in self:gmatch("([^\n]*)\n?") do
        if not first_line then indented_str = indented_str .. '\n' end
        local tab = first_line and ignore_first_line and '' or indent
        indented_str = indented_str .. tab .. line
        first_line = false
    end

    -- If the input string ended with a newline character then so should the output string.
    if ends_with_newline then indented_str = indented_str .. "\n" end
    return indented_str
end

--- Remove indentation from the start of each line in a string.
--- @param self            string  The string to strip indentation from which can be multiple lines.
--- @param indent          string  The "tab" to remove from the start of each line.
--- @return string retval  A string with the same number of lines as `self`.
function string:dedent_lines(indent)
    -- Handle some edge cases ...
    if self == '' or not indent or indent == '' then return self end

    local prefix_pattern = "(\n)" .. indent
    local replacement = "%1" -- Keep the newline but remove the prefix

    -- First handle the beginning of the string
    if self:sub(1, #indent) == indent then self = self:sub(#indent + 1) end

    -- Then handle all other lines
    local retval = self:gsub(prefix_pattern, replacement)
    return retval
end

-----------------------------------------------------------------------------------------------------------------------
-- Queries that depend on the `lulu.lpeg` module.
-----------------------------------------------------------------------------------------------------------------------

local patterns   = lpeg.patterns
local P, V, C    = lpeg.P, lpeg.V, lpeg.C
local Ct, Cs, Cc = lpeg.Ct, lpeg.Cs, lpeg.Cc

--- Does the string have a match to a pattern/string anywhere inside it?
--- @param self string The string to check.
--- @param pattern string|pattern The pattern to check for.
--- @return boolean retval
function string:contains(pattern)
    return lpeg.anywhere(pattern):match(self) and true or false
end

--- Does the string contain a `word` (a string/pattern surrounded by whitespace)?
--- @param self string The string to check.
--- @param word string|pattern The word to check for.
--- @return boolean retval
function string:contains_word(word)
    local p1 = P(word) * (patterns.ws + patterns.eos) * Cc(true)
    local p2 = patterns.ws * p1
    local p3 = p1 + (1 - p2) ^ 0 * p2 + Cc(false)
    return p3:match(self)
end

--- Can we can parse the *whole* string as a decimal (a positive integer)?
--- @param self string The string to check.
--- @return boolean retval
function string:is_dec()
    return (patterns.dec * patterns.eos):match(self) and true or false
end

--- Can we can parse the *whole* string as a positive hexadecimal integer?
--- @param self string The string to check.
--- @return boolean retval
--- The string can start with "0x" or "0X" or just be a string of hex characters.
function string:is_hex()
    return (patterns.hex * patterns.eos):match(self) and true or false
end

--- Can we can parse the *whole* string as a positive octal integer?
--- @param self string The string to check.
--- @return boolean retval
--- The string can start with "0" or just be a string of octal characters.
function string:is_oct()
    return (patterns.oct * patterns.eos):match(self) and true or false
end

--- Can we can parse the *whole* string as a positive binary integer?
--- @param self string The string to check.
--- @return boolean retval
--- The string can start with "0b" or "0B" or just be a string of binary characters.
function string:is_bin()
    return (patterns.bin * patterns.eos):match(self) and true or false
end

--- Can we can parse the *whole* string as a (potentially signed) integer?
--- @param self string The string to check.
--- @return boolean retval
function string:is_int()
    return (patterns.int * patterns.eos):match(self) and true or false
end

--- Can we can parse the *whole* string as a floating point number?
--- @param self string The string to check.
--- @return boolean retval
function string:is_float()
    return (patterns.float * patterns.eos):match(self) and true or false
end

--- Can we can parse the *whole* string as a some typ of number (binary, octal, hex, integer, float)?
--- @param self string The string to check.
--- @return boolean retval
function string:is_number()
    return (patterns.number * patterns.eos):match(self) and true or false
end

--- Does the string start with an escape character?
--- @param self string The string to check.
--- @param esc? string|pattern The escape character to use (default is a backslash).
--- @return boolean retval
function string:is_escaped(esc)
    esc = esc or patterns.esc
    return lpeg.is_escaped(esc):match(self) and true or false
end

-----------------------------------------------------------------------------------------------------------------------
-- String alteration methods that depend on the `lulu.lpeg` module.
-- These methods return new strings and do not alter the original string.
-----------------------------------------------------------------------------------------------------------------------

--- Returns a copy of this string where all matches to a pattern `p` are changed to `to`.
--- @param self string The string to change.
--- @param p string|pattern The pattern to match.
--- @param to string|function The replacement string or function. The default is "" so matches to `p` are deleted.
--- If `to` is a function then matches are replaced with `to(match)` which should return a string.
--- @return string retval The changed string.
function string:change(p, to)
    to = to or ""
    return lpeg.change(p, to):match(self)
end

--- Returns a copy of this string where all matches to a pattern `p` are deleted.
--- @param self string The string to change.
--- @param p string|pattern The pattern to match..
--- @return string retval The changed string.
function string:delete(p)
    return lpeg.change(p, ""):match(self)
end

--- Returns a copy of this string without any leading or trailing whitespace.
--- @param self string The string to change.
--- @return string retval The changed string.
function string:trim_ws()
    return patterns.trim_ws:match(self)
end

--- Returns a copy of this string with contiguous whitespaces converted to a single space.
--- @param self string The string to change.
--- @param careful? boolean Whether to leave spaces inside quotes alone (default is `true`).
--- @return string retval The changed string.
function string:collapse_ws(careful)
    if careful then
        return patterns.careful_collapse_ws:match(self)
    else
        return patterns.collapse_ws:match(self)
    end
end

--- Returns a copy of this string with all spaces removed.
--- @param self string The string to change.
--- @return string retval The changed string.
function string:delete_ws()
    return patterns.delete_ws:match(self)
end

--- Returns a copy of this string with specific escaped characters turned into unescaped ones. <br>
--- For example, we can use the function to turn 'joe said \"no way\" ...' into 'joe said "no way" ...'.
--- @param self string The string to change.
--- @param chars? string The characters to unescape (default "). Set to "{}" to unescape '\{'s and '\}'s.
--- @param esc? string|pattern The escape character to use (default is a backslash).
--- @return string retval The changed string.
function string:unescape(chars, esc)
    chars = chars or '"'
    esc = esc or patterns.esc
    return lpeg.unescape(chars, esc):match(self)
end

-----------------------------------------------------------------------------------------------------------------------
-- Tokenization methods that depend on the `lulu.lpeg` module.
-----------------------------------------------------------------------------------------------------------------------

--- Returns an array of all the "tokens" in a string by splitting it on a separator/pattern.
--- @param self string The string to tokenize.
--- @param sep? string|pattern The separator to split the string on (default is whitespace).
--- @return string[] tokens The array of tokens.
--- Note: consecutive separators are treated as one.
function string:to_tokens(sep)
    sep = sep or patterns.ws
    return lpeg.tokenizer(sep):match(self)
end

--- Returns an array of all the "lines" in a string by splitting on a newline character.
--- @param self string The string to tokenize.
--- @return string[] lines The array of lines.
--- Note: consecutive newlines are treated as one.
function string:to_lines()
    return lpeg.tokenizer(patterns.nl):match(self)
end

--- Returns the content of a string before the first occurrence of a separator/pattern.
--- @param self string The string to split.
--- @param sep string|pattern The separator to split the string on.
--- @return string retval The content of the string before the separator.
function string:before(sep)
    return lpeg.before(sep):match(self)
end

--- Returns the content of a string after the first occurrence of a separator/pattern.
--- @param self string The string to split.
--- @param sep string|pattern The separator to split the string on.
--- @return string retval The content of the string after the separator.
function string:after(sep)
    return lpeg.after(sep):match(self)
end

--- Returns an array of all the text-blocks/paragraphs in a string. <br>
--- Blocks/paragraphs are pieces of text delimited by one or more blank lines.
--- @param self string The string to tokenize.
--- @return string[] blocks The array of blocks.
function string:to_blocks()
    return patterns.blocks:match(self)
end

-----------------------------------------------------------------------------------------------------------------------
-- Truncation methods that depend on the `lulu.lpeg` module.
-----------------------------------------------------------------------------------------------------------------------

--- Returns a copy of a string where each line has from `p` to the end of that line removed. <br>
--- If `p` is a number we simply truncate each line at `p` characters.
--- @param self string The string to truncate.
--- @param p number|string|pattern We truncate lines starting at `p`.
--- @return string retval The truncated string.
function string:kill_from(p)
    -- Grammar: line = keep * zap * eol
    local line = V "line"
    local keep = V "keep"
    local zap = V "zap"

    -- Two cases: `p` is a number of characters vs. `p` is an arbitrary string/pattern:
    if type(p) == 'number' then
        return P {
            Cs(line ^ 0),
            line = keep * zap * patterns.eol,
            keep = P(p),
            zap = patterns.non_eol ^ 0 / ""
        }:match(self)
    else
        return P {
            Cs(line ^ 0),
            line = keep * zap * patterns.eol,
            keep = (1 - zap) ^ 0,
            zap = (p * patterns.non_eol ^ 0) / ""
        }:match(self)
    end
end

--- Returns a copy of a string where each line is killed from its start up to and including `p`. <br>
--- If `p` is a number we kill the first `p` characters in each line.
--- @param self string The string to truncate.
--- @param p    any     We kill up to and including `p`.
--- @return string retval The truncated string.
function string:kill_to(p)
    if type(p) == 'number' then
        return self:sub(p + 1)
    else
        local pos = self:find(p, 1, true)
        if pos then return self:sub(pos + #p) end
        return self
    end
end

--- Returns a copy of a string where each line is truncated at `n` characters.
--- @param self string The string to truncate.
--- @param n number The number of characters to truncate each line at.
--- @return string retval The string with truncated lines
function string:truncate(n)
    return self:kill_from(n)
end

--- Returns a copy of a string with any end-of-line comments erased from each line.
--- @param self string The string to truncate.
--- @param comment_start? string The comment start symbol (default is '#').
--- @return string retval The string with truncated lines.
function string:strip_comments(comment_start)
    comment_start = comment_start or '#'
    return self:kill_from(comment_start)
end

-----------------------------------------------------------------------------------------------------------------------
-- Delimited string methods that depend on the `lulu.lpeg` module.
-----------------------------------------------------------------------------------------------------------------------

--- Is this string delimited by left and right delimiters?
--- @param self string The string to check.
--- @param left? string The left delimiter (default is double quotes).
--- @param right? string The right delimiter (default is double quotes).
--- @param one_line? boolean If `true` the match only considers up to the first newline (default is `false`).
--- @return boolean retval
--- #### Note:
--- - If neither delimiter is given then we default to using double quotes: "..."
--- - If only one delimiter is given and it's a single character (e.g. "'") then we use that for both: '...'
--- - If only one delimiter is given with an even number of characters (e.g. "{}") then we split it in half '{' and '}'.
--- - You can of course specify the left and right delimiters separately.
function string:is_delimited(left, right, one_line)
    local delim = lpeg.delimited(left, right, one_line)
    return delim:match(self) and true or false
end

--- Does this string contain anywhere text delimited by left and right delimiters?
--- @param self string The string to check.
--- @param left? string The left delimiter (default is double quotes).
--- @param right? string The right delimiter (default is double quotes).
--- @param one_line? boolean If `true` the match only considers up to the first newline (default is `false`).
--- @return boolean retval
--- #### Note:
--- - If neither delimiter is given then we default to using double quotes: "..."
--- - If only one delimiter is given and it's a single character (e.g. "'") then we use that for both: '...'
--- - If only one delimiter is given with an even number of characters (e.g. "{}") then we split it in half '{' and '}'.
--- - You can of course specify the left and right delimiters separately.
function string:contains_delimited(left, right, one_line)
    local delim = lpeg.delimited(left, right, one_line)
    delim = lpeg.anywhere(delim)
    return delim:match(self) and true or false
end

-- Private function: Workhorse for the `string:first_delimited` and `string:all_delimited methods`.
local function capture_delimited(all, self, left, right, one_line)
    -- Patterns that determine whether or not we're looking at a delimited range of text.
    local delim = lpeg.delimited(left, right, one_line)
    local non_delim = 1 - delim

    -- Pattern to capture delimited content once we reach it.
    local content = lpeg.delimited_content(left, right, one_line)

    -- Patterns that walks through the non-delimited text to get to the delimited range.
    local p = non_delim ^ 0 * content
    if all then p = Ct(p ^ 0) end

    -- Do the deed
    return p:match(self)
end

--- Returns the *first* block of delimited content in a string.
--- @param self string The string to check.
--- @param left? string The left delimiter (default is double quotes).
--- @param right? string The right delimiter (default is double quotes).
--- @param one_line? boolean If `true` the match only considers up to the first newline (default is `false`).
--- @return string|nil retval The first block of delimited content or `nil` if there is none.
--- #### Note:
--- - If neither delimiter is given then we default to using double quotes: "..."
--- - If only one delimiter is given and it's a single character (e.g. "'") then we use that for both: '...'
--- - If only one delimiter is given with an even number of characters (e.g. "{}") then we split it in half '{' and '}'.
--- - You can of course specify the left and right delimiters separately.
function string:first_delimited(left, right, one_line) return capture_delimited(false, self, left, right, one_line) end

--- Returns an array of *all* blocks of delimited content in a string.
--- @param self string The string to check.
--- @param left? string The left delimiter (default is double quotes).
--- @param right? string The right delimiter (default is double quotes).
--- @param one_line? boolean If `true` the match only considers up to the first newline (default is `false`).
--- @return string[] retval An array of blocks of delimited content or an empty array if there are none.
--- #### Note:
--- - If neither delimiter is given then we default to using double quotes: "..."
--- - If only one delimiter is given and it's a single character (e.g. "'") then we use that for both: '...'
--- - If only one delimiter is given with an even number of characters (e.g. "{}") then we split it in half '{' and '}'.
--- - You can of course specify the left and right delimiters separately.
function string:all_delimited(left, right, one_line) return capture_delimited(true, self, left, right, one_line) end

-----------------------------------------------------------------------------------------------------------------------
-- Quote delimited string methods that depend on the `lpeg` module.
-----------------------------------------------------------------------------------------------------------------------

--- Is the string inside either matching single or double quotes.
--- @param self string The string to check.
function string:is_quoted()
    local delim = patterns.quoted
    return delim:match(self) and true or false
end

--- Does the string contain quoted text anywhere.
--- @param self string The string to check.
function string:contains_quoted()
    local delim = patterns.quoted
    delim = lpeg.anywhere(delim)
    return delim:match(self) and true or false
end

--- Returns the first quoted content in a string.
--- @param self string The string to check.
--- @return string|nil retval The first block of quoted content or `nil` if there is none.
function string:first_quoted()
    -- Turn nil matches into a giant number
    local npos = 9999999999

    -- See if we get a hit on content inside single or double quotes.
    local sq = lpeg.anywhere(patterns.single_quoted):match(self) or npos
    local dq = lpeg.anywhere(patterns.double_quoted):match(self) or npos

    -- If we found nothing return nil.
    if sq == npos and dq == npos then return nil end

    -- Return whichever quoted content came first in the string.
    if sq < dq then
        return self:first_delimited("'")
    else
        return self:first_delimited('"')
    end
end

--- Returns an array of all quoted content in a string.
--- @param self string The string to check.
--- @param quote? string The quote character to look for. If absent we look for both single and double quotes.
--- @return string[] retval An array of blocks of quoted content or `nil` if there is none.
function string:all_quoted(quote)
    if quote then return self:all_delimited(quote) end
    local singles = self:all_delimited("'")
    local doubles = self:all_delimited('"')
    local retval = singles
    for _, q in ipairs(doubles) do insert(retval, q) end
    return retval
end
