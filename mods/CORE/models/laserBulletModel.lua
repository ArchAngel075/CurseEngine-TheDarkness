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
   vec3_start = {100,100,0},
   vec3_end = {100,100,0},
   minWidth = 1,
   maxWidth = 8.25,
   incWidth = 1,
   growthStage = true,
   width = 1.25,
   percentLong = 0,
  }
 }
 self.LaS_Data = {}
 local lightWorld = CuCo.NetModule.Client.getLaSWorld()
 self.LaS_Data.polygon = lightWorld.newPolygon(-999,-999,-999,-999,-999,-999)
 self.LaS_Data.polygon.setGlowColor(0, 255, 255)
 self.LaS_Data.polygon.setGlowStrength(64.0)
 self.LaS_Data.polygon.setColor(255-115, 255, 255)
 self.LaS_Data.polygon.setAlpha(255)
 self.LaS_Data.polygon.setShine(true)
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

function model:laserUpdate()
 local dx = love.timer.getDelta()
 local vars = self.renderData.vars
 if vars.growthStage then
  if vars.width >= vars.maxWidth then
   vars.growthStage = false
  end
 elseif not vars.growthStage then
  if vars.width <= vars.minWidth then
   vars.growthStage = true
  end
 end
 
 if vars.growthStage then
  vars.width = vars.width+vars.incWidth*(dx*10)
 else
  vars.width = vars.width-vars.incWidth*(dx*10)
 end
end

function model:destroyLaS()
 self.LaS_Data.polygon.clear()
end

function model:draw()
 local thisClient = CuCo.NetModule.Client.self
 local vars = self.renderData.vars
 local vec3_start = vars.vec3_start
 local vec3_end = vars.vec3_end
 
 if vars.percentLong < 100 then
  vars.percentLong = vars.percentLong + (350 * love.timer.getDelta())
 elseif vars.percentLong > 100 then vars.percentLong = 100
 end
 
 local vec3_endAfter = {}
 local angle = math.atan2(vec3_start[2]-vec3_end[2],vec3_start[1]-vec3_end[1])+math.rad(180)
 local length = mlib.Line.GetLength(vec3_start[1],vec3_start[2],vec3_end[1],vec3_end[2])
 local mag = (vars.percentLong/100)*length
 
 local xc = mag*math.cos(angle)+vec3_start[1]
 local yc = mag*math.sin(angle)+vec3_start[2]
 vec3_endAfter = {xc,yc}
 local nOffset_start = thisClient:getRenderOffsetTo(vec3_start[1],vec3_start[2])
 local nOffset_end = thisClient:getRenderOffsetTo(vec3_endAfter[1],vec3_endAfter[2])
 
 self:laserUpdate()
 
  
 local polyPoints = {}
 local width = vars.width/2
 local L1 = {}
  L1[1] = width*math.cos(angle+math.rad(90))+nOffset_start[1]
  L1[2] = width*math.sin(angle+math.rad(90))+nOffset_start[2]
 local R1 = {}
  R1[1] = width*math.cos(angle-math.rad(90))+nOffset_start[1]
  R1[2] = width*math.sin(angle-math.rad(90))+nOffset_start[2]
 local L2 = {}
  L2[1] = width*math.cos(angle+math.rad(90))+nOffset_end[1]
  L2[2] = width*math.sin(angle+math.rad(90))+nOffset_end[2]
 local R2 = {}
  R2[1] = width*math.cos(angle-math.rad(90))+nOffset_end[1]
  R2[2] = width*math.sin(angle-math.rad(90))+nOffset_end[2]
 
  
 self.LaS_Data.polygon.setPoints(L1[1],L1[2],R1[1],R1[2],L2[1],L2[2],R2[1],R2[2])
 local widthPercentile = (((vars.width)/(vars.maxWidth)))
 self.LaS_Data.polygon.setAlpha(.5-(widthPercentile)*0.5)
 self.LaS_Data.polygon.setColor(((255)-(widthPercentile)*1), 255, 255)
 
 love.graphics.setLineWidth(vars.width)
 love.graphics.setColor(55,(((vars.width)/(vars.maxWidth/2)))*255,((vars.width/vars.maxWidth))*255,255)
 love.graphics.line(nOffset_start[1],nOffset_start[2],nOffset_end[1],nOffset_end[2])
 love.graphics.setColor(255,255,255,255)
 love.graphics.setLineWidth(1)
end

return model

