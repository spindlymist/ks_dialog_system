local mod = DialogSystem

local Underline = {
    Defaults = {
        transparency = 0,
        leftMargin = 30,
        rightMargin = 30,
        animTime = 20,
        animCurve = mod.anim.Bezier:new{
            { x = 0.0, y = 0.0 },
            { x = 0.5, y = 1.0 },
            { x = 1.0, y = 1.0 },
        },
        layer = 9,
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

    o.width = 200 - options.leftMargin - options.rightMargin
    o.t = 0

    return o
end

function Underline:show()
    self.object = Objects.new(mod.TemplatesBank, self.Template, 0, 0, self.options.layer)
    self.object:SetTransparency(self.options.transparency)
end

function Underline:hide()
    self.object = self.object:Destroy()
end

function Underline:onResponseSelected(layout)
    local y_center = layout.y + layout.height * 0.5
    local y_offset = (layout.lines * layout.lineHeight) / 2

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
