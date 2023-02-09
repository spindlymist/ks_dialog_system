local mod = DialogSystem

local Underline = {}
Underline.__index = Underline

function Underline:new(options)
    local o = { options = options or {} }
    setmetatable(o, self)

    o.object = Objects.NewTemplate(0, 0, o.options.layer or 9)
    ReplaceGraphics({mod.GraphicsPath.."Underline/Underline", 0, 200}, o.object)

    if o.options.color then
        o.object:ReplaceColor(
            255, 255, 255,
            o.options.color[1], o.options.color[2], o.options.color[3]
        )
    end

    o.options.leftMargin = o.options.leftMargin or 30
    o.targetWidth = 170
    o.t = 0

    o.curve = mod.anim.Bezier:new{
        { x = 0.0, y = 0.0 },
        { x = 0.5, y = 1.0 },
        { x = 1.0, y = 1.0 },
    }

    return o
end

function Underline:destroy()
    self.object:Destroy()
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
    self.t = mod.anim.clamp(self.t + elapsed * .05, 0, 1)
    local width = self.curve:evaluate(self.t).y * self.targetWidth
    self.object:SetAnimationFrame(width)
end

return Underline
