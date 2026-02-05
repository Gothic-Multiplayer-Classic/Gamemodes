ColonyPermissions = {}

function ColonyPermissions.isAdmin(playerId)
    local name = getPlayerName(playerId)
    return ColonyUtil.nameInList(name, ColonyConfig.admins)
end

function ColonyPermissions.isModerator(playerId, state)
    if state and state.moderator then
        return true
    end
    local name = getPlayerName(playerId)
    return ColonyUtil.nameInList(name, ColonyConfig.moderators)
end