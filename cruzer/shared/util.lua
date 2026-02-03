CruzerUtil = {}

function CruzerUtil.trim(value)
    if value == nil then
        return ""
    end
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

function CruzerUtil.splitWords(value)
    local out = {}
    for token in string.gmatch(value or "", "%S+") do
        table.insert(out, token)
    end
    return out
end

function CruzerUtil.parseNumbers(value)
    local out = {}
    for token in string.gmatch(value or "", "[-%d%.]+") do
        table.insert(out, tonumber(token))
    end
    return out
end

function CruzerUtil.parseKeyValue(line)
    if not line then
        return nil, nil
    end
    local key, value = line:match("^(%w+)%s*=%s*(.*)$")
    if not key then
        return nil, nil
    end
    return key, CruzerUtil.trim(value)
end

function CruzerUtil.distanceSquared(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz
end