Classic = Classic or require('shared.classes')

Classic.visuals = {
  bodyModels = {
    { label = 'Male', model = 'HUM_BODY_NAKED0' },
    { label = 'Female', model = 'HUM_BODY_BABE0' }
  },
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
function Visuals.normalizeWalkingOverlay(overlay)
  if type(overlay) ~= 'string' then
    return nil
  end
  overlay = string.upper(overlay):gsub('%.MDS$', '')
  for _, walk in ipairs(Visuals.walkingOverlays) do
    if walk.overlay:gsub('%.MDS$', '') == overlay then
      return walk.overlay
    end
  end
end

function Visuals.applyWalkingOverlay(playerId, overlay)
  if overlay == nil then
    overlay = Visuals.default.walkingOverlay
  end

  overlay = Visuals.normalizeWalkingOverlay(overlay)
  if overlay == nil then
    return false
  end

  -- Use full MDS names when removing overlays, just as when applying them.
  for _, walk in ipairs(Visuals.walkingOverlays) do
    if walk.overlay ~= '' then
      removePlayerOverlay(playerId, walk.overlay)
    end
  end

  if overlay ~= '' then
    return applyPlayerOverlay(playerId, overlay)
  end

  return true
end

return Visuals
