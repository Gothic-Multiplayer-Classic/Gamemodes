local VoiceChat = {
  playing = false
}

local indicator = Draw.new(100, 7600, 'Voice: speaking')
indicator:setFont('FONT_DEFAULT.TGA')
indicator:setColor(0, 255, 0)
indicator:setVisible(false)

local function isLocalPlayer(playerId)
  return heroId == nil or playerId == nil or tonumber(playerId) == tonumber(heroId)
end

function VoiceChat:setEnabled(enabled)
  self.playing = enabled
  Voice.setEnabled(enabled)
  indicator:setVisible(enabled and Voice.isEnabled() and Voice.isTransmitting())
end

local function startSelection(playerId)
  if isLocalPlayer(playerId) then
    VoiceChat:setEnabled(false)
  end
end

addEventHandler('classic:startCharacterCreation', startSelection)
addEventHandler('classic:visualRejected', startSelection)
addEventHandler('classic:startClassSelect', startSelection)

addEventHandler('classic:classSelected', function(playerId)
  if isLocalPlayer(playerId) then
    VoiceChat:setEnabled(true)
  end
end)

addEventHandler('onVoiceChatStateChange', function(enabled)
  indicator:setVisible(VoiceChat.playing and enabled and Voice.isTransmitting())
end)

addEventHandler('onVoiceTransmitStart', function()
  indicator:setVisible(VoiceChat.playing and Voice.isEnabled())
end)

addEventHandler('onVoiceTransmitStop', function()
  indicator:setVisible(false)
end)

addEventHandler('onExit', function()
  VoiceChat:setEnabled(false)
end)

VoiceChat:setEnabled(false)

return VoiceChat
