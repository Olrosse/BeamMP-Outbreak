
local M = {}
local floor = math.floor
local mod = math.fmod

local gamestate = {players = {}, settings = {}}

local defaultGreenFadeDistance = 20

--extensions.unload("outbreak") extensions.load("outbreak") extensions.reload("outbreak")

local blockedActions = {"dropPlayerAtCamera", "dropPlayerAtCameraNoReset", "recover_vehicle", "recover_vehicle_alt", "recover_to_last_road", "reload_vehicle", "reload_all_vehicles", "loadHome", "saveHome", "reset_all_physics" ,"reset_physics"}

local function getStat(name)
	return gameplay_statistic.metricGet(name) and gameplay_statistic.metricGet(name).value or 0
end

local function setNewMaxStat(name, value)
	local stat = getStat(name)
	if value > stat then gameplay_statistic.metricSet(name, value) end
end

local function seconds_to_days_hours_minutes_seconds(total_seconds) --modified code from https://stackoverflow.com/questions/45364628/lua-4-script-to-convert-seconds-elapsed-to-days-hours-minutes-seconds
	if not total_seconds then return end
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

local function gameStarting(time)
	local days, hours , minutes , seconds = seconds_to_days_hours_minutes_seconds(time)
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

	return days, hours , minutes , seconds
end

local function distance(vec1, vec2)
	return math.sqrt((vec2.x-vec1.x)^2 + (vec2.y-vec1.y)^2 + (vec2.z-vec1.z)^2)
end

local function resetInfected()
	for k,serverVehicle in pairs(MPVehicleGE.getVehicles()) do
		local ID = serverVehicle.gameVehicleID
		local vehicle = be:getObjectByID(ID)
		if vehicle then
			if serverVehicle.originalColor then
				vehicle.color = serverVehicle.originalColor
			end
			if serverVehicle.originalcolorPalette0 then
				vehicle.colorPalette0 = serverVehicle.originalcolorPalette0
			end
			if serverVehicle.originalcolorPalette1 then
				vehicle.colorPalette1 = serverVehicle.originalcolorPalette1
			end
		end
	end

	MPVehicleGE.hideNicknames(false)

	if vignetteShaderAPI then
		vignetteShaderAPI.resetVignette()
	end
	scenetree["PostEffectCombinePassObject"]:setField("enableBlueShift", 0,0)
	scenetree["PostEffectCombinePassObject"]:setField("blueShiftColor", 0,"0 0 0")


	--core_input_actionFilter.addAction(0, 'vehicleTeleporting', false)
	--core_input_actionFilter.addAction(0, 'vehicleMenues', false)
	--core_input_actionFilter.addAction(0, 'freeCam', false)
	--core_input_actionFilter.addAction(0, 'resetPhysics', false)
end

local function recieveGameState(data)
	local data = jsonDecode(data)
	gamestate = data
	M.gamestate = gamestate
	
	gamestate.vehiclesOwners = {}
	for k,vehicle in pairs(MPVehicleGE.getVehicles()) do
		local ID = vehicle.gameVehicleID
		local veh = be:getObjectByID(ID)
		if veh then
			gamestate.vehiclesOwners[ID] = vehicle.ownerName
		end
	end
	gamestate = data
	be:queueAllObjectLua("if outbreak then outbreak.setGameState("..serialize(gamestate)..") end")
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

	mergeTable(jsonDecode(data),gamestate)
	be:queueAllObjectLua("if outbreak then outbreak.setGameState("..serialize(gamestate)..") end")

	-- In game messages
	local time = 0

	if gamestate.time then time = gamestate.time-1 end

	local txt = ""
	
	if gamestate.gameRunning and time and time == -4 then
		if TriggerServerEvent then 
			TriggerServerEvent("outbreak_clientReady","nil")
		end
	end

	if gamestate.gameRunning and time and time == 0 then
		MPVehicleGE.hideNicknames(true)

		--if gamestate.settings and gamestate.settings.mode = "competitive" then
		--	core_input_actionFilter.setGroup('vehicleTeleporting', actionTemplate.vehicleTeleporting)
		--	core_input_actionFilter.addAction(0, 'vehicleTeleporting', true)

			--core_input_actionFilter.setGroup('vehicleMenues', actionTemplate.vehicleMenues)
			--core_input_actionFilter.addAction(0, 'vehicleMenues', true)

			--core_input_actionFilter.setGroup('freeCam', actionTemplate.freeCam)
			--core_input_actionFilter.addAction(0, 'freeCam', true)

		--	core_input_actionFilter.setGroup('resetPhysics', actionTemplate.resetPhysics)
		--	core_input_actionFilter.addAction(0, 'resetPhysics', true)
		--end
	end

	if time and time < 0 then
		txt = "Game starts in "..math.abs(time).." seconds"
		if vignetteShaderAPI and not vignetteShaderAPI.isEnabled() then
			vignetteShaderAPI.setEnabled(true)
		end
	elseif gamestate.gameRunning and not gamestate.gameEnding and time or gamestate.endtime and (gamestate.endtime - time) > 9 then

		local days, hours , minutes , seconds = seconds_to_days_hours_minutes_seconds(gamestate.roundLength - time)
		local amount = 0
		if days then
			amount = amount + 1
			if not hours then
				hours = 0
			end
		end
		if hours then
			amount = amount + 1
			if not minutes then
				minutes = 0
			end
		end
		if minutes then
			amount = amount + 1
			if not seconds then
				seconds = 0
			end
		end
		if seconds then
			amount = amount + 1
		end

		if days then
			if amount > 0 then
				days = ""..days.."."
			end
		end

		if hours then
			amount = amount - 1
			if amount > 0 then
				if days and hours < 10 then
					hours = "0"..hours..""
				end
				hours = ""..hours..":"
			end
		end

		if minutes then
			amount = amount - 1
			if amount > 0 then
				if hours and minutes < 10 then
					minutes = "0"..minutes..""
				end
				minutes = ""..minutes..":"
			end
		end

		if seconds and minutes then
			if seconds < 10 then
				seconds = "0"..seconds..""
			end
		end

		txt = "Infected "..gamestate.InfectedPlayers.."/"..gamestate.playerCount..", Time Left "..(days or "")..""..(hours or "")..""..(minutes or "")..""..(seconds or "")..""

	elseif time and gamestate.endtime and (gamestate.endtime - time) < 7 then

		for player, data in pairs(gamestate.players) do
			local txt = "Stats for "..player..""
			local stats = data.stats
			local skipPlayer = true
			if stats.survivedTime then
				local days, hours , minutes , seconds = gameStarting(stats.survivedTime)
				txt = ""..txt.."\n	Time Survived : "..(days or "")..""..(hours or "")..""..(minutes or "")..""..(seconds or "")..""
				skipPlayer = false
			end

			if data.firstInfected then
				txt = ""..txt.."\n Was first infected"
				skipPlayer = false
			end

			if stats.infecter then
				txt = ""..txt.."\n Was infected by : "..stats.infecter..""
				skipPlayer = false
			end

			if stats.infected then
				if stats.infected == 1 then
					txt = ""..txt.."\n Has infected : "..stats.infected.." Player"
				skipPlayer = false
				elseif stats.infected ~= 0 then
					txt = ""..txt.."\n Has infected : "..stats.infected.." Players"
				skipPlayer = false
				end
			end
			if not skipPlayer then
				guihooks.message({txt = txt}, 30, "outbreak."..player.."")
			end
		end

		local timeLeft = gamestate.endtime - time
		txt = "Infected "..gamestate.InfectedPlayers.."/"..gamestate.playerCount..", Colors reset in "..math.abs(timeLeft-1).." seconds"

	end
	if txt ~= "" then
		guihooks.message({txt = txt}, 1, "outbreak.time")
	end
	--\n
	if gamestate.gameEnded then
		local yourName = MPConfig.getNickname()
		for playerName, playerData in pairs(gamestate.players) do
			local stats = playerData.stats
			if stats then
				if playerName == yourName then
					gameplay_statistic.metricAdd("Infection/GamesPlayed", 1)
					if stats.infected and stats.infected > 0 then
						gameplay_statistic.metricAdd("Infection/TotalInfections", stats.infected)
						setNewMaxStat("Infection/MostInfectionsInOneGame", stats.infected)
					end
					if stats.survivedTime and stats.survivedTime > 0 then
						gameplay_statistic.metricAdd("Infection/TotalTimeSurvived.time", stats.survivedTime)
						setNewMaxStat("Infection/LongestTimeSurvived.time", stats.survivedTime)
					end
					if playerData.infecter then
						gameplay_statistic.metricAdd("Infection/InfectedBy/"..playerData.infecter.."", 1)
					end
					if playerData.firstInfected then
						gameplay_statistic.metricAdd("Infection/firstInfected", 1)
					end
				else
					if playerData.infecter == yourName then
						gameplay_statistic.metricAdd("Infection/InfectedOthers/"..playerName.."", 1)
					end
					gameplay_statistic.metricAdd("Infection/TimesPlayedWith/"..playerName.."", 1)
				end
			end
		end
		resetInfected()
	end
end

local function requestGameState()
	if TriggerServerEvent then TriggerServerEvent("outbreak_requestGameState","nil") end
end

local function sendContact(vehID,localVehID)
	if not MPVehicleGE or MPCoreNetwork and not MPCoreNetwork.isMPSession() then return end
	if not gamestate.gameRunning then return end -- temp fix for console spam when a game hasn't been ran yet
	if not MPVehicleGE.isOwn(localVehID) then return end

	local LocalvehPlayerName = MPVehicleGE.getNicknameMap()[localVehID]
	local vehPlayerName = MPVehicleGE.getNicknameMap()[vehID]
	if gamestate and gamestate.gameRunning then
		if gamestate.players[vehPlayerName] and gamestate.players[LocalvehPlayerName] then
			if gamestate.players[vehPlayerName].infected ~= gamestate.players[LocalvehPlayerName].infected and not gamestate.players[vehPlayerName].contacted then
				gamestate.players[vehPlayerName].contacted = true
				local serverVehID = MPVehicleGE.getServerVehicleID(vehID)
				local remotePlayerID, vehicleID = string.match(serverVehID, "(%d+)-(%d+)")
				if TriggerServerEvent then TriggerServerEvent("onContact", remotePlayerID) end
			end
		end
	end
end

local function recieveInfected(data)
	local playerName = data
	local playerServerName = MPConfig:getNickname()
	if playerName == playerServerName then
		MPVehicleGE.hideNicknames(false)
	end
end

local function onVehicleSwitched(oldID,ID)
	if not gamestate.gameRunning then return end
	local curentOwnerName = MPConfig.getNickname()
	if ID and MPVehicleGE.getVehicleByGameID(ID) then
		curentOwnerName = MPVehicleGE.getVehicleByGameID(ID).ownerName
	end

	if gamestate.players and gamestate.players[curentOwnerName] and gamestate.players[curentOwnerName].infected then
		MPVehicleGE.hideNicknames(false)
	elseif gamestate.players and gamestate.players[curentOwnerName] and not gamestate.players[curentOwnerName].infected then
		MPVehicleGE.hideNicknames(true)
	end
end

local function onVehicleSpawned(VehicleID)
	local veh = be:getObjectByID(VehicleID)
	if veh then
		local vehicle = MPVehicleGE.getVehicleByGameID(VehicleID)
		if vehicle then
			vehicle.originalColor = veh.color
			vehicle.originalcolorPalette0 = veh.colorPalette0
			vehicle.originalcolorPalette1 = veh.colorPalette1
		end
		veh:queueLuaCommand("if outbreak then outbreak.setGameState("..serialize(gamestate)..") end")
	end
end

local distancecolor = -1

local function nametags(curentOwnerName,player,vehicle)
	if gamestate.players[curentOwnerName] and gamestate.players[curentOwnerName].infected and not player.infected and curentOwnerName ~= vehicle.ownerName then
		local vehPos = vec3(be:getObjectOOBBCenterXYZ(vehicle.gameVehicleID))
		vehPos.z = vehPos.z + (vehicle.vehicleHeight * 0.5) + 0.2
		debugDrawer:drawTextAdvanced(vehPos, String(" Survivor "), ColorF(1,1,1,1), true, false, ColorI(200,50,50,255))
	end
end

local function color(player,vehicle,dt)
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
end

local fade = 0
local lastVehPos = vec3()
local moveTimer = 0

local function checkForMovement(currentVehID,currentVeh,dt)
	local vehPos = vec3(be:getObjectOOBBCenterXYZ(currentVehID))
	local vehVel = currentVeh:getVelocity()
	if distance(vehPos,lastVehPos) > 1 then
		moveTimer = 5
		lastVehPos = vehPos
	else
		moveTimer = math.max(0,moveTimer - dt)
	end
	if vehVel:length() < (gamestate.settings.maxResetMovingSpeed or 2) or moveTimer < 0 then
		core_input_actionFilter.setGroup('noResetsInfection', blockedActions)
		core_input_actionFilter.addAction(0, 'noResetsInfection', false)
	else
		core_input_actionFilter.setGroup('noResetsInfection', blockedActions)
		core_input_actionFilter.addAction(0, 'noResetsInfection', true)
	end
end

local function onPreRender(dt)
	if MPCoreNetwork and not MPCoreNetwork.isMPSession() then return end
	if not gamestate.gameRunning then return end

	local currentVehID = be:getPlayerVehicleID(0)
	local currentVeh = be:getObjectByID(currentVehID)
	local curentOwnerName = MPConfig.getNickname()

	if currentVehID and MPVehicleGE.getVehicleByGameID(currentVehID) then
		curentOwnerName = MPVehicleGE.getVehicleByGameID(currentVehID).ownerName
	end

	if gamestate.settings and gamestate.settings.disableResetsWhenMoving then
		if MPVehicleGE.isOwn(currentVehID) then
			checkForMovement(currentVehID,currentVeh,dt)
		end
	end

	local closestInfected = 100000000
	--local infectedClose = false

	for k,vehicle in pairs(MPVehicleGE.getVehicles()) do
		if gamestate.players then
			local player = gamestate.players[vehicle.ownerName]
			if player then
				nametags(curentOwnerName,player,vehicle)
				color(player,vehicle,dt)
				if gamestate.players[curentOwnerName] and currentVehID and not gamestate.players[curentOwnerName].infected and gamestate.players[vehicle.ownerName].infected and currentVehID ~= vehicle.gameVehicleID then
					local veh = be:getObjectByID(vehicle.gameVehicleID)
					if veh and currentVeh then
						if gamestate.players[vehicle.ownerName].infected then
							local distance = distance(currentVeh:getPosition(),veh:getPosition())
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
	distancecolor = math.min(1,1 -(closestInfected/(tempSetting or defaultGreenFadeDistance)))

	--if distancecolor > 0 then
	--	core_input_actionFilter.setGroup('vehicleTeleporting', actionTemplate.vehicleTeleporting)
	--	core_input_actionFilter.addAction(0, 'vehicleTeleporting', true)

	--	core_input_actionFilter.setGroup('resetPhysics', actionTemplate.resetPhysics)
	--	core_input_actionFilter.addAction(0, 'resetPhysics', true)
	--else
	--	core_input_actionFilter.addAction(0, 'vehicleTeleporting', false)
	---	core_input_actionFilter.addAction(0, 'resetPhysics', false)
	--end

	if vignetteShaderAPI then
		vignetteShaderAPI.setColor(Point4F(0, 0.12, 0,1))
	end
	if gamestate.settings and gamestate.settings.infectorTint and gamestate.players[curentOwnerName] and gamestate.players[curentOwnerName].infected then
		distancecolor = gamestate.settings.distancecolor or 0
		if vignetteShaderAPI then
			distancecolor = distancecolor + 0.2
			vignetteShaderAPI.setColor(Point4F(0, 0.15, 0,1))
		end
	end

	if (gamestate.time -gamestate.endtime) > 6 then
		fade = math.min(1,fade + dt)
	elseif not gamestate.gameEnding or (gamestate.endtime - gamestate.time) > 1 then
		fade = math.max(0,fade - dt)
	end

	if vignetteShaderAPI then
		if not vignetteShaderAPI.isEnabled() then
			vignetteShaderAPI.setEnabled(true)
		end
		vignetteShaderAPI.setInnerRadius((0.8 - math.max(0,distancecolor*fade)))
		vignetteShaderAPI.setOuterRadius((1.8 - math.max(0,distancecolor*fade))) --math.max(0,1 -(distancecolor*2))
	else
		scenetree["PostEffectCombinePassObject"]:setField("enableBlueShift", 0,distancecolor*0.7*fade)
		scenetree["PostEffectCombinePassObject"]:setField("blueShiftColor", 0,"0 1 0")
	end
end

local function onVehicleColorChanged(vehID,index,paint)
	local vehicle = MPVehicleGE.getVehicleByGameID(vehID)
	if vehicle then
		if index == 1 then
			vehicle.originalColor = ColorF(paint.baseColor[1],paint.baseColor[2],paint.baseColor[3],paint.baseColor[4]):asLinear4F()
		elseif index == 2 then
			vehicle.originalcolorPalette0 = ColorF(paint.baseColor[1],paint.baseColor[2],paint.baseColor[3],paint.baseColor[4]):asLinear4F()
		elseif index == 3 then
			vehicle.originalcolorPalette1 = ColorF(paint.baseColor[1],paint.baseColor[2],paint.baseColor[3],paint.baseColor[4]):asLinear4F()
		end
	end
end

local function onExtensionUnloaded()
	resetInfected()
end

if MPGameNetwork then AddEventHandler("outbreak_recieveInfected", recieveInfected) end
if MPGameNetwork then AddEventHandler("outbreak_resetInfected", resetInfected) end
if MPGameNetwork then AddEventHandler("outbreak_recieveGameState", recieveGameState) end
if MPGameNetwork then AddEventHandler("outbreak_updateGameState", updateGameState) end

requestGameState()

M.requestGameState = requestGameState
M.sendContact = sendContact
M.onPreRender = onPreRender
M.onVehicleSwitched = onVehicleSwitched
M.resetInfected = resetInfected
M.onExtensionUnloaded = onExtensionUnloaded
M.onResetGameplay = onResetGameplay
M.onVehicleSpawned = onVehicleSpawned
M.onVehicleColorChanged = onVehicleColorChanged
M.gamestate = gamestate


M.onInit = function() setExtensionUnloadMode(M, "manual") end

return M