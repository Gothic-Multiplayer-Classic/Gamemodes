local Visuals = require('shared.visuals')

local CharacterCreation = {
  visible = false,
  confirmed = false,
  selectedField = 2,
  headIndex = 4,
  skinTexture = Visuals.default.bodyTexture,
  faceTexture = Visuals.default.headTexture,
  savedCameraMovement = nil,
  savedCameraModeChange = nil
}

local pendingShow = false
local pendingVisual = nil
local pendingPreview = false
local weaponModeNone = NPC_WEAPON_NONE or 0
local cameraDistance = 250.0
local cameraHeight = 70.0

local controls = Draw.new(0, 0, 'Controls: UP/DOWN/A/D/RETURN')
local title = Draw.new(0, 150, 'Appearance')
local headLabel = Draw.new(0, 300, 'Head:')
local headValue = Draw.new(0, 300, '')
local faceLabel = Draw.new(0, 450, 'Face:')
local faceValue = Draw.new(0, 450, '')
local skinLabel = Draw.new(0, 600, 'Skin:')
local skinValue = Draw.new(0, 600, '')

local rows = {
  { label = headLabel, value = headValue },
  { label = faceLabel, value = faceValue },
  { label = skinLabel, value = skinValue }
}

local draws = {
  controls,
  title,
  headLabel,
  headValue,
  faceLabel,
  faceValue,
  skinLabel,
  skinValue
}

for _, draw in ipairs(draws) do
  draw:setFont('FONT_DEFAULT.TGA')
  draw:setColor(255, 255, 255)
  draw:setVisible(false)
end

local function alignValue(label, value)
  local pos = label:getPosition()
  value:setPosition(pos.x + label:getWidth() + 120, pos.y)
end

alignValue(headLabel, headValue)
alignValue(faceLabel, faceValue)
alignValue(skinLabel, skinValue)

local function clamp(value, minimum, maximum)
  value = math.floor(tonumber(value) or minimum)

  if value < minimum then
    return minimum
  end

  if value > maximum then
    return maximum
  end

  return value
end

local function findHeadIndex(model)
  for index, head in ipairs(Visuals.headModels) do
    if head.model == model then
      return index
    end
  end

  return CharacterCreation.headIndex
end

local function updateScene()
  local position = Visuals.position
  setPlayerPosition(heroId, position.x, position.y, position.z)
  setPlayerAngle(heroId, position.angle or 180)
  setPlayerOnFloor(heroId)

  local playerPos = getPlayerPosition(heroId)
  local angle = position.angle or 180
  local radians = (math.pi / 180) * angle
  local cameraX = playerPos.x + cameraDistance * math.sin(radians)
  local cameraZ = playerPos.z + cameraDistance * math.cos(radians)

  Camera.setPosition(cameraX, playerPos.y + cameraHeight, cameraZ)
  Camera.setRotation(0, angle + 180, 0)
end

function CharacterCreation:visual()
  local head = Visuals.headModels[self.headIndex] or Visuals.headModels[1]

  return {
    bodyModel = Visuals.bodyModel,
    bodyTexture = self.skinTexture,
    headModel = head.model,
    headTexture = self.faceTexture,
    teethTexture = Visuals.teethTexture,
    skinColor = Visuals.skinColor
  }
end

function CharacterCreation:setVisual(visual)
  if visual == nil then
    visual = Visuals.default
  end

  self.headIndex = findHeadIndex(visual.headModel or Visuals.default.headModel)
  self.skinTexture = clamp(tonumber(visual.bodyTexture) or Visuals.default.bodyTexture, Visuals.skinTexture.min, Visuals.skinTexture.max)
  self.faceTexture = clamp(tonumber(visual.headTexture) or Visuals.default.headTexture, Visuals.faceTexture.min, Visuals.faceTexture.max)
end

function CharacterCreation:preview()
  if heroId == nil then
    return
  end

  local visual = self:visual()
  local head = Visuals.headModels[self.headIndex] or Visuals.headModels[1]

  headValue:setText(head.label .. ' (' .. tostring(self.headIndex - 1) .. ')')
  faceValue:setText(tostring(self.faceTexture))
  skinValue:setText(tostring(self.skinTexture))

  for index, row in ipairs(rows) do
    local r, g, b = 255, 255, 255
    if index == self.selectedField then
      r, g, b = 0, 255, 0
    end

    row.label:setColor(r, g, b)
    row.value:setColor(r, g, b)
  end

  updateScene()
  setPlayerWeaponMode(heroId, weaponModeNone)
  clearInventory(heroId)
  setPlayerVisual(
    heroId,
    visual.bodyModel,
    visual.bodyTexture,
    visual.headModel,
    visual.headTexture,
    visual.teethTexture,
    visual.skinColor
  )
end

function CharacterCreation:show(visual)
  if visual ~= nil then
    pendingVisual = visual
  end

  if self.confirmed or self.visible then
    pendingShow = false
    return
  end

  if heroId == nil or getPlayerPosition(heroId) == nil then
    pendingShow = true
    return
  end

  pendingShow = false
  self.visible = true
  self.savedCameraMovement = Camera.movementEnabled
  self.savedCameraModeChange = Camera.modeChangeEnabled

  if pendingVisual ~= nil then
    self:setVisual(pendingVisual)
    pendingVisual = nil
  end

  disableControls(true)
  setHudMode(HUD_ALL, HUD_MODE_HIDDEN)
  Camera.movementEnabled = false
  Camera.modeChangeEnabled = false

  for _, draw in ipairs(draws) do
    draw:setVisible(true)
  end

  self:preview()
end

function CharacterCreation:hide()
  if not self.visible then
    return
  end

  self.visible = false

  for _, draw in ipairs(draws) do
    draw:setVisible(false)
  end

  disableControls(false)
  setHudMode(HUD_ALL, HUD_MODE_DEFAULT)
  Camera.movementEnabled = self.savedCameraMovement ~= false
  Camera.modeChangeEnabled = self.savedCameraModeChange ~= false
end

function CharacterCreation:previousField()
  if self.selectedField > 1 then
    self.selectedField = self.selectedField - 1
    pendingPreview = true
  end
end

function CharacterCreation:nextField()
  if self.selectedField < #rows then
    self.selectedField = self.selectedField + 1
    pendingPreview = true
  end
end

function CharacterCreation:decrease()
  if self.selectedField == 1 and self.headIndex > 1 then
    self.headIndex = self.headIndex - 1
  elseif self.selectedField == 2 and self.faceTexture > Visuals.faceTexture.min then
    self.faceTexture = self.faceTexture - 1
  elseif self.selectedField == 3 and self.skinTexture > Visuals.skinTexture.min then
    self.skinTexture = self.skinTexture - 1
  end

  pendingPreview = true
end

function CharacterCreation:increase()
  if self.selectedField == 1 and self.headIndex < #Visuals.headModels then
    self.headIndex = self.headIndex + 1
  elseif self.selectedField == 2 and self.faceTexture < Visuals.faceTexture.max then
    self.faceTexture = self.faceTexture + 1
  elseif self.selectedField == 3 and self.skinTexture < Visuals.skinTexture.max then
    self.skinTexture = self.skinTexture + 1
  end

  pendingPreview = true
end

function CharacterCreation:choose()
  if heroId == nil then
    return
  end

  self.confirmed = true
  self:hide()
  triggerServerEvent('classic:saveVisual', heroId, self:visual())
end

addEvent('classic:startCharacterCreation', true)
addEventHandler('classic:startCharacterCreation', function(playerId, visual)
  if heroId ~= nil and playerId ~= nil and tonumber(playerId) ~= tonumber(heroId) then
    return
  end

  CharacterCreation.confirmed = false
  CharacterCreation:show(visual)
end)

addEvent('classic:visualRejected', true)
addEventHandler('classic:visualRejected', function(playerId, visual)
  if heroId ~= nil and playerId ~= nil and tonumber(playerId) ~= tonumber(heroId) then
    return
  end

  CharacterCreation.confirmed = false
  CharacterCreation:show(visual)
end)

addEventHandler('onWorldEnter', function()
  if CharacterCreation.visible then
    CharacterCreation:preview()
  end
end)

addEventHandler('onRender', function()
  if pendingShow then
    CharacterCreation:show()
  end

  if CharacterCreation.visible and heroId ~= nil then
    updateScene()
  end

  if CharacterCreation.visible and pendingPreview then
    pendingPreview = false
    CharacterCreation:preview()
  end
end)

addEventHandler('onKeyDown', function(key)
  if not CharacterCreation.visible then
    return
  end

  if key == KEY_UP then
    CharacterCreation:previousField()
  elseif key == KEY_DOWN then
    CharacterCreation:nextField()
  elseif key == KEY_A or key == KEY_LEFT then
    CharacterCreation:decrease()
  elseif key == KEY_D or key == KEY_RIGHT then
    CharacterCreation:increase()
  elseif key == KEY_RETURN then
    CharacterCreation:choose()
  elseif key == KEY_ESCAPE then
    exitGame()
  end

  cancelEvent()
end, 10000)

addEventHandler('onExit', function()
  CharacterCreation:hide()
end)

function onResourceStop()
  CharacterCreation:hide()
end

return CharacterCreation
