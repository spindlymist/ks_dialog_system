local mod = DialogSystem
local DialogTree = {}

-- Utilities -------------------------------------------------------------------

local function wrap(value)
    if type(value) ~= "table" then
        return {value}
    end
    return value or {}
end

local function normalizeResponse(response)
    if type(response) == "string" then
        return {
            text = response,
            conds = {},
            effects = {},
            next = nil,
            isTerminal = true,
        }
    elseif type(response) == "table" then
        return {
            text = response[1],
            conds = wrap(response.conds),
            effects = wrap(response.effects),
            next = response.next,
            isTerminal = (response.next == nil),
        }
    end
end

local function normalizeState(state)
    if state and state.__isNormalized then
        return state
    elseif type(state) == "string" then
        return {
            text = state,
            responses = {},
            __isNormalized = true,
        }
    elseif type(state) == "table" then
        local text = state[1]
        local responses = {}
        for i = 2, #state do
            responses[i-1] = normalizeResponse(state[i])
        end

        return {
            text = text,
            responses = responses,
            __isNormalized = true,
        }
    end
end

--------------------------------------------------------------------------------

function DialogTree:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- Load dialog tree from file
    local data = dofile(mod.TreesPath .. o.name .. ".lua")

    o.character = data.__meta.character
    o.init = data.__meta.init
    o.start = data.__meta.start
    o.passive = data.__meta.passive

    data.__meta = nil
    o.states = data

    return o
end

function DialogTree:getPassiveDialog()
    return self:match(self.passive)
end

function DialogTree:getStartKey()
    -- Find the initial dialog state
    local key = self:match(self.start)

    -- Default to "__start" if this is the first time
    -- There is no default if the character has already been spoken to
    -- The dialog writer must include their own logic using $__nth
    if key == nil and self.states.__start and mod.vars(self.character).__nth == 1 then
        return "__start"
    end

    return key
end

function DialogTree:getDialogState(key)
    -- Lazily normalize the state for this key
    self.states[key] = normalizeState(self.states[key])
    local state = self.states[key]

    if not state then
        return print("Tried to load nonexistent state: " .. self.character .. "/" .. key)
    end

    -- Filter out responses whose conditions aren't met
    local responses = mod.func.filterMap(state.responses, function(response)
        if self:checkConditions(response.conds) then
            return {
                text = self:match(response.text),
                effects = response.effects,
                next = response.next,
            }
        end
    end)

    return {
        text = self:match(state.text),
        responses = responses,
        isTerminal = #responses == 0
    }
end

function DialogTree:match(field)
    -- If the field is empty or a string, just return it
    if field == nil or type(field) == "string" then
        return field
    end

    -- If it's a table, return the first element that meets all its conditions
    for _, value in ipairs(field) do
        -- A string has no conditions
        if type(value) == "string" then
            return value
        elseif self:checkConditions(value.conds) then
            return value[1]
        end
    end

    -- No element met all of its conditions
    return nil
end

function DialogTree:checkConditions(conds)
    conds = wrap(conds)

    return mod.func.all(conds, function(cond)
        return mod.parse.parseCondition(cond, self.character)()
    end)
end

function DialogTree:applyEffects(response)
    for _, effect in ipairs(response.effects) do
        mod.parse.parseEffect(effect, self.character)()
    end

    -- Determine which dialog state is next
    -- This can't be done earlier because the effects of this response could change the outcome
    response.next = self:match(response.next)
    response.isTerminal = (response.next == nil)
end

return DialogTree
