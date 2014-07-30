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
   isMoving = false,
   CurrentAnim = false,
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
 paths["officer_walk_strip"] = "mods/"..table.concat(path,"/").."/officer_walk_strip.png"
 
 local images = {}
 for k,v in pairs(paths) do
  images[k] = love.graphics.newImage(v)
 end
 self.LaS_Data.anims = {}
  self.LaS_Data.anims["officer_walk_strip"] = newAnimation(images["officer_walk_strip"], 32, 45, 0.15, 0)
 
 self.renderData.vars.CurrentAnim = self.LaS_Data.anims["officer_walk_strip"]
 
 self.LaS_Data.circle = lightWorld.newCircle(100,100,12)
 self.LaS_Data.circle.setShine(false)
 self.LaS_Data.circle.setGlowColor(0, 255, 255)
 self.LaS_Data.circle.setGlowStrength(4.0)
 self.LaS_Data.circle.setColor(255, 255, 255)
 self.LaS_Data.circle.setAlpha(0.25)
 self.LaS_Data.circle.setShadow(false)
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

function model:amILite()
 local lightWorld = CuCo.NetModule.Client.data.LaS.lightWorld
 local vars = self.renderData.vars
 if self.renderData.Owner then
  local thisClient = CuCo.NetModule.Client.self
  local renderOffset = thisClient:getRenderOffsetTo(self.renderData.vars.vec3[1],self.renderData.vars.vec3[2])
  
  local pixelData = {lightWorld.shadow:getPixel(renderOffset[1],renderOffset[2])}
  
  local default = 1
  local avg = (pixelData[1]+pixelData[2]+pixelData[3])/3
  avg = avg-(default*(default/3))
  
  local isLite = false
  if avg >= default then
   isLite = true
  end
  --print("Pixel:"..tostring(isLite).."\n"..Utils.gTBL(pixelData).."\n")
  return isLite
 -- 
 end
end

function model:createLaS()
 local lightWorld = CuCo.NetModule.Client.data.LaS.lightWorld
 local half = {love.window.getMode()}
 local half = {half[1]/2,half[2]/2}
end

function model:destroyLaS()
 self.LaS_Data.circle.clear()
end

function model:animUpdate()
 local thisClient = CuCo.NetModule.Client.self
 local vars = self.renderData.vars
 if not vars.isMoving then
  --self.renderData.vars.CurrentAnim = self.LaS_Data.anims["officer_walk_strip"]
  self.renderData.vars.CurrentAnim:seek(1)
 end
 
--local dDelay = 0.95
 --self.renderData.vars.CurrentAnim:setSpeed(dDelay)
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
 love.graphics.setColor(0,255,0,255)
 --love.graphics.circle("fill",(debugDot[1]),(debugDot[2]),8,16)

 self.LaS_Data.circle.setPosition(renderOffset[1],renderOffset[2])
 if self:amILite() then
  love.graphics.setColor(0,255,0,255)
 else
  love.graphics.setColor(255,0,0,255)
 end
 --love.graphics.circle("fill",(renderOffset[1]),(renderOffset[2]),18,32)
 love.graphics.setColor(255,255,255,255)
 
 self:animUpdate()
 self:drawAnim()
 love.graphics.setColor(255,255,255,255)
end

return model