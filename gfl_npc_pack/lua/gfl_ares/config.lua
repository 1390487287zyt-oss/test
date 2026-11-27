local attacks = {
    {range = 3650, windup = 0.62, interval = 0.24, recovery = 0.48, ports = {"left", "right", "left", "right"}},
    {range = 3650, windup = 1.08, interval = 0, recovery = 0.68, ports = {"rocket1", "rocket2", "rocket3", "rocket4"}},
    {range = 4300, minRange = 260, windup = 1.65, interval = 0.78, recovery = 0.72, ports = {"main", "main"}},
}

local profiles = {
    npc_vj_gfl_aa02_sinner = {
        name = 'AA-02 "Sinner"', health = 18000, shield = 2000, stun = 20,
        mass = 5000,
        speed = 1, pause = 0.82, damage = {65, 125}, cannonShots = 0,
        cooldowns = {4.5, 8.5},
    },
    npc_vj_gfl_aa02_ares = {
        name = "Ares", health = 50000, shield = 4000, stun = 10, recharge = 60,
        mass = 6500,
        speed = 1.38, pause = 0.48, damage = {105, 185, 620}, cannonShots = 2,
        cooldowns = {3.2, 6.0, 9.0},
    },
}

local function shotCount(skill, profile)
    return skill == 3 and profile.cannonShots or #attacks[skill].ports
end

local function lastShotTime(skill, profile)
    local attack = attacks[skill]
    return attack.windup + (shotCount(skill, profile) - 1) * attack.interval
end

return {
    attacks = attacks,
    shotCount = shotCount,
    lastShotTime = lastShotTime,
    profiles = profiles,
    groundMoveScale = 0.5,
    rocketRadius = 200,
    cannonRadius = 620,
    shieldVisual = {
        model = "models/gfl2/effects/shield_barrier4.mdl",
        material = "materials/models/gfl2/project/effects/shield_barrier/dun_080",
        skin = 2, scale = 1.18, soundDelay = 0.5, deployTime = 0.6,
        deploySound = "gfl2/effects/shield_restore.wav",
        breakSound = "gfl2/effects/armor_break.wav",
    },
    shotMessage = "gfl_aa02_shot",
    laserMessage = "gfl_aa02_ground_laser",
    deathMessage = "gfl_aa02_death",
}
