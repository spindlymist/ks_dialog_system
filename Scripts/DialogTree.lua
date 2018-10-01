local DialogTree = {}

function DialogTree:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function DialogTree:init()
	-- Load dialog tree from file
	self.dialog = dofile(WorldPath .."Dialog/".. self.file ..".lua")
	
	-- Ensure character's namespace exists
	if vars.gameState[self.dialog.character] == nil then
		vars.gameState[self.dialog.character] = {}
	end
	
	-- Set the ::times variable to 0. This variable holds the number
	-- of times the dialog menu has been shown.
	vars.gameState[self.dialog.character].times = 0
	
	-- Create prefixes for namespaces
	self.globalPrefix = "vars.gameState.global."
	self.charPrefix = "vars.gameState.".. self.dialog.character .."."
	
	-- Convert sign letter to object index and find sign object
	local index
	if self.sign == "A" then
		index = 17
	elseif self.sign == "B" then
		index = 18
	elseif self.sign == "C" then
		index = 19
	end
	self.sign = Objects.Find{Bank = 0, Obj = index}
	-- Record original sign location
	self.signX = self.sign:GetX()
	self.signY = self.sign:GetY()
	
	-- Check for passive text
	local passive = self:matchFirst(self.dialog.passive)
	if passive == nil then
		-- Hide the sign
		self:hideSign()
	else
	    -- Update sign with passive text
		self.sign:SetFlag(0, true)
		self.sign:SetString(0, passive)
		self.sign:SetFlag(1, false)
		self.sign:SetFlag(2, false)
	end
end

function DialogTree:replaceNamespaceSpecifiers(str)
	str = str:gsub("global::", self.globalPrefix)
	str = str:gsub("::", self.charPrefix)
	return str
end

function DialogTree:matchFirst(field)
	-- If the field is empty or a string, just return it
	if field == nil or type(field) == "string" then
		return field
	end
	
	-- If it's a table, go through each element
	-- Return the first element that meets all its conditions
	for i, v in pairs(field) do
		-- If it's a string, return this element
		if type(v) == "string" then
			return v
		end
		
		-- If it's a table, check each condition
		if self:checkConditions(v.conditions) then
			-- If all conditions are met, return this element
			return v[1]
		end
	end
	
	-- No element met all of its conditions
	return nil
end

function DialogTree:checkConditions(conditions)
	-- If there are no conditions, return true
	if conditions == nil then
		return true
	end
	
	-- If there is a single condition, wrap it in a table
	if type(conditions) == "string" then
		conditions = {conditions}
	end
	
	-- Otherwise, check each condition
	local conditionsMet = true
	for k, cnd in pairs(conditions) do
		if not self:checkCondition(cnd) then
			conditionsMet = false
			break
		end
	end
	
	return conditionsMet
end

function DialogTree:checkCondition(cnd)
	-- Replace namespace specifiers and parse as Lua code
	local f = loadstring("return ".. self:replaceNamespaceSpecifiers(cnd))
	-- Execute code and return the value
	return f()
end

function DialogTree:processConsequences(consequences)
	-- Return if there are no consequences
	if consequences == nil then return end
	
	-- If there is a single conseqeuence, wrap it in a table
	if type(consequences) == "string" then
		consequences = {consequences}
	end
	
	-- Iterate through the list of consequences
	for k, consequence in pairs(consequences) do
		-- Check for the simple consequence "::variableName"
		if consequence:match("[=( ]") == nil then
			-- For the simple form, just set that variable to true
			consequence = consequence .."=true"
		end
		-- Replace namespace specifiers and parse as Lua code
		local f = loadstring(self:replaceNamespaceSpecifiers(consequence))
		-- Execute code
		f()
	end
end

function DialogTree:processDialogKey(key)
    -- Check for file specifier (path/to/file::)
	local separatorIdx = key:find("::")
	if separatorIdx ~= nil then
		-- Separate into the filename and key
		self.file = key:sub(1, separatorIdx - 1)
		key = key:sub(separatorIdx + 2)
		-- Load new dialog
		self.dialog = dofile(WorldPath .."Dialog/".. self.file ..".lua")
	end
	
	return key
end

function DialogTree:show()
	-- Initialize variables
	self.textObjects = {}
	self.keyDown_up = false
	self.keyDown_down = false
	self.keyDown_jump = false
	
	-- Increase ::times variable
	vars.gameState[self.dialog.character].times = vars.gameState[self.dialog.character].times + 1

	-- Find the initial dialog state
	local active = self:matchFirst(self.dialog.active)
	if active == nil and vars.gameState[self.dialog.character].times == 1 then
		-- Default to "first" if none was specified and this is the first time
		if self.dialog.first == nil then
			-- "first" is undefined. Abort
			return
		end
		active = "first"
	elseif active == nil then
		-- There is no default if the character has already been talked to.
		-- The dialog writer must include their own logic using ::times
		-- if they want to be able to talk to the character multiple times.
		return
	end
	
	-- Disable player movement
	EnableKeysInput(false)
	
	-- Show background
	self.bg = Objects.NewTemplate(0, 0, 8)
	self.bg:LoadFrame(WorldPath.."Objects/DialogBackground.png")
	self.bg:SetX(100)
	self.bg:SetY(120)

	-- Show cursor
	self.cursor = Objects.NewTemplate(0, 0, 9)
	self.cursor:LoadFrame(WorldPath.."Objects/Cursor.png")
	self.cursor:SetX(15)
	
	-- Ensure sign is visible
	self:showSign()
	
	-- Go to the initial dialog state
	active = self:processDialogKey(active)
	self:setDialogState(active)
	
	-- Start update timer
	local firstTick = -1
	Timer(1, function(tick)
		if firstTick == -1 then
			firstTick = tick
		-- Ignore first 8 ticks because down key will
		-- be held from the shift.
		elseif tick - firstTick > 8 then
			self:update(tick)
		end
	end)
end

function DialogTree:setDialogState(key)
	-- Delete existing text objects
	for i, txt in pairs(self.textObjects) do
		txt:Destroy()
	end
	self.textObjects = {}
	
	-- Update sign
	self.sign:SetFlag(0, true)
	if type(self.dialog[key]) == "string" then
		self.sign:SetString(0, self.dialog[key])
	else
		self.sign:SetString(0, self:matchFirst(self.dialog[key][1]))
	end
	self.sign:SetFlag(1, false)
	self.sign:SetFlag(2, false)

	-- If this is a terminal line, hide the menu
	if type(self.dialog[key]) == "string" or #self.dialog[key] < 2 then
		self:hide()
		return
	end
	
	-- Check conditions for responses
	self.responses = {}
	local potentialResponses = range{self.dialog[key], 2}
	for k, response in pairs(potentialResponses) do
		if self:checkConditions(response.conditions) then
			-- If all conditions are met, add this response to the list
			self.responses[#self.responses + 1] = response
		end
	end
	
	-- Create text objects
	self.responseHeight = 240 / #self.responses
	local y = 0
	for i, response in pairs(self.responses) do
		local txt = Objects.Text{Layer = -1, Permanent = 1}
		txt:SetLayer(2)
		txt:MoveToBack()
		txt:SetPosition(30, y)
		txt:SetHeight(self.responseHeight)
		txt:SetWidth(150)
		txt:ReplaceColor(15, 14, 14, 255, 255, 255)
		if type(response) == "table" then
			txt:SetText(self:matchFirst(response[1]))
		else
			txt:SetText(response)
		end
		self.textObjects[i] = txt
		y = y + self.responseHeight
	end
	self.textObjects[1]:ReplaceColor(255, 255, 255, 255, 128, 0)
	
	-- Return cursor to top
	self.response = 1
	self.cursor:SetY(self.responseHeight / 2)
end

function DialogTree:updateCursor(newPosition)
	-- Make current 0 white
	self.textObjects[self.response]:ReplaceColor(255, 128, 0, 255, 255, 255)
	-- Update response
	self.response = newPosition
	-- Move cursor
	self.cursor:SetY(self.responseHeight * (self.response - 0.5))
	-- Make new response orange
	self.textObjects[self.response]:ReplaceColor(255, 255, 255, 255, 128, 0)
end

function DialogTree:update(tick)
	-- Moving cursor down
	if self.keyDown_down and not Controls.check("Down") then
		-- Wrap around if necessary
		if self.response == #self.responses then
			self:updateCursor(1)
		else
			self:updateCursor(self.response + 1)
		end
	-- Moving cursor up
	elseif self.keyDown_up and not Controls.check("Up") then
		-- Wrap around if necessary
		if self.response == 1 then
			self:updateCursor(#self.responses)
		else
			self:updateCursor(self.response - 1)
		end
	-- Selecting
	elseif self.keyDown_jump and not Controls.check("Jump") then
		-- Check for consequences of this response
		self:processConsequences(self.responses[self.response].consequences)
	
		-- If this is a terminal response, hide the sign
		-- and hide the menu.
		local after = self:matchFirst(self.responses[self.response].after)
		if after == nil then
			self:hideSign()
			self:hide()
			return
		end
		
		-- Check if the new state is in a different dialog tree
		after = self:processDialogKey(after)
		
		-- Go to the next dialog state
		self:setDialogState(after)
	end
	
	-- Update key states
	self.keyDown_down = Controls.check("Down")
	self.keyDown_up = Controls.check("Up")
	self.keyDown_jump = Controls.check("Jump")
end

function DialogTree:hide()
	-- Remove update timer
	RemoveTimer()
	-- Remove cursor
	self.cursor:Destroy()
	-- Remove text
	for i, txt in pairs(self.textObjects) do
		txt:Destroy()
	end
	-- Remove background
	self.bg:Destroy()
	-- Call dialog end callback, if any
	if self.onDialogEnd ~= nil then
		self.onDialogEnd()
	end
	-- Reenable player movement
	EnableKeysInput(true)
end

function DialogTree:hideSign()
	self.sign:SetPosition(0, -120)
end

function DialogTree:showSign()
	self.sign:SetPosition(self.signX, self.signY)
end

return DialogTree