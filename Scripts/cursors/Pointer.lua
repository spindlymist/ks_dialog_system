local mod = DialogSystem

local Pointer = {}
Pointer.__index = Pointer

function Pointer:new(options)
    local o = { options = options or {} }
    setmetatable(o, self)

    o.object = Objects.NewTemplate(0, 0, o.options.layer or 9)
    o.object:LoadFrame(mod.GraphicsPath.."Cursor.png")
    if o.options.color then
        o.object:ReplaceColor(
            255, 255, 255,
            o.options.color[1], o.options.color[2], o.options.color[3]
        )
    end

    o.options.leftMargin = o.options.leftMargin or 15
    o.y = 0

    return o
end

function Pointer:destroy()
    self.object:Destroy()
end

function Pointer:onResponseSelected(layout)
    self.object:SetX(layout.x + self.options.leftMargin)
    self.y = layout.y + layout.height / 2
end

function Pointer:animate(tick, elapsed)
    self.object:SetY(self.y + 3 * math.sin(tick * math.pi / 30))
end

return Pointer
