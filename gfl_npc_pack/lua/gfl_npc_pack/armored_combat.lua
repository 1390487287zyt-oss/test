local combat = {}
local zero = Vector()
local retaliationHits = 2
local baseName = "npc_vj_creature_base"

local function isCombatant(ent)
    return IsValid(ent) and not ent:IsWorld() and (ent:IsNPC() or ent:IsPlayer() or ent:IsNextBot())
end

local function attackerUnit(ent)
    if not IsValid(ent) or ent:IsWorld() then return end
    if ent.IsVJBaseSNPC_TankGun then
        local parent = ent:GetParent()
        if isCombatant(parent) and parent.IsVJBaseSNPC_TankChassis then return parent end
    end
    if isCombatant(ent) then return ent end
    local owner = ent:GetOwner()
    if isCombatant(owner) then return attackerUnit(owner) end
    local parent = ent:GetParent()
    if isCombatant(parent) then return attackerUnit(parent) end
end

function combat.IsRetaliating(self, ent)
    local counts = self.GFLFriendlyHits
    if not counts or not IsValid(ent) or ent:IsWorld() then return false end
    local unit = attackerUnit(ent)
    return unit ~= nil and counts[unit] == retaliationHits
end

local function applyMass(self)
    local physics = self:GetPhysicsObject()
    if IsValid(physics) and physics:GetMass() ~= self.GFLHeavyMass then
        physics:SetMass(self.GFLHeavyMass)
    end
end

function combat.Anchor(self)
    self:AddEFlags(EFL_NO_DAMAGE_FORCES)
    applyMass(self)
    -- The engine may recreate the movement hull during activation.
    timer.Simple(0, function()
        if IsValid(self) and not self.Dead then applyMass(self) end
    end)
end

local function settleImpact(self)
    -- Some projectiles explicitly set velocity as well as dealing damage.
    -- Remove upward impulses while keeping the current ground motion and gravity.
    local base = self:GetBaseVelocity()
    local localVelocity = self:GetVelocity() - base
    if base.z > 0 then self:SetVelocity(Vector(base.x, base.y, 0)) end
    if localVelocity.z > 0 then
        self:SetLocalVelocity(Vector(localVelocity.x, localVelocity.y, 0))
    end
end

local function healing(damage)
    for _, flag in pairs({DMG_DROWNRECOVER, DMG_HEAL, DMG_HEALING}) do
        if isnumber(flag) and flag ~= 0 and damage:IsDamageType(flag) then return true end
    end
    return false
end

local function recordFriendlyHit(self, damage, isFriendly)
    local source = damage:GetAttacker()
    local attacker = attackerUnit(source) or attackerUnit(damage:GetInflictor())
    if not attacker or attacker == self or attacker:Health() <= 0
        or not (isFriendly(self, attacker) or isFriendly(self, source)) then return end

    local counts = self.GFLFriendlyHits or {}
    self.GFLFriendlyHits = counts
    if counts[attacker] == retaliationHits then return end
    for previous in pairs(counts) do
        if not IsValid(previous) then counts[previous] = nil end
    end
    local count = (counts[attacker] or 0) + 1
    counts[attacker] = count
    if count ~= retaliationHits then return end

    -- Same-class NPCs can be absent from VJ Base's relationship list.
    local watched = self.RelationshipEnts
    if watched and not table.HasValue(watched, attacker) then watched[#watched + 1] = attacker end
    self:SetRelationshipMemory(attacker, VJ.MEM_OVERRIDE_DISPOSITION, D_HT)
    self:AddEntityRelationship(attacker, D_HT, 2)
    return attacker
end

function combat.Configure(ent, mass, isFriendly)
    ent.GFLHeavyMass = mass
    ent.DamageResponse = "OnlySearch"
    ent.CanFlinch = false
    ent.CombatDamageResponse = false
    ent.DamageAllyResponse = false
    ent.CanDetectDangers = false
    ent.RangeAttackAnimationFaceEnemy = false
    -- VJ Base also calls these schedules for some ally and passive reactions.
    ent.SCHEDULE_COVER_ENEMY = function() end
    ent.SCHEDULE_COVER_ORIGIN = function() end
    ent.CheckRelationship = function(self, other)
        local disposition = baseclass.Get(baseName).CheckRelationship(self, other)
        if disposition == D_ER then return disposition end
        if combat.IsRetaliating(self, other) then return D_HT end
        if isFriendly(self, other) then return D_LI end
        return disposition
    end
    ent.OnTakeDamage = function(self, damage)
        damage:SetDamageForce(zero)
        local attacker
        if not self.Dead and damage:GetDamage() > 0 and not healing(damage) then
            settleImpact(self)
            if not self.GFLImpactQueued then
                self.GFLImpactQueued = true
                timer.Simple(0, function()
                    if not IsValid(self) then return end
                    self.GFLImpactQueued = nil
                    if not self.Dead then settleImpact(self) end
                end)
            end
            -- Count the incoming amount before VJ's friendly bullet filter or shields absorb it.
            if not self.GodMode then attacker = recordFriendlyHit(self, damage, isFriendly) end
        end
        local result = baseclass.Get(baseName).OnTakeDamage(self, damage)
        if IsValid(attacker) and combat.CanFire(self) and self:GetState() ~= VJ_STATE_FREEZE
            and self:CheckRelationship(attacker) == D_HT then
            if self.IsFollowing and self.FollowData.Target == attacker then self:ResetFollowBehavior() end
            self:ForceSetEnemy(attacker, true)
        end
        return result
    end
    ent.TranslateSchedule = function(self, schedule)
        if schedule == SCHED_TAKE_COVER_FROM_ENEMY or schedule == SCHED_TAKE_COVER_FROM_ORIGIN
            or schedule == SCHED_TAKE_COVER_FROM_BEST_SOUND or schedule == SCHED_RUN_FROM_ENEMY
            or schedule == SCHED_RUN_FROM_ENEMY_FALLBACK or schedule == SCHED_RUN_FROM_ENEMY_MOB then
            local enemy = self:GetEnemy()
            return IsValid(enemy) and SCHED_COMBAT_FACE or SCHED_IDLE_STAND
        end
    end
end

function combat.CanFire(ent)
    return not ent.Dead and ent:Health() > 0 and VJ_CVAR_AI_ENABLED ~= false
end

function combat.Target(self, locked, hullFor, isFriendly, maxRange, minRange)
    local origin = self:GetPos()
    local rangeSqr = (maxRange or self.RangeAttackMaxDistance) ^ 2
    local minRangeSqr = (minRange or 0) ^ 2

    local function canEngage(enemy)
        if not IsValid(enemy) or enemy:IsWorld() or isFriendly(self, enemy) then return end
        local hull = hullFor(enemy)
        local distance = origin:DistToSqr(hull:GetPos())
        if isFriendly(self, hull) or distance > rangeSqr or distance < minRangeSqr then return end
        if (enemy:IsNPC() or enemy:IsPlayer() or enemy:IsNextBot()) and enemy:Health() <= 0 then return end
        return hull
    end

    local hull = canEngage(locked)
    if hull then return locked, hull end

    local enemy = self:GetEnemy()
    if enemy ~= locked then
        hull = canEngage(enemy)
        if hull then return enemy, hull end
    end
end

return combat
