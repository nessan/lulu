-----------------------------------------------------------------------------------------------------------------------
-- Lulu: An Enum class for Lua.
--
-- Full Documentation:     https://nessan.github.io/lulu
-- Source Repository:      https://github.com/nessan/lulu
-- SPDX-FileCopyrightText: 2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------
require('lulu.table')

local messages   = require('lulu.messages')
local scribe     = require('lulu.scribe')

local warn       = messages.warn
local inline     = scribe.inline
local clone      = table.clone
local insert     = table.insert
local sort       = table.sort

--- @class Enum The prototype and metatable for all `Enum` instances.
--- @field __name string The type-name of the `Enum` (defaults to 'Enum', instances can supply a more descriptive name).
local Enum       = { __name = "Enum" }

--- @class Enumerator The base prototype and metatable for all `Enumerator` instances.
--- All enumerators within any `Enum` will share a common metatable that is a *clone* of this class. <br>
--- The base class provides common methods for all enumerators like `tostring`, `tonumber`, etc.     <br>
--- Enumerators within an `Enum` may add custom methods and data added to their own metatable.       <br>
--- The `Enumerator` class is not exported. You only access its instances through the `Enum` class.
local Enumerator = { __name = "Enumerator" }

--- Private table: Each `Enum` instance `E` has its own sub-table in the `enum_data` table with the following fields:
--- - `enum_data[E].mt`            The metatable for all `Enumerator` instances that belong to `E`.
--- - `enum_data[E].ordinal_array` The enumerators in `E` as an array sorted by ordinal value. Created on demand.
local enum_data  = {}
setmetatable(enum_data, { __mode = "k" })

--- Private table: Each `Enumerator` instance `e` has its own sub-table in the `enumerator_data` table:
--- - `enumerator_data[e].name`       The name of the enumerator which will be unique in the parent `Enum`.
--- - `enumerator_data[e].ordinal`    Numerical *ordinal* value to sort/compare enumerators. May be auto-generated.
--- - `enumerator_data[e].associated` An optional table of associated data for the enumerator.
--- Enumerators are opaque and all their data is kept in this private `enumerators` table.
local enumerator_data = {}
setmetatable(enumerator_data, { __mode = "k" })

--- Private function: Returns `true` if the argument is an `Enumerator` of some sort.
--- @param obj any The object to check.
local function is_enumerator(obj)
    return enumerator_data[obj] ~= nil
end

--- The index metamethod for `Enumerator` isn't the usual `Class.__index = Class`.             <br>
--- There can be associated data for an enumerator stored in the `associated` field of the `enumerator_data` table. <br>
--- Moreover, the metatable for an enumerator is a *clone* of `Enumerator` which may have extra custom methods.
--- @param self Enumerator This `Enumerator`.
--- @param key any         The key to look up.
--- **Note:** You get the enumerator's name with `e:tostring()` and its ordinal with `e:tonumber()`.
function Enumerator:__index(key)
    -- Perhaps we are just looking for a piece of associated data.
    local associated = enumerator_data[self].associated
    if associated and associated[key] then return associated[key] end

    -- If that fails we look for the key in the metatable for this enumerator which is a clone of `Enumerator`.
    -- It will have all the standard methods like `tostring` and `tonumber` and may have other custom methods.
    local mt = getmetatable(self)
    return mt[key]
end

--- Enumerators are immutable so we don't allow any changes to their fields.
--- @param self Enumerator This enumerator
--- @param key any         Trying to set the value of this key.
--- @param val any         Trying to set the key's value to this.
function Enumerator:__newindex(key, val)
    warn("Enumerators are immutable -- ignoring attempt to set `%s.%s` to  %s.", self:tostring(), key, inline(val))
end

--- Returns `true` if this `Enumerator` belongs to a particular `Enum`.
--- @param self Enumerator This `Enumerator`.
--- @param enum Enum       The `Enum` to check the enumerator belongs to.
--- **Example:** If `s = Suit.Clubs` then `s:is_a(Suit)` returns `true`.
function Enumerator:is_a(enum)
    local enumerators = enum_data[enum].enumerators
    local name = enumerator_data[self].name
    return enumerators[name] ~= nil
end

--- Returns the name of the enumerator so if `s = Suit.Clubs` then `s:tostring()` is "Clubs".
--- @param self Enumerator The `Enumerator` to convert to a string.
--- @return string identifier The name of the enumerator.
function Enumerator:tostring()
    return enumerator_data[self].name
end

--- Synonym: Connect Lua's `tostring()` method to our version.
Enumerator.__tostring = Enumerator.tostring

--- Returns an ordinal number for the enumerator.
--- @param self Enumerator The `Enumerator` to convert to a number.
function Enumerator:tonumber()
    return enumerator_data[self].ordinal or -math.huge
end

--- Compare an enumerator to a number or another enumerator.
function Enumerator.__lt(lhs, rhs)
    local l = is_enumerator(lhs) and lhs:tonumber() or tonumber(lhs)
    local r = is_enumerator(rhs) and rhs:tonumber() or tonumber(rhs)
    return l < r
end

--- Compare an enumerator to a number or another enumerator.
function Enumerator.__le(lhs, rhs)
    local l = is_enumerator(lhs) and lhs:tonumber() or tonumber(lhs)
    local r = is_enumerator(rhs) and rhs:tonumber() or tonumber(rhs)
    return l <= r
end

--- Compare an enumerator to another enumerator.
--- **Note:** Lua only calls this method if the two operands are both **tables** and not `nil`.
function Enumerator.__eq(lhs, rhs)
    local l = is_enumerator(lhs) and lhs:tonumber() or tonumber(lhs)
    local r = is_enumerator(rhs) and rhs:tonumber() or tonumber(rhs)
    return l == r
end

-----------------------------------------------------------------------------------------------------------------------
-- Enum "metamethods" etc.
-----------------------------------------------------------------------------------------------------------------------

--- The index metamethod for `Enum` isn't the usual `Class.__index = Class`. <br>
--- Need to allow for the fact that the enum data is stored outside the instance in `enum_data`. <br>
--- @param self Enum This `Enum`.
--- @param key any   The key to look up.
function Enum:__index(key)
    -- Perhaps we are just looking for an enumerator in this `Enum` e.g. `Suit.Clubs`
    local enumerators = enum_data[self].enumerators
    if enumerators[key] then return enumerators[key] end

    -- Otherwise try the class metatable which has the common methods like `tostring` etc.
    if Enum[key] then return Enum[key] end

    -- Perhaps we are after some custom data that has been added to this particular `Enum`.
    return rawget(self, key)
end

--- The enumerators in an `Enum` are immutable. However, other methods and data that can be set/changed.
--- @param self Enum  This `Enum`.
--- @param key string The key to set.
--- @param val any The value to set the key to.
function Enum:__newindex(key, val)
    local enumerators = enum_data[self].enumerators
    if enumerators[key] then
        warn("Enumerators are immutable -- ignoring attempt to set `%s.%s` to  %s.", self:type(), key, inline(val))
        return
    end
    rawset(self, key, val)
end

--- Returns `true` if the argument is an `Enum` of some sort.
--- @param obj any The object to check.
--- **Note:** This is a static method so you call it as `Enum.is_instance(obj)`.
function Enum.is_instance(obj)
    return enum_data[obj] ~= nil
end

--- Returns a type-name for this `Enum` which defaults to 'Enum'.
--- @param self Enum This `Enum`.
--- @return string? type_name The type-name of the `Enum`.
--- You can set the `__name` field in an `Enum` to get something descriptive. <br>
--- If you create an `Enum` using the `ENUM` function below that is done automatically.
function Enum:type()
    return self.__name or nil
end

--- Sets the type-name for this `Enum`.
--- @param self Enum   This `Enum`.
--- @param name string The type-name to set.
function Enum:set_type(name)
    self.__name = name
end

-----------------------------------------------------------------------------------------------------------------------
-- Enum: Creation methods for Enums and for Enumerators.
-----------------------------------------------------------------------------------------------------------------------

--- Private function: Returns a new `Enum` instance and creates some space for its private data in `enum_data`.
--- @param  enum_type string? An optional type-name for this `Enum` type (defaults to 'Enum').
--- @return Enum enum         The new blank `Enum`.
local function new_enum(enum_type)
    local enum = {}
    if enum_type then enum.__name = enum_type end
    enum_data[enum] = {}
    enum_data[enum].enumerators = {}
    return setmetatable(enum, Enum)
end

--- Creates/returns the base-class/metatable for the enumerators belonging to the `Enum` `self`.
--- @param  self Enum This `Enum`.
--- @return metatable mt All of this enum's enumerators share this metatable which is a clone of `Enumerator`.
--- **Note:** The metatable is a clone so you can add methods etc. to be shared by just this Enum's enumerators.
function Enum:mt()
    -- We cache the metatable on the first call
    if not enum_data[self].mt then
        enum_data[self].mt = clone(Enumerator)
    end
    return enum_data[self].mt
end

--- Private function: Returns a suggested ordinal for the next enumerator you are adding to an `Enum`.
--- @param  enum Enum This `Enum`.
--- @return number ordinal Computed by adding 1 to the largest ordinal in the existing enumerators for `enum`.
--- **Note** With no user set ordinals this returns consecutive integers starting at 1.
local function next_ordinal(enum)
    local enumerators = enum_data[enum].enumerators
    local max = -math.huge
    for _, enumerator in pairs(enumerators) do
        local ordinal = enumerator:tonumber()
        if ordinal > max then max = ordinal end
    end
    return max == -math.huge and 1 or max + 1
end

--- Creates and then adds an enumerator to `enum`. Returns nothing.
--- @param enum       Enum    The parent for the enumerator we are adding.
--- @param name       string  Identifier for the enumerator which must not clash with the others in the `enum`.
--- @param ordinal    any?    Optional ordinal value which need not be unique though it typically is.
--- @param associated any?    Optional table of extra *associated data* for this enumerator.
--- If the ordinal is missing we generate it by adding 1 to the largest ordinal found amongst the existing enumerators.
local function add_enumerator(enum, name, ordinal, associated)
    -- The enumerator name must be a string.
    local type_name = type(name)
    if type_name ~= 'string' then
        warn("Ignoring enumerator -- name has type %q, should be a string!", type(name))
        return
    end

    -- The enumerator name must be unique within the parent enum.
    if enum_data[enum].enumerators[name] then
        warn("Ignoring enumerator '%s' -- that name is already in use!", name)
        return
    end

    -- Adding a new enumerator so any cached ordinal-sorted array of enumerators is out of date.
    enum_data[enum].ordinal_array = nil

    -- Perhaps both optional args are missing?
    if ordinal == nil then
        -- Create a new enumerator and store its private data ...
        local enumerator = setmetatable({}, enum:mt())
        enumerator_data[enumerator] = { name = name, ordinal = next_ordinal(enum) }
        enum_data[enum].enumerators[name] = enumerator
        return
    end

    -- Perhaps the second of the two optional arguments is missing?
    if associated == nil then
        -- The `ordinal` arg might actually be the associated data.
        if type(ordinal) == 'table' then associated, ordinal = ordinal, nil end
    end

    -- Mock up an associated table if it is missing.
    associated = associated or {}

    -- If the ordinal is missing we use the ordinal from the associated table or generate one.
    if not ordinal then
        if associated.ordinal then
            ordinal = associated.ordinal
        else
            ordinal = next_ordinal(enum)
        end
    end

    -- At this point both args should be the correct types.
    local type_ordinal = type(ordinal)
    if type_ordinal ~= 'number' then
        warn("Ignoring enumerator -- the 'ordinal' arg is a %q, should be a number!", type_ordinal)
        return
    end
    local type_associated = type(associated)
    if type_associated ~= 'table' then
        warn("Ignoring enumerator -- the 'associated' arg is a %q, should be a table!", type_associated)
        return
    end

    -- Create a new enumerator and store its private data ...
    local enumerator = setmetatable({}, enum:mt())
    enumerator_data[enumerator] = { name = name, ordinal = ordinal }
    enum_data[enum].enumerators[name] = enumerator

    -- Clone the `associated` arg if it is non-empty but ignore any ordinal field.
    if next(associated) then
        enumerator_data[enumerator].associated = clone(associated)
        enumerator_data[enumerator].associated.ordinal = nil
    end
end


--- Private function: Create an `Enum` from a general table of key-value pairs.
--- @param tbl        table   A general table of data to create the `Enum` from. Not an array of strings.
--- @param enum_type  string? If this is present it will become the type-name of the created `Enum`.
--- @return Enum enum The new `Enum` created from the table.
--- #### Notes:
--- - The table keys must be strings and these become the Enumerator names.
--- - If a table value is a number that becomes the Enumerator ordinal.
--- - If a table value is a table then the table is stored as the associated data for the Enumerator.
--- - If that data has a numeric 'ordinal' field then we use it as the ordinal for the Enumerator.
--- - Otherwise we generate default ordinals for the Enumerators (typically consecutive integers starting at 1).
local function from_general_table(tbl, enum_type)
    local enum = new_enum(enum_type)
    for name, val in pairs(tbl) do
        add_enumerator(enum, name, val)
    end
    return enum
end

--- Private function: Creates an `Enum` from an array of strings that may have embedded custom values.
--- @param arr       string[] The array of strings to create the `Enum` from.
--- @param enum_type string?  If this is present it will become the type-name of the created `Enum`.
--- @return Enum enum The new `Enum` created from the array.
--- #### Examples:
-- Tha array `{'Clubs', 'Diamonds', 'Hearts', 'Spades'}` sets the ordinal values to the default 1, 2, 3, 4. <br>
-- The array `{'Clubs', 'Diamonds = 32', 'Hearts', 'Spades = 40'}` sets the ordinal values to 1, 32, 33, 40.
local function from_array_of_strings(arr, enum_type)
    local enum = new_enum(enum_type)
    local ord = 1
    for i = 1, #arr do
        -- See if we can split the entry into a 'name', 'ordinal' pair (we allow 'name = ordinal', 'name ordinal' etc.)
        -- The enumerator name can have underscores and hyphens but no other punctuation.
        local words = {}
        for word in arr[i]:gmatch("[%w_-]+") do insert(words, word) end

        -- Grab the enumerator name and possibly a custom value which must be a number.
        local enumerator = words[1]
        if words[2] then
            local v = tonumber(words[2])
            if not v then
                warn("Ignoring ordinal value for enumerator %q -- non-number value %q!", enum_type, inline(v))
            else
                ord = v
            end
        end

        -- Store this enumerator in the overall enumeration & increment the value for the next one.
        add_enumerator(enum, enumerator, ord)
        ord = ord + 1
    end
    return enum;
end

--- Private function: Creates an Enum from a (long) string like [[Clubs, Diamonds = 4 , Hearts, Spades]].
--- @param str string        The string to create the Enum from.
--- @param enum_type string? If this is present it will become the type-name of the created `Enum`.
--- @return Enum enum The new `Enum` created from the string.
local function from_string(str, enum_type)
    -- Remove Lua comments from the string.
    local s = str:gsub("%-%-[^\n]+", "")

    -- Remove any whitespace and ',' or '=', that were used to join enumerator names to custom ordinals.
    -- Parse the resulting words into an array of strings.
    local arr = {}
    for word in s:gmatch('([^,\r\n\t =]+)') do
        if not tonumber(word) then
            insert(arr, word)
        else
            arr[#arr] = arr[#arr] .. " " .. tonumber(word)
        end
    end
    -- Pass the array on to our earlier function that handles arrays of strings.
    return from_array_of_strings(arr, enum_type)
end

--- Create an `Enum` from various sources. Note that `Enum(...)` is a synonym for `Enum:new(...)`.
--- @param ... any The source data to create the `Enum` from.
--- @return Enum enum The new `Enum` created from the source data.
--- #### Examples:
---  - A Lua table with string keys and typically integer ordinals though our enumerators can be complex. <br>
---   `Suit = Enum{ Clubs = 1, Diamonds = 2, Hearts = 4, Spades = 8 }`. All enumerator ordinals have to be defined.
---  - A Lua table with string keys and arbitrary associated data for the corresponding enumerators. <br>
---   `Suit = Enum{ Clubs = { abbrev = 'C', color = 'black', ordinal = 1}, ... }`.                   <br>
---    If you don't specify the ordinals they will be generated as consecutive integers from 1.
---    However, Lua stores these hash tables in an arbitrary order so the ordinals may not get distributed as you'd think!
---  - A Lua array of strings (the enumerator names) that optionally can have embedded custom ordinal values. <br>
---   `Suit = Enum{ 'Clubs', 'Diamonds', 'Hearts', 'Spades' }` sets the values to the default `1, 2, 3, 4`.
---   `Suit = Enum{'Clubs', 'Diamonds = 22', 'Hearts', 'Spades = 40'}` sets the values to `1, 22, 23, 40`.
---  - A single (typically long) string that we parse enumerators and associated values from.
---   `Suit = Enum[[Clubs, Diamonds, Hearts = 4, Spades]]` sets the values to `1, 2, 4, 5`.
---    Parsing from a string like this can be useful if you are defining your own domain specific language.
--- ### Note:
--- In all cases, the enumerator names must be unique strings, the enumerator ordinals can have duplicates.
--- As shown in the examples if the ordinals are not specified we use consecutive integers starting at 1.
--- If you set a custom ordinal value for an enumerator the rest of the ordinal. values increment from there.
function Enum:new(...)
    -- What we do next depends on the number of arguments.
    local nargs = select('#', ...)

    -- No arg version creates an empty Enum that presumably will get values later using the `add_enumerator` method.
    if nargs == 0 then return new_enum() end

    -- One arg version can either be a single (long) string, an array of strings, or a general Lua map/table.
    local is_array_of_strings = table.is_array_of_strings
    if nargs == 1 then
        local targ = type(...)
        if targ == 'string' then return from_string(...) end
        if targ == 'table' then
            if is_array_of_strings(...) then
                return from_array_of_strings(...)
            else
                return from_general_table(...)
            end
        end
        warn("Don't know how to create an Enum from a %q", targ)
        return new_enum()
    end

    -- Two args could be a string name for the Enum and a table of enumerators in either order.
    local arg1, arg2 = select(1, ...), select(2, ...)
    if type(arg1) == 'string' and type(arg2) == 'table' then
        if is_array_of_strings(arg2) then return from_array_of_strings(arg2, arg1) end
        return from_general_table(arg2, arg1)
    elseif type(arg1) == 'table' and type(arg2) == 'string' then
        if is_array_of_strings(arg1) then return from_array_of_strings(arg1, arg2) end
        return from_general_table(arg1, arg2)
    end

    -- Otherwise multiple args should be a comma separated list of strings that we can encapsulate in an array.
    local arr = { ... }
    if not is_array_of_strings(arr) then
        warn("Don't know how to create an Enum from these arguments!")
        return new_enum()
    end
    return from_array_of_strings(arr)
end

--- Synonym: `Enum(...)` is a synonym for `Enum:new(...)`.
setmetatable(Enum, { __call = Enum.new })

--- An alternate way to create an `Enum`. <br>
--- @param enum_type string The name of the Enum to create.
--- @return function enum_maker A function that will create the Enum from the data passed to it.
--- #### Example:
--- `ENUM 'Suit' [[Clubs, Diamonds, Hearts, Spades]]` creates the `Enum` named `Suit`. <br>
--- The return value from `ENUM('Suit') is a *function* that creates the `Enum` `Suit` from the second string/array/map etc. <br>
--- This way of creating an `Enum` will look "natural" to a C/C++ programmer.
--- It has the added advantage that it sets the `Enum` name. <br>
--- **NOTE:** This is a global function that gets exported along with the Enum module.
function ENUM(enum_type)
    assert(type(enum_type) == 'string', "Enum name should be a string not a: " .. type(enum_type))
    local function enum_from(arg)
        local enum = Enum:new(arg)
        enum.__name = enum_type
        rawset(_G, enum_type, enum)
    end
    return enum_from
end

--- Creates and then adds an enumerator to `self`. Returns nothing.
--- @param self       Enum    The parent for the enumerator we are adding.
--- @param name       string  Identifier for the enumerator which must not clash with the others in the `enum`.
--- @param ordinal    any?    Optional ordinal value which need not be unique though it typically is.
--- @param associated any?    Optional table of extra *associated data* for this enumerator.
--- If the ordinal is missing we generate it by adding 1 to the largest ordinal found amongst the existing enumerators.
function Enum:add_enumerator(name, ordinal, associated)
    add_enumerator(self, name, ordinal, associated)
    return self
end

-----------------------------------------------------------------------------------------------------------------------
-- Other Enum methods:
-----------------------------------------------------------------------------------------------------------------------

--- Private function: Returns the array of enumerators in `enum` sorted in ordinal order.
--- @param enum Enum We grab the enumerators from this `Enum`.
--- **Note:** We cache the sorted array of enumerators under the `private[enum]['array']` key,
local function enumerators_as_sorted_array(enum)
    -- On the first call we fill the cache with the required array.
    local data = enum_data[enum]
    if not data.ordinal_array then
        local arr = {}
        for _, enumerator in pairs(data.enumerators) do insert(arr, enumerator) end
        sort(arr, function(e1, e2) return e1:tonumber() < e2:tonumber() end)
        data.ordinal_array = arr
    end
    return data.ordinal_array
end


--- Returns the number of enumerators in an `Enum`.
--- @param self Enum This `Enum`.
--- @return number count The number of enumerators in the `Enum`.
function Enum:count()
    return #enumerators_as_sorted_array(self)
end

--- Returns an iterator that traverses the enumerators in increasing ordinal order.
--- @param self Enum This `Enum`.
--- @return function iter Used as `for e in enum:iter() do ... end`
function Enum:iter()
    local enumerators = enumerators_as_sorted_array(self)
    local i = 0
    return function()
        i = i + 1
        return enumerators[i]
    end
end

--- Synonym: `Enum.__len` is a synonym for `Enum.count`.
Enum.__len = Enum.count

--- Returns a string representation of an `Enum`. <br>
--- This only shows the enumerator names and their associated values.
--- @param self    Enum   The `Enum` to convert to a string.
--- @param indent? string If non-empty, the output will be multi-line with each line indented by this string.
--- @return string str The string representation of the `Enum`.
--- #### Example:
--- If we have `ENUM 'Suit' [[Clubs, Diamonds, Hearts, Spades]]` <br>
--- Then `Suit:tostring()` returns "Suit: Clubs = 1, Diamonds = 2, Hearts = 3, Spades = 4". <br>
function Enum:tostring(indent)
    indent = indent or ''
    local sep = indent == '' and ', ' or ',\n'
    local left_delim = indent == '' and ': ' or ':\n'
    local enumerators = enumerators_as_sorted_array(self)
    local count = #enumerators
    local retval = self.__name .. left_delim
    for i = 1, count do
        local e          = enumerators[i]
        local name       = e:tostring()
        local ordinal    = e:tonumber()
        local associated = enumerator_data[e].associated
        local str        = string.format("[%d] %s", ordinal, name)
        if associated then str = str .. ' = ' .. inline(associated) end
        retval = retval .. indent .. str
        if i < count then retval = retval .. sep end
    end
    return retval
end

--- Returns an 'inline' string representation of an `Enum` on one line of text.
--- @param self Enum The `Enum` to convert to a string.
--- @return string str The inline string representation of the `Enum`.
function Enum:inline()
    return self:tostring()
end

--- Returns a 'pretty' string representation of an `Enum` on multiple lines of text.
--- @param self Enum The `Enum` to convert to a string.
--- @return string str The pretty string representation of the `Enum`.
function Enum:pretty()
    return self:tostring('    ')
end

--- Synonym: Connect Lua's `tostring()` method to our version.
Enum.__tostring = Enum.inline

-- Export the Enum class and also the `ENUM` function that is another way to create Enums.
-- NOTE: The Enumerator class is not exported and you only access its instances through the Enum class.
return Enum
