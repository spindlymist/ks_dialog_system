local mod = DialogSystem

local DefaultRenderer = {
    Defaults = {
        sign = "A",
        dock = "left",
        textColor = {192, 192, 192},
        activeTextColor = {255, 255, 255},
        background = mod.GraphicsPath.."Background.png",
        transparency = 32,
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

    o.instanceDefaults = setmetatable(options or {}, { __index = self.Defaults })
    o:setOptions()
    o.textObjects = {}
    o.cursors = {}

    self.sign = o:findSign()
    self:hideSign()

    return o
end

function DefaultRenderer:setOptions(options)
    self.options = setmetatable(options or {}, { __index = self.instanceDefaults })
end

-- Sign management -------------------------------------------------------------

function DefaultRenderer:findSign()
    -- Convert sign letter to object index
    local signIndex = SignIndices[self.options.sign]

    -- Find the sign object
    local sign = {
        object = Objects.Find{Bank = 0, Obj = signIndex}
    }

    -- Record original sign location
    sign.x = sign.object:GetX()
    sign.y = sign.object:GetY()

    return sign
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

function DefaultRenderer:show(options)
    self:setOptions(options)

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
    self.bgObject = Objects.NewTemplate(0, 0, 8)
    self.bgObject:LoadFrame(self.options.background)
    self.bgObject:SetX(self.leftSide + 100)
    self.bgObject:SetY(120)
    self.bgObject:SetTransparency(self.options.transparency)

    -- Show cursors
    for class, options in pairs(self.options.cursors) do
        local cursor = class:new(options)
        cursor:show()
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
    self.bgObject = self.bgObject:Destroy()

    for _, text in ipairs(self.textObjects) do
        text:Destroy()
    end
    self.textObjects = {}

    for _, cursor in pairs(self.cursors) do
        cursor:hide()
    end
    self.cursors = {}

    RemoveTimer(self.updateWrapper)
    self:setOptions()
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

    -- Update layout data (for cursors)
    local _, lineHeight = self.textObjects[1]:GetCharacterSize()
    self.layout = {
        x = self.leftSide,
        height = responseHeight,
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
    self.layout.y = self.layout.height * (idx - 1)
    self.layout.lines = math.max(self.textObjects[idx]:GetLinesCount() + 1, 4)
    for _, cursor in pairs(self.cursors) do
        cursor:onLayout(self.layout)
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
