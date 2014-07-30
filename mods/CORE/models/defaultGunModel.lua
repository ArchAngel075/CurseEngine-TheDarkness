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
 local imgPath = Utils.deepcopy(self.path)
 imgPath[3] = "defaultgun.png"
 table.insert(imgPath,1,"mods")
 imgPath = table.concat(imgPath,"/")

 self.renderData = {
  Owner = false,
  vars = {
   vec3 = {100,100,0},
   image = love.graphics.newImage(imgPath),
   imgOffset = {25,50},
   isUsed = false,
  }
 }
 CuCo.debugModule.dump("[DEBUG] initialised model.")
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

function model:draw()
 if not self.renderData.vars.isUsed then return end
 local thisClient = CuCo.NetModule.Client.self
 local vars = self.renderData.vars
 local image = self.renderData.vars.image
 local imgOffset = self.renderData.vars.imgOffset
 local vec3 = vars.vec3 or {0,0,0}
 local nOffset = thisClient:getRenderOffsetTo(vec3[1],vec3[2])
 love.graphics.draw(image,nOffset[1],nOffset[2],vec3[3]+math.rad(90),0.75,0.75,imgOffset[1],imgOffset[2])
end

function model:destroy()
 self.renderData.vars.isUsed = false
 CuCo._RESERVED.MOD_DATABASE_HOST.BUILD[self.address] = nil
 CuCo.debugModule.dump("[DEBUG] destroyed model.")
end

return model

