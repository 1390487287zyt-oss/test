AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model                   = {"models/yo_ponika/sf_mdl/sf_jaeger_swap.mdl"}
ENT.StartHealth             = 300
ENT.TurningSpeed            = 50
ENT.DropWeaponOnDeath       = true
ENT.VJ_NPC_Class            = {"CLASS_SANGVIS"}
ENT.BloodColor              = "Black"
ENT.UsePlayerModelMovement  = true
ENT.DisableWandering        = true
ENT.Weapon_Strafe           = false
ENT.Weapon_CanMoveFire      = false
ENT.DisableChasingEnemy     = true
ENT.CanThrowBackDetectedGrenades = true

ENT.Weapon_MaxDistance                = 5000
ENT.WeaponSpread                      = 1
ENT.ConstantlyFaceEnemy_IfAttacking   = true
ENT.Weapon_RetreatDistance            = 800
ENT.Weapon_FindCoverOnReload          = false
ENT.AnimTbl_WeaponAttack              = ACT_RANGE_ATTACK1
ENT.AnimTbl_WeaponAttackGesture       = ACT_GESTURE_RANGE_ATTACK1

ENT.DisableWOSAnimations = true

ENT.HasMeleeAttack           = true
ENT.MeleeAttackDamage        = 30
ENT.MeleeAttackDamageType    = DMG_CLUB
ENT.AnimTbl_MeleeAttack      = {"melee_gunhit","melee_gunhit1","melee_gunhit2"}
ENT.CanCrouchOnWeaponAttack  = true

ENT.HasGrenadeAttack         = false
ENT.StartWeapon              = {"weapon_vj_magnamr"}

ENT.SightDistance                 = 5000
ENT.SightAngle                    = 300
ENT.EnemyTimeout                  = 60
ENT.CanInvestigate                = false
ENT.InvestigateSoundMultiplier    = 100
ENT.CanDetectDangers              = true
ENT.DangerDetectionDistance       = 200
ENT.AnimTbl_TakingCover           = ACT_COVER_LOW
ENT.AnimTbl_MoveToCover           = ACT_RUN_CROUCH
ENT.CanReceiveOrders              = false
ENT.CallForHelp                   = false
ENT.JumpParams = {
    Enabled     = true,
    MaxRise     = 500,
    MaxDrop     = 700,
    MaxDistance = 600,
}

ENT.CanFlinch = false

ENT.FootStepTimeRun  = 0
ENT.FootStepTimeWalk = 0
ENT.SoundTbl_FootStep     = {}
ENT.SoundTbl_Alert        = {}
ENT.SoundTbl_Death        = {"adv_die1", "adv_die2", "adv_die3", "adv_die4"}
ENT.SoundTbl_Pain         = {}
ENT.SoundTbl_AllyDeath    = {}
ENT.SoundTbl_Grenade      = {}
ENT.SoundTbl_ThrowGrenade = {}
ENT.SoundTbl_KillEnemy    = {}
ENT.SoundTbl_Reload       = {}
ENT.SoundTbl_Suppressing  = {}

function ENT:SetAnimationTranslations(wepHoldType)
    local at = self.AnimationTranslations
    at[ACT_WALK_CROUCH]       = ACT_HL2MP_WALK_CROUCH_PASSIVE
    at[ACT_WALK_CROUCH_AIM]   = ACT_HL2MP_WALK_CROUCH_AR2
    at[ACT_RUN]               = ACT_HL2MP_RUN_PASSIVE
    at[ACT_RUN_AGITATED]      = ACT_HL2MP_RUN_AR2
    at[ACT_RUN_AIM]           = ACT_HL2MP_RUN_AR2
    at[ACT_RUN_PROTECTED]     = ACT_HL2MP_RUN_PROTECTED
    at[ACT_RUN_CROUCH]        = ACT_HL2MP_WALK_CROUCH_PASSIVE
    at[ACT_RUN_CROUCH_AIM]    = ACT_HL2MP_WALK_CROUCH_AR2
    at[ACT_WALK]              = ACT_HL2MP_WALK_PASSIVE
    at[ACT_JUMP]              = ACT_HL2MP_JUMP_AR2
    at[ACT_IDLE]              = ACT_HL2MP_IDLE_PASSIVE
    at[ACT_IDLE_ANGRY]        = ACT_HL2MP_IDLE_AR2
    at[ACT_WALK_AGITATED]     = ACT_HL2MP_WALK_AR2
    at[ACT_WALK_AIM]          = ACT_HL2MP_WALK_AR2
    at[ACT_LAND]              = ACT_HL2MP_IDLE_PASSIVE
    if wepHoldType == "ar2" then
        at[ACT_RANGE_ATTACK1]         = ACT_HL2MP_IDLE_AR2
        at[ACT_GESTURE_RANGE_ATTACK1] = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2
        at[ACT_RANGE_ATTACK1_LOW]     = ACT_HL2MP_IDLE_CROUCH_AR2
        at[ACT_RELOAD]                = "vjges_reload_ar2"
        at[ACT_RELOAD_LOW]            = "vjges_reload_ar2"
    end
end

local RUN_ACTS = {
    [ACT_RUN]=true, [ACT_RUN_AIM]=true, [ACT_RUN_AIM_RIFLE]=true,
    [ACT_HL2MP_RUN_AR2]=true, [ACT_SIGNAL_GROUP]=true,
    [ACT_WALK_RIFLE]=true, [ACT_WALK_AIM_RIFLE]=true,
    [ACT_HL2MP_WALK_CROUCH_AR2]=true
}

function ENT:CustomOnInitialize()
    if self.StartWeapon and #self.StartWeapon > 0 then
        local wep = self.StartWeapon[math.random(#self.StartWeapon)]
        self:Give(wep)
        self.PrimaryWeapon = wep
    elseif self.MeleeWeapon then
        self:Give(self.MeleeWeapon)
    end

    self.EnemyMemoryTime        = 60
    self.SoundTbl_GrenadeAttack = {"Grenade_Pull_01", "Grenade_Pull_02"}
    self.VJ_CurSpeedBoost       = 1
    self.VJ_Investigating       = false
end

function ENT:GetActiveVJWeapon() return self:GetActiveWeapon() end

function ENT:CustomOnThink()
    local enemy = self:GetEnemy()
    local curTime = CurTime()

    if IsValid(enemy) then
        self.LastInCombatTime = curTime
    end

    -- Новый камуфляж: predator при наличии врага, обычный вид без врага
    local wepEnt = self:GetActiveWeapon()
    if IsValid(enemy) then
        self:SetMaterial("models/shadertest/predator")
        if IsValid(wepEnt) then
            wepEnt:SetMaterial("models/shadertest/predator")
        end
    else
        self:SetMaterial("")
        if IsValid(wepEnt) then
            wepEnt:SetMaterial("")
        end
    end

    -- Ускорение при беге
    if self:IsMoving() and RUN_ACTS[self:GetActivity()] then
        self.VJ_CurSpeedBoost = math.Approach(self.VJ_CurSpeedBoost, 1.2, 0.05)
        self:SetPlaybackRate(self.VJ_CurSpeedBoost)
        self:SetLocalVelocity(self:GetMoveVelocity() * self.VJ_CurSpeedBoost)
        return
    end
    self:SetPlaybackRate(1)
end