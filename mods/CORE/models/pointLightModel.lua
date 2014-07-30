local model = {
 type="class",
}

function model:new()
 local o = {} -- create a copy of the base data...
 setmetatable(o, self)
 self.__index = self
 return o
end

function model:init()
 self.renderData = {
  Owner = false,
  vars = {
   vec3 = {100,100,0},
   torch_isOn = true,
   charge = 100,
   lightData_color = {255,255,255},
   lightData_alpha = 255,
   lightData_Range = 600,
   lightData_Angle = math.rad(360),
   lightData_Direction = 0,
   
   lightData_GlowUp = 1,
   lightData_GlowDown = 0.5,
   lightData_Glow = 0,
   lightData_GlowState = "up",
   lightData_GlowStrength = 16,
   lightData_GlowSize = 0.5,
   
  }
 }
 self.LaS_Data = {}
 local lightWorld = CuCo.NetModule.Client.getLaSWorld()
 self:createLaS()
end

function model:setVar(varName,value)
 self.renderData.vars[varName] = value
end

function model:setOwner(address)
 if CuCo._RESERVED.MOD_DATABASE_PROXY.BUILD[address] then
  self.renderData.Owner = CuCo._RESERVED.MOD_DATABASE_PROXY.BUILD[address]
 else
  self.renderData.Owner = false
 end
end

function model:getOwner()
 return self.renderData.Owner or false
end

function model:update()
 self:updateDirectLight()
end

function model:amILite()
 local lightWorld = CuCo.NetModule.Client.data.LaS.lightWorld
 local vars = self.renderData.vars
 if self.renderData.Owner then
  local thisClient = CuCo.NetModule.Client.self
  local renderOffset = thisClient:getRenderOffsetTo(self.renderData.vars.vec3[1],self.renderData.vars.vec3[2])
  
  local debugDot = thisClient:getRenderOffsetTo(250,250)
  local pixelData = {lightWorld.shadow:getPixel(debugDot[1],debugDot[2])}
  
  local default = 5
  local avg = (pixelData[1]+pixelData[2]+pixelData[3])/3
  avg = avg-5*15
  
  local isLite = false
  if avg >= 5 then
   isLite = true
  end
  
 -- print("Pixel:"..tostring(isLite).."\n"..Utils.gTBL(pixelData).."\n")
 end
end

function model:createLaS()
--[[
   lightData_color = {255,255,255},
   lightData_alpha = 255,
   lightData_Range = 300,
   lightData_Angle = 360,
   lightData_Direction = 0,
--]]
 local vars = self.renderData.vars
 local lightWorld = CuCo.NetModule.Client.data.LaS.lightWorld
 local half = {love.window.getMode()}
 local half = {half[1]/2,half[2]/2}
 
 self.LaS_objLight = CuCo.NetModule.Client.tintLight:new()
 self.LaS_objLight.tint = {r=255,g=255,b=255}
 self.LaS_objLight.isFade = false
 self.LaS_objLight.light = lightWorld.newLight(half[1], half[2], 255, 255, 255)
  self.LaS_objLight.light.setRange(vars.lightData_Range)
  self.LaS_objLight.light.setGlowStrength(0)
  self.LaS_objLight.light.setGlowSize(0)
  self.LaS_objLight.light.setAngle(vars.lightData_Angle) --85
  self.LaS_objLight.light.setColor(vars.lightData_color[1],vars.lightData_color[2],vars.lightData_color[3])
 
  --self.LaS_objLight:tintTo(0,0,0,0.001)
  --self.LaS_objLight.fade:delay(0.5)
  --self.LaS_objLight:tintTo(vars.lightData_color[1],vars.lightData_color[2],vars.lightData_color[3],4)
end

function model:destroyLaS()
 self.LaS_Data.circle.clear()
 
 self.LaS_objLight.fade:stop()
 
 self.LaS_objLight.light.clear()
 
 self.LaS_objLight = nil
 
end

function model:updateDirectLight()
--[[
   lightData_color = {255,255,255},
   lightData_alpha = 255,
   lightData_Range = 300,
   lightData_Angle = 360,
   lightData_Direction = 0,
   
   lightData_GlowUp = 1,
   lightData_GlowDown = 0.25,
   lightData_Glow = 0,
   lightData_GlowState = "up",
   lightData_GlowStrength = 4,
   lightData_GlowSize = 0.5,
--]]
 local DLight = self.LaS_objLight
 if not DLight then return end
 local vars = self.renderData.vars
 if self.renderData.Owner then
  
  --DLight.light.setDirection(vars.lightData_Direction)
  local thisClient = CuCo.NetModule.Client.self
  --print("Vec3:",vars.vec3[1],vars.vec3[2])
  local renderOffset = thisClient:getRenderOffsetTo(vars.vec3[1],vars.vec3[2])
  DLight.light.setPosition(renderOffset[1],renderOffset[2])
  
  if vars.lightData_GlowState == "up" then
   if vars.lightData_Glow <= vars.lightData_GlowUp then
    vars.lightData_Glow = vars.lightData_Glow+(love.timer.getDelta()*1)
   end
   if vars.lightData_Glow > vars.lightData_GlowUp then
    vars.lightData_GlowState = "down"
	vars.lightData_Glow = vars.lightData_GlowUp
   end
  elseif vars.lightData_GlowState == "down" then
   if vars.lightData_Glow >= vars.lightData_GlowDown then
    vars.lightData_Glow = vars.lightData_Glow-(love.timer.getDelta()*1)
   end
   if vars.lightData_Glow < vars.lightData_GlowDown then
    vars.lightData_GlowState = "up"
	vars.lightData_Glow = vars.lightData_GlowDown
   end
  end
  DLight.light.setGlowStrength(vars.lightData_GlowStrength*vars.lightData_Glow)
  DLight.light.setGlowSize(vars.lightData_GlowSize)
  
   local half = {love.window.getMode()}
   half = {half[1]/2,half[2]/2}
   local rangeMax = vars.lightData_Range
   local range = vars.lightData_Range*vars.lightData_Glow
  
  local percentCharge = vars.charge/100
  range = (range*(percentCharge*1.75))
  if range >= rangeMax then
   range = rangeMax
  end
  local r = (vars.lightData_color[1]*(percentCharge))
  local g = (vars.lightData_color[2]*(percentCharge))
  local b = (vars.lightData_color[3]*(percentCharge))
  --DLight.light.setRange(range)
  --DLight:tintTo(r,g,b,0.01)
 end
end

function model:draw()
 --local of this clients asset for quick access :
 local thisClient = CuCo.NetModule.Client.self
 local renderOffset = thisClient:getRenderOffsetTo(self.renderData.vars.vec3[1],self.renderData.vars.vec3[2])
 love.graphics.setColor(0,0,255,255)
 love.graphics.circle("line",(renderOffset[1]),(renderOffset[2]),4,8)
 love.graphics.setColor(255,255,255,255)
 --self:amILite()
end

return model