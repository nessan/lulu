-----------------------------------------------------------------------------------------------------------------------
-- Busted tests for the `lulu.types` module.
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

local types = require('lulu.types')

describe('types module', function()
    describe('type function', function()
        it('should return standard types for non-table values', function()
            assert.equal('nil', types.type(nil))
            assert.equal('number', types.type(42))
            assert.equal('string', types.type("hello"))
            assert.equal('boolean', types.type(true))
            assert.equal('function', types.type(function() end))
        end)

        it('should return "table" for regular tables', function()
            assert.equal('table', types.type({}))
            assert.equal('table', types.type({ 1, 2, 3 }))
            assert.equal('table', types.type({ a = 1, b = 2 }))
        end)

        it('should return __name when tables have it as a string', function()
            local t = { __name = 'MyClass' }
            assert.equal('MyClass', types.type(t))

            local mt = { __name = 'WithMetatable' }
            local t2 = setmetatable({}, mt)
            assert.equal('table', types.type(t2)) -- The __name is in metatable, not in table directly

            local t3 = { __name = 123 }           -- __name is not a string
            assert.equal('table', types.type(t3))
        end)
    end)

    describe('is_integer function', function()
        it('should return true for integers', function()
            assert.is_true(types.is_integer(0))
            assert.is_true(types.is_integer(1))
            assert.is_true(types.is_integer(42))
            assert.is_true(types.is_integer(-10))
        end)

        it('should return false for non-integers', function()
            assert.is_false(types.is_integer(3.14))
            assert.is_false(types.is_integer(-2.5))
            assert.is_false(types.is_integer(0.0001))
            assert.is_false(types.is_integer('42'))
            assert.is_false(types.is_integer(nil))
            assert.is_false(types.is_integer({}))
            assert.is_false(types.is_integer(true))
        end)
    end)

    describe('is_positive_integer function', function()
        it('should return true for positive integers', function()
            assert.is_true(types.is_positive_integer(1))
            assert.is_true(types.is_positive_integer(42))
            assert.is_true(types.is_positive_integer(1000))
        end)

        it('should return false for zero, negative or non-integers', function()
            assert.is_false(types.is_positive_integer(0))
            assert.is_false(types.is_positive_integer(-1))
            assert.is_false(types.is_positive_integer(-42))
            assert.is_false(types.is_positive_integer(3.14))
            assert.is_false(types.is_positive_integer('42'))
            assert.is_false(types.is_positive_integer(nil))
            assert.is_false(types.is_positive_integer({}))
        end)
    end)

    describe('is_negative_integer function', function()
        it('should return true for negative integers', function()
            assert.is_true(types.is_negative_integer(-1))
            assert.is_true(types.is_negative_integer(-42))
            assert.is_true(types.is_negative_integer(-1000))
        end)

        it('should return false for zero, positive or non-integers', function()
            assert.is_false(types.is_negative_integer(0))
            assert.is_false(types.is_negative_integer(1))
            assert.is_false(types.is_negative_integer(42))
            assert.is_false(types.is_negative_integer(-3.14))
            assert.is_false(types.is_negative_integer('-42'))
            assert.is_false(types.is_negative_integer(nil))
            assert.is_false(types.is_negative_integer({}))
        end)
    end)

    describe('is_nan function', function()
        it('should return true for NaN values', function()
            assert.is_true(types.is_nan(0 / 0))
        end)

        it('should return false for non-NaN values', function()
            assert.is_false(types.is_nan(0))
            assert.is_false(types.is_nan(42))
            assert.is_false(types.is_nan(-3.14))
            assert.is_false(types.is_nan(1 / 0)) -- infinity
            assert.is_false(types.is_nan('NaN'))
            assert.is_false(types.is_nan(nil))
            assert.is_false(types.is_nan({}))
        end)
    end)
end)
