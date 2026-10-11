local Visuals = require('shared.visuals')

local CharacterCreation = {
  visible = false,
  waiting = false,
  selectedField = 1,
  bodyIndex = 1,
  headIndex = 4,
  faceTexture = Visuals.default.headTexture,
  skinTexture = Visuals.default.bodyTexture,
  walkingOverlayIndex = 1
}

local controls = Draw.new(0, 0, 'Controls: UP/DOWN/A/D/RETURN')
local title = Draw.new(0, 150, 'Appearance')
local fields = {
  Draw.new(0, 300, ''),
  Draw.new(0, 450, ''),
  Draw.new(0, 600, ''),
  Draw.new(0, 750, ''),
  Draw.new(0, 900, '')
}
CharacterCreation.status = Draw.new(0, 1050, '')
local draws = { controls, title, fields[1], fields[2], fields[3], fields[4], fields[5], CharacterCreation.status }

-- Body, head profile, face close-up, skin and walking views.
local cameras = {
  { angle = 0, distance = 260, height = 30 },
  { angle = 90, distance = 105, height = 80 },
  { angle = 0, distance = 140, height = 70 },
  { angle = 0, distance = 260, height = 30 },
  { angle = 45, distance = 300, height = 25 }
}

for _, draw in ipairs(draws) do
  draw:setFont('FONT_DEFAULT.TGA')
  draw:setColor(255, 255, 255)
  draw:setVisible(false)
end

function CharacterCreation:visual()
  return {
    bodyModel = Visuals.bodyModels[self.bodyIndex].model,
    bodyTexture = self.skinTexture,
    headModel = Visuals.headModels[self.headIndex].model,
    headTexture = self.faceTexture,
    teethTexture = Visuals.teethTexture,
    skinColor = Visuals.skinColor,
    walkingOverlay = Visuals.walkingOverlays[self.walkingOverlayIndex].overlay
  }
end

function CharacterCreation:show(visual)
  visual = visual or Visuals.default
  self.bodyIndex = 1
  self.headIndex = 4
  self.faceTexture = math.floor(visual.headTexture)
  self.skinTexture = math.floor(visual.bodyTexture)
  self.walkingOverlayIndex = 1
  self.position = nil
  for index, body in ipairs(Visuals.bodyModels) do
    if body.model == visual.bodyModel then
      self.bodyIndex = index
      break
    end
  end
  for index, head in ipairs(Visuals.headModels) do
    if head.model == visual.headModel then
      self.headIndex = index
      break
    end
  end
  local walkingOverlay = Visuals.normalizeWalkingOverlay(visual.walkingOverlay or '')
  for index, walk in ipairs(Visuals.walkingOverlays) do
    if walk.overlay == walkingOverlay then
      self.walkingOverlayIndex = index
      break
    end
  end
  self.visible = true
  self.waiting = false
  self.changed = true
  self.status:setText('')
  for _, draw in ipairs(draws) do
    draw:setVisible(true)
  end
end

function CharacterCreation:hide()
  self.visible = false
  self.waiting = false
  self.changed = false
  self.position = nil
  if heroId ~= nil and self.walking then
    stopAni(heroId, 'S_WALKL')
  end
  self.walking = false
  for _, draw in ipairs(draws) do
    draw:setVisible(false)
  end
end

function CharacterCreation:preview()
  local visual = self:visual()
  stopAni(heroId, 'S_WALKL')
  self.walking = false
  Visuals.applyWalkingOverlay(heroId, '')
  setPlayerVisual(heroId, visual.bodyModel, visual.bodyTexture, visual.headModel,
    visual.headTexture, visual.teethTexture, visual.skinColor)
  if visual.walkingOverlay ~= '' then
    applyPlayerOverlay(heroId, visual.walkingOverlay)
  end

  fields[1]:setText('Body: ' .. Visuals.bodyModels[self.bodyIndex].label)
  fields[2]:setText('Head: ' .. Visuals.headModels[self.headIndex].label)
  fields[3]:setText(string.format('Face: %d', self.faceTexture))
  fields[4]:setText(string.format('Skin: %d', self.skinTexture))
  fields[5]:setText('Walking: ' .. Visuals.walkingOverlays[self.walkingOverlayIndex].label)
  for index, draw in ipairs(fields) do
    if index == self.selectedField then
      draw:setColor(0, 255, 0)
    else
      draw:setColor(255, 255, 255)
    end
  end
end

function CharacterCreation:choose()
  self.waiting = true
  self.status:setText('Saving appearance... RETURN to retry.')
  if not triggerServerEvent('classic:saveVisual', nil, heroId, self:visual()) then
    self.waiting = false
    self.status:setText('Could not send appearance. Press RETURN to retry.')
  end
end

addEventHandler('onRender', function()
  if not CharacterCreation.visible or heroId == nil or getPlayerPosition(heroId) == nil then
    return
  end

  if CharacterCreation.changed then
    CharacterCreation:preview()
    CharacterCreation.changed = false
  end

  if CharacterCreation.position == nil then
    local position = Visuals.position
    setPlayerPosition(heroId, position.x, position.y, position.z)
    setPlayerAngle(heroId, position.angle)
    setPlayerOnFloor(heroId)
    local grounded = getPlayerPosition(heroId)
    if grounded == nil then return end
    CharacterCreation.position = { x = grounded.x, y = grounded.y, z = grounded.z }
  end

  if CharacterCreation.selectedField == 5 and not CharacterCreation.walking then
    CharacterCreation.walking = playAni(heroId, 'S_WALKL')
  end

  -- Like GMP 0.2b: play S_WALKL and reset the position each frame.
  local position = CharacterCreation.position
  setPlayerPosition(heroId, position.x, position.y, position.z)
  setPlayerAngle(heroId, Visuals.position.angle)

  local camera = cameras[CharacterCreation.selectedField]
  local angle = Visuals.position.angle + camera.angle
  local radians = math.rad(angle)
  Camera.setPosition(position.x + camera.distance * math.sin(radians),
    position.y + camera.height, position.z + camera.distance * math.cos(radians))
  Camera.setRotation(0, angle + 180, 0)
end)

addEventHandler('onKeyDown', function(key)
  if not CharacterCreation.visible or heroId == nil then
    return
  end

  if key == KEY_RETURN then
    CharacterCreation:choose()
  elseif key == KEY_ESCAPE then
    exitGame()
  elseif not CharacterCreation.waiting then
    if key == KEY_UP then
      CharacterCreation.selectedField = (CharacterCreation.selectedField - 2) % #fields + 1
    elseif key == KEY_DOWN then
      CharacterCreation.selectedField = CharacterCreation.selectedField % #fields + 1
    elseif key == KEY_A or key == KEY_LEFT or key == KEY_D or key == KEY_RIGHT then
      local change = (key == KEY_A or key == KEY_LEFT) and -1 or 1
      if CharacterCreation.selectedField == 1 then
        CharacterCreation.bodyIndex = (CharacterCreation.bodyIndex - 1 + change) % #Visuals.bodyModels + 1
      elseif CharacterCreation.selectedField == 2 then
        CharacterCreation.headIndex = (CharacterCreation.headIndex - 1 + change) % #Visuals.headModels + 1
      elseif CharacterCreation.selectedField == 3 then
        CharacterCreation.faceTexture = Visuals.faceTexture.min + (CharacterCreation.faceTexture - Visuals.faceTexture.min
          + change) % (Visuals.faceTexture.max - Visuals.faceTexture.min + 1)
      elseif CharacterCreation.selectedField == 4 then
        CharacterCreation.skinTexture = Visuals.skinTexture.min + (CharacterCreation.skinTexture - Visuals.skinTexture.min
          + change) % (Visuals.skinTexture.max - Visuals.skinTexture.min + 1)
      else
        CharacterCreation.walkingOverlayIndex = (CharacterCreation.walkingOverlayIndex - 1 + change)
          % #Visuals.walkingOverlays + 1
      end
    end
    CharacterCreation.changed = true
  end
  cancelEvent()
end)

return CharacterCreation
