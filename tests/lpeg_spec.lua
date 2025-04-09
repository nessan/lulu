-----------------------------------------------------------------------------------------------------------------------
-- Busted tests for the `lulu.callable` module.
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

local lpeg = require('lulu.xpeg')

describe('lpeg extensions', function()
    describe('patterns table', function()
        it('should have basic patterns defined', function()
            assert.is_table(lpeg.patterns)
            assert.truthy(lpeg.patterns.any)
            assert.truthy(lpeg.patterns.eos)
            assert.truthy(lpeg.patterns.alpha)
            assert.truthy(lpeg.patterns.digit)
        end)

        it('should match basic patterns correctly', function()
            assert.truthy(lpeg.patterns.alpha:match('a'))
            assert.truthy(lpeg.patterns.alpha:match('Z'))
            assert.falsy(lpeg.patterns.alpha:match('1'))

            assert.truthy(lpeg.patterns.digit:match('5'))
            assert.falsy(lpeg.patterns.digit:match('a'))

            assert.truthy(lpeg.patterns.alphanumeric:match('a'))
            assert.truthy(lpeg.patterns.alphanumeric:match('5'))
            assert.falsy(lpeg.patterns.alphanumeric:match('!'))
        end)

        it('should handle whitespace patterns', function()
            assert.truthy(lpeg.patterns.ws:match(' '))
            assert.truthy(lpeg.patterns.ws:match('\t'))
            assert.truthy(lpeg.patterns.ws:match('\n'))
            assert.falsy(lpeg.patterns.ws:match('a'))

            assert.truthy(lpeg.patterns.hs:match(' '))
            assert.truthy(lpeg.patterns.hs:match('\t'))
            assert.falsy(lpeg.patterns.hs:match('\n'))
        end)
    end)

    describe('number patterns', function()
        it('should match decimal numbers', function()
            local dec = lpeg.dec_number()
            assert.truthy(dec:match('123'))
            assert.truthy(dec:match('0'))
            assert.falsy(dec:match('abc'))

            -- With separator
            local dec_sep = lpeg.dec_number(',')
            assert.truthy(dec_sep:match('1,234,567'))
            assert.truthy(dec_sep:match('123'))
        end)

        it('should match hex numbers', function()
            local hex = lpeg.hex_number()
            assert.truthy(hex:match('0xFF'))
            assert.truthy(hex:match('0xabc123'))
            assert.truthy(hex:match('FF'))
            assert.falsy(hex:match('0xGG'))

            -- With separator
            local hex_sep = lpeg.hex_number('_')
            assert.truthy(hex_sep:match('0xFF_AA_BB'))
        end)

        it('should match float numbers', function()
            local float = lpeg.float_number()
            assert.truthy(float:match('123.456'))
            assert.truthy(float:match('-123.456'))
            assert.truthy(float:match('123.456e10'))
            assert.truthy(float:match('123.456E-10'))
            assert.truthy(float:match('.456'))
            assert.truthy(float:match('123.'))
            assert.falsy(float:match('abc'))
        end)
    end)

    describe('utility functions', function()
        it('should identify patterns correctly', function()
            assert.truthy(lpeg.is_pattern(lpeg.P('test')))
            assert.falsy(lpeg.is_pattern('test'))
            assert.falsy(lpeg.is_pattern(123))
        end)

        it('should handle whitespace trimming', function()
            local result = lpeg.patterns.trim_ws:match('  hello  world  ')
            assert.equals('hello  world', result)
        end)

        it('should collapse whitespace', function()
            local result = lpeg.patterns.collapse_ws:match('  hello   world  \t\n  test  ')
            assert.equals('hello world test', result)
        end)

        it('should delete whitespace', function()
            local result = lpeg.patterns.delete_ws:match('  hello   world  \t\n  test  ')
            assert.equals('helloworldtest', result)
        end)
    end)

    describe('anywhere pattern', function()
        it('should match patterns anywhere in string', function()
            local p = lpeg.anywhere(lpeg.P('test'))
            assert.truthy(p:match('this is a test'))
            assert.truthy(p:match('test this'))
            assert.truthy(p:match('testing'))
            assert.falsy(p:match('no match here'))
        end)
    end)

    describe('quoted string patterns', function()
        it('should match quoted strings', function()
            local p = lpeg.patterns.quoted
            assert.truthy(p:match('"hello world"'))
            assert.truthy(p:match('"hello \\"world\\""'))
            assert.falsy(p:match('"unclosed'))

            -- Custom delimiters
            assert.truthy(p:match("'hello world'"))
        end)
    end)
end)
