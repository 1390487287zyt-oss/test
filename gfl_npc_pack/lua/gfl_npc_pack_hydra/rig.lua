local auxiliary = {times = {}, barrels = {}, interval = 0.1}
local auxiliaryGroups = {"aux_left", "aux_right", "aux_left", "aux_right"}
local shotsPerGroup = 4
local auxiliaryRecoil = 0.18
for _, barrel in ipairs(auxiliaryGroups) do
    for _ = 1, shotsPerGroup do
        local index = #auxiliary.times + 1
        auxiliary.times[index] = 0.18 + (index - 1) * auxiliary.interval
        auxiliary.barrels[index] = barrel
    end
end
auxiliary.duration = auxiliary.times[#auxiliary.times] + auxiliaryRecoil

local rig = {
    auxShotMessage = "gfl_pack_hydra_aux_shot",
    auxFireSound = "weapons/ar2/fire1.wav",
    mainShotMessage = "gfl_pack_hydra_main_shot",
    deathMessage = "gfl_pack_hydra_death_breakup",
    moveScale = 0.5,
    strideDistance = 72,
    maxGaitTravel = 95,
    mins = Vector(-243, -103, -18),
    maxs = Vector(189, 103, 275),
    attacks = {
        [1] = auxiliary,
        [2] = {duration = 0.53, times = {0.27}, barrels = {"main_gun"}},
    },
    parts = {},
}

local stance = 0.57
local twoPi = 2 * math.pi
local zeroAngle = Angle(0, 0, 0)
local upperPivot = Vector(-45, 0, 111)
local chassisPivot = Vector(-34, 0, 82)
local gunPivots = {
    aux_left = Vector(-63, 31.25, 205),
    aux_right = Vector(-63, -31.25, 205),
    main_gun = Vector(-18, 0, 63),
}
local muzzlePositions = {
    -- The points sit just ahead of the circular muzzle rims in the mesh.
    aux_left = Vector(53.65, 31.325, 209.375),
    aux_right = Vector(53.65, -31.325, 209.375),
    main_gun = Vector(97, 0, 62.8),
}

local function addPart(name, texture, pivot, sample)
    rig.parts[#rig.parts + 1] = {name = name, texture = texture, pivot = pivot, sample = sample}
end
addPart("lower_body", "03", chassisPivot, Vector(-52, 0, 87))
addPart("upper_body", "01", upperPivot, Vector(-20, 0, 141))
addPart("turret_frame", "02", upperPivot, Vector(-75, 0, 186))
addPart("aux_left", "02", gunPivots.aux_left, Vector(19, 31, 205))
addPart("aux_right", "02", gunPivots.aux_right, Vector(19, -31, 205))
addPart("main_gun", "03", gunPivots.main_gun, Vector(49, 0, 63))

local legs = {
    {name = "front_left", texture = "04", phase = 0, hip = Vector(4, 40, 71), knee = Vector(54, 40, 75), ankle = Vector(125, 40, 17)},
    {name = "front_right", texture = "04", phase = 0.5, hip = Vector(4, -40, 71), knee = Vector(54, -40, 75), ankle = Vector(125, -40, 17)},
    {name = "rear_left", texture = "05", phase = 0.5, hip = Vector(-71, 52.7, 100.5), knee = Vector(-95, 52.7, 40), ankle = Vector(-148, 52.7, 37)},
    {name = "rear_right", texture = "05", phase = 0, hip = Vector(-71, -52.7, 100.5), knee = Vector(-95, -52.7, 40), ankle = Vector(-148, -52.7, 37)},
}

local function pitchBetween(a, b)
    return math.deg(math.atan2(a.z - b.z, b.x - a.x))
end

for _, leg in ipairs(legs) do
    leg.thigh = leg.name .. "_thigh"
    leg.shin = leg.name .. "_shin"
    leg.foot = leg.name .. "_foot"
    leg.upperLength = (leg.knee - leg.hip):Length()
    leg.lowerLength = (leg.ankle - leg.knee):Length()
    leg.upperPitch = pitchBetween(leg.hip, leg.knee)
    leg.lowerPitch = pitchBetween(leg.knee, leg.ankle)
    addPart(leg.thigh, leg.texture, leg.hip, leg.hip)
    addPart(leg.shin, leg.texture, leg.knee, (leg.knee + leg.ankle) * 0.5)
    addPart(leg.foot, leg.texture, leg.ankle, leg.ankle + Vector(0, 0, 3))
end

local function smooth(t)
    t = math.Clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

local function recoil(elapsed, release, duration)
    local afterShot = elapsed - release
    if afterShot < 0 or afterShot >= duration then return 0 end
    return (1 - smooth(afterShot / duration))
end

local function bodyRecoil(now, firedAt, duration)
    if not firedAt then return 0 end
    local afterShot = now - firedAt
    if afterShot < 0 or afterShot >= duration then return 0 end
    local progress = afterShot / duration
    return math.sin(progress * twoPi) * (1 - progress) ^ 2
end

local function setPose(poses, name, pos, ang)
    local pose = poses[name]
    if pose then
        pose.pos = pos
        pose.ang = ang
    else
        poses[name] = {pos = pos, ang = ang}
    end
end

local function poseLeg(poses, leg, phase, strength, direction, chassis, chassisAng)
    local gait = (phase + leg.phase) % 1
    local swing, step
    if gait < stance then
        swing = 0
        step = 1 - (gait / stance) * 2
    else
        local progress = (gait - stance) / (1 - stance)
        swing = math.sin(progress * math.pi)
        step = 2 * smooth(progress) - 1
    end

    local hip = LocalToWorld(leg.hip - chassisPivot, zeroAngle, chassis, chassisAng)
    local offset = (rig.strideDistance * stance * 0.5) * step * direction * strength
    local target = leg.ankle + Vector(offset, 0, swing * 18 * strength)
    local down = target - hip
    local distance = down:Length()
    local a, b = leg.upperLength, leg.lowerLength
    local reach = math.Clamp(distance, math.abs(a - b) + 0.05, a + b - 0.05)
    local alongTarget = down / distance
    local bend = Vector(-down.z, 0, down.x):GetNormalized()
    local along = (reach * reach + a * a - b * b) / (2 * reach)
    local rise = math.sqrt(math.max(0, a * a - along * along))
    local knee = hip + alongTarget * along + bend * rise
    local ankle = hip + alongTarget * reach
    setPose(poses, leg.thigh, hip, Angle(math.AngleDifference(pitchBetween(hip, knee), leg.upperPitch), 0, 0))
    setPose(poses, leg.shin, knee, Angle(math.AngleDifference(pitchBetween(knee, ankle), leg.lowerPitch), 0, 0))
    setPose(poses, leg.foot, ankle, Angle(-swing * 7 * direction * strength, 0, 0))
end

local function poseWeapon(poses, name, pos, ang, kick)
    -- Recoil moves the barrel backwards along its own bore.
    local slide = LocalToWorld(Vector(-kick, 0, 0), zeroAngle, pos, ang)
    setPose(poses, name, slide, ang)
end

function rig.Pose(poses, phase, strength, direction, attack, elapsed, pitch, yaw, weaponsOnly, now, firedAt)
    local leftAt, rightAt, mainAt
    if firedAt then leftAt, rightAt, mainAt = firedAt.aux_left, firedAt.aux_right, firedAt.main_gun end
    local upperKickLeft = leftAt and 8 * recoil(now, leftAt, auxiliaryRecoil) or 0
    local upperKickRight = rightAt and 8 * recoil(now, rightAt, auxiliaryRecoil) or 0
    local mainKick = mainAt and 15 * recoil(now, mainAt, 0.23) or 0
    local leftRock = bodyRecoil(now, leftAt, 0.16)
    local rightRock = bodyRecoil(now, rightAt, 0.16)
    local mainRock = bodyRecoil(now, mainAt, 0.29)
    local auxRock, sideRock = leftRock + rightRock, leftRock - rightRock
    local brace, aimBlend = 0, 0
    local profile = rig.attacks[attack]
    if profile and elapsed >= 0 and elapsed <= profile.duration then
        aimBlend = smooth(elapsed / 0.15) * (1 - smooth((elapsed - profile.duration + 0.10) / 0.10))
        if attack == 2 then
            brace = smooth(elapsed / 0.19) * (1 - smooth((elapsed - 0.28) / 0.24))
        end
    end
    local wave = phase * twoPi
    local contact = (1 - (phase * 2) % 1) ^ 8
    local lift = (-1.2 + 1.4 * math.cos(2 * wave) - 1.4 * contact) * strength - 3.5 * brace
    local chassis = chassisPivot + Vector(-1.2 * auxRock - 4 * mainRock, 0, lift - 2.6 * auxRock - 5 * mainRock)
    local chassisAng = Angle(-1.8 * auxRock - 5 * mainRock, 0, 2 * sideRock)
    local upperPos, upperAng = LocalToWorld(upperPivot - chassisPivot,
        Angle(math.sin(wave) * 1.7 * strength - 2.7 * auxRock - 4.5 * mainRock,
            1.25 * sideRock, math.sin(wave) * 0.9 * strength + 3.2 * sideRock), chassis, chassisAng)
    local auxAim = attack == 1 and aimBlend or 0
    local auxAng = Angle(pitch * auxAim, yaw * auxAim, 0)
    local left, leftAng = LocalToWorld(gunPivots.aux_left - upperPivot, auxAng, upperPos, upperAng)
    local right, rightAng = LocalToWorld(gunPivots.aux_right - upperPivot, auxAng, upperPos, upperAng)
    poseWeapon(poses, "aux_left", left, leftAng, upperKickLeft)
    poseWeapon(poses, "aux_right", right, rightAng, upperKickRight)

    local mainAim = attack == 2 and aimBlend or 0
    local mainPos, mainAng = LocalToWorld(gunPivots.main_gun - chassisPivot,
        Angle(pitch * mainAim - mainKick * 0.24, yaw * mainAim, 0), chassis, chassisAng)
    poseWeapon(poses, "main_gun", mainPos, mainAng, mainKick)
    if not weaponsOnly then
        setPose(poses, "lower_body", chassis, chassisAng)
        setPose(poses, "upper_body", upperPos, upperAng)
        setPose(poses, "turret_frame", upperPos, upperAng)
        for _, leg in ipairs(legs) do poseLeg(poses, leg, phase, strength, direction, chassis, chassisAng) end
    end
end

function rig.AimOffset(attack, target)
    local pivot = attack == 2 and gunPivots.main_gun or Vector(-63, 0, 205)
    local ang = (target - pivot):Angle()
    return math.Clamp(math.NormalizeAngle(ang.p), -30, 68), math.Clamp(math.NormalizeAngle(ang.y), -34, 34)
end

function rig.MuzzleLocal(poses, barrel)
    local pose = poses[barrel]
    return LocalToWorld(muzzlePositions[barrel] - gunPivots[barrel], zeroAngle, pose.pos, pose.ang)
end

return rig
