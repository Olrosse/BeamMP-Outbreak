
local floor = math.floor
local mod = math.fmod

local gameState = {players = {}}
local lastState = gameState
local weightingArray = {}

gameState.everyoneInfected = false
gameState.gameRunning = false
gameState.gameEnding = false

local includedPlayers = {} --TODO make these do something
local excludedPlayers = {} --TODO make these do something

local roundLength = 5*60 -- length of the game in seconds
local defaultGreenFadeDistance = 100 -- how close the infector has to be for the screen to start to turn green
local defaultColorPulse = false -- if the car color should pulse between the car color and green
local defaultInfectorTint = true -- if the infector should have a green tint
local defaultDistancecolor = 0.5 -- max intensity of the green filter
local disableResetsWhenMoving = true
local maxResetMovingSpeed = 2

MP.RegisterEvent("outbreak_clientReady","clientReady")
MP.RegisterEvent("outbreak_onContactRecieve","onContact")
MP.RegisterEvent("outbreak_requestGameState","requestGameState")
MP.TriggerClientEvent(-1, "outbreak_resetInfected", "data")

local function seconds_to_days_hours_minutes_seconds(total_seconds) --modified code from https://stackoverflow.com/questions/45364628/lua-4-script-to-convert-seconds-elapsed-to-days-hours-minutes-seconds
	local time_days		= floor(total_seconds / 86400)
	local time_hours	= floor(mod(total_seconds, 86400) / 3600)
	local time_minutes	= floor(mod(total_seconds, 3600) / 60)
	local time_seconds	= floor(mod(total_seconds, 60))

	if time_days == 0 then
		time_days = nil
	end
	if time_hours == 0 then
		time_hours = nil
	end
	if time_minutes == 0 then
		time_minutes = nil
	end
	if time_seconds == 0 then
		time_seconds = nil
	end
	return time_days ,time_hours , time_minutes , time_seconds
end

local function compareTable(gameState,tempTable,lastState)
	for varableName,varable in pairs(gameState) do
		if type(varable) == "table" then
			if not lastState[varableName] then
				lastState[varableName] = {}
			end
			if not tempTable[varableName] then
				tempTable[varableName] = {}
			end
			compareTable(gameState[varableName],tempTable[varableName],lastState[varableName])
			if type(tempTable[varableName]) == "table" and next(tempTable[varableName]) == nil then
				tempTable[varableName] = nil
			end
		elseif varable == "remove" then
			tempTable[varableName] = gameState[varableName]
			lastState[varableName] = nil
			gameState[varableName] = nil
		elseif lastState[varableName] ~= varable then
			tempTable[varableName] = gameState[varableName]
			lastState[varableName] = gameState[varableName]
		end
	end
end

local function updateClients()
	local tempTable = {}

	compareTable(gameState,tempTable,lastState)

	if tempTable and next(tempTable) ~= nil then
		MP.TriggerClientEventJson(-1, "outbreak_updateGameState", tempTable)
	end
end

function clientReady(localPlayerID, data)
	local playerName = MP.GetPlayerName(localPlayerID)
	if playerName then
		local player = gameState.players[playerName]
		if player then
			gameState.players[playerName].responded = true
		end
	end
end

function requestGameState(localPlayerID)
	MP.TriggerClientEventJson(localPlayerID, "outbreak_recieveGameState", gameState)
end

local function infectPlayer(playerName,force)
	local player = gameState.players[playerName]
	if player.localContact and player.remoteContact and not player.infected or force and not player.infected then
		player.infected = true
		if not force then
			local infectorPlayerName = player.infecter
			gameState.players[infectorPlayerName].stats.infected = gameState.players[infectorPlayerName].stats.infected + 1
			gameState.InfectedPlayers = gameState.InfectedPlayers + 1
			gameState.nonInfectedPlayers = gameState.nonInfectedPlayers - 1
			gameState.oneInfected = true

			MP.SendChatMessage(-1,""..infectorPlayerName.." has infected "..playerName.."!")
		else
			MP.SendChatMessage(-1,"server has infected "..playerName.."!")
		end

		MP.TriggerClientEvent(-1, "outbreak_recieveInfected", playerName)

		updateClients()
		--MP.TriggerClientEventJson(-1, "outbreak_recieveGameState", gameState)
	end
end

function onContact(localPlayerID, data)
	local remotePlayerName = MP.GetPlayerName(tonumber(data))
	local localPlayerName = MP.GetPlayerName(localPlayerID)
	if gameState.gameRunning and not gameState.gameEnding then
		local localPlayer = gameState.players[localPlayerName]
		local remotePlayer = gameState.players[remotePlayerName]
		if localPlayer and remotePlayer then
			if localPlayer.infected and not remotePlayer.infected then
				gameState.players[remotePlayerName].remoteContact = true
				gameState.players[remotePlayerName].infecter = localPlayerName
				infectPlayer(remotePlayerName)
			end
			if remotePlayer.infected and not localPlayer.infected then
				gameState.players[localPlayerName].localContact = true
				gameState.players[localPlayerName].infecter = remotePlayerName
				infectPlayer(localPlayerName)
			end
			if gameState.nonInfectedPlayers == 0 then 
				gameState.everyoneInfected = true
				updateClients()
			end
		end
	end
end

local function gameSetup(time)
	gameState = {}
	gameState.players = {}
	gameState.settings = {
		GreenFadeDistance = defaultGreenFadeDistance,
		ColorPulse = defaultColorPulse,
		infectorTint = defaultInfectorTint,
		distancecolor = defaultDistancecolor,
		disableResetsWhenMoving = disableResetsWhenMoving,
		maxResetMovingSpeed = maxResetMovingSpeed
		}
	local playerCount = 0
	for ID,Player in pairs(MP.GetPlayers()) do
		if MP.IsPlayerConnected(ID) and MP.GetPlayerVehicles(ID) then
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
			--MP.TriggerClientEvent(-1, "outbreak_addPlayers", tostring(k))
			MP.TriggerClientEvent(-1, "outbreak_addPlayers", Player)
		end
	end

	if playerCount == 0 then
		MP.SendChatMessage(-1,"Failed to start, found no vehicles")
		return
	end

	gameState.playerCount = playerCount
	gameState.InfectedPlayers = 0
	gameState.nonInfectedPlayers = playerCount
	gameState.time = -5
	gameState.roundLength = time or roundLength
	gameState.endtime = -1
	gameState.oneInfected = false
	gameState.everyoneInfected = false
	gameState.gameRunning = true
	gameState.gameEnding = false
	gameState.gameEnded = false

	MP.TriggerClientEventJson(-1, "outbreak_recieveGameState", gameState)
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
		--MP.SendChatMessage(-1,"Game stopped,"..nonInfectedCount.." survived and "..infectedCount.." got infected")
		MP.SendChatMessage(-1,"Game stopped, Everyone Looses")
		gameState.endtime = gameState.time + 10
	else
		MP.SendChatMessage(-1,"Game stopped for uknown reason,"..nonInfectedCount.." survived and "..infectedCount.." got infected")
	end
end

local function infectRandomPlayer()
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
				gameState.players[playername].firstInfected = true

				if gameState.time == 5 then
					MP.SendChatMessage(-1,""..playername.." is first infected!")
				else
					MP.SendChatMessage(-1,"no infected players, "..playername.." has been randomly infected!")
				end
				MP.TriggerClientEvent(-1, "outbreak_recieveInfected", playername)
				gameState.oneInfected = true
				gameState.InfectedPlayers = gameState.InfectedPlayers + 1
				gameState.nonInfectedPlayers = gameState.nonInfectedPlayers - 1
			end
		else
			weightingArray[playername].infections = weightingArray[playername].infections + 100
		end
	end
	if gameState.InfectedPlayers >= gameState.playerCount and gameState.nonInfectedPlayers == 0 then
		gameState.everyoneInfected = true
	end

	MP.TriggerClientEventJson(-1, "outbreak_recieveGameState", gameState)
end

local function gameStarting()
	local days, hours , minutes , seconds = seconds_to_days_hours_minutes_seconds(gameState.roundLength)
	local amount = 0
	if days then
		amount = amount + 1
	end
	if hours then
		amount = amount + 1
	end
	if minutes then
		amount = amount + 1
	end
	if seconds then
		amount = amount + 1
	end
	if days then
		amount = amount - 1
		if days == 1 then
			if amount > 1 then
				days = ""..days.." day, "
			elseif amount == 1 then
				days = ""..days.." day and "
			elseif amount == 0 then
				days = ""..days.." day "
			end
		else
			if amount > 1 then
				days = ""..days.." days, "
			elseif amount == 1 then
				days = ""..days.." days and "
			elseif amount == 0 then
				days = ""..days.." days "
			end
		end
	end
	if hours then
		amount = amount - 1
		if hours == 1 then
			if amount > 1 then
				hours = ""..hours.." hour, "
			elseif amount == 1 then
				hours = ""..hours.." hour and "
			elseif amount == 0 then
				hours = ""..hours.." hour "
			end
		else
			if amount > 1 then
				hours = ""..hours.." hours, "
			elseif amount == 1 then
				hours = ""..hours.." hours and "
			elseif amount == 0 then
				hours = ""..hours.." hours "
			end
		end
	end
	if minutes then
		amount = amount - 1
		if minutes == 1 then
			if amount > 1 then
				minutes = ""..minutes.." minute, "
			elseif amount == 1 then
				minutes = ""..minutes.." minute and "
			elseif amount == 0 then
				minutes = ""..minutes.." minute "
			end
		else
			if amount > 1 then
				minutes = ""..minutes.." minutes, "
			elseif amount == 1 then
				minutes = ""..minutes.." minutes and "
			elseif amount == 0 then
				minutes = ""..minutes.." minutes "
			end
		end
	end
	if seconds then
		if seconds == 1 then
			seconds = ""..seconds.." second "
		else
			seconds = ""..seconds.." seconds "
		end
	end

	MP.SendChatMessage(-1,"Infection game started, you have to survive for "..(days or "")..""..(hours or "")..""..(minutes or "")..""..(seconds or "").."")
end

local function gameRunningLoop()
	local players = gameState.players

	if gameState.time < 0 then
		MP.SendChatMessage(-1,"Infection game starting in "..math.abs(gameState.time).." second")

	elseif gameState.time == 0 then
		gameStarting()
		local unresponsiveString = ""
		for playername,_ in pairs(players) do
			if not gameState.players[playername].responded then
				gameState.players[playername] = "remove"
				if unresponsiveString == "" then
					unresponsiveString = unresponsiveString .. playername
				else
					unresponsiveString = unresponsiveString	.. "," .. playername
				end
			end
		end
		if unresponsiveString ~= "" then
			MP.SendChatMessage(-1,""..unresponsiveString.." did not respond and was removed from this round, rejoining the server should fix this issue")
		end
	end

	if not gameState.gameEnding and gameState.playerCount == 0 then
		gameState.gameEnding = true
		gameState.endtime = gameState.time + 2
	end

	if not gameState.gameEnding and gameState.time > 0 then
		local infectedCount = 0
		local nonInfectedCount = 0
		local playercount = 0
		for playername,player in pairs(players) do
			if player.localContact and player.remoteContact and not player.infected then
				player.infected = true
				MP.SendChatMessage(-1,""..playername.." has been infected!")
				MP.TriggerClientEvent(-1, "outbreak_recieveInfected", playername)
			elseif player.stats and gameState.time > 5 and not player.infected then
				if	not player.stats.survivedTime then
					player.stats.survivedTime = 5
				end
				player.stats.survivedTime = player.stats.survivedTime + 1
			end

			if player.infected then
				infectedCount = infectedCount + 1
			elseif not player.infected then
				nonInfectedCount = nonInfectedCount + 1
			end
			playercount = playercount + 1
		end
		if infectedCount >= gameState.playerCount and nonInfectedCount == 0 then
			gameState.everyoneInfected = true
		end
		gameState.InfectedPlayers = infectedCount
		gameState.nonInfectedPlayers = nonInfectedCount
		gameState.playerCount = playercount

		if gameState.time >= 5 and infectedCount == 0 then
			infectRandomPlayer()
		end
	end

	if not gameState.gameEnding and gameState.time == gameState.roundLength then
		gameEnd("time")
		gameState.endtime = gameState.time + 10
	elseif not gameState.gameEnding and gameState.everyoneInfected == true then
		gameEnd("infected")
		gameState.endtime = gameState.time + 10
	elseif gameState.gameEnding and gameState.time == gameState.endtime then
		gameState.gameRunning = false
		--MP.TriggerClientEvent(-1, "outbreak_resetInfected", "data")

		gameState = {}
		gameState.players = {}
		gameState.everyoneInfected = false
		gameState.gameRunning = false
		gameState.gameEnding = false
		gameState.gameEnded = true

		--MP.TriggerClientEventJson(-1, "outbreak_recieveGameState", gameState)
	end
	if gameState.gameRunning then
		gameState.time = gameState.time + 1
	end

	updateClients()
end

autoStart = false
local autoStartTimer = 0

local autoStartWaitInSeconds = 600

function timer()
	if gameState.gameRunning then
		gameRunningLoop()
	elseif autoStart and MP.GetPlayerCount() > -1 then
		autoStartTimer = autoStartTimer + 1
		if autoStartTimer >= autoStartWaitInSeconds then
			autoStartTimer = 0
			gameSetup()
		end
	end
end

MP.RegisterEvent("onContact", "onContact")

MP.RegisterEvent("second", "timer")
MP.CancelEventTimer("counter")
MP.CancelEventTimer("second")
MP.CreateEventTimer("second",1000)



local commands = {}

local function help(sender_id, sender_name, message, variable)
	MP.SendChatMessage(sender_id,"Infection command list")

	for k,v in pairs(commands) do
		local usage
		if v.usage then
			usage = v.usage..","
		else
			usage = ""
		end
		MP.SendChatMessage(sender_id,"/infection "..k..", "..usage.." "..v.tooltip.."")
	end
end

local function join(sender_id, sender_name, message, number)
	local playerid = number or sender_id
	local playername = MP.GetPlayerName(playerid)
	includedPlayers[playerid] = true
	MP.SendChatMessage(sender_id,"enabled for "..playername.."")
end

local function leave(sender_id, sender_name, message, number)
	local playerid = number or sender_id
	local playername = MP.GetPlayerName(playerid)
	includedPlayers[playerid] = nil
	MP.SendChatMessage(sender_id,"enabled for "..playername.."")
end

local function start(sender_id, sender_name, message, value)
	if not gameState.gameRunning then
		if value then value = value*60 end
		gameSetup(value)
	else
		MP.SendChatMessage(sender_id,"gamestart failed, game already running")
	end
end

local function stop(sender_id)
	if gameState.gameRunning then
		gameEnd("manual")
	else
		MP.SendChatMessage(sender_id,"gamestop failed, game not running")
	end
end

local function gameLength(sender_id, sender_name, message, value)
	if value then
		roundLength = value*60
		MP.SendChatMessage(sender_id,"set game length to "..value.."")

	else
		MP.SendChatMessage(sender_id,"setting roundLength failed, no value")
	end
end

local function reset(sender_id, sender_name, message, variable)
	weightingArray = {}
end

local function greenFadeDist(sender_id, sender_name, message, value)
	if value then
		defaultGreenFadeDistance = value
		if gameState.settings then
			gameState.settings.GreenFadeDistance = defaultGreenFadeDistance
		end
		MP.SendChatMessage(sender_id,"set greenFadeDist to "..value.."")

	else
		MP.SendChatMessage(sender_id,"setting greenFadeDist failed, no value")
	end
end

local function ColorPulse(sender_id, sender_name, message, value)
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
end

local function infectorTint(sender_id, sender_name, message, value)
	if defaultInfectorTint then
		defaultInfectorTint = false
		MP.SendChatMessage(sender_id,"setting infector tint to false")
	else
		defaultInfectorTint = true
		MP.SendChatMessage(sender_id,"setting infector tint to true")
	end
	if gameState.settings then
		gameState.settings.infectorTint = defaultInfectorTint
	end
end

local function filterIntensity(sender_id, sender_name, message, value)
	if value then
		defaultDistancecolor = value
		if gameState.settings then
			gameState.settings.distancecolor = defaultDistancecolor
		end
		MP.SendChatMessage(sender_id,"set filterIntensity to "..value.."")
	else
		MP.SendChatMessage(sender_id,"setting filterIntensity failed, no value")
	end
end

local function resetToggle(sender_id, sender_name, message, value)
	disableResetsWhenMoving = not disableResetsWhenMoving
	if gameState.settings then
		gameState.settings.disableResetsWhenMoving = disableResetsWhenMoving
	end
	if disableResetsWhenMoving then
		MP.SendChatMessage(sender_id,"Resetting is now restricted")
	else
		MP.SendChatMessage(sender_id,"Resetting is now allowed")
	end
end

local function setResetSpeed(sender_id, sender_name, message, value)
	if value then
		maxResetMovingSpeed = value
		if gameState.settings then
			gameState.settings.maxResetMovingSpeed = maxResetMovingSpeed
		end
		MP.SendChatMessage(sender_id,"set Max Reset Speed to "..value.."")
	else
		MP.SendChatMessage(sender_id,"setting Max Reset Speed failed, no value")
	end
end

commands = {
	["help"] = {
		["function"] = help,
		["tooltip"] = "Displays List of available commands"
	},
	["start"] = {
		["function"] = start,
		["tooltip"] = "starts infection game",
		["usage"] = "optional time in minutes"
	},
	["stop"] = {
		["function"] = stop,
		["tooltip"] = "stops infection game",
	},
	["reset"] = {
		["function"] = reset,
		["tooltip"] = "resets randomizer weights",
	},
	["game length set"] = {
		["function"] = gameLength,
		["tooltip"] = "sets the length of the round",
		["usage"] = "minutes"
	},
	["greenFadeDist set"] = {
		["function"] = greenFadeDist,
		["tooltip"] = "Adjusts how close in meters an infected car needs to be for the screen to start going green",
		["usage"] = "meters"
	},
	["filterIntensity set"] = {
		["function"] = filterIntensity,
		["tooltip"] = "Sets how intense the vignetting effect is",
		["usage"] = "0 to 1"
	},
	["ColorPulse toggle"] = {
		["function"] = ColorPulse,
		["tooltip"] = "Enabling this makes the infected cars pulse between green and the original color of the car",
	},
	["infector tint toggle"] = {
		["function"] = infectorTint,
		["tooltip"] = "This toggles on or off the vignetting effect on infected players",
	},
	["ResetAtSpeedAllowed toggle"] = {
		["function"] = resetToggle,
		["tooltip"] = "This toggles whether players can reset at speed",
	},
	["MaxResetSpeed set"] = {
		["function"] = setResetSpeed,
		["tooltip"] = "Sets the highest speed where resets are allowed",
	},
}

--Chat Commands
function outbreakChatMessageHandler(sender_id, sender_name, message)
	local msgStart = string.match(message,"[^%s]+")
	if msgStart == "/outbreak" or msgStart == "/infection" then
		local commandstringraw = string.sub(message,string.len(msgStart)+2)
		local commandstring, variable = string.match(commandstringraw,"^(.+) (%d*%.?%d*)$")
		local commandStringFinal = commandstring or commandstringraw

		if commands[commandStringFinal] then
			commands[commandStringFinal]["function"](sender_id, sender_name, message ,tonumber(variable))
		else
			MP.SendChatMessage(sender_id,"command not found, type /infection help for a list of infection commands")
		end
		return 1
	elseif string.sub(message,1,5) == "/help" then
		MP.SendChatMessage(sender_id,"type /infection help for a list of infection commands")
		return 1
	end
end

function onPlayerDisconnect(playerID)
	local PlayerName = MP.GetPlayerName(playerID)
	if gameState.gameRunning and gameState.players and gameState.players[PlayerName] then
		gameState.players[PlayerName] = "remove"
	end
end

function onVehicleDeleted(playerID,vehicleID)
	local PlayerName = MP.GetPlayerName(playerID)
	if gameState.gameRunning and gameState.players and gameState.players[PlayerName] then
		if not MP.GetPlayerVehicles(playerID) then
			gameState.players[PlayerName] = "remove"
		end
	end
end

MP.TriggerClientEventJson(-1, "outbreak_recieveGameState", gameState)
MP.TriggerClientEvent(-1, "outbreak_resetInfected", "data")

MP.RegisterEvent("onChatMessage", "outbreakChatMessageHandler")
MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
MP.RegisterEvent("onVehicleDeleted", "onVehicleDeleted")
MP.RegisterEvent("onPlayerJoin", "requestGameState")

