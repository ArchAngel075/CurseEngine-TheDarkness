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
   mode = "walk",
   CurrentAnim = false,
   seeks = false,
   torch_isOn = true,
   charge = 100,
  }
 }
 self.LaS_Data = {}
 local lightWorld = CuCo.NetModule.Client.getLaSWorld()
 
 
 local path = {}
 for i = 1,#self.path-1 do
  path[i] = self.path[i]
 end
 table.insert(path,"UserModelAnim")
 
 local paths = {}
 paths["officer_die_strip"] = "mods/"..table.concat(path,"/").."/officer_die_strip.png"
 paths["officer_headless_strip"] = "mods/"..table.concat(path,"/").."/officer_headless_strip.png"
 paths["officer_hit_strip"] = "mods/"..table.concat(path,"/").."/officer_hit_strip.png"
 paths["officer_shoot_strip"] = "mods/"..table.concat(path,"/").."/officer_shoot_strip.png"
 paths["officer_walk_strip"] = "mods/"..table.concat(path,"/").."/officer_walk_strip.png"
 
 local images = {}
 for k,v in pairs(paths) do
  images[k] = love.graphics.newImage(v)
 end
 self.LaS_Data.anims = {}
  self.LaS_Data.anims["officer_walk_strip"] = newAnimation(images["officer_walk_strip"], 32, 45, 0.15, 0)
  self.LaS_Data.anims["officer_shoot_strip"] = newAnimation(images["officer_shoot_strip"], 38, 45, 0.15, 0)
 
 self.LaS_Data.circle = lightWorld.newCircle(100,100,12)
 self.LaS_Data.circle.setShine(false)
 self.LaS_Data.circle.setGlowColor(0, 255, 255)
 self.LaS_Data.circle.setGlowStrength(4.0)
 self.LaS_Data.circle.setColor(255, 255, 255)
 self.LaS_Data.circle.setAlpha(0.5)
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
 

end

function model:sadismUpdate()
if not CuCo.NetModule.Client.self then return end
  local maxSadism = 4500
  local minSadism = 1
  local sadism = CuCo.NetModule.Client.self.sadism or 20
  --@5 = 2
  --@25 = 14
  --@30 = ?
  --@50 = 
  
  
  
  if CuCo.NetModule.Client.self and CuCo.NetModule.Client.self.keyBuffer["k"] and not CuCo.NetModule.Client.data.LaS.isFade then
   CuCo.NetModule.Client.LaS_objDefaultLight:tintTo(255,0,0,0.2)
   CuCo.NetModule.Client.LaS_objDefaultLight:tintTo(255,255,255,0.1)
  end
  local someValue = math.random(minSadism,maxSadism)
  local lowerSadism = sadism/1.5
  local upperSadism = sadism
  local timeElapsed = love.timer.getTime()-CuCo.NetModule.Client.timeTracker
  -- print("\n\n")
  -- print("time = ["..tostring(timeElapsed):sub(1,(tostring(timeElapsed):find(".",1,#tostring(timeElapsed),true))+3) .."]s")
  -- print("Count :"..CuCo.NetModule.Client.Tracker)
  --if timeElapsed >= 60 then error(CuCo.NetModule.Client.Tracker) end
  --print("Sadism Check :"..someValue.." >= "..lowerSadism .." and "..someValue.." <= "..upperSadism)
  if someValue >= lowerSadism and someValue <= upperSadism then
   --print("SADISM LEVEL :"..someValue)
   CuCo.NetModule.Client.Tracker = CuCo.NetModule.Client.Tracker+1
   local intensity = math.random(1,1+sadism/75)
   local function getDelay()
    math.randomseed(os.clock()+love.timer.getDelta())
    return math.random(0.01,0.05+intensity/50)
   end
   
   
   for i = 1,1+intensity do
    CuCo.NetModule.Client.LaS_objDefaultLight:tintTo(0,0,0,getDelay())
	CuCo.NetModule.Client.LaS_objDefaultLight.fade:delay(getDelay())
    CuCo.NetModule.Client.LaS_objDefaultLight:tintTo(255,255,255,getDelay())
	CuCo.NetModule.Client.LaS_objDefaultLight.fade:delay(getDelay())
   end
   for i = 1,1+math.random(0,intensity-1) do
    CuCo.NetModule.Client.LaS_objDefaultLight:tintTo(0,0,0,getDelay()+0.2)
	CuCo.NetModule.Client.LaS_objDefaultLight.fade:delay(getDelay()+0.8)
    CuCo.NetModule.Client.LaS_objDefaultLight:tintTo(255,255,255,getDelay()+0.1)
	CuCo.NetModule.Client.LaS_objDefaultLight.fade:delay(getDelay()+0.4)
   end
  end
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
 local lightWorld = CuCo.NetModule.Client.data.LaS.lightWorld
 local half = {love.window.getMode()}
 local half = {half[1]/2,half[2]/2}
 
 self.LaS_objDefaultLightOmni = CuCo.NetModule.Client.tintLight:new()
 self.LaS_objDefaultLightOmni.tint = {r=255,g=255,b=255}
 self.LaS_objDefaultLightOmni.isFade = false
 self.LaS_objDefaultLightOmni.light = lightWorld.newLight(half[1], half[2], 255*.95, 255*.95, 255*.95)
  self.LaS_objDefaultLightOmni.light.setRange(115/4.25) --355
  self.LaS_objDefaultLightOmni.light.setGlowStrength(0.005)
  self.LaS_objDefaultLightOmni.light.setGlowSize(0.01)
  self.LaS_objDefaultLightOmni.light.setColor(0,0,0)
 
 self.LaS_objDefaultLight = CuCo.NetModule.Client.tintLight:new()
 self.LaS_objDefaultLight.tint = {r=255,g=255,b=255}
 self.LaS_objDefaultLight.isFade = false
 self.LaS_objDefaultLight.light = lightWorld.newLight(half[1], half[2], 255*.95, 255*.95, 255*.95)
  self.LaS_objDefaultLight.light.setRange(1) --half[1]/2+half[2]/2
  self.LaS_objDefaultLight.light.setRange(half[1]/2.65+half[2]/2.65)
  self.LaS_objDefaultLight.light.setGlowStrength(0)
  self.LaS_objDefaultLight.light.setGlowSize(0)
  self.LaS_objDefaultLight.light.setAngle(math.rad(30)) --85
  self.LaS_objDefaultLight.light.setColor(0,0,0)
 
  self.LaS_objDefaultLight:tintTo(0,0,0,0.001)
  self.LaS_objDefaultLight.fade:delay(0.5)
  self.LaS_objDefaultLight:tintTo(255,255,255,4)
end

function model:destroyLaS()
 self.LaS_Data.circle.clear()
 
 self.LaS_objDefaultLight.fade:stop()
 self.LaS_objDefaultLightOmni.fade:stop()
 
 self.LaS_objDefaultLightOmni.light.clear()
 self.LaS_objDefaultLight.light.clear()
 
 self.LaS_objDefaultLightOmni = nil
 self.LaS_objDefaultLight = nil
 
end

function model:updateDirectLight()
 local DLight = self.LaS_objDefaultLight
 if not DLight then return end
 local vars = self.renderData.vars
 if self.renderData.Owner then
  DLight.light.setDirection((vars.vec3[3]*-1)-math.rad(90))
  local thisClient = CuCo.NetModule.Client.self
  
  local magbehind = -10
  local xcomp = magbehind*math.cos(self.renderData.vars.vec3[3])+self.renderData.vars.vec3[1]
  local ycomp = magbehind*math.sin(self.renderData.vars.vec3[3])+self.renderData.vars.vec3[2]
  
  local renderOffset = thisClient:getRenderOffsetTo(xcomp,ycomp)
  DLight.light.setPosition(renderOffset[1],renderOffset[2])
  
   local half = {love.window.getMode()}
   half = {half[1]/2,half[2]/2}
   local rangeMax = half[1]/2.65+half[2]/2.65
   local range = half[1]/2.65+half[2]/2.65
  
  local percentCharge = vars.charge/100
  range = (range*(percentCharge*1.75))
  if range >= rangeMax then
   range = rangeMax
  end
  local alpha = (255*(percentCharge))
  DLight.light.setRange(range)
  if not vars.torch_isOn then
   self.LaS_objDefaultLight:tintTo(0,0,0,0)
  else
   self.LaS_objDefaultLight:tintTo(alpha,alpha,alpha,0.01)
   
  end
   
  
 end
end

function model:updateOmniLight()
 local omniLight = self.LaS_objDefaultLightOmni
 if not omniLight then return end
 local vars = self.renderData.vars
 if self.renderData.Owner then
  omniLight.light.setDirection(vars.vec3[3])
  local thisClient = CuCo.NetModule.Client.self
  local renderOffset = thisClient:getRenderOffsetTo(self.renderData.vars.vec3[1],self.renderData.vars.vec3[2])
  omniLight.light.setPosition(renderOffset[1],renderOffset[2])
 
 
  if (vars.mode == "walk" or vars.mode == "walk_shoot") and not omniLight.isFade then
   local rgb = Utils.deepcopy(omniLight.tint)
   
   rgb.r = rgb.r+80*3
   rgb.g = rgb.g+80*3
   rgb.b = rgb.b+80*3
   
  local limitValue = 70
  
  for k,v in pairs(rgb) do
   if v > limitValue then v = limitValue end
  end
  
   omniLight:tintTo(rgb.r,rgb.g,rgb.b,0.5)
  elseif not omniLight.isFade then
   omniLight:tintTo(0,0,0,1)
  end
 end
end


function model:updateLight()


end

function model:setLight()



end

function model:animUpdate()
 local thisClient = CuCo.NetModule.Client.self
 local vars = self.renderData.vars
 if vars.mode == "walk" then
  self.renderData.vars.CurrentAnim = self.LaS_Data.anims["officer_walk_strip"]
 end
 if vars.mode == "idle" then
  self.renderData.vars.CurrentAnim = self.LaS_Data.anims["officer_walk_strip"]
  self.renderData.vars.CurrentAnim:seek(1)
 end
 if vars.mode == "walk_shoot" then
  self.renderData.vars.CurrentAnim = self.LaS_Data.anims["officer_shoot_strip"]
 end
 if vars.mode == "idle_shoot" then
  self.renderData.vars.CurrentAnim = self.LaS_Data.anims["officer_shoot_strip"]
  self.renderData.vars.CurrentAnim:seek(1)
 end
 
local dDelay = 0.95
 self.renderData.vars.CurrentAnim:setSpeed(dDelay)
 if self.renderData.Owner == CuCo.NetModule.Client.self and CuCo.NetModule.Client.self.keyBuffer["lshift"] then
  self.renderData.vars.CurrentAnim:setSpeed(1.05)
 end
end

function model:drawAnim()
 
 for k,v in pairs(self.LaS_Data.anims) do
  v:update(love.timer.getDelta())
 end
 
 local thisClient = CuCo.NetModule.Client.self
 local renderOffset = thisClient:getRenderOffsetTo(self.renderData.vars.vec3[1],self.renderData.vars.vec3[2])
 
 local placeoffset = {32/2,45/2}
 local imageOffset = {0,0}
 local drawOffset = {renderOffset[1]+imageOffset[1],renderOffset[2]-imageOffset[2]}
 local rot = self.renderData.vars.vec3[3]
 if self.renderData.vars.CurrentAnim then
  self.renderData.vars.CurrentAnim:draw(drawOffset[1],drawOffset[2],rot,1,1,placeoffset[1],placeoffset[2])
 end
end

function model:draw()
 --local of this clients asset for quick access :
 local thisClient = CuCo.NetModule.Client.self
 local renderOffset = thisClient:getRenderOffsetTo(self.renderData.vars.vec3[1],self.renderData.vars.vec3[2])
 local debugDot = thisClient:getRenderOffsetTo(250,250)
 if self.renderData.Owner == thisClient then
  self.LaS_Data.circle.setShadow(false)
 end
 love.graphics.setColor(0,255,0,255)
 self.LaS_Data.circle.setPosition(renderOffset[1],renderOffset[2])
 love.graphics.setColor(self.renderData.vars.color)
 love.graphics.circle("line",(renderOffset[1]),(renderOffset[2]),18,32)
 love.graphics.setColor(255,255,255,255)
 
 self:animUpdate()
 self:drawAnim()
 self:updateOmniLight()
 self:updateDirectLight()
 love.graphics.setColor(255,255,255,255)
end

function model:drawHUD()
 local thisClient = CuCo.NetModule.Client.self 
 if self.renderData.Owner ~= thisClient then return end
 local scene = CuCo.NetModule.Client.data.OnShadowsScene
 local push = function()
  love.graphics.setColor(255,255,255,255)
  local renderOffset = thisClient:getRenderOffsetTo(self.renderData.vars.vec3[1],self.renderData.vars.vec3[2])
  
  local charged = tostring((self.renderData.vars.charge/100)*100)
  local charged = charged:sub(1,(charged:find(".",1,#charged,true) or 1)+2)
  
  love.graphics.print("Charge:"..charged.."%",1,55)
 end
 scene:pushToDrawLayer("HUD",pushe)
end

function model:drawCover()
 local thisClient = CuCo.NetModule.Client.self
 if self.renderData.Owner == thisClient then -- this Clients userAsset
  
  
  local magbehind = -8
  local xcomp = magbehind*math.cos(self.renderData.vars.vec3[3])+self.renderData.vars.vec3[1]
  local ycomp = magbehind*math.sin(self.renderData.vars.vec3[3])+self.renderData.vars.vec3[2]
  
 
  local renderOffset = thisClient:getRenderOffsetTo(xcomp,ycomp)
  local coverCircleData = {}
  love.graphics.setColor(0,0,0,255)
   local vars = self.renderData.vars
 
  local angleLook = ((vars.vec3[3]*-1)-math.rad(90))
  local angle1 = angleLook -- -(angleLook/2)
  local angle2 = angleLook -- +(angleLook/2)
  local gapWidth = math.rad(115/1.5) -- size of his mouth
  local rot = vars.vec3[3]
  love.graphics.setColor(0,0,0,255)
  love.graphics.arc( "fill", renderOffset[1], renderOffset[2], math.sqrt((1024^2)+(768^2)), gapWidth+rot , (math.pi * 2) - gapWidth+rot )
 end
end

return model