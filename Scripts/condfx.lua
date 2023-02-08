local mod = DialogSystem

local function resolveVariables(code, character)
    local pieces = {}

    local block_start = nil
    local ident_start = nil
    local the_end = #code + 1
    local i = 1

    while i <= #code do
        local char = code:sub(i, i)
        if char:match("[_%a]") then
            block_start = block_start or i
            ident_start = ident_start or i
        elseif char:match("%d") then
            block_start = block_start or i
        elseif char == "$" then
            local block_end = i - 1

            local sign_start, sign_end = code:find("(%$+)", i)
            local sign_count = sign_end - sign_start + 1
            local hasLeading = sign_count > 1
            local hasTrailing = sign_count % 2 == 1
            
            if hasLeading then
                pieces[#pieces + 1] = code:sub(block_start or the_end, block_end) or ""
                pieces[#pieces + 1] = string.rep("$", math.floor(sign_count / 2))
                block_start = nil
                ident_start = nil
            else
                pieces[#pieces + 1] = code:sub(block_start or the_end, (ident_start or i) - 1) or ""
            end
            
            if hasTrailing then
                local namespace = code:sub(ident_start or the_end, block_end)
                if namespace == nil or namespace == "" then
                    namespace = character
                end
                local ident_from, ident_to = code:find("^([_%a][_%w]*)", sign_end + 1)

                if not ident_from then
                    print("Bad condition or effect: " .. code)
                    return
                end

                local identifier = code:sub(ident_from, ident_to)
                local resolved = 'vars["' .. mod.VarsKey .. '"]["' .. namespace .. '"]["' .. identifier .. '"]'

                pieces[#pieces + 1] = resolved
                i = ident_to
            else
                i = sign_end
            end

            block_start = nil
            ident_start = nil
        else
            block_start = block_start or i
            ident_start = nil
        end
        i = i + 1
    end

    if block_start then
        pieces[#pieces + 1] = code:sub(block_start)
    end

    return table.concat(pieces)
end

local function evalCondition(cond, character)
    -- Resolve variables and execute as Lua code
    local f = loadstring("return " .. resolveVariables(cond, character))
    return f()
end

local function executeEffect(effect, character)
    -- For the simple form "::variableName", just set that variable to true
    if effect:match("[=( ]") == nil then
        effect = effect .. "=true"
    end

    -- Resolve variables and execute as Lua code
    local f = loadstring(resolveVariables(effect, character))
    f()
end

return {
    evalCondition = evalCondition,
    executeEffect = executeEffect,
}
