----------------------------------------------------------------------------------------------------------------------
-- Busted tests for the `lulu.Enum` module.
--
-- SPDX-FileCopyrightText:  2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------

-- Add "." and ".." to the package path for relative requires.
local dot = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]] or "./"
package.path = dot .. "?.lua;" .. dot .. "../?.lua;" .. package.path

local busted = require('busted')
local describe, it, before_each = busted.describe, busted.it, busted.before_each
local assert = require('luassert')

local Enum = require('lulu.Enum')

describe("Enum", function()

    describe("creation", function()
        it("should create an empty enum with no arguments", function()
            local empty = Enum:new()
            assert.is_not_nil(empty)
            assert.equals(0, #empty)
        end)

        it("should create an enum from an array of strings", function()
            local suit = Enum:new({ 'Clubs', 'Diamonds', 'Hearts', 'Spades' })
            assert.equals(4, #suit)
            assert.equals(1, suit.Clubs:tonumber())
            assert.equals(2, suit.Diamonds:tonumber())
            assert.equals(3, suit.Hearts:tonumber())
            assert.equals(4, suit.Spades:tonumber())
        end)

        it("should create an enum from a table with custom ordinals", function()
            local suit = Enum:new({
                Clubs = 1,
                Diamonds = 2,
                Hearts = 4,
                Spades = 8
            })
            assert.equals(4, #suit)
            assert.equals(1, suit.Clubs:tonumber())
            assert.equals(2, suit.Diamonds:tonumber())
            assert.equals(4, suit.Hearts:tonumber())
            assert.equals(8, suit.Spades:tonumber())
        end)

        it("should create an enum from a string", function()
            local suit = Enum:new([[Clubs, Diamonds = 4, Hearts, Spades]])
            assert.equals(4, #suit)
            assert.equals(1, suit.Clubs:tonumber())
            assert.equals(4, suit.Diamonds:tonumber())
            assert.equals(5, suit.Hearts:tonumber())
            assert.equals(6, suit.Spades:tonumber())
        end)

        it("should create an enum with associated data", function()
            local suit = Enum:new({
                Clubs = { color = 'black', symbol = '♣' },
                Diamonds = { color = 'red', symbol = '♦' },
                Hearts = { color = 'red', symbol = '♥' },
                Spades = { color = 'black', symbol = '♠' }
            })
            assert.equals(4, #suit)
            assert.equals('black', suit.Clubs.color)
            assert.equals('♦', suit.Diamonds.symbol)
            assert.equals('red', suit.Hearts.color)
            assert.equals('♠', suit.Spades.symbol)
        end)
    end)

    describe("ENUM function", function()
        it("should create an enum with a type name", function()
            ENUM('Suit')([[Clubs, Diamonds, Hearts, Spades]])
            assert.equals('Suit', Suit:type())
            assert.equals(4, #Suit)
        end)
    end)

    describe("enumerator operations", function()
        local suit

        before_each(function()
            suit = Enum:new({ 'Clubs', 'Diamonds', 'Hearts', 'Spades' })
        end)

        it("should convert enumerators to strings", function()
            assert.equals('Clubs', suit.Clubs:tostring())
            assert.equals('Diamonds', tostring(suit.Diamonds))
        end)

        it("should convert enumerators to numbers", function()
            assert.equals(1, suit.Clubs:tonumber())
            assert.equals(2, suit.Diamonds:tonumber())
        end)

        it("should compare enumerators", function()
            assert.is_true(suit.Clubs < suit.Diamonds)
            assert.is_true(suit.Hearts >= suit.Diamonds)
            assert.is_true(suit.Spades <= 4)
        end)

        it("should check if enumerator belongs to enum", function()
            assert.is_true(suit.Hearts:is_a(suit))
        end)

        it("should prevent modification of enumerators", function()
            local old_value = suit.Clubs:tonumber()
            suit.Clubs = 100 -- This should be ignored
            assert.equals(old_value, suit.Clubs:tonumber())
        end)
    end)

    describe("enum operations", function()
        local suit

        before_each(function()
            suit = Enum:new({ 'Clubs', 'Diamonds', 'Hearts', 'Spades' })
        end)

        it("should count enumerators", function()
            assert.equals(4, suit:count())
            assert.equals(4, #suit)
        end)

        it("should return sorted array of enumerators", function()
            local enums = suit:enumerators()
            assert.equals(4, #enums)
            assert.equals(1, enums[1]:tonumber())
            assert.equals(4, enums[4]:tonumber())
        end)

        it("should convert enum to string", function()
            local str = suit:tostring()
            assert.matches("Enum: .*Clubs.*Diamonds.*Hearts.*Spades", str)
        end)

        it("should add enumerators dynamically", function()
            suit:add_enumerator("Joker", 5)
            assert.equals(5, #suit)
            assert.equals(5, suit.Joker:tonumber())
        end)
    end)

    describe("error handling", function()
        it("should handle invalid enum creation arguments", function()
            local invalid = Enum:new(123) -- Invalid argument type
            assert.equals(0, #invalid)
        end)

        it("should prevent duplicate enumerator names", function()
            local suit = Enum:new({ 'Clubs' })
            suit:add_enumerator('Clubs', 2) -- Should be ignored
            assert.equals(1, #suit)
            assert.equals(1, suit.Clubs:tonumber())
        end)

        it("should handle invalid associated data", function()
            local suit = Enum:new()
            suit:add_enumerator('Clubs', 1, "invalid") -- Should ignore invalid associated data
            assert.equals(0, #suit)
        end)
    end)
end)
