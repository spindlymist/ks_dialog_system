local mod = DialogSystem

local Highlight = {
    Defaults = {
        transparency = 117,
        leftMargin = 30,
        lag = 5,
        layer = 9,
    }
}
Highlight.__index = Highlight

function Highlight:new(options)
    options = setmetatable(options or {}, { __index = self.Defaults })
    local o = setmetatable({ options = options }, self)

    if not self.Template then
        self.Template = Objects.NewGlobalTemplate()
        ReplaceGraphics({mod.GraphicsPath.."Highlight/Highlight", 0, 78}, mod.TemplatesBank, self.Template)
    end

    o.object = Objects.new(mod.TemplatesBank, self.Template, 0, 0, o.options.layer)
    o.object:SetTransparency(127)

    if options.color then
        o.object:ReplaceColor(
            255, 255, 255,
            options.color[1], options.color[2], options.color[3]
        )
    end

    o.y = 0
    o.height = 0
    o.targetY = 0
    o.targetHeight = 0
    o.skipAnim = true -- skip animation on first layout

    return o
end

function Highlight:destroy()
    self.object = self.object:Destroy()
end

function Highlight:onLayout(layout)
    self.object:SetTransparency(self.options.transparency)
    self.object:SetX(layout.x + 100)
    self.targetHeight = math.min(layout.lines * layout.lineHeight, 78)
    self.targetY = layout.y + layout.height * 0.5
end

function Highlight:animate(tick, elapsed)
    if self.skipAnim then
        self.y = self.targetY
        self.height = self.targetHeight
        self.skipAnim = false
    else
        self.y = mod.anim.simpleInterpolate(self.y, self.targetY, elapsed, self.options.lag)
        self.height = mod.anim.simpleInterpolate(self.height, self.targetHeight, elapsed, self.options.lag)
    end

    self.object:SetY(self.y)
    self.object:SetAnimationFrame(self.height)
end

return Highlight
