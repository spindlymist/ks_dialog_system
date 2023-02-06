local mod = DialogSystem

--[[----------------------------------------------------------------------------
map(array, f)

Transforms each element in array by a function f.

    array  (required)  the array to operate on
    f      (required)  the function to apply to each entry

    return    the transformed elements
--]]----------------------------------------------------------------------------
local function map(array, f)
    local values = {}

    for key, value in ipairs(array) do
        values[key] = f(value)
    end
    
    return values
end

--[[----------------------------------------------------------------------------
filterMap(array, f)

Transforms each element in array by a function f and filters out nil values.

    array  (required)  the array to operate on
    f      (required)  the function to apply to each entry

    return    the transformed elements, excluding nil values
--]]----------------------------------------------------------------------------
local function filterMap(array, f)
    local values = {}

    for key, value in ipairs(array) do
        local mappedValue = f(value)
        if mappedValue ~= nil then
            values[#values + 1] = mappedValue
        end
    end
    
    return values
end

--[[----------------------------------------------------------------------------
all(array, f)

Determines if every element in array satisfies a predicate f.

    array  (required)  the array to operate on
    f      (required)  the predicate to test each element with

    return    true if f returns true for all elements, false otherwise
--]]----------------------------------------------------------------------------
local function all(array, f)
    for _, value in ipairs(array) do
        if not f(value) then
            return false
        end
    end

    return true
end

return {
    map = map,
    filterMap = filterMap,
    all = all,
}
