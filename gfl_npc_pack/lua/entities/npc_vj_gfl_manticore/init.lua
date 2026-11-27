AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("gfl_manticore_snpc/geometry.lua")
AddCSLuaFile("gfl_manticore_snpc/rig.lua")
AddCSLuaFile("gfl_manticore_snpc/death_parts.lua")
AddCSLuaFile("gfl_manticore_snpc/death_fx.lua")
include("shared.lua")

local combat = include("gfl_npc_pack/armored_combat.lua")
local rig = include("gfl_manticore_snpc/rig.lua")
util.AddNetworkString(rig.shotMessage)
util.AddNetworkString(rig.deathMessage)

-- The stock model is the VJ navigation carrier. The client draws the PMX rig.
ENT.Model = {"models/antlion_guard.mdl"}
ENT.HullType = HULL_LARGE
ENT.MovementType = VJ_MOVETYPE_GROUND
ENT.StartHealth = 6000
ENT.TurningSpeed = 46
ENT.JumpParams = {Enabled = false}
ENT.CanOpenDoors = false
ENT.SightDistance = 3600
ENT.SightAngle = 165
ENT.Bleeds = false
ENT.HasSounds = false
ENT.HasDeathCorpse = false
ENT.HasDeathAnimation = false
ENT.HasMeleeAttack = false
ENT.HasLeapAttack = false
ENT.HasRangeAttack = true
ENT.AnimTbl_RangeAttack = false
ENT.RangeAttackMinDistance = 190
ENT.RangeAttackMaxDistance = 2400
ENT.RangeAttackAngleRadius = 40
ENT.RangeAttackExtraTimers = false
ENT.TimeUntilRangeAttackProjectileRelease = false
ENT.NextAnyAttackTime_Range = rig.attackDuration
ENT.NextRangeAttackTime = 2.70
ENT.LimitChaseDistance = "OnlyRange"
ENT.LimitChaseDistance_Min = "UseRangeDistance"
ENT.LimitChaseDistance_Max = "UseRangeDistance"

local launcherOffset = Vector(14, 0, 87)
local fireSound = "weapons/ar2/npc_ar2_altfire.wav"
util.PrecacheSound(fireSound)

local function allied(self, ent)
    if not IsValid(ent) or ent:IsWorld() then return false end
    if self == ent then return true end
    if (ent:IsNPC() or ent:IsPlayer() or ent:IsNextBot()) and self:Disposition(ent) == D_LI then return true end
    local tags = ent.VJ_NPC_Class
    if not istable(tags) then return false end
    for _, tag in ipairs(self.VJ_NPC_Class) do
        if table.HasValue(tags, tag) then return true end
    end
    return false
end

local function friendlyHit(self, ent)
    if combat.IsRetaliating(self, ent) then return false end
    return allied(self, ent) or (IsValid(ent) and not ent:IsWorld() and allied(self, ent:GetParent()))
end

combat.Configure(ENT, 4500, friendlyHit)

local function targetHull(enemy)
    if enemy.IsVJBaseSNPC_TankGun then
        local chassis = enemy:GetParent()
        if IsValid(chassis) and chassis.IsVJBaseSNPC_TankChassis then return chassis end
    end
    return enemy
end

local function aimPoint(hull, from)
    local low, high = hull:OBBMins(), hull:OBBMaxs()
    if hull:IsVehicle() or hull.IsVJBaseSNPC_Tank or high.z - low.z <= 64 then
        return hull:LocalToWorld((low + high) * 0.5)
    end
    if hull:IsNPC() or hull:IsPlayer() then
        local point = hull:BodyTarget(from, false)
        if isvector(point) then return point end
    end
    return hull:WorldSpaceCenter()
end

function ENT:Init()
    self:SetMaxHealth(self:Health())
    self:DrawShadow(false)
    self:SetCollisionBounds(Vector(-52, -36, 0), Vector(51, 36, 143))
    self:SetSurroundingBounds(Vector(-159, -62, 0), Vector(171, 62, 200))
    combat.Anchor(self)
    self:SetSaveValue("m_HackedGunPos", launcherOffset)
    self.ManticoreServerPose = {}
    self.ManticoreShotTimer = "gfl_manticore_shot_" .. self:EntIndex()
    self:CallOnRemove("ManticoreShotTimer", function(_, name) timer.Remove(name) end, self.ManticoreShotTimer)
    if self.AnimationTranslations then
        local walk = self:SelectWeightedSequence(ACT_WALK)
        local run = self:SelectWeightedSequence(ACT_RUN)
        local walkSpeed = walk >= 0 and self:GetSequenceGroundSpeed(walk)
        local runSpeed = run >= 0 and self:GetSequenceGroundSpeed(run)
        if walkSpeed and walkSpeed > 0 and (not runSpeed or runSpeed <= 0 or walkSpeed < runSpeed) then
            self.AnimationTranslations[ACT_RUN] = ACT_WALK
        end
    end
end

function ENT:OnThink()
    local pos, grounded = self:GetPos(), self:IsOnGround()
    local previous, wasGrounded = self.ManticoreStepPos, self.ManticoreStepGrounded
    self.ManticoreStepPos, self.ManticoreStepGrounded = pos, grounded
    if self.Dead or not grounded or not wasGrounded or not previous or not self:IsMoving()
        or self.ManticoreVolleyEnemy ~= nil or (self.ManticoreVolleyEnd or 0) > CurTime() then return end
    local travel = (pos - previous):Length2D()
    if travel > 100 then return end
    local step = rig.strideDistance * 0.5
    local distance = (self.ManticoreStepDistance or 0) + travel
    self.ManticoreStepDistance = distance % step
    if distance >= step then util.ScreenShake(pos, 2.6, 19, 0.16, 490) end
end

local fireShot

function ENT:OnRangeAttack(status, enemy)
    if status == "PreInit" then
        return not IsValid(enemy) or friendlyHit(self, enemy) or friendlyHit(self, targetHull(enemy))
            or (self.ManticoreVolleyEnd or 0) > CurTime()
    end
    if status ~= "Init" or self.ManticoreVolleyEnemy then return end

    local now = CurTime()
    self.ManticoreVolleyEnemy = enemy
    self.ManticoreVolleyEnd = now + rig.attackDuration
    self:SetManticoreAttackStart(now)
    self:SetManticoreAttackTarget(aimPoint(targetHull(enemy), self:LocalToWorld(launcherOffset)))
    self:StopMoving()
    self:SetTurnTarget(enemy, rig.attackDuration)
    self.NextChaseTime = math.max(self.NextChaseTime or 0, self.ManticoreVolleyEnd)

    local rate = self.AnimPlaybackRate
    self.NextAnyAttackTime_Range = rig.attackDuration * rate
    self.NextRangeAttackTime = 2.70 * rate
    timer.Create(self.ManticoreShotTimer, rig.release, 1, function()
        if not IsValid(self) then return end
        local locked = self.ManticoreVolleyEnemy
        self.ManticoreVolleyEnemy = nil
        if not locked or not combat.CanFire(self) then return end
        local target, hull = combat.Target(self, locked, targetHull, friendlyHit)
        if not target then return end
        if target ~= locked then self:SetTurnTarget(target, rig.attackDuration - rig.release) end
        fireShot(self, target, hull)
    end)
end

local function traceAim(self, launcher, target)
    local pose = self.ManticoreServerPose
    local pitch, yaw = rig.AimOffset(self:WorldToLocal(target))
    rig.Pose(pose, 0, 0, 1, rig.release, pitch, yaw, nil, true)
    local source = self:LocalToWorld(rig.MuzzleLocal(pose))
    local direction = (target - source):GetNormalized()
    if direction:Dot(self:GetForward()) <= 0 then return end
    local bore = util.TraceLine({start = launcher, endpos = source, filter = self, mask = MASK_SOLID_BRUSHONLY})
    if bore.Hit then return end
    local hit = util.TraceLine({
        start = source, endpos = source + direction * (self.RangeAttackMaxDistance + 200),
        filter = self, mask = MASK_SHOT,
    })
    return hit, source, direction
end

local function selectShot(self, enemy, hull)
    local launcher = self:LocalToWorld(launcherOffset)
    local target = aimPoint(hull, launcher)
    local hit, source, direction = traceAim(self, launcher, target)
    if hit and friendlyHit(self, hit.Entity) then return end
    if hit and (hit.Entity == hull or hit.Entity == enemy) then return hit, source, direction, target end

    local mins, maxs = hull:OBBMins(), hull:OBBMaxs()
    local center = (mins + maxs) * 0.5
    local top = mins.z + (maxs.z - mins.z) * 0.73
    local width = (maxs.y - mins.y) * 0.28
    for _, offset in ipairs({Vector(0, 0, top - center.z), Vector(0, -width, 0), Vector(0, width, 0)}) do
        local aim = hull:LocalToWorld(center + offset)
        local trace, from, along = traceAim(self, launcher, aim)
        if trace and (trace.Entity == hull or trace.Entity == enemy) then return trace, from, along, aim end
    end
    return hit, source, direction, target
end

local function inflict(self, ent, damage, position, direction)
    if not IsValid(ent) or ent:IsWorld() or friendlyHit(self, ent) then return end
    local info = DamageInfo()
    info:SetAttacker(self)
    info:SetInflictor(self)
    info:SetDamage(self:ScaleByDifficulty(damage))
    info:SetDamageType(DMG_BLAST)
    info:SetDamagePosition(position)
    info:SetDamageForce(direction * damage * 40)
    ent:TakeDamageInfo(info)
end

function ENT:OnRangeAttackExecute()
    return true
end

fireShot = function(self, enemy, hull)
    local hit, source, direction, target = selectShot(self, enemy, hull)
    if not hit then return true end
    self:SetManticoreAttackTarget(target)
    self:EmitSound(fireSound, 95, 79, 1, CHAN_WEAPON)
    net.Start(rig.shotMessage)
    net.WriteEntity(self)
    net.WriteVector(source)
    net.WriteVector(hit.HitPos)
    net.SendPVS(source)
    if hit.Hit and not hit.HitSky then
        inflict(self, hit.Entity, 96, hit.HitPos, direction)
        local center = hit.HitPos + hit.HitNormal * 3
        local explosion = EffectData()
        explosion:SetOrigin(center)
        explosion:SetScale(0.72)
        util.Effect("Explosion", explosion, true, true)
        for _, ent in ipairs(ents.FindInSphere(center, 112)) do
            if ent ~= hit.Entity and not friendlyHit(self, ent) then
                local point = ent:NearestPoint(center)
                local offset = point - center
                local damage = 44 * math.Clamp(1 - offset:Length() / 112, 0, 1)
                if damage > 0 and not util.TraceLine({start = center, endpos = point, filter = {self, ent}, mask = MASK_SHOT}).Hit then
                    inflict(self, ent, damage, point, offset:GetNormalized())
                end
            end
        end
    end
end

function ENT:OnDeath(_, _, status)
    if status ~= "Init" or self.ManticoreDeathSent then return end
    self.ManticoreDeathSent = true
    self.ManticoreVolleyEnemy = nil
    timer.Remove(self.ManticoreShotTimer)
    net.Start(rig.deathMessage)
    net.WriteEntity(self)
    net.WriteVector(self:GetPos())
    net.WriteAngle(self:GetAngles())
    net.SendPVS(self:WorldSpaceCenter())
end
