local M = {}

local drawDebug = obj.debugDrawProxy

local positionoffset = v.data.nodes[v.data.refNodes[0].ref].pos

local abs = math.abs
local sqrt = math.sqrt
local min = math.min
local max = math.max
local vehicleID = obj:getId()
local carWidth = obj:getInitialWidth()
local carLength = obj:getInitialLength()
local carHeight = obj:getInitialHeight()
local vehiclerotation = quat(obj:getRotation())
local vehiclePosition = obj:getPosition() - (positionoffset:rotated(vehiclerotation))

local mapObjects = mapmgr.getObjects()
local vehiclemap = {}

local function distance(vec1, vec2)
	return sqrt((vec2.x-vec1.x)^2 + (vec2.y-vec1.y)^2 + (vec2.z-vec1.z)^2)
end

local function getCenterOfNodes()
	local front = 0
	local rear = 0
	local left = 0
	local right = 0
	local top = 0
	local bottom = 0
	for k,v in pairs(v.data.nodes) do
		if v.pos.y < front then
			front = v.pos.y
		end
		if v.pos.y > rear then
			rear = v.pos.y
		end
		if v.pos.x < left then
			left = v.pos.x
		end
		if v.pos.x > right then
			right = v.pos.x
		end
		if v.pos.z > top then
			top = v.pos.z
		end
		if v.pos.z < bottom then
			bottom = v.pos.z
		end
	end
	return vec3((left+right)/2,(front+rear)/2,(top+bottom)/2)
end

local carCenter = positionoffset-getCenterOfNodes()

local function getPosOffset(id)
	local data = {}
	data.offset = carCenter
	data.carWidth = obj:getInitialWidth()
	data.carLength = obj:getInitialLength()
	data.carHeight = obj:getInitialHeight()
	obj:queueObjectLuaCommand(id, "if contactdetection then contactdetection.setPosOffset(" .. tostring(vehicleID) .. ", " .. serialize(data) .. ") end")
end

local function setPosOffset(id,data)
	if not vehiclemap[id] then
		vehiclemap[id] = {}
	end
	vehiclemap[id] = data
end

local function sendData(data)

end

local function updateGFX(dt)

	if carWidth == 0 then
		carWidth = obj:getInitialWidth()
		carLength = obj:getInitialLength()
		carHeight = obj:getInitialHeight()
	end

	if v.mpVehicleType == "R" then return end
	
    local vehicles = mapmgr.getObjects()
	
	local localVehData = vehicles[vehicleID]
	if not localVehData then return end

	local offset = carCenter
	local dirVec = localVehData.dirVec
	local dirVecUp = localVehData.dirVecUp

	vehiclerotation = quatFromDir(dirVec*-1,dirVecUp)
	vehiclePosition = vehicles[vehicleID].pos - ((carCenter):rotated(vehiclerotation))

	local detectcolor = color(255,0,0,200)

	if next(mapmgr.objectCollisionIds) then
		local contact = 0
		for _,vehID in pairs(mapmgr.objectCollisionIds) do
			if vehiclemap[vehID] then
				local vehData = vehicles[vehID]
				if vehData then
					local offset = vehiclemap[vehID].offset
					local dirVec = vehData.dirVec
					local dirVecUp = vehData.dirVecUp
					local rot = quatFromDir(dirVec*-1,dirVecUp)
					local pos = vehData.pos - offset:rotated(rot)

					local distance = distance(vehiclePosition, pos)
					if distance < ((vehiclemap[vehID].carLength+carLength)/2)*1.01 then
						detectcolor = color(0,255,0,200)
						--outbreak.sendContact(323899)
						vehiclemap[vehID].ColState = true
					end
				end
			else
				obj:queueObjectLuaCommand(vehID,"if contactdetection then contactdetection.getPosOffset(" .. tostring(vehicleID) .. ") end")
			end
		end
	end

	for ID,vehData in pairs(vehiclemap) do -- TODO: make a proper hit detection that doesn't send duplicates
		--dump(vehData.lastColState, vehData.ColState)
		if not vehData.lastColState and vehData.ColState then
			obj:queueGameEngineLua("if outbreak then outbreak.sendContact(" .. tostring(ID) .. ","..tostring(vehicleID)..") end")
			--dump("collision")
		end

		vehData.lastColState = vehData.ColState
		vehData.ColState = false
	end
	--local detectcolor = color(0,255,0,200)

   --drawDebug:drawSphere(0.1 , obj:getPosition(), color(0,255,0,200))
   --drawDebug:drawSphere(0.1 , obj:getPosition() - (carCenter):rotated(quat(obj:getRotation())), detectcolor)
   --drawDebug:drawSphere(0.1 , obj:getPosition() - (vec3(carCenter.x,carCenter.y+(carLength/2),carCenter.z)):rotated(quat(obj:getRotation())), detectcolor)
   --drawDebug:drawSphere(0.1 , obj:getPosition() - (vec3(carCenter.x,carCenter.y-(carLength/2),carCenter.z)):rotated(quat(obj:getRotation())), detectcolor)

   --drawDebug:drawSphere(0.1 , obj:getPosition() - (vec3(carCenter.x,carCenter.y,carCenter.z+(carHeight/2))):rotated(quat(obj:getRotation())), detectcolor)
   --drawDebug:drawSphere(0.1 , obj:getPosition() - (vec3(carCenter.x,carCenter.y,carCenter.z-(carHeight/2))):rotated(quat(obj:getRotation())), detectcolor)
   --
   --drawDebug:drawSphere(0.1 , obj:getPosition() - (vec3(carCenter.x+(carWidth/2),carCenter.y,carCenter.z)):rotated(quat(obj:getRotation())), detectcolor)
   --drawDebug:drawSphere(0.1 , obj:getPosition() - (vec3(carCenter.x-(carWidth/2),carCenter.y,carCenter.z)):rotated(quat(obj:getRotation())), detectcolor)
    --dump(obj:getPosition() - (positionoffset-carCenter):rotated(quat(obj:getRotation())))
end

M.setPosOffset = setPosOffset
M.getPosOffset = getPosOffset
M.updateGFX = updateGFX

return M