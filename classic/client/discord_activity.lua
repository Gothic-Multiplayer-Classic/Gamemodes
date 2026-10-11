local Classic = require('shared.classes')

local DiscordActivity = {
  details = nil,
  state = nil
}

local function isLocalPlayer(playerId)
  return heroId == nil or playerId == nil or tonumber(playerId) == tonumber(heroId)
end

function DiscordActivity:setText(details, state)
  if details ~= self.details then
    Discord.setDetails(details)
    self.details = details
  end

  if state ~= self.state then
    Discord.setState(state)
    self.state = state
  end
end

function DiscordActivity:startSelection(details)
  self:setText(details, '')
end

function DiscordActivity:clear()
  self.details = nil
  self.state = nil
  Discord.clearActivity()
end

local function startCharacterCreation(playerId)
  if isLocalPlayer(playerId) then
    DiscordActivity:startSelection('Creating a character')
  end
end

addEventHandler('classic:startCharacterCreation', startCharacterCreation)
addEventHandler('classic:visualRejected', startCharacterCreation)

addEventHandler('classic:startClassSelect', function(playerId)
  if isLocalPlayer(playerId) then
    DiscordActivity:startSelection('Selecting a class')
  end
end)

addEventHandler('classic:classSelected', function(playerId, classId, playerName)
  if not isLocalPlayer(playerId) then
    return
  end

  classId = tonumber(classId)
  local info = classId ~= nil and Classic.classes[classId + 1] or nil
  if info == nil then
    return
  end

  DiscordActivity:setText('Playing as ' .. playerName or 'Player', info.name .. ' | ' .. info.team)
end)

addEventHandler('onExit', function()
  DiscordActivity:clear()
end)

return DiscordActivity
