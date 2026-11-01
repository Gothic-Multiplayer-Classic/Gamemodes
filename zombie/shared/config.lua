Zombie = {
  awaitSeconds = 59,
  roundSeconds = 299,
  minPlayers = 2,
  respawnMs = 5000,
  noZombieSeconds = 15,
  -- These coordinates belong to Gothic II's New World. Change world and spawns together.
  world = 'NEWWORLD\\NEWWORLD.ZEN',
  virtualWorld = 0,
  previewVirtualWorldBase = 20000,
  preview = { x = 2492.85, y = 802.80, z = -872.84, angle = 120 },
  zombieSpawns = {
    { x = 5587.17, y = 367.20, z = -5857.20, angle = 76 },
    { x = 6380.95, y = 368.20, z = -3531.90, angle = 120 },
    { x = 8571.92, y = 368.20, z = -5834.56, angle = 309 },
    { x = 8461.10, y = 368.25, z = -3832.24, angle = 218 },
    { x = 6131.65, y = 368.25, z = -4315.43, angle = 81 },
    { x = 7715.59, y = 368.10, z = -3396.38, angle = 241 },
    { x = 8049.91, y = 368.20, z = -6227.58, angle = 2 },
    { x = 7653.45, y = 368.20, z = -3988.10, angle = 139 }
  },
  humanSpawns = {
    { x = 12467.02, y = 998.20, z = -2261.10, angle = 223 },
    { x = 13221.27, y = 998.20, z = -3018.44, angle = 273 },
    { x = 11435.20, y = 998.20, z = -3104.30, angle = 76 },
    { x = 11826.88, y = 998.20, z = -3812.57, angle = 24 },
    { x = 14046.03, y = 1187.80, z = -1371.67, angle = 226 }
  },
  fortBoundary = {
    x = 9287.83, y = 925.16, z = -4676.88, radius = 700,
    destination = { x = 10979.91, y = 998.10, z = -4047.13, angle = 240 }
  },
  classes = {
    { name = 'Zombie Fighter', team = 'zombie', instance = 'ZOMBIE01', health = 5000, strength = 200 },
    { name = 'Zombie Voodoo', team = 'zombie', instance = 'ZOMBIE02', health = 5000, strength = 200 },
    { name = 'Zombie Hobgoblin', team = 'zombie', instance = 'ZOMBIE03', health = 5000, strength = 200 },
    { name = 'Zombie Nazi', team = 'zombie', instance = 'ZOMBIE04', health = 5000, strength = 200 },
    {
      name = 'Pirate', team = 'human', instance = 'PC_HERO', health = 300, strength = 145,
      visual = { bodyModel = 'Hum_Body_Naked0', bodyTexture = 3, headModel = 'Hum_Head_Psionic', headTexture = 59 },
      -- KrummSchwert is a one-handed weapon; the old script trained the wrong skill.
      skills = { [WEAPON_1H] = 60 },
      armor = 'ITAR_PIR_H_Addon', melee = 'ITMW_KRUMMSCHWERT'
    },
    {
      name = 'Dragon Hunter', team = 'human', instance = 'PC_HERO', health = 300,
      strength = 90, dexterity = 50,
      visual = { bodyModel = 'Hum_Body_Naked0', bodyTexture = 2, headModel = 'Hum_Head_Fighter', headTexture = 120 },
      skills = { [WEAPON_1H] = 60, [WEAPON_CBOW] = 50 },
      armor = 'ITAR_DJG_M', melee = 'ITMW_RUBINKLINGE', ranged = 'ITRW_CROSSBOW_L_02',
      items = { { instance = 'ITRW_BOLT', amount = 50 } }
    },
    {
      name = 'Knight', team = 'human', instance = 'PC_HERO', health = 300,
      strength = 120, dexterity = 80,
      visual = { bodyModel = 'Hum_Body_Naked0', bodyTexture = 1, headModel = 'Hum_Head_FatBald', headTexture = 32 },
      skills = { [WEAPON_2H] = 60, [WEAPON_BOW] = 50 },
      armor = 'ITAR_PAL_M', melee = 'ITMW_2H_PAL_SWORD', ranged = 'ITRW_BOW_M_02',
      items = { { instance = 'ITRW_ARROW', amount = 50 } }
    },
    {
      name = 'Acrobat', team = 'human', instance = 'PC_HERO', health = 300,
      strength = 40, dexterity = 100, acrobatics = 1,
      visual = { bodyModel = 'Hum_Body_Naked0', bodyTexture = 2, headModel = 'Hum_Head_Thief', headTexture = 95 },
      skills = { [WEAPON_1H] = 40, [WEAPON_BOW] = 90 },
      armor = 'ITAR_DIEGO', melee = 'ItMw_FrancisDagger_Mis', ranged = 'ITRW_BOW_M_03',
      items = { { instance = 'ITRW_ARROW', amount = 200 } }
    }
  },
  sounds = {
    start = 'OPENPORTAL.WAV', zombiesWin = 'ZOMBIE_01.WAV', humansWin = 'CHAPTER_01.WAV',
    humanDeath = {
      'SVM_9_DEAD.WAV', 'SVM_6_DEAD.WAV', 'SVM_3_DEAD.WAV', 'SVM_5_DEAD.WAV',
      'SVM_12_DEAD.WAV', 'SVM_4_DEAD.WAV', 'SVM_7_DEAD.WAV', 'SVM_11_DEAD.WAV'
    },
    humanKill = {
      'SVM_13_KILLENEMY.WAV', 'SVM_14_KILLENEMY.WAV', 'SVM_1_KILLENEMY.WAV',
      'SVM_11_KILLENEMY.WAV', 'SVM_6_KILLENEMY.WAV', 'SVM_12_KILLENEMY.WAV',
      'SVM_12_ENEMYKILLED.WAV', 'SVM_4_ENEMYKILLED.WAV', 'SVM_5_ENEMYKILLED.WAV',
      'SVM_8_ENEMYKILLED.WAV', 'SVM_10_ENEMYKILLED.WAV', 'SVM_9_ENEMYKILLED.WAV',
      'SVM_3_ENEMYKILLED.WAV', 'SVM_7_ENEMYKILLED.WAV'
    },
    zombieKill = { 'BREATH01.WAV', 'BREATH02.WAV', 'BREATH03.WAV' }
  }
}

return Zombie
