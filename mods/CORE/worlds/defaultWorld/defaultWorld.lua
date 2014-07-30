local asset = {
 type="class",
}

function asset:new()
 local o = {} -- create a copy of the base data...
 setmetatable(o, self)
 self.__index = self
 return o
end

function asset:buildPhysicsmap(builtMap)
 self.physics.physicsmap = {}
 for k,v in pairs(builtMap) do
  --[[
   x,y set,
   properties, solid true makes it solid!
  --]]
  self.physics.physicsmap[k] = {}
  local Tile = v.tile
  local worldPos = {x=v.world_x,y=v.world_y}
  local TablePos = {x=v.table_x,y=v.table_y}
  if Tile.properties and Tile.properties["solid"] == "true" then
   self.physics.physicsmap[k].body = love.physics.newBody( self.physics.world, ((worldPos.x-1)*32)-16, ((worldPos.y-1)*32)-16, "static" )
   self.physics.physicsmap[k].shape = love.physics.newRectangleShape( 32, 32 )
   self.physics.physicsmap[k].fixture = love.physics.newFixture( self.physics.physicsmap[k].body, self.physics.physicsmap[k].shape, 1 )
   self.physics.physicsmap[k].fixture:setUserData(self)
  end
  if not Tile.properties or Tile.properties and Tile.properties.solid == nil then
   error(Utils.gTBL(v))
  end
 end
end

function asset:beginCollision(with)

end

function asset:onBuild()
 self.physics = {}
 self.physics.world = love.physics.newWorld(0,0,true)
 self.physics.world:setCallbacks( CuCo.NetModule.Core.collisionEvent )
 self.isWall = true
 
 --map file is located in same location as self
 local path = {}
 for i = 1,#self.path-1 do
  path[i] = self.path[i]
 end
 local maptmxpath = Utils.deepcopy(path)
 maptmxpath[#maptmxpath+1] = maptmxpath[#maptmxpath].."_Map"
 maptmxpath = "mods/"..table.concat(maptmxpath,"/")
 self.stimap = sti.new(maptmxpath)
 
 --DEBUG
 
 --
 
 
 
 local builtMap = Utils.stiHelper.constructFromMap(self.stimap)
 
 self:buildPhysicsmap(builtMap)
 self:buildSpawnmap(self.stimap)
 
 self.updateHook = CuCo.EngineModule.data.Events["onUpdate"]:newHook(self.update,self)
end

function asset:onProxyBuild()
 --map file is located in same location as self
 local path = {}
 for i = 1,#self.path-1 do
  path[i] = self.path[i]
 end
 local maptmxpath = Utils.deepcopy(path)
 maptmxpath[#maptmxpath+1] = maptmxpath[#maptmxpath].."_Map"
 maptmxpath = "mods/"..table.concat(maptmxpath,"/")
 self.stimap = sti.new(maptmxpath)
 
 local builtMap = Utils.stiHelper.constructFromMap(self.stimap)
 self:buildLightsmap(builtMap)
 
 self.drawHook = CuCo.EngineModule.data.Events["onDraw"]:newHook(self.drawProxy,self)
 self.updateHook = CuCo.EngineModule.data.Events["onUpdate"]:newHook(self.updateProxy,self)
end

function asset:updateProxy()
 self.stimap:update()
end

function asset:update()
 self.stimap:update()
 self.physics.world:update(love.timer.getDelta())
end

function asset:registerEnemySpawn(rect)
 local spawn = {}
 spawn.size = {rect.width,rect.height}
 spawn.vec2 = {rect.x,rect.y}
 spawn.shape = rect.shape
 spawn.chance = 1--tonumber(rect.properties.population)
 if spawn.chance == 0 then spawn.chance = 1 end
 table.insert(self.spawnBoxi.enemySpawns,spawn)
end

function asset:randomPointIn(spawnBox)

 if type(spawnBox) == "table" then
  spawnBox = spawnBox
 elseif type(spawnBox) == "string" then
  spawnBox = self.spawnBoxi[spawnBox]
 end

 local chanceBox = {}
 for k,v in pairs(spawnBox) do
  if not chanceBox[v.chance] then
   chanceBox[v.chance] = {}
  end
  table.insert(chanceBox[v.chance],v)
 end
 local k
 local rectList
 function getChanceRects()
  k = math.random(1,100)
  chance = chanceBox[k]
  if chance then
   local rectList = #chance
   return rectList
  else
   return false
  end
 end
 
 while rectList == 0 or not rectList do
  rectList = getChanceRects()
 end
 
 local rectUse = math.random(1,rectList)
 --error(k..":"..Utils.gTBL(chanceBox))
 local box = chanceBox[k][rectUse]
 local pointOut
 
 function getPointInBox()
  local p = {math.random(1,box.size[1]) , math.random(1,box.size[2])}
  return {p[1]+box.vec2[1] , p[2]+box.vec2[2]}
 end
 pointOut = getPointInBox()
 return pointOut
end

function asset:registerPlayerSpawn(rect)
 local spawn = {}
 spawn.size = {rect.width,rect.height}
 spawn.vec2 = {rect.x,rect.y}
 spawn.shape = rect.shape
 spawn.chance = 1
 table.insert(self.spawnBoxi.playerSpawns,spawn)
end

function asset:buildSpawnmap(map)
 self.spawnBoxi = {}
 self.spawnBoxi.playerSpawns = {}
 self.spawnBoxi.enemySpawns = {}
 
 for layer_index,layer_value in pairs(map.layers) do
  if layer_value.objects then
   for object_i,object_v in pairs(layer_value.objects) do
    if object_v.properties then
	 if object_v.properties.population then
	  self:registerEnemySpawn(object_v)
     end
	 if object_v.properties.spawnRoom then
	  self:registerPlayerSpawn(object_v)
     end
	end
   end
  end
 end
end

function asset:buildLightsmap(stimap)
self.lightsmap = {}
local lightWorld = CuCo.NetModule.Client.getLaSWorld()
 for k,v in pairs(stimap) do
  --[[
   x,y set,
   properties, solid true return solid body.
  --]]
  local Tile = v.tile
  local worldPos = {x=v.world_x,y=v.world_y}
  local TablePos = {x=v.table_x,y=v.table_y}

  self.lightsmap[k] = {}
  if Tile.properties and Tile.properties["solid"] == "true" then
   self.lightsmap[k].rect = lightWorld.newRectangle(((worldPos.x-1)*32)-16, ((worldPos.y-1)*32)-16, 32, 32)
   self.lightsmap[k].iPos = {worldPos.x,worldPos.y}
  end
 end
end

function asset:updateLightMap()
  local lightWorld = CuCo.NetModule.Client.getLaSWorld()
  local thisClient = CuCo.NetModule.Client.self
  for k,v in pairs(self.lightsmap) do
   if v.rect then
    local pos = v.iPos
   	local offset = thisClient:getRenderOffsetTo((((pos[1]-1)*32)-16), (((pos[2]-1)*32)-16))
    v.rect.setPosition(offset[1],offset[2])
   end
  end
  --error()
end

function asset:drawProxy()
 local scene = CuCo.NetModule.Client.getScene()
 local push = function()
  -- these run regardless
  
  --local of this clients asset for quick access :
  local thisClient = CuCo.NetModule.Client.self
  local renderOffset = thisClient:getRenderOffsetTo(thisClient.vec3[1],thisClient.vec3[2])
  love.graphics.push()
   local translateX = (CuCo.EngineModule.Window[1]/2)+thisClient.vec3[1]*-1
   local translateY = (CuCo.EngineModule.Window[2]/2)+thisClient.vec3[2]*-1
   love.graphics.translate(translateX,translateY)
   self.stimap:draw()
   self.stimap:setDrawRange(translateX, translateY, CuCo.EngineModule.Window[1], CuCo.EngineModule.Window[2])
   self.lightsTranslation = {translateX, translateY}
  love.graphics.pop()
  self:updateLightMap()
  -----
  -- local builtMap = Utils.stiHelper.constructFromMap(self.stimap)
  -- local redColor = {255,0,0,63}
  -- local blueColor = {0,0,255,63}
  -- local nilColor = {255,255,255,255}
  -- if CuCo.NetModule.Client.self.keyBuffer["rshift"] then
   -- for k,v in pairs(builtMap) do
    -- if v.properties["solid"] == "true" then
     -- love.graphics.setColor(redColor)
    -- elseif v.properties["solid"] == "false" then
     -- love.graphics.setColor(blueColor)
    -- end
	-- local offset = thisClient:getRenderOffsetTo((((v.x-1)*32)-32), (((v.y-1)*32)-32))
    -- love.graphics.rectangle( "fill", offset[1], offset[2], 32, 32 )
    -- love.graphics.setColor(nilColor)
   -- end
  -- end
  -----
 end
 scene:pushToDrawLayer("Map",push)
end


function asset:toProxy_isRelevant()
 --return false --dont alert client to this asset, _ removed, see below
 --[[
  In future map data will be stored and updated, 
  but for now this client has no need to be proxied...
  
  now needed, map is now relevent as client uses to render.
 --]]
 return true
end

function asset:toProxy_cookThis()
 local cook = {}
 return cook
end

function asset:toHost_cookThis()
 --send to Host from client!
 local cook = {}
 return cook
end

function asset:updateProxyCall(real)
 --
end

function asset:updateFromClient(proxy)
 --serverside!
end

function asset:destroy()
 CuCo.EngineModule.data.Events["onUpdate"]:removeHook(self.updateHook)
 CuCo.EngineModule.data.Events["onDraw"]:removeHook(self.drawHook)
 self = nil
end

return asset

