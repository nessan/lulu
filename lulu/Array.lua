-----------------------------------------------------------------------------------------------------------------------
-- Lulu: An Array class for Lua.
--
-- Full Documentation:     https://nessan.github.io/lulu
-- Source Repository:      https://github.com/nessan/lulu
-- SPDX-FileCopyrightText: 2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------
require 'lulu.table'

local messages = require 'lulu.messages'
local callable = require 'lulu.callable'
local types    = require 'lulu.types'
local scribe   = require 'lulu.scribe'

local warn     = messages.warn
local insert   = table.insert
local remove   = table.remove
local sort     = table.sort

-----------------------------------------------------------------------------------------------------------------------
-- All Array instances share a common prototype table of methods.
-- In Lua's usual idiom for OOP this `Array` table also serves as the metatable for all the instances.
-----------------------------------------------------------------------------------------------------------------------

--- @class Array
local Array    = {}
Array.__index  = Array
Array.__name   = 'Array'

--- Is an object an instance of the Array class or a subclass of Array?
--- @param self Array The Array class.
--- @param obj any The object to check.
function Array:is_instance(obj)
    if type(obj) ~= 'table' then return false end
    local mt = getmetatable(obj)
    if rawequal(mt, self) then return true end
    while mt do
        mt = getmetatable(mt)
        if rawequal(mt, self) then return true end
    end
    return false
end

--- Returns the name for this class or subclass.
function Array:name()
    return self.__name
end

-----------------------------------------------------------------------------------------------------------------------
-- Methods to create Arrays and subclasses
-- In this section `self` will either be `Array` or possibly a subclass of `Array`.
-----------------------------------------------------------------------------------------------------------------------

--- Private function: Returns `true` if the argument is a Lua array (table indexed from 1 with no holes).
--- @param arg any The argument to check.
local function is_array(arg)
    if type(arg) ~= 'table' then return false end
    local j = 0
    for _ in pairs(arg) do
        j = j + 1
        if arg[j] == nil then return false end
    end
    return true
end

--- Create an `Array`.
--- @param ... any
--- @return Array array
--- - `arr = Array()` returns the empty `Array`: `[]`
--- - `arr = Array({1,2,3,4})` turns the Lua array `{1,2,3,4}` into an `Array`: `[1,2,3,4]` without copying.
--- - `arr = Array('a', 'b', 'c')` returns the `Array`: `['a', 'b', 'c']`.
--- - `arr = Array({1,2}, {3,4}, {5,6})` return the `Array`: `[{1,2}, {3,4}, {5,6}]` <br>
--- Note that `Array(...)` is a synonym for `Array:new(...)`.
function Array:new(...)
    -- What we do depends on the number of arguments.
    local nargs = select('#', ...)

    -- No arguments: Create an empty Array.
    if nargs == 0 then return setmetatable({}, self) end

    -- Single argument: Check if it is a Lua array and if so just return it as an Array.
    if nargs == 1 and is_array(...) then return setmetatable(..., self) end

    -- Single non-array arg or multiple args: Stick whatever we were given into a Lua array and return it as an Array
    return setmetatable({ ... }, self)
end

--- Synonym: `arr = Array(...)` is a synonym for `arr = Array:new(...)`
setmetatable(Array, { __call = Array.new })

--- Create a new `Array` with a specified size and repeated initial value or repeated calls to a value function.
--- @param n number The size of the Array.
--- @param value any The initial value for each element or a function that generates the values.
--- @param ... any Extra arguments pass to `value` if it is a function.
--- @return Array array
--- If `value` is a *function* then it is called for each element `i` as `value(i, ...)`
function Array:rep(n, value, ...)
    local retval = setmetatable({}, self)
    local fun = callable(value, false)
    if fun then
        for i = 1, n do insert(retval, fun(i, ...)) end
    else
        for i = 1, n do insert(retval, value) end
    end
    return retval
end

--- Create a new `Array` of numbers from `start` to `stop` with an optional `step` increment.
--- @param start number The first number in the range will be included.
--- @param stop number The last number in the range which may not be included depending on the `step`.
--- @param step? number The increment between numbers (default 1).
--- @return Array array
function Array:range(start, stop, step)
    local retval = setmetatable({}, self)
    step = step or 1

    -- Trivial case?
    if start == stop then return { start } end

    -- Handle mis-ordered ranges with a warning.
    if start < stop and step < 0 then
        warn("range(%d, %d, %d) is an empty array", start, stop, step)
        return retval
    end
    if start > stop and step > 0 then
        warn("range(%d, %d, %d) is an empty array", start, stop, step)
        return retval
    end

    -- Normal case.
    for i = start, stop, step do insert(retval, i) end
    return retval
end

--- Create a subclass of `Array` or a sub-subclass etc.
--- @param name string? Optional new name for the subclass.
--- @param tbl table? Optional table of methods to add to the subclass.
--- @return Array subclass The new subclass of `Array` with the `__index` metamethod set to itself.
--- **NOTE:** For a direct descendant of `Array` the metatable is set to `Array` just like any instance of `Array`.<br>
--- However, the `subclass.__index` metamethod is set to the subclass itself so instances of the subclass will inherit
--- methods from the subclass first. If a method is not found in the subclass it will be looked for in the superclass
--- (i.e. `Array`). This is the standard Lua way of doing OOP which works because metatables "chain".
function Array:subclass(name, tbl)
    -- Allow for the case where the `name` arg is omitted.
    if type(name) ~= 'string' then name, tbl = nil, name end

    -- Create a new instance of the superclass as usual and grab a reference as `subclass`
    local subclass = setmetatable(tbl or {}, self)

    -- Set the `__index` metamethod of the subclass to the subclass itself.
    subclass.__index = subclass

    -- Set the name of the subclass if one was provided.
    if name then subclass.__name = name end

    -- Lift the `__tostring` method from the superclass to the subclass.
    -- Lua's `print` and `tostring` methods do not seem to chain up through superclasses! (Bug?)
    if self.__tostring then subclass.__tostring = self.__tostring end

    -- Synonym: `arr = subclass(...)` is a synonym for `arr = subclass:new(...)`
    local mt = getmetatable(subclass)
    mt.__call = subclass.new
    return subclass
end

-----------------------------------------------------------------------------------------------------------------------
-- Copies and equality checks.
-- From here on `self` will be an *instance* of `Array` or of a subclass of Array,
-----------------------------------------------------------------------------------------------------------------------

--- Returns a new empty array that has the same `type` as this `Array`.
--- @param self Array The Array to copy the type/metatable from.
--- @return Array new_array The new empty array with the same metatable as `self`.
function Array:new_instance()
    return setmetatable({}, getmetatable(self))
end

--- Create a shallow copy of this `Array`.
--- @param self Array The Array to clone.
--- @return Array clone Shallow copy of `self` with the same metatable as `self`.
function Array:clone()
    local retval = self:new_instance()
    for i = 1, #self do insert(retval, self[i]) end
    return retval
end

--- Create a deep copy of this `Array` handling recursive or cyclical elements.
--- @param self Array The Array to clone.
--- @return Array copy Deep copy of `self` with the same metatable as `self`.
function Array:copy()
    return table.copy(self)
end

--- Private function: Deeply compare the content in two *Lua arrays* for equality. Metatables are ignored.
--- @param lhs any[] The left-hand side which is assumed to be a Lua array.
--- @param rhs any[] The right-hand side which is assumed to be a Lua array.
local function array_eq(lhs, rhs)
    -- Obvious edge case: If the lengths are different then the arrays are not equal.
    if #lhs ~= #rhs then return false end
    return table.eq(lhs, rhs, false)
end


--- Returns `true` if this `Array` is deeply equal to another `Array`.
--- @param self     Array   This array.
--- @param arr      Array   The array to compare against.
--- @param check_mt boolean Whether to check the metatables for equality (default `true`).
--- **NOTE:** You can use `Array:eq(arr, false)` to skip checking the metatables and just compare the content.
function Array:eq(arr, check_mt)
    if check_mt == nil then check_mt = true end
    if check_mt and getmetatable(self) ~= getmetatable(arr) then return false end
    return array_eq(self, arr)
end

--- Synonym: Overload the Lua '==' method with our own version.
function Array.__eq(lhs, rhs) return lhs:eq(rhs) end

-----------------------------------------------------------------------------------------------------------------------
-- Access Array elements and other basic bits of Array data.
-----------------------------------------------------------------------------------------------------------------------

--- Returns the number of elements in this `Array`.
--- @param self Array This array.
--- @return number size
function Array:size()
    return #self
end

--- Returns `true` if the `Array` empty.
--- @param self Array This array.
function Array:is_empty()
    return #self == 0
end

--- Returns `true` if all the elements have the same type `e_type` as determined by `types`.
--- @param self Array This array.
function Array:is_array_of(e_type)
    -- Edge case: An empty array has no elements at all, let alone elements of a specific type.
    if #self == 0 then return false end
    for i = 1, #self do
        if types(self[i]) ~= e_type then return false end
    end
    return true
end

--- Returns `true` if all the elements have a single type as determined by `types`.
--- @param self Array This array.
function Array:is_array_of_one_type()
    -- Edge case: An empty array has no elements so is considered to be of one type.
    if #self == 0 then return true end
    local e_type = types(self[1])
    for i = 2, #self do
        if types(self[i]) ~= e_type then return false end
    end
    return true
end

--- Returns `true` if all the elements are numbers.
--- @param self Array This array.
function Array:is_array_of_numbers(e_type)
    return self:is_array_of('number')
end

--- Returns `true` if all the elements are strings.
--- @param self Array This array.
function Array:is_array_of_strings(e_type)
    return self:is_array_of('string')
end

--- Returns a random value from this `Array`.
--- @param self Array This array.
--- @return any value Returns `nil` if the array is empty.
function Array:random()
    local n = #self
    return n > 0 and self[math.random(n)] or nil
end

--- Returns a specific `Array` element.
--- @param self Array This array.
--- @param i number The element index. Negative values for `i` count back from the end of the array.
--- @return any value
--- **NOTE:** No range check is done on the index `i`.
function Array:at(i)
    return i > 0 and self[i] or self[#self + i + 1]
end

--- Returns the first element or a default value if the `Array` is empty.
--- @param self Array This array.
--- @param default? any The default value to return if the array is empty.
--- @return any|nil The first element of the array or `default` if the array is empty.
function Array:first(default)
    return #self > 0 and self[1] or default
end

--- Returns the final element  or a default value if the `Array` is empty.
--- @param self Array This array.
--- @param default? any The default value to return if the array is empty.
--- @return any|nil The first element of the array or `default` if the array is empty.
function Array:final(default)
    return #self > 0 and self[#self] or default
end

--- Returns the value *and* index of the "extreme" element according to a comparator function.
--- @param self Array This array which should be non-empty.
--- @param cmp any The comparator function to apply to element pairs.
--- @param ... any Additional arguments to pass to the comparator function.
--- @return any|nil val The value of the "extreme" element.
--- @return number|nil index The index of the "extreme" element.
function Array:extreme(cmp, ...)
    if #self == 0 then return nil, nil end
    cmp = callable(cmp)
    if not cmp then return nil, nil end
    local i, v = 1, self[1]
    for j = 2, #self do if cmp(self[j], v, ...) then i, v = j, self[j] end end
    return v, i
end

--- Returns the index & value of the "maximum" element.
--- @param self Array This array which should be non-empty.
--- @return number|nil index The index of the "largest" element.
--- @return any|nil val The value of the "largest" element.
function Array:max()
    return self:extreme(function(a, b) return a > b end)
end

--- Returns the index & value of the "minimum" element.
--- @param self Array This array which should be non-empty.
--- @return number|nil index The index of the "smallest" element.
--- @return any|nil val The value of the "smallest" element.
function Array:min()
    return self:extreme(function(a, b) return a < b end)
end

-----------------------------------------------------------------------------------------------------------------------
-- Searches for specific elements in the Array.
-----------------------------------------------------------------------------------------------------------------------

--- Checks whether *all* the elements in the Array pass a predicate test.
--- @param self Array This array.
--- @param prd any The predicate function to apply to each element.
--- @param ... any Additional arguments to pass to the predicate function.
--- @return boolean result `true` if all elements pass the predicate test, `false` otherwise.
function Array:all(prd, ...)
    prd = callable(prd)
    if not prd then return false end
    for i = 1, #self do if not prd(self[i], ...) then return false end end
    return true
end

--- Checks whether *any* of the elements in the Array pass a predicate test.
--- @param self Array This array.
--- @param prd any The predicate function to apply to each element.
--- @param ... any Additional arguments to pass to the predicate function.
--- @return boolean result `true` if any element passed the predicate test, `false` otherwise.
function Array:any(prd, ...)
    prd = callable(prd)
    if not prd then return false end
    for i = 1, #self do if prd(self[i], ...) then return true end end
    return false
end

--- Checks whether *none* of the elements in the Array pass a predicate test.
--- @param self Array This array.
--- @param prd any The predicate function to apply to each element.
--- @param ... any Additional arguments to pass to the predicate function.
--- @return boolean result `true` if no element passed the predicate test, `false` otherwise.
function Array:none(prd, ...)
    prd = callable(prd)
    if not prd then return false end
    for i = 1, #self do if prd(self[i], ...) then return false end end
    return true
end

--- Returns the index of the first element which matches a value or `nil` if the search fails.
--- @param self Array This array.
--- @param value any The value to hunt for.
--- @param start? number The index to start searching from (default 1). Negative => from the array end.
--- @return number|nil index  The index of the first matching element in the array or `nil` if the search fails.
function Array:find(value, start)
    if not start then start = 1 elseif start < 0 then start = #self + start + 1 end
    for i = start, #self do if table.eq(self[i], value) then return i end end
    return nil
end

--- Returns the index of the first element which matches a value or `nil` if the search fails.
--- The search is done in reverse.
--- @param self Array This array.
--- @param value any The value to hunt for.
--- @param start? number The index to start searching from (default `#self`). Negative => from the array start.
--- @return number|nil index  The index of the first matching element in the array or `nil` if the search fails.
function Array:find_reverse(value, start)
    if not start then start = #self elseif start < 0 then start = #self + start + 1 end
    for i = start, 1, -1 do if table.eq(self[i], value) then return i end end
    return nil
end

--- Returns the index of the first element that satisfies a predicate function or `nil`  if the search fails.
--- @param self Array This array.
--- @param prd any The predicate function to apply to each element of `self`.
--- @param start? number The index to start searching from (default 1). Negative => from the array end.
--- @param ... any Additional arguments to pass to the predicate function.
--- @return number|nil index The index of the first element found that satisfies the predicate or `nil`.
--- @return any|nil ? val The array value at the index or `nil`.
--- @return any|nil p_val The value of the predicate evaluated at `val` or `nil` if the value is not found.
function Array:find_if(prd, start, ...)
    prd = callable(prd)
    if not prd then return nil, nil, nil end
    if not start then start = 1 elseif start < 0 then start = #self + start + 1 end
    for i = start, #self do
        local v = self[i]
        local p = prd(v, ...)
        if p then return i, v, p end
    end
    return nil, nil, nil
end

--- Returns the index of the first element that satisfies a predicate function or `nil`  if the search fails. <br>
--- The search is done in reverse.
--- @param self Array This array.
--- @param prd any The predicate function to apply to each element of `self`.
--- @param start? number The index to start searching from (default `#self`). Negative => from the array end.
--- @param ... any Additional arguments to pass to the predicate function.
--- @return number|nil index The index of the first element found that satisfies the predicate or `nil`.
--- @return any|nil ? val The element value at the index or `nil`.
--- @return any|nil p_val The value of the predicate evaluated at `val` or `nil` if the value is not found.
function Array:find_if_reverse(prd, start, ...)
    prd = callable(prd)
    if not prd then return nil, nil, nil end
    if not start then start = #self elseif start < 0 then start = #self + start + 1 end
    for i = start, 1, -1 do
        local v = self[i]
        local p = prd(v, ...)
        if p then return i, v, p end
    end
    return nil, nil, nil
end

-----------------------------------------------------------------------------------------------------------------------
-- Extracting Sub-Arrays
-----------------------------------------------------------------------------------------------------------------------

--- Private function: Given an array length `N` and two range arguments `m` and `n` return the first and final indices.
--- @param N number The length of the array.
--- @param m0 number If `m` is `nil` then use the range [m0, n0] as the default for [m, n].
--- @param n0 number If `n` is `nil` then use the range [m0, n0] as the default for [m, n].
--- @param m? number The first index of the range to extract. Negative `m` counts back from the end.
--- @param n? number The final index of the range to extract. Negative `n` counts back from the end.
--- @return number|nil first The first index of the range to extract.
--- @return number|nil final The final index of the range to extract.
--- **NOTE:** If the range is invalid we return `nil, nil` and issue a warning.
local function to_range(N, m0, n0, m, n)
    -- Start by assuming that m & n are missing and use the defaults.
    local first, final = m0, n0
    if m then
        if not n then
            -- One passed range argument: Extract the first or final `m` elements.
            if m >= 0 then
                first, final = 1, m
            else
                first, final = N + m + 1, N
            end
        else
            -- Two passed range arguments: Extract the elements from `m` to `n` inclusive allowing for negative `m` and `n`.
            first, final = m, n
            if first < 0 then first = N + first + 1 end
            if final < 0 then final = N + final + 1 end
        end
    end
    -- Check the range is valid.
    if first < 1 or final > N or first > final then
        warn("Bad range `%s` to `%s` for an array of length %d", tostring(m), tostring(n), N)
        return nil, nil
    end
    return first, final
end

--- Returns a new `Array` that is a shallow clone of a range of elements in this one.
--- @param self Array This array.
--- @param m? number With no `n` argument, we take the first or final `m` elements. Negative `m` count back from end.
--- @param n? number If given, we take the elements from `m` to `n` inclusive. Negative `n` count back from end.
--- @return Array take The clone with the indicated range of elements copied.
--- NOTE: The default no -argument call `arr:take()` returns a clone of `arr` with the final element removed.
function Array:take(m, n)
    local retval = self:new_instance()
    local N = #self
    if N == 0 then return retval end

    -- Get the range indices allow for all the variations of `m` and `n` & for the no-arg default case.
    local first, final = to_range(N, 1, N - 1, m, n)
    if not first then return retval end

    -- Copy the elements in the range.
    for i = first, final do insert(retval, self[i]) end
    return retval
end

--- Returns a new array that is a shallow clone of `self` without the final element.
--- @param self Array This array.
--- NOTE: This is functionally equivalent to `arr:take()`.
function Array:most()
    local retval = self:new_instance()
    local N = #self
    if N == 0 then return retval end

    -- Copy the elements in the range.
    for i = 1, N - 1 do insert(retval, self[i]) end
    return retval
end

--- Returns a new `Array` that is a shallow clone of this one with a range of elements removed.
--- @param self Array This array.
--- @param m? number With no `n` argument, we drop the first or final `m` elements. Negative `m` count back from end.
--- @param n? number If given, we drop the elements from `m` to `n` inclusive. Negative `n` count back from end.
--- @return Array drop The clone with the indicated range of elements removed.
--- NOTE: The default no-argument call `arr:drop()` returns a clone of `arr` with the first element removed.
function Array:drop(m, n)
    local retval = self:new_instance()
    local N = #self
    if N == 0 then return retval end

    -- Get the range indices allow for all the variations of `m` and `n` & for the no-arg default case.
    local first, final = to_range(N, 1, 1, m, n)
    if not first then return retval end

    -- Copy the elements outside the range.
    for i = 1, first - 1 do insert(retval, self[i]) end
    for i = final + 1, N do insert(retval, self[i]) end
    return retval
end

--- Returns a new array that is a shallow clone of `self` without the first element.
--- @param self Array This array.
--- NOTE: This is functionally equivalent to `arr:drop()`.
function Array:rest()
    local retval = self:new_instance()
    local N = #self
    if N == 0 then return retval end

    -- Copy the elements in the range.
    for i = 2, N do insert(retval, self[i]) end
    return retval
end

--- Returns a new `Array` that is a shallow clone of the elements in this one that pass a predicate test.
--- @param self Array This array.
--- @param prd any The predicate function to apply to each element.
--- @param ... any Additional arguments to pass to the predicate function.
--- @return Array result The array where each element passes the predicate test.
function Array:take_if(prd, ...)
    local retval = self:new_instance()
    prd = callable(prd)
    if not prd then return retval end
    for i = 1, #self do if prd(self[i], ...) then insert(retval, self[i]) end end
    return retval
end

--- Returns a new `Array` that is a shallow clone of this one without any elements that pass a predicate test.
--- @param self Array This array.
--- @param prd any The predicate function to apply to each element.
--- @param ... any Additional arguments to pass to the predicate function.
--- @return Array result The array where no element passes the predicate test.
function Array:drop_if(prd, ...)
    local retval = self:new_instance()
    prd = callable(prd)
    if not prd then return self:clone() end
    for i = 1, #self do if not prd(self[i], ...) then insert(retval, self[i]) end end
    return retval
end

--- Returns a new `Array` that is a shallow clone of the unique elements in this one.
--- @param self Array This array.
--- @return Array retval A new `Array` with the unique values.
function Array:drop_duplicates()
    local retval = self:new_instance()
    local seen = {}
    for _, v in ipairs(self) do
        if not seen[v] then
            retval[#retval + 1] = v
            seen[v] = true
        end
    end
    return retval
end

-----------------------------------------------------------------------------------------------------------------------
-- Methods that alter an Array's content and generally return `self` to allow for chaining.
-----------------------------------------------------------------------------------------------------------------------

--- Clears this `Array` in-place from an optional `start` index.
--- @param self Array    This array which is cleared in place.
--- @param start? number The index to start clearing from (default 1) -- negative value counts back from array end.
--- @return Array self   Allows for chaining.
function Array:clear(start)
    start = start or 1
    if start < 0 then start = #self + start + 1 end
    for i = start, #self do self[i] = nil end
    return self
end

--- Sorts this `Array` in-place & returns `self` to allow for chaining.
--- @param self Array  This array which is sorted in place.
--- @param cmp? any    The optional comparison function to use (defaults to by type and value).
--- @return Array self Allows for chaining.
function Array:sort(cmp)
    cmp = cmp and callable(cmp) or table.compare
    sort(self, cmp)
    return self
end

--- Shuffles this `Array` in place & returns `self` to allow for chaining.
--- @param self Array  This array which is shuffled in place.
--- @return Array self Allows for chaining.
function Array:shuffle()
    local n = #self
    for i = 1, n do
        local j = math.random(i, n)
        self[i], self[j] = self[j], self[i]
    end
    return self
end

--- Reverse the contents of this `Array` in-place & returns `self` to allow for chaining.
--- @param self Array  This array which is reversed in place.
--- @return Array self Allows for chaining.
function Array:reverse()
    local n = #self
    for i = 1, n // 2 do self[i], self[n - i + 1] = self[n - i + 1], self[i] end
    return self
end

--- Insert a value at position `pos` & return `self` to allow for chaining.
--- @param self Array   This array which is transformed in place.
--- @param i number     The position to insert the value at, shifting elements to the next-greater index if necessary.
--- @param value any    The value to insert.
--- @return Array self  Allows for chaining.
--- **NOTE:** Same as `table.insert(...)` so default `pos` is `#self + 1`.
function Array:insert(i, value)
    insert(self, i, value)
    return self
end

--- Efficiently remove the value at position `pos` & return the value removed (like `table.remove(...)`).
--- @param self Array This array which is transformed in place.
--- @param i number   The position to remove the value from -- negative values count back from the end of the array.
--- @return any value The value removed from the array of `nil` on failure.
--- **NOTE:** The default `pos` is `#self` so `arr:remove()` removes the final element.
function Array:remove(i)
    -- Lua handles last element removal efficiently.
    if not i then return remove(self) end
    -- Otherwise we have to shuffle down the elements.
    local N = #self
    local pos = i or N + i + 1
    if pos < 1 or pos > N then
        warn("Index %s is out of range for an array of length %d", tostring(i), N)
        return nil
    end
    local value = self[pos]
    for j = pos, N - 1 do self[j] = self[j + 1] end
    self[N] = nil
    return value
end

--- Add a value to the end of the array & return `self` to allow for chaining.
--- @param self Array  This array which is transformed in place.
--- @param value any   The value to add.
--- @return Array self Allows for chaining.
function Array:push(value)
    insert(self, value)
    return self
end

--- Remove the value from the end of the `Array` & return the value removed.
--- @param self Array  This array which is transformed in place.
--- @return Array self Allows for chaining.
--- **NOTE:** Same as `table.remove(...)` so we return the value removed (this is the exception to `return self`).
function Array:pop()
    return remove(self)
end

--- Append the passed arguments to the end of the `Array` & return `self` to allow for chaining.
--- @param self Array  This array which is transformed in place.
--- @param ... any     The values to append.
--- @return Array self Allows for chaining.
--- If any passed arg is a Lua array we append the *values* from that arg (unwrapping that arg by one level).
function Array:append(...)
    local args = { ... }
    for i = 1, #args do
        local ai = args[i]
        if is_array(ai) then
            for j = 1, #ai do insert(self, ai[j]) end
        else
            insert(self, ai)
        end
    end
    return self
end

--- Efficiently deletes the values from index `m` to index `n` inclusive  & returns `self` to allow for chaining.
--- @param self Array  This array which is transformed in place.
--- @param m? number   With no `n` argument, we delete the first or final `m` elements. Negative `m` count back from end.
--- @param n? number   If given, we delete the elements from `m` to `n` inclusive. Negative `n` count back from end.
--- @return Array self Allows for chaining.
--- **NOTE:** The default no-argument call `arr:delete()` removes the *first* element in `arr`.
function Array:delete(m, n)
    local N = #self
    if N == 0 then return self end

    -- Get the range indices allow for all the variations of `m` and `n` & for the no-arg default case.
    local first, final = to_range(N, 1, 1, m, n)
    if not first then return self end

    -- Shift down ...
    local len = final - first + 1
    for i = final + 1, N do self[i - len] = self[i] end

    -- Null out the trailing elements ...
    for i = N - len + 1, N do self[i] = nil end
    return self
end

--- Efficiently deletes all values **except** those from index `m` to index `n` inclusive.
--- @param self Array  This array which is transformed in place.
--- @param m? number   With no `n` argument, we delete the first or final `m` elements. Negative `m` count back from end.
--- @param n? number   If given, we delete the elements from `m` to `n` inclusive. Negative `n` count back from end.
--- @return Array self Allows for chaining.
--- **NOTE:** The default no-argument call `arr:delete()` removes the *final* element in `arr`.
function Array:keep(m, n)
    local N = #self
    if N == 0 then return self end

    -- Get the range indices allow for all the variations of `m` and `n` & for the no-arg default case.
    local first, final = to_range(N, 1, N - 1, m, n)
    if not first then return self end

    -- Shift down if necessary ...
    if first ~= 1 then
        for i = first, final do self[i - first + 1] = self[i] end
    end

    -- Null out the trailing elements ...
    local len = final - first + 1
    for i = len + 1, N do self[i] = nil end
    return self
end

--- Efficiently deletes all values **except** those that pass a predicate test
--- @param self Array  This array which is transformed in place.
--- @param prd any     The predicate function to apply to each element.
--- @param ... any     Additional arguments to pass to the predicate function.
--- @return Array self Allows for chaining.
function Array:keep_if(prd, ...)
    local N = #self
    if N == 0 then return self end

    prd = callable(prd)
    if not prd then return self end

    -- Shift element at index `i` down to index `pos` if it passes the predicate test.
    local pos = 1
    for i = 1, N do
        if prd(self[i], ...) then
            if i ~= pos then self[pos] = self[i] end
            pos = pos + 1
        end
    end
    for i = pos, N do self[i] = nil end
    return self
end

--- Efficiently deletes all values that pass a predicate test.
--- @param self Array  This array which is transformed in place.
--- @param prd any     The predicate function to apply to each element.
--- @param ... any     Additional arguments to pass to the predicate function.
--- @return Array self Allows for chaining.
function Array:delete_if(prd, ...)
    local N = #self
    if N == 0 then return self end

    prd = callable(prd)
    if not prd then return self end

    -- Shift element at index `i` down to index `pos` if it fails the predicate test.
    local pos = 1
    for i = 1, N do
        if not prd(self[i], ...) then
            if i ~= pos then self[pos] = self[i] end
            pos = pos + 1
        end
    end
    for i = pos, N do self[i] = nil end
    return self
end

-----------------------------------------------------------------------------------------------------------------------
-- Functional Methods: map, transform, fold, reduce, flatten, etc.
-----------------------------------------------------------------------------------------------------------------------

--- Returns a new `Array` which is the result of applying a function to each element in an array.
--- @param self Array This array.
--- @param fun any A function, callable table, or lambda to apply to each element.
--- @param ... any Additional arguments to pass to the function.
--- @return Array retval A new `Array` with the results of applying `fun` to each element.
function Array:map(fun, ...)
    local retval = self:new_instance()
    fun = callable(fun)
    if not fun then return retval end
    for i = 1, #self do retval[i] = fun(self[i], ...) end
    return retval
end

--- Transform an `Array` *in-place* by applying a function to each element. We return the transformed `Array`.
--- @param self Array This array.
--- @param fun any The function, callable table, or lambda to apply to each value.
--- @param ... any Additional arguments to pass to the function.
function Array:transform(fun, ...)
    fun = callable(fun)
    if not fun then return self end
    for i = 1, #self do self[i] = fun(self[i], ...) end
    return self
end

--- Returns a new `Array` which is the result of "folding" a function over this one.
--- @param self Array This array which should be non-empty.
--- @param fun any The function should take two arguments and return a single value.
--- @param x? any The initial value for the first call to the fold (defaults to `first()`).
--- See the `reduce` function which returns the final value of the `fold`
function Array:fold(fun, x)
    local retval = self:new_instance()
    -- Empty array? Never apply `fun`.
    if #self == 0 then
        insert(retval, x)
        return retval
    end

    -- The function to apply.
    fun = callable(fun)
    if not fun then return retval end

    -- If we are given an `x` the returned array will be an array of length `#self + 1`.
    -- Otherwise, it will have length `#self` and we use the first element of `self` as the first `x`.
    local start = x and 1 or 2
    x = x or self[1]
    insert(retval, x)
    for i = start, #self do
        x = fun(x, self[i])
        insert(retval, x)
    end
    return retval
end

--- Reduce this `Array` to a single value by applying a function to each element and accumulating the result.
--- @param self Array This array which should be non-empty.
--- @param fun any The function of two variables to apply to each (result, element) pair.
--- @param initial_value? any The initial value for the accumulator (default `self:first()`).
function Array:reduce(fun, initial_value)
    if #self == 0 then return initial_value end
    fun = callable(fun)
    if not fun then return initial_value end
    local retval = initial_value and fun(initial_value, self[1]) or self[1]
    for i = 2, #self do retval = fun(retval, self[i]) end
    return retval
end

--- Returns a new `Array` which is a flattened version of this one.
--- @param self Array This array.
--- @param depth? number The depth of the flattening (default 1).
--- @return Array retval A new `Array` with the elements of the original array flattened. <br>
--- For example, if `arr = [[1,2], [3,4], [5,6]]` then `arr:flatten()` returns `[1,2,3,4,5,6]`.
function Array:flatten(depth)
    depth = depth or 1
    local retval = self:new_instance()
    local function flatten_helper(arr, current_depth)
        if current_depth == 0 then
            for _, v in ipairs(arr) do insert(retval, v) end
        else
            for _, v in ipairs(arr) do
                if type(v) == 'table' then
                    flatten_helper(v, current_depth - 1)
                else
                    insert(retval, v)
                end
            end
        end
    end
    flatten_helper(self, depth)
    return retval
end

-----------------------------------------------------------------------------------------------------------------------
-- Methods that generate new arrays and occasionally tables by operating on this one.
-----------------------------------------------------------------------------------------------------------------------

--- Returns a new `Array` that has our elements in reverse order.
--- @param self Array This array.
--- @return Array retval
function Array:reversed()
    local retval = self:new_instance()
    for i = #self, 1, -1 do insert(retval, self[i]) end
    return retval
end

--- Returns a *map* of the values in this `Array` to their indices.
--- @param self Array This array.
--- @return table retval A **table** mapping the `Array` values to their indices.
--- For example, if `arr = ['a', 'b', 'c']` then `arr:to_map()` returns `[a = 1, b = 2, c = 3]`.
function Array:to_map()
    local retval = {}
    for i, v in ipairs(self) do if not retval[v] then retval[v] = i end end
    return retval
end

--- Creates a *set* from the values in this `Array`.
--- @param self Array This array.
--- @return table retval A **table** with the values of the `Array` as keys and `true` as the value.
--- For example, if `arr = ['a', 'b', 'c']` then `arr:to_set()` returns `[a = true, b = true, c = true]`.
function Array:to_set()
    local retval = {}
    for _, v in ipairs(self) do retval[v] = true end
    return retval
end

--- Returns a *map* of the values this `Array` to the number of times they occur.
--- @param self Array This array.
--- @return table retval A **table** mapping the values in the array to the number of times they occur.
--- For example: `['a', 'b', 'a', 'c', 'b']` -> `[a = 2, b = 2, c = 1]`
function Array:counts()
    local retval = {}
    for _, v in ipairs(self) do retval[v] = (retval[v] or 0) + 1 end
    return retval
end

-----------------------------------------------------------------------------------------------------------------------
-- Unions, Intersections, Differences, and Zips
-----------------------------------------------------------------------------------------------------------------------

--- Returns a new `Array` that has the elements from `self` along with those of the passed arguments.
--- @param self Array This array.
--- @param ...  any The other items to add in which can be anything -- non-table args are treated as one element arrays.
--- @return Array union A new Array of all the values with **no duplicates**.
function Array:union(...)
    local retval = self:drop_duplicates()
    local args = { ... }
    for i = 1, #args do
        local arr = args[i]
        if type(arr) == 'table' then
            for _, v in pairs(arr) do
                if not retval:find(v) then insert(retval, v) end
            end
        else
            if not retval:find(arr) then insert(retval, arr) end
        end
    end
    return retval
end

--- Private function: Fills `intersection` with the elements that are in common amongst the other passed arguments.
--- @param intersection Array The array to fill with the common elements.
--- @param ... any The other items to consider which can be anything -- non-table args are treated as one element arrays.
local function fill_intersection(intersection, ...)
    local args = { ... }
    if #args < 2 then
        warn(1, "Need at least two arguments to find values in common!")
        return
    end

    -- Helper function: Returns `true` if `val` is in the array `arr` otherwise returns `false`
    local function contains(arr, val)
        for _, v in ipairs(arr) do if table.eq(v, val) then return true end end
        return false
    end

    -- Handle any non-array arguments by converting them to single-element arrays.
    local N = #args
    for i = 1, N do if not is_array(args[i]) then args[i] = { args[i] } end end

    -- Sort the arrays by their lengths in increasing order to make the comparisons more efficient.
    sort(args, function(a, b) return #a < #b end)

    -- Look for unique common elements between the shortest array and all the others.
    for _, val in ipairs(args[1]) do
        if intersection:find(val) then goto continue end
        for i = 2, N do
            if not contains(args[i], val) then goto continue end
        end
        insert(intersection, val)
        ::continue::
    end
end

--- Returns a new `Array` that holds the elements that are in this one and all the other passed arguments.
--- @param self Array This array.
--- @vararg ... The other items to consider which can be anything -- non-table args are treated as one element arrays.
--- @return Array intersection A new sorted array of the values that are in common with no duplicates.
function Array:intersection(...)
    local retval = self:new_instance()
    fill_intersection(retval, self, ...)
    return retval
end

--- Returns a new `Array` that holds the elements of `self` that are not in `other`.
--- @param self Array This array.
--- @param other table Another `Array`
--- @param symmetric boolean? Defaults to `false`. If `true` we return the "symmetric" difference.
--- @return Array retval A new `Array` that is the difference of the two input arrays.
function Array:difference(other, symmetric)
    local retval = self:new_instance()
    if symmetric == nil then symmetric = false end
    local in_other = other:to_set()
    for _, v in ipairs(self) do if not in_other[v] then insert(retval, v) end end
    if symmetric then
        local in_self = self:to_set()
        for _, v in ipairs(other) do if not in_self[v] then insert(retval, v) end end
    end
    return retval
end

--- Private function: Fills `zip` by zipping the other passed arguments.
--- @param zip Array The array to fill.
--- @param ... any The other items to consider which can be anything -- non-table args are treated as one element arrays.
local function fill_zip(zip, ...)
    -- Handle any non-array arguments by converting them to single-element arrays.
    local args = { ... }
    for i = 1, #args do if not is_array(args[i]) then args[i] = { args[i] } end end

    -- Sort the arrays by their lengths in decreasing order.
    sort(args, function(a, b) return #a > #b end)

    -- Only need to consider the non-empty arrays.
    local N = 0
    for i = 1, #args do
        if #args[i] == 0 then break end
        N = N + 1
    end
    if N == 0 then return end

    -- The return value will be an array of the same length as the longest input array.
    local len = #args[1]
    for i = 1, len do
        local row = {}
        for j = 1, N do
            local arr = args[j]
            row[j] = arr[(i - 1) % #arr + 1]
        end
        insert(zip, row)
    end
end

--- Returns a new `Array` formed by zipping this one with other arguments.
--- @param self Array This array.
--- @param ... any These can be Lua arrays or non-table args that we treat as one element Lua arrays.
--- @return Array retval A new `Array` that will be the same length as the length of the longest input argument.
--- For example: `[1,2,3].zip({4, 5, 6}, {7, 8, 9})` -> `[{1, 4, 7}, {2, 5, 8}, {3, 6, 9}]`. <br>
--- If the arrays are of different lengths, we cycle through the shorter arrays. <br>
--- For example: `[1,2,3].zip({4, 5})` -> `[{1, 4}, {2, 5}, {3, 4}]`.
--- If any argument is not an table, it is treated as a single-element array.
--- For example: `[1,2,3].zip(4, 5)` -> `[{1, 4, 5}, {2, 4, 5}, {3, 4, 5}]`.
function Array:zip(...)
    local retval = self:new_instance()
    fill_zip(retval, self, ...)
    return retval
end

-----------------------------------------------------------------------------------------------------------------------
-- Concatenation
-----------------------------------------------------------------------------------------------------------------------

--- Returns a new `Array` that is the concatenation of `a` and `b`:  Can write `c = a .. b`.
--- @param a Array The first array.
--- @param b Array The second array.
--- @return Array retval A new `Array` that is the concatenation of the two input arrays.
function Array.__concat(a, b)
    local retval = a:clone()
    for i = 1, #b do insert(retval, b[i]) end
    return retval
end

-----------------------------------------------------------------------------------------------------------------------
-- Methods to turn Arrays to strings.
-----------------------------------------------------------------------------------------------------------------------

--- We use  a copy of Scribe's various options table but set `use_metatable` to `false` to avoid infinite loops.
local inline_options = scribe.clone(scribe.options.inline)
inline_options.use_metatable = false

local pretty_options = scribe.clone(scribe.options.pretty)
pretty_options.use_metatable = false

local classic_options = scribe.clone(scribe.options.classic)
classic_options.use_metatable = false

local alt_options = scribe.clone(scribe.options.alt)
alt_options.use_metatable = false

local inline_json_options = scribe.clone(scribe.options.inline_json)
inline_json_options.use_metatable = false

local json_options = scribe.clone(scribe.options.json)
json_options.use_metatable = false

--- Returns a one-line string representation of this `Array`.
--- @param self Array This array.
--- @return string str A one-line string for the array.
function Array:inline()
    if #self == 0 then return "[]" end
    return scribe.inline(self, inline_options)
end

--- Returns a "pretty" multiline string representation of this `Array`.
--- @param self Array This array.
--- @return string str A multi-line string for the array.
function Array:pretty()
    if #self == 0 then return "[]" end
    return scribe.pretty(self, pretty_options)
end

--- Returns a "classic" multiline string representation of this `Array`.
--- @param self Array This array.
--- @return string str A multi-line string for the array.
function Array:classic()
    if #self == 0 then return "[]" end
    return scribe.classic(self, classic_options)
end

--- Returns an alternate "pretty" multiline string representation of this `Array`.
--- @param self Array This array.
--- @return string str A multi-line string for the array.
function Array:alt()
    if #self == 0 then return "[]" end
    return scribe.alt(self, alt_options)
end

--- Returns a one-line "JSON" string representation of this `Array`.
--- @param self Array This array.
--- @return string str A one-line JSON-style string for the array.
function Array:inline_json()
    if #self == 0 then return "[]" end
    return scribe.inline_json(self, inline_json_options)
end

--- Returns a "JSON" multiline string representation of this `Array`.
--- @param self Array This array.
--- @return string str A multi-line JSON style string for the array.
function Array:json()
    if #self == 0 then return "[]" end
    return scribe.json(self, json_options)
end

--- Connect the standard `tostring` method to something sensible for this array `Array`.
--- @param self Array This array.
--- @return string str A one-line string representation of the array.
function Array:__tostring()
    return self:inline()
end

return Array
