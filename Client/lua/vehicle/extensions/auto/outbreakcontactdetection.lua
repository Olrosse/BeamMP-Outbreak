local M = {}

local vehicleID = obj:getId()
local carLength = obj:getInitialLength()
local vehiclePosition = obj:getCenterPosition()

--[[
local drawDebug = obj.debugDrawProxy
local carHeight = obj:getInitialHeight()
local carWidth = obj:getInitialWidth()

local vehRot = quat()

local function collisionDebugDraw(vehID, isColliding)
	local detectColor = color(255,0,0,200)
	if isColliding then
		detectColor = color(0,255,0,200)
	end

	local vehPos = obj:getObjectCenterPosition(vehID)
	local vehWidth = obj:getObjectInitialWidth(vehID)
	local vehLength = obj:getObjectInitialLength(vehID)
	local vehHeight = obj:getObjectInitialHeight(vehID)
	local dir = obj:getObjectDirectionVector(vehID)
	local dirUp = obj:getObjectDirectionVectorUp(vehID)
	vehRot:setFromDir(dir,dirUp)

	drawDebug:drawSphere(0.1 , vehPos, color(0,255,0,200))
	drawDebug:drawSphere(0.1 , vehPos - (vec3((vehWidth/2),0,0)):rotated(vehRot),  detectColor)
	drawDebug:drawSphere(0.1 , vehPos - (vec3(-(vehWidth/2),0,0)):rotated(vehRot), detectColor)
	drawDebug:drawSphere(0.1 , vehPos - (vec3(0,(vehLength/2),0)):rotated(vehRot), detectColor)
	drawDebug:drawSphere(0.1 , vehPos - (vec3(0,-(vehLength/2),0)):rotated(vehRot),detectColor)
	drawDebug:drawSphere(0.1 , vehPos - (vec3(0,0,(vehHeight/2))):rotated(vehRot), detectColor)
	drawDebug:drawSphere(0.1 , vehPos - (vec3(0,0,-(vehHeight/2))):rotated(vehRot),detectColor)
end --]]

local function checkForCollisions()
	--if not outbreak then return end
	--if outbreak.gamestate and not outbreak.gamestate.gameRunning then return end
	if carLength == 0 then
		--carWidth = obj:getInitialWidth()
		carLength = obj:getInitialLength()
		--carHeight = obj:getInitialHeight()
	end
	if v.mpVehicleType == "R" then return end

	--local isColliding = false
	if next(mapmgr.objectCollisionIds) ~= nil then
		vehiclePosition:set(obj:getCenterPosition())
		for _,vehID in pairs(mapmgr.objectCollisionIds) do
			local distance = vehiclePosition:distance(obj:getObjectCenterPosition(vehID))
			if distance < ((obj:getObjectInitialLength(vehID)+carLength)/2)*1.1 then
				obj:queueGameEngineLua("if outbreak then outbreak.sendContact("..vehID..","..vehicleID..") end")
				--isColliding = true
				--collisionDebugDraw(vehID,isColliding)
			end
		end
	end
	--collisionDebugDraw(vehicleID,isColliding)
end

--local veh = getObjectByID(55207) local vel = veh:getVelocity() veh:applyClusterVelocityScaleAdd(veh:getRefNodeId(), -1, vel.x, vel.y, vel.z) veh:setPosition(vec3(0,0,0))

M.checkForCollisions = checkForCollisions

return M