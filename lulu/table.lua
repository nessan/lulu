-----------------------------------------------------------------------------------------------------------------------
-- Lulu: Extra Lua table methods.
--
-- Full Documentation:      https://nessan.github.io/lulu
-- Source Repository:       https://github.com/nessan/lulu
-- SPDX-FileCopyrightText:  2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------
local messages = require 'lulu.messages'
local types    = require 'lulu.types'
local callable = require 'lulu.callable'

local sort     = table.sort
local insert   = table.insert
local remove   = table.remove
local warn     = messages.warn

-----------------------------------------------------------------------------------------------------------------------
-- Type check & metadata methods.
-----------------------------------------------------------------------------------------------------------------------

--- Returns `true` if the argument is a table. Issues a warning if its not.
--- @param arg any The argument to check.
function table.is_table(arg)
    if type(arg) ~= 'table' then
        warn(1, "Expected a table argument but got a '%s'!", type(arg))
        return false
    end
    return true
end

--- Returns the number of top-level elements in a table.
--- @param tbl table     The table to check.
--- @return number count The number of top-level elements in the table.
function table.size(tbl)
    local count = 0
    if not table.is_table(tbl) then return count end
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

--- Private function: Returns `true` if the argument is a Lua array (table indexed from 1 with no holes).
--- @param arg any The argument to check.
function table.is_array(arg)
    if type(arg) ~= 'table' then return false end
    local j = 0
    for _ in pairs(arg) do
        j = j + 1
        if arg[j] == nil then return false end
    end
    return true
end

--- Returns `true` if the `arr` argument is an array where all the elements are of the given type `e_type`.
--- @param arr any[] The array to check.
--- @param e_type string We check that the elements all have this type.
--- **Note:** The element types are determined by `types.type` which is a slightly enhanced version of the standard.
function table.is_array_of(arr, e_type)
    if not table.is_array(arr) then return false end
    -- Edge case: An empty array has no elements at all, let alone elements of a specific type.
    if #arr == 0 then return false end
    for i = 1, #arr do
        if types.type(arr[i]) ~= e_type then return false end
    end
    return true
end

--- Returns `true` if the `arr` argument is an array where all the elements are of a single type.
--- @param arr any[] The array to check.
--- **Note:** The element types are determined by `types.type` which is a slightly enhanced version of the standard.
function table.is_array_of_one_type(arr)
    if not table.is_array(arr) then return false end
    -- Edge case: An empty array has no elements so is considered to be of one type.
    if #arr == 0 then return true end
    local e_type = types.type(arr[1])
    for i = 2, #arr do
        if types.type(arr[i]) ~= e_type then return false end
    end
    return true
end

--- Returns `true` if the `arr` argument is an array where all the elements are numbers
--- @param arr any[] The array to check.
function table.is_array_of_numbers(arr)
    return table.is_array_of(arr, 'number')
end

--- Returns `true` if the `arr` argument is an array where all the elements are strings.
--- @param arr any[] The array to check.
function table.is_array_of_strings(arr)
    return table.is_array_of(arr, 'string')
end

--- Returns a table of metadata for the argument and all its sub-table.
--- @param root_tbl table The table to examine which can contain circular references.
--- @return table md A table with a sub-table `md[t]` for each sub-table `t` encountered in `tbl` including itself.
--- - `md[t].array`  Boolean that is `true` if `t` is a Lua array (i.e., indexed from 1 with no holes).
--- - `md[t].size`   Number of elements in `t`. This is the number of key-value pairs in `t`.
--- - `md[t].subs`   Number of sub-tables in `t`. Path references do not count to this total.
--- - `map[t].refs`  Number of references to `t`. Greater than 1 if `t` is shared.
function table.metadata(root_tbl)
    -- Space for all the metadata.
    local md = {}
    if not table.is_table(root_tbl) then return md end

    -- All tables have at least one reference. Add one for the root in case it is referenced by an immediate child.
    md[root_tbl] = { refs = 1 }

    -- The recursive workhorse processes a `tbl` using a breadth first traversal.
    local function process(tbl)
        -- Initialize the data we collect. Assuming the table is an array until proven otherwise.
        local size, array, subs = 0, true, 0

        -- Breath first traversal so keep track of any unprocessed children to process later.
        local children = {}
        for _, v in pairs(tbl) do
            -- Increment the element count.
            size = size + 1

            -- If we still think that this is an array but hit a "hole" then `tbl` is not a Lua array.
            if array and tbl[size] == nil then array = false end

            -- From the metadata perspective, from here we only care about elements that are tables.
            if type(v) == 'table' then
                if md[v] then
                    -- Seen `v` before so increment the reference count -- `v` will be output as a path reference.
                    md[v].refs = md[v].refs + 1
                else
                    -- Haven't seen `v` before so it's a genuine sub-table.
                    subs = subs + 1
                    -- Add `v` to the array of tables to process later.
                    table.insert(children, v)
                    -- Give `v` a metadata entry in case an immediate sibling has a reference to it.
                    md[v] = { refs = 1 }
                end
            end
        end

        -- Store the computed metadata fields for `tbl`
        md[tbl].size, md[tbl].array, md[tbl].subs = size, array, subs

        -- Process all the children. Next time it will the grandchildren etc.
        for _, child in ipairs(children) do process(child) end
    end

    -- Kick things off by processing the root table.
    process(root_tbl)
    return md
end

-----------------------------------------------------------------------------------------------------------------------
-- Copying & Comparing tables.
-----------------------------------------------------------------------------------------------------------------------

--- Returns a shallow copy of a table. We do not copy any metatables.
--- @param obj any The object to copy. Typically a table but handles other types without issuing a warning.
function table.clone(obj)
    if type(obj) ~= 'table' then return obj end
    local retval = {}
    for k, v in pairs(obj) do retval[k] = v end
    return retval
end

--- Returns a deep copy of a table. We copy the metatable if it exists.
--- @param obj any The object to copy. Typically a table but handles other types without issuing a warning.
function table.copy(obj)
    if type(obj) ~= 'table' then return obj end

    -- Keep a cache of the tables we have already copied to avoid infinite recursion on cycles.
    cache = {}

    -- Workhorse function to copy a table. This is called recursively.
    local function process(tbl)
        -- If we have already copied this table, return the cached copy.
        if cache[tbl] then return cache[tbl] end

        -- Create a new table and store it in the cache under the `tbl` key.
        local retval = {}
        cache[tbl] = retval

        -- Copy the metatable if it exists.
        local mt = getmetatable(tbl)
        if mt then setmetatable(retval, mt) end

        -- Copy all the keys and values from `tbl` to `retval`. May recurse on the values.
        for k, v in pairs(tbl) do
            if type(v) == 'table' then retval[k] = process(v) else retval[k] = v end
        end

        return retval
    end

    -- Kick things off by processing the root table.
    return process(obj)
end

--- Returns `true` if `o1` & `o2` are identical in *content*. Does a deep comparison & handles recursive tables.
--- @param obj_1 any The first object to compare. Typically a table but handles other types without issuing a warning.
--- @param obj_2 any The second object to compare. Typically a table but handles other types without issuing a warning.
--- @param compare_mt? boolean If `true` (the default) we will compare metatables and use the `__eq` metamethod if it exists.
--- **NOTE:** This also handles tables where the keys are themselves tables.
function table.eq(obj_1, obj_2, compare_mt)
    -- By default we make use of any `__eq` metamethod.
    if compare_mt == nil then compare_mt = true end

    -- Keep a cache of the tables we have already compared to avoid infinite recursion on cycles.
    local cache = {}

    -- The recursive workhorse that does all the work.
    local function process(o1, o2)
        -- Types must match.
        local o1_type = type(o1)
        local o2_type = type(o2)
        if o1_type ~= o2_type then return false end

        -- Simplest case: `o1` and `o2` are not tables (note that in Lua this works for strings also).
        if o1_type ~= 'table' then return o1 == o2 end

        -- We have a table. If `o1` and `o2` are at the same address, they are the same table.
        if rawequal(o1, o2) then return true end

        -- Perhaps we've checked these two tables before? Prevent infinite recursion.
        if cache[o1] then return cache[o1] == o2 end
        if cache[o2] then return cache[o2] == o1 end
        cache[o1] = o2

        -- If requested: Compare metatables and use any `__eq` metamethod
        if compare_mt then
            local mt1, mt2 = getmetatable(o1), getmetatable(o2)
            if mt1 ~= mt2 then return false end
            if mt1 and mt1.__eq then return o1 == o2 end
        end

        -- Get the set of *all* the top-level keys in `o2` (both table keys and non-table keys).
        -- Also create a separate array of the keys that are themselves tables.
        local o2_set_of_keys = {}
        local o2_table_keys  = {}
        for k, _ in pairs(o2) do
            if type(k) == "table" then insert(o2_table_keys, k) end
            o2_set_of_keys[k] = true
        end

        -- Iterate through `o1` and try to find a match in the contents of `o2`.
        for k1, v1 in pairs(o1) do
            local v2 = o2[k1]
            if type(k1) ~= 'table' then
                if v2 == nil then return false end  -- o1 has a key that o2 doesn't have.
                o2_set_of_keys[k1] = nil
                if not process(v1, v2) then return false end
            else
                -- If `k1` is a table, we need to find an equivalent one in our array of table keys from `o2`.
                -- NOTE: We match on the key's *contents* not the key itself (this could be made into an option).
                local found_match = false
                for i, k2 in ipairs(o2_table_keys) do
                    if process(k1, k2) and process(v1, o2[k2]) then
                        remove(o2_table_keys, i)
                        o2_set_of_keys[k2] = nil
                        found_match = true
                        break
                    end
                end
                if not found_match then return false end
            end
        end

        -- Perhaps we haven't exhausted all the keys in `o2` yet? If so, it is "bigger" than `o1`.
        if next(o2_set_of_keys) then return false end

        -- All good
        return true
    end

    -- Kick things off by processing `obj_1` and `obj_2`
    return process(obj_1, obj_2)
end

-----------------------------------------------------------------------------------------------------------------------
-- Value and key lookups
-----------------------------------------------------------------------------------------------------------------------

--- Returns the "first" key for a top-level value in a table or `nil` if not found.
--- @param tbl table The table to look in.
--- @param value any The value to look for.
--- @return any key The key for the value or `nil` if not found.
--- **Note:** For a general Lua table the idea of *first* is nebulous as the ordering of key-value pairs is not defined.
function table.find(tbl, value)
    for k, v in pairs(tbl) do if table.eq(v, value) then return k end end
    return nil
end

--- Returns `true` if a particular value is present at the top level in a table.
--- @param tbl table The table to look in.
--- @param value any The value to look for.
function table.contains(tbl, value)
    return table.find(tbl, value) ~= nil
end

--- Returns the first key-value pair where `p = predicate(value,...)` is not `nil`. <br>
--- For example, `kv_where(t, "==", 42)` will return the first key-value pair where the value is 42.
--- @param tbl table The table to search.
--- @param predicate any A function, callable table, or lambda to use to check values.
--- @param ... any Additional arguments to pass to the predicate.
--- @return any|nil k The key of the found value or `nil` if not found.
--- @return any|nil v The value of the found value or `nil` if not found.
--- @return any|nil p The value of the predicate (`p = predicate(v,...)`) or `nil`.
--- #### Notes:
--- 1. The function actually returns the *trio* `k,v,p` where `p = predicate(v,...)` and `v = tbl[k]`.
--- 2. The notion of *first* for a general Lua table is nebulous as the ordering of key-value pairs is not defined.
--- 3. This function only looks at the top level values in the table. It is not recursive.
function table.find_if(tbl, predicate, ...)
    predicate = callable(predicate)
    if predicate then
        for k, v in pairs(tbl) do
            local p = predicate(v, ...)
            if p then return k, v, p end
        end
    end
    return nil, nil, nil
end

-----------------------------------------------------------------------------------------------------------------------
-- Maps and transformations
-----------------------------------------------------------------------------------------------------------------------

--- Returns a *new* table which is the result of applying a "function" to each *value* in a table. <br>
--- The returned table has the same keys as the input table.
--- @param tbl table The table to map over.
--- @param fun any   The function, callable table, or lambda to apply to each value.
--- @param ... any   Additional arguments to pass to the function.
function table.map(tbl, fun, ...)
    local retval = {}
    fun = callable(fun)
    if fun then
        for k, v in pairs(tbl) do retval[k] = fun(v, ...) end
    end
    return retval
end

--- Returns a *new* table which is the result of applying a "function" to the values from two tables. <br>
--- The returned table has the same keys as the first input table.
--- @param tbl1 table The first table to map over.
--- @param tbl2 table The second table -- we only consider values from this table where the key is also in `tbl1`.
--- @param fun any The function, callable table, or lambda to apply to each value pair.
--- @param ... any Additional arguments to pass to the function.
--- **Note:** The function is called as `fun(v1,v2,...)` and should return the new value.
function table.map2(tbl1, tbl2, fun, ...)
    local retval = {}
    fun = callable(fun)
    if fun then
        for k, v1 in pairs(tbl1) do
            local v2 = tbl2[k]
            if v2 ~= nil then retval[k] = fun(v1, v2, ...) end
        end
    end
    return retval
end

--- Returns a *new* table which is the result of applying a "function" to the keys and values of a table. <br>
--- @param tbl table The table to map over.
--- @param ... any Additional arguments to pass to the function.
--- @param fun any The function, callable table, or lambda to apply to each key-value pair.
--- @return table retval A table with keys and values described below.
--- ##### Notes:
--- - The function is called as `fun(k,v,...) and should return either one or two outputs.
--- - If it returns just one output `o`, the returned table will have an entry `retval[k] = o`
--- - If is returns two outputs `o1`, and `o2` then the new table has an entry `retval[o1] = o2`
--- - If `retval[o1]` is already occupied then it becomes an array of values `retval[o1] = {..., o2}`
function table.kv_map(tbl, fun, ...)
    local retval = {}
    fun = callable(fun)
    if fun then
        for k, v in pairs(tbl) do
            -- Call `fun` with both k & v and any other args where `fun` might return two outputs:
            local kr, vr = fun(k, v, ...)

            -- Perhaps we only got one output — if so, that output is a value not a key.
            -- We captured the value in the `kr` variable but really that is `vr`.
            if vr == nil then vr, kr = kr, k end

            -- Store `vr` under the key `kr` in `retval`.
            if retval[kr] then
                -- Putting multiple values under `kr` so we need an array for that.
                if type(retval[kr]) == 'table' then
                    -- Already have an array so pop in an extra value.
                    insert(retval[kr], vr)
                else
                    -- Not an array so create one and add the old and new values to that array.
                    local old_value = retval[kr]
                    retval[kr] = { old_value, vr }
                end
            else
                -- Probably the common case: Have nothing as yet for the key `kr`.
                retval[kr] = vr
            end
        end
    end
    return retval
end

--- Transform a table *in-place* by applying a function to each element. We return the transformed table.
--- @param tbl table The table to transform.
--- @param fun any The function, callable table, or lambda to apply to each value.
--- @param ... any Additional arguments to pass to the function.
function table.transform(tbl, fun, ...)
    fun = callable(fun)
    if fun then
        for k, v in pairs(tbl) do tbl[k] = fun(v, ...) end
    end
    return tbl
end

-----------------------------------------------------------------------------------------------------------------------
-- Methods to return arrays of keys and values & another to return an ordered iterator.
-----------------------------------------------------------------------------------------------------------------------

--- Fallback comparator method you can use to sort Lua objects -- by type first and then by value.
--- @param a any The first object to compare.
--- @param b any The second object to compare.
--- @return boolean `true` if `a` should come before `b`.
function table.compare(a, b)
    -- Note that "number" < "string", so numbers will be sorted before strings.
    local ta, tb = type(a), type(b)
    if ta ~= tb then
        return ta < tb
    elseif ta == 'table' or ta == 'boolean' or ta == 'function' then
        return tostring(a) < tostring(b)
    else
        return a < b
    end
end

--- Return an *array* of top-level table keys optionally sorted in some manner.
--- @param tbl table The table to get the keys from.
--- @param comparator? any The comparator to use for sorting the keys.
--- - If the comparator argument is explicitly set to `false` no sorting is done.
--- - If the comparator is not provided, the keys are sorted by their type and then by their value.
function table.keys(tbl, comparator)
    local retval = {}
    if not table.is_table(tbl) then return retval end
    for k in pairs(tbl) do insert(retval, k) end

    -- If the comparator is explicitly false, we don't sort the keys.
    if comparator == false then return retval end

    -- Otherwise, we sort the keys using the provided comparator or the default one.
    if comparator == nil then comparator = table.compare else comparator = callable(comparator) end
    sort(retval, comparator)
    return retval
end

--- Return an *array* of top-level values in a table optionally sorted in some manner.
--- @param tbl table The table to get the values from.
--- @param comparator? any The comparator to use for sorting the values.
--- If the comparator argument is false no sorting is done -- this is the default.
function table.values(tbl, comparator)
    local retval = {}
    if not table.is_table(tbl) then return retval end
    for _, v in pairs(tbl) do insert(retval, v) end

    -- If the comparator is missing or explicitly set to false, we don't sort the values.
    if comparator == nil or comparator == false then return retval end

    -- Otherwise, we sort the values using the provided comparator.
    comparator = callable(comparator)
    sort(retval, comparator)
    return retval
end

--- Returns an ordered iterator that traverses a table in a sorted key order.
--- @param comparator? any A function, callable table, or lambda to use to compare keys. Default is `compare`.
--- @return function iter Used as `for k, v in iter(tbl) do ... end`
--- Note: This function takes an optional comparator method and returns another function that takes a table. <br>
--- That function returns an iterator which is what you use in place of Lua's standard `pairs`.
function table.ordered_pairs(comparator)
    -- If the comparator is *explicitly* set to `false` we will just use Lua's standard `pairs` function.
    if comparator == false then return pairs end

    -- If the comparator is completely missing we use the `compare` above.
    comparator = comparator or table.compare

    -- Return a function that takes a table, sorts its keys, and returns another iterator function.
    return function(tbl)
        -- Ever time this iterator is called we increment the index and return the corresponding key & value.
        -- Note that once you run off the end of the key array the return is just `nil`, `nil`,
        local keys = table.keys(tbl, comparator)
        local i = 0
        return function()
            i = i + 1
            return keys[i], tbl[keys[i]]
        end
    end
end

-----------------------------------------------------------------------------------------------------------------------
-- Methods that convert tables to sets and counts.
-----------------------------------------------------------------------------------------------------------------------

--- Returns the *set* of values in a table.
--- @param tbl table The table to convert to a value set.
--- @return table set The keys are the values in `tbl` with corresponding value `true`
function table.set_of_values(tbl)
    local retval = {}
    if not table.is_table(tbl) then return retval end
    for _, v in pairs(tbl) do retval[v] = true end
    return retval
end

--- Returns the *set* of keys in a table.
--- @param tbl table The table to convert to a key set.
--- @return table set The keys are the keys in `tbl` with corresponding value `true`
function table.set_of_keys(tbl)
    local retval = {}
    if not table.is_table(tbl) then return retval end
    for k, _ in pairs(tbl) do retval[k] = true end
    return retval
end

--- Returns a *map* of the values in a table to the number of times they occur.
--- @param tbl table The table to count the value occurrences from.
--- @return table retval A **table** mapping the values in the table to the number of times they occur.
--- For example: `['a', 'b', 'a', 'c', 'b']` -> `[a = 2, b = 2, c = 1]`
function table.counts(tbl)
    local retval = {}
    if not table.is_table(tbl) then return retval end
    for _, v in pairs(tbl) do retval[v] = (retval[v] or 0) + 1 end
    return retval
end

-----------------------------------------------------------------------------------------------------------------------
-- Unions, intersections, and differences
-----------------------------------------------------------------------------------------------------------------------

--- Returns the union of two or more tables. Takes into account *both* keys and values.
--- @vararg table The tables to combine. Arguments must all be tables.
--- @return table union The union of the tables.
--- If a key is in more than one table, the returned table will have an array of values for that key.
function table.union(...)
    local retval = {}
    local args = { ... }
    for i = 1, #args do
        local tbl = args[i]
        if type(tbl) ~= 'table' then
            warn("Skipping arg[%d] which is a '%s' not a table!", i, type(tbl))
            goto next_arg
        end
        for key, val in pairs(tbl) do
            -- Simplest case: key is not in the union yet so add the key-value pair and continue.
            if not retval[key] then
                retval[key] = val
                goto next_kv
            end

            -- We don't duplicate keys holding the same value.
            local rv = retval[key]
            if table.eq(rv, val) then goto next_kv end

            -- The key is already in the union but the value is different--add it to the array of values for this key.
            if type(rv) ~= 'table' then
                retval[key] = { rv, val }
                goto next_kv
            end

            -- The key is in the union and it has an array of corresponding values already.
            -- If that array does not already have the new value, add it.
            if not table.contains(rv, val) then insert(rv, val) end

            -- Continue to the next key-value pair in the current table.
            ::next_kv::
        end
        ::next_arg::
    end
    return retval
end

--- Returns an *array* of all the values from the table arguments.
--- @vararg ... Two or more tables to consider. Non-table args are treated as one element arrays.
--- @return table union A new Lua array of all values without duplicates.
--- **NOTE:** This is different from the `union` method as we only consider element *values*.
function table.merged_values(...)
    local retval = {}
    local args = { ... }
    for i = 1, #args do
        local tbl = args[i]
        if type(tbl) == 'table' then
            for _, v in pairs(tbl) do
                if not table.contains(retval, v) then insert(retval, v) end
            end
        end
    end
    return retval
end

--- Returns an *array* of all the keys from the table arguments.
--- @vararg ... Two or more tables to consider.
--- @return table union A new Lua array of all keys without duplicates.
--- **NOTE:** This is different from the `union` method as we only consider element *keys*.
function table.merged_keys(...)
    local retval = {}
    local args = { ... }
    for i = 1, #args do
        local tbl = args[i]
        if type(tbl) == 'table' then
            for k, _ in pairs(tbl) do
                if not table.contains(retval, k) then insert(retval, k) end
            end
        end
    end
    return retval
end

--- Returns the intersection of two or more tables. Takes into account *both* keys and values.
--- @vararg ... The tables to combine.
--- @return table intersection The intersection of the tables.
--- Keys *and* values must be the same to make it into the intersection.
function table.intersection(...)
    -- Intersection of two tables: Keys and values must be the same to make it into the intersection.
    local function pairwise_intersection(t1, t2)
        local retval = {}
        for k, v in pairs(t1) do if t2[k] and table.eq(t2[k], v) then retval[k] = v end end
        return retval
    end

    -- Handle arbitrary number of tables: There has to be at least two tables to find an intersection.
    local args = { ... }
    if #args < 2 then
        warn("Need at least two tables to find the intersection!")
        return {}
    end
    for i = 1, #args do
        local tbl = args[i]
        if type(tbl) ~= 'table' then
            warn("arg[%d] is a '%s' not a table!", i, type(tbl))
            return {}
        end
    end
    local retval = pairwise_intersection(args[1], args[2])
    for i = 3, #args do retval = pairwise_intersection(retval, args[i]) end
    return retval
end

--- Returns a Lua array of the *values* that are in common between two or more tables.
--- @vararg table The tables to search. Non-table args are treated as one element arrays.
--- @return table vals An array of values that are in common between the tables.  The array will have no duplicates.
function table.common_values(...)
    local args = { ... }
    if #args < 2 then
        warn("Need at least two tables to find the values in common!")
        return {}
    end

    -- Handle any non-array arguments by converting them to single-element arrays.
    for i = 1, #args do if type(args[i]) ~= 'table' then args[i] = { args[i] } end end

    local retval = {}
    for _, v in pairs(args[1]) do
        if table.contains(retval, v) then goto continue end
        for i = 2, #args do if not table.contains(args[i], v) then goto continue end end
        insert(retval, v)
        ::continue::
    end
    return retval
end

--- Returns a Lua array of the *keys* that are in common between two or more tables.
--- @vararg table The tables to search.
--- @return table keys An array of keys that are in common between the tables.  The array will have no duplicates.
function table.common_keys(...)
    local args = { ... }
    if #args < 2 then
        warn("Need at least two tables to find the keys in common!")
        return {}
    end
    local retval = {}
    for k in pairs(args[1]) do
        if table.contains(retval, k) then goto continue end
        for i = 2, #args do if not args[i][k] then goto continue end end
        insert(retval, k)
        ::continue::
    end
    return retval
end

--- Returns a table of the elements in `t1` that are not in `t2`: `t1 - t2`.        <br>
--- Optionally, we can return the symmetric difference: `(t1 - t2) ∪ (t2 - t1)`.    <br>
--- This method Takes into account *both* keys and values in the two tables.
--- @param t1 table The first table.
--- @param t2 table The second table.
--- @param symmetric? boolean If `true`, we return the symmetric difference. (Default `false`)
function table.difference(t1, t2, symmetric)
    if symmetric == nil then symmetric = false end
    local retval = {}
    for k, v in pairs(t1) do
        if t2[k] and table.eq(t2[k], v) then goto continue end
        retval[k] = v
        ::continue::
    end
    if symmetric then
        for k, v in pairs(t2) do
            if t1[k] and table.eq(t1[k], v) then goto continue end
            if not retval[k] then
                retval[k] = v
                goto continue
            end
            if type(retval[k]) ~= 'table' then
                retval[k] = { retval[k], v }
            else
                insert(retval[k], v)
            end
            ::continue::
        end
    end
    return retval
end

--- Returns an array of the *values* in `t1` that are not in `t2`. <br>
--- Optionally returns an array of the values that are only in *one* of the two tables.
--- @param t1 table The first table to compare.
--- @param t2 table The second table to compare.
--- @param symmetric? boolean If `true`,  we return the symmetric unique values. (Default `false`)
--- **NOTE:** This is different from the `difference` method as we only consider element *values*.
function table.unique_values(t1, t2, symmetric)
    if symmetric == nil then symmetric = false end
    local retval = {}
    local in_t2 = table.set_of_values(t2)
    for _, v in pairs(t1) do if not in_t2[v] then insert(retval, v) end end
    if symmetric then
        local in_t1 = table.set_of_values(t1)
        for _, v in pairs(t2) do if not in_t1[v] then insert(retval, v) end end
    end
    return retval
end

--- Returns an array of the *keys* in `t1` that are not in `t2`: `(t1 - t2)`. <br>
--- Optionally returns an array of the keys that are only in *one* of the two tables.
--- @param t1 table The first table to compare.
--- @param t2 table The second table to compare.
--- @param symmetric? boolean If `true`, we return the symmetric unique keys. (Default `false`)
--- **NOTE:** This is different from the `difference` method as we only consider element *keys*.
function table.unique_keys(t1, t2, symmetric)
    if symmetric == nil then symmetric = false end
    local retval = {}
    local in_t2 = table.set_of_keys(t2)
    for k, _ in pairs(t1) do if not in_t2[k] then insert(retval, k) end end
    if symmetric then
        local in_t1 = table.set_of_keys(t1)
        for k, _ in pairs(t2) do if not in_t1[k] then insert(retval, k) end end
    end
    return retval
end
