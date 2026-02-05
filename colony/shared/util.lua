ColonyUtil = {}

function ColonyUtil.normalize(name)
    return string.upper(name or "")
end

function ColonyUtil.nameInList(name, list)
    if not name or not list then
        return false
    end
    local needle = ColonyUtil.normalize(name)
    for _, entry in ipairs(list) do
        if needle == ColonyUtil.normalize(entry) then
            return true
        end
    end
    return false
end