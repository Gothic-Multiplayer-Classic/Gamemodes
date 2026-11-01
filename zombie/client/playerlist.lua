local Zombie = require('shared.config')

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
  x = 2200,
  y = 2200,
  lineHeight = 200,
  maxVisibleRows = 16,
  font = fontPrefix .. 'FONT_DEFAULT.TGA',
  first = 1,
  players = {},
  rows = {}
}

local background = Sprite.new(1900, 2000, 4500, 4000, 'MENU_INGAME.TGA')
background:setVisible(false)

local function makeDraw(x, y, text)
  local draw = Label.new(x, y, text)
  draw:setFont(PlayerList.font)
  draw:setColor(255, 255, 255)
  draw:setVisible(false)
  return draw
end

local columns = { id = 2200, nickname = 2650, team = 4250, class = 4900 }
local title = makeDraw(PlayerList.x, PlayerList.y, string.sub(getHostname(), 1, 40))
local count = makeDraw(5900, PlayerList.y, '')
local noPlayers = makeDraw(PlayerList.x, PlayerList.y + 2 * PlayerList.lineHeight, 'No players.')
local footer = makeDraw(PlayerList.x, 5800, 'UP/DOWN: scroll | PAGE UP/DOWN: page | F1/ESC: close')
local headings = {}
for _, column in ipairs({ { 'id', 'ID' }, { 'nickname', 'Nickname' }, { 'team', 'Team' }, { 'class', 'Class' } }) do
  headings[#headings + 1] = makeDraw(columns[column[1]], PlayerList.y + PlayerList.lineHeight, column[2])
end
local previousControlsDisabled = false
local savedKeys = {}
local blockedKeys = { KEY_T, KEY_F2, KEY_F3, KEY_F7 }

for index = 1, PlayerList.maxVisibleRows do
  local row = {}
  for name, x in pairs(columns) do
    row[name] = makeDraw(x, PlayerList.y + (index + 1) * PlayerList.lineHeight, '')
  end
  PlayerList.rows[index] = row
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
    for _, draw in pairs(row) do draw:setVisible(playerId ~= nil) end
    if playerId ~= nil then
      local info = self.players[playerId]
      local class = info and Zombie.classes[info.classId]
      local team, className = '-', 'Selecting class'
      if info and info.joined then
        team = info.team == 'human' and 'Human' or 'Zombie'
        className = class and class.name or 'Respawning'
        if not info.alive or (class and class.team ~= info.team) then className = 'Respawning' end
      end
      row.id:setText(tostring(playerId))
      row.nickname:setText(string.sub(getPlayerName(playerId) or tostring(playerId), 1, 20))
      row.team:setText(team)
      row.class:setText(className)
      if playerId == heroId then
        row.nickname:setColor(128, 180, 128)
      else
        row.nickname:setColor(255, 255, 255)
      end
      if team == 'Human' then
        row.team:setColor(70, 255, 70)
      elseif team == 'Zombie' then
        row.team:setColor(255, 70, 70)
      else
        row.team:setColor(255, 255, 255)
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
  footer:setVisible(visible)
  for _, heading in ipairs(headings) do heading:setVisible(visible) end
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
      for _, draw in pairs(row) do draw:setVisible(false) end
    end
    disableControls(previousControlsDisabled)
    for key, enabled in pairs(savedKeys) do setScriptKeyEnabled(key, enabled) end
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
