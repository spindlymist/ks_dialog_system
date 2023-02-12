local mod = DialogSystem

--[[----------------------------------------------------------------------------
Constructs an array contaning the keys of `table`.

    @param table The table to pull keys from.
    @return The array of keys.
--]]----------------------------------------------------------------------------
local function keysOf(table)
    local keys = {}
    for key, _ in pairs(table) do
        keys[#keys+1] = key
    end

    return keys
end


--[[----------------------------------------------------------------------------
Overrides nil values in table `to` with values from table `from`.

    @param from The table to copy from.
    @param to The table to copy to.
    @param keys The keys to copy. If nil, the keys of `from` are used.
    @param map A function to map keys between tables. If nil, keys are unmapped.
    @return The modified to table (not a copy).
--]]----------------------------------------------------------------------------
local function inheritKeys(from, to, keys, map)
    keys = keys or keysOf(from)
    for _, from_key in ipairs(keys) do
        local to_key = (map and map(from_key)) or from_key
        if to[to_key] == nil then
            to[to_key] = from[from_key]
        end
    end

    return to
end

local Cursors = {
    pointer = mod.cursors.Pointer,
    underline = mod.cursors.Underline,
    highlight = mod.cursors.Highlight,
    tracer = mod.cursors.Tracer,
}

--[[----------------------------------------------------------------------------
Converts the idiosyncratic factory options to the standard format understood by
`DefaultRenderer`. Optionally inherits cursors and cursor options from a parent.

    @param options The options table to convert.
    @param parent The parent options' cursor table.
    @return A table mapping cursor classes to their options.
--]]----------------------------------------------------------------------------
local function normalizeCursors(options, parent)
    options.cursors = options.cursors or {}

    -- Copy quick options for stock cursors
    inheritKeys(options, options.cursors, keysOf(Cursors), function(key)
        return Cursors[key]
    end)

    -- Inherit cursors from parent
    if parent then
        inheritKeys(parent, options.cursors)
    end

    -- Convert booleans and copy tables
    local cursors = {}
    for key, entry in pairs(options.cursors) do
        if entry then
            cursors[key] = (entry == true and {}) or entry

            -- Inherit cursor options from parent
            if parent and parent[key] then
                inheritKeys(parent[key], cursors[key])
            end
        end
    end

    return cursors
end

--[[----------------------------------------------------------------------------
Converts the idiosyncratic factory options to the standard formats understood by
`DialogMenu`, `DefaultRenderer`, and `DefaultInputHandler`. Optionally inherits
options from a parent.

    @param options The options table to convert.
    @param parent The options to inherit. If nil, nothing is inherited.
    @return A table containing the normalized options for each component.
--]]----------------------------------------------------------------------------
local function normalizeOptions(options, parent)
    -- Handle nil/empty options
    if type(options) ~= "table" or next(options) == nil then
        return {
            renderer = mod.DefaultRenderer,
            inputHandler = mod.DefaultInputHandler,
        }
    end

    -- Render options
    local renderKeys = { "sign", "dock", "textColor", "activeTextColor" }
    local renderOptions = inheritKeys(options, {}, renderKeys)

    if parent then
        inheritKeys(parent.render, renderOptions, renderKeys)
    end

    renderOptions.cursors = normalizeCursors(options, parent and parent.render.cursors)

    -- Input options
    local inputKeys = { "keys" }
    local inputOptions = inheritKeys(options, {}, inputKeys)

    if parent then
        inheritKeys(parent.input, inputOptions, inputKeys)
    end

    -- Menu options
    local menuKeys = { "events" }
    local menuOptions = inheritKeys(options, {}, menuKeys)

    if parent then
        inheritKeys(parent.menu, menuOptions, menuKeys)
    end

    return {
        renderer = options.renderer or mod.DefaultRenderer,
        render = renderOptions,
        inputHandler = options.inputHandler or mod.DefaultInputHandler,
        input = inputOptions,
        menu = menuOptions,
    }
end

--[[----------------------------------------------------------------------------
Constructs a "template function" for creating menus with the specified options.

The template function takes a dialog tree to load and options to override. It
creates the menu and returns a "display function". The display function takes
options to temporarily override and displays the menu.

Typically, `withOptions` is used to create a global template used throughout the
story. The template function is called to load a dialog tree and set up options
for a particular screen/character. The display function is called to display the
menu and set up options for a particular situation.

Example:
    local createMenu = withOptions{
        underline = false,
    }

    function x1000y1000()
        local showMenu = createMenu{"MyCharacter/MyTree",
            textColor = {192, 92, 0},
            activeTextColor = {255, 128, 0},
        }

        function events.ShiftA()
            showMenu{dock = "right"}
        end

        function events.ShiftB()
            showMenu{dock = "left"}
        end
    end

    @param options The options table to convert.
    @return A function that creates a new menu and returns a function for
        displaying that menu.
--]]----------------------------------------------------------------------------
local function withOptions(options)
    -- Initialize/normalize template
    local template = normalizeOptions(options, {
        render = { cursors = {
            [mod.cursors.Pointer] = {},
            [mod.cursors.Highlight] = {},
            [mod.cursors.Underline] = {},
        } },
        input = {},
        menu = {},
    })

    -- Create template function
    return function(treeOrOptions)
        local tree, instance

        -- Disambiguate parameter
        if type(treeOrOptions) == "table" then
            tree = treeOrOptions.tree or treeOrOptions[1]
            instance = treeOrOptions
        else
            tree = treeOrOptions
        end

        instance = normalizeOptions(instance, template)

        -- Create menu
        local renderer = instance.renderer:new(instance.render)
        local inputHandler = instance.inputHandler:new(instance.input)
        local menu = mod.DialogMenu:new(renderer, inputHandler, instance.menu)
        menu:load(tree)

        -- Create display function
        return function(options)
            options = normalizeOptions(options, instance)
            menu:show(options.menu, options.render, options.input)
        end
    end
end

return {
    withOptions = withOptions
}
