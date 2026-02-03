CruzerClassSystem = {}

local function applyStats(playerId, stats)
    if stats.maxHealth then
        setPlayerMaxHealth(playerId, stats.maxHealth)
    end
    if stats.health then
        setPlayerHealth(playerId, stats.health)
    end
    if stats.maxMana then
        setPlayerMaxMana(playerId, stats.maxMana)
    end
    if stats.mana then
        setPlayerMana(playerId, stats.mana)
    end
    if stats.magicLevel and setPlayerMagicLevel then
        setPlayerMagicLevel(playerId, stats.magicLevel)
    end
    if stats.strength then
        setPlayerStrength(playerId, stats.strength)
    end
    if stats.dexterity then
        setPlayerDexterity(playerId, stats.dexterity)
    end
end

local function applySkills(playerId, skills)
    if not skills then
        return
    end
    setPlayerSkillWeapon(playerId, SKILL_1H, skills.oneHand or 0)
    setPlayerSkillWeapon(playerId, SKILL_2H, skills.twoHand or 0)
    setPlayerSkillWeapon(playerId, SKILL_BOW, skills.bow or 0)
    setPlayerSkillWeapon(playerId, SKILL_CBOW, skills.crossbow or 0)
end

local function applyItems(playerId, items)
    if not items then
        return
    end
    for _, item in ipairs(items) do
        if item.equip then
            giveItem(playerId, item.instance, 1)
            equipItem(playerId, item.instance)
        else
            giveItem(playerId, item.instance, item.amount or 1)
        end
    end
end

function CruzerClassSystem.applyClass(playerId, state, classId)
    local classData = CruzerClasses[classId]
    if not classData then
        return false
    end

    state.classId = classId
    state.guild = classData.guild or -1

    if state.baseOverlay then
        removePlayerOverlay(playerId, state.baseOverlay)
    end

    if classData.baseOverlay then
        applyPlayerOverlay(playerId, classData.baseOverlay)
        state.baseOverlay = classData.baseOverlay
    else
        state.baseOverlay = nil
    end

    applyStats(playerId, classData.stats or {})
    applySkills(playerId, classData.skills)

    triggerClientEvent(playerId, "cruzer:clearInventory", nil)
    applyItems(playerId, classData.items)

    return true
end

function CruzerClassSystem.isLeader(classId)
    for _, id in ipairs(CruzerConfig.leaderClasses) do
        if id == classId then
            return true
        end
    end
    return false
end

function CruzerClassSystem.getName(classId)
    local classData = CruzerClasses[classId]
    if classData then
        return classData.name
    end
    return "Unknown"
end
