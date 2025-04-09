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

local callable = require("lulu.callable")

describe("callable module", function()
    describe("operators", function()
        it("should correctly implement basic arithmetic operators", function()
            assert.are.equal(5, callable.operators["+"](2, 3))
            assert.are.equal(-1, callable.operators["-"](2, 3))
            assert.are.equal(6, callable.operators["*"](2, 3))
            assert.are.equal(2, callable.operators["/"](6, 3))
            assert.are.equal(2, callable.operators["%"](5, 3))
            assert.are.equal(8, callable.operators["^"](2, 3))
        end)

        it("should correctly implement comparison operators", function()
            assert.is_true(callable.operators["=="](2, 2))
            assert.is_false(callable.operators["=="](2, 3))
            assert.is_true(callable.operators["~="](2, 3))
            assert.is_false(callable.operators["~="](2, 2))
            assert.is_true(callable.operators["<"](2, 3))
            assert.is_false(callable.operators["<"](3, 2))
            assert.is_true(callable.operators["<="](2, 2))
            assert.is_true(callable.operators[">"](3, 2))
            assert.is_false(callable.operators[">"](2, 3))
            assert.is_true(callable.operators[">="](3, 3))
        end)

        it("should correctly implement logical operators", function()
            assert.is_true(callable.operators["and"](true, true))
            assert.is_false(callable.operators["and"](true, false))
            assert.is_true(callable.operators["or"](true, false))
            assert.is_false(callable.operators["or"](false, false))
        end)

        it("should correctly implement special operators", function()
            assert.are.equal(3, callable.operators["#"]("abc"))
            assert.are.equal("hello world", callable.operators[".."]("hello ", "world"))
            assert.is_true(callable.operators["~"]("hello world", "world"))
            assert.is_false(callable.operators["~"]("hello world", "banana"))

            local t = { 10, 20, 30 }
            assert.are.equal(20, callable.operators["[]"](t, 2))

            local function add(a, b) return a + b end
            assert.are.equal(5, callable.operators["()"](add, 2, 3))

            local result = callable.operators["{}"](1, 2, 3)
            assert.are.equal(1, result[1])
            assert.are.equal(2, result[2])
            assert.are.equal(3, result[3])

            assert.are.equal(42, callable.operators[""]({ 42 })[1])
        end)
    end)

    describe("lambda", function()
        it("should create functions from lambda strings with named parameters", function()
            local add = callable.lambda("|a, b| a + b")
            assert.are.equal(5, add(2, 3))

            local multiply = callable.lambda("|x,y| x * y")
            assert.are.equal(6, multiply(2, 3))
        end)

        it("should create functions from lambda strings with anonymous parameter", function()
            local increment = callable.lambda("_ + 1")
            assert.are.equal(3, increment(2))

            local double = callable.lambda("_ * 2")
            assert.are.equal(4, double(2))
        end)

        it("should return nil for invalid lambda strings", function()
            local spy = spy.on(require("lulu.messages"), "warn")

            assert.is_nil(callable.lambda("invalid lambda"))
            --assert.spy(spy).was_called()

            assert.is_nil(callable.lambda("invalid lambda", false))
            --assert.spy(spy).was_called(1) -- Still only once, not twice
        end)
    end)

    describe("callable", function()
        it("should return functions as is", function()
            local function test_func() return "hello" end
            assert.are.equal(test_func, callable.callable(test_func))
        end)

        it("should handle callable tables", function()
            local obj = setmetatable({}, { __call = function() return "called" end })
            assert.are.equal(obj, callable.callable(obj))
        end)

        it("should convert operator strings to functions", function()
            local add = callable.callable("+")
            assert.are.equal(5, add(2, 3))
        end)

        it("should convert lambda strings to functions", function()
            local add = callable.callable("|a, b| a + b")
            assert.are.equal(5, add(2, 3))
        end)

        it("should return nil for non-callable objects", function()
            local spy = spy.on(require("lulu.messages"), "warn")

            assert.is_nil(callable.callable(123))
            assert.spy(spy).was_called()

            assert.is_nil(callable.callable(123, false))
            assert.spy(spy).was_called(1) -- Still only once
        end)
    end)

    describe("is_callable", function()
        it("should correctly identify callable objects", function()
            local function test_func() end
            local test_table = setmetatable({}, { __call = function() end })

            assert.is_true(callable.is_callable(test_func))
            assert.is_true(callable.is_callable(test_table))
            assert.is_true(callable.is_callable("+"))
            assert.is_true(callable.is_callable("|x| x*2"))

            assert.is_false(callable.is_callable(123))
            assert.is_false(callable.is_callable("not a lambda"))
            assert.is_false(callable.is_callable({}))
        end)
    end)
end)
