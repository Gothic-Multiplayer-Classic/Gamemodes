CruzerPermissions = {}

local function normalize(name)
    return string.upper(name or "")
end

function CruzerPermissions.isAdmin(playerId)
    local name = getPlayerName(playerId)
    if not name then
        return false
    end

    local upperName = normalize(name)
    for _, adminName in ipairs(CruzerConfig.admins) do
        if upperName == normalize(adminName) then
            return true
        end
    end
    return false
end
