local Classic = require('shared.classes')
local Visuals = require('shared.visuals')

local ClassSelect = {
  selected = 1,
  visible = false,
  confirmed = false,
  savedCameraMovement = nil,
  savedCameraModeChange = nil
}

local pendingShow = false
local pendingPreview = false
local pendingVisual = nil
local weaponModeNone = NPC_WEAPON_NONE or 0
local showcaseDistance = 250.0
local showcaseHeight = 70.0

local controls = Draw.new(0, 0, 'Controls: A/D/RETURN')
local classLabel = Draw.new(0, 150, 'Class:')
local classValue = Draw.new(0, 150, '')
local descriptionLabel = Draw.new(0, 300, 'Description:')
local descriptionValue = Draw.new(0, 300, '')
local teamLabel = Draw.new(0, 450, 'Team:')
local teamValue = Draw.new(0, 450, '')

local draws = {
  controls,
  classLabel,
  classValue,
  descriptionLabel,
  descriptionValue,
  teamLabel,
  teamValue
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

alignValue(classLabel, classValue)
alignValue(descriptionLabel, descriptionValue)
alignValue(teamLabel, teamValue)

local function applyVisual(visual)
  if heroId == nil or visual == nil then
    return
  end

  setPlayerVisual(
    heroId,
    visual.bodyModel or Visuals.bodyModel,
    tonumber(visual.bodyTexture) or Visuals.default.bodyTexture,
    visual.headModel or Visuals.default.headModel,
    tonumber(visual.headTexture) or Visuals.default.headTexture,
    tonumber(visual.teethTexture) or Visuals.teethTexture,
    tonumber(visual.skinColor) or Visuals.skinColor
  )
end

local function updatePreview(info)
  local spawn = info.spawn
  setPlayerPosition(heroId, spawn.x, spawn.y, spawn.z)
  setPlayerAngle(heroId, spawn.angle or 180)
  setPlayerOnFloor(heroId)

  local playerPos = getPlayerPosition(heroId)
  local angle = spawn.angle or 180
  local radians = (math.pi / 180) * angle
  local cameraX = playerPos.x + showcaseDistance * math.sin(radians)
  local cameraZ = playerPos.z + showcaseDistance * math.cos(radians)

  Camera.setPosition(cameraX, playerPos.y + showcaseHeight, cameraZ)
  Camera.setRotation(0, angle + 180, 0)
end

function ClassSelect:preview()
  local info = Classic.classes[self.selected]
  if info == nil then
    return
  end

  classValue:setText(info.name)
  descriptionValue:setText(info.description)
  teamValue:setText(info.team)

  updatePreview(info)
  setPlayerWeaponMode(heroId, weaponModeNone)
  clearInventory()

  if info.armor ~= nil then
    equipArmor(heroId, info.armor)
  end

  if info.primary ~= nil then
    equipMeleeWeapon(heroId, info.primary)
  end

  if info.secondary ~= nil then
    equipRangedWeapon(heroId, info.secondary)
  end
end

function ClassSelect:show(visual)
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

  disableControls(true)
  setHudMode(HUD_ALL, HUD_MODE_HIDDEN)
  Camera.movementEnabled = false
  Camera.modeChangeEnabled = false

  if pendingVisual ~= nil then
    applyVisual(pendingVisual)
    pendingVisual = nil
  end

  for _, draw in ipairs(draws) do
    draw:setVisible(true)
  end

  self:preview()
end

function ClassSelect:hide()
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

function ClassSelect:previous()
  self.selected = self.selected - 1
  if self.selected < 1 then
    self.selected = #Classic.classes
  end

  pendingPreview = true
end

function ClassSelect:next()
  self.selected = self.selected + 1
  if self.selected > #Classic.classes then
    self.selected = 1
  end

  pendingPreview = true
end

function ClassSelect:choose()
  if heroId == nil then
    return
  end

  self.confirmed = true
  clearInventory()
  self:hide()
  triggerServerEvent('classic:selectClass', heroId, self.selected - 1)
end

addEvent('classic:startClassSelect', true)
addEventHandler('classic:startClassSelect', function(playerId, visual)
  if heroId ~= nil and playerId ~= nil and tonumber(playerId) ~= tonumber(heroId) then
    return
  end

  ClassSelect.confirmed = false
  ClassSelect.selected = 1
  ClassSelect:show(visual)
end)

addEvent('classic:classSelected', true)
addEventHandler('classic:classSelected', function(playerId)
  if heroId ~= nil and playerId ~= nil and tonumber(playerId) ~= tonumber(heroId) then
    return
  end

  ClassSelect.confirmed = true
  ClassSelect:hide()
end)

addEventHandler('onWorldEnter', function()
  if ClassSelect.visible then
    ClassSelect:preview()
  end
end)

addEventHandler('onRender', function()
  if pendingShow then
    ClassSelect:show()
  end

  if ClassSelect.visible and heroId ~= nil then
    local info = Classic.classes[ClassSelect.selected]
    if info ~= nil then
      updatePreview(info)
    end
  end

  if ClassSelect.visible and pendingPreview then
    pendingPreview = false
    ClassSelect:preview()
  end
end)

addEventHandler('onKeyDown', function(key)
  if not ClassSelect.visible then
    return
  end

  if key == KEY_A then
    ClassSelect:previous()
  elseif key == KEY_D then
    ClassSelect:next()
  elseif key == KEY_RETURN then
    ClassSelect:choose()
  elseif key == KEY_ESCAPE then
    exitGame()
  end

  cancelEvent()
end, 10000)

addEventHandler('onExit', function()
  ClassSelect:hide()
end)

function onResourceStop()
  ClassSelect:hide()
end

return ClassSelect
