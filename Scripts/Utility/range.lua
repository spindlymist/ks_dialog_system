--[[----------------------------------------------------------------------------
range{array, start, finish, step}
range{array, start=###, finish=###, step=###}

This function returns a subset of an array.

    array   (required)               the array to operate on
    start   (default: 1)             first element to include.
    finish  (default: last element)  last element to include.
    step    (default: 1)             number of elements to advance by.

    return  the requested elements
--]]----------------------------------------------------------------------------

return function(args)
	local array = args[1]
	local start = args["start"] or args[2] or 1
	local finish = args["finish"] or args[3] or #array
	local step = args["step"] or args[4] or 1
	
	local elements = {}
	for i=start, finish, step do
		elements[#elements + 1] = array[i]
	end
	
	return elements
end