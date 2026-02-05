ColonyVisuals = {}

local bodyModels = {
    "Hum_Body_Naked0",
    "Hum_Body_Babe0",
}

local headModels = {
    "Hum_Head_Pony",
    "Hum_Head_Fighter",
    "Hum_Head_FatBald",
    "Hum_Head_Bald",
    "Hum_Head_Thief",
    "Hum_Head_Psionic",
    "Hum_Head_Babe",
}

local maxBodyTexture = 12
local maxHeadTexture = 162

local menu = {
    active = false,
    option = 1,
    bodyIndex = 1,
    bodyTexture = 0,
    headIndex = 1,
    headTexture = 0,
}

local bgTexture = Texture.new(0, 0, 256, 256, "DLG_CONVERSATION.TGA")
bgTexture:setPositionPx(350, 240)
bgTexture:setSizePx(350, 220)
bgTexture:setVisible(false)

local menuDraws = {
    Draw.new(nax(400), nay(3000), "Change gender"),
    Draw.new(nax(400), nay(3400), "Change body texture"),
    Draw.new(nax(400), nay(3800), "Change head model"),
    Draw.new(nax(400), nay(4200), "Change head texture"),
}

for index, draw in ipairs(menuDraws) do
    draw:setFont("Font_Old_20_White.TGA")
    draw:setColor(255, 255, 255)
    draw:setPositionPx(380, 260 + (index - 1) * 35)
    draw:setVisible(false)
end

local function findIndex(list, value)
    for index, entry in ipairs(list) do
        if entry == value then
            return index
        end
    end
    return 1
end

local function updateMenuSelection()
    for index, draw in ipairs(menuDraws) do
        if index == menu.option then
            draw:setColor(0, 250, 0)
        else
            draw:setColor(255, 255, 255)
        end
    end
end

local function updateVisual()
    local bodyModel = bodyModels[menu.bodyIndex]
    local headModel = headModels[menu.headIndex]
    setPlayerVisual(heroId, bodyModel, menu.bodyTexture, headModel, menu.headTexture)
    triggerServerEvent("colony:updateVisual", heroId, bodyModel, menu.bodyTexture, headModel, menu.headTexture)
end

local function wrapValue(value, minValue, maxValue)
    if value > maxValue then
        return minValue
    end
    if value < minValue then
        return maxValue
    end
    return value
end

local function toggleMenu(toggle)
    menu.active = toggle
    bgTexture:setVisible(toggle)
    for _, draw in ipairs(menuDraws) do
        draw:setVisible(toggle)
    end
    if toggle then
        menu.option = 1
        local visual = getPlayerVisual(heroId) or {}
        menu.bodyIndex = findIndex(bodyModels, visual.bodyModel)
        menu.bodyTexture = visual.bodyTexture or 0
        menu.headIndex = findIndex(headModels, visual.headModel)
        menu.headTexture = visual.headTexture or 0
        updateMenuSelection()
    end
    disableControls(toggle)
end

addEventHandler("onKeyDown", function(key)
    if key == KEY_F7 and not menu.active then
        toggleMenu(true)
        return
    end

    if not menu.active then
        return
    end

    if key == KEY_ESCAPE then
        toggleMenu(false)
        return
    end

    if key == KEY_DOWN then
        menu.option = wrapValue(menu.option + 1, 1, 4)
        updateMenuSelection()
        return
    end

    if key == KEY_UP then
        menu.option = wrapValue(menu.option - 1, 1, 4)
        updateMenuSelection()
        return
    end

    if key == KEY_RIGHT then
        if menu.option == 1 then
            menu.bodyIndex = wrapValue(menu.bodyIndex + 1, 1, #bodyModels)
        elseif menu.option == 2 then
            menu.bodyTexture = wrapValue(menu.bodyTexture + 1, 0, maxBodyTexture)
        elseif menu.option == 3 then
            menu.headIndex = wrapValue(menu.headIndex + 1, 1, #headModels)
        elseif menu.option == 4 then
            menu.headTexture = wrapValue(menu.headTexture + 1, 0, maxHeadTexture)
        end
        updateVisual()
        return
    end

    if key == KEY_LEFT then
        if menu.option == 1 then
            menu.bodyIndex = wrapValue(menu.bodyIndex - 1, 1, #bodyModels)
        elseif menu.option == 2 then
            menu.bodyTexture = wrapValue(menu.bodyTexture - 1, 0, maxBodyTexture)
        elseif menu.option == 3 then
            menu.headIndex = wrapValue(menu.headIndex - 1, 1, #headModels)
        elseif menu.option == 4 then
            menu.headTexture = wrapValue(menu.headTexture - 1, 0, maxHeadTexture)
        end
        updateVisual()
    end
end)
