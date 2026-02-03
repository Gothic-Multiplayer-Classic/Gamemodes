CruzerState = {}

CruzerState.players = {}
CruzerState.activePlayers = {}

function CruzerState.ensurePlayer(playerId)
    if not CruzerState.players[playerId] then
        CruzerState.players[playerId] = {
            logged = false,
            password = nil,
            classId = 0,
            moderator = 0,
            guild = -1,
            seepm = false,
            baseOverlay = nil,
        }
    end
    return CruzerState.players[playerId]
end

function CruzerState.removePlayer(playerId)
    CruzerState.players[playerId] = nil
    CruzerState.activePlayers[playerId] = nil
end

function CruzerState.markActive(playerId)
    CruzerState.activePlayers[playerId] = true
end

function CruzerState.listActive()
    local list = {}
    for playerId, _ in pairs(CruzerState.activePlayers) do
        table.insert(list, playerId)
    end
    table.sort(list)
    return list
end
