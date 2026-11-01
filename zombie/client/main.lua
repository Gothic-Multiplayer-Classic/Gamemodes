local Zombie = require('shared.config')
local savedChatFont = chatInputGetFont()
local savedChatPosition = chatInputGetPosition()
local savedChatMaxLength = chatInputGetMaxLength()
local Chat = require('client.chat')
local PlayerList = require('client.playerlist')

local selecting = false
local selectedClass = 5
local selectionReceived = false
local roundActive = false
local waiting = false
local previewChanged = false
local nextReady = 0
local announcementUntil = 0
local stopped = false
local savedKeys, savedHud = {}, {}
local savedControls, cameraMovement, cameraModeChange
local sounds = {}
local gameSound
local nextSoundCleanup = 0
local blockedKeys = { KEY_T, KEY_F1, KEY_F2, KEY_F3, KEY_F7 }
local hudTypes = { HUD_ALL, HUD_HEALTH_BAR, HUD_MANA_BAR, HUD_SWIM_BAR, HUD_FOCUS_BAR, HUD_FOCUS_NAME }
local labels = {}

local function label(x, y, text, r, g, b)
  local draw = Label.new(x, y, text)
  draw:setFont('FONT_DEFAULT.TGA')
  draw:setColor(r or 255, g or 255, b or 255)
  draw:setVisible(false)
  labels[#labels + 1] = draw
  return draw
end

local phaseLabel = label(6300, 5400, '', 255, 100, 255)
local timerLabel = label(6300, 5700, '')
local zombiesLabel = label(6300, 6000, '', 255, 70, 70)
local humansLabel = label(6300, 6300, '', 70, 255, 70)
local teamLabel = label(6300, 6600, '')
local announcement = label(0, 2900, '')
local controls = label(100, 1700, 'A/D: choose class | RETURN: join')
local className = label(100, 1950, '')
local classTeam = label(100, 2200, '')
local classNote = label(100, 2450, '')
local status = label(100, 2700, '')
local menuLabels = { controls, className, classTeam, classNote, status }

local function enforceWarmupWeaponMode()
  if stopped or (roundActive and not selecting) or heroId == nil then return end
  local mode = getPlayerWeaponMode(heroId)
  if mode ~= nil and mode ~= WEAPONMODE_NONE then
    setPlayerWeaponMode(heroId, WEAPONMODE_NONE)
  end
end

local function selectionMode(enabled)
  -- Close the list before saving selection state so its control lock cannot leak.
  if enabled then PlayerList:setEnabled(false) end
  Chat:setEnabled(not enabled and not stopped)
  PlayerList:setEnabled(not enabled and not stopped)
  if enabled and not selecting then
    savedControls = isControlsDisabled()
    cameraMovement = Camera.movementEnabled
    cameraModeChange = Camera.modeChangeEnabled
    for _, key in ipairs(blockedKeys) do
      savedKeys[key] = isScriptKeyEnabled(key)
      setScriptKeyEnabled(key, false)
    end
    for _, hud in ipairs(hudTypes) do savedHud[hud] = getHudMode(hud) end
  elseif not enabled and selecting then
    for key, value in pairs(savedKeys) do setScriptKeyEnabled(key, value) end
    savedKeys = {}
    setHudMode(HUD_ALL, savedHud[HUD_ALL] or HUD_MODE_DEFAULT)
    for _, hud in ipairs(hudTypes) do
      if savedHud[hud] ~= nil then setHudMode(hud, savedHud[hud]) end
    end
    savedHud = {}
    disableControls(savedControls)
    Camera.movementEnabled = cameraMovement
    Camera.modeChangeEnabled = cameraModeChange
  end
  selecting = enabled
  if enabled then
    disableControls(true)
    setHudMode(HUD_ALL, HUD_MODE_HIDDEN)
    Camera.movementEnabled = false
    Camera.modeChangeEnabled = false
    chatInputClear()
    chatInputClose()
  end
  for _, draw in ipairs(menuLabels) do draw:setVisible(enabled) end
end

local function updateClass()
  local class = Zombie.classes[selectedClass]
  className:setText(string.format('Class: %s (%d/%d)', class.name, selectedClass, #Zombie.classes))
  classTeam:setText('First round team: ' .. (class.team == 'human' and 'Human' or 'Zombie'))
  classTeam:setColor(class.team == 'human' and 70 or 255, class.team == 'human' and 255 or 70, 70)
  classNote:setText('Your chosen class starts round one. Later rounds randomize teams.')
  status:setText('')
  previewChanged = true
end

for _, event in ipairs({ 'zombie:selection', 'zombie:state', 'zombie:announcement', 'zombie:sound', 'zombie:players' }) do
  addEvent(event, true)
end

addEventHandler('zombie:players', function(context, roster)
  if not context.remote or type(roster) ~= 'table' then return end
  PlayerList.players = roster
  PlayerList:update()
end)

addEventHandler('zombie:selection', function(context, selected, classId, team)
  if not context.remote or heroId == nil or context.sourceId ~= heroId then return end
  selectionReceived = true
  waiting = false
  if type(classId) == 'number' and classId % 1 == 0 and Zombie.classes[classId] then
    selectedClass = classId
  end
  selectionMode(not selected)
  if selected then
    local human = team == 'human'
    teamLabel:setText('Team: ' .. (human and 'Human' or 'Zombie'))
    teamLabel:setColor(human and 70 or 255, human and 255 or 70, 70)
    teamLabel:setVisible(true)
  else
    teamLabel:setVisible(false)
    updateClass()
  end
end)

addEventHandler('zombie:state', function(context, phase, seconds, humans, zombies)
  if not context.remote then return end
  roundActive = phase == 'active'
  enforceWarmupWeaponMode()
  phaseLabel:setText(phase == 'active' and 'Round ends in:' or 'Round begins in:')
  local remaining = math.max(0, math.floor(tonumber(seconds) or 0))
  timerLabel:setText(string.format('%d:%02d', math.floor(remaining / 60), remaining % 60))
  humansLabel:setText('Humans: ' .. tostring(humans))
  zombiesLabel:setText('Zombies: ' .. tostring(zombies))
  for _, draw in ipairs({ phaseLabel, timerLabel, humansLabel, zombiesLabel }) do draw:setVisible(true) end
end)

addEventHandler('zombie:announcement', function(context, text, r, g, b, durationMs)
  if not context.remote or type(text) ~= 'string' then return end
  announcement:setText(text)
  announcement:setColor(r or 255, g or 255, b or 255)
  announcement:setPosition(math.max(100, (8192 - announcement:getWidth()) / 2), 3100)
  announcement:setVisible(true)
  announcementUntil = getTickCount() + (tonumber(durationMs) or 5000)
end)

addEventHandler('zombie:sound', function(context, file, targetPlayerId)
  if not context.remote or type(file) ~= 'string' then return end
  if targetPlayerId == nil then
    if gameSound then gameSound:stop() end
    gameSound = Sound.new(file)
    gameSound:play()
    return
  end
  if type(targetPlayerId) ~= 'number' then return end
  local sound = Sound3d.new(file)
  sound.radius = 2000
  if not sound:setTargetPlayer(targetPlayerId) then return end
  if #sounds >= 16 then table.remove(sounds, 1):stop() end
  sound:play()
  sounds[#sounds + 1] = sound
end)

addEventHandler('onKeyDown', function(key)
  if stopped then return end
  if selecting then
    if heroId == nil or not selectionReceived then return end
    if key == KEY_RETURN then
      waiting = true
      status:setText('Joining... Press RETURN to retry.')
      if not triggerServerEvent('zombie:selectClass', nil, selectedClass) then
        waiting = false
        status:setText('Could not join. Press RETURN to retry.')
      end
    elseif not waiting and (key == KEY_A or key == KEY_D) then
      selectedClass = (selectedClass - 1 + (key == KEY_A and -1 or 1)) % #Zombie.classes + 1
      updateClass()
    end
    if key ~= KEY_ESCAPE then cancelEvent() end
    return
  end
end)

addEventHandler('onRender', function()
  if stopped then return end
  enforceWarmupWeaponMode()
  local now = getTickCount()
  local position = heroId ~= nil and getPlayerPosition(heroId) or nil
  if not selectionReceived and position and now >= nextReady then
    triggerServerEvent('zombie:ready', nil)
    nextReady = now + 1000
  end
  if selecting and position then
    disableControls(true)
    if chatInputIsOpen() then chatInputClear(); chatInputClose() end
    if previewChanged and selectionReceived then
      previewChanged = not triggerServerEvent('zombie:previewClass', nil, selectedClass)
    end
    local angle = Zombie.preview.angle
    local radians = math.rad(angle)
    Camera:setPosition(position.x + 250 * math.sin(radians), position.y + 70,
      position.z + 250 * math.cos(radians))
    Camera:setRotationDegrees(0, angle + 180, 0)
  end
  if announcementUntil > 0 and now >= announcementUntil then
    announcement:setVisible(false)
    announcementUntil = 0
  end
  if now >= nextSoundCleanup then
    for i = #sounds, 1, -1 do
      if not sounds[i]:isPlaying() then table.remove(sounds, i) end
    end
    nextSoundCleanup = now + 500
  end
end)

addEventHandler('onWorldEnter', function()
  if selecting then selectionMode(true); previewChanged = true end
  if not selectionReceived then nextReady = 0 end
end)

function onResourceStop()
  if stopped then return end
  stopped = true
  PlayerList:setEnabled(false)
  selectionMode(false)
  Chat:clear()
  for _, draw in ipairs(labels) do draw:setVisible(false) end
  for _, sound in ipairs(sounds) do sound:stop() end
  sounds = {}
  if gameSound then gameSound:stop(); gameSound = nil end
  chatInputClear()
  chatInputClose()
  chatInputSetFont(savedChatFont)
  chatInputSetPosition(savedChatPosition.x, savedChatPosition.y)
  chatInputSetMaxLength(savedChatMaxLength)
end

addEventHandler('onExit', onResourceStop)
selectionMode(true)
updateClass()

exports = { Chat = Chat, PlayerList = PlayerList }
return exports
