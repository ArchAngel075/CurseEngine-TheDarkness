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
 -- CuCo.onNewInstanceEvent:newHook(self.myFunction,self)
 --Create the assets container for the Events the client will cause...
 self.isPlayer = true
 self.eventBuffer = {}
 --Create the assets key container for sending to host
 self.keyBuffer = {}
 self.mouseBuffer = {}
 
 local half = {love.window.getMode( )}
 local half = {half[1]/2,half[2]/2}
 
 local randomSpawn = CuCo.NetModule.Server.physics.world:randomPointIn("playerSpawns")
 
 self.vec3 = randomSpawn
 ---physics data
 self.physics = {}
 self.physics.body = love.physics.newBody( CuCo.NetModule.Server.physics.world.physics.world, randomSpawn[1], randomSpawn[2], "dynamic" )
 self.physics.shape = love.physics.newCircleShape( 12 )
 self.physics.fixture = love.physics.newFixture( self.physics.body, self.physics.shape, 7.5 )
 self.physics.fixture:setUserData( self )
 self.physics.body:setLinearDamping(5.5)
 ---
 self.inventory = {selected = false}
 self.charge = 100 -- int
 self.chargeMax = 100 -- int
 self.charge_walkGain = 0.001 -- int
 self.charge_torchLoss = 0.001 -- int
 self.torch_isOn = true
 
 
 
 -- local aWeapon = CuCo.AssetModule.newInstance(CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.wep.defaultGun)
 -- aWeapon.owner = self
 -- aWeapon.bulletType = CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.bullets.bounceBullet
 -- self:addToInventory(aWeapon)
 -- CuCo.debugModule.dump("[DEBUG] Created wep 1")
 
 -- local aWeapon = CuCo.AssetModule.newInstance(CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.wep.defaultGun)
 -- aWeapon.owner = self
 -- self:addToInventory(aWeapon)
 -- aWeapon.canFireTimer_Base = (1/1.65)
 -- CuCo.debugModule.dump("[DEBUG] Created wep 2")
 
 --local aWeapon = CuCo.AssetModule.newInstance(CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.wep.laserGun)
 -- --aWeapon.bulletType = CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.bullets.bounceBullet
 -- -- self:addToInventory(aWeapon)
 -- -- CuCo.debugModule.dump("[DEBUG] Created wep 1")
 -- -- self:selectFromInventory(1)
 -- -- CuCo.debugModule.dump("[DEBUG] selected wep 1")
 
 local giveWeapon = false
 
 if giveWeapon then
  local aWeapon = CuCo.AssetModule.newInstance(CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.wep.defaultGun)
  aWeapon.owner = self
  self.weapon = aWeapon
  self.weapon:selected()
  CuCo.debugModule.dump("[DEBUG] selected weapon")
 end
 
 self.mousePressedHook = CuCo.onClientMousePressedEvent:newHook(self.event_onMousePressed , self)
 self.updateHook = CuCo.EngineModule.data.Events["onUpdate"]:newHook(self.update,self)
end

function asset:beginCollision(with)
 local with = with
 print("I '"..self.address.."' Collided with '"..with.address.."'")
end

function asset:onProxyBuild(real)
 local half = {love.window.getMode( )}
 local half = {half[1]/2,half[2]/2}
 --Create the assets container for the Events the client will cause...
 self.eventBuffer = {}
 --Create the assets key container for sending to host
 self.keyBuffer = {}
 self.mouseBuffer = {}
 self.vec3 = {half[1],half[2],0}
 self.model = CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.models.UserModel:new()
 self.model:init()
 self.model:setOwner(self.address)
 self.camera = {half[1],half[2]}
 
 self._lastUpdatedDelta = 0
 self._lastUpdated = love.timer.getTime()
 
 ----
 self.drawHook = CuCo.EngineModule.data.Events["onDraw"]:newHook(self.drawProxy,self)
end

function asset:applyForceToBody(x,y)
 if self.physics and self.physics.body then
  self.physics.body:applyLinearImpulse(x,y)
 end
end

function asset:getRenderOffsetTo(x,y) -- TODO rename to getRenderOffsetToProxy
 local half = {love.window.getMode( )}
 local half = {half[1]/2,half[2]/2}
 --return {0,0}
 return {(((self.camera[1]-x))-half[1])*-1,(((self.camera[2]-y))-half[2])*-1}
end

function asset:getRenderOffsetTo_Server(x,y) --rename to getRenderOffsetTo
 local half = {love.window.getMode( )}
 local half = {half[1]/2,half[2]/2}
 --return {0,0}
 return {(((self.vec3[1]-x))-half[1])*-1,(((self.vec3[2]-y))-half[2])*-1}
end

function asset:selectFromInventory(index)
 if self.inventory[index] then
  if self.weapon then self.weapon:unselected() end
  self.inventory["selected"] = index
  self.weapon = self.inventory[index]
  self.weapon:selected()
 end
end

function asset:upInventory()
 if #self.inventory ~= 0 then
  if self.inventory["selected"] == #self.inventory then
   self:selectFromInventory(1)
  else
   self:selectFromInventory(self.inventory["selected"]+1)
  end
 end
end

function asset:downInventory()
 if #self.inventory ~= 0 then
  if self.inventory["selected"] == 1 then
   self:selectFromInventory(#self.inventory)
  else
   self:selectFromInventory(self.inventory["selected"]-1)
  end
 end
end

function asset:addToInventory(object)
 if object then
  self.inventory[#self.inventory+1] = object
  if not self.inventory["selected"] then self.inventory["selected"] = 1 end
 end
end

function asset:isOnScreen(x,y)
 local half = {love.window.getMode( )}
 local half = {half[1]/2,half[2]/2}
 local offset = self:getRenderOffsetTo_Server(x,y)
 local x,y = offset[1],offset[2]
 if x <= half[1]*2.75
 and x >= 0
 and y <= half[2]*2.75
 and y >= 0 then
  return true
 else
  return false
 end
end

function asset:update()
 if not self.physics then return end
 local keybuffer = self.keyBuffer
 local mousebuffer = self.mouseBuffer
  local mag = 1.55
  local mag = mag*10
 if (keybuffer["a"] or keybuffer["d"]) and (keybuffer["w"] or keybuffer["s"]) then
  mag = mag-0.15
 end
 if self.keyBuffer["lshift"] then mag = mag*1.75 end
 if keybuffer["a"] then self:applyForceToBody(-mag*1.25,0) end
 if keybuffer["d"] then self:applyForceToBody(mag*1.25,0) end
 if keybuffer["w"] then self:applyForceToBody(0,-mag) end
 if keybuffer["s"] then self:applyForceToBody(0,mag) end
 self.vec3[1] = self.physics.body:getX()
 self.vec3[2] = self.physics.body:getY()
 if mousebuffer.vec3 and type(mousebuffer.vec3) == "table" then
  self.vec3[3] = mousebuffer.vec3[3]
 else
  self.vec3[3] = -1
 end
 if mousebuffer.l and self.weapon then
  --self.weapon:use()
 end
 if mousebuffer.wu then
  self:upInventory()
  
  --create a lovely zed
  
   --self:createZed()
  if not self.cZed then
   CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.fspawnZeds(1)
   
   --light debugging
   local light = CuCo.AssetModule.newInstance(CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.PointLights.defaultPointLight)
   
   self.cZed = true
  end
  
 end
 if mousebuffer.wd then
  self:downInventory()
 end
 
 if self:isMoving() then
  self.charge = self.charge+self.charge_walkGain
  if self.charge > self.chargeMax then self.charge = self.chargeMax end
 end
 if self.torch_isOn then
  self.charge = self.charge-self.charge_torchLoss
 end
 
 --[[
   self.charge = 100 -- int
 self.chargeMax = 100 -- int
 self.charge_walkGain = 0.25 -- int
 self.charge_torchLoss = 0.01 -- int
 
 --]]
 if self.charge < 0 then
  self.charge = 0
  self.torch_isOn = false
 end
end


function asset:event_onMousePressed(user,b,posx,posy)
 if not (user == self) then return end
 if b == "r" then
  self:toggleTorch()
  
  local torchSounds = CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.netSoundsPaths
  local indexi = {}
  local indexI = 0
  for k,v in pairs(torchSounds) do
   indexI = indexI+1
   if k:sub(1,#"torch") == "torch" then
    indexi[tostring(indexI)] = k
   end
  end
  
  local randomTorchSound = math.random(1,#indexi)
  randomTorchSound = indexi[tostring(randomTorchSound)]
  CuCo.NetModule.Core.broadcastSoundEvent(randomTorchSound,{self.vec3[1],self.vec3[2]})
 end
end

function asset:toggleTorch()
 local state = "Off"
 if self.torch_isOn then state = "Off" else state = "On" end
 print("Torch "..state)
 self.torch_isOn = not(self.torch_isOn)
end

function asset:createZed()
local Zed = CuCo.AssetModule.newInstance(CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.abbers.Zed)
 local spawnPos = {self.physics.body:getPosition()}
 spawnPos[1] = math.random(500,3000)
 spawnPos[2] = math.random(500,3000)
 spawnPos[3] = self.vec3[3]
 Zed.physics.body:setPosition(spawnPos[1],spawnPos[2])

end

function asset:updateModel()
 local half = {love.window.getMode( )}
 local half = {half[1]/2,half[2]/2}
 if self.model then
  if self == CuCo.NetModule.Client.self then
   -- these run if this asset does belong to this client
   self.model:setVar("color",{0,255,0,255})
   local mXY = {love.mouse.getPosition()}
   local rot = math.atan2(mXY[2]-half[2],mXY[1]-half[1])
   self.mouseBuffer.vec3 = {mXY[1],mXY[2],rot}
   --CuCo.NetModule.Client.LaS_defualLight.setDirection((self.vec3[3]*-1)-math.rad(90))
  else
   self.model:setVar("color",{255,0,0,255})
  end
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
  -- local textOffset = thisClient:getRenderOffsetTo(self.vec3[1],self.vec3[2])
  -- local data = "Data :["
  
  -- if love.keyboard.isDown"lshift" or love.keyboard.isDown"rshift" then
   -- data = data.."\n"..Utils.gTBL({ID=self.address,Keys=self.keyBuffer,Mouse=self.mouseBuffer,Events=self.eventBuffer,vec3=self.vec3},1)
  -- else
   -- data = data.."HIDDEN]"
  -- end
   -- love.graphics.print(data,textOffset[1],textOffset[2])
 end
 scene:pushToDrawLayer("Players",push)
 
 local scene = CuCo.NetModule.Client.data.OnShadowsScene
 local push = function()
  if not self.model then return end
  self.model:drawCover()
  love.graphics.setColor(255,255,255,255)
 end
 scene:pushToDrawLayer("Coverup",push)
 
 if self.model then
  love.graphics.setColor(255,255,255,255)
  self.model:drawHUD()
 end
 if not CuCo._RESERVED.MOD_DATABASE_PROXY.BUILD[self.address] then
  CuCo.AssetModule.destroyAsset(self)
 end
end


function asset:toProxy_isRelevant(to)
 return true
 -- if to then
  -- local rVec3 = Utils.deepcopy({self.physics.body:getPosition()})
  -- local linVec2 = {}
  -- local linVec2 = {self.physics.body:getLinearVelocity()}
  -- local blinVec2 = {to.physics.body:getLinearVelocity()}
  -- local dx = love.timer.getDelta()
  -- rVec3[1] = (rVec3[1])-- - (linVec2[1])*1.5 --+ (blinVec2[1]*0.01)
  -- rVec3[2] = (rVec3[2])-- - (linVec2[2])*1.5 --+ (blinVec2[2]*0.01)
  
  -- if to:isOnScreen(rVec3[1],rVec3[2]) then
   -- return true
  -- else
   -- return false
  -- end
 -- else
  -- print("WARNING : attempt to relevant check on no client object?!")
  -- return true
 -- end
end

function asset:isMoving()
 if not self.physics then return end
 local linVec2 = {self.physics.body:getLinearVelocity()}
 --div by mag
 local mag = mlib.Line.GetLength( 0, 0,math.abs(linVec2[1]),math.abs(linVec2[2]))
 if mag/100 >= 0.2 then return true else return false end
end

function asset:getAnimMode()
 if self:isMoving() then
  if self.mouseBuffer["l"] then
   return "walk_shoot"
  else
   return "walk"
  end
 else
  if self.mouseBuffer["l"] then
   return "idle_shoot"
  else
   return "idle"
  end
 end
end

function asset:toProxy_cookThis()
 local cook = {}
 cook.animMode = self:getAnimMode()
 cook.vec3 = Utils.deepcopy(self.vec3)
 cook.keyBuffer = Utils.deepcopy(self.keyBuffer)
 cook.mouseBuffer = Utils.deepcopy(self.mouseBuffer)
 cook.torch_isOn = self.torch_isOn
 cook.charge = self.charge
 if self.weapon then
  cook.weapon = self.weapon.address
 end
 return cook
end

function asset:toHost_cookThis()
 --send to Host from client!
 local cook = {}
 if CuCo.NetModule.Client.self and self == CuCo.NetModule.Client.self then
  -- these run if this asset does belong to this client
  cook["eventBuffer"] = Utils.deepcopy(self.eventBuffer)
  cook["keyBuffer"] = Utils.deepcopy(self.keyBuffer)
  cook["mouseBuffer"] = Utils.deepcopy(self.mouseBuffer)
  
  --table.insert(CuCo.NetModule.Client.self.eventBuffer,{"onMouseReleased",b,mx,my})
  self.eventBuffer = {}
  if self.mouseBuffer["wu"] then
   self.mouseBuffer["wu"] = nil
   local pos = {love.mouse.getPosition()}
   table.insert(CuCo.NetModule.Client.self.eventBuffer,{"onMouseReleased","wu",pos[1],pos[2]})
  end
  if self.mouseBuffer["wd"] then
   self.mouseBuffer["wd"] = nil
   local pos = {love.mouse.getPosition()}
   table.insert(CuCo.NetModule.Client.self.eventBuffer,{"onMouseReleased","wd",pos[1],pos[2]})
  end
 end
 return cook
end

function asset:updateCycle()
 


end

function asset:simulation()


end

function asset:simulate(from,to)
 flux.to(from, self._lastUpdatedDelta+(love.timer.getDelta()) ,to)
end

function asset:updateProxyCall(real)
 self._lastUpdatedDelta = love.timer.getTime()-(self._lastUpdated or love.timer.getTime())
 self._lastUpdated = love.timer.getTime()
 self._simulateData_future = real
 self._simulateData_past = self._simulateData_past or real
 
 if not (CuCo.NetModule.Client.self and self == CuCo.NetModule.Client.self) then
  -- these run if this asset does not belong to this client
  if real.keyBuffer then self.keyBuffer = real.keyBuffer end
  if real.mouseBuffer then self.mouseBuffer = real.mouseBuffer end
  if real.eventBuffer then self.eventBuffer = real.eventBuffer end
 end
 if (CuCo.NetModule.Client.self and self == CuCo.NetModule.Client.self) then
  -- these run if this asset does belong to this client
  if real.vec3 then
   love.audio.setPosition( real.vec3[1], real.vec3[2], 64 )
  end
 end
 --these run regardless
 self.torch_isOn = real.torch_isOn
 self.model:setVar("torch_isOn",real.torch_isOn)
 
 self.charge = real.charge
 self.model:setVar("charge",real.charge)
 
 if real.animMode then
  self.model:setVar("mode",real.animMode)
 end
 
 if real.vec3 then 
  self.vec3 = real.vec3
  self.camera = {self.vec3[1],self.vec3[2]}
 end
 if real.weapon then
  self.weapon = CuCo._RESERVED.MOD_DATABASE_PROXY.BUILD[real.weapon]
 end
end

function asset:updateFromClient(proxy)
 --serverside!
 if proxy.keyBuffer then
  self.keyBuffer = Utils.deepcopy(proxy.keyBuffer)
 end
 if proxy.mouseBuffer then
  self.mouseBuffer = Utils.deepcopy(proxy.mouseBuffer)
 end
 if proxy.eventBuffer then
  self.eventBuffer = Utils.deepcopy(proxy.eventBuffer)
  proxy.eventBuffer = nil
  --detect events and fire :
  self:eventParser()
 end
end

function asset:eventParser()
 while #self.eventBuffer >= 1 do
  CuCo.NetModule.Core.eventParser(self,self.eventBuffer[1])
  table.remove(self.eventBuffer,1)
 end
end

function asset:initCurseClient()
 self.CurseClient = {}
 self.CurseClient.Uname = "unknown"
end

function asset:getRenderData()
 return self.renderData
end

function asset:setName(Uname)
 self.CurseClient.Uname = Uname
end

function asset:destroyProxy()
 CuCo.debugModule.dump("[DEBUG] destroying model.")
 self.model:destroyLaS()
 CuCo.EngineModule.data.Events["onDraw"]:removeHook(self.drawHook)
end

function asset:destroy()
 self.physics.fixture:destroy()
 
 for k,v in pairs(self.inventory) do
  if k ~= "selected" then
   CuCo.AssetModule.destroyAsset(v)
  end
 end
 self.inventory.selected = nil
 
 CuCo.EngineModule.data.Events["onUpdate"]:removeHook(self.updateHook)
end

function asset:myFunction()
 --
end

return asset

