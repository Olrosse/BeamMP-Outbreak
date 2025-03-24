require("client/postFx/outbreakVignette")

local M = {}

local vignettePostFX = scenetree.findObject("OutbreakVignettePostFX")

local enabled = false

local function setEnabled(state)
	enabled = state
	vignettePostFX.isEnabled = state
	vignettePostFX.color = Point4F(0, 0.15, 0,1)
end

local function setDistance(distancecolor)
	 vignettePostFX.innerRadius = 1 - math.min(0,distancecolor)
	 vignettePostFX.outerRadius = 2.1 - math.min(0,distancecolor)
end

local function resetVignette()
	vignettePostFX.innerRadius = 0
	vignettePostFX.outerRadius = 0
	vignettePostFX.center = Point2F(0.5, 0.5)
	vignettePostFX.color = Point4F(0, 0.2, 0, 0)
	setEnabled(false)
end

local function setInnerRadius(value)
	vignettePostFX.innerRadius = value or 1
end
local function setOuterRadius(value)
	vignettePostFX.outerRadius = value or 1
end
local function setColor(color)
	vignettePostFX.color = color --Point4F(0, 0.2, 0, 0)
end

local function isEnabled()
	return enabled
end

M.setEnabled = setEnabled
M.isEnabled = isEnabled
M.setDistance = setDistance
M.resetVignette = resetVignette

M.setInnerRadius = setInnerRadius
M.setOuterRadius = setOuterRadius
M.setColor = setColor


M.onInit = function() setExtensionUnloadMode(M, "manual") end

return M