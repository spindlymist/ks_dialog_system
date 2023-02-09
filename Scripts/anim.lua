local function clamp(x, min, max)
    return math.min(math.max(x, min), max)
end

local function sign(x)
    return (x > 0 and 1) or (x < 0 and -1) or 0
end

local function simpleInterpolate(from, to, elapsed, rate)
    if from == to then return to end

    local range = to - from
    local delta = (range / rate) * elapsed
    delta = clamp(math.abs(delta), 1, math.abs(range)) * sign(range)

    return from + delta
end

local function lerp(a, b, t)
    return (1 - t) * a + t * b
end

local Bezier = {}
Bezier.__index = Bezier

function Bezier:new(o)
    o = o or {}
    setmetatable(o, self)

    return (#o == 3 and o) or nil
end

function Bezier:evaluate(t)
    local u = 1 - t
    local c1 = u*u
    local c2 = 2*u*t
    local c3 = t*t

    return {
        x = c1 * self[1].x + c2 * self[2].x + c3 * self[3].x,
        y = c1 * self[1].y + c2 * self[2].y + c3 * self[3].y,
    }
end

return {
    simpleInterpolate = simpleInterpolate,
    lerp = lerp,
    clamp = clamp,
    Bezier = Bezier,
}
