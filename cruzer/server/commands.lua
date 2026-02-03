CruzerCommands = {}

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

local function resolvePlayerId(nameOrId)
    local id = tonumber(nameOrId)
    if id ~= nil then
        return id
    end
    local targetName = tostring(nameOrId or "")
    for _, playerId in ipairs(CruzerState.listActive()) do
        if getPlayerName(playerId) == targetName then
            return playerId
        end
    end
    return nil
end

local function ensureLogged(playerId, state)
    if state.logged then
        return true
    end
    msg(playerId, 255, 0, 0, "Log in first to use chat.")
    return false
end

local function wrongArgs(playerId, cmd)
    msg(playerId, 255, 0, 0, "Wrong amount of arguments. Usage: " .. cmd)
end
local function lackingPerms(playerId)
    msg(playerId, 255, 0, 0, "You don't have permissions to use this command.")
end

function CruzerCommands.register(playerId, params)
    local args = sscanf("s", params)
    if not args then
        wrongArgs(playerId, "/register (password)")
        return
    end

    local state = CruzerState.ensurePlayer(playerId)
    if state.logged then
        msg(playerId, 255, 0, 0, "You're already logged in!")
        return
    end

    local name = getPlayerName(playerId)
    if CruzerAccounts.exists(name) then
        msg(playerId, 255, 0, 0, "You already have an account. Use /login (password) to log in.")
        return
    end

    state.logged = true
    state.password = args[1]

    setPlayerPosition(playerId, CruzerConfig.spawnPosition.x, CruzerConfig.spawnPosition.y, CruzerConfig.spawnPosition.z)
    msg(playerId, 179, 0, 255, "Registered successfully! You are now logged in.")
    sendMessageToPlayer(playerId, 0, 255, 255, "Check out our website: http://khorinis-roleplay.pl/")
    setPlayerColor(playerId, 255, 255, 255)
    CruzerClassSystem.applyClass(playerId, state, 0)
    CruzerAccounts.save(playerId, state)
    triggerClientEvent(playerId, "cruzer:disableControls", nil, false)
end

function CruzerCommands.login(playerId, params)
    local args = sscanf("s", params)
    if not args then
        wrongArgs(playerId, "/login (password)")
        return
    end

    local state = CruzerState.ensurePlayer(playerId)
    if state.logged then
        msg(playerId, 255, 0, 0, "You're already logged in!")
        return
    end

    local name = getPlayerName(playerId)
    local account = CruzerAccounts.exists(name)
    if not account then
        msg(playerId, 255, 0, 0, "You don't have an account. Use /register (password) to create one.")
        return
    end

    if account.password ~= args[1] then
        msg(playerId, 255, 0, 0, "Wrong password. Use the one you registered with.")
        msg(playerId, 255, 0, 0, "If you don't remember your password, contact the administrator.")
        return
    end

    if getPlayerWorld(playerId) ~= CruzerConfig.defaultWorld then
        setPlayerWorld(playerId, CruzerConfig.defaultWorld)
    end
    CruzerAccounts.load(playerId, state)

    state.logged = true
    CruzerClassSystem.applyClass(playerId, state, state.classId or 0)
    triggerClientEvent(playerId, "cruzer:disableControls", nil, false)
    msg(playerId, 0, 255, 154, "You are logged in! Welcome back " .. name .. "!")
    sendMessageToPlayer(playerId, 0, 255, 255, "Check out our website: http://khorinis-roleplay.pl/")
    setPlayerColor(playerId, 255, 255, 255)
end

function CruzerCommands.nickname(playerId, params)
    local state = CruzerState.ensurePlayer(playerId)
    if state.logged then
        msg(playerId, 255, 0, 0, "You're already logged in!")
        return
    end

    local args = sscanf("s", params)
    if not args then
        wrongArgs(playerId, "/n (name)")
        return
    end

    setPlayerName(playerId, args[1])
    msg(playerId, 119, 255, 0, "Your character name: " .. args[1])

    if CruzerAccounts.exists(args[1]) then
        msg(playerId, 111, 255, 0, "You already have an account. Use /login (password) to log in.")
    else
        msg(playerId, 239, 255, 0, "You don't have an account. Use /register (password) to create one.")
    end
end

function CruzerCommands.pm(playerId, params)
    local args = sscanf("ds", params)
    if not args then
        wrongArgs(playerId, "/pm (id) (message)")
        return
    end

    local id = resolvePlayerId(args[1])
    local text = args[2]
    if not id or id == playerId then
        msg(playerId, 255, 0, 0, "This player isn't connected, or you're writing to yourself.")
        return
    end

    msg(id, 255, 154, 0, string.format("(PM) %s|%d >> %s", getPlayerName(playerId), playerId, text))
    msg(playerId, 255, 68, 0, string.format("(PM) %s|%d << %s", getPlayerName(id), id, text))

    for _, adminId in ipairs(CruzerState.listActive()) do
        local adminState = CruzerState.ensurePlayer(adminId)
        if adminId ~= playerId and adminId ~= id and adminState.seepm then
            msg(adminId, 0, 255, 94, string.format("(PM Preview)| from %s|%d to %s|%d: %s", getPlayerName(playerId), playerId, getPlayerName(id), id, text))
        end
    end
end

function CruzerCommands.ooc(playerId, params)
    if not ensureLogged(playerId, CruzerState.ensurePlayer(playerId)) then
        return
    end
    sendNearby(playerId, CruzerConfig.chatDistances.ooc, { r = 255, g = 255, b = 0 }, string.format("(OOC) %s: %s", getPlayerName(playerId), params))
end

function CruzerCommands.me(playerId, params)
    if not ensureLogged(playerId, CruzerState.ensurePlayer(playerId)) then
        return
    end
    sendNearby(playerId, CruzerConfig.chatDistances.me, { r = 242, g = 86, b = 8 }, string.format("# %s %s #", getPlayerName(playerId), params))
end

function CruzerCommands.doo(playerId, params)
    if not ensureLogged(playerId, CruzerState.ensurePlayer(playerId)) then
        return
    end
    sendNearby(playerId, CruzerConfig.chatDistances.doo, { r = 47, g = 242, b = 8 }, string.format("%s (%s)", params, getPlayerName(playerId)))
end

function CruzerCommands.whisper(playerId, params)
    if not ensureLogged(playerId, CruzerState.ensurePlayer(playerId)) then
        return
    end
    sendNearby(playerId, CruzerConfig.chatDistances.whisper, { r = 0, g = 255, b = 255 }, string.format("%s whispers: %s", getPlayerName(playerId), params))
end

function CruzerCommands.scream(playerId, params)
    if not ensureLogged(playerId, CruzerState.ensurePlayer(playerId)) then
        return
    end
    sendNearby(playerId, CruzerConfig.chatDistances.scream, { r = 242, g = 8, b = 8 }, string.format("%s shouts: %s", getPlayerName(playerId), params))
end

function CruzerCommands.help(playerId, params)
    local args = sscanf("d", params)
    local page = args and args[1] or 1
    if page == 1 then
        msg(playerId, 255, 255, 0, "Available commands on Khorinis RolePlay - Page 1")
        msg(playerId, 255, 255, 0, "Chat based on prefixes instead of commands:")
        msg(playerId, 255, 255, 0, "@ - Out of Character")
        msg(playerId, 255, 255, 0, ". - Surrounding")
        msg(playerId, 255, 255, 0, "! - Shouting")
        msg(playerId, 255, 255, 0, ", - Whisper")
        msg(playerId, 255, 255, 0, "# - Character action")
    elseif page == 2 then
        msg(playerId, 255, 255, 0, "Available commands on Khorinis RolePlay - Page 2")
        msg(playerId, 255, 255, 0, "The same chat but with commands:")
        msg(playerId, 255, 255, 0, "/b - Out of Character")
        msg(playerId, 255, 255, 0, "/do - Surrounding")
        msg(playerId, 255, 255, 0, "/sh - Shouting")
        msg(playerId, 255, 255, 0, "/w - Whisper")
        msg(playerId, 255, 255, 0, "/me - Character action")
    else
        msg(playerId, 255, 255, 0, "Available commands on Khorinis RolePlay - Page 3")
        msg(playerId, 255, 255, 0, "/pm - Private message")
        msg(playerId, 255, 255, 0, "/adm - Message to administrator")
        msg(playerId, 255, 255, 0, "/visual - Change character visual")
        msg(playerId, 255, 255, 0, "/gmsg - Message to guild")
        msg(playerId, 255, 255, 0, "/changepass - Change your password")
        msg(playerId, 255, 255, 0, "/m.help - Moderator help page")
    end
end

function CruzerCommands.modHelp(playerId, params)
    local state = CruzerState.ensurePlayer(playerId)
    if not (state.moderator == 1 or CruzerPermissions.isAdmin(playerId)) then
        lackingPerms(playerId)
        return
    end

    msg(playerId, 255, 255, 0, "Available Moderator commands on Khorinis RolePlay")
    msg(playerId, 255, 255, 0, "/promote - Change player class")
    msg(playerId, 255, 255, 0, "/post - Global message")
    msg(playerId, 255, 255, 0, "/m.kick - Kick player")
    msg(playerId, 255, 255, 0, "/m.all - Shows all players with permissions online")
end

function CruzerCommands.modKick(playerId, params)
    local state = CruzerState.ensurePlayer(playerId)
    if not (state.moderator == 1 or CruzerPermissions.isAdmin(playerId)) then
        lackingPerms(playerId)
        return
    end

    local args = sscanf("ds", params)
    if not args then
        wrongArgs(playerId, "/m.kick (id) (reason)")
        return
    end

    local targetId = resolvePlayerId(args[1])
    if not targetId then
        msg(playerId, 255, 0, 0, "Player is not connected.")
        return
    end

    sendMessageToAll(255, 0, 0, string.format("%s was kicked out by %s, for: %s", getPlayerName(targetId), getPlayerName(playerId), args[2]))
    kick(targetId)
end

function CruzerCommands.modAll(playerId, params)
    local state = CruzerState.ensurePlayer(playerId)
    if not (state.moderator == 1 or CruzerPermissions.isAdmin(playerId) or CruzerClassSystem.isLeader(state.classId)) then
        lackingPerms(playerId)
        return
    end

    msg(playerId, 255, 255, 0, "People with higher permissions currently online:")
    for _, id in ipairs(CruzerState.listActive()) do
        local targetState = CruzerState.ensurePlayer(id)
        if CruzerPermissions.isAdmin(id) then
            msg(playerId, 255, 0, 0, string.format("%d|%s (Administrator)", id, getPlayerName(id)))
        elseif targetState.moderator == 1 then
            msg(playerId, 0, 0, 255, string.format("%d|%s (Moderator)", id, getPlayerName(id)))
        elseif CruzerClassSystem.isLeader(targetState.classId) then
            msg(playerId, 0, 255, 0, string.format("%d|%s (Leader)", id, getPlayerName(id)))
        end
    end
end

function CruzerCommands.post(playerId, params)
    local state = CruzerState.ensurePlayer(playerId)
    if not (state.moderator == 1 or CruzerPermissions.isAdmin(playerId) or CruzerClassSystem.isLeader(state.classId)) then
        lackingPerms(playerId)
        return
    end

    local args = sscanf("s", params)
    if not args then
        wrongArgs(playerId, "/post (message)")
        return
    end

    sendMessageToAll(0, 200, 225, string.format("(GLOBAL) %d|%s: %s", playerId, getPlayerName(playerId), args[1]))
end

function CruzerCommands.changeClass(playerId, params)
    local args = sscanf("dd", params)
    if not args then
        wrongArgs(playerId, "/promote (id) (classId)")
        return
    end

    local state = CruzerState.ensurePlayer(playerId)
    if not (CruzerPermissions.isAdmin(playerId) or state.moderator == 1 or CruzerClassSystem.isLeader(state.classId)) then
        lackingPerms(playerId)
        return
    end

    local targetId = resolvePlayerId(args[1])
    local classId = args[2]

    if not targetId or not CruzerClasses[classId] then
        msg(playerId, 255, 0, 0, "Player or class id not found.")
        return
    end

    local targetState = CruzerState.ensurePlayer(targetId)
    CruzerClassSystem.applyClass(targetId, targetState, classId)
    msg(targetId, 0, 255, 0, "Your class has been changed to: " .. CruzerClassSystem.getName(classId))
    msg(playerId, 0, 255, 0, "Player " .. getPlayerName(targetId) .. " class was changed to: " .. CruzerClassSystem.getName(classId))
end

function CruzerCommands.adm(playerId, params)
    local args = sscanf("s", params)
    if not args then
        return
    end

    for _, id in ipairs(CruzerState.listActive()) do
        if id ~= playerId then
            local targetState = CruzerState.ensurePlayer(id)
            if CruzerPermissions.isAdmin(id) or targetState.moderator == 1 then
                msg(id, 0, 255, 255, "Message for the administrator:")
                msg(id, 0, 255, 255, string.format("(Adm)%d|%s:%s", playerId, getPlayerName(playerId), args[1]))
            end
        end
    end
    msg(playerId, 0, 255, 0, "Message sent.")
end

function CruzerCommands.changePassword(playerId, params)
    local args = sscanf("ss", params)
    if not args then
        wrongArgs(playerId, "/changepass (oldpass) (newpass)")
        return
    end

    local state = CruzerState.ensurePlayer(playerId)
    if not state.logged then
        msg(playerId, 255, 0, 0, "You need to be logged in to change password.")
        return
    end

    if args[1] ~= state.password then
        msg(playerId, 255, 0, 0, "Old password doesn't match your current password.")
        return
    end

    state.password = args[2]
    CruzerAccounts.save(playerId, state)
    msg(playerId, 0, 255, 0, "Password changed.")
end

function CruzerCommands.togglePmSpy(playerId, params)
    local state = CruzerState.ensurePlayer(playerId)
    if not CruzerPermissions.isAdmin(playerId) then
        lackingPerms(playerId)
        return
    end

    state.seepm = not state.seepm
    if state.seepm then
        msg(playerId, 0, 255, 0, "Private messages preview enabled.")
    else
        msg(playerId, 255, 0, 0, "Private messages preview disabled.")
    end
end

function CruzerCommands.visual(playerId, params)
    local args = sscanf("dddd", params)
    if not args then
        wrongArgs(playerId, "/visual (bodyModel1-2) (bodyTexture) (headModel1-7) (headTexture)")
        return
    end

    local bodyModels = { "Hum_Body_Naked0", "Hum_Body_Babe0" }
    local headModels = { "Hum_Head_FatBald", "Hum_Head_Fighter", "Hum_Head_Pony", "Hum_Head_Bald", "Hum_Head_Thief", "Hum_Head_Psionic", "Hum_Head_Babe" }

    local bodyModel = bodyModels[args[1]]
    local headModel = headModels[args[3]]
    if not bodyModel or not headModel then
        msg(playerId, 255, 0, 0, "Wrong model id.")
        return
    end

    setPlayerVisual(playerId, bodyModel, args[2], headModel, args[4])
    msg(playerId, 0, 255, 0, "Visual changed!")
end

function CruzerCommands.guildMessage(playerId, params)
    local args = sscanf("s", params)
    if not args then
        wrongArgs(playerId, "/gmsg (message)")
        return
    end

    local state = CruzerState.ensurePlayer(playerId)
    if state.guild == -1 then
        msg(playerId, 255, 0, 0, "You aren't a member of a guild.")
        return
    end

    for _, id in ipairs(CruzerState.listActive()) do
        local targetState = CruzerState.ensurePlayer(id)
        if targetState.guild == state.guild then
            msg(id, 205, 133, 63, string.format(">|GUILD| %d|%s: %s", playerId, getPlayerName(playerId), args[1]))
        end
    end
end

function CruzerCommands.kall(playerId, params)
    if not CruzerPermissions.isAdmin(playerId) then
        lackingPerms(playerId)
        return
    end

    local args = sscanf("s", params)
    sendMessageToAll(255, 0, 0, args and args[1] or "")

    for _, id in ipairs(CruzerState.listActive()) do
        kick(id)
    end
end

function CruzerCommands.modToggle(playerId, params)
    if not CruzerPermissions.isAdmin(playerId) then
        lackingPerms(playerId)
        return
    end

    local args = sscanf("d", params)
    if not args then
        wrongArgs(playerId, "/mod (id)")
        return
    end

    local targetId = resolvePlayerId(args[1])
    if not targetId then
        msg(playerId, 255, 0, 0, "Player is not connected.")
        return
    end

    local targetState = CruzerState.ensurePlayer(targetId)
    targetState.moderator = targetState.moderator == 1 and 0 or 1
    if targetState.moderator == 1 then
        msg(playerId, 0, 255, 0, "You gave moderator permissions to " .. getPlayerName(targetId) .. "|" .. targetId)
        msg(targetId, 0, 255, 0, "Administrator " .. getPlayerName(playerId) .. "|" .. playerId .. " gave you moderator permissions.")
    else
        msg(playerId, 255, 0, 0, "You took moderator permissions from " .. getPlayerName(targetId) .. "|" .. targetId)
        msg(targetId, 0, 255, 0, "Administrator " .. getPlayerName(playerId) .. "|" .. playerId .. " took away your moderator permissions.")
    end
end

function CruzerCommands.getPos(playerId, params)
    local pos = getPlayerPosition(playerId)
    msg(playerId, 255, 255, 0, string.format("X:%f Y:%f Z:%f", pos.x, pos.y, pos.z))
end

function CruzerCommands.playAnim(playerId, params)
    playAni(playerId, params)
end

CruzerCommands.registry = {
    ["register"] = CruzerCommands.register,
    ["login"] = CruzerCommands.login,
    ["pm"] = CruzerCommands.pm,
    ["pw"] = CruzerCommands.pm,
    ["b"] = CruzerCommands.ooc,
    ["ooc"] = CruzerCommands.ooc,
    ["me"] = CruzerCommands.me,
    ["ja"] = CruzerCommands.me,
    ["do"] = CruzerCommands.doo,
    ["to"] = CruzerCommands.doo,
    ["sh"] = CruzerCommands.scream,
    ["k"] = CruzerCommands.scream,
    ["sz"] = CruzerCommands.whisper,
    ["w"] = CruzerCommands.whisper,
    ["adm"] = CruzerCommands.adm,
    ["help"] = CruzerCommands.help,
    ["promote"] = CruzerCommands.changeClass,
    ["visual"] = CruzerCommands.visual,
    ["post"] = CruzerCommands.post,
    ["gmsg"] = CruzerCommands.guildMessage,
    ["kall"] = CruzerCommands.kall,
    ["changepass"] = CruzerCommands.changePassword,
    ["preview"] = CruzerCommands.togglePmSpy,
    ["m.help"] = CruzerCommands.modHelp,
    ["m.kick"] = CruzerCommands.modKick,
    ["m.all"] = CruzerCommands.modAll,
    ["mod"] = CruzerCommands.modToggle,
    ["n"] = CruzerCommands.nickname,
    ["pos"] = CruzerCommands.getPos,
    ["ani"] = CruzerCommands.playAnim,
}
