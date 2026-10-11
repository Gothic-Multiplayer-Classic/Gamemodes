local CharacterCreation = require('client.character_creation')
local ClassSelect = require('client.class_selection')
local Anims = require('client.anims')
local Map = require('client.map')
local Watch = require('client.watch')
local VoiceChat = require('client.voice_chat')
local DiscordActivity = require('client.discord_activity')

exports = {
  CharacterCreation = CharacterCreation,
  ClassSelect = ClassSelect,
  Anims = Anims,
  Map = Map,
  Watch = Watch,
  VoiceChat = VoiceChat,
  DiscordActivity = DiscordActivity
}

function onResourceStop()
  CharacterCreation:hide()
  ClassSelect:hide()
  Anims:close()
  Map:close()
  Watch:setVisible(false)
  VoiceChat:setEnabled(false)
  DiscordActivity:clear()
end

return exports
