ColonyState = {
    players = {},
    active = {},
}

function ColonyState.ensurePlayer(playerId)
    if not ColonyState.players[playerId] then
        ColonyState.players[playerId] = {
            logged = false,
            password = nil,
            classId = 1,
            moderator = false,
            guild = 0,
            walkOverlay = nil,
        }
    end
    return ColonyState.players[playerId]
end

function ColonyState.markActive(playerId)
    ColonyState.active[playerId] = true
end

function ColonyState.removePlayer(playerId)
    ColonyState.players[playerId] = nil
    ColonyState.active[playerId] = nil
end

function ColonyState.listActive()
    local result = {}
    for playerId, _ in pairs(ColonyState.active) do
        table.insert(result, playerId)
    end
    table.sort(result)
    return result
end