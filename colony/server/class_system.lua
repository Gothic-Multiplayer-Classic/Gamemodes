ColonyClassSystem = {}

function ColonyClassSystem.applyClass(playerId, classId)
    local classDef = ColonyClasses[classId] or ColonyClasses[1]
    if classDef and classDef.apply then
        classDef.apply(playerId)
    end
end