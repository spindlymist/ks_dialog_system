local mod = DialogSystem

local DialogMenu = {
    Defaults = {}
}
DialogMenu.__index = DialogMenu

function DialogMenu:new(renderer, inputHandler, options)
    local o = setmetatable({}, self)

    o.renderer = renderer
    o.inputHandler = inputHandler
    o.options = setmetatable(options or {}, { __index = self.Defaults })

    return o
end

function DialogMenu:load(tree)
    -- Load dialog tree from file
    self.tree = mod.DialogTree:new{name = tree}
    self:initCharacterTable(self.tree.init)

    -- Render passive dialog if present
    local passive = self.tree:getPassiveDialog()
    if passive then
        self.renderer:showPassiveDialog(passive)
    end
end

function DialogMenu:initCharacterTable(initValues)
    -- Create character table if necessary
    local characterTable = mod.vars(self.tree.character)

    -- Initialize undefined keys
    initValues = initValues or {}
    for key, value in pairs(initValues) do
        characterTable[key] = characterTable[key] or value
    end

    -- Reset the $__nth variable
    characterTable.__nth = 0

    mod.vars()[self.tree.character] = characterTable
end

function DialogMenu:show(onDialogEnd)
    self.onDialogEnd = onDialogEnd

    -- Increase the $__nth variable
    mod.vars(self.tree.character).__nth = mod.vars(self.tree.character).__nth + 1

    -- Determine starting state (abort if absent)
    local start = self.tree:getStartKey()
    if not start then
        return false
    end

    -- Activate renderer and input handler
    self.renderer:show()
    self.inputHandler:enable(self)

    -- Go to the initial dialog state
    self:setDialogState(start)

    return true
end

function DialogMenu:hide()
    -- Deactivate renderer and input handler
    self.renderer:hide()
    self.inputHandler:disable()

    -- Call dialog end callback if present
    if self.onDialogEnd then
        self.onDialogEnd()
    end
end

function DialogMenu:selectResponse(idx)
    if idx >= 1 and idx <= #self.dialogState.responses then
        self.renderer:selectResponse(self.responseIdx, idx)
        self.responseIdx = idx
    end
end

function DialogMenu:selectPrevResponse()
    local idx

    -- Wrap around if necessary
    if self.responseIdx == 1 then
        idx = #self.dialogState.responses
    else
        idx = self.responseIdx - 1
    end

    self.renderer:selectResponse(self.responseIdx, idx)
    self.responseIdx = idx
end

function DialogMenu:selectNextResponse()
    local idx

    -- Wrap around if necessary
    if self.responseIdx == #self.dialogState.responses then
        idx = 1
    else
        idx = self.responseIdx + 1
    end

    self.renderer:selectResponse(self.responseIdx, idx)
    self.responseIdx = idx
end

function DialogMenu:confirmResponse()
    local response = self.dialogState.responses[self.responseIdx]

    self.tree:applyEffects(response)

    if response.isTerminal then
        return self:hide()
    end

    self:setDialogState(response.next)
end

function DialogMenu:resolveDialogKey(key)
    local tree = self.tree

    -- Check for file specifier (path/to/file:)
    local separatorIdx = key:find(":")
    if separatorIdx ~= nil then
        -- Separate into the tree name and key
        local tree_name = key:sub(1, separatorIdx - 1)
        key = key:sub(separatorIdx + 1)
        -- Load new dialog
        tree = mod.DialogTree:new{name = tree_name}
    end

    return tree, key
end

function DialogMenu:setDialogState(key)
    local tree
    tree, key = self:resolveDialogKey(key)

    -- Update dialog state
    self.tree = tree
    self.dialogState = self.tree:getDialogState(key)

    -- Check for invalid or terminal state
    if not self.dialogState then
        return self:hide()
    elseif self.dialogState.isTerminal then
        self:hide()
        self.renderer:showPassiveDialog(self.dialogState.text)
        return
    end

    -- Render
    self.renderer:updateDialog(self.dialogState.text)
    self.renderer:updateResponses(mod.func.map(self.dialogState.responses, function(response)
        return response.text
    end))

    -- Select first response
    self.responseIdx = 1
    self:selectResponse(self.responseIdx)
end

return DialogMenu
