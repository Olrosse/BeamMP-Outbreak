local M = {}

local floor = math.floor
local mod = math.fmod

local gamestate = {players = {}, settings = {}}

local defaultGreenFadeDistance = 20

local function seconds_to_days_hours_minutes_seconds(total_seconds) --modified code from https://stackoverflow.com/questions/45364628/lua-4-script-to-convert-seconds-elapsed-to-days-hours-minutes-seconds
    local time_minutes  = floor(mod(total_seconds, 3600) / 60)
    local time_seconds  = floor(mod(total_seconds, 60))
    --if (time_minutes < 10) then
    --    time_minutes = "0" .. time_minutes
    --end
    if (time_seconds < 10) and time_minutes > 0 then
        time_seconds = "0" .. time_seconds
    end
	if time_minutes > 0 then
    	return time_minutes .. ":" .. time_seconds
	else
    	return time_seconds
	end
end

local function distance(vec1, vec2)
	return math.sqrt((vec2.x-vec1.x)^2 + (vec2.y-vec1.y)^2 + (vec2.z-vec1.z)^2)
end

local function resetInfected(data)
	for k,vehicle in pairs(MPVehicleGE.getVehicles()) do
		local ID = vehicle.gameVehicleID
		if vehicle.originalColor then
			be:getObjectByID(ID).color = vehicle.originalColor
		end
		if vehicle.originalcolorPalette0 then
			be:getObjectByID(ID).colorPalette0 = vehicle.originalcolorPalette0
		end
		if vehicle.originalcolorPalette1 then
			be:getObjectByID(ID).colorPalette1 = vehicle.originalcolorPalette1
		end
	end

	MPVehicleGE.hideNicknames(false)
	scenetree["PostEffectCombinePassObject"]:setField("enableBlueShift", 0,0)
	scenetree["PostEffectCombinePassObject"]:setField("blueShiftColor", 0,"0 0 0")
end

local function recieveGameState(data)
	local data = jsonDecode(data)

	if not gamestate.gameRunning and data.gameRunning then
		for k,vehicle in pairs(MPVehicleGE.getVehicles()) do
			local ID = vehicle.gameVehicleID
			local veh = be:getObjectByID(ID)
			if veh then
				vehicle.originalColor = be:getObjectByID(ID).color
				vehicle.originalcolorPalette0 = be:getObjectByID(ID).colorPalette0
				vehicle.originalcolorPalette1 = be:getObjectByID(ID).colorPalette1
			end
		end
	end
	gamestate = data
end

local function updateGameState(data)
	for variableName,value in pairs(jsonDecode(data)) do
		if variableName == "players" then
			for playerName,PlayerVariables in pairs(value) do
				if type(PlayerVariables) == "table" then
					for playerVariableName,Playervalue in pairs(PlayerVariables) do
						if not gamestate[variableName][playerName] then
							gamestate[variableName][playerName] = {}
						end
						gamestate[variableName][playerName][playerVariableName] = Playervalue
					end
					if PlayerVariables.removed then
						gamestate.players[playerName] = nil
					end
				end
			end
			if value.removed then
				gamestate.players = {}
			end
		elseif variableName == "settings" then
			for settingName,settingVariable in pairs(value) do
				gamestate.settings[settingName] = settingVariable
			end
		else
			gamestate[variableName] = value
		end
	end

	-- In game messages
	local time = 0

	if gamestate.time then time = gamestate.time-1 end

	local txt = ""

	if gamestate.gameRunning and time and time == 0 then
		MPVehicleGE.hideNicknames(true)
	end

	if time and time < 0 then
		txt = "Game starts in "..math.abs(time).." seconds"
	elseif gamestate.gameRunning and not gamestate.gameEnding and time or gamestate.endtime and (gamestate.endtime - time) > 9 then
		local InfectedPlayers = gamestate.InfectedPlayers
		local nonInfectedPlayers = gamestate.nonInfectedPlayers

		local timeLeft = seconds_to_days_hours_minutes_seconds(gamestate.roundLenght - time)
		txt = "Infected "..gamestate.InfectedPlayers.."/"..gamestate.playerCount..", Time Left "..timeLeft..""
	elseif time and gamestate.endtime and (gamestate.endtime - time) < 7 then

		local InfectedPlayers = gamestate.InfectedPlayers
		local nonInfectedPlayers = gamestate.nonInfectedPlayers

		local timeLeft = gamestate.endtime - time
		txt = "Infected "..gamestate.InfectedPlayers.."/"..gamestate.playerCount..", Colors reset in "..math.abs(timeLeft-1).." seconds"

	end
	if txt ~= "" then
		guihooks.message({txt = txt}, 1, "outbreak.time")
	end

	if gamestate.gameEnded then
		resetInfected()
		scenetree["PostEffectCombinePassObject"]:setField("enableBlueShift", 0,0)
	end
end

local function requestGameState()
	TriggerServerEvent("requestGameState","nil")
end

local function sendContact(vehID)
	if not MPVehicleGE or MPCoreNetwork and not MPCoreNetwork.isMPSession() then return end

    local serverVehID = MPVehicleGE.getServerVehicleID(vehID)
	local remotePlayerID, vehicleID = string.match(serverVehID, "(%d+)-(%d+)")
	TriggerServerEvent("onContact", remotePlayerID)
end

local function recieveInfected(data)
	local playerName = data
	local playerServerName = MPConfig:getNickname()
	if playerName == playerServerName then
		MPVehicleGE.hideNicknames(false)
	end
end

local function onVehicleSwitched(oldID,ID)
	local currentVehID = be:getPlayerVehicleID(0)
	local curentOwnerName = MPConfig.getNickname()
	if currentVehID and MPVehicleGE.getVehicleByGameID(currentVehID) then
		curentOwnerName = MPVehicleGE.getVehicleByGameID(currentVehID).ownerName
	end

	if gamestate.players and gamestate.players[curentOwnerName] and gamestate.players[curentOwnerName].infected then
		MPVehicleGE.hideNicknames(false)
	elseif gamestate.players and gamestate.players[curentOwnerName] and not gamestate.players[curentOwnerName].infected then
		MPVehicleGE.hideNicknames(true)
	end
end

local function onPreRender(dt)

	if MPCoreNetwork and not MPCoreNetwork.isMPSession() then return end
	if not gamestate.gameRunning then return end

	local currentVehID = be:getPlayerVehicleID(0)
	local curentOwnerName = MPConfig.getNickname()

	if currentVehID and MPVehicleGE.getVehicleByGameID(currentVehID) then
		curentOwnerName = MPVehicleGE.getVehicleByGameID(currentVehID).ownerName
	end

	local closestInfected = 100000000

	for k,vehicle in pairs(MPVehicleGE.getVehicles()) do

		if gamestate.players then
			local player = gamestate.players[vehicle.ownerName]
			if player then
				if gamestate.players[curentOwnerName] and gamestate.players[curentOwnerName].infected and not player.infected and curentOwnerName ~= vehicle.ownerName then
					local veh = be:getObjectByID(vehicle.gameVehicleID)
					if veh then
						local vehPos = veh:getPosition()
						local posOffset = vec3(0,0,2)
						debugDrawer:drawTextAdvanced(vehPos+posOffset, String(" Survivor "), ColorF(1,1,1,1), true, false, ColorI(200,50,50,255))
					end
				end

				if player.infected then
					if not vehicle.transition or not vehicle.colortimer then
						vehicle.transition = 1
						vehicle.colortimer = 1.6
					end
					local veh = be:getObjectByID(vehicle.gameVehicleID)
					if veh then
						if not vehicle.originalColor then
							vehicle.originalColor = veh.color
						end
						if not vehicle.originalcolorPalette0 then
							vehicle.originalcolorPalette0 = veh.colorPalette0
						end
						if not vehicle.originalcolorPalette1 then
							vehicle.originalcolorPalette1 = veh.colorPalette1
						end

						if not gamestate.gameEnding or (gamestate.endtime - gamestate.time) > 1 then
							local transition = vehicle.transition
							local colortimer = vehicle.colortimer
							local color = 0.6 - (1*((1+math.sin(colortimer))/2)*0.2)
							local colorfade = (1*((1+math.sin(colortimer))/2))*math.max(0.6,transition)
							local greenfade = 1 -((1*((1+math.sin(colortimer))/2))*(math.max(0.6,transition)))
							if gamestate.settings and not gamestate.settings.ColorPulse then
								color = 0.6
								colorfade = transition
								greenfade = 1 - transition
							end
							--dump(k,colorfade,greenfade,transition,colortimer,gamestate.settings)
			
							
							veh.color = ColorF(vehicle.originalColor.x*colorfade,(vehicle.originalColor.y*colorfade) + (color*greenfade), vehicle.originalColor.z*colorfade, vehicle.originalColor.w):asLinear4F()
							veh.colorPalette0 = ColorF(vehicle.originalcolorPalette0.x*colorfade,(vehicle.originalcolorPalette0.y*colorfade) + (color*greenfade), vehicle.originalcolorPalette0.z*colorfade, vehicle.originalcolorPalette0.w):asLinear4F()
							veh.colorPalette1 = ColorF(vehicle.originalcolorPalette1.x*colorfade,(vehicle.originalcolorPalette1.y*colorfade) + (color*greenfade), vehicle.originalcolorPalette1.z*colorfade, vehicle.originalcolorPalette1.w):asLinear4F()
							
							vehicle.colortimer = colortimer + (dt*2.6)
							if transition > 0 then
								vehicle.transition = math.max(0,transition - dt)
							end

							vehicle.color = color
							vehicle.colorfade = colorfade
							vehicle.greenfade = greenfade
						elseif (gamestate.endtime - gamestate.time) <= 1 then
							local transition = vehicle.transition
							local color = vehicle.color or 0
							local colorfade = vehicle.colorfade or 1
							local greenfade = vehicle.greenfade or 0
							--dump(k,colorfade,greenfade,transition,vehicle.colortimer)
							
							veh.color = ColorF(vehicle.originalColor.x*colorfade,(vehicle.originalColor.y*colorfade) + (color*greenfade), vehicle.originalColor.z*colorfade, vehicle.originalColor.w):asLinear4F()
							veh.colorPalette0 = ColorF(vehicle.originalcolorPalette0.x*colorfade,(vehicle.originalcolorPalette0.y*colorfade) + (color*greenfade), vehicle.originalcolorPalette0.z*colorfade, vehicle.originalcolorPalette0.w):asLinear4F()
							veh.colorPalette1 = ColorF(vehicle.originalcolorPalette1.x*colorfade,(vehicle.originalcolorPalette1.y*colorfade) + (color*greenfade), vehicle.originalcolorPalette1.z*colorfade, vehicle.originalcolorPalette1.w):asLinear4F()
							
							vehicle.colorfade = math.min(1,colorfade + dt)
							vehicle.greenfade = math.max(0,greenfade - dt)
							vehicle.colortimer = 1.6
							if transition < 1 then
								vehicle.transition = math.min(1,transition + dt)
							end
						end
					end
				end
				if gamestate.players[curentOwnerName] and currentVehID and not gamestate.players[curentOwnerName].infected and gamestate.players[vehicle.ownerName].infected and currentVehID ~= vehicle.gameVehicleID then
					local myVeh = be:getObjectByID(currentVehID)
					local veh = be:getObjectByID(vehicle.gameVehicleID)
					if veh and myVeh then
						if gamestate.players[vehicle.ownerName].infected then
							local distance = distance(myVeh:getPosition(),veh:getPosition())
							if distance < closestInfected then
								closestInfected = distance
							end
						end
					end
				end
			end
		end
	end
	local tempSetting = defaultGreenFadeDistance
	if gamestate.settings then
		tempSetting = gamestate.settings.GreenFadeDistance
	end
	local distancecolor = math.min(0.4,1 -(closestInfected/(tempSetting or defaultGreenFadeDistance)))
	if gamestate.settings and gamestate.settings.infectorTint and gamestate.players[curentOwnerName] and gamestate.players[curentOwnerName].infected then
		distancecolor = 0.5
	end
	--dump(distancecolor)
	scenetree["PostEffectCombinePassObject"]:setField("enableBlueShift", 0,distancecolor)
	scenetree["PostEffectCombinePassObject"]:setField("blueShiftColor", 0,"0 1 0")
end

local function onExtensionUnloaded()
	resetInfected()
end

if MPGameNetwork then AddEventHandler("recieveInfected", recieveInfected) end
if MPGameNetwork then AddEventHandler("resetInfected", resetInfected) end
if MPGameNetwork then AddEventHandler("recieveGameState", recieveGameState) end
if MPGameNetwork then AddEventHandler("updateGameState", updateGameState) end

M.requestGameState = requestGameState

M.sendContact = sendContact
M.onPreRender = onPreRender
M.onVehicleSwitched = onVehicleSwitched
M.resetInfected = resetInfected
M.onExtensionUnloaded = onExtensionUnloaded

return M