local Mod = {}
Mod.NAME = "NET"

function Mod.checkValid()
 return true
end

function Mod:onActivate()
 print("[NET] Activated")
 local channels = 8
 
 local path = self.path
 self.netSoundsPaths = {
  torch_click1 = path.."/sounds/torch/torch_one.mp3",
  torch_click2 = path.."/sounds/torch/torch_two.mp3",
  torch_click3 = path.."/sounds/torch/torch_three.mp3",
 }
 self.netSoundsSource = {}
 for k,v in pairs(self.netSoundsPaths) do
  self.netSoundsSource[k] = {}
  for i = 1,channels do
   table.insert(self.netSoundsSource[k],love.audio.newSource( v, "static"))
  end
 end
 print("[NET] Loaded Sounds")
end

function Mod.fgetOpenChannel(soundUID)
 local source = false
 for k,v in pairs(Mod.netSoundsSource[soundUID]) do
  if v:isStopped() then
   v:rewind()
   source = v
   break
  end
 end
 return source
end

function Mod.fspawnZeds(n)
 for i = 1,n or 1 do
  local Zed = CuCo.AssetModule.newInstance(CuCo._RESERVED.MOD_DATABASE_HOST.REG.NET.abbers.Zed)
  local spawnPos = CuCo.NetModule.Server.physics.world:randomPointIn("enemySpawns")
  spawnPos[3] = 0
  Zed.physics.body:setPosition(spawnPos[1],spawnPos[2])
 end
end


return Mod
