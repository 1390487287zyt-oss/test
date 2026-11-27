AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("gfl_npc_pack_hydra/rig.lua")
AddCSLuaFile("gfl_npc_pack_hydra/death_fx.lua")
AddCSLuaFile("gfl_npc_pack_hydra/death_parts.lua")
include("shared.lua")

local combat = include("gfl_npc_pack/armored_combat.lua")
local rig = include("gfl_npc_pack_hydra/rig.lua")
util.AddNetworkString(rig.auxShotMessage)
util.AddNetworkString(rig.mainShotMessage)
util.AddNetworkString(rig.deathMessage)
util.PrecacheSound(rig.auxFireSound)

local spawnHealth = include("gfl_npc_pack_hydra/spawn.lua").health

-- The base uses a stock animation model for navigation. The client draws the Hydra rig.
ENT.Model = {"models/antlion_guard.mdl"}
ENT.StartHealth = spawnHealth
ENT.HullType = HULL_LARGE
ENT.MovementType = VJ_MOVETYPE_GROUND
ENT.JumpParams = {Enabled = false}
ENT.CanOpenDoors = false
ENT.TurningSpeed = 41
ENT.SightDistance = 5000
ENT.SightAngle = 165
ENT.Bleeds = false
ENT.BloodColor = false
ENT.HasDeathCorpse = false
ENT.HasDeathAnimation = false
ENT.HasMeleeAttack = false
ENT.HasLeapAttack = false
ENT.HasSounds = false
ENT.HasRangeAttack = true
ENT.AnimTbl_RangeAttack = false
ENT.RangeAttackAngleRadius = 52
ENT.RangeAttackMinDistance = 65
ENT.RangeAttackMaxDistance = 3650
ENT.TimeUntilRangeAttackProjectileRelease = false
ENT.RangeAttackExtraTimers = false
ENT.NextAnyAttackTime_Range = 0.88
ENT.NextRangeAttackTime = 1.5
ENT.LimitChaseDistance = "OnlyRange"
ENT.LimitChaseDistance_Min = 175
ENT.LimitChaseDistance_Max = "UseRangeDistance"

local mainCooldown = 5.2
local minimumAuxStartInterval = 1
local blastRadius = 160
local auxiliaryDamage = 40
local mainDamage = 138
local launcherOffset = Vector(20, 0, 117)
local allyTags = {}
for _, tag in ipairs(ENT.VJ_NPC_Class) do allyTags[tag] = true end

local function isLiving(ent)
    return ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()
end

local function allied(self, ent)
    if not IsValid(ent) or not isLiving(ent) then return false end
    if self == ent or self:Disposition(ent) == D_LI then return true end
    if not istable(ent.VJ_NPC_Class) then return false end
    for _, tag in ipairs(ent.VJ_NPC_Class) do
        if allyTags[tag] then return true end
    end
    return false
end

local function targetHull(enemy)
    if enemy.IsVJBaseSNPC_TankGun then
        local chassis = enemy:GetParent()
        if IsValid(chassis) and chassis.IsVJBaseSNPC_TankChassis then return chassis end
    end
    return enemy
end

local function aimPoint(hull, origin)
    local mins, maxs = hull:OBBMins(), hull:OBBMaxs()
    if hull.IsVJBaseSNPC_Tank or hull:IsVehicle() or maxs.z - mins.z <= 64 then
        return hull:LocalToWorld((mins + maxs) * 0.5)
    end
    if hull:IsNPC() or hull:IsPlayer() then
        local body = hull:BodyTarget(origin, false)
        if isvector(body) then return body end
    end
    return hull:WorldSpaceCenter()
end

local function friendlyHit(self, ent)
    if combat.IsRetaliating(self, ent) then return false end
    return allied(self, ent) or (IsValid(ent) and not ent:IsWorld() and allied(self, ent:GetParent()))
end

combat.Configure(ENT, 6000, friendlyHit)

local fireShot

local function scheduleShots(self, volley)
    local name = self.HydraShotTimer
    local profile = volley.profile
    local times = profile.times
    local tick = engine.TickInterval()
    local shot = 1
    local nextFire = volley.started + times[1]
    timer.Create(name, tick, 0, function()
        if not IsValid(self) or self.HydraVolley ~= volley or not combat.CanFire(self) then
            timer.Remove(name)
            if IsValid(self) and self.HydraVolley == volley then self.HydraVolley = nil end
            return
        end
        local now = CurTime()
        if now < nextFire then return end
        local enemy, hull = combat.Target(self, volley.enemy, targetHull, friendlyHit)
        if enemy then
            if enemy ~= volley.enemy then
                volley.enemy = enemy
                self:SetTurnTarget(enemy, math.max(tick, self.HydraVolleyEnd - now))
            end
            fireShot(self, volley, shot, enemy, hull, now)
        end
        shot = shot + 1
        if not times[shot] then
            self.HydraVolley = nil
            timer.Remove(name)
            return
        end
        -- Do not stack missed shots in the same tick when the server stalls.
        nextFire = math.max(volley.started + times[shot], now + profile.interval - tick)
        self.HydraVolleyEnd = math.max(self.HydraVolleyEnd, nextFire + times[#times] - times[shot])
        self.NextChaseTime = math.max(self.NextChaseTime or 0, self.HydraVolleyEnd)
    end)
end

function ENT:Initialize()
    baseclass.Get("npc_vj_creature_base").Initialize(self)
    -- Keep direct spawns consistent with the Sandbox NPC list.
    self.StartHealth = spawnHealth
    self:SetMaxHealth(spawnHealth)
    self:SetHealth(spawnHealth)
end

function ENT:Init()
    self:DrawShadow(false)
    self:SetCollisionBounds(Vector(-55, -55, 0), Vector(55, 55, 187))
    self:SetSurroundingBounds(Vector(-201, -79, -1), Vector(149, 79, 250))
    combat.Anchor(self)
    self:SetSaveValue("m_HackedGunPos", launcherOffset)
    -- Use a slower native movement sequence without changing the navigation hull.
    if self.AnimationTranslations then
        local walk = self:SelectWeightedSequence(ACT_WALK)
        local walkSpeed = walk >= 0 and self:GetSequenceGroundSpeed(walk)
        if walkSpeed and walkSpeed >= 1 then
            local run = self:SelectWeightedSequence(ACT_RUN)
            local runSpeed = run >= 0 and self:GetSequenceGroundSpeed(run)
            if not runSpeed or runSpeed < 1 or walkSpeed < runSpeed then
                self.AnimationTranslations[ACT_RUN] = ACT_WALK
            end
        end
    end
    self.HydraServerPose = {}
    self.HydraFiredAt = {}
    self.HydraNextMain = 0
    self.HydraShotTimer = "gfl_hydra_burst_" .. self:EntIndex()
    self:CallOnRemove("HydraShotTimer", function(_, name) timer.Remove(name) end, self.HydraShotTimer)
end

function ENT:OnThink()
    local pos = self:GetPos()
    local grounded = self:IsOnGround()
    local lastPos, wasGrounded = self.HydraStepPos, self.HydraStepGrounded
    self.HydraStepPos, self.HydraStepGrounded = pos, grounded

    local now = CurTime()
    if not lastPos or not grounded or not wasGrounded or not self:IsMoving() or self.Dead
        or (self.HydraVolleyEnd or 0) > now then return end

    local travel = (pos - lastPos):Length2D()
    if travel > rig.maxGaitTravel then return end
    -- Diagonal pairs land twice per gait cycle. One short, local shake per contact.
    local stepDistance = rig.strideDistance * 0.5
    local distance = (self.HydraStepDistance or 0) + travel
    self.HydraStepDistance = distance % stepDistance
    if distance >= stepDistance then
        util.ScreenShake(pos, 3.8, 20, 0.18, 560)
    end
end

function ENT:OnRangeAttack(status, enemy)
    if status == "PreInit" then
        if not IsValid(enemy) or friendlyHit(self, enemy) then return true end
        if friendlyHit(self, targetHull(enemy)) or self:GetPos():DistToSqr(enemy:GetPos()) > self.RangeAttackMaxDistance ^ 2 then
            return true
        end
        return self.HydraVolley ~= nil or (self.HydraVolleyEnd or 0) > CurTime()
    end
    if status ~= "Init" or self.HydraVolley then return end

    local now = CurTime()
    local target = aimPoint(targetHull(enemy), self:LocalToWorld(launcherOffset))
    local distance = self:GetPos():DistToSqr(target)
    local mainReady = now >= self.HydraNextMain
    local useMain = mainReady and distance >= 300 * 300
    local mode = useMain and 2 or 1
    local profile = rig.attacks[mode]

    local volley = {enemy = enemy, mode = mode, profile = profile, started = now}
    self.HydraVolley = volley
    self.HydraVolleyEnd = now + profile.duration
    self:SetHydraAttackTarget(target)
    self:SetHydraAttackStart(now)
    self:SetHydraAttack(mode)
    self:StopMoving()
    self:SetTurnTarget(enemy, profile.duration)
    self.NextChaseTime = math.max(self.NextChaseTime or 0, now + profile.duration)
    -- VJ Base owns attack eligibility and cooldowns; the committed burst owns its own release clock.
    local rate = self.AnimPlaybackRate
    self.NextAnyAttackTime_Range = (profile.duration + (useMain and profile.times[1] or 0)) * rate
    self.NextRangeAttackTime = (useMain and 1.65 + profile.times[1]
        or math.max(minimumAuxStartInterval, profile.duration)) * rate
    if useMain then self.HydraNextMain = now + mainCooldown end
    scheduleShots(self, volley)
end

local function sendMainShot(self, start, finish)
    local tracer = EffectData()
    tracer:SetStart(start)
    tracer:SetOrigin(finish)
    tracer:SetScale(6500)
    util.Effect("GaussTracer", tracer, true, true)

    net.Start(rig.mainShotMessage)
    net.WriteEntity(self)
    net.SendPVS(start)
end

local function traceAim(self, mode, barrel, elapsed, now, launcher, point)
    local pose = self.HydraServerPose
    local pitch, yaw = rig.AimOffset(mode, self:WorldToLocal(point))
    rig.Pose(pose, 0, 0, 1, mode, elapsed, pitch, yaw, true, now, self.HydraFiredAt)
    local source = self:LocalToWorld(rig.MuzzleLocal(pose, barrel))
    local direction = (point - source):GetNormalized()
    if direction:Dot(self:GetForward()) < -0.17 then return end
    local bore = util.TraceLine({
        start = launcher, endpos = source, filter = self, mask = MASK_SOLID_BRUSHONLY,
    })
    if bore.Hit then return end

    -- Cover the muzzle offset and large hulls at the edge of attack range.
    local trace = util.TraceLine({
        start = source, endpos = source + direction * (self.RangeAttackMaxDistance + 256),
        filter = self, mask = MASK_SHOT,
    })
    return trace, source, direction
end

local function hitTarget(trace, enemy, hull)
    local hit = trace and trace.Entity
    return trace and trace.Hit and (hit == enemy or hit == hull
        or (IsValid(hit) and not hit:IsWorld() and hit:GetParent() == hull))
end

local function selectShot(self, enemy, hull, mode, barrel, elapsed, now)
    local launcher = self:LocalToWorld(launcherOffset)
    local target = aimPoint(hull, launcher)
    local trace, source, direction = traceAim(self, mode, barrel, elapsed, now, launcher, target)
    if trace and friendlyHit(self, trace.Entity) then return end
    if hitTarget(trace, enemy, hull) then return trace, source, direction, target end

    -- Check exposed parts of the collision hull if the first aim point misses.
    local candidates = {}
    if hull:IsNPC() or hull:IsPlayer() then
        local head = hull:HeadTarget(source or launcher)
        if isvector(head) then candidates[#candidates + 1] = head end
    end
    local mins, maxs = hull:OBBMins(), hull:OBBMaxs()
    local center = (mins + maxs) * 0.5
    local raised = mins.z + (maxs.z - mins.z) * 0.72
    local width = (maxs.y - mins.y) * 0.30
    candidates[#candidates + 1] = hull:LocalToWorld(Vector(center.x, center.y, raised))
    candidates[#candidates + 1] = hull:LocalToWorld(Vector(center.x, center.y - width, center.z))
    candidates[#candidates + 1] = hull:LocalToWorld(Vector(center.x, center.y + width, center.z))
    candidates[#candidates + 1] = hull:NearestPoint(source or launcher)
    for _, point in ipairs(candidates) do
        if point:DistToSqr(target) >= 1 then
            local hit, from, along = traceAim(self, mode, barrel, elapsed, now, launcher, point)
            if hitTarget(hit, enemy, hull) and not friendlyHit(self, hit.Entity) then
                return hit, from, along, point
            end
        end
    end
    return trace, source, direction, target
end

local function inflict(self, target, amount, kind, position, direction)
    if not IsValid(target) or target:IsWorld() or target == self or friendlyHit(self, target) then return end
    local damage = DamageInfo()
    damage:SetAttacker(self)
    damage:SetInflictor(self)
    damage:SetDamage(self:ScaleByDifficulty(amount))
    damage:SetDamageType(kind)
    damage:SetDamagePosition(position)
    damage:SetDamageForce(direction * amount * 45)
    target:TakeDamageInfo(damage)
end

local function detonate(self, trace)
    local position = trace.HitPos + trace.HitNormal * 3
    local effect = EffectData()
    effect:SetOrigin(position)
    effect:SetScale(1)
    util.Effect("Explosion", effect, true, true)
    for _, target in ipairs(ents.FindInSphere(position, blastRadius)) do
        if target ~= self and target ~= trace.Entity and not friendlyHit(self, target) then
            local exposed = target:NearestPoint(position)
            local cover = util.TraceLine({start = position, endpos = exposed, filter = {self, target}, mask = MASK_SHOT})
            if not cover.Hit then
                local offset = exposed - position
                local amount = 70 * math.Clamp(1 - offset:Length() / blastRadius, 0, 1)
                if amount > 0 then inflict(self, target, amount, DMG_BLAST, exposed, offset:GetNormalized()) end
            end
        end
    end
end

function ENT:OnRangeAttackExecute()
    -- Suppress VJ Base's stock projectile.
    return true
end

fireShot = function(self, volley, shot, enemy, hull, now)
    local mode, profile = volley.mode, volley.profile
    local main = mode == 2
    local barrel = profile.barrels[shot]
    local trace, source, direction, target = selectShot(self, enemy, hull, mode, barrel,
        profile.times[shot] - 0.001, now)
    if not trace then return true end

    self.HydraFiredAt[barrel] = now
    self:SetHydraAttackTarget(target)
    if main then
        sendMainShot(self, source, trace.HitPos)
        self:EmitSound("weapons/ar2/npc_ar2_altfire.wav", 103, 66, 1, CHAN_WEAPON)
    else
        net.Start(rig.auxShotMessage)
        net.WriteEntity(self)
        net.WriteUInt(shot - 1, 4)
        net.WriteFloat(now)
        net.WriteVector(source)
        net.WriteVector(trace.HitPos)
        net.SendPVS(source)
    end
    if trace.Hit and not trace.HitSky then
        inflict(self, trace.Entity, main and mainDamage or auxiliaryDamage,
            main and DMG_BLAST or DMG_BULLET, trace.HitPos, direction)
        if main then detonate(self, trace) end
    end

end

function ENT:OnDeath(_, _, status)
    if status ~= "Init" or self.HydraDeathSent then return end
    self.HydraDeathSent = true
    self.HydraVolley = nil
    timer.Remove(self.HydraShotTimer)
    self:SetHydraAttack(0)

    -- The client animation continues after VJ Base removes this NPC.
    net.Start(rig.deathMessage)
    net.WriteEntity(self)
    net.WriteVector(self:GetPos())
    net.WriteAngle(self:GetAngles())
    net.SendPVS(self:WorldSpaceCenter())
end
