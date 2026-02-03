CruzerUI = {}

local bg = Texture.new(0, 0, 256, 256, "DLG_CONVERSATION.TGA")
bg:setPositionPx(1425, 885)
bg:setSizePx(400, 180)
bg:setVisible(false)

local serverName = Draw.new(nax(5200), nay(7500), "Khorinis RolePlay")
serverName:setFont("Font_Old_20_White_Hi.TGA")
serverName:setColor(255, 143, 0)
serverName:setPositionPx(720, 465)
serverName:setVisible(false)

local website = Draw.new(nax(6000), 0, "http://khorinis-roleplay.pl/")
website:setFont("Font_Old_10_White_Hi.TGA")
website:setColor(142, 35, 35)
website:setPositionPx(750, 500)
website:setVisible(false)

local colorIndex = 1

local function rotateColor()
    colorIndex = colorIndex + 1
    if colorIndex > #CruzerConfig.drawColors then
        colorIndex = 1
    end
    local color = CruzerConfig.drawColors[colorIndex]
    serverName:setColor(color.r, color.g, color.b)
end

CruzerUI.show = function()
    bg:setVisible(true)
    serverName:setVisible(true)
    website:setVisible(true)
end

CruzerUI.hide = function()
    bg:setVisible(false)
    serverName:setVisible(false)
    website:setVisible(false)
end

setTimer(rotateColor, 60000, 0)
