local mod = DialogSystem

local Sidelight = {}
Sidelight.__index = Sidelight

function Sidelight:new(options)
    local o = { options = options or {} }
    setmetatable(o, self)

    o.object = Objects.NewTemplate(0, 0, o.options.layer or 9)
    ReplaceGraphics({mod.GraphicsPath.."Sidelight/Sidelight", 0, 78}, o.object)

    if o.options.color then
        o.object:ReplaceColor(
            255, 255, 255,
            o.options.color[1], o.options.color[2], o.options.color[3]
        )
    end

    o.object:SetTransparency(o.options.transparency or 0)

    o.options.leftMargin = o.options.leftMargin or 196
    o.y = 0
    o.height = 0
    o.targetY = 0
    o.targetHeight = 0

    return o
end

function Sidelight:destroy()
    self.object:Destroy()
end

function Sidelight:onResponseSelected(layout)
    self.object:SetX(layout.x + self.options.leftMargin + 2)
    self.targetHeight = layout.lines * layout.lineHeight
    self.targetY = layout.y + layout.height * 0.5
end

function Sidelight:animate(tick, elapsed)
    self.y = mod.anim.simpleInterpolate(self.y, self.targetY, elapsed, 5)
    self.height = mod.anim.simpleInterpolate(self.height, self.targetHeight, elapsed, 5)

    self.object:SetY(self.y)
    self.object:SetAnimationFrame(self.height)
end

return Sidelight
