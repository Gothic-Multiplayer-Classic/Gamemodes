ColonyCommands = { registry = {} }

local function msg(playerId, r, g, b, text)
    sendMessageToPlayer(playerId, r, g, b, text)
end

local function broadcast(r, g, b, text)
    sendMessageToAll(r, g, b, text)
end

local function sendNearby(playerId, radius, color, message)
    local pos = getPlayerPosition(playerId)
    local world = getPlayerWorld(playerId)
    local nearby = findNearbyPlayers(pos, radius, world)
    for _, targetId in ipairs(nearby) do
        msg(targetId, color.r, color.g, color.b, message)
    end
end

local function ensureLogged(playerId, state)
    if state.logged then
        return true
    end
    msg(playerId, 255, 0, 0, "Please log in first.")
    return false
end

local function wrongArgs(playerId, cmd)
    msg(playerId, 255, 255, 255, "Usage: " .. cmd)
end

local function applyNameColor(playerId)
    local name = getPlayerName(playerId)
    if ColonyUtil.nameInList(name, ColonyConfig.colorGroups.red) then
        setPlayerColor(playerId, 255, 0, 0)
    elseif ColonyUtil.nameInList(name, ColonyConfig.colorGroups.green) then
        setPlayerColor(playerId, 0, 255, 0)
    elseif ColonyUtil.nameInList(name, ColonyConfig.colorGroups.violet) then
        setPlayerColor(playerId, 238, 130, 238)
    elseif ColonyUtil.nameInList(name, ColonyConfig.colorGroups.sky) then
        setPlayerColor(playerId, 135, 206, 235)
    end
end

local function setModerator(state, playerId)
    state.moderator = ColonyUtil.nameInList(getPlayerName(playerId), ColonyConfig.moderators)
end

local function clearChatForPlayer(playerId)
    for _ = 1, 14 do
        msg(playerId, 255, 255, 255, " ")
    end
end

local function clearChatForAll()
    for _ = 1, 14 do
        broadcast(255, 255, 255, " ")
    end
end

local function registerCommand(name, fn)
    local normalized = string.lower(name or "")
    normalized = normalized:gsub("^/", "")
    ColonyCommands.registry[normalized] = fn
end

registerCommand("fat", function(playerId, params)
    local args = sscanf("d", params)
    if not args then
        wrongArgs(playerId, "/fat <0-2>")
        return
    end
    local value = args[1]
    if value < 0 or value > 2 then
        wrongArgs(playerId, "/fat <0-2>")
        return
    end
    setPlayerFatness(playerId, value)
end)

registerCommand("wzrost", function(playerId, params)
    local args = sscanf("d", params)
    if not args then
        wrongArgs(playerId, "/wzrost <0-2>")
        return
    end
    local value = args[1]
    if value == 0 then
        setPlayerScale(playerId, 1.0, 1.0, 1.0)
    elseif value == 1 then
        setPlayerScale(playerId, 1.02, 1.02, 1.02)
    elseif value == 2 then
        setPlayerScale(playerId, 1.05, 1.05, 1.05)
    else
        wrongArgs(playerId, "/wzrost <0-2>")
    end
end)

registerCommand("help", function(playerId)
    msg(playerId, 0, 0, 255, "-----------Server Help Menu-----------")
    msg(playerId, 0, 196, 255, "/chats - Lists all available chats.")
    msg(playerId, 0, 196, 255, "/functions - Lists additional features")
end)

registerCommand("chats", function(playerId)
    msg(playerId, 0, 0, 255, "-----------Chats-----------")
    msg(playerId, 0, 196, 255, "/b - OOC")
    msg(playerId, 0, 196, 255, "/me - Action")
    msg(playerId, 0, 196, 255, "/do - Surroundings")
    msg(playerId, 0, 196, 255, "/sz - Whisper")
    msg(playerId, 0, 196, 255, "/k - Shout")
end)

registerCommand("functions", function(playerId)
    msg(playerId, 0, 0, 255, "-----------Features-----------")
    msg(playerId, 0, 196, 255, "/anims - Shows all available animations on the server.")
    msg(playerId, 0, 196, 255, "/styles - Lists all walking styles you can use")
    msg(playerId, 0, 196, 255, "/clear - Clears chat.")
    msg(playerId, 0, 196, 255, "/pm - Sends a private message to another player.")
    msg(playerId, 0, 196, 255, "For more information, type /functions2")
end)

registerCommand("functions2", function(playerId)
    msg(playerId, 0, 0, 255, "-----------Features2-----------")
    msg(playerId, 0, 196, 255, "/changepass - Change password")
    msg(playerId, 0, 196, 255, "/fat - Increases body size")
    msg(playerId, 0, 196, 255, "/height - Increases height")
    msg(playerId, 0, 196, 255, "/afk - Announces that you're away from the keyboard")
    msg(playerId, 0, 196, 255, "/jj - Announces that you're back at the keyboard")
end)

registerCommand("clear", function(playerId)
    clearChatForPlayer(playerId)
end)

registerCommand("aclear", function(playerId)
    local state = ColonyState.ensurePlayer(playerId)
    if ColonyPermissions.isAdmin(playerId) or ColonyPermissions.isModerator(playerId, state) then
        clearChatForAll()
    else
        msg(playerId, 255, 0, 0, "You don't have permission to use this command.")
    end
end)

registerCommand("restart", function(playerId)
    if not ColonyPermissions.isAdmin(playerId) then
        msg(playerId, 255, 0, 0, "You don't have permission to use this command.")
        return
    end
    for _, id in ipairs(ColonyState.listActive()) do
        ColonyAccounts.save(id, ColonyState.ensurePlayer(id))
        kick(id, "Restart")
    end
end)

registerCommand("afk", function(playerId)
    local state = ColonyState.ensurePlayer(playerId)
    if not ensureLogged(playerId, state) then
        return
    end
    triggerClientEvent(playerId, "colony:disableControls", nil, true)
    playAni(playerId, "T_STAND_2_SIT")
    msg(playerId, 192, 192, 192, "If you return to the game, type /jj")
    broadcast(192, 192, 192, string.format("%s (ID:%d) went AFK!", getPlayerName(playerId), playerId))
    setPlayerColor(playerId, 54, 65, 63)
end)

registerCommand("jj", function(playerId)
    local state = ColonyState.ensurePlayer(playerId)
    if not ensureLogged(playerId, state) then
        return
    end
    triggerClientEvent(playerId, "colony:disableControls", nil, false)
    msg(playerId, 192, 192, 192, "Are you back?")
    broadcast(192, 192, 192, string.format("%s (ID:%d) is back!", getPlayerName(playerId), playerId))
    setPlayerColor(playerId, 250, 250, 250)
    applyNameColor(playerId)
end)

registerCommand("me", function(playerId, params)
    local state = ColonyState.ensurePlayer(playerId)
    if not ensureLogged(playerId, state) then
        return
    end
    sendNearby(playerId, ColonyConfig.chatDistances.me, { r = 255, g = 128, b = 0 }, string.format("(%d)%s #%s#", playerId, getPlayerName(playerId), params))
end)

registerCommand("do", function(playerId, params)
    local state = ColonyState.ensurePlayer(playerId)
    if not ensureLogged(playerId, state) then
        return
    end
    sendNearby(playerId, ColonyConfig.chatDistances.doo, { r = 119, g = 0, b = 255 }, string.format("(%d)(%s)%s", playerId, getPlayerName(playerId), params))
end)

registerCommand("b", function(playerId, params)
    local state = ColonyState.ensurePlayer(playerId)
    if not ensureLogged(playerId, state) then
        return
    end
    sendNearby(playerId, ColonyConfig.chatDistances.ooc, { r = 0, g = 137, b = 255 }, string.format("(OOC)(%d)%s (%s)", playerId, getPlayerName(playerId), params))
end)

registerCommand("g", function(playerId, params)
    local state = ColonyState.ensurePlayer(playerId)
    if not ensureLogged(playerId, state) then
        return
    end
    if ColonyPermissions.isAdmin(playerId)
        or ColonyPermissions.isModerator(playerId, state)
        or ColonyConfig.globalChatClasses[state.classId] then
        broadcast(229, 87, 5, string.format("%s: %s", getPlayerName(playerId), params))
    else
        msg(playerId, 250, 0, 0, "You don't have permission to use global chat!")
    end
end)

registerCommand("k", function(playerId, params)
    local state = ColonyState.ensurePlayer(playerId)
    if not ensureLogged(playerId, state) then
        return
    end
    sendNearby(playerId, ColonyConfig.chatDistances.scream, { r = 255, g = 34, b = 0 }, string.format("%s shouts %s", getPlayerName(playerId), params))
end)

registerCommand("sz", function(playerId, params)
    local state = ColonyState.ensurePlayer(playerId)
    if not ensureLogged(playerId, state) then
        return
    end
    sendNearby(playerId, ColonyConfig.chatDistances.whisper, { r = 0, g = 255, b = 247 }, string.format("%s whispers %s", getPlayerName(playerId), params))
end)

registerCommand("pm", function(playerId, params)
    local args = sscanf("ds", params)
    if not args then
        wrongArgs(playerId, "/pm playerId message")
        return
    end
    local targetId = args[1]
    if not isPlayerConnected(targetId) then
        msg(playerId, 255, 0, 0, "That player is not connected to the server!")
        return
    end
    msg(targetId, 255, 205, 0, string.format("(PM)(ID:%d) << %s %s", playerId, getPlayerName(playerId), args[2]))
    msg(playerId, 188, 255, 0, string.format("(PM)(ID:%d) >> %s %s", playerId, getPlayerName(targetId), args[2]))
end)

registerCommand("promote", function(playerId, params)
    local state = ColonyState.ensurePlayer(playerId)
    if not ColonyPermissions.isAdmin(playerId) and not ColonyPermissions.isModerator(playerId, state) then
        msg(playerId, 255, 0, 0, "You don't have the required permissions.")
        return
    end

    local args = sscanf("dd", params)
    if not args then
        wrongArgs(playerId, "/promote (player ID) (class ID)")
        return
    end

    local targetId = args[1]
    local classId = args[2]
    if not isPlayerConnected(targetId) then
        msg(playerId, 255, 0, 0, string.format("Player with ID %d is not connected to the server.", targetId))
        return
    end

    if not ColonyClasses[classId] then
        msg(playerId, 255, 0, 0, "Invalid class ID.")
        return
    end

    local targetState = ColonyState.ensurePlayer(targetId)
    targetState.classId = classId
    ColonyClassSystem.applyClass(targetId, classId)
    ColonyAccounts.save(targetId, targetState)

    msg(targetId, 255, 205, 0, string.format("You have become: %s", ColonyClasses[classId].name or ("Class " .. classId)))
    msg(playerId, 255, 205, 0, string.format("Promotion granted to %s (ID %d).", getPlayerName(targetId), targetId))
end)

registerCommand("nick", function(playerId, params)
    local state = ColonyState.ensurePlayer(playerId)
    if state.logged then
        msg(playerId, 255, 0, 0, "You are already logged in.")
        return
    end
    local args = sscanf("s", params)
    if not args then
        wrongArgs(playerId, "/nick Nick")
        return
    end
    setPlayerName(playerId, args[1])
    if ColonyAccounts.exists(args[1]) then
        msg(playerId, 0, 0, 255, "You're in the database. Type: /login password!")
    else
        msg(playerId, 0, 0, 255, "You're not in the database. Type: /register password!")
    end
end)

registerCommand("register", function(playerId, params)
    local state = ColonyState.ensurePlayer(playerId)
    if state.logged then
        msg(playerId, 255, 0, 0, "You are already registered!")
        return
    end

    local args = sscanf("s", params)
    if not args then
        wrongArgs(playerId, "/register password")
        return
    end

    local name = getPlayerName(playerId)
    if ColonyAccounts.exists(name) then
        msg(playerId, 255, 0, 0, "That account already exists!")
        return
    end

    state.password = args[1]
    state.logged = true
    setModerator(state, playerId)

    setPlayerPosition(playerId, ColonyConfig.spawnPosition.x, ColonyConfig.spawnPosition.y, ColonyConfig.spawnPosition.z)
    ColonyClassSystem.applyClass(playerId, 1)
    setPlayerColor(playerId, 255, 255, 255)
    applyNameColor(playerId)
    ColonyAccounts.save(playerId, state)
    triggerClientEvent(playerId, "colony:disableControls", nil, false)
    msg(playerId, 0, 255, 60, "Registration completed successfully :>!")
end)

registerCommand("login", function(playerId, params)
    local state = ColonyState.ensurePlayer(playerId)
    if state.logged then
        msg(playerId, 255, 0, 0, "You are already logged in!")
        return
    end

    local args = sscanf("s", params)
    if not args then
        wrongArgs(playerId, "/login password")
        return
    end

    local name = getPlayerName(playerId)
    local account = ColonyAccounts.exists(name)
    if not account then
        msg(playerId, 255, 0, 0, "You don't have an account here! Register first!")
        return
    end

    if account.password ~= args[1] then
        msg(playerId, 255, 0, 0, "The provided password is incorrect!")
        return
    end

    if getPlayerWorld(playerId) ~= ColonyConfig.defaultWorld then
        setPlayerWorld(playerId, ColonyConfig.defaultWorld)
    end

    ColonyAccounts.load(playerId, state)
    state.logged = true
    setModerator(state, playerId)
    ColonyClassSystem.applyClass(playerId, state.classId or 1)
    triggerClientEvent(playerId, "colony:disableControls", nil, false)
    msg(playerId, 0, 255, 60, "You have logged in!")
    setPlayerColor(playerId, 255, 255, 255)
    applyNameColor(playerId)
end)

registerCommand("changepass", function(playerId, params)
    local state = ColonyState.ensurePlayer(playerId)
    if not state.logged then
        msg(playerId, 255, 0, 0, "You must be logged in to change your password!")
        return
    end
    local args = sscanf("ss", params)
    if not args then
        wrongArgs(playerId, "/changepass old_password new_password")
        return
    end
    if args[1] ~= state.password then
        msg(playerId, 255, 0, 0, "You didn't enter your password correctly!")
        return
    end
    state.password = args[2]
    ColonyAccounts.save(playerId, state)
    msg(playerId, 0, 255, 60, "Password changed!")
end)

registerCommand("ban", function(playerId, params)
    local state = ColonyState.ensurePlayer(playerId)
    if not ColonyPermissions.isAdmin(playerId) and not ColonyPermissions.isModerator(playerId, state) then
        msg(playerId, 255, 250, 200, "(Server): You are not an admin/moderator.")
        return
    end
    local args = sscanf("ds", params)
    if not args then
        wrongArgs(playerId, "/ban (player ID) (reason)")
        return
    end
    local id = args[1]
    if not isPlayerConnected(id) then
        msg(playerId, 255, 250, 200, string.format("(Server): Player with ID %d is not connected to the server.", id))
        return
    end
    broadcast(255, 0, 0, string.format("(Server): %s was banned by %s. Reason: %s", getPlayerName(id), getPlayerName(playerId), args[2]))
    ban(id, args[2])
end)

registerCommand("kick", function(playerId, params)
    local state = ColonyState.ensurePlayer(playerId)
    if not ColonyPermissions.isAdmin(playerId) and not ColonyPermissions.isModerator(playerId, state) then
        msg(playerId, 255, 250, 200, "(Server): You are not an admin/moderator.")
        return
    end
    local args = sscanf("ds", params)
    if not args then
        wrongArgs(playerId, "/kick (player ID) (reason)")
        return
    end
    local id = args[1]
    if not isPlayerConnected(id) then
        msg(playerId, 255, 250, 200, string.format("(Server): Player with ID %d is not connected to the server.", id))
        return
    end
    broadcast(255, 0, 0, string.format("(Server): %s was kicked by %s. Reason: %s", getPlayerName(id), getPlayerName(playerId), args[2]))
    kick(id, args[2])
end)

registerCommand("tp", function(playerId, params)
    local state = ColonyState.ensurePlayer(playerId)
    if not ColonyPermissions.isAdmin(playerId) and not ColonyPermissions.isModerator(playerId, state) then
        msg(playerId, 255, 250, 200, "(Server): You are not an admin/moderator")
        return
    end
    local args = sscanf("dd", params)
    if not args then
        wrongArgs(playerId, "/tp (from player) (to player id)")
        return
    end
    local fromId = args[1]
    local toId = args[2]
    if not isPlayerConnected(fromId) then
        msg(playerId, 255, 250, 200, string.format("(Server): Player with ID %d is not connected to the server.", fromId))
        return
    end
    if not isPlayerConnected(toId) then
        msg(playerId, 255, 250, 200, string.format("(Server): Player with ID %d is not connected to the server.", toId))
        return
    end
    local pos = getPlayerPosition(toId)
    setPlayerPosition(fromId, pos.x + 50, pos.y, pos.z)
    msg(fromId, 255, 250, 200, string.format("You teleported to %s", getPlayerName(toId)))
    msg(toId, 255, 250, 200, string.format("%s teleported to you", getPlayerName(fromId)))
end)

local animationCommands = {
    ["/pray3"] = { anim = "T_PRAY_2_STAND", label = "Pray3" },
    ["/pray2"] = { anim = "T_STAND_2_PRAY", label = "Pray2" },
    ["/dance4"] = { anim = "T_DANCE_05", label = "Dance4" },
    ["/dance3"] = { anim = "T_DANCE_04", label = "Dance3" },
    ["/dance2"] = { anim = "T_DANCE_03", label = "Dance2" },
    ["/levitate"] = { anim = "S_HEASHOOT", label = "Levitate" },
    ["/cheer"] = { anim = "T_WATCHFIGHT_YEAH", label = "Cheering" },
    ["/repair"] = { anim = "S_REPAIR_S1", label = "Repairing" },
    ["/sit"] = { anim = "T_STAND_2_SIT", label = "Sit" },
    ["/sleep"] = { anim = "T_STAND_2_SLEEPGROUND", label = "Sleep" },
    ["/pee"] = { anim = "T_STAND_2_PEE", label = "Pee" },
    ["/train"] = { anim = "T_1HSFREE", label = "Train" },
    ["/inspect"] = { anim = "T_1HSINSPECT", label = "Inspect" },
    ["/pray1"] = { anim = "S_PRAY", label = "Pray" },
    ["/look"] = { anim = "T_SEARCH", label = "Look around" },
    ["/gather"] = { anim = "T_PLUNDER", label = "Gather" },
    ["/guard1"] = { anim = "S_LGUARD", label = "Guard1" },
    ["/guard2"] = { anim = "S_HGUARD", label = "Guard2" },
    ["/finish"] = { anim = "T_1HSFINISH", label = "Finish off" },
    ["/death"] = { anim = "S_DEAD", label = "Death" },
    ["/wash"] = { anim = "S_WASH", label = "Wash" },
    ["/magic1"] = { anim = "T_PRACTICEMAGIC", label = "Magic1" },
    ["/magic2"] = { anim = "T_PRACTICEMAGIC2", label = "Magic2" },
    ["/magic3"] = { anim = "T_PRACTICEMAGIC3", label = "Magic3" },
    ["/magic4"] = { anim = "T_PRACTICEMAGIC4", label = "Magic4" },
    ["/dance1"] = { anim = "S_FIRE_VICTIM", label = "Dance1" },
    ["/bow"] = { anim = "T_GREETNOV", label = "Bow" },
    ["/no"] = { anim = "T_NO", label = "No" },
    ["/facepalm"] = { anim = "T_WATCHFIGHT_OHNO", label = "Facepalm" },
    ["/levitate2"] = { anim = "S_SUCKENERGY_VICTIM", label = "Levitate2" },
    ["/hand1"] = { anim = "T_COMEOVERHERE", label = "Hand1" },
    ["/hand2"] = { anim = "T_FORGETIT", label = "Hand2" },
    ["/hand3"] = { anim = "T_GETLOST", label = "Hand3" },
    ["/hand4"] = { anim = "T_GREETCOOL", label = "Hand4" },
    ["/hand5"] = { anim = "T_GREETRIGHT", label = "Hand5" },
    ["/scratch1"] = { anim = "R_SCRATCHEGG", label = "Scratch1" },
    ["/scratch2"] = { anim = "R_SCRATCHHEAD", label = "Scratch2" },
    ["/scratch3"] = { anim = "R_SCRATCHLSHOULDER", label = "Scratch3" },
    ["/leg1"] = { anim = "R_LEGSHAKE", label = "Leg1" },
    ["/leg2"] = { anim = "T_BORINGKICK", label = "Leg2" },
    ["/death2"] = { anim = "S_DEADB", label = "Death2" },
}

for command, data in pairs(animationCommands) do
    registerCommand(command, function(playerId)
        playAni(playerId, data.anim)
        msg(playerId, 238, 180, 34, "You started the animation: " .. data.label)
    end)
end

registerCommand("animations", function(playerId)
    msg(playerId, 0, 0, 255, "|||Available animations|||")
    msg(playerId, 0, 196, 255, "/sit, /sleep, /pee, /train, /inspect, /look")
    msg(playerId, 0, 196, 255, "/gather, /guard1, /guard2, /finish, /wash, /magic1, /magic2, /magic3, /magic4")
    msg(playerId, 0, 196, 255, "/dance1, /dance2, /dance3, /dance4, /repair, /cheer, /levitate, /levitate2")
    msg(playerId, 0, 196, 255, "/pray1, /pray2, /pray3, /bow, /no, /facepalm, /hand1, /hand2, /hand3")
    msg(playerId, 0, 196, 255, "/hand4, /hand5, /scratch1, /scratch2, /scratch3, /leg1, /leg2, /death, /death2")
end)

registerCommand("styles", function(playerId)
    msg(playerId, 0, 0, 255, "|||Available walking styles|||")
    msg(playerId, 0, 196, 255, "/style guard - guard walking style")
    msg(playerId, 0, 196, 255, "/style woman - female walking style")
    msg(playerId, 0, 196, 255, "/style mage - mage walking style")
    msg(playerId, 0, 196, 255, "/style relaxed - relaxed walking style")
    msg(playerId, 0, 196, 255, "/style arrogant - arrogant walking style")
    msg(playerId, 0, 196, 255, "/style tired - tired walking style")
end)

registerCommand("style", function(playerId, params)
    local args = sscanf("s", params)
    if not args then
        wrongArgs(playerId, "/style (guard|woman|mage|relaxed|arrogant|tired)")
        return
    end

    local styleKey = string.lower(args[1])
    local overlays = {
        guard = "Humans_Militia.mds",
        woman = "Humans_Babe.mds",
        mage = "Humans_Mage.mds",
        relaxed = "Humans_Relaxed.mds",
        arrogant = "Humans_Arrogance.mds",
        tired = "Humans_Tired.mds",
    }

    local overlay = overlays[styleKey]
    if not overlay then
        wrongArgs(playerId, "/style (guard|woman|mage|relaxed|arrogant|tired)")
        return
    end

    local state = ColonyState.ensurePlayer(playerId)
    if state.walkOverlay then
        removePlayerOverlay(playerId, state.walkOverlay)
    end
    applyPlayerOverlay(playerId, overlay)
    state.walkOverlay = overlay
    msg(playerId, 238, 180, 34, "Current walking style: " .. styleKey)
end)
