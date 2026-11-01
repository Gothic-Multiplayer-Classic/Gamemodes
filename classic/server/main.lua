local players = {}

setVoiceRange(Classic.voiceRange)
setVoiceEnabled(true)

local function applyStats(playerId, info)
  local skills = info.skills or {}

  setPlayerStrength(playerId, info.strength or 0)
  setPlayerDexterity(playerId, info.dexterity or 0)
  setPlayerMaxHealth(playerId, info.health or 0)
  setPlayerHealth(playerId, info.health or 0)
  setPlayerMaxMana(playerId, info.mana or 0)
  setPlayerMana(playerId, info.mana or 0)

  setPlayerSkillWeapon(playerId, WEAPON_1H, skills[WEAPON_1H] or 0)
  setPlayerSkillWeapon(playerId, WEAPON_2H, skills[WEAPON_2H] or 0)
  setPlayerSkillWeapon(playerId, WEAPON_BOW, skills[WEAPON_BOW] or 0)
  setPlayerSkillWeapon(playerId, WEAPON_CBOW, skills[WEAPON_CBOW] or 0)

  setPlayerTalent(playerId, TALENT_1H, math.floor((skills[WEAPON_1H] or 0) / 30))
  setPlayerTalent(playerId, TALENT_2H, math.floor((skills[WEAPON_2H] or 0) / 30))
  setPlayerTalent(playerId, TALENT_BOW, math.floor((skills[WEAPON_BOW] or 0) / 30))
  setPlayerTalent(playerId, TALENT_CROSSBOW, math.floor((skills[WEAPON_CBOW] or 0) / 30))
  setPlayerTalent(playerId, TALENT_MAGE, info.magicLevel or 0)
  setPlayerTalent(playerId, TALENT_ACROBATIC, info.acrobatics or 0)
  setPlayerTalent(playerId, TALENT_SNEAK, info.sneaking or 0)
  setPlayerTalent(playerId, TALENT_PICK_LOCKS, info.lockpicking or 0)
  setPlayerTalent(playerId, TALENT_PICKPOCKET, info.pickpocket or 0)
end

local function equipClass(playerId, class)
  if class.armor then equipArmor(playerId, class.armor) end
  if class.primary then equipMeleeWeapon(playerId, class.primary) end
  if class.secondary then equipRangedWeapon(playerId, class.secondary) end
end

local function clearShowcase(playerId)
  local player = players[playerId]
  if player.preview == nil then return end
  local class = Classic.classes[player.preview]

  setPlayerWeaponMode(playerId, WEAPONMODE_NONE)
  unequipArmor(playerId)
  unequipMeleeWeapon(playerId)
  unequipRangedWeapon(playerId)
  for _, slot in ipairs({ 'armor', 'primary', 'secondary' }) do
    if class[slot] then removeItem(playerId, class[slot], 1) end
  end
  player.preview = nil
end

local function showClass(playerId, classId)
  local player = players[playerId]
  local class = Classic.classes[classId]
  if player.preview ~= classId then
    clearShowcase(playerId)
    equipClass(playerId, class)
    player.preview = classId
  end
  local spawn = class.spawn
  setPlayerPosition(playerId, spawn.x, spawn.y, spawn.z)
  setPlayerAngle(playerId, spawn.angle)
end

local function sendPlayers(playerId)
  local classes = {}
  local targets = {}
  for id, player in pairs(players) do
    if player.class ~= nil then
      classes[id] = player.class
    end
    if playerId == nil or playerId == id then
      targets[#targets + 1] = id
    end
  end
  if #targets > 0 then
    triggerClientEvent(targets, 'classic:players', nil, classes)
  end
end

local function showSelection(playerId)
  local player = players[playerId]
  if player.class ~= nil then
    triggerClientEvent(playerId, 'classic:classSelected', { sourceId = playerId }, player.class - 1, getPlayerName(playerId))
  else
    if player.preview == nil then showClass(playerId, 1) end
    triggerClientEvent(playerId, 'classic:startClassSelect', { sourceId = playerId })
  end
  sendPlayers(playerId)
end

addEventHandler('onPlayerConnect', function(playerId)
  players[playerId] = {}

  local position = Classic.classes[1].spawn
  setVoiceEnabledForPlayer(playerId, false)
  setPlayerRespawnTime(playerId, 5000)
  setPlayerMaxHealth(playerId, 500)
  setPlayerHealth(playerId, 500)
  setPlayerMaxMana(playerId, 500)
  setPlayerMana(playerId, 500)
  setPlayerStrength(playerId, 300)
  setPlayerDexterity(playerId, 300)
  setPlayerVirtualWorld(playerId, Classic.previewVirtualWorldBase + playerId)
  spawnPlayer(playerId, position.x, position.y, position.z)
  showSelection(playerId)
end)

addEvent('classic:requestSelection', true)
addEvent('classic:previewClass', true)
addEvent('classic:selectClass', true)

-- The sender is authenticated by the server; payloads never select the requesting player.
addEventHandler('classic:requestSelection', function(context)
  if not context.remote then return end
  local playerId = context.senderPlayerId
  if players[playerId] then showSelection(playerId) end
end)

addEventHandler('classic:previewClass', function(context, classId)
  if not context.remote then return end
  local playerId = context.senderPlayerId
  local player = players[playerId]
  if player == nil or player.class ~= nil then return end
  if type(classId) ~= 'number' or classId % 1 ~= 0 or Classic.classes[classId + 1] == nil then return end
  showClass(playerId, classId + 1)
end)

addEventHandler('classic:selectClass', function(context, classId)
  if not context.remote then return end
  local playerId = context.senderPlayerId
  local player = players[playerId]
  if player == nil then return end
  if player.class ~= nil then
    showSelection(playerId)
    return
  end
  if type(classId) ~= 'number' or classId % 1 ~= 0 or Classic.classes[classId + 1] == nil then
    triggerClientEvent(playerId, 'classic:classRejected', { sourceId = playerId })
    return
  end

  local class = Classic.classes[classId + 1]
  clearShowcase(playerId)
  applyStats(playerId, class)
  setPlayerPosition(playerId, class.spawn.x, class.spawn.y, class.spawn.z)
  setPlayerAngle(playerId, class.spawn.angle)
  setPlayerVirtualWorld(playerId, 0)
  equipClass(playerId, class)
  for _, item in ipairs(class.items or {}) do
    giveItem(playerId, item.instance, item.amount or 1)
    if (class.magicLevel or 0) > 0 and item.instance:sub(1, 5) == 'ITRU_' then
      equipItem(playerId, item.instance)
    end
  end
  player.class = classId + 1
  setVoiceEnabledForPlayer(playerId, true)
  showSelection(playerId)
  sendPlayers()
  sendMessageToAll(0, 255, 0, getPlayerName(playerId) .. ' joined the game.')
end)

addEventHandler('onPlayerRespawn', function(playerId)
  local player = players[playerId]
  if player == nil or player.class == nil then return end
  local class = Classic.classes[player.class]
  setPlayerPosition(playerId, class.spawn.x, class.spawn.y, class.spawn.z)
  setPlayerAngle(playerId, class.spawn.angle)
  setPlayerHealth(playerId, class.health)
  setPlayerMana(playerId, class.mana)
end)

addEventHandler('onPlayerMessage', function(playerId, message)
  local player = players[playerId]
  if player ~= nil and player.class ~= nil then
    local color = getPlayerNameColor(playerId)
    sendPlayerMessageToAll(playerId, color.r, color.g, color.b, getPlayerName(playerId) .. ': ' .. message)
  end
  cancelEvent()
end)

addEventHandler('onPlayerDisconnect', function(playerId)
  local message = getPlayerName(playerId) .. ' left the game.'
  players[playerId] = nil
  for id in pairs(players) do
    sendMessageToPlayer(id, 255, 0, 0, message)
  end
  sendPlayers()
end)

function onResourceStop()
  setVoiceEnabled(false)
end
