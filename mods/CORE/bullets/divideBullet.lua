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
 self.vec3 = {-1,-1}
 self.physics = {}
 self.physics.body = love.physics.newBody( CuCo.NetModule.Server.physics.world.physics.world, -1, -1, "dynamic" )
 --self.physics.body:setLinearDamping(0.01)
 self.physics.shape = love.physics.newCircleShape( 4 )
 self.physics.fixture = love.physics.newFixture( self.physics.body, self.physics.shape, 0.15 )
 self.physics.fixture:setUserData( self )
 
 self.owner = false
 
 
 self.lifeTime = 1.15
 self.lifeTimeExceed = self.lifeTime + love.timer.getTime()
 self.isChild = false
 
 self.updateHook = CuCo.EngineModule.data.Events["onUpdate"]:newHook(self.update,self)
end

function asset:onProxyBuild(real)
 --Create the assets container for the Events the client will cause...
 self.eventBuffer = {}
 --Create the assets key container for sending to host
 self.vec3 = {200,500}
 self.model = CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.models.defaultBulletModel:new()
 self.model:init()
 self.model:setOwner(self.address) --proper way to set owner
 
 self.lifeTime = 1.15
 self.lifeTimeExceed = self.lifeTime
 
 self.drawHook = CuCo.EngineModule.data.Events["onDraw"]:newHook(self.drawProxy,self)
end

function asset:update()
 self.vec3[1] = self.physics.body:getX()
 self.vec3[2] = self.physics.body:getY()
 self.vec3[3] = self.physics.body:getAngle()
 if self.lifeTimeExceed <= love.timer.getTime() then
  if self.isChild then
   --CuCo.AssetModule.destroyAsset(self)
   --do nothing
  else
   local spawnPoint = {self.physics.body:getPosition()}
   local linVec2 = {self.physics.body:getLinearVelocity()}
   local angle = self.divAngle
   local mag = 1.25
  
   for i = 1,3 do
    mag = mag+math.random(0.05,0.55)
    angle = angle+math.rad(math.random(-3,3))
    -----------
    local bulletType = CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.bullets.divideBullet
    local bullet = CuCo.AssetModule.newInstance(bulletType)
    local xcomp = mag*math.cos(angle)
    local ycomp = mag*math.sin(angle)
    bullet.owner = self.owner
    bullet.physics.body:setPosition(spawnPoint[1],spawnPoint[2])
    bullet.physics.body:applyLinearImpulse(xcomp,ycomp)
    bullet.divAngle = angle
    bullet.isChild = true
    ------------------
   end
   CuCo.AssetModule.destroyAsset(self)
  end
 end
end

function asset:updateModel()
 if self.vec3 then
  self.model:setVar("vec3",self.vec3)
 end
  self.model:setVar("lifeTimeExceed",self.lifeTimeExceed)
  self.model:setVar("lifeTime",self.lifeTime)
  self.model:setVar("Time",self.time)
end

function asset:drawProxy()
 if not self.isRelevant then return end
 -- these run regardless
 --update the model with data partaining to owner status
  --if we are owned then set renderdata to client pos offset by x,y
  --if owned by world then we use default render data(no change)
  
 local scene = CuCo.NetModule.Client.getScene()
 local push = function()
  if self.model then
   self:updateModel()
   self.model:draw()
  end
 end
 scene:pushToDrawLayer("Bullets",push)
end

function asset:toProxy_isRelevant(to)
 if to then
  local rVec3 = Utils.deepcopy({self.physics.body:getPosition()})
  local linVec2 = {}
  local linVec2 = {self.physics.body:getLinearVelocity()}
  local blinVec2 = {to.physics.body:getLinearVelocity()}
  local dx = love.timer.getDelta()
  rVec3[1] = (rVec3[1]) - (linVec2[1]*(dx+0.25)) --+ (blinVec2[1]*0.01)
  rVec3[2] = (rVec3[2]) - (linVec2[2]*(dx+0.25)) --+ (blinVec2[2]*0.01)
  
  
  if to:isOnScreen(rVec3[1],rVec3[2]) then
   return true
  else
   return false
  end
 else
  print("WARNING : attempt to relevant check on no bullet object?!")
  return true
 end
end

function asset:beginCollision(with)
 if with.isPlayer and with ~= self.owner then --player collide with not owner
  CuCo.AssetModule.destroyAsset(self) 
 end
 if with.isWall then
  CuCo.AssetModule.destroyAsset(self)
 end
end

function asset:toProxy_cookThis()
 local cook = {}
 cook.owner = self.owner.address or false
 cook.vec3 = Utils.deepcopy(self.vec3)
 cook.lifeTimeExceed = self.lifeTimeExceed
 cook.time = love.timer.getTime()
 cook.lifeTime = self.lifeTime
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
 if real.vec3 then
  self.vec3 = real.vec3
 end
 if real.lifeTimeExceed then
  self.lifeTimeExceed = real.lifeTimeExceed
  self.lifeTime = real.lifeTime
  self.time = real.time
 end
end

function asset:updateFromClient(proxy)

end

function asset:destroyProxy()
  CuCo.debugModule.dump("[DEBUG] destroying model.")
  self.model:destroyLaS()
  self.model = nil
 CuCo.EngineModule.data.Events["onDraw"]:removeHook(self.drawHook)
end

function asset:destroy()
 self.physics.fixture:destroy()
 CuCo.EngineModule.data.Events["onUpdate"]:removeHook(self.updateHook)
 self = nil
end

function asset:myFunction()
 --
end

return asset

