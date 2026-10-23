local Classic = require('shared.classes')

local language = getLanguageIndex()
local fontPrefix = 'CP1252_'
if language == LANG_PL or language == LANG_CZ or language == LANG_SK or language == LANG_ISV or language == LANG_HU or language == LANG_SZL then
  fontPrefix = 'CP1250_'
elseif language == LANG_RU or language == LANG_UA then
  fontPrefix = 'CP1251_'
elseif language == LANG_TR then
  fontPrefix = 'CP1254_'
end

local PlayerList = {
  enabled = false,
  visible = false,
  x = 2900,
  y = 2200,
  lineHeight = 200,
  maxVisibleRows = 17,
  font = fontPrefix .. 'FONT_DEFAULT.TGA',
  first = 1,
  classes = {},
  rows = {}
}

local background = Sprite.new(2500, 2000, 3500, 4000, 'MENU_INGAME.TGA')
background:setVisible(false)

local function makeDraw(x, y, text)
  local draw = Label.new(x, y, text)
  draw:setFont(PlayerList.font)
  draw:setColor(255, 255, 255)
  draw:setVisible(false)
  return draw
end

local title = makeDraw(PlayerList.x, PlayerList.y, getHostname())
local count = makeDraw(5500, PlayerList.y, '')
local noPlayers = makeDraw(PlayerList.x, PlayerList.y + PlayerList.lineHeight, 'No players.')
local previousControlsDisabled = false
local savedKeys = {}
local blockedKeys = { KEY_T, KEY_F2, KEY_F3, KEY_F7 }

for index = 1, PlayerList.maxVisibleRows do
  PlayerList.rows[index] = makeDraw(PlayerList.x, PlayerList.y + index * PlayerList.lineHeight, '')
end

function PlayerList:update()
  if not self.visible then return end
  disableControls(true)

  local players = getOnlinePlayers() or {}
  table.sort(players)
  self.first = math.max(1, math.min(self.first, math.max(1, #players - self.maxVisibleRows + 1)))

  count:setText(string.format('%d/%d', #players, getMaxSlots()))
  noPlayers:setVisible(#players == 0)
  for index, row in ipairs(self.rows) do
    local playerId = players[self.first + index - 1]
    row:setVisible(playerId ~= nil)
    if playerId ~= nil then
      local name = getPlayerName(playerId) or tostring(playerId)
      local class = Classic.classes[self.classes[playerId]]
      local className = class and class.name or 'Selecting class'
      row:setText(string.sub(name, 1, 20) .. ', ' .. string.sub(className, 1, 20))
      if playerId == heroId then
        row:setColor(128, 180, 128)
      else
        row:setColor(255, 255, 255)
      end
    end
  end
end

function PlayerList:setVisible(visible)
  if self.visible == visible then return end
  self.visible = visible
  background:setVisible(visible)
  title:setVisible(visible)
  count:setVisible(visible)
  noPlayers:setVisible(false)

  if visible then
    self.first = 1
    previousControlsDisabled = isControlsDisabled()
    disableControls(true)
    for _, key in ipairs(blockedKeys) do
      savedKeys[key] = isScriptKeyEnabled(key)
      setScriptKeyEnabled(key, false)
    end
    self:update()
  else
    for _, row in ipairs(self.rows) do
      row:setVisible(false)
    end
    disableControls(previousControlsDisabled)
    for key, enabled in pairs(savedKeys) do
      setScriptKeyEnabled(key, enabled)
    end
    savedKeys = {}
  end
end

function PlayerList:setEnabled(enabled)
  self.enabled = enabled
  if not enabled then self:setVisible(false) end
end

addEventHandler('onRender', function()
  PlayerList:update()
end)

addEventHandler('onKeyDown', function(key)
  if not PlayerList.enabled or isConsoleOpen() or chatInputIsOpen() then return end
  if key == KEY_F1 then
    PlayerList:setVisible(not PlayerList.visible)
  elseif PlayerList.visible then
    if key == KEY_ESCAPE then
      PlayerList:setVisible(false)
    elseif key == KEY_UP then
      PlayerList.first = PlayerList.first - 1
    elseif key == KEY_DOWN then
      PlayerList.first = PlayerList.first + 1
    elseif key == KEY_PRIOR then
      PlayerList.first = PlayerList.first - PlayerList.maxVisibleRows
    elseif key == KEY_NEXT then
      PlayerList.first = PlayerList.first + PlayerList.maxVisibleRows
    end
    PlayerList:update()
  else
    return
  end
  cancelEvent()
end, 9000)

addEventHandler('onWorldChange', function()
  PlayerList:setVisible(false)
end)

return PlayerList
