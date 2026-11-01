local players = {}
local phase, seconds = 'waiting', Zombie.awaitSeconds
local noZombieSeconds = 0
local rosterDirty = true
local pendingKillers = {}
local timers = {}
local loadoutItems = {}
local weaponTalents = {
  [WEAPON_1H] = TALENT_1H, [WEAPON_2H] = TALENT_2H,
  [WEAPON_BOW] = TALENT_BOW, [WEAPON_CBOW] = TALENT_CROSSBOW
}

for _, class in ipairs(Zombie.classes) do
  for _, slot in ipairs({ 'armor', 'melee', 'ranged' }) do
    if class[slot] then loadoutItems[class[slot]] = true end
  end
  for _, item in ipairs(class.items or {}) do loadoutItems[item.instance] = true end
end

local function announce(text, r, g, b)
  sendMessageToAll(r, g, b, text)
  triggerClientEvent(nil, 'zombie:announcement', nil, text, r, g, b, 5000)
end

local function sound(file, targetId, recipient)
  triggerClientEvent(recipient, 'zombie:sound', nil, file, targetId)
end

local function randomSound(files, targetId)
  if #files > 0 then sound(files[math.random(#files)], targetId) end
end

local function counts()
  local humans, zombies, joined = 0, 0, 0
  for _, player in pairs(players) do
    if player.joined then
      joined = joined + 1
      if player.alive then
        if player.team == 'human' then humans = humans + 1 else zombies = zombies + 1 end
      end
    end
  end
  return humans, zombies, joined
end

local function sendPlayers(recipient)
  if recipient == nil and not rosterDirty then return end
  local roster = {}
  for id, player in pairs(players) do
    roster[id] = {
      classId = player.actualClass, team = player.team,
      joined = player.joined, alive = player.alive
    }
  end
  triggerClientEvent(recipient, 'zombie:players', nil, roster)
  if recipient == nil then rosterDirty = false end
end

local function sendState(recipient)
  local humans, zombies = counts()
  triggerClientEvent(recipient, 'zombie:state', nil, phase, seconds, humans, zombies)
  sendPlayers(recipient)
end

local function sendSelection(id)
  local player = players[id]
  triggerClientEvent(id, 'zombie:selection', { sourceId = id }, player.joined,
    player.chosenClass or player.previewClass, player.team)
end

local function clearLoadout(id)
  setPlayerWeaponMode(id, WEAPONMODE_NONE)
  unequipArmor(id)
  unequipMeleeWeapon(id)
  unequipRangedWeapon(id)
  -- The server has no inventory iterator. Pickups and drops are blocked below,
  -- so every item owned by this mode is present in this finite set.
  for instance in pairs(loadoutItems) do
    local amount = hasItem(id, instance)
    if amount > 0 then removeItem(id, instance, amount) end
  end
end

local function applyClass(id, classId)
  local class = Zombie.classes[classId]
  clearLoadout(id)
  setPlayerInstance(id, class.instance)
  if class.visual then
    local visual = class.visual
    setPlayerVisual(id, visual.bodyModel, visual.bodyTexture, visual.headModel, visual.headTexture)
  end
  setPlayerMaxHealth(id, class.health)
  setPlayerHealth(id, class.health)
  setPlayerMaxMana(id, 0)
  setPlayerMana(id, 0)
  setPlayerStrength(id, class.strength)
  setPlayerDexterity(id, class.dexterity or 0)
  for weapon, talent in pairs(weaponTalents) do
    local skill = (class.skills or {})[weapon] or 0
    setPlayerSkillWeapon(id, weapon, skill)
    setPlayerTalent(id, talent, math.min(2, math.floor(skill / 30)))
  end
  setPlayerTalent(id, TALENT_ACROBATIC, class.acrobatics or 0)
  setPlayerTalent(id, TALENT_MAGE, 0)
  if class.armor then equipArmor(id, class.armor) end
  if class.melee then equipMeleeWeapon(id, class.melee) end
  if class.ranged then equipRangedWeapon(id, class.ranged) end
  for _, item in ipairs(class.items or {}) do giveItem(id, item.instance, item.amount) end
  setPlayerWeaponMode(id, WEAPONMODE_NONE)
end

local function place(id, point)
  setPlayerPosition(id, point.x, point.y, point.z)
  setPlayerAngle(id, point.angle)
end

local function spawnAs(id, team)
  local player = players[id]
  local classId = player.chosenClass
  if Zombie.classes[classId].team ~= team then
    local previous = player.actualClass and Zombie.classes[player.actualClass]
    classId = previous and previous.team == team and player.actualClass
      or (team == 'human' and math.random(5, 8) or math.random(1, 4))
  end
  player.applying = true
  pendingKillers[id] = nil
  player.team, player.actualClass = team, classId
  rosterDirty = true
  setPlayerVirtualWorld(id, Zombie.virtualWorld)
  if isPlayerDead(id) then respawnPlayer(id) end
  applyClass(id, classId)
  -- Instance constructors can overwrite protection and weapon mode defaults.
  setPlayerInvulnerable(id, phase ~= 'active')
  setPlayerWeaponMode(id, phase == 'active' and team == 'zombie' and WEAPONMODE_FIST or WEAPONMODE_NONE)
  local spawns = team == 'human' and Zombie.humanSpawns or Zombie.zombieSpawns
  place(id, spawns[math.random(#spawns)])
  setPlayerNameColor(id, team == 'human' and 0 or 255, team == 'human' and 255 or 0, 0)
  player.alive, player.applying = true, false
  sendSelection(id)
end

local function beginWaiting()
  phase, seconds, noZombieSeconds = 'waiting', Zombie.awaitSeconds, 0
  local participants = {}
  for id, player in pairs(players) do
    if player.joined then participants[#participants + 1] = id end
  end
  local zombieId = #participants > 1 and participants[math.random(#participants)] or nil
  for id, player in pairs(players) do
    if player.joined then spawnAs(id, id == zombieId and 'zombie' or 'human') end
  end
  sendState()
end

local function choosePlayerForTeam(team)
  local candidates = {}
  for id, player in pairs(players) do
    if player.joined and player.alive and player.team ~= team then
      candidates[#candidates + 1] = id
    end
  end
  if #candidates == 0 then return false end
  local id = candidates[math.random(#candidates)]
  spawnAs(id, team)
  announce(getPlayerName(id) .. ' was assigned to the ' .. team .. ' team.', 255, 255, 0)
  return true
end

local function finishRound(humansWin)
  if humansWin then
    announce('Humans survived the zombie attack!', 0, 255, 0)
    sound(Zombie.sounds.humansWin)
  else
    announce('The zombies have infected all humans!', 255, 0, 0)
    sound(Zombie.sounds.zombiesWin)
  end
  beginWaiting()
end

local function connect(id)
  if players[id] then return end
  players[id] = {
    joined = false, alive = false, previewClass = 5,
    respawnTime = getPlayerRespawnTime(id), invulnerable = isPlayerInvulnerable(id)
  }
  rosterDirty = true
  local player = players[id]
  player.applying = true
  setPlayerRespawnTime(id, Zombie.respawnMs)
  if getPlayerWorld(id) ~= Zombie.world then setPlayerWorld(id, Zombie.world) end
  setPlayerVirtualWorld(id, Zombie.previewVirtualWorldBase + id)
  applyClass(id, player.previewClass)
  setPlayerInvulnerable(id, true)
  if isPlayerSpawned(id) then
    if isPlayerDead(id) then respawnPlayer(id) end
    place(id, Zombie.preview)
  else
    spawnPlayer(id, Zombie.preview.x, Zombie.preview.y, Zombie.preview.z)
    setPlayerAngle(id, Zombie.preview.angle)
  end
  player.applying = false
  sendMessageToPlayer(id, 0, 255, 0, 'Zombie Mode by Risen. Choose a class with A/D and press RETURN.')
  sendSelection(id)
  sendState(id)
end

local function validClass(classId)
  return type(classId) == 'number' and classId % 1 == 0 and Zombie.classes[classId] ~= nil
end

local function sender(context)
  if type(context) ~= 'table' or not context.remote then return nil end
  local id = context.senderPlayerId
  if not players[id] or not isPlayerConnected(id) then return nil end
  return id
end

for _, name in ipairs({ 'zombie:ready', 'zombie:previewClass', 'zombie:selectClass' }) do
  addEvent(name, true)
end

addEventHandler('zombie:ready', function(context)
  local id = sender(context)
  if id == nil then return end
  sendSelection(id)
  sendState(id)
end)

addEventHandler('zombie:previewClass', function(context, classId)
  local id = sender(context)
  if id == nil or players[id].joined or not validClass(classId) then return end
  local player = players[id]
  if player.previewClass == classId then return end
  player.previewClass = classId
  applyClass(id, classId)
  setPlayerInvulnerable(id, true)
  place(id, Zombie.preview)
end)

addEventHandler('zombie:selectClass', function(context, classId)
  local id = sender(context)
  if id == nil or not validClass(classId) then return end
  local player = players[id]
  if player.joined then sendSelection(id); return end
  player.chosenClass, player.joined = classId, true
  local team = phase == 'active' and 'zombie' or Zombie.classes[classId].team
  spawnAs(id, team)
  if Zombie.classes[classId].team ~= team then
    sendMessageToPlayer(id, 255, 255, 0, 'The round has started. You joined the zombies.')
  end
  sound(Zombie.sounds.start, nil, id)
  sendState()
end)

addEventHandler('onPlayerConnect', connect)
addEventHandler('onPlayerDisconnect', function(id)
  players[id] = nil
  pendingKillers[id] = nil
  rosterDirty = true
  sendState()
end)

addEventHandler('onPlayerRespawn', function(id)
  local player = players[id]
  if not player or player.applying then return end
  if player.joined then
    spawnAs(id, phase == 'active' and 'zombie' or player.team)
  else
    applyClass(id, player.previewClass)
    setPlayerInvulnerable(id, true)
    place(id, Zombie.preview)
  end
  sendState()
end)

addEventHandler('onPlayerWorldEnter', function(id)
  local player = players[id]
  if not player or player.applying then return end
  if player.joined then
    local spawns = player.team == 'human' and Zombie.humanSpawns or Zombie.zombieSpawns
    place(id, spawns[math.random(#spawns)])
  else
    place(id, Zombie.preview)
  end
  sendSelection(id)
  sendState(id)
end)

local function killPlayer(id, killerId)
  if pendingKillers[id] then return end
  -- setPlayerHealth emits onPlayerDeath with a nil killer. Preserve the hit's sender.
  pendingKillers[id] = { id = killerId }
  setPlayerHealth(id, 0)
end

addEventHandler('onPlayerHit', function(attackerId, victimId, damage)
  local victim = players[victimId]
  local attacker = players[attackerId]
  if not victim then return end
  if phase ~= 'active' or not victim.joined or not victim.alive
    or (attackerId ~= nil and (not attacker or not attacker.joined or not attacker.alive)) then
    cancelEvent()
    return
  end
  -- Native PvP melee damage knocks players out. This mode requires actual deaths.
  if damage >= getPlayerHealth(victimId) then
    cancelEvent()
    killPlayer(victimId, attackerId)
  end
end)

addEventHandler('onPlayerUnconscious', function(attackerId, victimId)
  local victim = players[victimId]
  if not victim or not victim.joined or not victim.alive then return end
  if phase == 'active' then
    killPlayer(victimId, attackerId)
  else
    setPlayerHealth(victimId, Zombie.classes[victim.actualClass].health)
  end
end)

addEventHandler('onPlayerWeaponModeChange', function(id, _, mode)
  local player = players[id]
  if not player or player.applying then return end
  local allowed = phase == 'active' and player.joined and player.alive
  local required = allowed and player.team == 'zombie' and WEAPONMODE_FIST or WEAPONMODE_NONE
  if (not allowed or player.team == 'zombie') and mode ~= required then
    setPlayerWeaponMode(id, required)
  end
end)

addEventHandler('onPlayerDeath', function(id, killerId)
  local pending = pendingKillers[id]
  pendingKillers[id] = nil
  if pending then killerId = pending.id end
  local victim = players[id]
  if not victim or not victim.joined or not victim.alive then return end
  local victimTeam = victim.team
  victim.alive = false
  rosterDirty = true
  if victimTeam == 'human' then randomSound(Zombie.sounds.humanDeath, id) end
  if phase == 'active' then victim.team = 'zombie' end
  local killer = killerId ~= id and players[killerId] or nil
  if killer and killer.joined then
    if killer.team == 'human' and victimTeam == 'zombie' then
      randomSound(Zombie.sounds.humanKill, killerId)
    elseif killer.team == 'zombie' and victimTeam == 'human' then
      randomSound(Zombie.sounds.zombieKill, killerId)
      sendMessageToAll(255, 0, 0, getPlayerName(killerId) .. ' infected ' .. getPlayerName(id) .. '.')
    elseif killer.team == 'human' and victimTeam == 'human' and killer.alive then
      sendMessageToAll(255, 0, 0, getPlayerName(killerId) .. ' killed a teammate and was killed.')
      killPlayer(killerId, nil)
    end
  end
  sendState()
end)

addEventHandler('onPlayerMessage', function(id, message)
  local player = players[id]
  if player and player.joined then
    sendPlayerMessageToAll(id, player.team == 'human' and 0 or 255,
      player.team == 'human' and 255 or 0, 0, getPlayerName(id) .. ': ' .. message)
  end
  cancelEvent()
end)

for _, name in ipairs({ 'onPlayerTakeItem', 'onPlayerDropItem' }) do
  addEventHandler(name, function(id) if players[id] then cancelEvent() end end)
end

local function tick()
  local humans, zombies, joined = counts()
  if joined == 0 then
    phase, seconds, noZombieSeconds = 'waiting', Zombie.awaitSeconds, 0
  elseif phase == 'waiting' then
    if joined < Zombie.minPlayers then
      seconds = Zombie.awaitSeconds
    else
      seconds = math.max(0, seconds - 1)
      if seconds == 0 and humans + zombies >= Zombie.minPlayers then
        if zombies == 0 then choosePlayerForTeam('zombie') end
        if humans == 0 then choosePlayerForTeam('human') end
        humans, zombies = counts()
        if humans > 0 and zombies > 0 then
          phase, seconds, noZombieSeconds = 'active', Zombie.roundSeconds, 0
          for id, player in pairs(players) do
            if player.joined then
              setPlayerInvulnerable(id, false)
              setPlayerWeaponMode(id, player.team == 'zombie' and WEAPONMODE_FIST or WEAPONMODE_NONE)
            end
          end
          sound(Zombie.sounds.start)
        end
      end
    end
  elseif humans == 0 then
    finishRound(false)
  else
    seconds = math.max(0, seconds - 1)
    if seconds == 0 then
      finishRound(true)
    elseif zombies == 0 then
      noZombieSeconds = noZombieSeconds + 1
      if noZombieSeconds >= Zombie.noZombieSeconds then
        choosePlayerForTeam('zombie')
        noZombieSeconds = 0
      end
    else
      noZombieSeconds = 0
    end
  end
  sendState()
end

local function checkBoundary()
  local boundary = Zombie.fortBoundary
  for id, player in pairs(players) do
    if player.joined and player.alive and player.team == 'human' then
      local position = getPlayerPosition(id)
      if position then
        local dx, dy, dz = position.x - boundary.x, position.y - boundary.y, position.z - boundary.z
        if dx * dx + dy * dy + dz * dz <= boundary.radius * boundary.radius then
          place(id, boundary.destination)
          triggerClientEvent(id, 'zombie:announcement', nil, 'Defend the fort against the zombies!', 255, 255, 0, 5000)
        end
      end
    end
  end
end

function onResourceStart()
  if #timers > 0 then return end
  for _, id in ipairs(getOnlinePlayers()) do connect(id) end
  timers = { setTimer(tick, 1000, 0), setTimer(checkBoundary, 500, 0) }
end

function onResourceStop()
  for _, timer in ipairs(timers) do killTimer(timer) end
  timers = {}
  for id, player in pairs(players) do
    setPlayerInvulnerable(id, player.invulnerable)
    setPlayerRespawnTime(id, player.respawnTime)
    if not player.joined then setPlayerVirtualWorld(id, Zombie.virtualWorld) end
  end
end
