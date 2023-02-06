local mod = DialogSystem
local DialogMenu = {}

function DialogMenu:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- Initialize renderer
    if o.renderer == nil then
        o.rendererOptions = o.rendererOptions or {}
        o.renderer = mod.DefaultRenderer:new{options = o.rendererOptions}
    end

    -- Initialize input handler
    if o.inputHandler == nil then
        o.inputHandlerOptions = o.inputHandlerOptions or {}
        o.inputHandler = mod.DefaultInputHandler:new{options = o.inputHandlerOptions}
    end

    -- Load dialog tree from file
    o.tree = mod.DialogTree:new{name = o.tree}

    -- Initialize character table
    mod.vars()[o.tree.character] = mod.vars(o.tree.character) or {}
    mod.vars(o.tree.character).__nth = 0 -- the # of times this character has been spoken to

    -- Render passive dialog if present
    local passive = o.tree:getPassiveDialog()
    if passive then
        o.renderer:showPassiveDialog(passive)
    end

    return o
end

function DialogMenu:show(options)
    -- Increase the ::__nth variable
    mod.vars(self.tree.character).__nth = mod.vars(self.tree.character).__nth + 1

    -- Determine starting state (abort if absent)
    local start = self.tree:getStartKey()
    if not start then
        return false
    end

    -- Activate renderer and input handler
    self.renderer:show(options and options.rendererOptions)
    self.inputHandler:enable(self, options and options.inputHandlerOptions)

    -- Go to the initial dialog state
    self:setDialogState(start)

    return true
end

function DialogMenu:hide()
    -- Deactivate renderer and input handler
    self.renderer:hide()
    self.inputHandler:disable()

    -- Call dialog end callback if present
    if self.events and self.events.onDialogEnd then
        self.events.onDialogEnd()
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

    -- Check for file specifier (path/to/file::)
    local separatorIdx = key:find("::")
    if separatorIdx ~= nil then
        -- Separate into the tree name and key
        local tree_name = key:sub(1, separatorIdx - 1)
        key = key:sub(separatorIdx + 2)
        -- Load new dialog
        tree = mod.DialogTree:new{name = tree_name}
    end

    return tree, key
end

function DialogMenu:setDialogState(key)
    tree, key = self:resolveDialogKey(key)

    -- Update dialog state
    self.tree = tree
    self.dialogState = self.tree:getDialogState(key)

    if not self.dialogState then
        return self:hide()
    elseif self.dialogState.isTerminal then
        self:hide()
        return self.renderer:showPassiveDialog(self.dialogState.text)
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
