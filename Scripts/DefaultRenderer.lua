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
        enableSidelight = false,
    }
}

-- Utilities -------------------------------------------------------------------

local SignIndices = {
    A = 17,
    B = 18,
    C = 19
}

local function clamp(x, min, max)
    return math.min(math.max(x, min), max)
end

local function sign(x)
    return (x > 0 and 1) or (x < 0 and -1) or 0
end

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

    -- Show cursor
    if self.options.enableCursor then
        self.cursor = Objects.NewTemplate(0, 0, 9)
        self.cursor:LoadFrame(mod.GraphicsPath.."Cursor.png")
        self.cursor:ReplaceColor(
            255, 255, 255,
            self.options.activeTextColor[1], self.options.activeTextColor[2], self.options.activeTextColor[3]
        )
        self.cursor:SetX(self.leftSide + 15)
    end
    self.cursorY = 0

    if self.options.enableUnderline then
        self.underline = Objects.NewTemplate(0, 0, 9)
        ReplaceGraphics({mod.GraphicsPath.."Underline/Underline", 0, 19}, self.underline)
        self.underline.Animations = {
            Rage = {0, 19, Delay = 1, Loop = false}
        }
        self.underline:SetX(self.leftSide + 60 + (200-60)/2)
    end

    if self.options.enableHighlight then
        self.highlight = Objects.NewTemplate(0, 0, 9)
        ReplaceGraphics({mod.GraphicsPath.."Highlight/Highlight", 0, 78}, self.highlight)
        self.highlight:SetX(self.leftSide + 100)
        self.highlight:SetY(self.cursorY)
        self.highlight:SetTransparency(118)
    end
    self.highlightY = 0
    self.highlightHeight = 1

    if self.options.enableSidelight then
        self.sidelight = Objects.NewTemplate(0, 0, 9)
        ReplaceGraphics({mod.GraphicsPath.."Sidelight/Sidelight", 0, 78}, self.sidelight)
        self.sidelight:SetX(self.leftSide + 196 + 2)
        self.sidelight:SetY(self.cursorY)
    end

    -- Ensure sign is visible
    self:showSign()

    -- Start update timer
    self.updateWrapper = self.updateWrapper or function(tick) self:update(tick) end
    Timer(1, self.updateWrapper)
end

function DefaultRenderer:hide()
    self:hideSign()

    for _, text in pairs(self.textObjects) do
        text:Destroy()
    end
    self.textObjects = {}

    if self.cursor then self.cursor = self.cursor:Destroy() end
    if self.underline then self.underline = self.underline:Destroy() end
    if self.highlight then self.highlight = self.highlight:Destroy() end
    if self.sidelight then self.sidelight = self.sidelight:Destroy() end
    self.backgroundImage = self.backgroundImage:Destroy()

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

    -- Move cursor
    self.cursorY = self.responseHeight * (idx - 0.5)

    local lines = math.max(self.textObjects[idx]:GetLinesCount() + 1, 4)
    local _, char_height = self.textObjects[idx]:GetCharacterSize()

    self.highlightHeight = lines * char_height
    self.highlightY = self.cursorY

    self.sidelightHeight = self.highlightHeight
    self.sidelightY = self.highlightY

    if self.options.enableUnderline then
        self.underline:SetY(self.cursorY + self.highlightHeight / 2 - 1)
        self.underline:Animate("Rage")
    end
end

-- end required interface ------------------------------------------------------

local function interpolate(from, to, elapsed)
    if from == to then return to end

    local range = to - from
    local delta = (range / 5) * elapsed
    delta = clamp(math.abs(delta), 1, math.abs(range)) * sign(range)

    return from + delta
end

function DefaultRenderer:update(tick)
    local elapsed = tick - (self.last_tick or tick)
    self.last_tick = tick

    if self.cursor then
        self.cursor:SetY(self.cursorY + 3 * math.sin(tick * math.pi / 30))
    end

    if self.highlight then
        local y = interpolate(self.highlight:GetY(), self.highlightY, elapsed)
        self.highlight:SetY(y)
        local frame = interpolate(
            self.highlight:GetAnimationFrame(),
            self.highlightHeight,
            elapsed)
        self.highlight:SetAnimationFrame(frame)
    end

    if self.sidelight then
        local y = interpolate(self.sidelight:GetY(), self.sidelightY, elapsed)
        self.sidelight:SetY(y)
        local frame = interpolate(
            self.sidelight:GetAnimationFrame(),
            self.sidelightHeight,
            elapsed)
        self.sidelight:SetAnimationFrame(frame)
    end
end

return DefaultRenderer
