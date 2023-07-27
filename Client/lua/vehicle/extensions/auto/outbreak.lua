local M = {}

local gamestate = {players = {}, settings = {}}

--local originalstartRecovery = recovery.startRecovering
--local originalstopRecovery = recovery.stopRecovering()
--
--local function newStartRecovering(useAltMode)
--	if gamestate.gameRunning then return end
--	originalstartRecovery(useAltMode)
--end
--local function newStopRecovering()
--	if gamestate.gameRunning then return end
--	originalstopRecovery()
--end
--
--recovery.startRecovering = newStartRecovering
--recovery.stopRecovering = newStopRecovering

local function setGameState(data)
	--local data = jsonDecode(data)
	gamestate = data
end

local function mergeTable(table,gamestateTable)
	for variableName,value in pairs(table) do
		if type(value) == "table" then
			mergeTable(value,gamestateTable[variableName])
		elseif value == "remove" then
			gamestateTable[variableName] = nil
		else
			gamestateTable[variableName] = value
		end
	end
end

local function updateGameState(data)
	mergeTable(data,gamestate)
	dump(gamestate)
end

M.setGameState = setGameState
M.updateGameState = updateGameState

return M