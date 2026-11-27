local geometry = include("gfl_manticore_snpc/geometry.lua")
local rig = {
    parts = geometry.parts,
    mins = Vector(-185, -77, -24),
    maxs = Vector(197, 77, 219),
    strideDistance = 64,
    shotMessage = "gfl_manticore_cannon",
    deathMessage = "gfl_manticore_breakup",
    release = 0.32,
    attackDuration = 0.67,
}

local zero = Angle(0, 0, 0)
local pivots = {}
for _, part in ipairs(rig.parts) do pivots[part.name] = part.pivot end
local chassisPivot = pivots.body
local muzzleOffset = geometry.muzzle - pivots.cannon
local stance = 0.60

local function smooth(value)
    local t = math.Clamp(value, 0, 1)
    return t * t * (3 - 2 * t)
end

local function pitchBetween(a, b)
    return math.deg(math.atan2(a.z - b.z, b.x - a.x))
end

local legs = {}
for _, entry in ipairs({
    {"front_left", 0}, {"front_right", 0.5}, {"rear_left", 0.5}, {"rear_right", 0},
}) do
    local name, offset = entry[1], entry[2]
    local thigh, shin, foot = name .. "_thigh", name .. "_shin", name .. "_foot"
    local hip, knee, ankle = pivots[thigh], pivots[shin], pivots[foot]
    local axis = ankle - hip
    local bend = Vector(-axis.z, 0, axis.x)
    local top, bottom = name .. "_piston_top", name .. "_piston_bottom"
    legs[#legs + 1] = {
        phase = offset, thigh = thigh, shin = shin, foot = foot,
        hip = hip, knee = knee, ankle = ankle,
        upper = (knee - hip):Length(), lower = (ankle - knee):Length(),
        upperPitch = pitchBetween(hip, knee), lowerPitch = pitchBetween(knee, ankle),
        bendSign = (knee - hip):Dot(bend) < 0 and -1 or 1,
        pistonTop = pivots[top] and top, pistonBottom = pivots[bottom] and bottom,
    }
end

local function setPose(poses, name, pos, ang)
    local pose = poses[name]
    if not pose then
        pose = {}
        poses[name] = pose
    end
    pose.pos, pose.ang = pos, ang
end

local function poseLeg(poses, leg, phase, strength, direction, chassis, chassisAngle)
    local t = (phase + leg.phase) % 1
    local step, lift = 0, 0
    if t < stance then
        step = 1 - 2 * t / stance
    else
        local swing = (t - stance) / (1 - stance)
        step = 2 * smooth(swing) - 1
        lift = math.sin(swing * math.pi)
    end

    local hip = LocalToWorld(leg.hip - chassisPivot, zero, chassis, chassisAngle)
    local target = leg.ankle + Vector(rig.strideDistance * stance * 0.5 * step * direction, 0, 14 * lift) * strength
    local offset = target - hip
    local distance = offset:Length()
    local axis = offset / distance
    local bend = Vector(-axis.z, 0, axis.x):GetNormalized() * leg.bendSign
    local reach = math.Clamp(distance, math.abs(leg.upper - leg.lower) + 0.01, leg.upper + leg.lower - 0.01)
    local along = (reach ^ 2 + leg.upper ^ 2 - leg.lower ^ 2) / (2 * reach)
    local knee = hip + axis * along + bend * math.sqrt(math.max(0, leg.upper ^ 2 - along ^ 2))
    local ankle = hip + axis * reach
    local thighAngle = Angle(math.AngleDifference(pitchBetween(hip, knee), leg.upperPitch), 0, 0)
    local shinAngle = Angle(math.AngleDifference(pitchBetween(knee, ankle), leg.lowerPitch), 0, 0)
    local footAngle = Angle(-4 * lift * direction * strength, 0, 0)
    setPose(poses, leg.thigh, hip, thighAngle)
    setPose(poses, leg.shin, knee, shinAngle)
    setPose(poses, leg.foot, ankle, footAngle)

    if leg.pistonTop then
        local topRest, bottomRest = pivots[leg.pistonTop], pivots[leg.pistonBottom]
        local top = LocalToWorld(topRest - leg.knee, zero, knee, shinAngle)
        local bottom = LocalToWorld(bottomRest - leg.ankle, zero, ankle, footAngle)
        local pitch = math.AngleDifference(pitchBetween(top, bottom), pitchBetween(topRest, bottomRest))
        local angle = Angle(pitch, 0, 0)
        setPose(poses, leg.pistonTop, top, angle)
        setPose(poses, leg.pistonBottom, bottom, angle)
    end
end

function rig.AimOffset(target)
    local angle = (target - pivots.mount):Angle()
    return math.Clamp(math.NormalizeAngle(angle.p), -25, 52),
        math.Clamp(math.NormalizeAngle(angle.y), -36, 36)
end

function rig.Pose(poses, phase, strength, direction, elapsed, pitch, yaw, firedAgo, weaponsOnly)
    local aim, brace, slide, kick = 0, 0, 0, 0
    if elapsed >= 0 and elapsed < rig.attackDuration then
        aim = smooth(elapsed / 0.20) * (1 - smooth((elapsed - 0.53) / 0.14))
        brace = smooth(elapsed / 0.24) * (1 - smooth((elapsed - 0.34) / 0.24))
    end
    if firedAgo and firedAgo >= 0 and firedAgo < 0.32 then
        local progress = firedAgo / 0.32
        slide = 11 * (1 - smooth(progress))
        kick = math.sin(progress * 2 * math.pi) * (1 - progress) ^ 2
    end
    local wave = phase * 2 * math.pi
    local contact = (1 - (phase * 2) % 1) ^ 8
    local lift = (-1.1 + math.cos(wave * 2) - 1.2 * contact) * strength - 2.3 * brace - 3.6 * kick
    local chassis = chassisPivot + Vector(-3 * kick, 0, lift)
    local chassisAngle = Angle(math.sin(wave) * 1.2 * strength - 6.5 * kick, 0, math.sin(wave) * 0.7 * strength)
    local mountPos, mountAngle = LocalToWorld(pivots.mount - chassisPivot,
        Angle(pitch * aim, yaw * aim, 0), chassis, chassisAngle)
    local cannonPos, cannonAngle = LocalToWorld(pivots.cannon - pivots.mount - Vector(slide, 0, 0),
        zero, mountPos, mountAngle)
    setPose(poses, "mount", mountPos, mountAngle)
    setPose(poses, "cannon", cannonPos, cannonAngle)
    if weaponsOnly then return end

    setPose(poses, "body", chassis, chassisAngle)
    local antennaPos, antennaAngle = LocalToWorld(pivots.antenna - chassisPivot, zero, chassis, chassisAngle)
    setPose(poses, "antenna", antennaPos, antennaAngle)
    for _, leg in ipairs(legs) do poseLeg(poses, leg, phase, strength, direction, chassis, chassisAngle) end
end

function rig.MuzzleLocal(poses)
    local cannon = poses.cannon
    return LocalToWorld(muzzleOffset, zero, cannon.pos, cannon.ang)
end

return rig
