local mod = DialogSystem

local DefaultInputHandler = {
    Defaults = {
        keys = {
            Next = "Down",
            Prev = "Up",
            Confirm = "Jump",
        },
    }
}
DefaultInputHandler.__index = DefaultInputHandler

function DefaultInputHandler:new(options)
    local o = setmetatable({}, self)

    o.options = setmetatable(options or {}, { __index = self.Defaults })

    return o
end

function DefaultInputHandler:enable(callbacks)
    self.callbacks = callbacks

    -- Disable player movement
    self:disableInput()

    -- Initialize input state
    self:initKeyStates()

    -- Start update timer
    self.updateWrapper = self.updateWrapper or function(tick) self:update(tick) end
    Timer(1, self.updateWrapper)
end

function DefaultInputHandler:initKeyStates()
    local nextIsDown = Controls.check(self.options.keys.Next)
    local prevIsDown = Controls.check(self.options.keys.Prev)
    local confIsDown = Controls.check(self.options.keys.Confirm)

    self.keyStates = {
        Next    = { isDown = nextIsDown, wasReleased = false, wasPressed = false, ignoreNextRelease = nextIsDown },
        Prev    = { isDown = prevIsDown, wasReleased = false, wasPressed = false, ignoreNextRelease = prevIsDown },
        Confirm = { isDown = confIsDown, wasReleased = false, wasPressed = false, ignoreNextRelease = confIsDown }
    }
end

function DefaultInputHandler:disable()
    RemoveTimer(self.updateWrapper)
    self:enableInput()
end

function DefaultInputHandler:update(tick)
    self:updateKeyStates()

    if self.keyStates.Next.wasPressed then
        self.callbacks:selectNextResponse()
    elseif self.keyStates.Prev.wasPressed then
        self.callbacks:selectPrevResponse()
    elseif self.keyStates.Confirm.wasReleased then
        self.callbacks:confirmResponse()
    end
end

function DefaultInputHandler:updateKeyStates()
    for key, state in pairs(self.keyStates) do
        local isDown = Controls.check(self.options.keys[key])

        if isDown then
            state.wasReleased = false
            state.wasPressed = not state.isDown
            state.isDown = true
        else
            -- Ignore the first release of any key that was held when the menu was opened
            -- This prevents unwanted behavior if, for instance, the player was still holding
            -- jump (confirm) when they started talking to a character
            if not state.ignoreNextRelease then
                state.wasReleased = state.isDown
            end
            state.wasPressed = false
            state.isDown = false
            state.ignoreNextRelease = false
        end
    end
end

function DefaultInputHandler:disableInput()
    -- Register an event handler to reenable input if Juni dies while the menu is open
    self.deathEvent = self.deathEvent or function(restart)
        self:enableInput()
    end
    events.global.Death.Add(self.deathEvent)

    EnableKeysInput(false)
end

function DefaultInputHandler:enableInput()
    events.global.Death.Remove(self.deathEvent)
    EnableKeysInput(true)
end

return DefaultInputHandler
