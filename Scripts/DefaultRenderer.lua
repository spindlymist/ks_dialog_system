local mod = DialogSystem

local DefaultRenderer = {
    Defaults = {
        sign = "A",
        dock = "left",
        textColor = {192, 192, 192},
        activeTextColor = {255, 255, 255},
        background = mod.GraphicsPath.."Background.png",
        backgroundTransparency = 32,
        cursors = {},
    }
}
DefaultRenderer.__index = DefaultRenderer

local SignIndices = {
    A = 17,
    B = 18,
    C = 19
}

function DefaultRenderer:new(options)
    local o = setmetatable({}, self)

    o.options = setmetatable(options or {}, { __index = self.Defaults })
    o.textObjects = {}
    o.cursors = {}

    o:findSign()
    o:hideSign()

    return o
end

-- Sign management -------------------------------------------------------------

function DefaultRenderer:findSign()
    -- Convert sign letter to object index
    local signIndex = SignIndices[self.options.sign]

    -- Find the sign object
    self.sign = {
        object = Objects.Find{Bank = 0, Obj = signIndex}
    }

    -- Record original sign location
    self.sign.x = self.sign.object:GetX()
    self.sign.y = self.sign.object:GetY()
end

function DefaultRenderer:hideSign()
    -- Move it off screen
    self.sign.object:SetPosition(0, -120)
end

function DefaultRenderer:showSign()
    -- Restore its original position
    self.sign.object:SetPosition(self.sign.x, self.sign.y)
end

function DefaultRenderer:updateSign(text)
    self.sign.object:SetString(0, text)
    self.sign.object:SetFlag(0, true)
    self.sign.object:SetFlag(1, false)
    self.sign.object:SetFlag(2, false)
end

-- Begin required interface ----------------------------------------------------

function DefaultRenderer:show()
    -- Determine x position of dialog interface based on specified docking (default left)
    if self.options.dock == "right" then
        self.leftSide = 400
    else
        self.leftSide = 0
    end

    -- Show background
    self.backgroundObject = Objects.NewTemplate(0, 0, 8)
    if type(self.options.background) == "table" then
        self.backgroundObject:LoadFrame(self.Defaults.background)
        self.backgroundObject:ReplaceColor(0, 0, 0,
            self.options.background[1], self.options.background[2], self.options.background[3]
        )
    else
        self.backgroundObject:LoadFrame(self.options.background)
    end
    self.backgroundObject:SetX(self.leftSide + 100)
    self.backgroundObject:SetY(120)
    self.backgroundObject:SetTransparency(self.options.backgroundTransparency)

    -- Create cursors
    for class, options in pairs(self.options.cursors) do
        local cursor = class:new(options)
        self.cursors[#self.cursors+1] = cursor
    end

    -- Ensure sign is visible
    self:showSign()

    -- Start update timer
    self.updateWrapper = self.updateWrapper or function(tick) self:update(tick) end
    Timer(1, self.updateWrapper)
end

function DefaultRenderer:hide()
    self:hideSign()
    self.backgroundObject = self.backgroundObject:Destroy()

    for _, text in ipairs(self.textObjects) do
        text:Destroy()
    end
    self.textObjects = {}

    for _, cursor in pairs(self.cursors) do
        cursor:destroy()
    end
    self.cursors = {}

    RemoveTimer(self.updateWrapper)
end

function DefaultRenderer:showPassiveDialog(text)
    self:showSign()
    self:updateSign(text)
end

function DefaultRenderer:updateDialog(text)
    self:updateSign(text)
end

function DefaultRenderer:updateResponses(responses)
    -- Delete existing text objects
    for _, text in ipairs(self.textObjects) do
        text:Destroy()
    end
    self.textObjects = {}

    -- Create text objects
    local responseHeight = 240 / #responses
    local y = 0
    for i, response in ipairs(responses) do
        local text = Objects.Text{Layer = 8, Permanent = 0}

        text:SetLayer(2)
        text:MoveToBack()
        text:SetPosition(self.leftSide + 30, y)
        text:SetHeight(responseHeight)
        text:SetWidth(150)
        text:ReplaceColor(
            15, 14, 14,
            self.options.textColor[1], self.options.textColor[2], self.options.textColor[3]
        )
        text:SetText(response)

        self.textObjects[i] = text
        y = y + responseHeight
    end
end

function DefaultRenderer:selectResponse(prevIdx, idx)
    -- Recolor old response
    self.textObjects[prevIdx]:ReplaceColor(
        self.options.activeTextColor[1], self.options.activeTextColor[2], self.options.activeTextColor[3],
        self.options.textColor[1], self.options.textColor[2], self.options.textColor[3]
    )

    -- Recolor new response
    self.textObjects[idx]:ReplaceColor(
        self.options.textColor[1], self.options.textColor[2], self.options.textColor[3],
        self.options.activeTextColor[1], self.options.activeTextColor[2], self.options.activeTextColor[3]
    )

    -- Layout cursors on next update
    -- This can't be done on the first frame the menu is shown
    -- because GetLinesCount() will always return 0.
    self.selectedText = self.textObjects[idx]
end

-- end required interface ------------------------------------------------------

function DefaultRenderer:layout()
    local _, lineHeight = self.selectedText:GetCharacterSize()
    local layout = {
        x = self.leftSide,
        y = self.selectedText:GetY(),
        height = self.selectedText:GetHeight(),
        width = 200,
        lineHeight = lineHeight,
        lines = self.selectedText:GetLinesCount(),
    }

    for _, cursor in pairs(self.cursors) do
        cursor:onLayout(layout)
    end

    self.selectedText = nil
end

function DefaultRenderer:update(tick)
    local elapsed = tick - (self.last_tick or tick)
    self.last_tick = tick

    if self.selectedText then
        self:layout()
    end

    for _, cursor in pairs(self.cursors) do
        cursor:animate(tick, elapsed)
    end
end

return DefaultRenderer
