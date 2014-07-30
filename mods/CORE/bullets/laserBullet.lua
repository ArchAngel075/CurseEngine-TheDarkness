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
 self.vec3_start = {-1,-1}
 self.vec3_end = {-1,-1}
 
 self.owner = false
 
 
 self.lifeTime = 4
 self.lifeTimeExceed = self.lifeTime + love.timer.getTime()
 
 self.updateHook = CuCo.EngineModule.data.Events["onUpdate"]:newHook(self.update,self)
end

function asset:onProxyBuild(real)
 --Create the assets container for the Events the client will cause...
 self.eventBuffer = {}
 --Create the assets key container for sending to host
 self.vec3_start = {-1,-1}
 self.vec3_end = {-1,-1}
 self.model = CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.models.laserBulletModel:new()
 self.model:init()
 self.model:setOwner(self.address) --proper way to set owner
 self.drawHook = CuCo.EngineModule.data.Events["onDraw"]:newHook(self.drawProxy,self)
end

function asset:update()
 if self.lifeTimeExceed <= love.timer.getTime() then
  CuCo.AssetModule.destroyAsset(self)
 end
 --check col
 if self.vec3_start and self.vec3_end then
  --build player list
  local playerlist = {}
  for k,v in pairs(CuCo.NetModule.Server.getClients()) do
   local point = {v.physics.body:getPosition()}
   local shape = mlib.Shape.NewShape(point[1],point[2],6)
   table.insert(playerlist,{v,shape})
  end
  for k,v in pairs(playerlist) do
	local doesCollide = mlib.Polygon.CircleIntersects(
	v[2].x,v[2].y,v[2].radius,
	{self.vec3_start[1],self.vec3_start[2],self.vec3_end[1],self.vec3_end[2]}
													 )
    if doesCollide then
	 self:beginCollision(v[1])
	end
  end
 end  
 --
end

function asset:setlaserstart(x,y)
 self.vec3_start = {x,y}
end
function asset:setlaserend(x,y)
 self.vec3_end = {x,y}
end

function asset:setlaser(sx,sy,ex,ey)
 self:setlaserstart(sx,sy)
 self:setlaserend(ex,ey)
end

function asset:updateModel()
 if self.vec3_start then  
  self.model:setVar("vec3_start",self.vec3_start)
  self.model:setVar("vec3_end",self.vec3_end)
 end
end

function asset:drawProxy()
 if not self.model then return end
 -- these run regardless
 --update the model with data partaining to owner status
  --if we are owned then set renderdata to client pos offset by x,y
  --if owned by world then we use default render data(no change)
  
 local scene = CuCo.NetModule.Client.getScene()
 local push = function()
  
  self:updateModel()
  self.model:draw()
 end
 scene:pushToDrawLayer("Bullets",push)
end

function asset:toProxy_isRelevant(to)
 -- if to then
  -- local rVec3 = Utils.deepcopy({self.physics.body:getPosition()})
  -- local linVec2 = {}
  -- local linVec2 = {self.physics.body:getLinearVelocity()}
  -- local blinVec2 = {to.physics.body:getLinearVelocity()}
  -- local dx = love.timer.getDelta()
  -- rVec3[1] = (rVec3[1]) - (linVec2[1]*(dx+0.25)) --+ (blinVec2[1]*0.01)
  -- rVec3[2] = (rVec3[2]) - (linVec2[2]*(dx+0.25)) --+ (blinVec2[2]*0.01)
  
  
  -- if to:isOnScreen(rVec3[1],rVec3[2]) then
   -- return true
  -- else
   -- return false
  -- end
 -- else
  -- print("WARNING : attempt to relevant check on no bullet object?!")
  -- return true
 -- end
 return true
 --TODO create screen box relevence
end

function asset:beginCollision(with)
 if with.isPlayer and with ~= self.owner then --player collide with not owner
  --CuCo.AssetModule.destroyAsset(self)
 end
 if with.isWall then
  --CuCo.AssetModule.destroyAsset(self)
 end
end

function asset:toProxy_cookThis()
 local cook = {}
 cook.owner = self.owner.address or false
 cook.vec3_start = Utils.deepcopy(self.vec3_start)
 cook.vec3_end = Utils.deepcopy(self.vec3_end)
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
 if real.vec3_start then
  self.vec3_start = real.vec3_start
  self.vec3_end = real.vec3_end
 end
end

function asset:updateFromClient(proxy)

end

function asset:destroyProxy()
  CuCo.debugModule.dump("[DEBUG] destroying model.")
  self.model:destroyLaS()
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

