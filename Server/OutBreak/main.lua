
local gameState = {players = {}}
local laststate = gameState
local weightingArray = {}

gameState.everyoneInfected = false
gameState.gameRunning = false
gameState.gameEnding = false

local includedPlayers = {}
local excludedPlayers = {}

local roundLenght = 60*5
local defaultGreenFadeDistance = 20
local defaultColorPulse = true

MP.RegisterEvent("onContactRecieve","onContact")
MP.RegisterEvent("requestGameState","requestGameState")
MP.TriggerClientEvent(-1, "resetInfected", "data")

local function updateClients()
	local tempTable = {}

	for variableName,value in pairs(gameState) do

		if variableName == "players" then
			if not next(value) and next(laststate[variableName]) then
				laststate[variableName] = value
				tempTable[variableName] = {removed = true}
			end
			for playerName,PlayerVariables in pairs(value) do

				if not laststate[variableName][playerName] then
					laststate[variableName][playerName] = {}
				end

				for playerVariableName,Playervalue in pairs(PlayerVariables) do

					if laststate[variableName][playerName][playerVariableName] ~= Playervalue then

						if not tempTable[variableName] then
							tempTable[variableName] = {}
						end
						if not tempTable[variableName][playerName] then
							tempTable[variableName][playerName] = {}
						end

						tempTable[variableName][playerName][playerVariableName] = Playervalue
						laststate[variableName][playerName][playerVariableName] = Playervalue
					end

				end
			end

			if laststate.players then
				for playerName,PlayerVariables in pairs(laststate.players) do
					if not gameState.players[playerName] then
						laststate.players[playerName] = nil
						if not tempTable.player then
							tempTable.players = {}
						end
						tempTable.players[playerName] = {}
						tempTable.players[playerName].removed = true
					end 
				end
			end
		elseif variableName == "settings" then
			if not laststate[variableName] then
				laststate[variableName] = {}
			end
			for settingName,settingVariable in pairs(value) do
				if laststate[variableName][settingName] ~= settingVariable then
					if not tempTable[variableName] then
						tempTable[variableName] = {}
					end
					laststate[variableName][settingName] = settingVariable
					tempTable[variableName][settingName] = settingVariable
				end
			end
		else
			if laststate[variableName] ~= value then
				tempTable[variableName] = value
				laststate[variableName] = value
			end
		end
	end
	if tempTable and next(tempTable) ~= nil then
		--if tempTable.players then print(tempTable.players,"1",laststate.players,"2",gameState.players) end
		MP.TriggerClientEventJson(-1, "updateGameState", tempTable)
	end
end

function requestGameState(localPlayerID)
	--print(localPlayerID,gameState)
	MP.TriggerClientEventJson(localPlayerID, "recieveGameState", gameState)
end

function onContact(localPlayerID, data)
	local remotePlayerName = MP.GetPlayerName(tonumber(data))
	local localPlayerName = MP.GetPlayerName(localPlayerID)
	if gameState.gameRunning and not gameState.gameEnding then
		local localPlayer = gameState.players[localPlayerName]
		local remotePlayer = gameState.players[remotePlayerName]
		local infectedCount = 0
		local nonInfectedCount = 0
		if localPlayer and remotePlayer then 
			if localPlayer.infected == true then
				gameState.players[remotePlayerName].remoteContact = true
				gameState.players[remotePlayerName].infecter = localPlayerName
			end
			if remotePlayer.infected == true then
				gameState.players[localPlayerName].localContact = true
				gameState.players[localPlayerName].infecter = remotePlayerName
			end
			for k,player in pairs(gameState.players) do
				if player.localContact and player.remoteContact and not player.infected then
					player.infected = true
					local playername = k
					local infectorPlayerName = player.infecter
					MP.SendChatMessage(-1,""..infectorPlayerName.." has infected "..playername.."!")

					gameState.players[infectorPlayerName].stats.infected = gameState.players[infectorPlayerName].stats.infected + 1

					infectedCount = infectedCount + 1
					MP.TriggerClientEvent(-1, "recieveInfected", k)
					gameState.oneInfected = true
					updateClients()
					MP.TriggerClientEventJson(-1, "recieveGameState", gameState)
				elseif player.infected then
					infectedCount = infectedCount + 1
				elseif not player.infected then
					nonInfectedCount = nonInfectedCount + 1
				end
			end
		end
		gameState.InfectedPlayers = infectedCount
		gameState.nonInfectedPlayers = nonInfectedCount
		if nonInfectedCount == 0 then 
			gameState.everyoneInfected = true
			updateClients()
			MP.TriggerClientEventJson(-1, "recieveGameState", gameState)
		end
	end
end

local function gameSetup()
	gameState = {}
	gameState.players = {}
	gameState.settings = {GreenFadeDistance = defaultGreenFadeDistance, ColorPulse = defaultColorPulse}
	local playerCount = 0
	for ID,Player in pairs(MP.GetPlayers()) do
		if MP.IsPlayerConnected(ID) then
			if not weightingArray[Player] then
				weightingArray[Player] = {}
				weightingArray[Player].games = 1
				weightingArray[Player].infections = 1
			else
				weightingArray[Player].games = weightingArray[Player].games + 1
			end

			local player = {}
			player.stats = {}
			player.stats.infected = 0
			player.ID = ID
			player.infected = false
			player.localContact = false
			player.remoteContact = false
			gameState.players[Player] = player
			playerCount = playerCount + 1
			--MP.TriggerClientEvent(-1, "addPlayers", tostring(k))
			MP.TriggerClientEvent(-1, "addPlayers", Player)
		end
	end
	gameState.playerCount = playerCount
	gameState.InfectedPlayers = 0
	gameState.nonInfectedPlayers = playerCount
	gameState.time = -10
	gameState.roundLenght = roundLenght
	gameState.endtime = -1
	gameState.oneInfected = false
	gameState.everyoneInfected = false
	gameState.gameRunning = true
	gameState.gameEnding = false
	gameState.gameEnded = false
	
	MP.TriggerClientEventJson(-1, "recieveGameState", gameState)
end

local function gameEnd(reason)
	gameState.gameEnding = true
	local infectedCount = 0
	local nonInfectedCount = 0
	local players = gameState.players
	for k,player in pairs(players) do
		if player.infected then
			infectedCount = infectedCount + 1
		else
			nonInfectedCount = nonInfectedCount + 1
		end
	end
	if reason == "time" then
		MP.SendChatMessage(-1,"Game over,"..nonInfectedCount.." survived and "..infectedCount.." got infected")
	elseif reason == "infected" then
		MP.SendChatMessage(-1,"Game over, no survivors")
	elseif reason == "manual" then
		MP.SendChatMessage(-1,"Game stopped,"..nonInfectedCount.." survived and "..infectedCount.." got infected")
		gameState.endtime = gameState.time + 10
	else
		MP.SendChatMessage(-1,"Game stopped for uknown reason,"..nonInfectedCount.." survived and "..infectedCount.." got infected")
	end
end

local function gameRunningLoop()
	if gameState.time < 0 then
		MP.SendChatMessage(-1,"Infection game starting in "..math.abs(gameState.time).." second")
	elseif gameState.time == 0 then
		MP.SendChatMessage(-1,"Infection game started, you have "..roundLenght.." seconds to survive")
	end

	if not gameState.gameEnding and gameState.playerCount == 0 then
		gameState.gameEnding = true
		gameState.endtime = gameState.time + 2
	end

	if not gameState.gameEnding and gameState.time >= 5 then
		local infectedCount = 0
		local nonInfectedCount = 0
		for k,player in pairs(gameState.players) do
			if player.infected then
				infectedCount = infectedCount + 1
			elseif not player.infected then
				nonInfectedCount = nonInfectedCount + 1
			end
		end
		if infectedCount == 0 and nonInfectedCount ~= 0 then
			gameState.oneInfected = false
			local players = gameState.players
			local weightRatio = 0
			for playername,player in pairs(players) do

				local infections = weightingArray[playername].infections
				local games = weightingArray[playername].games
				local playerCount = gameState.playerCount

				local weight = math.max(1,(1/((games/infections)/playerCount))*100)
				weightingArray[playername].startNumber = weightRatio
				weightRatio = weightRatio + weight
				weightingArray[playername].endNumber = weightRatio
				weightingArray[playername].weightRatio = weightRatio
				--print(playername,weightingArray[playername].endNumber - weightingArray[playername].startNumber,weightingArray[playername].startNumber , weightingArray[playername].endNumber,weightingArray[playername].infections,weightingArray[playername].games,gameState.playerCount)
			end

			local randomID = math.random(1, math.floor(weightRatio))
			
			for playername,player in pairs(players) do
				if randomID >= weightingArray[playername].startNumber and randomID <= weightingArray[playername].endNumber then--if count == randomID then
					if not gameState.oneInfected then
						gameState.players[playername].remoteContact = true
						gameState.players[playername].localContact = true
						gameState.players[playername].infected = true

						if gameState.time == 5 then
							MP.SendChatMessage(-1,""..playername.." is first infected!")
						else
							MP.SendChatMessage(-1,"no infected players, "..playername.." has been randomly infected!")
						end
						MP.TriggerClientEvent(-1, "recieveInfected", playername)
						gameState.oneInfected = true
						nonInfectedCount = nonInfectedCount - 1
						infectedCount = infectedCount + 1
					end
				else
					weightingArray[playername].infections = weightingArray[playername].infections + 100
				end
			end
			--print(infectedCount , gameState.playerCount , nonInfectedCount)
			if infectedCount >= gameState.playerCount and nonInfectedCount == 0 then
				gameState.everyoneInfected = true
			end
			
			gameState.InfectedPlayers = infectedCount
			gameState.nonInfectedPlayers = nonInfectedCount
			MP.TriggerClientEventJson(-1, "recieveGameState", gameState)
			--print(randomID,weightingArray)
		end
	end

	local players = gameState.players
 

	if not gameState.gameEnding and gameState.time > 0 then
		local infectedCount = 0
		local nonInfectedCount = 0
		local playercount = 0
		for playername,player in pairs(players) do
			playercount = playercount + 1
			if player.localContact and player.remoteContact and not player.infected then
				player.infected = true
				MP.SendChatMessage(-1,""..playername.." has been infected!")
				MP.TriggerClientEvent(-1, "recieveInfected", playername)
			end

			if player.infected then
				infectedCount = infectedCount + 1
			elseif not player.infected then
				nonInfectedCount = nonInfectedCount + 1
			end
		end
			
		gameState.InfectedPlayers = infectedCount
		gameState.nonInfectedPlayers = nonInfectedCount
		gameState.playerCount = playercount
	end

	if not gameState.gameEnding and gameState.time == gameState.roundLenght then
		gameEnd("time")
		gameState.endtime = gameState.time + 10
	elseif not gameState.gameEnding and gameState.everyoneInfected == true then
		gameEnd("infected")
		gameState.endtime = gameState.time + 10
	elseif gameState.gameEnding and gameState.time == gameState.endtime then
		gameState.gameRunning = false
		--MP.TriggerClientEvent(-1, "resetInfected", "data")
		--print(gameState.gameEnding ,gameState.time ,gameState.endtime)

		gameState = {}
		gameState.players = {}
		gameState.everyoneInfected = false
		gameState.gameRunning = false
		gameState.gameEnding = false
		gameState.gameEnded = true

		--MP.TriggerClientEventJson(-1, "recieveGameState", gameState)
	end
	if gameState.gameRunning then
		gameState.time = gameState.time + 1
	end

	updateClients()
	--print(gameState)
end

function timer()
	if gameState.gameRunning then
		gameRunningLoop()
	else
		--gameSetup()
	end
end

MP.RegisterEvent("onContact", "onContact")

MP.RegisterEvent("second", "timer")
MP.CancelEventTimer("counter")
MP.CancelEventTimer("second")
MP.CreateEventTimer("second",1000)

--Chat Commands
function outbreakChatMessageHandler(sender_id, sender_name, message)
	if message == "/outbreak join" or string.find(message,"/outbreak join %d+") then
		local number = tonumber(string.sub(message,14,10000))
		local playerid = number or sender_id
		local playername = MP.GetPlayerName(playerid)
		includedPlayers[playerid] = true
		MP.SendChatMessage(sender_id,"enabled for "..playername.."")
		return 1
		
	elseif message == "/outbreak leave" or string.find(message,"/outbreak leave %d+") then
		local number = tonumber(string.sub(message,15,10000))
		local playerid = number or sender_id
		local playername = MP.GetPlayerName(playerid)
		includedPlayers[playerid] = nil
		MP.SendChatMessage(sender_id,"enabled for "..playername.."")
		return 1
		
	elseif message == "/outbreak start" or string.find(message,"/outbreak start %d+") then
		local number = tonumber(string.sub(message,15,10000))
		if not gameState.gameRunning then
			local gameLenght = number or roundLenght
			gameSetup()
		else
			MP.SendChatMessage(sender_id,"gamestart failed, game already running")
		end

		return 1
		
	elseif message == "/outbreak stop" then
		if gameState.gameRunning then
			gameEnd("manual")
		else
			MP.SendChatMessage(sender_id,"gamestop failed, game not running")
		end

		return 1

    elseif string.find(message,"/outbreak game length set %d+") then
		local value = tonumber(string.sub(message,27,10000))
		if value then
			roundLenght = value*60
			MP.SendChatMessage(sender_id,"set game length to "..value.."")
			
		else
			MP.SendChatMessage(sender_id,"setting roundLenght failed, no value")
		end
		return 1

    elseif string.find(message,"/outbreak greenFadeDist set %d+") then
		local value = tonumber(string.sub(message,29,10000))
		if value then
			defaultGreenFadeDistance = value
			if gameState.settings then
				gameState.settings.GreenFadeDistance = defaultGreenFadeDistance
			end
			MP.SendChatMessage(sender_id,"set greenFadeDist to "..value.."")
			
		else
			MP.SendChatMessage(sender_id,"setting roundLenght failed, no value")
		end
		return 1

    elseif string.find(message,"/outbreak ColorPulse toggle") then
		if defaultColorPulse then
			defaultColorPulse = false
			MP.SendChatMessage(sender_id,"setting ColorPulse to false")
		else
			defaultColorPulse = true
			MP.SendChatMessage(sender_id,"setting ColorPulse to true")
		end
		if gameState.settings then
			gameState.settings.ColorPulse = defaultColorPulse
		end
		return 1

    elseif string.find(message,"/outbreak reset") then
			weightingArray = {}
		return 1
		
    elseif message == "/outbreak help" then
		MP.SendChatMessage(sender_id,"/outbreak start")
		MP.SendChatMessage(sender_id,"/outbreak stop")
		MP.SendChatMessage(sender_id,"/outbreak game length set (minutes))")
		MP.SendChatMessage(sender_id,"/outbreak reset (resets randomizer)")
	--	excludedPlayers[]
		return 1
    else
        return 0
	end
end

function onPlayerDisconnect(playerID)
	local PlayerName = MP.GetPlayerName(playerID)
	if gameState.gameRunning and gameState.players and gameState.players[PlayerName] then
		gameState.players[PlayerName] = nil
		--gameState.playerCount = gameState.playerCount - 1
	end
end

MP.TriggerClientEventJson(-1, "recieveGameState", gameState)
MP.TriggerClientEvent(-1, "resetInfected", "data")

MP.RegisterEvent("onChatMessage", "outbreakChatMessageHandler")
MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
MP.RegisterEvent("onPlayerJoin", "requestGameState")
