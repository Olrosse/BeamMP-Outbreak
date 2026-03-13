local M = {}

M.gamestate = {players = {}, settings = {}}

local gameRunning = false
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

local currentMailboxVersion = -1

local function updateGameState(dt)
	local lastMailboxVersion = obj:getLastMailboxVersion("OutbreakGameState")
	if currentMailboxVersion ~= lastMailboxVersion then
		currentMailboxVersion = lastMailboxVersion
		M.gamestate = lpack.decode(obj:getLastMailbox("OutbreakGameState"))
		checkGameRunning()
    end
end

local function updateGFX()
	if gameRunning then
		updateGameState()
		gameModeUpdate()
	end
	outbreakcontactdetection.checkForCollisions()
end

local function setGameIsRunning()
	gameRunning = true
end

local function setGameIsStopped()
	gameRunning = false
end

M.setGameIsRunning = setGameIsRunning
M.setGameIsStopped = setGameIsStopped
M.updateGameState = updateGameState
M.updateGFX = updateGFX

return M