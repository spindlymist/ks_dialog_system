local mod = DialogSystem

local Patterns = {}
Patterns.DelimRepeated = "%$+"
Patterns.Identifier = "([_%a][_%w]*)"
Patterns.ScopedIdentifier = Patterns.Identifier .. ":" .. Patterns.Identifier
Patterns.Leading = {
    Identifier = "^" .. Patterns.Identifier,
    ScopedIdentifier = "^" .. Patterns.ScopedIdentifier,
}
Patterns.SimpleEffects = {
    Unscoped = "^%s*%$" .. Patterns.Identifier .. "%s*$",
    Scoped = "^%s*%$" .. Patterns.ScopedIdentifier .. "%s*$",
}

local function collapsePairs(delims)
    local count = math.floor(#delims / 2)
    local hasTrailing = #delims % 2 == 1

    return string.rep(delims:sub(1, 1), count), hasTrailing
end

local function parseScopedIdentifier(code, default_ns, from)
    local namespace, identifier = code:match(Patterns.Leading.ScopedIdentifier, from)

    if namespace then
        from = from + (#namespace + 1 + #identifier) -- +1 for the the colon
    else
        namespace = default_ns
        identifier = code:match(Patterns.Leading.Identifier, from)

        if not identifier then return nil, nil, nil end

        from = from + #identifier
    end

    return namespace, identifier, from
end

local function resolveVariables(code, character)
    local parts = {}
    local from = 1
    local delim_from, delim_to = code:find(Patterns.DelimRepeated, from)

    while delim_from ~= nil do
        local collapsed, hasTrailing = collapsePairs(code:sub(delim_from, delim_to))

        parts[#parts+1] = code:sub(from, delim_from - 1)
        parts[#parts+1] = collapsed

        from = delim_to + 1

        if hasTrailing then
            local namespace, identifier
            namespace, identifier, from = parseScopedIdentifier(code, character, from)

            if not identifier then return nil end -- any unpaired $ must be followed by an identifier

            parts[#parts+1] = 'vars["' .. mod.VarsKey .. '"].' .. namespace .. '.' .. identifier
        end

        delim_from, delim_to = code:find("%$+", from)
    end

    parts[#parts+1] = code:sub(from)

    return table.concat(parts)
end

local function parseCondition(cond, character)
    -- Don't do anything to functions
    if type(cond) == "function" then return cond end

    -- Resolve variables
    local resolved = resolveVariables(cond, character)
    assert(resolved, "Bad condition: `" .. cond .. "`")

    -- Parse as Lua code
    return loadstring("return " .. resolved)
end

local function parseEffect(effect, character)
    -- Don't do anything to functions
    if type(effect) == "function" then return effect end

    -- For the simple forms "$variable" and "$namespace:variable", set that variable to true
    if effect:find(Patterns.SimpleEffects.Unscoped) or
       effect:find(Patterns.SimpleEffects.Scoped)
    then
        effect = effect .. "=true"
    end

    -- Resolve variables
    local resolved = resolveVariables(effect, character)
    assert(resolved, "Bad effect: `" .. effect .. "`")

    -- Parse as Lua code
    return loadstring(resolved)
end

return {
    parseCondition = parseCondition,
    parseEffect = parseEffect,
}
