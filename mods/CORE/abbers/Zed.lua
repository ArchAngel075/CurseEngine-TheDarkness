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
 --Create the assets container for the Events the client will cause...
 self.vec3 = {-100,-100}
 ---physics data
 self.physics = {}
 self.physics.body = love.physics.newBody( CuCo.NetModule.Server.physics.world.physics.world, -100,-100, "dynamic" )
 self.physics.shape = love.physics.newCircleShape( 12 )
 self.physics.fixture = love.physics.newFixture( self.physics.body, self.physics.shape, 7.5 )
 self.physics.fixture:setUserData( self )
 self.physics.body:setLinearDamping(5.5)
 ---
 self.isDumbMoveTimer = 0
 self.isDumbMoveLength = 20
 self.isSeePlayerActive = false
 self.wanderFor = 15
 self.wanderRange = 800
 
 
 self.updateHook = CuCo.EngineModule.data.Events["onUpdate"]:newHook(self.update,self)
end

function asset:beginCollision(with)
 local with = with
 --print("I '"..self.address.."' Collided with '"..with.address.."'")
end

function asset:onProxyBuild(real)
 local half = {love.window.getMode( )}
 local half = {half[1]/2,half[2]/2}
 --Create the assets container for the Events the client will cause...
 self.vec3 = {-100,-100,0}
 self.model = CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.models.ZedModel:new()
 self.model:init()
 self.model:setOwner(self.address)
 ----
 self.drawHook = CuCo.EngineModule.data.Events["onDraw"]:newHook(self.drawProxy,self)
end

function asset:applyForceToBody(x,y)
 if self.physics and self.physics.body then
  self.physics.body:applyLinearImpulse(x,y)
 end
end

function asset:update()
 if not self.physics then return end
 self:MoveCheck()
 
 if self.Target then
  
  local target = self.Target.player
  --print("DXDX:"..mlib.Line.GetLength(target[1], target[2], self.vec3[1], self.vec3[2]))
  if (mlib.Line.GetLength(target[1], target[2], self.vec3[1], self.vec3[2]) <= 50 or self.isDumbMoveTimer+self.wanderFor < love.timer.getTime()) and not self.isSeePlayerActive then
   if self.isDumbMoveTimer < love.timer.getTime() then
    self.Target.player = {self.vec3[1]+math.random(-self.wanderRange,self.wanderRange), self.vec3[1]+math.random(-self.wanderRange,self.wanderRange)}
	self.isDumbMoveTimer = love.timer.getTime()+self.isDumbMoveLength
   end
  end
  
  local target = self.Target.player
  local angleTo = math.atan2(target[2]-self.vec3[2],target[1]-self.vec3[1])
  self.physics.body:setAngle(angleTo)
  
  local speed = 8
  if self.isSeePlayerActive then speed = speed+3 end
  local xcomp = speed*math.cos(angleTo)
  local ycomp = speed*math.sin(angleTo)
  self:applyForceToBody(xcomp,ycomp)
 end
 self.vec3[1] = self.physics.body:getX()
 self.vec3[2] = self.physics.body:getY()
 self.vec3[3] = self.physics.body:getAngle()
end

function asset:LosCheckAgainst(point)
 local World = CuCo.NetModule.Server.physics.world.physics.world
 local hasLOS = true
 
 local pos = {self.physics.body:getPosition()}
 
 
 local callback = function(fixture, x, y, xn, yn, fraction)
  local object = fixture:getUserData()
  if object and object.isWall then
   hasLOS = false
   return 0
  end
  return 1
 end
 
 World:rayCast(pos[1], pos[2], point[1], point[2], callback )
 
 return hasLOS
end


function asset:MoveCheck()
 --if self.Target then return end

 local players = CuCo.NetModule.Server.getClients()
 local canSee = {}
 for k,v in pairs(players) do
  local pos = {v.physics.body:getPosition()}
  local hasLoS = self:LosCheckAgainst(pos)
  if hasLoS then canSee[#canSee+1] = v end
 end
 
 local Target = {}
 for k,v in pairs(canSee) do
  local MyPos = {self.physics.body:getPosition()}
  local playerPos = {self.physics.body:getPosition()}
  
  if not Target.dx then --we havent done first...
   Target.dx = mlib.Line.GetLength(MyPos[1], MyPos[2], playerPos[1], playerPos[2])
   Target.player = v
  elseif Target.dx then
   local dx = mlib.Line.GetLength(MyPos[1], MyPos[2], playerPos[1], playerPos[2])
   if Target.dx > dx then
    Target.dx = mlib.Line.GetLength(MyPos[1], MyPos[2], playerPos[1], playerPos[2])
    Target.player = v
   end
  end
 end
 
 
 
 if #canSee ~= 0 and Target.dx then
  self.Target = {dx=Target.dx,player={Target.player.physics.body:getPosition()}}
  self.isSeePlayerActive = true
 else
  self.isSeePlayerActive = false
 end
end

function asset:updateModel()
 local half = {love.window.getMode( )}
 local half = {half[1]/2,half[2]/2}
 if self.model then
  self.model:setVar("vec3",self.vec3)
 end
end

function asset:drawProxy()
 if not self.isRelevant then return end
 -- these run regardless
 --draw model :
 local thisClient = CuCo.NetModule.Client.self
 local scene = CuCo.NetModule.Client.getScene()
 local push = function()
  if not self.model then return end
  self:updateModel()
  self.model:draw()
  love.graphics.setColor(255,255,255,255)
 end
 scene:pushToDrawLayer("Enemies",push)
 
 if not CuCo._RESERVED.MOD_DATABASE_PROXY.BUILD[self.address] then
  CuCo.AssetModule.destroyAsset(self)
 end
end


function asset:toProxy_isRelevant(to)
 return true
end

function asset:isMoving()
 if not self.physics then return end
 local linVec2 = {self.physics.body:getLinearVelocity()}
 --div by mag
 local mag = mlib.Line.GetLength( 0, 0,math.abs(linVec2[1]),math.abs(linVec2[2]))
 if mag/100 >= 0.2 then return true else return false end
end

function asset:toProxy_cookThis()
 local cook = {}
 cook.vec3 = Utils.deepcopy(self.vec3)
 cook.isMoving = self:isMoving()
 return cook
end

function asset:toHost_cookThis()
 --send to Host from client!
 local cook = {}
 return cook
end

function asset:updateProxyCall(real)
 --these run regardless
 if real.vec3 then 
  self.vec3 = real.vec3 
  self.model:setVar("isMoving",real.isMoving or false)
 end
end

function asset:updateFromClient(proxy)
 --serverside!
end

function asset:destroyProxy()
 CuCo.debugModule.dump("[DEBUG] destroying model.")
 self.model:destroyLaS()
 CuCo.EngineModule.data.Events["onDraw"]:removeHook(self.drawHook)
end

function asset:destroy()
 self.physics.fixture:destroy()
 
 CuCo.EngineModule.data.Events["onUpdate"]:removeHook(self.updateHook)
end

return asset

