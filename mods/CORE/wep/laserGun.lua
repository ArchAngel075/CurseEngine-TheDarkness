local asset = {
 type="class",
}

function asset:new()
 local o = {} -- create a copy of the base data...
 setmetatable(o, self)
 self.__index = self
 return o
end

function asset:onBuild()
 self.updateHook = CuCo.EngineModule.data.Events["onUpdate"]:newHook(self.update,self)
 
 self.bulletType = CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.bullets.laserBullet
 
 self.isUsed = false
 
 self.canFireTimer = love.timer.getTime()
 local rps = 0.45--4
 --[[
  rounds per second
  n rounds each second
  rps of 1 is 1/1 = 1
  rps of 2 is 1/2 = 0.5
   1/n is time lag
 --]]
 self.canFireTimer_Base = (1/rps)
end

function asset:onProxyBuild(real)
 --Create the assets container for the Events the client will cause...
 self.eventBuffer = {}
 --Create the assets key container for sending to host
 self.isUsed = false
 -- self.model = CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.models.defaultGunModel:new()
 -- self.model:init()
 -- self.model:setOwner(self.address) --proper way to set owner
 self.drawHook = CuCo.EngineModule.data.Events["onDraw"]:newHook(self.drawProxy,self)
end

function asset:selected()
 self.isUsed = true
 print("I '"..self.address.."' was selected!")
end

function asset:unselected()
 self.isUsed = false
 print("I '"..self.address.."' was unselected!")
end

function asset:update()
 
end

function asset:canUse()
 local canFireTimer = self.canFireTimer
 if love.timer.getTime() >= canFireTimer then
  return true
 end
 return false
end

function asset:use()
 if not self:canUse() then return end
 self.canFireTimer = love.timer.getTime()+self.canFireTimer_Base
 
 local spawnPos = {self.owner.physics.body:getPosition()}
 spawnPos[3] = self.owner.vec3[3]

 local magspawn = 10000
 local xlimit = magspawn*math.cos(spawnPos[3])+spawnPos[1]
 local ylimit = magspawn*math.sin(spawnPos[3])+spawnPos[2]
 
 function callback(fixture, x, y, xn, yn, fraction)
  if fixture:getUserData() then
   local fObject = fixture:getUserData()
   if fObject == self.owner then return 1 end
   if fObject.isWall then
    local starts = spawnPos
    local ends = {x,y}
    local laser = CuCo.AssetModule.newInstance(self.bulletType)
	laser.owner = self.owner
	laser:setlaser(starts[1],starts[2],ends[1],ends[2])
    return 0
   end
  end
  return fraction
 end
 
 local World = CuCo.NetModule.Server.physics.world.physics.world
 World:rayCast( spawnPos[1], spawnPos[2], xlimit, ylimit, callback )
end

function asset:updateModel()
 if self.owner then
  if self.owner.vec3[3] then
   --self.model:setVar("vec3",self.owner.vec3)
  end
 end
 --self.model:setVar("isUsed",self.isUsed)
end

function asset:drawProxy()
 if not self.isUsed then return end
 -- these run regardless
 --update the model with data partaining to owner status
  --if we are owned then set renderdata to client pos offset by x,y
  --if owned by world then we use default render data(no change)
  --CuCo.debugModule.dump("[DEBUG] initialised model.")
 local scene = CuCo.NetModule.Client.getScene()
 local push = function()
  -- self:updateModel()
  -- self.model:draw()
 end
 scene:pushToDrawLayer("Wep",push)
 
 if not CuCo._RESERVED.MOD_DATABASE_PROXY.BUILD[self.address] then
  CuCo.AssetModule.destroyAsset(self)
 end
end

function asset:toProxy_isRelevant()
 return true
end

function asset:toProxy_cookThis()
 local cook = {}
 cook.owner = self.owner.address or false
 cook.isUsed = self.isUsed or false
 return cook
end

function asset:toHost_cookThis()
 --send to Host from client!
 local cook = {}
 return cook
end

function asset:updateProxyCall(real)
 if real.owner then 
  self.owner = CuCo._RESERVED.MOD_DATABASE_PROXY.BUILD[real.owner]
 end
 if real.isUsed then self.isUsed = real.isUsed end
end

function asset:updateFromClient(proxy)

end

function asset:setName(Uname)
 self.CurseClient.Uname = Uname
end

function asset:destroyProxy()
 --self.model:setVar("isUsed",false)
 CuCo.debugModule.dump("[DEBUG] destroying model.")
 self.model = nil
 CuCo.EngineModule.data.Events["onDraw"]:removeHook(self.drawHook)
end

function asset:destroy()
 CuCo.EngineModule.data.Events["onUpdate"]:removeHook(self.updateHook)
 self = nil
end

function asset:myFunction()
 --
end

return asset

