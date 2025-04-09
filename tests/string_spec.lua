-----------------------------------------------------------------------------------------------------------------------
-- Busted tests for the `lulu.string` module.
--
-- SPDX-FileCopyrightText:  2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------

-- Add "." and ".." to the package path for relative requires.
local dot = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]] or "./"
package.path = dot .. "?.lua;" .. dot .. "../?.lua;" .. package.path

local busted = require('busted')
local describe, it = busted.describe, busted.it
local assert = require('luassert')

require('lulu.string') -- This extends the string type

describe('string module', function()
    describe('iter()', function()
        it('should iterate over each character in a string', function()
            local str = "hello"
            local chars = {}
            for c in str:iter() do
                table.insert(chars, c)
            end
            assert.are.same({ 'h', 'e', 'l', 'l', 'o' }, chars)
        end)

        it('should handle empty strings', function()
            local str = ""
            local count = 0
            for _ in str:iter() do
                count = count + 1
            end
            assert.equals(0, count)
        end)

        it('should handle special characters', function()
            local str = "hello\nworld\t!"
            local chars = {}
            for c in str:iter() do
                table.insert(chars, c)
            end
            assert.are.same({ 'h', 'e', 'l', 'l', 'o', '\n', 'w', 'o', 'r', 'l', 'd', '\t', '!' }, chars)
        end)

        it('should handle unicode characters', function()
            local str = "héllo→世界"
            local chars = {}
            for c in str:iter() do
                table.insert(chars, c)
            end
            assert.are.same({ 'h', 'é', 'l', 'l', 'o', '→', '世', '界' }, chars)
        end)
    end)

    describe('to_array()', function()
        it('should convert string to array of characters', function()
            local str = "world"
            assert.are.same({ 'w', 'o', 'r', 'l', 'd' }, str:to_array())
        end)

        it('should handle empty strings', function()
            local str = ""
            assert.are.same({}, str:to_array())
        end)

        it('should handle strings with spaces', function()
            local str = "a b c"
            assert.are.same({ 'a', ' ', 'b', ' ', 'c' }, str:to_array())
        end)

        it('should handle special characters', function()
            local str = "hello\nworld\t!"
            assert.are.same({ 'h', 'e', 'l', 'l', 'o', '\n', 'w', 'o', 'r', 'l', 'd', '\t', '!' }, str:to_array())
        end)

        it('should handle unicode characters', function()
            local str = "héllo→世界"
            assert.are.same({ 'h', 'é', 'l', 'l', 'o', '→', '世', '界' }, str:to_array())
        end)
    end)

    describe('split()', function()
        it('should split string on whitespace by default', function()
            local str = "hello world lua"
            assert.are.same({ 'hello', 'world', 'lua' }, str:split())
        end)

        it('should split string on custom separator', function()
            local str = "hello,world,lua"
            assert.are.same({ 'hello', 'world', 'lua' }, str:split(','))
        end)

        it('should handle empty strings', function()
            local str = ""
            assert.are.same({}, str:split())
        end)

        it('should handle strings with no separators', function()
            local str = "hello"
            assert.are.same({ 'hello' }, str:split(','))
        end)

        it('should handle multiple consecutive separators', function()
            local str = "hello   world"
            assert.are.same({ 'hello', 'world' }, str:split())
        end)

        it('should handle strings with only separators', function()
            local str = "   "
            assert.are.same({}, str:split())
        end)

        it('should handle special characters as separators', function()
            local str = "hello\nworld\tlua"
            assert.are.same({ 'hello', 'world', 'lua' }, str:split())
            assert.are.same({ 'hello\nworld\tlua' }, str:split('|'))
        end)

        it('should handle multiple character separators', function()
            local str = "hello||world||lua"
            assert.are.same({ 'hello', 'world', 'lua' }, str:split('||'))
        end)

        it('should handle pattern special characters as separators', function()
            local str = "hello.world.lua"
            assert.are.same({ 'hello', 'world', 'lua' }, str:split('.'))

            str = "hello%world%lua"
            assert.are.same({ 'hello', 'world', 'lua' }, str:split('%'))

            str = "hello$world$lua"
            assert.are.same({ 'hello', 'world', 'lua' }, str:split('$'))
        end)

        it('should handle unicode separators', function()
            local str = "hello→world→lua"
            assert.are.same({ 'hello', 'world', 'lua' }, str:split('→'))
        end)

        it('should handle mixed separators when using whitespace default', function()
            local str = "hello world\tlua\ntest"
            assert.are.same({ 'hello', 'world', 'lua', 'test' }, str:split())
        end)
    end)

    describe('is_empty()', function()
        it('should return true for empty strings', function()
            assert.is_true((""):is_empty())
        end)

        it('should return false for non-empty strings', function()
            assert.is_false(("hello"):is_empty())
            assert.is_false((" "):is_empty())
        end)
    end)

    describe('is_non_empty()', function()
        it('should return true for non-empty strings', function()
            assert.is_true(("hello"):is_non_empty())
            assert.is_true((" "):is_non_empty())
        end)

        it('should return false for empty strings', function()
            assert.is_false((""):is_non_empty())
        end)
    end)

    describe('is_alpha()', function()
        it('should return true for alphabetic strings', function()
            assert.is_true(("hello"):is_alpha())
            assert.is_true(("HELLO"):is_alpha())
            assert.is_true(("hElLo"):is_alpha())
        end)

        it('should return false for non-alphabetic strings', function()
            assert.is_false(("hello123"):is_alpha())
            assert.is_false(("hello!"):is_alpha())
            assert.is_false((" "):is_alpha())
            assert.is_false((""):is_alpha())
        end)
    end)

    describe('is_digit()', function()
        it('should return true for digit strings', function()
            assert.is_true(("123"):is_digit())
            assert.is_true(("0"):is_digit())
        end)

        it('should return false for non-digit strings', function()
            assert.is_false(("123a"):is_digit())
            assert.is_false(("12.3"):is_digit())
            assert.is_false(("-123"):is_digit())
            assert.is_false((" "):is_digit())
            assert.is_false((""):is_digit())
        end)
    end)

    describe('is_alphanumeric()', function()
        it('should return true for alphanumeric strings', function()
            assert.is_true(("hello123"):is_alphanumeric())
            assert.is_true(("123"):is_alphanumeric())
            assert.is_true(("hello"):is_alphanumeric())
        end)

        it('should return false for non-alphanumeric strings', function()
            assert.is_false(("hello 123"):is_alphanumeric())
            assert.is_false(("hello!"):is_alphanumeric())
            assert.is_false((" "):is_alphanumeric())
            assert.is_false((""):is_alphanumeric())
        end)
    end)

    describe('is_blank()', function()
        it('should return true for blank strings', function()
            assert.is_true((" "):is_blank())
            assert.is_true(("\t"):is_blank())
            assert.is_true(("\n"):is_blank())
            assert.is_true(("   "):is_blank())
            assert.is_true((""):is_blank())
        end)

        it('should return false for non-blank strings', function()
            assert.is_false(("hello"):is_blank())
            assert.is_false((" hello "):is_blank())
        end)
    end)

    describe('is_lower()', function()
        it('should return true for lowercase strings', function()
            assert.is_true(("hello"):is_lower())
            assert.is_true(("hello world"):is_lower())
        end)

        it('should return false for non-lowercase strings', function()
            assert.is_false(("Hello"):is_lower())
            assert.is_false(("HELLO"):is_lower())
            assert.is_false(("hello123"):is_lower())
            assert.is_false((""):is_lower())
        end)
    end)

    describe('is_upper()', function()
        it('should return true for uppercase strings', function()
            assert.is_true(("HELLO"):is_upper())
            assert.is_true(("HELLO WORLD"):is_upper())
        end)

        it('should return false for non-uppercase strings', function()
            assert.is_false(("Hello"):is_upper())
            assert.is_false(("hello"):is_upper())
            assert.is_false(("HELLO123"):is_upper())
            assert.is_false((""):is_upper())
        end)
    end)

    describe('starts_with()', function()
        it('should return true when string starts with prefix', function()
            assert.is_true(("hello"):starts_with("he"))
            assert.is_true(("hello"):starts_with("hello"))
            assert.is_true(("hello"):starts_with(""))
        end)

        it('should return false when string does not start with prefix', function()
            assert.is_false(("hello"):starts_with("lo"))
            assert.is_false(("hello"):starts_with("hello!"))
        end)
    end)

    describe('ends_with()', function()
        it('should return true when string ends with suffix', function()
            assert.is_true(("hello"):ends_with("lo"))
            assert.is_true(("hello"):ends_with("hello"))
            assert.is_true(("hello"):ends_with(""))
        end)

        it('should return false when string does not end with suffix', function()
            assert.is_false(("hello"):ends_with("he"))
            assert.is_false(("hello"):ends_with("hello!"))
        end)
    end)

    describe('prepend()', function()
        it('should prepend string with prefix', function()
            assert.equals("prefix-hello", ("hello"):prepend("prefix-"))
            assert.equals("hello", ("hello"):prepend(""))
            assert.equals("prefix", (""):prepend("prefix"))
        end)
    end)

    describe('append()', function()
        it('should append string with suffix', function()
            assert.equals("hello-suffix", ("hello"):append("-suffix"))
            assert.equals("hello", ("hello"):append(""))
            assert.equals("suffix", (""):append("suffix"))
        end)
    end)

    describe('trim_start()', function()
        it('should trim whitespace from start by default', function()
            assert.equals("hello", ("  hello"):trim_start())
            assert.equals("hello  ", ("  hello  "):trim_start())
            assert.equals("hello", ("\t\nhello"):trim_start())
        end)

        it('should trim specified characters from start', function()
            assert.equals("hello", ("---hello"):trim_start("-"))
            assert.equals("hello---", ("---hello---"):trim_start("-"))
        end)
    end)

    describe('trim_end()', function()
        it('should trim whitespace from end by default', function()
            assert.equals("hello", ("hello  "):trim_end())
            assert.equals("  hello", ("  hello  "):trim_end())
            assert.equals("hello", ("hello\t\n"):trim_end())
        end)

        it('should trim specified characters from end', function()
            assert.equals("hello", ("hello---"):trim_end("-"))
            assert.equals("---hello", ("---hello---"):trim_end("-"))
        end)
    end)

    describe('trim()', function()
        it('should trim whitespace from both ends by default', function()
            assert.equals("hello", ("  hello  "):trim())
            assert.equals("hello", ("\t\nhello\t\n"):trim())
        end)

        it('should trim specified characters from both ends', function()
            assert.equals("hello", ("---hello---"):trim("-"))
            assert.equals("hello", ("--hello--"):trim("-"))
        end)
    end)

    describe('pad_start()', function()
        it('should pad start with spaces by default', function()
            assert.equals("  hello", ("hello"):pad_start(7))
            assert.equals("hello", ("hello"):pad_start(5))
            assert.equals("hello", ("hello"):pad_start(3))
        end)

        it('should pad start with specified character', function()
            assert.equals("00hello", ("hello"):pad_start(7, "0"))
            assert.equals("..hello", ("hello"):pad_start(7, "."))
        end)

        it('should handle multi-character padding', function()
            assert.equals("ababahello", ("hello"):pad_start(10, "ab"))
        end)
    end)

    describe('pad_end()', function()
        it('should pad end with spaces by default', function()
            assert.equals("hello  ", ("hello"):pad_end(7))
            assert.equals("hello", ("hello"):pad_end(5))
            assert.equals("hello", ("hello"):pad_end(3))
        end)

        it('should pad end with specified character', function()
            assert.equals("hello00", ("hello"):pad_end(7, "0"))
            assert.equals("hello..", ("hello"):pad_end(7, "."))
        end)

        it('should handle multi-character padding', function()
            assert.equals("helloababa", ("hello"):pad_end(10, "ab"))
        end)
    end)

    describe('ensure_start()', function()
        it('should return original string if it starts with prefix', function()
            assert.equals("hello", ("hello"):ensure_start("he"))
            assert.equals("hello", ("hello"):ensure_start("hello"))
        end)

        it('should add minimal prefix to ensure string starts with prefix', function()
            assert.equals("prefix-hello", ("hello"):ensure_start("prefix-"))
            assert.equals("testhello", ("hello"):ensure_start("test"))
        end)
    end)

    describe('ensure_end()', function()
        it('should return original string if it ends with suffix', function()
            assert.equals("hello", ("hello"):ensure_end("lo"))
            assert.equals("hello", ("hello"):ensure_end("hello"))
        end)

        it('should add minimal suffix to ensure string ends with suffix', function()
            assert.equals("hello-suffix", ("hello"):ensure_end("-suffix"))
            assert.equals("hellotest", ("hellot"):ensure_end("test"))
        end)
    end)

    describe('ellipsis()', function()
        it('should truncate string and add ellipsis', function()
            assert.equals("he ...", ("hello"):ellipsis(2))
            assert.equals("hello ...", ("hello"):ellipsis(5))
            assert.equals("hello world ...", ("hello world"):ellipsis(11))
        end)

        it('should handle strings shorter than length', function()
            assert.equals("hello ...", ("hello"):ellipsis(10))
        end)
    end)

    describe('to_hex()', function()
        it('should convert string to hex representation', function()
            assert.equals("68656c6c6f", ("hello"):to_hex())
            assert.equals("776f726c64", ("world"):to_hex())
            assert.equals("", (""):to_hex())
        end)
    end)

    describe('collapse_ws()', function()
        it('should collapse multiple whitespace into single space by default', function()
            assert.equals("hello world", ("hello   world"):collapse_ws())
            assert.equals("hello world", ("hello\t\nworld"):collapse_ws())
        end)

        it('should preserve spaces in quotes when careful is true', function()
            assert.equals('hello "  world  " test', ("hello \"  world  \" test"):collapse_ws(true))
            assert.equals("hello '  world  ' test", ("hello '  world  ' test"):collapse_ws(true))
        end)

        it('should collapse all spaces when careful is false', function()
            assert.equals('hello " world " test', ("hello \"  world  \" test"):collapse_ws(false))
        end)
    end)

    describe('kill_to()', function()
        it('should remove content up to and including pattern', function()
            assert.equals("world", ("hello world"):kill_to("hello "))
            assert.equals("def", ("abc def"):kill_to("abc "))
        end)

        it('should handle pattern not found', function()
            assert.equals("hello world", ("hello world"):kill_to("xyz"))
        end)

        it('should handle empty string', function()
            assert.equals("", (""):kill_to("xyz"))
        end)
    end)
end)
