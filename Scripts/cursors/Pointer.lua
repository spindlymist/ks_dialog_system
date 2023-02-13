local mod = DialogSystem

local Pointer = {
    Defaults = {
        transparency = 0,
        leftMargin = 15,
        image = mod.GraphicsPath.."Pointer.png",
        bobHeight = 3,
        bobTime = 60,
        layer = 9,
    }
}
Pointer.__index = Pointer

function Pointer:new(options)
    options = setmetatable(options or {}, { __index = self.Defaults })
    local o = setmetatable({ options = options }, self)

    o.object = Objects.NewTemplate(0, 0, o.options.layer)
    o.object:LoadFrame(o.options.image)
    o.object:SetTransparency(127)

    return o
end

function Pointer:destroy()
    self.object = self.object:Destroy()
end

function Pointer:onLayout(layout)
    self.object:SetTransparency(self.options.transparency)
    self.object:SetX(layout.x + self.options.leftMargin)
    self.y = layout.y + layout.height / 2
end

function Pointer:animate(tick, elapsed)
    local offset = self.options.bobHeight * math.sin((tick / self.options.bobTime) * (2 * math.pi))
    self.object:SetY(self.y + offset)
end

return Pointer
