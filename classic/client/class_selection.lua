local Classic = require('shared.classes')

local ClassSelect = {
  selected = 1,
  visible = false,
  waiting = false
}

local controls = Label.new(0, 0, 'Controls: A/D/RETURN')
local className = Label.new(0, 150, '')
local description = Label.new(0, 300, '')
local team = Label.new(0, 450, '')
ClassSelect.status = Label.new(0, 600, '')
local draws = { controls, className, description, team, ClassSelect.status }

for _, draw in ipairs(draws) do
  draw:setFont('FONT_DEFAULT.TGA')
  draw:setColor(255, 255, 255)
  draw:setVisible(false)
end

function ClassSelect:show()
  if not self.visible then
    self.selected = 1
  end
  self.visible = true
  self.waiting = false
  self.changed = true
  self.status:setText('')
  for _, draw in ipairs(draws) do
    draw:setVisible(true)
  end
end

function ClassSelect:hide()
  self.visible = false
  self.waiting = false
  self.changed = false
  for _, draw in ipairs(draws) do
    draw:setVisible(false)
  end
end

function ClassSelect:preview()
  local info = Classic.classes[self.selected]
  className:setText('Class: ' .. info.name)
  description:setText('Description: ' .. info.description)
  team:setText('Team: ' .. info.team)

  -- Showcase items must be owned by the server, or inventory sync removes them.
  if not triggerServerEvent('classic:previewClass', nil, self.selected - 1) then
    self.status:setText('Could not request showcase. Choose a class to retry.')
  end
end

function ClassSelect:choose()
  self.waiting = true
  self.status:setText('Joining the game... RETURN to retry.')
  if not triggerServerEvent('classic:selectClass', nil, self.selected - 1) then
    self.waiting = false
    self.status:setText('Could not send class. Press RETURN to retry.')
  end
end

addEventHandler('onRender', function()
  if not ClassSelect.visible or heroId == nil or getPlayerPosition(heroId) == nil then
    return
  end

  if ClassSelect.changed then
    ClassSelect:preview()
    ClassSelect.changed = false
  end

  local spawn = Classic.classes[ClassSelect.selected].spawn
  setPlayerPosition(heroId, spawn.x, spawn.y, spawn.z)
  setPlayerAngle(heroId, spawn.angle)
  setPlayerOnFloor(heroId)
  local position = getPlayerPosition(heroId)
  if position ~= nil then
    local radians = math.rad(spawn.angle)
    Camera:setPosition(position.x + 250 * math.sin(radians), position.y + 70,
      position.z + 250 * math.cos(radians))
    Camera:setRotationDegrees(0, spawn.angle + 180, 0)
  end
end)

addEventHandler('onKeyDown', function(key)
  if not ClassSelect.visible or heroId == nil then
    return
  end

  if key == KEY_RETURN then
    ClassSelect:choose()
  elseif key == KEY_ESCAPE then
    exitGame()
  elseif not ClassSelect.waiting then
    if key == KEY_A then
      ClassSelect.selected = (ClassSelect.selected - 2) % #Classic.classes + 1
      ClassSelect.changed = true
    elseif key == KEY_D then
      ClassSelect.selected = ClassSelect.selected % #Classic.classes + 1
      ClassSelect.changed = true
    end
  end
  cancelEvent()
end)

return ClassSelect
