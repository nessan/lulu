-----------------------------------------------------------------------------------------------------------------------
-- Busted tests for the `lulu.paths` module.
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

local paths = require("lulu.paths")

describe("paths", function()
    describe("directory separator functions", function()
        it("returns the correct directory separator", function()
            local sep = package.config:sub(1, 1)
            assert.are.equal(sep, paths.os_directory_separator())
        end)

        it("correctly identifies Windows platform", function()
            local is_windows = package.config:sub(1, 1) == '\\'
            assert.are.equal(is_windows, paths.is_windows())
        end)

        it("correctly identifies Unix platform", function()
            local is_unix = package.config:sub(1, 1) == '/'
            assert.are.equal(is_unix, paths.is_unix())
        end)

        it("correctly identifies POSIX platform", function()
            local is_posix = package.config:sub(1, 1) == '/'
            assert.are.equal(is_posix, paths.is_posix())
        end)
    end)

    describe("path component functions", function()
        it("extracts components from a standard path", function()
            local dir, base, ext = paths.components("/Users/Jorge/test.lua")
            assert.are.equal("/Users/Jorge/", dir)
            assert.are.equal("test.lua", base)
            assert.are.equal("lua", ext)
        end)

        it("extracts components from a path without extension", function()
            local dir, base, ext = paths.components("/Users/Jorge/test")
            assert.are.equal("/Users/Jorge/", dir)
            assert.are.equal("test", base)
            assert.are.equal("", ext)
        end)

        it("extracts components from a relative path", function()
            local dir, base, ext = paths.components("test.lua")
            assert.are.equal("./", dir) -- Assuming Unix for this test
            assert.are.equal("test.lua", base)
            assert.are.equal("lua", ext)
        end)

        it("extracts components from a path with multiple dots", function()
            local dir, base, ext = paths.components("/Users/Jorge/test.min.lua")
            assert.are.equal("/Users/Jorge/", dir)
            assert.are.equal("test.min.lua", base)
            assert.are.equal("lua", ext)
        end)
    end)

    describe("dirname function", function()
        it("extracts directory from a standard path", function()
            local dir = paths.dirname("/Users/Jorge/test.lua")
            assert.are.equal("/Users/Jorge/", dir)
        end)

        it("extracts directory from a relative path", function()
            local dir = paths.dirname("test.lua")
            assert.are.equal("./", dir) -- Assuming Unix for this test
        end)
    end)

    describe("basename function", function()
        it("extracts basename from a standard path", function()
            local base = paths.basename("/Users/Jorge/test.lua")
            assert.are.equal("test.lua", base)
        end)

        it("extracts basename from a path with multiple dots", function()
            local base = paths.basename("/Users/Jorge/test.min.lua")
            assert.are.equal("test.min.lua", base)
        end)
    end)

    describe("extension function", function()
        it("extracts extension from a standard path", function()
            local ext = paths.extension("/Users/Jorge/test.lua")
            assert.are.equal("lua", ext)
        end)

        it("returns empty string for a path without extension", function()
            local ext = paths.extension("/Users/Jorge/test")
            assert.are.equal("", ext)
        end)

        it("extracts extension from a path with multiple dots", function()
            local ext = paths.extension("/Users/Jorge/test.min.lua")
            assert.are.equal("lua", ext)
        end)
    end)

    describe("filename function", function()
        it("extracts filename from a standard path", function()
            local filename = paths.filename("/Users/Jorge/test.lua")
            assert.are.equal("test", filename)
        end)

        it("returns the basename for a path without extension", function()
            local filename = paths.filename("/Users/Jorge/test")
            assert.are.equal("test", filename)
        end)

        it("extracts filename from a path with multiple dots", function()
            local filename = paths.filename("/Users/Jorge/test.min.lua")
            assert.are.equal("test.min", filename)
        end)
    end)

    describe("script path functions", function()
        -- These are harder to test deterministically, so we'll just check types
        it("returns a string for script_path", function()
            local path = paths.script_path()
            assert.is_string(path)
        end)

        it("returns a string for script_name", function()
            local name = paths.script_name()
            assert.is_string(name)
        end)
    end)

    describe("path join function", function()
        it("joins path segments with correct separator", function()
            local sep = paths.os_directory_separator()
            local path = paths.join("dir1", "dir2", "file.txt")
            assert.are.equal("dir1" .. sep .. "dir2" .. sep .. "file.txt", path)
        end)

        it("handles empty arguments", function()
            assert.are.equal("", paths.join())
            assert.are.equal("dir1", paths.join("dir1"))
        end)

        it("resets path when segment starts with separator", function()
            local sep = paths.os_directory_separator()
            local path = paths.join("dir1", "dir2", sep .. "absolute", "file.txt")
            assert.are.equal(sep .. "absolute" .. sep .. "file.txt", path)
        end)

        it("adds missing separators between segments", function()
            local sep = paths.os_directory_separator()
            local path = paths.join("dir1/", "file.txt")  -- intentionally using forward slash
            assert.are.equal("dir1/" .. "file.txt", path) -- should preserve the existing separator
        end)
    end)

    describe("file existence function", function()
        it("returns true /etc/hosts", function()
            local this_file = "/etc/hosts"
            assert.is_true(paths.exists(this_file))
        end)

        it("returns false for non-existent file", function()
            assert.is_false(paths.exists("this_file_should_not_exist_12345.xyz"))
        end)
    end)

    describe("directory check function", function()
        it("returns true for existing directory", function()
            -- This test assumes it's running from the project root
            local dir = "."
            assert.is_true(paths.is_directory(dir))
        end)

        it("returns false for regular files", function()
            -- This test assumes it's running from the project root
            local this_file = "tests/paths_spec.lua"
            assert.is_false(paths.is_directory(this_file))
        end)

        it("returns false for non-existent paths", function()
            assert.is_false(paths.is_directory("non_existent_directory_12345"))
        end)
    end)
end)
