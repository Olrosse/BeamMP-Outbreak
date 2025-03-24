local outbreakVignettePostFXCallbacks = {}

outbreakVignettePostFXCallbacks.onAdd = function()
    local outbreakVignettePostFX = scenetree.findObject("OutbreakVignettePostFX")
    if outbreakVignettePostFX then
        outbreakVignettePostFX.innerRadius = 0
        outbreakVignettePostFX.outerRadius = 1
        outbreakVignettePostFX.center = Point2F(0.5, 0.5)
        outbreakVignettePostFX.color = Point4F(0, 0, 0, 0.5)
    end
end

outbreakVignettePostFXCallbacks.setShaderConsts = function()
    local outbreakVignettePostFX = scenetree.findObject("OutbreakVignettePostFX")
    if outbreakVignettePostFX then
        outbreakVignettePostFX:setShaderConst("$innerRadius", outbreakVignettePostFX.innerRadius)
        outbreakVignettePostFX:setShaderConst("$outerRadius", outbreakVignettePostFX.outerRadius)
        local center = outbreakVignettePostFX.center
        outbreakVignettePostFX:setShaderConst("$center", center.x and string.format("%g %g", center.x, center.y) or center)
        local color = outbreakVignettePostFX.color
        outbreakVignettePostFX:setShaderConst("$color", color.x and string.format("%g %g %g %g", color.x, color.y, color.z, color.w) or color)
    end
end
rawset(_G, "OutbreakVignettePostFXCallbacks", outbreakVignettePostFXCallbacks)

local outbreakVignetteShader = scenetree.findObject("OutbreakVignetteShader")
if not outbreakVignetteShader then
    outbreakVignetteShader = createObject("ShaderData")
    outbreakVignetteShader.DXVertexShaderFile = "shaders/common/postFx/outbreakVignette/outbreakVignetteP.hlsl"
    outbreakVignetteShader.DXPixelShaderFile  = "shaders/common/postFx/outbreakVignette/outbreakVignetteP.hlsl"
    outbreakVignetteShader.pixVersion = 5.0
    outbreakVignetteShader:registerObject("OutbreakVignetteShader")
end

local outbreakVignettePostFX = scenetree.findObject("OutbreakVignettePostFX")
if not outbreakVignettePostFX then
    outbreakVignettePostFX = createObject("PostEffect")
    outbreakVignettePostFX.isEnabled = false
    outbreakVignettePostFX.allowReflectPass = false
    outbreakVignettePostFX:setField("renderTime", 0, "PFXBeforeBin")
    outbreakVignettePostFX:setField("renderBin", 0, "AfterPostFX")
    --outbreakVignettePostFX.renderPriority = 9999;

    outbreakVignettePostFX:setField("shader", 0, "OutbreakVignetteShader")
    outbreakVignettePostFX:setField("stateBlock", 0, "PFX_DefaultStateBlock")
    outbreakVignettePostFX:setField("texture", 0, "$backBuffer")

    outbreakVignettePostFX:registerObject("OutbreakVignettePostFX")
end
