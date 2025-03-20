local M = {}

local gamestate = {players = {}, settings = {}}

local function setGameState(data)
	M.gamestate = data
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
	M.gamestate = gamestate
end


M.setGameState = setGameState
M.updateGameState = updateGameState

return M