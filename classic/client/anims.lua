local Anims = {
  x = 6500,
  y = 3200,
  lineHeight = 200,
  maxVisibleRows = 10,
  font = 'FONT_DEFAULT.TGA',
  visible = false,
  selectedIndex = 1,
  firstIndex = 1,
  rows = {}
}

local animations = {
  { name = 'Sit', loop = 'S_SIT', start = 'T_STAND_2_SIT', finish = 'T_SIT_2_STAND' },
  { name = 'Piss', loop = 'S_PEE', start = 'T_STAND_2_PEE', finish = 'T_PEE_2_STAND' },
  { name = 'Guard', loop = 'S_HGUARD', start = 'T_STAND_2_HGUARD', finish = 'T_HGUARD_2_STAND' },
  { name = 'Wash', loop = 'S_WASH', start = 'T_STAND_2_WASH', finish = 'T_WASH_2_STAND' },
  { name = 'Pray', loop = 'S_PRAY', start = 'T_STAND_2_PRAY', finish = 'T_PRAY_2_STAND' },
  { name = 'Magic', loop = 'T_PRACTICEMAGIC3' },
  { name = 'Magic2', loop = 'T_PRACTICEMAGIC4' },
  { name = 'Magic3', loop = 'T_PRACTICEMAGIC2' },
  { name = 'Dance', loop = 'T_DANCE_05' },
  { name = 'WatchFight', loop = 'S_WATCHFIGHT', start = 'T_STAND_2_WATCHFIGHT', finish = 'T_WATCHFIGHT_2_STAND' },
  { name = 'Cello', loop = 'S_CELLO_S0', start = 'T_CELLO_STAND_2_S0', finish = 'T_CELLO_S0_2_STAND' },
  { name = 'Drumscheit', loop = 'S_DRUMSCHEIT_S0', start = 'T_DRUMSCHEIT_STAND_2_S0', finish = 'T_DRUMSCHEIT_S0_2_STAND' },
  { name = 'Dudel', loop = 'S_DUDEL_S0', start = 'T_DUDEL_STAND_2_S0', finish = 'T_DUDEL_S0_2_STAND' },
  { name = 'Harfe', loop = 'S_HARFE_S0', start = 'T_HARFE_STAND_2_S0', finish = 'T_HARFE_S0_2_STAND' },
  { name = 'Ielaute', loop = 'S_IELAUTE_S0', start = 'T_IELAUTE_STAND_2_S0', finish = 'T_IELAUTE_S0_2_STAND' },
  { name = 'Drums', loop = 'S_PAUKE_S0', start = 'T_PAUKE_STAND_2_S0', finish = 'T_PAUKE_S0_2_STAND' },
  { name = 'Plunder', loop = 'T_PLUNDER' },
  { name = 'Kick', loop = 'T_BORINGKICK' }
}

local suppressedKeys = {
  KEY_T,
  KEY_F1,
  KEY_F6,
  KEY_F7
}

local previousControlsDisabled = false
local previousKeyState = {}
local activeMenuLoop = nil

local title = Label.new(Anims.x, Anims.y, 'Anims Menu')
title:setFont(Anims.font)
title:setColor(255, 255, 255)
title:setVisible(false)

local function isHeroUnavailable()
  return heroId == nil or isPlayerDead(heroId) or isPlayerUnconscious(heroId)
end

local function hideRows()
  for _, row in ipairs(Anims.rows) do
    row:setVisible(false)
  end
end

local function setMenuInputDisabled(disabled)
  if disabled then
    previousControlsDisabled = isControlsDisabled()
    disableControls(true)

    for _, key in ipairs(suppressedKeys) do
      if previousKeyState[key] == nil then
        previousKeyState[key] = isScriptKeyEnabled(key)
      end
      setScriptKeyEnabled(key, false)
    end

    return
  end

  disableControls(previousControlsDisabled)
  previousControlsDisabled = false

  for _, key in ipairs(suppressedKeys) do
    local previous = previousKeyState[key]
    if previous ~= nil then
      setScriptKeyEnabled(key, previous)
      previousKeyState[key] = nil
    end
  end
end

for index = 1, Anims.maxVisibleRows do
  local row = Label.new(Anims.x, Anims.y + index * Anims.lineHeight, '')
  row:setFont(Anims.font)
  row:setColor(255, 255, 255)
  row:setVisible(false)
  Anims.rows[index] = row
end

function Anims:update()
  if not self.visible then
    return
  end

  self.selectedIndex = math.max(1, math.min(#animations, self.selectedIndex))
  self.firstIndex = math.max(1, math.min(math.max(#animations - self.maxVisibleRows + 1, 1), self.firstIndex))

  title:setVisible(true)
  hideRows()

  local visibleRows = math.min(self.maxVisibleRows, #animations - self.firstIndex + 1)
  for rowIndex = 1, visibleRows do
    local animationIndex = self.firstIndex + rowIndex - 1
    local row = self.rows[rowIndex]

    row:setText(animations[animationIndex].name)
    if animationIndex == self.selectedIndex then
      row:setColor(128, 180, 128)
    else
      row:setColor(255, 255, 255)
    end
    row:setVisible(true)
  end
end

function Anims:open()
  if self.visible or #animations == 0 or isHeroUnavailable() then
    return
  end

  local animation = animations[self.selectedIndex]
  local playing = activeMenuLoop == animation.loop or getPlayerAni(heroId) == animation.loop
  if animation.finish ~= nil and playing then
    playAni(heroId, animation.finish)
    activeMenuLoop = nil
    return
  end

  if animation.finish == nil and playing then
    stopAni(heroId, animation.loop)
    activeMenuLoop = nil
    return
  end

  self.visible = true
  setMenuInputDisabled(true)
  self:update()
end

function Anims:close()
  if not self.visible then
    return
  end

  self.visible = false
  title:setVisible(false)
  hideRows()
  setMenuInputDisabled(false)
end

function Anims:toggle()
  if self.visible then
    self:close()
  else
    self:open()
  end
end

function Anims:runSelected()
  if #animations == 0 or isHeroUnavailable() then
    self:close()
    return
  end

  local animation = animations[self.selectedIndex]
  if playAni(heroId, animation.start or animation.loop) then
    activeMenuLoop = animation.loop
  else
    activeMenuLoop = nil
  end
  self:close()
end

function Anims:scroll(delta)
  if delta < 0 then
    if self.selectedIndex > 1 then
      self.selectedIndex = self.selectedIndex - 1
      if self.firstIndex > 1 and self.selectedIndex > self.firstIndex then
        self.firstIndex = self.firstIndex - 1
      end
    end
  elseif delta > 0 and self.selectedIndex < #animations then
    self.selectedIndex = self.selectedIndex + 1
    if self.selectedIndex > self.maxVisibleRows then
      self.firstIndex = self.firstIndex + 1
    end
  end

  self:update()
end

addEventHandler('onRender', function()
  if not Anims.visible then
    return
  end

  if isHeroUnavailable() then
    activeMenuLoop = nil
    Anims:close()
    return
  end

  disableControls(true)
  Anims:update()
end)

addEventHandler('onKeyDown', function(key)
  if key == KEY_F3 and not isConsoleOpen() and not chatInputIsOpen() then
    Anims:toggle()
    return
  end

  if not Anims.visible then
    return
  end

  if key == KEY_ESCAPE then
    Anims:close()
  elseif key == KEY_UP then
    Anims:scroll(-1)
  elseif key == KEY_DOWN then
    Anims:scroll(1)
  elseif key == KEY_RETURN then
    Anims:runSelected()
  end
end, 9000)

addEventHandler('onPlayerDeath', function(playerId)
  if heroId ~= nil and tonumber(playerId) == tonumber(heroId) then
    activeMenuLoop = nil
    Anims:close()
  end
end)

addEventHandler('onWorldChange', function()
  activeMenuLoop = nil
  Anims:close()
end)

addEventHandler('onWorldEnter', function()
  activeMenuLoop = nil
  Anims:close()
end)

addEventHandler('onExit', function()
  activeMenuLoop = nil
  Anims:close()
end)

return Anims
