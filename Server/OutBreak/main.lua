
gameState = {}
includedPlayers = {}
excludedPlayers = {}
everyoneInfected = false
gameRunning = false
gameEnding = false

roundLenght = 20--60*5
time = 0
endtime = -1

MP.RegisterEvent("onContactRecieve","onContact")

function onContact(localPlayerID, data)
	local remotePlayerID = tonumber(data)
	if gameRunning and not gameEnding then
		local localPlayer = gameState.players[localPlayerID]
		local remotePlayer = gameState.players[remotePlayerID]

		local infectedCount = 0
		local nonInfectedCount = 0
		if localPlayer and remotePlayer then
			if localPlayer.infected == true then
				gameState.players[remotePlayerID].remoteContact = true
				gameState.players[remotePlayerID].infecter = localPlayerID
			end
			if remotePlayer.infected == true then
				gameState.players[localPlayerID].localContact = true
				gameState.players[localPlayerID].infecter = remotePlayerID
			end
			for k,player in pairs(gameState.players) do
				if player.localContact and player.remoteContact and not player.infected then
					player.infected = true
					local playername = MP.GetPlayerName(k)
					local infectorPlayerName = MP.GetPlayerName(player.infecter)
					MP.SendChatMessage(-1,""..playername.." has been infected by "..infectorPlayerName.."!")
					infectedCount = infectedCount + 1
					MP.TriggerClientEvent(-1, "recieveInfected", tostring(k))
					oneInfected = true
				elseif player.infected then
					infectedCount = infectedCount + 1
				elseif not player.infected then
					nonInfectedCount = nonInfectedCount + 1
				end
			end
		end
		if nonInfectedCount == 0 then
			everyoneInfected = true
		end
	end
end

local function gameSetup()
	print("setup")
	gameState = {}
	gameState.players = {}
	MP.TriggerClientEvent(-1, "resetInfected", "data")
	local playerCount = 0
	for k,Player in pairs(MP.GetPlayers()) do
		player = {}
		player.infected = false
		player.localContact = false
		player.remoteContact = false
		gameState.players[k] = player
		playerCount = playerCount + 1
		MP.TriggerClientEvent(-1, "addPlayers", tostring(k))
	end
	gameState.playerCount = playerCount
	time = -10
	endtime = -1
	oneInfected = false
	everyoneInfected = false
	gameRunning = true
	gameEnding = false
	--MP.SendChatMessage(-1,"Infection game starting in "..math.abs(time).." second")
end

local function gameEnd(reason)
	gameEnding = true
	local infectedCount = 0
	local nonInfectedCount = 0
	print(reason,"ending")
	if reason == "time" then
		local players = gameState.players
		for k,player in pairs(players) do
			if player.infected then
				infectedCount = infectedCount + 1
			else
				nonInfectedCount = nonInfectedCount + 1
			end
		end
		MP.SendChatMessage(-1,"Game over,"..nonInfectedCount.." survived and "..infectedCount.." got infected")
	elseif reason == "infected" then
		MP.SendChatMessage(-1,"Game over, no survivors")
	elseif reason == "manual" then
		MP.SendChatMessage(-1,"Game stopped,"..nonInfectedCount.." survived and "..infectedCount.." got infected")
		endtime = time + 10
	else
		MP.SendChatMessage(-1,"Game stopped for uknown reason,"..nonInfectedCount.." survived and "..infectedCount.." got infected")
	end
end

local function gameRunningLoop()

	if time < 0 then
		MP.SendChatMessage(-1,"Infection game starting in "..math.abs(time).." second")
	elseif time == 0 then
		MP.SendChatMessage(-1,"Infection game started, you have "..roundLenght.." seconds to survive")
	end

	if time == 5 and not oneInfected then
		local randomID = math.random(1, gameState.playerCount)
		local count = 0
		
		local players = gameState.players
		for k,player in pairs(players) do
			count = count + 1
			if count == randomID then
				gameState.players[k].remoteContact = true
				gameState.players[k].localContact = true
				gameState.players[k].infected = true
				local playername = MP.GetPlayerName(k)
				MP.SendChatMessage(-1,""..playername.." is first infected!")
				MP.TriggerClientEvent(-1, "recieveInfected", tostring(k))
				oneInfected = true
			end
		end 
	end

	local players = gameState.players
	if not players then
		gameEnding = true
		endtime = time + 2
	end

	local infectedCount = 0
	local nonInfectedCount = 0

	if not gameEnding and time > 0 then
		for k,player in pairs(players) do
			if player.localContact and player.remoteContact and not player.infected then
				player.infected = true
				local playername = MP.GetPlayerName(k)
				MP.SendChatMessage(-1,""..playername.." has been infected!")
				infectedCount = infectedCount + 1
				MP.TriggerClientEvent(-1, "recieveInfected", tostring(k))
			else
				nonInfectedCount = nonInfectedCount + 1
			end
		end
	end

	if not gameEnding and time == roundLenght then
		gameEnd("time")
		endtime = time + 10
	elseif not gameEnding and everyoneInfected == true then
		gameEnd("infected")
		endtime = time + 10
	elseif gameEnding and time == endtime then
		gameRunning = false
		MP.TriggerClientEvent(-1, "resetInfected", "data")
		print(gameEnding ,time ,endtime)
	end
	time = time + 1
end

function timer()
	if gameRunning then
		gameRunningLoop()
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
		MP.TriggerClientEvent(sender_id,"active",tostring(true))
		MP.SendChatMessage(sender_id,"enabled for "..playername.."")
		return 1
		
	elseif message == "/outbreak leave" or string.find(message,"/outbreak leave %d+") then
		local number = tonumber(string.sub(message,15,10000))
		local playerid = number or sender_id
		local playername = MP.GetPlayerName(playerid)
		includedPlayers[playerid] = true
		MP.TriggerClientEvent(sender_id,"active",tostring(true))
		MP.SendChatMessage(sender_id,"enabled for "..playername.."")
		return 1
		
	elseif message == "/outbreak start" or string.find(message,"/outbreak start %d+") then
		local number = tonumber(string.sub(message,15,10000))
		if not gameRunning then
			local gameLenght = number or roundLenght
			gameSetup()
		else
			MP.SendChatMessage(sender_id,"gamestart failed, game already running")
		end

		return 1
		
	elseif message == "/outbreak stop" then
		if gameRunning then
			gameEnd("manual")
		else
			MP.SendChatMessage(sender_id,"gamestop failed, game not running")
		end

		return 1

    elseif string.find(message,"/funny type set %d+") then
		local value = tonumber(string.sub(message,17,10000))
		if value then
			explosionType = value
			MP.TriggerClientEvent(-1,"explosionType",tostring(explosionType))
			MP.SendChatMessage(sender_id,"set type to "..value.."")
		else
			MP.SendChatMessage(sender_id,"setting type failed, no value")
		end
		return 1
		
    elseif message == "/outbreak help" then
		--MP.SendChatMessage(sender_id,"/funny enable (ID or blank for yourself)")
		return 1
    else
        return 0
	end
end

MP.RegisterEvent("onChatMessage", "outbreakChatMessageHandler")