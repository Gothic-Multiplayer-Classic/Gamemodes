local VoiceChat = {
  playing = false
}

local indicator = Draw.new(100, 7600, 'Voice: speaking')
indicator:setFont('FONT_DEFAULT.TGA')
indicator:setColor(0, 255, 0)
indicator:setVisible(false)

function VoiceChat:setEnabled(enabled)
  self.playing = enabled
  Voice.setEnabled(enabled)
  indicator:setVisible(enabled and Voice.isEnabled() and Voice.isTransmitting())
end

addEventHandler('onVoiceChatStateChange', function(enabled)
  indicator:setVisible(VoiceChat.playing and enabled and Voice.isTransmitting())
end)

addEventHandler('onVoiceTransmitStart', function()
  indicator:setVisible(VoiceChat.playing and Voice.isEnabled())
end)

addEventHandler('onVoiceTransmitStop', function()
  indicator:setVisible(false)
end)

VoiceChat:setEnabled(false)

return VoiceChat
