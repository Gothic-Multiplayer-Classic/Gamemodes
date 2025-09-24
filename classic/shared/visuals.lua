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
    skinColor = 0
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

return Classic.visuals
