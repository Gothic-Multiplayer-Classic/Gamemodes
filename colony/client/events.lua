local soundCache = {}

local function playSound(file)
    if not file or file == "" then
        return
    end
    if not soundCache[file] then
        soundCache[file] = Sound.new(file)
    end
    soundCache[file]:play()
end

addEvent("colony:disableControls", true)
addEventHandler("colony:disableControls", function(_, toggle)
    disableControls(toggle)
end)

addEvent("colony:showUi", true)
addEventHandler("colony:showUi", function()
    clearMultiplayerMessages()
    ColonyUI.show()
end)

addEvent("colony:hideUi", true)
addEventHandler("colony:hideUi", function()
    ColonyUI.hide()
end)

addEvent("colony:playSound", true)
addEventHandler("colony:playSound", function(_, file)
    playSound(file)
end)
