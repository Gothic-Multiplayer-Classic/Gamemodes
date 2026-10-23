local Classic = require('shared.classes')
local Chat = require('client.chat')
local PlayerList = require('client.playerlist')
local CharacterCreation = require('client.character_creation')
local ClassSelect = require('client.class_selection')
local Anims = require('client.anims')
local Map = require('client.map')
local Watch = require('client.watch')
local VoiceChat = require('client.voice_chat')
local DiscordActivity = require('client.discord_activity')

local selecting = false
local selectionReceived = false
local selectionRequested = false
local savedKeys = {}
local cameraMovement, cameraModeChange
local blockedKeys = { KEY_T, KEY_F1, KEY_F7, KEY_F2, KEY_F3 }

local function selectionMode(enabled)
  Chat:setEnabled(not enabled)
  PlayerList:setEnabled(not enabled)
  if enabled then
    if not selecting then
      cameraMovement = Camera.movementEnabled
      cameraModeChange = Camera.modeChangeEnabled
      for _, key in ipairs(blockedKeys) do
        savedKeys[key] = isScriptKeyEnabled(key)
        setScriptKeyEnabled(key, false)
      end
    end
    disableControls(true)
    setHudMode(HUD_ALL, HUD_MODE_HIDDEN)
    Camera.movementEnabled = false
    Camera.modeChangeEnabled = false
    chatInputClear()
    chatInputClose()
  elseif selecting then
    for key, enabled in pairs(savedKeys) do
      setScriptKeyEnabled(key, enabled)
    end
    savedKeys = {}
    disableControls(false)
    setHudMode(HUD_ALL, HUD_MODE_DEFAULT)
    Camera.movementEnabled = cameraMovement
    Camera.modeChangeEnabled = cameraModeChange
  end
  selecting = enabled
end

local function isForLocalPlayer(context)
  return context.remote and heroId ~= nil and context.sourceId == heroId
end

local function showCharacterCreation(context, visual, reason)
  if not isForLocalPlayer(context) then return end
  selectionReceived = true
  selectionMode(true)
  VoiceChat:setEnabled(false)
  ClassSelect:hide()
  CharacterCreation:show(visual)
  CharacterCreation.status:setText(reason or '')
  DiscordActivity:setText('Creating a character', '')
end

addEvent('classic:startCharacterCreation', true)
addEvent('classic:visualRejected', true)
addEvent('classic:startClassSelect', true)
addEvent('classic:classRejected', true)
addEvent('classic:classSelected', true)
addEvent('classic:players', true)
addEventHandler('classic:players', function(context, classes)
  if not context.remote or type(classes) ~= 'table' then return end
  Map.players = classes
  PlayerList.classes = classes
  Map:update()
  PlayerList:update()
end)
addEventHandler('classic:startCharacterCreation', showCharacterCreation)
addEventHandler('classic:visualRejected', showCharacterCreation)

addEventHandler('classic:startClassSelect', function(context)
  if not isForLocalPlayer(context) then return end
  selectionReceived = true
  selectionMode(true)
  VoiceChat:setEnabled(false)
  CharacterCreation:hide()
  ClassSelect:show()
  DiscordActivity:setText('Selecting a class', '')
end)

addEventHandler('classic:classRejected', function(context, reason)
  if not isForLocalPlayer(context) then return end
  ClassSelect.waiting = false
  ClassSelect.status:setText(reason or 'Choose a class and press RETURN again.')
end)

addEventHandler('classic:classSelected', function(context, classId, playerName)
  if not isForLocalPlayer(context) then return end
  local info = Classic.classes[classId + 1]
  if info == nil then return end
  selectionReceived = true
  CharacterCreation:hide()
  ClassSelect:hide()
  selectionMode(false)
  setHudMode(HUD_HEALTH_BAR, HUD_MODE_ALWAYS_VISIBLE)
  setHudMode(HUD_MANA_BAR, HUD_MODE_ALWAYS_VISIBLE)
  VoiceChat:setEnabled(true)
  DiscordActivity:setText(playerName, info.name .. ' | ' .. info.team)
end)

addEventHandler('onRender', function()
  if not selecting then return end
  if chatInputIsOpen() then
    chatInputClear()
    chatInputClose()
  end
  if heroId ~= nil and getPlayerPosition(heroId) ~= nil then
    disableControls(true)
    if not selectionReceived and not selectionRequested then
      selectionRequested = triggerServerEvent('classic:requestSelection', nil)
    end
  end
end)

addEventHandler('onWorldEnter', function()
  if selecting then
    selectionMode(true)
    selectionRequested = false
    CharacterCreation.changed = CharacterCreation.visible
    CharacterCreation.position = nil
    ClassSelect.changed = ClassSelect.visible
  end
end)

function onResourceStop()
  CharacterCreation:hide()
  ClassSelect:hide()
  Anims:close()
  Map:close()
  Watch:setVisible(false)
  selectionMode(false)
  Chat:setEnabled(false)
  Chat:clear()
  PlayerList:setEnabled(false)
  VoiceChat:setEnabled(false)
  DiscordActivity:clear()
end

addEventHandler('onExit', onResourceStop)
selectionMode(true)

exports = {
  Chat = Chat,
  PlayerList = PlayerList,
  CharacterCreation = CharacterCreation,
  ClassSelect = ClassSelect,
  Anims = Anims,
  Map = Map,
  Watch = Watch,
  VoiceChat = VoiceChat,
  DiscordActivity = DiscordActivity
}
return exports
