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
   lifeTimeExceed = 0,
   lifeTime = 1.5,
   Time = 1,
  }
 }
 self.LaS_Data = {}
 local lightWorld = CuCo.NetModule.Client.getLaSWorld()
 self.LaS_Data.circle = lightWorld.newCircle(100,100,4)
 self.LaS_Data.circle.setShine(true)
 self.LaS_Data.circle.setGlowColor(255, 255, 255)
 self.LaS_Data.circle.setGlowStrength(2.0)
 self.LaS_Data.circle.setColor(255, 255, 255)
 self.LaS_Data.circle.setAlpha(0.25)
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

function model:getRenderData()
 return self.renderData
end

function model:destroyLaS()
 self.LaS_Data.circle.clear()
end

function model:draw()
 local thisClient = CuCo.NetModule.Client.self
 local vars = self.renderData.vars
 local vec3 = vars.vec3 
 local nOffset = thisClient:getRenderOffsetTo(vec3[1],vec3[2])
 
 --LAS stufies
 local percentage = ((vars.lifeTimeExceed/vars.Time))
 local glowTotal = percentage*(4.0)
 self.LaS_Data.circle.setGlowColor(255*percentage, 255*percentage, 255*percentage)
 self.LaS_Data.circle.setGlowStrength(glowTotal)
 --self.LaS_Data.circle.setColor(15*percentage, 255*percentage, 15*percentage)
 
 
  self.LaS_Data.circle.setPosition(nOffset[1],nOffset[2])
 
 ----
 

 love.graphics.circle("fill",nOffset[1],nOffset[2],4,16)
 love.graphics.setLineWidth(1)
 love.graphics.circle("line",nOffset[1],nOffset[2],6,16)
 love.graphics.setLineWidth(1)
end

return model

