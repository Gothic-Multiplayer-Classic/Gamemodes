local function msg(playerId, r, g, b, text)
    sendMessageToPlayer(playerId, r, g, b, text)
end

local function sendNearby(playerId, radius, color, message)
    local pos = getPlayerPosition(playerId)
    local world = getPlayerWorld(playerId)
    local nearby = findNearbyPlayers(pos, radius, world)
    for _, targetId in ipairs(nearby) do
        msg(targetId, color.r, color.g, color.b, message)
    end
end

addEventHandler("onPlayerConnect", function(playerId)
    spawnPlayer(playerId)

    local state = ColonyState.ensurePlayer(playerId)
    ColonyState.markActive(playerId)

    setPlayerMaxHealth(playerId, ColonyConfig.maxHealth)
    setPlayerHealth(playerId, ColonyConfig.maxHealth)
    setPlayerPosition(playerId, ColonyConfig.loginSpawn.x, ColonyConfig.loginSpawn.y, ColonyConfig.loginSpawn.z)
    setPlayerAngle(playerId, ColonyConfig.spawnAngle)

    setPlayerColor(playerId, 0, 0, 255)
    setPlayerName(playerId, string.format("Nameless %d", playerId))

    msg(playerId, 255, 0, 0, "Before registering, change your nickname with /ustawnick - the nickname MUST be lore-friendly!")
    msg(playerId, 0, 255, 255, "Type /pomoc if you need help.")

    triggerClientEvent(playerId, "colony:showUi", nil)
    triggerClientEvent(playerId, "colony:disableControls", nil, true)
    triggerClientEvent(playerId, "colony:playSound", nil, "DIA_GARWIG_HELLO_06_00.WAV")
    triggerClientEvent(playerId, "colony:playSound", nil, "DIA_RAMIREZ_HALLO_14_02.WAV")

    state.logged = false
end)

addEventHandler("onPlayerDisconnect", function(playerId)
    local state = ColonyState.ensurePlayer(playerId)
    if state.logged then
        ColonyAccounts.save(playerId, state)
        sendMessageToAll(255, 0, 0, string.format("%s took a break.", getPlayerName(playerId)))
    end

    triggerClientEvent(playerId, "colony:hideUi", nil)
    ColonyState.removePlayer(playerId)
end)

addEventHandler("onPlayerSpawn", function(playerId)
    local state = ColonyState.ensurePlayer(playerId)
    if not state.logged then
        setPlayerPosition(playerId, ColonyConfig.loginSpawn.x, ColonyConfig.loginSpawn.y, ColonyConfig.loginSpawn.z)
        triggerClientEvent(playerId, "colony:disableControls", nil, true)
        return
    end

    setPlayerPosition(playerId, ColonyConfig.spawnPosition.x, ColonyConfig.spawnPosition.y, ColonyConfig.spawnPosition.z)
    ColonyClassSystem.applyClass(playerId, state.classId or 1)
end)

addEventHandler("onPlayerMessage", function(playerId, text)
    local state = ColonyState.ensurePlayer(playerId)
    if not state.logged then
        msg(playerId, 255, 0, 0, "Please log in first.")
        return
    end

    sendNearby(
        playerId,
        ColonyConfig.chatDistances.say,
        { r = 250, g = 250, b = 250 },
        string.format("%s says %s", getPlayerName(playerId), text)
    )
end)

addEventHandler("onPlayerCommand", function(playerId, command, params)
    local cmd = string.lower(command or "")
    cmd = cmd:gsub("^/", "")
    local handler = ColonyCommands.registry[cmd]
    if handler then
        handler(playerId, params or "")
    end
end)

print("addEvent 'colony:updateVisual': ", addEvent("colony:updateVisual", true))
addEventHandler("colony:updateVisual", function(sourceId, bodyModel, bodyTexture, headModel, headTexture)
    if not sourceId then
        return
    end
    setPlayerVisual(sourceId, bodyModel or "", bodyTexture or 0, headModel or "", headTexture or 0)
end)

setTimer(function()
    for _, id in ipairs(ColonyState.listActive()) do
        local state = ColonyState.ensurePlayer(id)
        if state.logged then
            ColonyAccounts.save(id, state)
        end
    end
end, 3 * 60000, 0)
