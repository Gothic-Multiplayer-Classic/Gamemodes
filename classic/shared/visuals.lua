local ClassicRoot = Classic

if ClassicRoot == nil and require ~= nil then
  ClassicRoot = require('shared.classes')
end

Classic = ClassicRoot or {}

Classic.visuals = {
  bodyModel = 'HUM_BODY_NAKED0',
  skinTexture = { min = 0, max = 12 },
  faceTexture = { min = 0, max = 162 },
  teethTexture = 0,
  skinColor = 0,
  position = { x = 29912.9, y = 5185.68, z = -15710.0, angle = -34.0 },
  default = {
    bodyModel = 'HUM_BODY_NAKED0',
    bodyTexture = 9,
    headModel = 'HUM_HEAD_PONY',
    headTexture = 18,
    teethTexture = 0,
    skinColor = 0,
    walkingOverlay = ''
  },
  walkingOverlays = {
    { label = 'Default', overlay = '' },
    { label = 'Guard', overlay = 'HUMANS_MILITIA.MDS' },
    { label = 'Mage', overlay = 'HUMANS_MAGE.MDS' },
    { label = 'Relaxed', overlay = 'HUMANS_RELAXED.MDS' },
    { label = 'Arrogant', overlay = 'HUMANS_ARROGANCE.MDS' },
    { label = 'Tired', overlay = 'HUMANS_TIRED.MDS' },
    { label = 'Woman', overlay = 'HUMANS_BABE.MDS' }
  },
  headModels = {
    { label = 'Fighter', model = 'HUM_HEAD_FIGHTER' },
    { label = 'Bald', model = 'HUM_HEAD_BALD' },
    { label = 'Fat Bald', model = 'HUM_HEAD_FATBALD' },
    { label = 'Pony', model = 'HUM_HEAD_PONY' },
    { label = 'Psionic', model = 'HUM_HEAD_PSIONIC' },
    { label = 'Thief', model = 'HUM_HEAD_THIEF' }
  }
}

local Visuals = Classic.visuals
local allowedWalkingOverlays = {}

for _, entry in ipairs(Visuals.walkingOverlays) do
  allowedWalkingOverlays[entry.overlay] = true
end

function Visuals.isWalkingOverlayAllowed(overlay)
  return type(overlay) == 'string' and allowedWalkingOverlays[overlay] == true
end

function Visuals.applyWalkingOverlay(playerId, overlay)
  if overlay == nil then
    overlay = Visuals.default.walkingOverlay
  end

  if not Visuals.isWalkingOverlayAllowed(overlay) then
    return false
  end

  local alreadyApplied = false
  for _, activeOverlay in ipairs(getPlayerOverlays(playerId) or {}) do
    if activeOverlay == overlay then
      alreadyApplied = true
    elseif allowedWalkingOverlays[activeOverlay] then
      removePlayerOverlay(playerId, activeOverlay)
    end
  end

  if overlay ~= '' and not alreadyApplied then
    return applyPlayerOverlay(playerId, overlay)
  end

  return true
end

return Visuals
