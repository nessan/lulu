-----------------------------------------------------------------------------------------------------------------------
-- Busted tests for the `lulu.messages` module.
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

local messages = require("lulu.messages")

describe("Lulu messages module", function()
    local original_stdout, original_stderr
    local mock_stdout, mock_stderr

    setup(function()
        -- Save original stdout and stderr
        original_stdout = io.stdout
        original_stderr = io.stderr

        -- Create mock io objects to capture output
        mock_stdout = {
            buffer = "",
            write = function(self, str)
                self.buffer = self.buffer .. str
                return self
            end,
            flush = function() return true end
        }

        mock_stderr = {
            buffer = "",
            write = function(self, str)
                self.buffer = self.buffer .. str
                return self
            end,
            flush = function() return true end
        }
    end)

    before_each(function()
        -- Clear buffers before each test
        mock_stdout.buffer = ""
        mock_stderr.buffer = ""

        -- Redirect stdout and stderr to our mocks
        io.stdout = mock_stdout
        io.stderr = mock_stderr
    end)

    after_each(function()
        -- Restore stdout and stderr after each test
        io.stdout = original_stdout
        io.stderr = original_stderr
    end)

    describe("source_info", function()
        it("returns the correct function name, file, and line number", function()
            local func, file, line = messages.source_info()
            assert.is_string(func)
            assert.is_string(file)
            assert.is_number(line)
        end)

        it("handles stack frame offsets correctly", function()
            local function nested_function()
                local func, file, line = messages.source_info(1) -- Get info for the caller of nested_function
                return func, file, line
            end

            local function calling_function()
                local func, file, line = nested_function()
                return func, file, line
            end

            local func, file, line = calling_function()
            assert.equals("calling_function", func)
        end)
    end)

    describe("message", function()
        it("formats and outputs a simple message", function()
            messages.message("Test message")
            assert.matches("'[^']+' %([^:]+:%d+%):%s+Test message", mock_stdout.buffer)
        end)

        it("formats message with arguments", function()
            messages.message("Value: %d", 42)
            assert.matches("'[^']+' %([^:]+:%d+%):%s+Value: 42", mock_stdout.buffer)
        end)
    end)

    describe("info", function()
        it("formats and outputs an info message", function()
            messages.info("Information")
            assert.matches("%[INFO%] from '[^']+' %([^:]+:%d+%):%s+Information", mock_stdout.buffer)
        end)
    end)

    describe("warn", function()
        it("formats and outputs a warning message", function()
            messages.warn("Warning message")
            assert.matches("%[WARNING%] from '[^']+' %([^:]+:%d+%):%s+Warning message", mock_stdout.buffer)
        end)
    end)

    describe("fatal", function()
        local original_os_exit

        setup(function()
            -- Save original os.exit
            original_os_exit = os.exit
            -- Mock os.exit to prevent actual program termination
            os.exit = function() end
        end)

        teardown(function()
            -- Restore original os.exit
            os.exit = original_os_exit
        end)

        it("formats and outputs a fatal error message", function()
            messages.fatal("Fatal error")
            assert.matches("%[FATAL ERROR%] from '[^']+' %([^:]+:%d+%):%s+Fatal error", mock_stderr.buffer)
            assert.matches("The program will now exit", mock_stderr.buffer)
        end)
    end)
end)
