AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model             = {"models/yo_ponika/sf_mdl/vespid_swap.mdl"}
ENT.StartHealth       = 600
ENT.TurningSpeed      = 30
ENT.DropWeaponOnDeath = true
ENT.VJ_NPC_Class      = {"CLASS_SANGVIS"}
ENT.BloodColor        = "Black"
ENT.UsePlayerModelMovement  = true
ENT.JumpParams = {
    Enabled     = true,
    MaxRise     = 200,
    MaxDrop     = 500,
    MaxDistance = 300,
}

ENT.Weapon_MaxDistance         = 2500
ENT.WeaponSpread               = 1
ENT.Weapon_CanMoveFire         = true
ENT.ConstantlyFaceEnemy_IfAttacking = true
ENT.Weapon_RetreatDistance     = 10
ENT.Weapon_FindCoverOnReload   = false
ENT.AnimTbl_WeaponAttack       = ACT_RANGE_ATTACK1
ENT.AnimTbl_WeaponAttackGesture = ACT_GESTURE_RANGE_ATTACK1
ENT.CanCallReinforce      = true
ENT.ReinforceCooldown     = 200
ENT.ReinforceSmokeEntity  = "obj_vj_adv_officer_smoke"
ENT.ReinforceDropship     = "event_advent_transporter"
ENT.ReinforceThrowBone    = "ValveBiped.Bip01_L_Hand"
ENT.ReinforceAnim         = "ThrowItem"
ENT.ReinforceDelay        = 1
ENT.ReinforceDropshipTime = math.random(10,20)

ENT.DisableWOSAnimations = true

ENT.HasMeleeAttack        = true
ENT.MeleeAttackDamage     = 45
ENT.MeleeAttackDamageType = DMG_CLUB
ENT.AnimTbl_MeleeAttack   = {"melee_gunhit","melee_gunhit1","melee_gunhit2"}
ENT.CanCrouchOnWeaponAttack = true

ENT.HasGrenadeAttack = true
ENT.NextGrenadeAttackTime = 30
ENT.CanThrowBackDetectedGrenades = false
ENT.GrenadeAttackEntity = "obj_vj_adv_he_grenade"
ENT.GrenadeAttackMinDistance = 500
ENT.GrenadeAttackMaxDistance = 1000
ENT.GrenadeAttackChance = 4
ENT.GrenadeAttackBone = "ValveBiped.Bip01_L_Finger1"
ENT.AnimTbl_GrenadeAttack = "grenThrow"
ENT.HasGrenadeAttackSounds = true
ENT.GrenadeAttackSoundChance = 1
ENT.GrenadeAttackAnimationFaceEnemy = true
ENT.GrenadeAttackThrowTime = 0.8

ENT.SightDistance        = 2000
ENT.SightAngle           = 300
ENT.EnemyTimeout         = 30
ENT.CanInvestigate       = true
ENT.InvestigateSoundMultiplier = 100
ENT.CanDetectDangers     = true
ENT.DangerDetectionDistance = 400

ENT.AnimTbl_TakingCover  = ACT_COVER_LOW
ENT.AnimTbl_MoveToCover  = ACT_RUN_CROUCH
ENT.CanReceiveOrders     = true
ENT.CallForHelp          = true
ENT.CallForHelpDistance  = 10000
ENT.CallForHelpCooldown  = 4
ENT.CallForHelpAnimCooldown = 30
ENT.CallForHelpAnimFaceEnemy = true
ENT.AnimTbl_CallForHelp  = ACT_HL2MP_IDLE_AR2

ENT.CanFlinch        = true
ENT.FlinchChance     = 10
ENT.NextFlinchTime   = 5
ENT.AnimTbl_Flinch   = {"vjges_flinch_gesture","vjges_flinchsmall","vjges_flinchbig"}
ENT.FlinchHitGroupMap = {
    [HITGROUP_HEAD] = {"vjges_flinchheadgest"},
    [HITGROUP_CHEST] = {"vjges_flinchchest"},
    [HITGROUP_STOMACH] = {"vjges_flinchgutgest"},
    [HITGROUP_LEFTARM] = {"vjges_flinchlarmgest"},
    [HITGROUP_RIGHTARM] = {"vjges_flinchrarmgest"},
    [HITGROUP_LEFTLEG] = {"vjges_flinchleft"},
    [HITGROUP_RIGHTLEG] = {"vjges_flinchright"}
}
ENT.FootStepTimeRun = 0.25
ENT.FootStepTimeWalk = 0.5
ENT.SoundTbl_FootStep = {"step1","step2","step3","step4","step5","step6","step7","step8","step9","step10"}
ENT.SoundTbl_Grenade      = {"adv_gren1", "adv_gren2", "adv_gren3"}
ENT.SoundTbl_Reload       = {"adv_reload1", "adv_reload2", "adv_reload3"}

function ENT:SetAnimationTranslations(wepHoldType)
    local at = self.AnimationTranslations

    at[ACT_WALK_CROUCH]     = ACT_HL2MP_WALK_CROUCH_PASSIVE
    at[ACT_WALK_CROUCH_AIM] = ACT_HL2MP_WALK_CROUCH_AR2

    at[ACT_RUN] 			= ACT_HL2MP_RUN_PASSIVE
    at[ACT_RUN_AGITATED]    = ACT_HL2MP_RUN_AR2
    at[ACT_RUN_AIM] 		= ACT_HL2MP_RUN_AR2
    at[ACT_RUN_PROTECTED]   = ACT_HL2MP_RUN_PROTECTED
    at[ACT_RUN_CROUCH]      = ACT_HL2MP_WALK_CROUCH_PASSIVE
    at[ACT_RUN_CROUCH_AIM]  = ACT_HL2MP_WALK_CROUCH_AR2

    at[ACT_WALK]            = ACT_HL2MP_WALK_PASSIVE
    at[ACT_JUMP] 			= ACT_HL2MP_JUMP_AR2
    at[ACT_LAND]              = ACT_HL2MP_IDLE_PASSIVE

    at[ACT_IDLE]            = ACT_HL2MP_IDLE_PASSIVE
    at[ACT_IDLE_ANGRY]      = ACT_HL2MP_IDLE_AR2
    at[ACT_WALK_AGITATED] 	= ACT_HL2MP_WALK_AR2
	at[ACT_WALK_AIM] 		= ACT_HL2MP_WALK_AR2
    
    if wepHoldType == "ar2" then
        at[ACT_RANGE_ATTACK1]         = ACT_HL2MP_IDLE_AR2
        at[ACT_GESTURE_RANGE_ATTACK1] = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2
        at[ACT_RANGE_ATTACK1_LOW]     = ACT_HL2MP_IDLE_CROUCH_AR2
        at[ACT_RELOAD] 				  = "vjges_reload_ar2"
        at[ACT_RELOAD_LOW] 		   	  = "vjges_reload_ar2"
    end

    if wepHoldType == "pistol" then
        at[ACT_RANGE_ATTACK1] 				= ACT_HL2MP_IDLE_PISTOL
        at[ACT_GESTURE_RANGE_ATTACK1] 		= ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL
        at[ACT_RANGE_ATTACK1_LOW] 			= ACT_HL2MP_IDLE_CROUCH_PISTOL
    end
end

local RUN_ACTS = {
    [ACT_RUN] = true,
    [ACT_RUN_AIM] = true,
    [ACT_RUN_AIM_RIFLE] = true,
    [ACT_HL2MP_RUN_AR2] = true,
    [ACT_SIGNAL_GROUP] = true,
    [ACT_WALK_RIFLE] = true,
    [ACT_WALK_AIM_RIFLE] = true,
    [ACT_HL2MP_WALK_CROUCH_AR2] = true
}

function ENT:CallReinforcement()
    if not self.CanCallReinforce then return end
    self.CanCallReinforce = false

    local enemy = self:GetEnemy()
    if not IsValid(enemy) then return end

    local reinforcePos  = self:GetPos()
    local reinforceAng  = self:GetAngles()
    local dropshipClass = self.ReinforceDropship
    local smokeClass    = self.ReinforceSmokeEntity
    local throwBone     = self.ReinforceThrowBone
    local boneID = self:LookupBone(throwBone)
    if boneID and smokeClass then
        local bonePos, boneAng = self:GetBonePosition(boneID)
        if bonePos then
            local smoke = ents.Create(smokeClass)
            if IsValid(smoke) then
                smoke:SetPos(bonePos + self:GetForward() * 10)
                smoke:SetAngles(boneAng)
                smoke:Spawn()
                smoke:Activate()

                local phys = smoke:GetPhysicsObject()
                if IsValid(phys) then
                    phys:Wake()
                    phys:SetVelocity(self:GetForward() * 500 + Vector(0,0,100))
                end
            end
        end
    end

    timer.Simple(self.ReinforceDropshipTime, function()
        if not dropshipClass then return end
        local dropship = ents.Create(dropshipClass)
        if IsValid(dropship) then
            dropship.LandingSpot = reinforcePos
            dropship:SetPos(reinforcePos + Vector(0,0,5000))
            dropship:SetAngles(reinforceAng)
            dropship:Spawn()
            dropship:Activate()
        end
    end)

    timer.Simple(self.ReinforceCooldown, function()
        if IsValid(self) then
            self.CanCallReinforce = true
        end
    end)
end

local MARK_CHECK_INTERVAL = 2
local MARK_CHANCE         = 2
local ABILITY_COOLDOWN    = 5

function ENT:CustomOnInitialize()
    self.EnemyMemoryTime  = 30
    self.SoundTbl_GrenadeAttack = {"Grenade_Pull_01", "Grenade_Pull_02"}

    self.VJ_CurSpeedBoost = 0.7
    self.VJ_Investigating = false

    self.VJ_PistolLock       = false
    self.VJ_UsingPistol      = false
    self.VJ_SwitchingWeapon  = false
    self.VJ_MainWeaponAmmo   = 0

    self.ADVENT_NextMarkTime       = 0
    self.ADVENT_NextMarkCheckT     = 0
    self.ADVENT_MarkedEnemyCache   = NULL
    self.ADVENT_AbilityActive      = false
    self.ADVENT_AbilityCooldownEnd = 0
end

function ENT:ADVENT_TriggerAbility(animName, effectDelay, effectCallback)
    self.ADVENT_AbilityActive      = true
    self.ADVENT_AbilityCooldownEnd = CurTime() + ABILITY_COOLDOWN

    self:VJ_ACT_PLAYACTIVITY(animName, true, false, false)

    timer.Simple(effectDelay, function()
        if not IsValid(self) then return end
        effectCallback()
    end)

    timer.Simple(ABILITY_COOLDOWN, function()
        if IsValid(self) then
            self.ADVENT_AbilityActive = false
        end
    end)
end

local CLOSE_DIST = 750

function ENT:CustomOnThink()
    local enemy   = self:GetEnemy()
    local curTime = CurTime()
    local wep     = self:GetActiveWeapon()
    if IsValid(enemy)
    and not self.ADVENT_AbilityActive
    and curTime >= self.ADVENT_AbilityCooldownEnd
    and curTime >= self.ADVENT_NextMarkCheckT
    and self.EnemyData.Visible
    and not self.VJ_SwitchingWeapon then

        self.ADVENT_NextMarkCheckT = curTime + MARK_CHECK_INTERVAL

        local useReinforce = math.random(1, 2) == 1

        if useReinforce and self.CanCallReinforce then
            self:ADVENT_TriggerAbility(
                self.ReinforceAnim,
                self.ReinforceDelay,
                function()
                    self:CallReinforcement()
                end
            )

        elseif not useReinforce
        and curTime >= self.ADVENT_NextMarkTime
        and not (ADVENT_IsMarked and ADVENT_IsMarked(enemy)) then
            self:ADVENT_TriggerAbility(
                "mark_enemy_anim",
                0.8,
                function()
                    if IsValid(self) and IsValid(enemy)
                    and ADVENT_MarkTarget then
                        ADVENT_MarkTarget(self, enemy)
                    end
                end
            )
        end
    end

    if self.VJ_SwitchingWeapon then return end

    if not self.VJ_UsingPistol and IsValid(wep) and wep:GetClass() == "weapon_vj_magnrifle" then
        if wep:Clip1() > 15 then self.VJ_PistolLock = false end
    end

    if IsValid(enemy) and IsValid(wep)
    and not self.VJ_UsingPistol
    and not self.VJ_PistolLock then
        local dist = self:GetPos():Distance(enemy:GetPos())
        if dist <= 750 and wep:GetClass() == "weapon_vj_magnrifle" and wep:Clip1() <= 15 then
            self.VJ_SwitchingWeapon = true
            self.VJ_MainWeaponAmmo  = wep:Clip1()
            self.VJ_PistolLock      = true
            self.HasReloadAnimation  = false
            self.CanReload           = false
            self:SetPlaybackRate(1.9)
            self:VJ_ACT_PLAYACTIVITY("smgdraw", true, false, false)
            timer.Simple(0.25, function()
                if not IsValid(self) then return end
                local curWep = self:GetActiveWeapon()
                if IsValid(curWep) then curWep:Remove() end
                self:Give("weapon_vj_magnpistol")
                self.VJ_UsingPistol = true
                self:SetPlaybackRate(1)
            end)
            timer.Simple(0.35, function()
                if IsValid(self) then self.VJ_SwitchingWeapon = false end
            end)
            return
        end
    end

    if self.VJ_UsingPistol and IsValid(wep) and wep:GetClass() == "weapon_vj_magnpistol" and wep:Clip1() <= 0 then
        self.VJ_SwitchingWeapon = true
        self:SetPlaybackRate(1.9)
        self:VJ_ACT_PLAYACTIVITY("smgdraw", true, false, false)
        timer.Simple(0.25, function()
            if not IsValid(self) then return end
            local curWep = self:GetActiveWeapon()
            if IsValid(curWep) then curWep:Remove() end
            self:Give("weapon_vj_magnrifle")
            local newWep = self:GetActiveWeapon()
            if IsValid(newWep) then newWep:SetClip1(self.VJ_MainWeaponAmmo or 0) end
            self.VJ_UsingPistol     = false
            self.CanReload          = true
            self.HasReloadAnimation = true
            self:SetPlaybackRate(1)
        end)
        timer.Simple(0.35, function()
            if IsValid(self) then self.VJ_SwitchingWeapon = false end
        end)
        return
    end

    if self.VJ_UsingPistol and not self.VJ_SwitchingWeapon and (not IsValid(enemy) or enemy:Health() <= 0) then
        self.VJ_SwitchingWeapon = true
        self:SetPlaybackRate(1.9)
        self:VJ_ACT_PLAYACTIVITY("smgdraw", true, false, false)
        timer.Simple(0.25, function()
            if not IsValid(self) then return end
            local curWep = self:GetActiveWeapon()
            if IsValid(curWep) then curWep:Remove() end
            self:Give("weapon_vj_magnrifle")
            local newWep = self:GetActiveWeapon()
            if IsValid(newWep) then newWep:SetClip1(self.VJ_MainWeaponAmmo or 0) end
            self.VJ_UsingPistol     = false
            self.Weapon_MaxDistance = 1000
            self.CanReload          = true
            self.HasReloadAnimation = true
            self:SetPlaybackRate(1)
        end)
        timer.Simple(0.35, function()
            if IsValid(self) then self.VJ_SwitchingWeapon = false end
        end)
        return
    end

    local RUN_ACTS = {
        [ACT_RUN]                   = true,
        [ACT_RUN_AIM]               = true,
        [ACT_RUN_AIM_RIFLE]         = true,
        [ACT_HL2MP_RUN_AR2]         = true,
        [ACT_SIGNAL_GROUP]          = true,
        [ACT_WALK_RIFLE]            = true,
        [ACT_WALK_AIM_RIFLE]        = true,
        [ACT_HL2MP_WALK_CROUCH_AR2] = true
    }

    if self:IsMoving() and RUN_ACTS[self:GetActivity()] then
        self.VJ_CurSpeedBoost = math.Approach(self.VJ_CurSpeedBoost, 1.2, 0.05)
        self:SetPlaybackRate(self.VJ_CurSpeedBoost)
        self:SetLocalVelocity(self:GetMoveVelocity() * self.VJ_CurSpeedBoost)
        return
    end

    self.VJ_CurSpeedBoost = 1
    self:SetPlaybackRate(1)
end