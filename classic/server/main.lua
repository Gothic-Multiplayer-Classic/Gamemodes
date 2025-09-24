local Classic = Classic
local Visuals = Classic.visuals

local visualStorePath = 'classic/players.json'
local selectedClassByPlayer = {}
local creatingVisualByPlayer = {}
local visualByPlayer = {}
local allowedHeadModels = {}

for _, head in ipairs(Visuals.headModels) do
  allowedHeadModels[head.model] = true
end

local function clampInt(value, minimum, maximum)
  value = math.floor(tonumber(value) or minimum)

  if value < minimum then
    return minimum
  end

  if value > maximum then
    return maximum
  end

  return value
end

local function normalizeVisual(visual)
  if type(visual) ~= 'table' then
    return nil
  end

  local bodyModel = visual.bodyModel
  local headModel = visual.headModel

  if bodyModel ~= Visuals.bodyModel or not allowedHeadModels[headModel] then
    return nil
  end

  return {
    bodyModel = bodyModel,
    bodyTexture = clampInt(visual.bodyTexture, Visuals.skinTexture.min, Visuals.skinTexture.max),
    headModel = headModel,
    headTexture = clampInt(visual.headTexture, Visuals.faceTexture.min, Visuals.faceTexture.max),
    teethTexture = Visuals.teethTexture,
    skinColor = Visuals.skinColor
  }
end

local function playerStoreKey(playerId)
  local playerUuid = getPlayerUUID(playerId)
  if playerUuid ~= nil and playerUuid ~= '' then
    return 'uuid:' .. playerUuid
  end

  local playerName = getPlayerName(playerId)
  if playerName ~= nil and playerName ~= '' then
    return 'name:' .. string.lower(playerName)
  end

  local playerIp = getPlayerIP(playerId)
  if playerIp ~= nil and playerIp ~= '' then
    return 'ip:' .. playerIp
  end

  return tostring(playerId)
end

local function loadPlayerVisual(playerId)
  local file = JSON(visualStorePath)
  if not file then
    return nil
  end

  return normalizeVisual(file:getItem(playerStoreKey(playerId)))
end

local function savePlayerVisual(playerId, visual)
  local file = JSON(visualStorePath)
  if not file then
    return false
  end

  file:setItem(playerStoreKey(playerId), visual)
  return true
end

local function applyVisual(playerId, visual)
  if visual == nil then
    return false
  end

  visualByPlayer[playerId] = visual

  return setPlayerVisual(
    playerId,
    visual.bodyModel,
    visual.bodyTexture,
    visual.headModel,
    visual.headTexture,
    visual.teethTexture,
    visual.skinColor
  )
end

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

local function giveEquipment(playerId, info)
  if info.armor ~= nil then
    equipArmor(playerId, info.armor)
  end

  if info.primary ~= nil then
    equipMeleeWeapon(playerId, info.primary)
  end

  if info.secondary ~= nil then
    equipRangedWeapon(playerId, info.secondary)
  end

  for _, item in ipairs(info.items or {}) do
    giveItem(playerId, item.instance, item.amount or 1)
    if (info.magicLevel or 0) > 0 and string.sub(item.instance, 1, 5) == 'ITRU_' then
      equipItem(playerId, item.instance)
    end
  end
end

local function preparePreviewPlayer(playerId)
  local spawn = Classic.selectorPlayerPosition

  setPlayerRespawnTime(playerId, 5000)
  setPlayerHealth(playerId, 500)
  setPlayerMaxHealth(playerId, 500)
  setPlayerMana(playerId, 500)
  setPlayerMaxMana(playerId, 500)
  setPlayerStrength(playerId, 300)
  setPlayerDexterity(playerId, 300)
  setPlayerVirtualWorld(playerId, Classic.previewVirtualWorldBase + playerId)
  setPlayerAngle(playerId, spawn.angle or 180)
  spawnPlayer(playerId, spawn.x, spawn.y, spawn.z)
end

local function startClassSelection(playerId, visual)
  creatingVisualByPlayer[playerId] = nil
  applyVisual(playerId, visual)
  triggerClientEvent(playerId, 'classic:startClassSelect', playerId, visual)
end

addEvent('classic:saveVisual', true)
addEvent('classic:selectClass', true)

addEventHandler('onPlayerConnect', function(playerId)
  selectedClassByPlayer[playerId] = nil
  creatingVisualByPlayer[playerId] = nil
  visualByPlayer[playerId] = nil

  preparePreviewPlayer(playerId)

  local visual = loadPlayerVisual(playerId)
  if visual ~= nil then
    startClassSelection(playerId, visual)
    return
  end

  visual = normalizeVisual(Visuals.default)
  creatingVisualByPlayer[playerId] = true
  applyVisual(playerId, visual)
  triggerClientEvent(playerId, 'classic:startCharacterCreation', playerId, visual)
end)

addEventHandler('classic:saveVisual', function(playerId, visual)
  playerId = tonumber(playerId)

  if playerId == nil or not isPlayerConnected(playerId) or selectedClassByPlayer[playerId] ~= nil or not creatingVisualByPlayer[playerId] then
    return
  end

  local normalized = normalizeVisual(visual)
  if normalized == nil then
    triggerClientEvent(playerId, 'classic:visualRejected', playerId, normalizeVisual(Visuals.default))
    return
  end

  savePlayerVisual(playerId, normalized)
  startClassSelection(playerId, normalized)
end)

addEventHandler('classic:selectClass', function(playerId, classId)
  playerId = tonumber(playerId)
  classId = tonumber(classId)

  if playerId == nil or classId == nil or selectedClassByPlayer[playerId] ~= nil or creatingVisualByPlayer[playerId] then
    return
  end

  local info = Classic.classes[classId + 1]
  if info == nil or not isPlayerConnected(playerId) then
    return
  end

  selectedClassByPlayer[playerId] = classId

  local spawn = info.spawn
  applyStats(playerId, info)
  applyVisual(playerId, visualByPlayer[playerId] or loadPlayerVisual(playerId))
  setPlayerPosition(playerId, spawn.x, spawn.y, spawn.z)
  setPlayerAngle(playerId, spawn.angle or 180)
  setPlayerVirtualWorld(playerId, 0)
  giveEquipment(playerId, info)

  local playerName = getPlayerName(playerId) or 'Player'
  sendMessageToAll(0, 255, 0, playerName .. ' joined to the game.')
  triggerClientEvent(playerId, 'classic:classSelected', playerId, classId)
end)

addEventHandler('onPlayerRespawn', function(playerId)
  local classId = selectedClassByPlayer[playerId]
  if classId == nil then
    return
  end

  local info = Classic.classes[classId + 1]
  if info == nil then
    return
  end

  local spawn = info.spawn
  applyVisual(playerId, visualByPlayer[playerId])
  setPlayerPosition(playerId, spawn.x, spawn.y, spawn.z)
  setPlayerAngle(playerId, spawn.angle or 180)
  setPlayerHealth(playerId, info.health or 0)
  setPlayerMana(playerId, info.mana or 0)
end)

addEventHandler('onPlayerMessage', function(playerId, message)
  if selectedClassByPlayer[playerId] == nil then
    cancelEvent()
    return
  end

  local color = getPlayerColor(playerId) or { r = 255, g = 255, b = 255 }
  local playerName = getPlayerName(playerId) or 'Player'
  sendPlayerMessageToAll(playerId, color.r, color.g, color.b, playerName .. ': ' .. message)
  cancelEvent()
end)

addEventHandler('onPlayerDisconnect', function(playerId)
  selectedClassByPlayer[playerId] = nil
  creatingVisualByPlayer[playerId] = nil
  visualByPlayer[playerId] = nil
end)
