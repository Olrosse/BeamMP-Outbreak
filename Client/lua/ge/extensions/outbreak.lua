local M = {}

--local infected = {}
local players = {}

local function getCurrentVehicleID()
	
end

--local function onGameStart()
--end

local function addPlayers(playerID)
	local ID = playerID--tonumber(playerID)
	if not players[ID] then
		players[ID] = {infected = false,colortimer = 1.6,transition = 1}
	end
	
	local playerServerID = MPConfig.getPlayerServerID()
	dump(playerID , playerServerID)
	if tonumber(playerID) == playerServerID then
		MPVehicleGE.hideNicknames(true)
	end
	--dump(playerID,players)
end

local function sendContact(vehID)
	if not MPVehicleGE then return end
    local serverVehID = MPVehicleGE.getServerVehicleID(vehID)
	local remotePlayerID, vehicleID = string.match(serverVehID, "(%d+)-(%d+)")
	TriggerServerEvent("onContact", remotePlayerID)
end

local function recieveInfected(data)
	--dump(data,"recieveInfected")
	local playerID = tonumber(data)

	local playerServerID = MPConfig.getPlayerServerID()
	if playerID == playerServerID then
		MPVehicleGE.hideNicknames(false)
	end

	for k,vehicle in pairs(MPVehicleGE.getVehicles()) do
		--dump(k,vehicle,"loop")
		--dump(vehicle.ownerID,data,"compare")
		if vehicle.ownerID == playerID then
			local ID = vehicle.gameVehicleID
			be:getObjectByID(ID).color = ColorF(0, 0.6, 0, 1):asLinear4F()
		end
	end

	if players[data] then
		players[data].infected = true
	end
end

local colortimer = 1.6

local function resetInfected(data)
	--dump(infected,"infectedtable")
	for k,vehicle in pairs(MPVehicleGE.getVehicles()) do
		--dump(k,vehicle,"loop")
		--dump(vehicle.ownerID,data,"compare")
		if players[tostring(vehicle.ownerID)] and players[tostring(vehicle.ownerID)].infected then
			local ID = vehicle.gameVehicleID
			be:getObjectByID(ID).color = vehicle.originalColor
		end
	end

	for k,vehicle in pairs(MPVehicleGE.getVehicles()) do
		vehicle.originalColor = be:getObjectByID(vehicle.gameVehicleID).color
	end

	colortimer = 1.6

	MPVehicleGE.hideNicknames(false)
	players = {}
end

local function onVehicleSwitched(oldID,ID)
	dump(oldID,ID)

	local currentVehID = be:getPlayerVehicleID(0)
	local curentOwnerID = MPConfig.getPlayerServerID()
	if currentVehID and MPVehicleGE.getVehicleByGameID(currentVehID) then
		curentOwnerID = MPVehicleGE.getVehicleByGameID(currentVehID).ownerID
	end
	
	if players[tostring(curentOwnerID)] and players[tostring(curentOwnerID)].infected then
		MPVehicleGE.hideNicknames(false)
	elseif players[tostring(curentOwnerID)] and not players[tostring(curentOwnerID)].infected then
		MPVehicleGE.hideNicknames(true)
	end
end

local function onPreRender(dt)
	if MPCoreNetwork and not MPCoreNetwork.isMPSession() then return end
	local currentVehID = be:getPlayerVehicleID(0)
	local curentOwnerID = MPConfig.getPlayerServerID()
	if currentVehID and MPVehicleGE.getVehicleByGameID(currentVehID) then
		curentOwnerID = MPVehicleGE.getVehicleByGameID(currentVehID).ownerID
	end
	for k,vehicle in pairs(MPVehicleGE.getVehicles()) do
		local player = players[tostring(vehicle.ownerID)]
		if not player then return end
		if players[tostring(curentOwnerID)] and players[tostring(curentOwnerID)].infected then
			if not players[tostring(vehicle.ownerID)].infected and curentOwnerID ~= vehicle.ownerID then
				local veh = be:getObjectByID(vehicle.gameVehicleID)
				if not veh then return end
				local vehPos = veh:getPosition()
				local posOffset = vec3(0,0,2)
				debugDrawer:drawTextAdvanced(vehPos+posOffset, String(" Survivor "), ColorF(1,1,1,1), true, false, ColorI(200,50,50,255))
			end
		end
		if player.infected then
			transition = player.transition
			colortimer = player.colortimer
			local color = 0.6 - (1*((1+math.sin(colortimer))/2)*0.2)
			local colorfade = (1*((1+math.sin(colortimer))/2))*transition
			local greenfade = 1 -((1*((1+math.sin(colortimer))/2))*transition)
			local veh = be:getObjectByID(vehicle.gameVehicleID)
			--dump(colortimer,colorfade,greenfade,transition)
			veh.color = ColorF(vehicle.originalColor.x*colorfade,(vehicle.originalColor.y*colorfade) + (color*greenfade), vehicle.originalColor.z*colorfade, vehicle.originalColor.w):asLinear4F()
			player.colortimer = colortimer + (dt*1.6)
			if transition > 0.6 then
				player.transition = transition - dt
			end
		end
	end
end

if MPGameNetwork then AddEventHandler("recieveInfected", recieveInfected) end
if MPGameNetwork then AddEventHandler("resetInfected", resetInfected) end
if MPGameNetwork then AddEventHandler("addPlayers", addPlayers) end

M.sendContact = sendContact
M.onPreRender = onPreRender
M.infected = infected
M.onVehicleSwitched = onVehicleSwitched

return M