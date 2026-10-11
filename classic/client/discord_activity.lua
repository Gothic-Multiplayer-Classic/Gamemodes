local DiscordActivity = {}

function DiscordActivity:setText(details, state)
  if self.details ~= details then
    Discord.setDetails(details)
    self.details = details
  end
  if self.state ~= state then
    Discord.setState(state)
    self.state = state
  end
end

function DiscordActivity:clear()
  self.details = nil
  self.state = nil
  Discord.clearActivity()
end

return DiscordActivity
