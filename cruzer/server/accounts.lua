CruzerAccounts = {}

local function accountsDb(name)
    return JSON("cruzer/" .. name .. ".json")
end

local function buildPayload(playerId, state)
    local position = getPlayerPosition(playerId)
    local angle = getPlayerAngle(playerId) or 0
    local hp = getPlayerHealth(playerId) or 0
    local maxHp = getPlayerMaxHealth(playerId) or 0
    local mana = getPlayerMana(playerId) or 0
    local maxMana = getPlayerMaxMana(playerId) or 0
    local magic = 0
    if getPlayerMagicLevel then
        magic = getPlayerMagicLevel(playerId) or 0
    end
    local str = getPlayerStrength(playerId) or 0
    local dex = getPlayerDexterity(playerId) or 0
    local oneH = getPlayerSkillWeapon(playerId, SKILL_1H) or 0
    local twoH = getPlayerSkillWeapon(playerId, SKILL_2H) or 0
    local bow = getPlayerSkillWeapon(playerId, SKILL_BOW) or 0
    local cbow = getPlayerSkillWeapon(playerId, SKILL_CBOW) or 0
    local visual = getPlayerVisual(playerId) or {}

    return {
        password = state.password,
        classId = state.classId or 0,
        moderator = state.moderator or 0,
        guild = state.guild or 0,
        position = { position.x, position.y, position.z },
        angle = angle,
        stats = { hp, maxHp, mana, maxMana, magic, str, dex },
        skills = { oneH, twoH, bow, cbow },
        visual = {
            bodyModel = visual.bodyModel or "Hum_Body_Naked0",
            bodyTexture = visual.bodyTexture or 9,
            headModel = visual.headModel or "Hum_Head_Pony",
            headTexture = visual.headTexture or 18,
        },
    }
end

function CruzerAccounts.exists(name)
    local db = accountsDb(name)
    if not db then
        return false
    end

    local payload = db:getItem(name)
    if payload == nil then
        return false
    end

    return payload
end

function CruzerAccounts.save(playerId, state)
    if not state.logged or not state.password then
        return false
    end

    local name = getPlayerName(playerId)
    if not name or name == "" then
        return false
    end

    local db = accountsDb(name)
    if not db then
        return false
    end

    local payload = buildPayload(playerId, state)
    db:setItem(name, payload)
    return true
end

function CruzerAccounts.load(playerId, state)
    local name = getPlayerName(playerId)
    if not name or name == "" then
        return false
    end

    local db = accountsDb(name)
    if not db then
        return false
    end

    local payload = db:getItem(name)
    if payload == nil then
        return false
    end

    state.password = payload.password
    state.classId = payload.classId or 0
    state.moderator = payload.moderator or 0
    state.guild = payload.guild or -1

    if payload.position and #payload.position >= 3 then
        setPlayerPosition(playerId, payload.position[1], payload.position[2], payload.position[3])
    end

    if payload.angle then
        setPlayerAngle(playerId, payload.angle)
    end

    if payload.stats and #payload.stats >= 7 then
        setPlayerHealth(playerId, payload.stats[1])
        setPlayerMaxHealth(playerId, payload.stats[2])
        setPlayerMana(playerId, payload.stats[3])
        setPlayerMaxMana(playerId, payload.stats[4])
        if setPlayerMagicLevel then
            setPlayerMagicLevel(playerId, payload.stats[5])
        end
        setPlayerStrength(playerId, payload.stats[6])
        setPlayerDexterity(playerId, payload.stats[7])
    end

    if payload.skills and #payload.skills >= 4 then
        setPlayerSkillWeapon(playerId, SKILL_1H, payload.skills[1])
        setPlayerSkillWeapon(playerId, SKILL_2H, payload.skills[2])
        setPlayerSkillWeapon(playerId, SKILL_BOW, payload.skills[3])
        setPlayerSkillWeapon(playerId, SKILL_CBOW, payload.skills[4])
    end

    if payload.visual then
        setPlayerVisual(
            playerId,
            payload.visual.bodyModel or "Hum_Body_Naked0",
            payload.visual.bodyTexture or 9,
            payload.visual.headModel or "Hum_Head_Pony",
            payload.visual.headTexture or 18
        )
    end

    return true
end
