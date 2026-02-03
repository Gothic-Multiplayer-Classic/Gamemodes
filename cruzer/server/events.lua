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

local function getChatType(text)
    if not text or text == "" then
        return "RP", text
    end

    local first = text:sub(1, 1)
    if first == "!" then
        return "SCREAM", text:sub(2)
    elseif first == "," then
        return "WHISPER", text:sub(2)
    elseif first == "." then
        return "TO", text:sub(2)
    elseif first == "@" then
        return "OOC", text:sub(2)
    elseif first == "#" then
        return "ME", text:sub(2)
    end
    return "RP", text
end

local function formatChatMessage(playerId, messageType, text)
    local name = getPlayerName(playerId)
    if messageType == "RP" then
        return string.format("(%d) %s says: %s", playerId, name, text)
    elseif messageType == "SCREAM" then
        return string.format("%s shouts: %s", name, text)
    elseif messageType == "WHISPER" then
        return string.format("%s whispers: %s", name, text)
    elseif messageType == "TO" then
        return string.format("%s (%s)", text, name)
    elseif messageType == "OOC" then
        return string.format("(OOC) %s: %s", name, text)
    elseif messageType == "ME" then
        return string.format("# %s %s #", name, text)
    end
    return text
end

addEventHandler("onPlayerConnect", function(playerId)
    spawnPlayer(playerId)
    print(getPlayerIP(playerId))

    CruzerState.ensurePlayer(playerId)
    CruzerState.markActive(playerId)

    msg(playerId, 0, 255, 0, "-- Original gamemode written by V0iD, upgraded by NolFejs --")
    msg(playerId, 0, 255, 0, "")
    msg(playerId, 255, 145, 0, "Welcome to Khorinis RolePlay!")
    msg(playerId, 255, 145, 0, "Type /help to learn how to play on the server!")
    msg(playerId, 0, 255, 0, "Type /n (name) to set the name of your character.")

    setPlayerColor(playerId, 0, 255, 0)
    triggerClientEvent(playerId, "cruzer:showUi", nil)
    triggerClientEvent(playerId, "cruzer:disableControls", nil, true)
end)

addEventHandler("onPlayerDisconnect", function(playerId, reason)
    local state = CruzerState.ensurePlayer(playerId)
    if state.logged then
        CruzerAccounts.save(playerId, state)
        sendMessageToAll(255, 0, 0, string.format("%s left the game.", getPlayerName(playerId)))
    end

    triggerClientEvent(playerId, "cruzer:hideUi", nil)
    CruzerState.removePlayer(playerId)
end)

addEventHandler("onPlayerSpawn", function(playerId, posX, posY, posZ)
    local state = CruzerState.ensurePlayer(playerId)
    if not state.logged then
        setPlayerPosition(playerId, CruzerConfig.loginSpawn.x, CruzerConfig.loginSpawn.y, CruzerConfig.loginSpawn.z)
        triggerClientEvent(playerId, "cruzer:disableControls", nil, true)
        return
    end

    CruzerClassSystem.applyClass(playerId, state, state.classId or 0)
end)

addEventHandler("onPlayerMessage", function(playerId, text)
    local state = CruzerState.ensurePlayer(playerId)
    if not state.logged then
        msg(playerId, 255, 0, 0, "Log in first to use chat.")
        return
    end

    local msgType, sanitized = getChatType(text)
    local message = formatChatMessage(playerId, msgType, sanitized)

    if msgType == "SCREAM" then
        sendNearby(playerId, CruzerConfig.chatDistances.scream, { r = 242, g = 8, b = 8 }, message)
    elseif msgType == "WHISPER" then
        sendNearby(playerId, CruzerConfig.chatDistances.whisper, { r = 0, g = 255, b = 255 }, message)
    elseif msgType == "TO" then
        sendNearby(playerId, CruzerConfig.chatDistances.doo, { r = 47, g = 242, b = 8 }, message)
    elseif msgType == "OOC" then
        sendNearby(playerId, CruzerConfig.chatDistances.ooc, { r = 255, g = 255, b = 0 }, message)
    elseif msgType == "ME" then
        sendNearby(playerId, CruzerConfig.chatDistances.me, { r = 242, g = 86, b = 8 }, message)
    else
        sendNearby(playerId, CruzerConfig.chatDistances.say, { r = 230, g = 230, b = 230 }, message)
    end
end)

addEventHandler("onPlayerCommand", function(playerId, command, params)
    local cmd = string.lower(command or "")
    local handler = CruzerCommands.registry[cmd]
    if handler then
        handler(playerId, params or "")
    end
end)

--[[ addEventHandler("onPlayerHit", function(attackerId, victimId, damage)
    if not attackerId then
        return
    end
    local state = CruzerState.ensurePlayer(attackerId)
    if state.classId == 0 then
        kick(attackerId)
    end
end) ]]

addEventHandler("onPlayerWeaponModeChange", function(playerId, oldMode, newMode)
    local state = CruzerState.ensurePlayer(playerId)
    if state.classId == 0 and newMode ~= WEAPON_NONE then
        msg(playerId, 255, 0, 0, "You're too weak to fight.")
        setPlayerWeaponMode(playerId, WEAPON_NONE)
        return
    end

    local oneH = getPlayerSkillWeapon(playerId, SKILL_1H) or 0
    local twoH = getPlayerSkillWeapon(playerId, SKILL_2H) or 0
    local bow = getPlayerSkillWeapon(playerId, SKILL_BOW) or 0
    local cbow = getPlayerSkillWeapon(playerId, SKILL_CBOW) or 0

    if state.weaponOverlay then
        removePlayerOverlay(playerId, state.weaponOverlay)
        state.weaponOverlay = nil
    end

    local overlay = nil
    if newMode == WEAPON_1H then
        if oneH >= 60 then
            overlay = "Humans_1hST2.mds"
        elseif oneH >= 30 then
            overlay = "Humans_1hST1.mds"
        end
    elseif newMode == WEAPON_2H then
        if twoH >= 60 then
            overlay = "Humans_2hST2.mds"
        elseif twoH >= 30 then
            overlay = "Humans_2hST1.mds"
        end
    elseif newMode == WEAPON_BOW then
        if bow >= 60 then
            overlay = "Humans_BowT2.mds"
        elseif bow >= 30 then
            overlay = "Humans_BowT1.mds"
        end
    elseif newMode == WEAPON_CBOW then
        if cbow >= 60 then
            overlay = "Humans_CBowT2.mds"
        elseif cbow >= 30 then
            overlay = "Humans_CBowT1.mds"
        end
    end

    if overlay then
        applyPlayerOverlay(playerId, overlay)
        state.weaponOverlay = overlay
    end
end)

setTimer(function()
    for _, id in ipairs(CruzerState.listActive()) do
        local state = CruzerState.ensurePlayer(id)
        if state.logged then
            CruzerAccounts.save(id, state)
        end
    end
end, 3 * 60000, 0)
