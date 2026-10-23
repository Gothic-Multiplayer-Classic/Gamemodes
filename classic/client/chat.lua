local language = getLanguageIndex()
local fontPrefix = 'CP1252_'
if language == LANG_PL or language == LANG_CZ or language == LANG_SK or language == LANG_ISV or language == LANG_HU or language == LANG_SZL then
  fontPrefix = 'CP1250_'
elseif language == LANG_RU or language == LANG_UA then
  fontPrefix = 'CP1251_'
elseif language == LANG_TR then
  fontPrefix = 'CP1254_'
end

local Chat = {
  x = 0,
  y = 0,
  maxLines = 6,
  historySize = 50,
  lineHeight = 200,
  inputTextOffset = 200,
  inputLimit = 84,
  font = fontPrefix .. 'FONT_DEFAULT.TGA',
  visible = true,
  enabled = false,
  location = 0,
  inputHistory = {},
  inputHistorySize = 10,
  inputHistoryLocation = 0,
  lines = {}
}

local inputPrompt = Label.new(Chat.x, Chat.y + Chat.maxLines * Chat.lineHeight, '->')
local inputText = Label.new(Chat.x + Chat.inputTextOffset, Chat.y + Chat.maxLines * Chat.lineHeight, '')
local lastInputText = ''

inputPrompt:setFont(Chat.font)
inputText:setFont(Chat.font)
inputPrompt:setColor(255, 255, 255)
inputText:setColor(255, 255, 255)
inputPrompt:setVisible(false)
inputText:setVisible(false)
chatInputSetFont(Chat.font)

function Chat:layout()
  chatInputSetPosition(self.x, self.y + self.maxLines * self.lineHeight)

  local firstVisible = self:firstVisibleLine()
  local lastVisible = self:lastVisibleLine()

  for index, line in ipairs(self.lines) do
    local visible = self.enabled and self.visible and index >= firstVisible and index <= lastVisible
    line:setVisible(visible)

    if visible then
      local y = self.y + (index - firstVisible) * self.lineHeight
      line:setPosition(self.x, y)
    end
  end
end

function Chat:firstVisibleLine()
  if #self.lines == 0 then
    return 1
  end

  local first = #self.lines - self.maxLines + 1 + self.location
  if first < 1 then
    return 1
  end

  return first
end

function Chat:lastVisibleLine()
  if #self.lines == 0 then
    return 0
  end

  return math.min(self:firstVisibleLine() + self.maxLines - 1, #self.lines)
end

function Chat:setLocation(location)
  local maxBack = math.max(#self.lines - self.maxLines, 0)
  self.location = math.max(-maxBack, math.min(location, 0))
  self:layout()
end

function Chat:scroll(delta)
  self:setLocation(self.location + delta)
end

function Chat:setMaxLines(maxLines)
  maxLines = math.floor(tonumber(maxLines) or self.maxLines)
  if maxLines <= 0 or maxLines > 30 then
    return
  end

  self.maxLines = maxLines
  if self.historySize < self.maxLines then
    self.historySize = self.maxLines
  end

  self:setLocation(self.location)
end

function Chat:setHistorySize(historySize)
  historySize = math.floor(tonumber(historySize) or self.historySize)
  if historySize < self.maxLines then
    return
  end

  self.historySize = historySize
  while #self.lines > self.historySize do
    local old = table.remove(self.lines, 1)
    old:setVisible(false)
  end

  self:setLocation(self.location)
end

function Chat:setInputHistorySize(size)
  size = math.floor(tonumber(size) or self.inputHistorySize)
  if size < 0 then
    return
  end

  self.inputHistorySize = size
  while #self.inputHistory > self.inputHistorySize do
    table.remove(self.inputHistory, 1)
  end

  self:loadInputHistoryMessage(0)
end

function Chat:pushInputHistoryMessage(message)
  message = tostring(message or '')
  if self.inputHistorySize <= 0 or message == '' then
    return
  end

  if self.inputHistory[#self.inputHistory] == message then
    self.inputHistoryLocation = 0
    return
  end

  table.insert(self.inputHistory, message)
  while #self.inputHistory > self.inputHistorySize do
    table.remove(self.inputHistory, 1)
  end

  self.inputHistoryLocation = 0
end

function Chat:loadInputHistoryMessage(location)
  if #self.inputHistory == 0 then
    return
  end

  location = math.max(-#self.inputHistory, math.min(location, 0))
  if self.inputHistoryLocation == location then
    return
  end

  self.inputHistoryLocation = location

  if location == 0 then
    chatInputSetText('')
  else
    chatInputSetText(self.inputHistory[#self.inputHistory + location + 1])
  end
end

function Chat:showNewest()
  self:setLocation(0)
end

function Chat:push(line)
  local firstVisible = self:firstVisibleLine()
  local wasAtNewest = self.location == 0
  local removed = 0

  table.insert(self.lines, line)
  while #self.lines > self.historySize do
    local old = table.remove(self.lines, 1)
    old:setVisible(false)
    removed = removed + 1
  end

  if wasAtNewest then
    self.location = 0
  else
    local desiredFirst = math.max(firstVisible - removed, 1)
    local newestFirst = math.max(#self.lines - self.maxLines + 1, 1)
    self.location = desiredFirst - newestFirst
  end

  self:setLocation(self.location)
end

function Chat:pushMessage(message, r, g, b)
  message = tostring(message or ''):gsub('\r\n', '\n'):gsub('\r', '\n')
  for text in (message .. '\n'):gmatch('(.-)\n') do
    local draw = Label.new(0, 0, text)
    draw:setFont(self.font)
    draw:setColor(r or 255, g or 255, b or 255)
    draw:setVisible(false)
    self:push(draw)
  end
end

function Chat:clear()
  for _, line in ipairs(self.lines) do
    line:setVisible(false)
  end
  self.lines = {}
  self.location = 0
  self:layout()
end

function Chat:setVisible(visible)
  self.visible = visible and true or false
  self:layout()

  if not self.visible and chatInputIsOpen() then
    chatInputClear()
    chatInputClose()
  end
end

function Chat:setEnabled(enabled)
  self.enabled = enabled
  self:layout()
  if not enabled then
    chatInputClear()
    chatInputClose()
    inputPrompt:setVisible(false)
    inputText:setVisible(false)
  end
end

function Chat:print(message, r, g, b)
  self:pushMessage(message, r, g, b)
end

function Chat:printPlayer(playerId, r, g, b, message)
  self:pushMessage(message, r, g, b)
end

function Chat:updateInput()
  if not self.enabled then return end
  local open = self.visible and chatInputIsOpen()
  local pos = chatInputGetPosition()
  local font = chatInputGetFont()
  local text = chatInputGetText()
  local caret = chatInputGetCaretPosition()
  local shownText = text

  -- Ordinary typing is consumed natively and does not emit onKeyDown.
  if open and text ~= lastInputText and heroId ~= nil then
    playGesticulation(heroId)
  end
  lastInputText = text

  if open and math.floor(getTickCount() / 750) % 2 == 0 then
    shownText = string.sub(text, 1, caret) .. '_' .. string.sub(text, caret + 1)
  end

  inputPrompt:setFont(font)
  inputText:setFont(font)
  inputPrompt:setPosition(pos.x, pos.y)
  inputText:setPosition(pos.x + self.inputTextOffset, pos.y)
  inputText:setText(shownText)
  inputPrompt:setVisible(open)
  inputText:setVisible(open)
end

local function insertPasteText(text)
  if not Chat.enabled or not chatInputIsOpen() then
    return
  end

  text = tostring(text or '')
  text = string.gsub(text, '[\r\n]+', ' ')
  if text == '' then
    return
  end

  local current = chatInputGetText()
  local caret = chatInputGetCaretPosition()
  local nextText = string.sub(current, 1, caret) .. text .. string.sub(current, caret + 1)

  if #nextText > Chat.inputLimit then
    nextText = string.sub(nextText, 1, Chat.inputLimit)
  end

  chatInputSetText(nextText)
  chatInputSetCaretPosition(math.min(caret + #text, #nextText))
end

local function commandText(command, params)
  params = tostring(params or '')
  if params == '' then
    return '/' .. command
  end

  return '/' .. command .. ' ' .. params
end

addEventHandler('onRender', function()
  Chat:updateInput()
end)

addEventHandler('onPlayerMessage', function(playerId, r, g, b, message)
  Chat:print(message, r, g, b)
end)

addEventHandler('onPaste', function(text)
  insertPasteText(text)
end)

addEventHandler('onCommand', function(command, params)
  if not Chat.enabled then return end
  local rawCommand = tostring(command or '')
  command = string.lower(rawCommand)
  params = tostring(params or '')

  Chat:pushInputHistoryMessage(commandText(rawCommand, params))

  if command == 'chatclear' then
    Chat:clear()
    cancelEvent()
  elseif command == 'chatlines' then
    local args = sscanf('d', params)
    if args then
      Chat:setMaxLines(args[1])
    end
    cancelEvent()
  elseif command == 'chatlimit' then
    local args = sscanf('d', params)
    if args then
      Chat:setHistorySize(args[1])
    end
    cancelEvent()
  elseif command == 'chatinputlimit' then
    local args = sscanf('d', params)
    if args then
      Chat:setInputHistorySize(args[1])
    end
    cancelEvent()
  end
end)

addEventHandler('onKeyDown', function(key)
  if not Chat.enabled then return end
  if chatInputIsOpen() then
    if key == KEY_UP then
      Chat:scroll(-1)
      cancelEvent()
    elseif key == KEY_DOWN then
      Chat:scroll(1)
      cancelEvent()
    elseif key == KEY_PRIOR or key == KEY_PGUP then
      Chat:loadInputHistoryMessage(Chat.inputHistoryLocation - 1)
      cancelEvent()
    elseif key == KEY_NEXT or key == KEY_PGDN then
      Chat:loadInputHistoryMessage(Chat.inputHistoryLocation + 1)
      cancelEvent()
    elseif key == KEY_RETURN then
      Chat:pushInputHistoryMessage(chatInputGetText())
      Chat:showNewest()
      Chat.inputHistoryLocation = 0
    elseif key == KEY_ESCAPE then
      Chat.inputHistoryLocation = 0
    elseif key == KEY_HOME then
      chatInputSetCaretPosition(0)
      cancelEvent()
    elseif key == KEY_END then
      chatInputSetCaretPosition(#chatInputGetText())
      cancelEvent()
    end
    return
  end

  if key == KEY_T and Chat.visible and not isConsoleOpen() then
    chatInputOpen()
    Chat:showNewest()
    Chat.inputHistoryLocation = 0
    return
  end

  if key == KEY_F7 then
    Chat:setVisible(not Chat.visible)
  end
end)

addEventHandler('onMouseWheel', function(direction)
  if Chat.enabled and Chat.visible and chatInputIsOpen() then
    Chat:scroll(-direction)
  end
end)

Chat:layout()

return Chat
