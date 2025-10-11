local M = {}

M.gamestate = {players = {}, settings = {}}

local gameModeUpdate = nop
local gameModeUpdateRunning = false

local function checkGameRunning()
	if M.gamestate.gameRunning then
		if not gameModeUpdateRunning then
			gameModeUpdate = outbreakcontactdetection and outbreakcontactdetection.checkForCollisions or nop
			gameModeUpdateRunning = true
		end
	elseif gameModeUpdateRunning then
		gameModeUpdate = nop
		gameModeUpdateRunning = false
	end
end

local function setGameState(data)
	M.gamestate = data
	checkGameRunning()
end

local function mergeTable(table,gamestateTable)
	for variableName,value in pairs(table) do
		if type(value) == "table" then
			if not gamestateTable[variableName] then
				gamestateTable[variableName] = {}
			end
			mergeTable(value,gamestateTable[variableName])
		elseif value == "remove" then
			gamestateTable[variableName] = nil
		else
			gamestateTable[variableName] = value
		end
	end
end

local function updateGameState(data)
	mergeTable(jsonDecode(data),M.gamestate)
	checkGameRunning()
end

local function updateGFX()
	gameModeUpdate()
end

M.setGameState = setGameState
M.updateGameState = updateGameState
M.updateGFX = updateGFX

return M