local mod = DialogSystem

local function split(str, pattern, from)
    local parts = {}

    from = from or 1
    local sep_start, sep_end = str:find(pattern, from)

    while sep_start ~= nil do
        parts[#parts + 1] = str:sub(from, sep_start - 1)
        from = sep_end + 1
        sep_start, sep_end = str:find(pattern, from)
    end

    parts[#parts + 1] = str:sub(from)

    return parts
end

local function match_with_indices(str, pattern)
    local from, to = str:find(pattern)
    return from and str:sub(from, to), from, to
end

local function resolveVariables(code, character)
    local parts = split(code, "%$%$")
    local syntax_error = false

    parts = mod.func.map(parts, function(part)
        local chunks = {}
        local from = 1

        local next_dollar = part:find("%$", from)
        while next_dollar ~= nil do
            local before = part:sub(from, next_dollar - 1)
            local after = part:sub(next_dollar + 1)

            local namespace, ns_from, _ = match_with_indices(before, "([_%a][_%w]*)$")
            namespace = namespace or character

            local identifier, _, id_to = match_with_indices(after, "^([_%a][_%w]*)")
            if identifier == nil then
                syntax_error = true
                return
            end

            chunks[#chunks+1] = part:sub(from, (ns_from or next_dollar) - 1)
            chunks[#chunks+1] = 'vars["' .. mod.VarsKey .. '"]["' .. namespace .. '"]["' .. identifier .. '"]'

            from = (next_dollar + 1) + id_to
            next_dollar = part:find("%$", from)
        end

        chunks[#chunks+1] = part:sub(from)

        return table.concat(chunks)
    end)

    if syntax_error then
        return nil
    else
        return table.concat(parts, "$")
    end
end

local function parseCondition(cond, character)
    -- Resolve variables
    local resolved = resolveVariables(cond, character)
    assert(resolved, "Bad condition: `" .. cond .. "`")

    -- Parse as Lua code
    return loadstring("return " .. resolved)
end

local function parseEffect(effect, character)
    -- For the simple forms "$variable" and "namespace$variable", set that variable to true
    if effect:match("^%$([_%a][_%w]*)$") or
       effect:match("^([_%a][_%w]*)%$([_%a][_%w]*)$")
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
