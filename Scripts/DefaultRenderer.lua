local mod = DialogSystem
local DefaultRenderer = {
    Defaults = {
        sign = "A",
        dock = "left",
        textColor = {192, 192, 192},
        activeTextColor = {255, 255, 255},
        enableCursor = true,
        enableUnderline = true,
        enableHighlight = true,
        enableSidelight = true,
    }
}

-- Utilities -------------------------------------------------------------------

local SignIndices = {
    A = 17,
    B = 18,
    C = 19
}

--------------------------------------------------------------------------------

function DefaultRenderer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.textObjects = {}
    o:initOptions()
    o:initSign()
    o:hideSign()

    return o
end

function DefaultRenderer:initOptions()
    self.instanceDefaults = self.options or {}
    setmetatable(self.instanceDefaults, { __index = DefaultRenderer.Defaults })

    self.options = {}
    setmetatable(self.options, { __index = self.instanceDefaults })
end

function DefaultRenderer:initSign()
    -- Convert sign letter to object index and find sign object
    local signIndex = SignIndices[self.options.sign]
    self.signObject = Objects.Find{Bank = 0, Obj = signIndex}
    self.signObject:SetFlag(0, true)

    -- Record original sign location
    self.signX = self.signObject:GetX()
    self.signY = self.signObject:GetY()
end

function DefaultRenderer:hideSign()
    -- Move it off screen
    self.signObject:SetPosition(0, -120)
end

function DefaultRenderer:showSign()
    -- Restore its original position
    self.signObject:SetPosition(self.signX, self.signY)
end

function DefaultRenderer:updateSign(text)
    self.signObject:SetString(0, text)
    self.signObject:SetFlag(1, false)
    self.signObject:SetFlag(2, false)
end

-- Begin required interface ----------------------------------------------------

function DefaultRenderer:show(options)
    -- Temporarily override instance options
    self.options = options or {}
    setmetatable(self.options, { __index = self.instanceDefaults })

    -- Determine x position of dialog interface based on specified docking (default left)
    if self.options.dock == "right" then
        self.leftSide = 400
    else
        self.leftSide = 0
    end

    -- Show background
    self.backgroundImage = Objects.NewTemplate(0, 0, 8)
    self.backgroundImage:LoadFrame(mod.GraphicsPath.."DialogBackground.png")
    self.backgroundImage:SetX(self.leftSide + 100)
    self.backgroundImage:SetY(120)
    self.backgroundImage:SetTransparency(32)

    -- Create cursors
    self.cursors = {}
    if self.options.enableCursor then
        self.cursors[#self.cursors+1] = mod.cursors.Pointer:new{color = self.options.activeTextColor}
    end

    if self.options.enableUnderline then
        self.cursors[#self.cursors+1] = mod.cursors.Underline:new{color = self.options.activeTextColor}
    end

    if self.options.enableHighlight then
        self.cursors[#self.cursors+1] = mod.cursors.Highlight:new{color = self.options.activeTextColor}
    end

    if self.options.enableSidelight then
        self.cursors[#self.cursors+1] = mod.cursors.Sidelight:new{color = self.options.activeTextColor}
    end

    -- Ensure sign is visible
    self:showSign()

    -- Start update timer
    self.updateWrapper = self.updateWrapper or function(tick) self:update(tick) end
    Timer(1, self.updateWrapper)
end

function DefaultRenderer:hide()
    self:hideSign()
    self.backgroundImage = self.backgroundImage:Destroy()

    for _, text in pairs(self.textObjects) do
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
    for _, text in pairs(self.textObjects) do
        text:Destroy()
    end
    self.textObjects = {}

    -- Create text objects
    self.responseHeight = 240 / #responses
    local y = 0
    for i, response in pairs(responses) do
        local text = Objects.Text{Layer = 8, Permanent = 0}

        text:SetLayer(2)
        text:MoveToBack()
        text:SetPosition(self.leftSide + 30, y)
        text:SetHeight(self.responseHeight)
        text:SetWidth(150)
        text:ReplaceColor(
            15, 14, 14,
            self.options.textColor[1], self.options.textColor[2], self.options.textColor[3]
        )
        text:SetText(response)

        self.textObjects[i] = text
        y = y + self.responseHeight
    end

    local _, lineHeight = self.textObjects[1]:GetCharacterSize()
    self.layout = {
        x = self.leftSide,
        height = self.responseHeight,
        width = 200,
        lineHeight = lineHeight
    }
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

    -- Update cursors
    self.layout.y = self.responseHeight * (idx - 1)
    self.layout.lines = math.max(self.textObjects[idx]:GetLinesCount() + 1, 4)
    for _, cursor in pairs(self.cursors) do
        cursor:onResponseSelected(self.layout)
    end
end

-- end required interface ------------------------------------------------------

function DefaultRenderer:update(tick)
    local elapsed = tick - (self.last_tick or tick)
    self.last_tick = tick

    for _, cursor in pairs(self.cursors) do
        cursor:animate(tick, elapsed)
    end
end

return DefaultRenderer
