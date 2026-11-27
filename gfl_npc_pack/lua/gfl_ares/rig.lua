local geometry = include("gfl_ares/geometry.lua")
local config = include("gfl_ares/config.lua")
local rig = {
    parts = geometry.parts, seams = geometry.seams, stride = 78,
    mins = Vector(-174, -114, -18), maxs = Vector(225, 110, 232),
}
local zero, zeroAngle = Vector(), Angle()
local stance = .58
local halfStep = rig.stride * stance * .5
local toeLift = 16

local function pitch(x, z)
    return math.atan2(-z, x)
end

local joints = {}
for _, part in ipairs(rig.parts) do joints[part.name] = part.rest end

local function legGeometry(side)
    local thigh = joints["knee_" .. side]
    local shin = joints["ankle_" .. side]
    return {
        foot = thigh + shin,
        thighLength = math.sqrt(thigh.x ^ 2 + thigh.z ^ 2),
        shinLength = math.sqrt(shin.x ^ 2 + shin.z ^ 2),
        thighPitch = pitch(thigh.x, thigh.z),
        shinPitch = pitch(shin.x, shin.z),
    }
end

local legs = {left = legGeometry("left"), right = legGeometry("right")}

local function ease(a, b, t)
    local x = math.Clamp((t - a) / (b - a), 0, 1)
    return x * x * (3 - 2 * x)
end

local function recoil(t)
    if not t or t < 0 or t >= .52 then return 0 end
    return (1 - ease(.035, .52, t)) * ease(-.025, .035, t)
end

local function leg(angles, side, phase, weight, heave, crouch, travel)
    local geometry = legs[side]
    local reach, lift
    if phase < stance then
        -- Cancel the NPC's forward travel during support so the planted foot stays put.
        reach, lift = halfStep - phase * rig.stride, 0
    else
        local swing = (phase - stance) / (1 - stance)
        reach = Lerp(ease(0, 1, swing), -halfStep, halfStep)
        lift = math.sin(math.pi * swing) ^ 1.2
    end

    local targetX = geometry.foot.x + reach * weight
    local targetZ = geometry.foot.z + toeLift * lift * weight - heave
    local thigh, shin = geometry.thighLength, geometry.shinLength
    local bend = math.acos(math.Clamp((targetX ^ 2 + targetZ ^ 2 - thigh ^ 2 - shin ^ 2) / (2 * thigh * shin), -1, 1))
    local thighPitch = pitch(targetX, targetZ) - math.atan2(shin * math.sin(bend), thigh + shin * math.cos(bend))
    local hip = math.deg(thighPitch - geometry.thighPitch)
    local knee = math.deg(bend - (geometry.shinPitch - geometry.thighPitch))
    angles["hip_" .. side] = Angle(hip + 16 * crouch, 0, 0)
    angles["knee_" .. side] = Angle(knee - 28 * crouch, 0, 0)
    angles["ankle_" .. side] = Angle(-hip - knee + 12 * crouch - 7 * lift * weight, 0, 0)
    angles["toe_" .. side] = Angle(-6 * lift * weight, 0, 0)
    angles["wheel_" .. side] = Angle(-travel * 5.2 % 360, 0, 0)
end

function rig.Pose(out, phase, weight, travel, skill, t, aim, fired, stagger, brace, shotCount, aimTarget)
    local angles, offsets = {}, {}
    local left = recoil(fired.left)
    local right = recoil(fired.right)
    local rocket = recoil(fired.rocket)
    local main = recoil(fired.main)
    local a = config.attacks[skill]
    local ramp = a and ease(0, a.windup * .84, t) or 0
    local attackEnd = a and (a.windup + a.interval * ((skill == 3 and (shotCount or 1) or #a.ports) - 1) + a.recovery) or 0
    local prep = a and ramp * (1 - ease(attackEnd - a.recovery * .7, attackEnd, t)) or 0
    if skill == 2 then prep = ramp * (1 - ease(attackEnd - .2, attackEnd, t)) end
    local settle = stagger * .87 + (brace or 0) * .24
    local step = (phase * 2) % 1
    local gaitHeight = (-7.7 + 13.2 * math.sin(math.pi * step) ^ 1.35) * weight
    local windupDrop = skill == 1 and 5 or skill == 2 and 7 or 9
    local kick = 8.5 * math.max(left, right) + 14 * rocket + 19 * main
    local heave = gaitHeight - prep * windupDrop - kick
    local chassisPitch = 9 * stagger
    offsets.body = Vector(0, 0, heave - 13 * settle)
    angles.body = Angle(chassisPitch, 0, 6 * stagger)
    local yaw = a and math.Clamp(aim.y, -27, 27) * prep or 0
    local pitch = a and math.Clamp(aim.p, -28, 48) * prep or 0
    angles.torso = Angle(-.35 * chassisPitch - 4 * prep, yaw * .24, 0)
    angles.head = Angle(pitch * .48 + 24 * stagger, yaw * .28, -3 * stagger)
    angles.radar = Angle(-heave * .14, -8 * prep, 0)

    leg(angles, "left", phase, weight, heave, settle, travel)
    leg(angles, "right", (phase + .5) % 1, weight, heave, settle, travel)
    local guns = skill == 1 and prep or 0
    local armPitch = -33 * guns + 13 * stagger - gaitHeight * .28
    angles.arm_left = Angle(armPitch, yaw * .16, 0)
    angles.arm_right = Angle(armPitch, yaw * .16, 0)
    angles.gun_left = Angle(33 * guns + pitch * guns - 16 * left, yaw * .72, 0)
    angles.gun_right = Angle(33 * guns + pitch * guns - 16 * right, yaw * .72, 0)
    offsets.gun_left, offsets.gun_right = Vector(-9 * left, 0, 0), Vector(-9 * right, 0, 0)

    local launcher = skill == 2 and prep or 0
    local opening = skill == 2 and ease(.49, .96, t) * (1 - ease(1.34, 1.71, t)) or 0
    angles.launcher_arm = Angle(-24 * launcher, 0, 0)
    angles.launcher_forearm = Angle(13 * launcher, 0, 0)
    angles.launcher_mount = Angle(0, yaw, 0)
    angles.launcher = Angle(4 * launcher + .7 * pitch * launcher - 13 * rocket, 0, 0)
    angles.hatch_top, angles.hatch_bottom = Angle(-107 * opening, 0, 0), Angle(102 * opening, 0, 0)
    for index = 1, 4 do
        local key = "cap_" .. index
        angles[key] = Angle(91 * opening, 0, 0)
        offsets[key] = Vector(-3 * opening, 0, (index < 3 and 3 or -3) * opening)
    end

    local cannon = skill == 3 and prep or 0
    local lift = skill == 3 and (ease(.13, .54, t) - ease(.73, 1.35, t)) or 0
    angles.cannon_mount = Angle(-6 * lift, yaw * .29, 0)
    angles.cannon = Angle(pitch * cannon - 9 * lift - 11 * main + 23 * stagger, yaw * .63, 0)
    offsets.cannon = Vector(-24 * main, 0, 0)

    for index, part in ipairs(rig.parts) do
        local parent = out[part.parent]
        local rest = part.rest + (offsets[part.name] or zero)
        local rotation = angles[part.name] or zeroAngle
        if skill == 3 and aimTarget and part.name == "cannon" then
            local pivot = LocalToWorld(rest, zeroAngle, parent.pos, parent.ang)
            local localAim = WorldToLocal(aimTarget, zeroAngle, pivot, parent.ang)
            local heading = localAim:Angle()
            rotation = Angle(Lerp(prep, -14 * lift, math.Clamp(heading.p, -30, 48)) - 14 * main,
                math.Clamp(heading.y, -40, 40) * prep, 0)
        end
        local position, angle = LocalToWorld(rest, rotation, parent and parent.pos or zero, parent and parent.ang or zeroAngle)
        local pose = out[index] or {}
        pose.pos, pose.ang = position, angle
        out[index] = pose
    end
end

function rig.Muzzle(poses, name)
    local port = geometry.ports[name]
    local pose = poses[port.part]
    return LocalToWorld(port.offset, zeroAngle, pose.pos, pose.ang)
end

return rig
