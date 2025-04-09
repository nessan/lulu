-----------------------------------------------------------------------------------------------------------------------
-- Lulu: Extra Lua lpeg data and methods.
--
-- Adds a table of some generally useful patterns accessible via `M.patterns`
-- Adds some functions to create patterns that depend on arguments.
--
-- Full Documentation:     https://nessan.github.io/lulu
-- Source Repository:      https://github.com/nessan/lulu
-- SPDX-FileCopyrightText: 2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------
local lpeg = require 'lpeg'

-- Import all the lpeg functions into the module.
local M = {}
for k, v in pairs(lpeg) do M[k] = v end

-- Localize the usual lpeg pattern methods.
local P, R, S, V, B   = M.P, M.R, M.S, M.V, M.B
local Ct, C, Cs, Cc   = M.Ct, M.C, M.Cs, M.Cc
local Cmt             = M.Cmt

-----------------------------------------------------------------------------------------------------------------------
--- Add commonly used patterns to the module in the sub-table `patterns`.
-----------------------------------------------------------------------------------------------------------------------
--- @type userdata pattern A Lua PEG pattern object.
--- @alias pattern userdata

M.patterns            = M.patterns or {}
local patterns        = M.patterns

patterns.any          = P(1)                          --- @type pattern Matches any character.
patterns.eos          = P(-1)                         --- @type pattern Matches the end of the subject or string.
patterns.esc          = P('\\')                       --- @type pattern Matches the standard escape character: '\'
patterns.alpha        = R('AZ', 'az')                 --- @type pattern Matches alphabetic characters.
patterns.digit        = R('09')                       --- @type pattern Matches decimal digits.
patterns.alphanumeric = R('AZ', 'az', '09')           --- @type pattern Matches alphanumeric characters.
patterns.lower        = R("az")                       --- @type pattern Matches lowercase letters.
patterns.upper        = R("AZ")                       --- @type pattern Matches uppercase letters.
patterns.graph        = R('!~')                       --- @type pattern Matches printable characters.
patterns.punctuation  = R('!/', ':@', '[\'', '{~')    --- @type pattern Matches non-alphanumeric printable chars.
patterns.hs           = S(' \t')                      --- @type pattern Matches horizontal space.
patterns.ws           = S(' \t\n\r\v\f')              --- @type pattern Matches whitespace including newlines.
patterns.non_hs       = 1 - patterns.hs               --- @type pattern Matches non-horizontal space characters.
patterns.non_ws       = 1 - patterns.ws               --- @type pattern Matches non-whitespace characters.
patterns.nl           = P('\r') ^ -1 * '\n'           --- @type pattern Matches newlines (DOS and Unix).
patterns.non_nl       = 1 - patterns.nl               --- @type pattern Matches non-newline characters (DOS & Unix).
patterns.eol          = patterns.nl + patterns.eos    --- @type pattern Matches end-of-line or end-of-subject.
patterns.non_eol      = 1 - patterns.eol              --- @type pattern Matches non-end-of-line characters.
patterns.sign         = S('+-')                       --- @type pattern Matches plus or minus signs.
patterns.bin_digit    = S('01')                       --- @type pattern Matches binary digits.
patterns.oct_digit    = R("07")                       --- @type pattern Matches octal digits.
patterns.dec_digit    = R("09")                       --- @type pattern Matches decimal digits.
patterns.hex_digit    = R('09', 'AF', 'af')           --- @type pattern Matches hexadecimal digits.

-----------------------------------------------------------------------------------------------------------------------
-- Queries.
-----------------------------------------------------------------------------------------------------------------------

--- Query to see if an argument is an lpeg pattern.
--- @param arg any The argument to test.
--- @return boolean `true` if the argument is an lpeg pattern.
function M.is_pattern(arg) return arg and M.type(arg) == 'pattern' end

-----------------------------------------------------------------------------------------------------------------------
-- Patterns that match numbers.
-----------------------------------------------------------------------------------------------------------------------

--- Match unsigned decimal integers with optional digit group separators.
--- @param sep? string Optional separator e.g. "," to handle "7,000,139" (defaults to "")
--- @return pattern pattern Matches a decimal number.
function M.dec_number(sep)
    sep = sep or ''
    return patterns.dec_digit * (P(sep) ^ -1 * patterns.dec_digit) ^ 0
end

--- Match unsigned hexadecimal integers with optional digit group separators.
--- @param sep? string Optional separator e.g. "_" to handle "0xA9F8_016B" (defaults to "")
--- @return pattern pattern Matches a hexadecimal number.
function M.hex_number(sep)
    sep = sep or ''
    return ('0' * S('xX')) ^ -1 * (P(sep) ^ -1 * patterns.hex_digit) ^ 1
end

--- Match unsigned octal integers with optional digit group separators.
--- @param sep? string Optional separator e.g. "_" to handle "0135_025" (defaults to "")
--- @return pattern pattern Matches an octal number.
function M.oct_number(sep)
    sep = sep or ''
    return ('0') ^ -1 * (P(sep) ^ -1 * patterns.oct_digit) ^ 1
end

--- Match unsigned binary integers with optional digit group separators.
--- @param sep? string Optional separator e.g. "_" to handle "0b1001_0101" (defaults to "")
--- @return pattern pattern Matches an octal number.
function M.bin_number(sep)
    sep = sep or ''
    return ('0' * S('bB')) ^ -1 * (P(sep) ^ -1 * patterns.bin_digit) ^ 1
end

--- Match any form of signed integer with optional digit group separators.
--- @param sep? string Optional separator between groups of digits (defaults to "")
--- @return pattern pattern Matches a signed integer.
function M.int_number(sep)
    sep = sep or ''
    return patterns.sign ^ -1 *
        (M.hex_number(sep) + M.bin_number(sep) + M.oct_number(sep) + M.dec_number(sep))
end

--- Match any form of signed float with optional digit group separators.
--- @param sep? string Optional separator between groups of digits (defaults to "")
--- @return pattern pattern Matches a signed float.
function M.float_number(sep)
    sep = sep or ''
    local exp = S('eE') * patterns.sign ^ -1 * patterns.dec_digit * (P(sep) ^ -1 * patterns.dec_digit) ^ 0
    return patterns.sign ^ -1 *
        ((M.dec_number(sep) ^ -1 * '.' * M.dec_number(sep) + M.dec_number(sep) * '.' * M.dec_number(sep) ^ -1 *
            -P('.')) * exp ^ -1 + (M.dec_number(sep) * exp))
end

--- Match any form of signed number with optional digit group separators.
--- @param sep? string Optional separator between groups of digits (defaults to "")
--- @return pattern pattern Matches a signed number.
function M.number(sep) return M.float_number(sep) + M.int_number(sep) end

patterns.dec         = M.dec_number('')   -- Matches a decimal number.
patterns.hex         = M.hex_number('')   -- Matches a hexadecimal number.
patterns.oct         = M.oct_number('')   -- Matches an octal number.
patterns.bin         = M.bin_number('')   -- Matches a binary number.
patterns.int         = M.int_number('')   -- Matches an integer.
patterns.float       = M.float_number('') -- Matches a floating point number.
patterns.num         = M.number('')       -- Matches any number.

--- @type pattern Capture that ignores leading and trailing whitespace.
patterns.trim_ws     = patterns.ws ^ 0 * C((patterns.ws ^ 0 * patterns.non_ws ^ 1) ^ 0)

--- @type pattern Substitution capture that trims and collapses ALL contiguous interior white-spaces to a single space.
patterns.collapse_ws = Cs(patterns.ws ^ 0 / "" * patterns.non_ws ^ 0 *
    ((patterns.ws ^ 0 / " " * patterns.non_ws ^ 1) ^ 0))

--- @type pattern Substitution capture that removes all whitespace.
patterns.delete_ws   = Cs((patterns.ws ^ 1 / "" + patterns.non_ws ^ 1) ^ 0)

--- @type pattern Table capture all the text blocks/paragraphs in a subject string. <br>
--- A block/paragraph is text followed by one or more empty lines or the end of the string.
patterns.blocks      = P {
    Ct(V "block" ^ 1),
    block = patterns.ws ^ 0 * C(V "block_content") * V "block_end",
    block_content = (1 - V "block_end") ^ 1,
    block_end = patterns.nl * V "blank_line" ^ 1 + patterns.eos,
    blank_line = patterns.hs ^ 0 * patterns.nl
}

-----------------------------------------------------------------------------------------------------------------------
-- Functions that create patterns based on some input
-----------------------------------------------------------------------------------------------------------------------

--- Creates a pattern that allows an input pattern to work anywhere in a subject string. <br>
--- @param p pattern|string The pattern that currently only matches at the start of a string.
--- @return pattern anywhere_p A pattern that matches `p` anywhere in the string.
--- #### Usage:
--- If `p` is a pattern then `p:match(str)` is a match query anchored at the start of `str`. <br>
--- You can use `anywhere(p):match(str)` to instead drive through `str` looking for a match.
function M.anywhere(p)
    -- This grammar says try to match `p` but if that fails advance one character and repeat.
    -- Note: There is one rule in the grammar and V(1) is shorthand for "apply rule #1"
    return P { p + 1 * M.V(1) }
end

--- Creates a substitution pattern that acts on strings so matches to `p` are changed.
--- @param p string|pattern The pattern to match.
--- @param to string|function The replacement string or a function that returns a string.
--- @return pattern change_pattern A pattern that substitutes `to` for matches to `p`.
--- If `to` is a string then any match is replaced with that string <br>
--- If `to` is a function then each match is replaced with the return value from `to(match)` which should be a string.
function M.change(p, to)
    p = P(p)
    return Cs(((p / to) + patterns.any) ^ 0)
end

--- Creates a pattern that checks whether a string starts with an escape character.
--- @param esc? string|pattern The escape character pattern (defaults to `patterns.esc`).
--- @return pattern is_escaped A pattern that checks for an escape character at the start of a string.
function M.is_escaped(esc)
    esc = esc or patterns.esc
    return P(1) * B(esc)
end

--- Creates a pattern that turns escaped characters into unescaped ones.
--- @param chars? string The characters to unescape (defaults to `'"'`).
--- @param esc? string|pattern The escape character pattern (defaults to `patterns.esc`).
--- @return pattern unescape A pattern that removes escape characters from a string.
function M.unescape(chars, esc)
    chars = chars or '"'
    esc = esc or patterns.esc

    -- There is a substitution pattern for each letter in chars -- here is the first one:
    local c = chars:sub(1, 1)
    local zapper = P((esc * P(c)) / c)

    -- Add escape zappers for all the other entries in chars also
    for i = 2, #chars do
        c = chars:sub(i, i)
        zapper = zapper + P((esc * P(c)) / c)
    end

    -- Overall substitution pattern (we match on zappers first!)
    return Cs((zapper + patterns.any) ^ 0)
end

-----------------------------------------------------------------------------------------------------------------------
-- Patterns that split subject strings into tokens/parts based on a separators pattern/string.
-----------------------------------------------------------------------------------------------------------------------

--- Creates a pattern that matches starting with string/pattern `from` until the end of the line.
--- @param from pattern|string The pattern or string to match from.
--- @return pattern to_eol A pattern that matches from `from` to the end of the line.
function M.to_eol(from) return from * (patterns.non_nl) ^ 0 end

--- Creates a table capture pattern to split a string into tokens based on a separator/pattern. <br>
--- Consecutive separators are treated as one.
--- @param sep pattern|string The separator pattern or string.
--- @return pattern tokenizer A pattern that captures all the tokens in a subject string.
function M.tokenizer(sep) return P { Ct((sep ^ 0 * C(V "word")) ^ 0), word = (patterns.any - sep) ^ 1 } end

--- Creates a capture pattern for all content before the first occurrence of a separator/pattern.
--- @param sep pattern|string The separator pattern or string.
--- @return pattern before A pattern that captures all content before the first separator.
function M.before(sep)
    sep = P(sep)
    return C((1 - sep) ^ 0) * sep
end

--- Creates a capture pattern for all content after the first occurrence of a separator/pattern.
--- @param sep pattern|string The separator pattern or string.
--- @return pattern after A pattern that captures all content after the first separator.
function M.after(sep)
    sep = M.anywhere(sep)
    return sep * C(patterns.any ^ 0)
end

-----------------------------------------------------------------------------------------------------------------------
-- Patterns for text delimited by left and right delimiters.
-----------------------------------------------------------------------------------------------------------------------

--- Private function: Derive left and right delimiters from a string.
--- @param str string The string to derive delimiters from.
--- @return string left The left delimiter
--- @return string right  The right delimiter.
--- If the `str` has just one character 'c' it returns the two identical values 'c' and 'c'. <br>
--- Otherwise if there are an odd number of characters the function errors out.
local function delimiters_from(str)
    local ns = #str
    if ns == 1 then return str, str end
    if ns % 2 == 0 then
        local n2 = ns / 2
        return str:sub(1, n2), str:sub(n2 + 1)
    end
    error("Not clear how to derive left & right delimiters from string '" .. str .. "'")
end

--- Private function: Workhorse for the `M.delimited` and `M.delimited_content` methods.
--- @param capture boolean If true then we capture the content.
--- @param left? string The left delimiter string (defaults to '"').
--- @param right? string The right delimiter string (defaults to `left` but see the note below).
--- @param one_line? boolean If true then the match stops at the first newline (default is false).
--- @return pattern delimited A pattern that matches/captures content delimited by `left` and `right`.
--- #### Note:
--- - If neither delimiter is given then we default to using double quotes: "..."
--- - If only one delimiter is given and it's a single character (e.g. "'") then we use that for both: '...'
--- - If only one delimiter is given with an even number of characters (e.g. "{}") then we split it in half '{' and '}'.
--- - You can of course specify the left and right delimiters separately.
--- - If `left == right` then escaped delimiters aren't matched ("inner \"quote\" here" matches the whole string).
--- - If `left != right` then we 'balance' so "{}" applied to ("{123{45}67}") matches on '123{45}67'..
local function create_delimited(capture, left, right, one_line)
    -- Default value for `left`:
    if not left or #left == 0 then left = '"' end

    -- May need to derive the right delimiter from the delimiter string passed as `left`.
    local rt = type(right)
    if rt ~= 'string' and rt ~= 'userdata' then
        one_line = right
        left, right = delimiters_from(left)
    end

    -- This local `any` matches content inside the delimiters.
    local any = patterns.any
    any = any - right
    if one_line then any = any - patterns.nl end

    -- Either looking at things like {content} or "content".
    if left == right then
        -- Match on "start \"inner quote\" end" should be to: start \"inner quote\" end
        local delim = left
        any = any - patterns.esc + patterns.esc * delim
        local unescaped_delim = delim - B(patterns.esc)
        return P { unescaped_delim * V "content" * delim, content = capture and C(any ^ 0) or any ^ 0 }
    else
        -- Match on {123{456}789} should be the whole balanced: 123{456}789
        any = any - left
        return P { left * V "content" * right, content = capture and C((any + V(1)) ^ 0) or (any + V(1)) ^ 0 }
    end
end

--- Creates a pattern to *match* delimited content.
--- @param left? string The left delimiter string (defaults to '"').
--- @param right? string The right delimiter string (defaults to left).
--- @param one_line? boolean If true then the match will stop at the first newline (default is false).
--- @return pattern delimited A pattern that matches content delimited by `left` and `right`.
--- #### Note:
--- - If neither delimiter is given then we default to using double quotes: "..."
--- - If only one delimiter is given and it's a single character (e.g. "'") then we use that for both: '...'
--- - If only one delimiter is given with an even number of characters (e.g. "{}") then we split it in half '{' and '}'.
--- - You can of course specify the left and right delimiters separately.
--- - If `left == right` then escaped delimiters aren't matched: "inner \"quote\" here" matches the whole string.
--- - If `left != right` then we 'balance' so "{}" applied to "{123{45}67}" matches on '123{45}67'.
function M.delimited(left, right, one_line) return create_delimited(false, left, right, one_line) end

--- Creates a pattern to *capture* delimited content.
--- @param left? string The left delimiter string (defaults to '"').
--- @param right? string The right delimiter string (defaults to left).
--- @param one_line? boolean If true then the match will stop at the first newline (default is false).
--- @return pattern delimited A pattern that matches content delimited by `left` and `right`.
--- #### Note:
--- - If neither delimiter is given then we default to using double quotes: "..."
--- - If only one delimiter is given and it's a single character (e.g. "'") then we use that for both: '...'
--- - If only one delimiter is given with an even number of characters (e.g. "{}") then we split it in half '{' and '}'.
--- - You can of course specify the left and right delimiters separately.
--- - If `left == right` then escaped delimiters aren't matched: "inner \"quote\" here" captures the whole string.
--- - If `left != right` then we 'balance' so "{}" applied to "{123{45}67}" captures '123{45}67'.
function M.delimited_content(left, right, one_line) return create_delimited(true, left, right, one_line) end

--- @type pattern Matches single quoted strings.
patterns.single_quoted = M.delimited("'")

--- @type pattern Matches double quoted strings.
patterns.double_quoted = M.delimited('"')

--- @type pattern Matches either single or double quoted strings.
patterns.quoted = patterns.double_quoted + patterns.single_quoted

--- @type pattern Captures content inside single quotes.
patterns.single_quoted_content = M.delimited_content("'")

--- @type pattern Captures content inside double quotes.
patterns.double_quoted_content = M.delimited_content('"')

--- @type pattern Captures content inside either single or double quotes.
patterns.quoted_content = patterns.double_quoted_content + patterns.single_quoted_content

--- @type pattern Substitution capture that trims and collapses contiguous interior white-spaces to one space but not inside quotes.
patterns.careful_collapse_ws =
    Cs(patterns.ws ^ 0 / "" *
        ((patterns.quoted + patterns.non_ws ^ 1 + patterns.ws ^ 1 / "" *
            (patterns.eos + Cc(" "))) ^ 0))

-----------------------------------------------------------------------------------------------------------------------
-- Other pattern manipulation functions
-----------------------------------------------------------------------------------------------------------------------

--- Creates a new pattern where `p` is only matched if it is preceded by a character in the `set` string. <br>
--- The `skip` string is used to skip over characters between the `set` and the `p` match (default whitespace).
--- @param set string The set of characters that determine if the pattern `p` is in force.
--- @param p string|pattern The pattern that we want to match after we hit a character in the `set` string.
--- @param skip? string The set of characters to skip over (default is whitespace).
--- @return pattern after_set A pattern that matches `p` only after a character in `set`.
function M.after_set(set, p, skip)
    skip = skip or ' \t\n\r\v\f'

    local set_chars, skip_chars = {}, {}
    for char in set:gmatch('.') do set_chars[string.byte(char)] = true end
    for char in skip:gmatch('.') do skip_chars[string.byte(char)] = true end

    return (B(S(set)) + -B(1)) * p + Cmt(C(p), function(input, index, match, ...)
        local pos = index - #match
        if #skip > 0 then while pos > 1 and skip_chars[input:byte(pos - 1)] do pos = pos - 1 end end
        if pos == 1 or set_chars[input:byte(pos - 1)] then return index, ... end
        return nil
    end)
end

--- Creates a new pattern where `p` is only matched if it is preceded by a newline character. <br>
--- @param p string|pattern The pattern that we want to match after a newline.
--- @param allow_indent? boolean If true then the match is allowed after any line indentation (default is false).
--- @return pattern starts_line A pattern that matches `p` only at the beginning of a line.
function M.after_newline(p, allow_indent)
    return M.after_set('\r\n\v\f', p, allow_indent and ' \t' or '')
end

return M
