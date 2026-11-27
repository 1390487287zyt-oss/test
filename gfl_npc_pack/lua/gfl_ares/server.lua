local combat = include("gfl_npc_pack/armored_combat.lua")
local config = include("gfl_ares/config.lua")
local rig = include("gfl_ares/rig.lua")
local profile = config.profiles[ENT.AA02Class]
local skillCount = #profile.cooldowns
local missileClass = "gfl_aa02_rocket"
local center = Vector(0, 0, 103)
local launchBox = Vector(2, 2, 2)
local shotSound = {"npc/strider/strider_minigun2.wav", "weapons/rpg/rocketfire1.wav", "npc/strider/fire.wav"}
local chargeSound = "npc/strider/charging.wav"
for _, name in ipairs({config.shotMessage, config.laserMessage, config.deathMessage}) do util.AddNetworkString(name) end
for _, sound in ipairs(shotSound) do util.PrecacheSound(sound) end
util.PrecacheSound(chargeSound)
local shieldVisual = config.shieldVisual
util.PrecacheSound(shieldVisual.deploySound)
util.PrecacheSound(shieldVisual.breakSound)

ENT.Model = {"models/antlion_guard.mdl"}
ENT.HullType = HULL_LARGE
ENT.MovementType = VJ_MOVETYPE_GROUND
ENT.CanOpenDoors = false
ENT.JumpParams = {Enabled = false}
ENT.TurningSpeed = 42
ENT.SightDistance = 5000
ENT.SightAngle = 168
ENT.Bleeds = false
ENT.BloodColor = false
ENT.HasSounds = false
ENT.HasDeathCorpse = false
ENT.HasDeathAnimation = false
ENT.HasMeleeAttack = false
ENT.HasLeapAttack = false
ENT.HasRangeAttack = true
ENT.AnimTbl_RangeAttack = false
ENT.RangeAttackMinDistance = 16
ENT.RangeAttackMaxDistance = config.attacks[skillCount].range
ENT.RangeAttackAngleRadius = 49
ENT.RangeAttackExtraTimers = false
ENT.TimeUntilRangeAttackProjectileRelease = false
ENT.NextRangeAttackTime = .15
ENT.NextAnyAttackTime_Range = .15
ENT.LimitChaseDistance = "OnlyRange"
ENT.LimitChaseDistance_Min = 185
ENT.LimitChaseDistance_Max = config.attacks[1].range
ENT.VJ_ID_Boss = true

local alliedTags = {}
for _, tag in ipairs(ENT.VJ_NPC_Class) do alliedTags[tag] = true end

local function isAlly(self, ent)
    if not IsValid(ent) or ent:IsWorld() then return false end
    if ent == self then return true end
    if (ent:IsNPC() or ent:IsNextBot() or ent:IsPlayer()) and self:Disposition(ent) == D_LI then return true end
    for _, tag in ipairs(istable(ent.VJ_NPC_Class) and ent.VJ_NPC_Class or {}) do
        if alliedTags[tag] then return true end
    end
    return false
end

local function friendly(self, ent)
    if combat.IsRetaliating(self, ent) then return false end
    return isAlly(self, ent) or (IsValid(ent) and not ent:IsWorld() and isAlly(self, ent:GetParent()))
end

combat.Configure(ENT, profile.mass, friendly)

local function enemyHull(ent)
    if ent.IsVJBaseSNPC_TankGun then
        local parent = ent:GetParent()
        if IsValid(parent) and parent.IsVJBaseSNPC_TankChassis then return parent end
    end
    return ent
end

local function aimAt(ent)
    if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
        return ent:LocalToWorld((ent:OBBMins() + ent:OBBMaxs()) * .5)
    end
    return ent:WorldSpaceCenter()
end

local function applyDamage(self, ent, amount, kind, point, direction)
    if not IsValid(ent) or ent:IsWorld() or friendly(self, ent) or amount <= 0 then return end
    local dmg = DamageInfo()
    dmg:SetAttacker(self)
    dmg:SetInflictor(self)
    dmg:SetDamage(self:ScaleByDifficulty(amount))
    dmg:SetDamageType(kind)
    dmg:SetDamagePosition(point)
    dmg:SetDamageForce(direction * amount * 31)
    ent:TakeDamageInfo(dmg)
end

function ENT:AA02Blast(point, hit, direction, direct, splash, radius, scale)
    if scale then
        local effect = EffectData()
        effect:SetOrigin(point)
        effect:SetScale(scale)
        util.Effect("Explosion", effect, true, true)
    end
    if direct then applyDamage(self, hit, direct, DMG_BLAST, point, direction) end
    for _, target in ipairs(ents.FindInSphere(point, radius)) do
        if target ~= hit and target:GetClass() ~= missileClass and not friendly(self, target) then
            local nearest = target:NearestPoint(point)
            local delta = nearest - point
            local fraction = 1 - delta:Length() / radius
            if fraction > 0 and not util.TraceLine({
                start = point, endpos = nearest, mask = MASK_SHOT, filter = {self, target, hit},
            }).Hit then
                applyDamage(self, target, splash * fraction, DMG_BLAST, nearest, delta:GetNormalized())
            end
        end
    end
end

local function deployShield(self, now)
    self.AA02RechargeAt = nil
    self:SetAA02ShieldStart(now)
    self:SetAA02ShieldHP(profile.shield)
    local started = self:GetAA02ShieldStart()
    timer.Simple(shieldVisual.soundDelay, function()
        if IsValid(self) and not self.Dead and self:GetAA02ShieldHP() > 0 and self:GetAA02ShieldStart() == started then
            self:EmitSound(shieldVisual.deploySound, 85)
        end
    end)
end

function ENT:Initialize()
    baseclass.Get("npc_vj_creature_base").Initialize(self)
    self.StartHealth = profile.health
    self:SetMaxHealth(profile.health)
    self:SetHealth(profile.health)
    deployShield(self, CurTime())
end

function ENT:Init()
    self:DrawShadow(false)
    self:SetCollisionBounds(Vector(-43, -54, 0), Vector(43, 54, 147))
    self:SetSurroundingBounds(Vector(-143, -85, -3), Vector(197, 77, 190))
    combat.Anchor(self)
    self:SetSaveValue("m_HackedGunPos", center)
    self.AA02Cooldown = {}
    for skill = 1, skillCount do self.AA02Cooldown[skill] = 0 end
    self.AA02NextSkill = 1
    self.AA02Pose = {}
    local translations = self.AnimationTranslations
    if translations then
        local walk = self:SelectWeightedSequence(ACT_WALK)
        if walk >= 0 and self:GetSequenceGroundSpeed(walk) > 1 then
            translations[ACT_RUN] = ACT_WALK
        end
    end
end

local function applyGroundSpeed(self)
    if self:GetNavType() ~= NAV_GROUND or self:GetCurGoalType() == 0 then return end

    local speed = self:GetSequenceGroundSpeed(self:GetSequence())
    if speed <= 0 then
        local sequence = self:GetMovementSequence()
        if sequence < 0 then return end
        speed = self:GetSequenceGroundSpeed(sequence)
    end
    if speed > 0 then
        self:SetSaveValue("m_flGroundSpeed", speed * self:GetModelScale() * config.groundMoveScale)
    end
end

function ENT:OverrideMove(interval)
    local overridden = baseclass.Get("npc_vj_creature_base").OverrideMove(self, interval)
    if not overridden then applyGroundSpeed(self) end
    return overridden
end

function ENT:OverrideMoveFacing(interval, goal)
    local overridden = baseclass.Get("npc_vj_creature_base").OverrideMoveFacing(self, interval, goal)
    -- The navigator may select a new movement sequence after OverrideMove.
    applyGroundSpeed(self)
    return overridden
end

local function stopVolley(self)
    if self:GetAA02Skill() == 3 then self:StopSound(chargeSound) end
    self.AA02Volley = nil
    self:SetAA02Skill(0)
end

function ENT:OnDamaged(dmg, _, status)
    if status ~= "PreDamage" or self.Dead then return end
    local amount, shield = dmg:GetDamage(), self:GetAA02ShieldHP()
    if amount <= 0 or shield <= 0 then return end
    if friendly(self, dmg:GetAttacker()) then
        dmg:SetDamage(0)
        return
    end
    local absorbed = math.min(shield, amount)
    self:SetAA02ShieldHP(shield - absorbed)
    dmg:SetDamage(amount - absorbed)
    if absorbed < shield then return end
    local now = CurTime()
    self:SetAA02StunEnd(now + profile.stun)
    self.AA02StunStart = now
    self.AA02RechargeAt = profile.recharge and now + profile.recharge
    self.AA02BeforeStun = self:GetState()
    -- The shield break prevents new attacks and movement. A committed volley can finish.
    self:StopAttacks(false)
    self:StopMoving()
    self:SetLocalVelocity(Vector())
    self:SetState(VJ_STATE_FREEZE)
    self:EmitSound(shieldVisual.breakSound, 100)
end

local function groundAim(self, hull)
    local mins, maxs = hull:OBBMins(), hull:OBBMaxs()
    local midpoint = (mins + maxs) * .5
    local feet = hull:LocalToWorld(Vector(midpoint.x, midpoint.y, mins.z))
    local down = util.TraceLine({
        start = feet + Vector(0, 0, 40), endpos = feet - Vector(0, 0, 1800),
        mask = MASK_SOLID_BRUSHONLY, filter = {self, hull},
    })
    if not down.Hit or down.HitSky or down.StartSolid or down.HitNormal.z < .25 then return end
    return down.HitPos
end

local function selectSkill(self, now, hull)
    local distance = self:GetPos():DistToSqr(hull:GetPos())
    for offset = 0, skillCount - 1 do
        local skill = (self.AA02NextSkill + offset - 1) % skillCount + 1
        local attack = config.attacks[skill]
        if self.AA02Cooldown[skill] <= now and distance <= attack.range ^ 2
            and distance >= (attack.minRange or 0) ^ 2 then
            if skill ~= 3 then return skill, aimAt(hull) end
            local point = groundAim(self, hull)
            if point then return skill, point end
        end
    end
end

function ENT:OnRangeAttack(status, enemy)
    if status ~= "PreInit" and status ~= "Init" then return end
    local now = CurTime()
    if self.AA02Volley or self.AA02StunStart or now < (self.AA02PauseUntil or 0)
        or not IsValid(enemy) or friendly(self, enemy) then return true end
    local hull = enemyHull(enemy)
    if friendly(self, hull) then return true end
    local skill, aim = selectSkill(self, now, hull)
    if status == "PreInit" then return skill == nil end
    if not skill then return end

    local attack = config.attacks[skill]
    local duration = (config.lastShotTime(skill, profile) + attack.recovery) / profile.speed
    self.AA02Volley = {
        skill = skill, attack = attack, enemy = enemy, started = now,
        nextShot = now + attack.windup / profile.speed, ends = now + duration,
        count = config.shotCount(skill, profile), index = 1, fired = {},
    }
    self.AA02NextSkill = skill % skillCount + 1
    self.AA02Cooldown[skill] = now + profile.cooldowns[skill]
    self:SetAA02Aim(aim)
    self:SetAA02SkillStart(now)
    self:SetAA02Skill(skill)
    if skill == 3 then self:EmitSound(chargeSound, 88, 100 * profile.speed, .75, CHAN_AUTO) end
    self:StopMoving()
    self:SetTurnTarget(enemy, duration)
    self.NextChaseTime = math.max(self.NextChaseTime or 0, now + duration)
end

function ENT:OnRangeAttackExecute()
    -- The shared volley clock below controls every muzzle and discharge.
    return true
end

local function fireRocket(self, source, dir, target, number)
    local projectile = ents.Create(missileClass)
    if not IsValid(projectile) then return false end
    projectile:SetPos(source)
    local sideways = number % 2 == 1 and -1 or 1
    local vertical = number <= 2 and .14 or .07
    projectile:SetAngles((dir + self:GetRight() * sideways * .08 + self:GetUp() * vertical):Angle())
    projectile:SetOwner(self)
    projectile.AA02Target = target + self:GetRight() * sideways * 22 + self:GetForward() * (number <= 2 and 15 or -15)
    projectile.AA02Damage = profile.damage[2]
    projectile.AA02Speed = profile.speed
    projectile:Spawn()
    return true
end

local function fireLaser(self, volley, source, target, direction, now)
    local trace = util.TraceLine({
        start = source, endpos = target + direction * 6,
        mask = MASK_SOLID_BRUSHONLY, filter = self,
    })
    local impact = trace.Hit and trace.HitPos or target
    local hit = trace.Hit and not trace.HitSky and not trace.StartSolid
    local normal = hit and trace.HitNormal or -direction

    self:StopSound(chargeSound)
    self:EmitSound(shotSound[3], 105, 100, 1, CHAN_WEAPON)
    volley.fired.main = now
    if hit then
        local position = impact + normal * 4
        self:AA02Blast(position, nil, direction, nil, profile.damage[3], config.cannonRadius)
        util.ScreenShake(impact, 12, 21, .48, 1250)
    end

    local recipients = RecipientFilter()
    recipients:AddPVS(source)
    recipients:AddPVS(impact)
    net.Start(config.laserMessage)
    net.WriteEntity(self)
    net.WriteFloat(now)
    net.WriteVector(source)
    net.WriteVector(impact)
    net.WriteNormal(normal)
    net.WriteBool(hit)
    net.Send(recipients)
end

local function shot(self, volley, port, ordinal, now)
    local target = self:GetAA02Aim()
    local localTarget = self:WorldToLocal(target)
    local angles = (localTarget - center):Angle()
    local fired = {}
    for key, time in pairs(volley.fired) do fired[key] = now - time end
    local brace = math.Clamp(1 - math.abs(now - self:GetAA02ShieldStart() - .26) / .45, 0, 1)
    rig.Pose(self.AA02Pose, 0, 0, 0, volley.skill, (now - volley.started) * profile.speed, angles, fired, 0, brace, volley.count, localTarget)
    local localPos = rig.Muzzle(self.AA02Pose, port)
    local source = self:LocalToWorld(localPos)
    local direction = (target - source):GetNormalized()
    if direction:Dot(self:GetForward()) <= .25 then return false end
    if util.TraceLine({start = self:LocalToWorld(center), endpos = source, mask = MASK_SOLID_BRUSHONLY, filter = self}).Hit then return false end

    if volley.skill == 3 then
        fireLaser(self, volley, source, target, direction, now)
        return true
    end
    local impact
    if volley.skill == 2 then
        local path = util.TraceHull({
            start = source, endpos = source + direction * 21, mins = -launchBox, maxs = launchBox,
            filter = self, mask = MASK_SOLID_BRUSHONLY,
        })
        if path.Hit or not fireRocket(self, source, direction, target, ordinal) then return false end
        impact = source + direction * 100
    else
        local trace = util.TraceLine({
            start = source, endpos = source + direction * (volley.attack.range + 420),
            mask = MASK_SHOT, filter = self,
        })
        if friendly(self, trace.Entity) then return false end
        impact = trace.HitPos
        if trace.Hit and not trace.HitSky then
            applyDamage(self, trace.Entity, profile.damage[1], DMG_BULLET, impact, direction)
        end
    end

    if volley.skill ~= 2 or volley.lastRocketSound ~= now then
        self:EmitSound(shotSound[volley.skill], 91, 100, 1, CHAN_WEAPON)
        if volley.skill == 2 then volley.lastRocketSound = now end
    end
    if volley.skill == 1 then volley.fired[port] = now end
    net.Start(config.shotMessage)
    net.WriteEntity(self)
    net.WriteUInt(volley.skill, 2)
    net.WriteUInt(ordinal - 1, 2)
    net.WriteFloat(now)
    net.WriteVector(source)
    net.WriteVector(impact)
    net.SendPVS(source)
    return true
end

local function updateVolleyAim(self, volley, now)
    local target, hull = combat.Target(self, volley.enemy, enemyHull, friendly, volley.attack.range, volley.attack.minRange)
    local aim
    if hull then
        if volley.skill == 3 then aim = groundAim(self, hull) else aim = aimAt(hull) end
    end
    if aim then
        if target ~= volley.enemy then
            volley.enemy = target
            if not self.AA02StunStart then self:SetTurnTarget(target, math.max(.1, volley.ends - now)) end
        end
        self:SetAA02Aim(aim)
    end
    return aim
end

function ENT:OnThink()
    if self.Dead then return end
    local now = CurTime()
    if self.AA02StunStart and now >= self:GetAA02StunEnd() then
        if self:GetState() == VJ_STATE_FREEZE then self:SetState(self.AA02BeforeStun) end
        self.AA02StunStart, self.AA02BeforeStun = nil, nil
    end
    if self.AA02RechargeAt and now >= self.AA02RechargeAt and self:GetAA02ShieldHP() <= 0 then
        deployShield(self, now)
    end
    local volley = self.AA02Volley
    if not volley then return end
    if volley.skill > skillCount or not combat.CanFire(self) then
        stopVolley(self)
        return
    end
    if self:IsMoving() then self:StopMoving() end
    if now < volley.nextShot then
        if volley.skill == 3 and volley.index <= volley.count and now >= (volley.nextAim or 0) then
            volley.nextAim = now + .1
            updateVolleyAim(self, volley, now)
        end
        return
    end
    local attack = volley.attack
    if volley.index > volley.count then
        stopVolley(self)
        self.AA02PauseUntil = now + profile.pause
        return
    end
    local aim = updateVolleyAim(self, volley, now)
    if volley.skill == 2 then
        -- Snapshot all four muzzles in the same server tick.
        if aim then
            for index, port in ipairs(attack.ports) do shot(self, volley, port, index, now) end
            volley.fired.rocket = now
        end
        volley.index = volley.count + 1
    else
        if aim then shot(self, volley, attack.ports[volley.index], volley.index, now) end
        volley.index = volley.index + 1
    end
    local delay = volley.index > volley.count and attack.recovery or attack.interval
    volley.nextShot = now + delay / profile.speed
end

function ENT:OnDeath(_, _, status)
    if status ~= "Init" or self.AA02DeathSent then return end
    self.AA02DeathSent = true
    stopVolley(self)
    self.AA02RechargeAt = nil
    self:SetAA02ShieldHP(0)
    net.Start(config.deathMessage)
    net.WriteEntity(self)
    net.WriteVector(self:GetPos())
    net.WriteAngle(self:GetAngles())
    net.WriteBool(profile.cannonShots > 0)
    net.SendPVS(self:GetPos())
    local blast = EffectData()
    blast:SetOrigin(self:LocalToWorld(center))
    blast:SetScale(1.8)
    util.Effect("Explosion", blast, true, true)
end
