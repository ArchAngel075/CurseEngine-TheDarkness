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
 self.vec3 = {300,300}
 ---physics data
 self.physics = {}
 self.physics.body = love.physics.newBody( CuCo.NetModule.Server.physics.world.physics.world, 300,300, "dynamic" )
 self.physics.shape = love.physics.newCircleShape( 4 )
 self.physics.fixture = love.physics.newFixture( self.physics.body, self.physics.shape, 10 )
 self.physics.fixture:setUserData( self )
 self.physics.body:setLinearDamping(7.5)
 ---
 
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
 self.vec3 = {300,300,0}
 self.model = CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.models.pointLightModel:new()
 self.model:init()
 self.model:setOwner(self.address)
 ----
 self.drawHook = CuCo.EngineModule.data.Events["onDraw"]:newHook(self.drawProxy,self)
 self.updateHook = CuCo.EngineModule.data.Events["onUpdate"]:newHook(self.updateProxy,self)
end

function asset:applyForceToBody(x,y)
 if self.physics and self.physics.body then
  self.physics.body:applyLinearImpulse(x,y)
 end
end

function asset:update()
 if not self.physics then return end
 self.vec3[1] = self.physics.body:getX()
 self.vec3[2] = self.physics.body:getY()
 self.vec3[3] = self.physics.body:getAngle()
end

function asset:updateProxy()
 self.model:update()

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
 --local scene = CuCo.NetModule.Client.getScene()
 local scene = CuCo.NetModule.Client.data.OnShadowsScene
 local push = function()
  if not self.model then return end
  self:updateModel()
  self.model:draw()
  love.graphics.setColor(255,255,255,255)
 end
 scene:pushToDrawLayer("LightMap",push)
 --scene:pushToDrawLayer("Lights",push)
 
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

