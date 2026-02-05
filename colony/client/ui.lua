ColonyUI = {}

local infoDraw = Draw.new(nax(200), nay(6400), "Chronicles of the Colony")
infoDraw:setFont("Font_Old_20_White_Hi.TGA")
infoDraw:setColor(0, 255, 255)
infoDraw:setPositionPx(90, 460)
infoDraw:setVisible(false)

ColonyUI.show = function()
    infoDraw:setVisible(true)
end

ColonyUI.hide = function()
    infoDraw:setVisible(false)
end
