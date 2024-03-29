local mod = DialogSystem

local Underline = {
    Defaults = {
        transparency = 0,
        leftMargin = 30,
        rightMargin = 30,
        paddingY = 6,
        minHeight = 51,
        animTime = 20,
        animCurve = mod.anim.Bezier:new{
            { x = 0.0, y = 0.0 },
            { x = 0.5, y = 1.0 },
            { x = 1.0, y = 1.0 },
        },
        layer = 10,
    }
}
Underline.__index = Underline

function Underline:new(options)
    options = setmetatable(options or {}, { __index = self.Defaults })
    local o = setmetatable({ options = options }, self)

    if not self.Template then
        self.Template = Objects.NewGlobalTemplate()
        ReplaceGraphics({mod.GraphicsPath.."Underline/Underline", 0, 200}, mod.TemplatesBank, self.Template)
    end

    o.object = Objects.new(mod.TemplatesBank, self.Template, 0, 0, o.options.layer)
    o.object:SetTransparency(127)

    if options.color then
        o.object:ReplaceColor(
            255, 255, 255,
            options.color[1], options.color[2], options.color[3]
        )
    end

    o.width = 200 - options.leftMargin - options.rightMargin
    o.t = 0

    return o
end

function Underline:destroy()
    self.object = self.object:Destroy()
end

function Underline:onLayout(layout)
    local y_center = layout.y + layout.height * 0.5
    local text_height = math.max(
        self.options.minHeight,
        layout.lines * layout.lineHeight + self.options.paddingY * 2
    )
    local y_offset = math.ceil(text_height / 2)

    self.object:SetTransparency(self.options.transparency)
    self.object:SetX(layout.x + self.options.leftMargin + 100)
    self.object:SetY(y_center + y_offset - 1)
    self.object:SetAnimationFrame(0)
    self.t = 0
end

function Underline:animate(tick, elapsed)
    self.t = mod.anim.clamp(self.t + elapsed * (1 / self.options.animTime), 0, 1)
    local frame = self.options.animCurve:evaluate(self.t).y * self.width
    self.object:SetAnimationFrame(frame)
end

return Underline
