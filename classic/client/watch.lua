local Watch = {
  x = 7000,
  y = 2500,
  lineHeight = 200,
  font = 'FONT_DEFAULT.TGA',
  visible = true,
  lines = {}
}

local function makeLine(index, text)
  local draw = Label.new(Watch.x, Watch.y + (index - 1) * Watch.lineHeight, text)
  draw:setFont(Watch.font)
  draw:setColor(255, 255, 255)
  draw:setVisible(Watch.visible)
  return draw
end

Watch.lines = {
  makeLine(1, 'Real Time:'),
  makeLine(2, ''),
  makeLine(3, 'Game Time:'),
  makeLine(4, '')
}

function Watch:setVisible(visible)
  self.visible = visible and true or false
  for _, line in ipairs(self.lines) do
    line:setVisible(self.visible)
  end
end

function Watch:update()
  if not self.visible then
    return
  end

  local realTime = getRealTime()
  local gameTime = getTime()
  self.lines[2]:setText(string.format('%02d:%02d:%02d', realTime.hour, realTime.minute, realTime.second))
  self.lines[4]:setText(string.format('%02d:%02d', gameTime.hour, gameTime.minute))
end

addEventHandler('onRender', function()
  Watch:update()
end)

Watch:update()

return Watch
