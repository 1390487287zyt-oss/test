local breakup = include("gfl_manticore_snpc/death_parts.lua")
local blastTime = 0.74
local turretDelay = 0.108
local wreckLifetime = 14
local maxWrecks = 4
local maxDrawDistanceSqr = 4200 ^ 2
local fixedStep = 1 / 60
local gravityStep = Vector(0, 0, -405 * fixedStep)
local emberGravity = Vector(0, 0, -270)
local origin = Vector(0, 0, 0)
local noAngles = Angle(0, 0, 0)
local bracePivot = Vector(-23, 0, 98)
local blastOffset = Vector(-22, 0, 112)
local turretOffset = Vector(24, 0, 81)
local blastSound = "ambient/explosions/explode_4.wav"
local impactSound = "physics/metal/metal_box_impact_hard1.wav"

local function foldedPose(wreck, piece, age)
    local weight = math.Clamp((age - 0.18) / 0.53, 0, 1)
    weight = weight * weight * (3 - 2 * weight)
    local tremor = math.sin(age * 59) * weight * (1 - weight)
    local pitch = Angle(2.4 * weight + 1.4 * tremor, 0, 0)
    local pivot = bracePivot - Vector(0, 0, 4.2 * weight)
    local center, angle = LocalToWorld(piece.localCenter - bracePivot, piece.localAngle, pivot, pitch)
    return LocalToWorld(center, angle, wreck.position, wreck.angle)
end

local function makeParticle(emitter, texture, pos, velocity, lifetime, alpha, initialSize, endSize)
    local particle = emitter:Add(texture, pos)
    if not particle then return end
    particle:SetVelocity(velocity)
    particle:SetDieTime(lifetime)
    particle:SetStartAlpha(alpha)
    particle:SetEndAlpha(0)
    particle:SetStartSize(initialSize)
    particle:SetEndSize(endSize)
    return particle
end

local function burst(position, secondary)
    sound.Play(blastSound, position, secondary and 89 or 102, secondary and 104 or 82, secondary and 0.62 or 1)
    local emitter = ParticleEmitter(position)
    if not emitter or not emitter:IsValid() then return end

    local size = secondary and 0.65 or 1
    local glow = makeParticle(emitter, "sprites/light_glow02_add", position, origin, 0.22, 245, 80 * size, 165 * size)
    if glow then glow:SetColor(255, 133, 48) end

    for index = 1, secondary and 10 or 18 do
        local p = position + VectorRand() * 16
        local offset = VectorRand() * 60 + Vector(0, 0, 44)
        local smoke = makeParticle(emitter, "particles/smokey", p, offset,
            math.Rand(1.3, 2.1), 115, 24 * size, math.Rand(58, 96) * size)
        if smoke then
            smoke:SetColor(62, 58, 54)
            smoke:SetRoll(math.Rand(0, 2 * math.pi))
            smoke:SetRollDelta(math.Rand(-1.2, 1.2))
            smoke:SetAirResistance(26)
        end
        local spark = makeParticle(emitter, "effects/spark", p, VectorRand() * 235 + Vector(0, 0, 125),
            math.Rand(0.30, 0.78), 240, math.Rand(4, 7), 0)
        if spark then
            spark:SetColor(255, math.random(128, 204), 64)
            spark:SetGravity(emberGravity)
            spark:SetStartLength(13)
            spark:SetEndLength(0)
        end

        -- The fine chips use the engine fleck material. The larger parts use the Manticore meshes.
        local texture = index % 2 == 0 and "effects/fleck_cement1" or "effects/fleck_cement2"
        local chip = makeParticle(emitter, texture, p,
            VectorRand() * 210 + Vector(0, 0, 150), math.Rand(0.7, 1.7), 225, math.Rand(2, 5), 1)
        if chip then
            chip:SetColor(97, 103, 82)
            chip:SetGravity(emberGravity)
            chip:SetRoll(math.Rand(0, 2 * math.pi))
            chip:SetRollDelta(math.Rand(-8, 8))
        end
    end
    emitter:Finish()
end

local function verticalBounds(piece, angle)
    local up = Vector(angle:Forward().z, -angle:Right().z, angle:Up().z)
    local low, high = 0, 0
    for _, point in ipairs(piece.profile.support) do
        local z = point:Dot(up)
        low = math.min(low, z)
        high = math.max(high, z)
    end
    return low, high
end

local function stepPiece(wreck, piece, age, elapsed)
    if piece.settled or age < piece.launch then return end
    if not piece.position then
        piece.position, piece.angle = foldedPose(wreck, piece, piece.launch)
        piece.bottom = verticalBounds(piece, piece.angle)
    end

    piece.velocity = piece.velocity + gravityStep
    piece.angle:RotateAroundAxis(piece.axis, piece.spin * fixedStep)
    local bottom, top = verticalBounds(piece, piece.angle)
    local radius = piece.profile.radius
    local lift = math.max(0, piece.bottom - bottom)
    local goal = piece.position + piece.velocity * fixedStep
    local hit = util.TraceHull({
        start = piece.position + Vector(0, 0, lift + 0.2),
        endpos = goal,
        mins = Vector(-radius, -radius, bottom),
        maxs = Vector(radius, radius, top),
        mask = MASK_SOLID_BRUSHONLY,
    })
    piece.bottom = bottom
    if hit.StartSolid then
        -- A fragment can start against a step or wall when the model overlaps scenery.
        local floor = util.TraceLine({
            start = piece.position + Vector(0, 0, 20),
            endpos = piece.position + Vector(0, 0, bottom - 26),
            mask = MASK_SOLID_BRUSHONLY,
        })
        if floor.Hit and not floor.StartSolid and floor.HitNormal.z > 0.5
            and piece.position.z + bottom < floor.HitPos.z then
            piece.position = floor.HitPos + Vector(0, 0, -bottom + 0.25)
            piece.velocity = Vector(piece.velocity.x * 0.4, piece.velocity.y * 0.4, 0)
            piece.spin = piece.spin * 0.4
        else
            piece.settled = true
        end
        return
    end
    if not hit.Hit then
        piece.position = goal
        return
    end

    local normal = hit.HitNormal
    piece.position = hit.HitPos + normal * 0.25
    local approach = piece.velocity:Dot(normal)
    local tangent = piece.velocity - normal * approach
    local hardHit = approach < -35
    local bounce = hardHit and -approach * 0.22 or 0
    piece.velocity = tangent * (hardHit and 0.58 or 0.87) + normal * bounce
    piece.spin = piece.spin * (hardHit and 0.55 or 0.84)
    if not piece.hitOnce and approach < -65 and normal.z > 0.5 then
        piece.hitOnce = true
        if elapsed >= (wreck.nextImpactSound or 0) then
            wreck.nextImpactSound = elapsed + 0.075
            sound.Play(impactSound, piece.position, 74, math.random(85, 113), 0.48)
        end
    end
    if normal.z > 0.5 and bounce == 0 and piece.velocity:Length() < 6 and piece.spin < 15 then
        piece.settled = true
    end
end

return function(rig, getRenderParts, sampleLight, drawPart)
    local wrecks = {}

    hook.Add("Think", "GFLManticoreWreckPhysics", function()
        if #wrecks == 0 then return end
        local now = CurTime()
        for index = #wrecks, 1, -1 do
            local wreck = wrecks[index]
            local age = now - wreck.start
            if age >= wreckLifetime then
                table.remove(wrecks, index)
            else
                if age >= blastTime and not wreck.blast then
                    wreck.blast = true
                    burst(LocalToWorld(blastOffset, noAngles, wreck.position, wreck.angle), false)
                end
                if age >= blastTime + turretDelay and not wreck.turretBlast then
                    wreck.turretBlast = true
                    burst(LocalToWorld(turretOffset, noAngles, wreck.position, wreck.angle), true)
                end
                if wreck.blast and not wreck.settled then
                    -- Avoid doing unbounded catch-up if a frame stalls.
                    wreck.simAge = math.max(wreck.simAge, age - 4 * fixedStep)
                    while wreck.simAge + fixedStep <= age + 0.00001 do
                        wreck.simAge = wreck.simAge + fixedStep
                        local settled = true
                        for _, piece in ipairs(wreck.pieces) do
                            stepPiece(wreck, piece, wreck.simAge, age)
                            settled = settled and piece.settled
                        end
                        wreck.settled = settled
                    end
                end
            end
        end
    end)

    hook.Add("PostDrawOpaqueRenderables", "GFLManticoreWreckDraw", function(drawingDepth, _, drawing3DSkybox)
        if #wrecks == 0 or drawingDepth or drawing3DSkybox then return end
        local parts = getRenderParts()
        if not parts then return end
        local now, eye = CurTime(), EyePos()
        for _, wreck in ipairs(wrecks) do
            local age = now - wreck.start
            if age < wreckLifetime and eye:DistToSqr(wreck.position) < maxDrawDistanceSqr then
                local updateLight = now >= wreck.nextLight
                if updateLight then wreck.nextLight = now + 0.17 end
                local flash = 0
                if age >= blastTime then
                    flash = math.exp(-(age - blastTime) * 15)
                    if age >= blastTime + turretDelay then
                        flash = flash + 0.70 * math.exp(-(age - blastTime - turretDelay) * 15)
                    end
                end
                local tint = Vector(1.10, 0.49, 0.18) * flash
                for index, piece in ipairs(wreck.pieces) do
                    local pos, angle = piece.position, piece.angle
                    if not pos then pos, angle = foldedPose(wreck, piece, age) end
                    local modelPos = LocalToWorld(piece.modelOffset, noAngles, pos, angle)
                    if updateLight or not piece.light then piece.light = sampleLight(pos) end
                    wreck.matrix:SetTranslation(modelPos)
                    wreck.matrix:SetAngles(angle)
                    cam.PushModelMatrix(wreck.matrix)
                    drawPart(parts[index], piece.light + tint, age < blastTime)
                    cam.PopModelMatrix()
                end
            end
        end
    end)

    hook.Add("PostCleanupMap", "GFLManticoreWreckCleanup", function()
        wrecks = {}
    end)

    return function(position, angle, pose)
        if #wrecks >= maxWrecks then table.remove(wrecks, 1) end
        if not pose then
            pose = {}
            rig.Pose(pose, 0, 0, 1, -1, 0, 0)
        end
        local pieces = {}
        for index, part in ipairs(rig.parts) do
            local profile = breakup[part.name]
            local state = pose[part.name]
            local center = LocalToWorld(profile.center, noAngles, state.pos, state.ang)
            local velocity = LocalToWorld(profile.velocity, noAngles, origin, angle)
            local spin = LocalToWorld(profile.spin, noAngles, origin, angle)
            pieces[index] = {
                profile = profile, localCenter = center, localAngle = state.ang,
                modelOffset = profile.center * -1, launch = blastTime + profile.delay,
                velocity = velocity, axis = spin:GetNormalized(), spin = spin:Length(),
            }
        end
        wrecks[#wrecks + 1] = {
            position = position, angle = angle, pieces = pieces, matrix = Matrix(),
            start = CurTime(), nextLight = 0, simAge = blastTime,
        }
    end
end
