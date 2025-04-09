----------------------------------------------------------------------------------------------------------------------
-- Busted tests for the `lulu.table` module.
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

require('lulu.table')

describe("Table utility functions", function()
    describe("table.intersection()", function()
        it("returns the intersection of two tables with same keys and values", function()
            local t1 = { a = 1, b = 2, c = 3 }
            local t2 = { a = 1, b = 2, d = 4 }

            local result = table.intersection(t1, t2)
            assert.are.same({ a = 1, b = 2 }, result)
        end)

        it("returns empty table when no common elements exist", function()
            local t1 = { a = 1, b = 2 }
            local t2 = { c = 3, d = 4 }

            local result = table.intersection(t1, t2)
            assert.are.same({}, result)
        end)

        it("returns empty table when one table is empty", function()
            local t1 = { a = 1, b = 2 }
            local t2 = {}

            local result = table.intersection(t1, t2)
            assert.are.same({}, result)
        end)

        it("handles more than two tables", function()
            local t1 = { a = 1, b = 2, c = 3, d = 4 }
            local t2 = { a = 1, b = 2, c = 3, e = 5 }
            local t3 = { a = 1, c = 3, f = 6 }

            local result = table.intersection(t1, t2, t3)
            assert.are.same({ a = 1, c = 3 }, result)
        end)

        it("requires values to match exactly for intersection", function()
            local t1 = { a = 1, b = "hello", c = { 1, 2 } }
            local t2 = { a = 1, b = "hello", c = { 1, 2 } }
            local t3 = { a = 1, b = "hello", c = { 1, 3 } }

            local result = table.intersection(t1, t2)
            assert.are.same({ a = 1, b = "hello", c = { 1, 2 } }, result)

            result = table.intersection(t1, t3)
            assert.are.same({ a = 1, b = "hello" }, result)
        end)

        it("warns and returns empty table when fewer than 2 tables provided", function()
            local t1 = { a = 1, b = 2 }
            local result = table.intersection(t1)
            assert.are.same({}, result)
        end)

        it("warns and returns empty table when non-table arguments provided", function()
            local t1 = { a = 1, b = 2 }
            local result = table.intersection(t1, "not a table")
            assert.are.same({}, result)
        end)
    end)

    describe("table.common_values()", function()
        it("returns values common to all tables", function()
            local t1 = { 1, 2, 3, 4 }
            local t2 = { 2, 3, 5, 6 }

            local result = table.common_values(t1, t2)
            table.sort(result)
            assert.are.same({ 2, 3 }, result)
        end)

        it("returns empty array when no common values exist", function()
            local t1 = { 1, 2 }
            local t2 = { 3, 4 }

            local result = table.common_values(t1, t2)
            assert.are.same({}, result)
        end)

        it("treats non-table arguments as single-element arrays", function()
            local t1 = { 1, 2, 3 }
            local value = 2

            local result = table.common_values(t1, value)
            assert.are.same({ 2 }, result)
        end)

        it("works with mixed table structures", function()
            local t1 = { 1, 2, 3 }
            local t2 = { a = 1, b = 2, c = 4 }

            local result = table.common_values(t1, t2)
            table.sort(result)
            assert.are.same({ 1, 2 }, result)
        end)

        it("handles more than two tables", function()
            local t1 = { 1, 2, 3, 4 }
            local t2 = { 2, 3, 5, 6 }
            local t3 = { 2, 7, 8 }

            local result = table.common_values(t1, t2, t3)
            assert.are.same({ 2 }, result)
        end)

        it("doesn't include duplicate values", function()
            local t1 = { 1, 2, 2, 3 }
            local t2 = { 2, 2, 3, 4 }

            local result = table.common_values(t1, t2)
            table.sort(result)
            assert.are.same({ 2, 3 }, result)
        end)

        it("warns and returns empty table when fewer than 2 arguments provided", function()
            local t1 = { 1, 2, 3 }
            local result = table.common_values(t1)
            assert.are.same({}, result)
        end)
    end)

    describe("table.common_keys()", function()
        it("returns keys common to all tables", function()
            local t1 = { a = 1, b = 2, c = 3 }
            local t2 = { a = 4, b = 5, d = 6 }

            local result = table.common_keys(t1, t2)
            table.sort(result)
            assert.are.same({ "a", "b" }, result)
        end)

        it("returns empty array when no common keys exist", function()
            local t1 = { a = 1, b = 2 }
            local t2 = { c = 3, d = 4 }

            local result = table.common_keys(t1, t2)
            assert.are.same({}, result)
        end)

        it("works with integer keys", function()
            local t1 = { [1] = "a", [2] = "b", [3] = "c" }
            local t2 = { [1] = "d", [2] = "e", [4] = "f" }

            local result = table.common_keys(t1, t2)
            table.sort(result)
            assert.are.same({ 1, 2 }, result)
        end)

        it("handles table keys", function()
            local key1 = { x = 1 }
            local key2 = { y = 2 }

            local t1 = { [key1] = "a", [key2] = "b" }
            local t2 = { [key1] = "c", [3] = "d" }

            local result = table.common_keys(t1, t2)
            assert.are.same({ key1 }, result)
        end)

        it("handles more than two tables", function()
            local t1 = { a = 1, b = 2, c = 3, d = 4 }
            local t2 = { a = 5, b = 6, c = 7, e = 8 }
            local t3 = { a = 9, c = 10, f = 11 }

            local result = table.common_keys(t1, t2, t3)
            table.sort(result)
            assert.are.same({ "a", "c" }, result)
        end)

        it("warns and returns empty table when fewer than 2 tables provided", function()
            local t1 = { a = 1, b = 2 }
            local result = table.common_keys(t1)
            assert.are.same({}, result)
        end)
    end)

    describe("table.is_table()", function()
        it("returns true for tables", function()
            assert.is_true(table.is_table({}))
            assert.is_true(table.is_table({ 1, 2, 3 }))
            assert.is_true(table.is_table({ a = 1 }))
        end)

        it("returns false and warns for non-tables", function()
            assert.is_false(table.is_table(42))
            assert.is_false(table.is_table("string"))
            assert.is_false(table.is_table(nil))
        end)
    end)

    describe("table.is_array()", function()
        it("returns true for proper arrays", function()
            assert.is_true(table.is_array({}))
            assert.is_true(table.is_array({ 1, 2, 3 }))
            assert.is_true(table.is_array({ "a", "b", "c" }))
        end)

        it("returns false for tables with holes", function()
            local t = { 1, 2, nil, 4 }
            assert.is_false(table.is_array(t))
        end)

        it("returns false for non-sequential indices", function()
            local t = { [2] = "b", [1] = "a", [4] = "d" }
            assert.is_false(table.is_array(t))
        end)
    end)

    describe("table.is_array_of()", function()
        it("validates arrays of numbers", function()
            assert.is_true(table.is_array_of({ 1, 2, 3 }, "number"))
            assert.is_false(table.is_array_of({ 1, "2", 3 }, "number"))
        end)

        it("validates arrays of strings", function()
            assert.is_true(table.is_array_of({ "a", "b", "c" }, "string"))
            assert.is_false(table.is_array_of({ "a", 2, "c" }, "string"))
        end)

        it("returns false for empty arrays", function()
            assert.is_false(table.is_array_of({}, "number"))
        end)
    end)

    describe("table.metadata()", function()
        it("analyzes simple tables", function()
            local t = { 1, 2, 3 }
            local md = table.metadata(t)
            assert.is_true(md[t].array)
            assert.equals(3, md[t].size)
            assert.equals(0, md[t].subs)
        end)

        it("handles nested tables", function()
            local child = { a = 1 }
            local parent = { x = child, y = { b = 2 } }
            local md = table.metadata(parent)
            assert.equals(2, md[parent].size)
            assert.equals(2, md[parent].subs)
            assert.equals(1, md[child].size)
        end)

        it("detects shared references", function()
            local shared = { 1, 2 }
            local t = { a = shared, b = shared }
            local md = table.metadata(t)
            assert.equals(2, md[shared].refs)
        end)
    end)

    describe("table.clone() and table.copy()", function()
        it("creates shallow copies", function()
            local orig = { a = 1, b = { x = 2 } }
            local clone = table.clone(orig)

            assert.are_not.equal(orig, clone)
            assert.are.same(orig, clone)
            assert.are.equal(orig.b, clone.b) -- Same reference for nested table
        end)

        it("creates deep copies", function()
            local orig = { a = 1, b = { x = 2 } }
            local copy = table.copy(orig)

            assert.are_not.equal(orig, copy)
            assert.are.same(orig, copy)
            assert.are_not.equal(orig.b, copy.b) -- Different reference for nested table
        end)

        it("handles recursive structures", function()
            local t = { a = 1 }
            t.self = t
            local copy = table.copy(t)

            assert.are_not.equal(t, copy)
            assert.equals(copy, copy.self) -- Preserves recursive structure
        end)
    end)

    describe("table.size()", function()
        it("returns correct count for simple tables", function()
            assert.equals(0, table.size({}))
            assert.equals(3, table.size({ 1, 2, 3 }))
            assert.equals(2, table.size({ a = 1, b = 2 }))
        end)

        it("counts all top-level elements in mixed tables", function()
            local t = {
                [1] = "one",
                ["two"] = 2,
                [{}] = "table key",
                nested = { 1, 2, 3 }
            }
            assert.equals(4, table.size(t))
        end)

        it("returns 0 for non-table arguments", function()
            assert.equals(0, table.size(42))
            assert.equals(0, table.size("string"))
            assert.equals(0, table.size(nil))
        end)
    end)

    describe("table.is_array_of_one_type()", function()
        it("returns true for arrays of single type", function()
            assert.is_true(table.is_array_of_one_type({ 1, 2, 3 }))
            assert.is_true(table.is_array_of_one_type({ "a", "b", "c" }))
            assert.is_true(table.is_array_of_one_type({ {}, {}, {} }))
        end)

        it("returns false for mixed type arrays", function()
            assert.is_false(table.is_array_of_one_type({ 1, "2", 3 }))
            assert.is_false(table.is_array_of_one_type({ 1, {}, "string" }))
        end)

        it("returns true for empty arrays", function()
            assert.is_true(table.is_array_of_one_type({}))
        end)

        it("returns false for non-array tables", function()
            assert.is_false(table.is_array_of_one_type({ a = 1, b = 2 }))
            assert.is_false(table.is_array_of_one_type({ [2] = "b", [1] = "a", [4] = "d" }))
        end)
    end)

    describe("table.counts()", function()
        it("counts occurrences in simple arrays", function()
            local result = table.counts({ 1, 2, 2, 3, 3, 3 })
            assert.are.same({
                [1] = 1,
                [2] = 2,
                [3] = 3
            }, result)
        end)

        it("counts string values", function()
            local result = table.counts({ "a", "b", "a", "c", "b", "a" })
            assert.are.same({
                ["a"] = 3,
                ["b"] = 2,
                ["c"] = 1
            }, result)
        end)

        it("handles mixed types", function()
            local obj = {}
            local result = table.counts({ 1, "a", obj, 1, "a", obj })
            assert.are.same({
                [1] = 2,
                ["a"] = 2,
                [obj] = 2
            }, result)
        end)

        it("returns empty table for empty input", function()
            assert.are.same({}, table.counts({}))
        end)

        it("returns empty table for non-table input", function()
            assert.are.same({}, table.counts(42))
            assert.are.same({}, table.counts("string"))
            assert.are.same({}, table.counts(nil))
        end)
    end)
end)
