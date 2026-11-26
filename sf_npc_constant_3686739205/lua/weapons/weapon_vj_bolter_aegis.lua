if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end

SWEP.Base 						= "weapon_vj_base"
SWEP.PrintName					= "Magnetic Cannon"
SWEP.Author 					= "Nikolai"
SWEP.Contact					= "http://steamcommunity.com/groups/vrejgaming"
SWEP.Purpose					= "This weapon is made for NPCs"

-- Main Settings ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.MadeForNPCsOnly 			= true
SWEP.WorldModel					= "models/gfl2_surtr_weapon1.mdl"
SWEP.HoldType 					= "crossbow"
SWEP.Spawnable					= false
SWEP.AdminSpawnable				= false

-- NPC Settings ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.NPC_HasReloadSound 		= true
SWEP.NPC_ReloadSound 			= {"MagnetCanReload"}
SWEP.Primary.ClipSize 			= 200
SWEP.NPC_FiringDistanceScale 	= 2
-- World Model ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.WorldModel_UseCustomPosition = true
SWEP.WorldModel_CustomPositionAngle = Vector(0,100,180)
SWEP.WorldModel_CustomPositionOrigin = Vector(-7, -3, 7)
SWEP.WorldModel_CustomPositionBone = "ValveBiped.Bip01_R_Hand"

-- Primary Fire ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.Primary.Damage				= 50
SWEP.Primary.PlayerDamage 		= "Double"
SWEP.Primary.Force				= 8
SWEP.Primary.Tracer				= 1
SWEP.Primary.TracerType			= "magnetic_cannon_tracer"
SWEP.Primary.Automatic			= true
SWEP.Primary.Ammo				= "ar2"
SWEP.Primary.Sound				= {"CMF1","CMF2","CMF3"}
SWEP.PrimaryEffects_MuzzleFlash = true
SWEP.PrimaryEffects_MuzzleParticles = {"magnet_muzzleflash"}
SWEP.PrimaryEffects_MuzzleAttachment = "1"
SWEP.PrimaryEffects_SpawnShells = false
SWEP.PrimaryEffects_DynamicLightColor = Color(255, 0, 0)

SWEP.AllowedToChangeFireOnDist = true
function SWEP:CustomOnThink()
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsNPC() then return end

    local enemy = owner:GetEnemy()
    
    -- 1. Определяем нужные параметры
    local nextFire = 0.1
    local spread = 0.001
    local automatic = true
    local timeUntil = 0.1

    if owner.IsSuppressing then
        -- Параметры подавления
        nextFire = 0.06
        spread = 0.8
        automatic = true
        timeUntil = 0

        if (self.NextSuppressFireT or 0) < CurTime() then
            self:NPCShoot_Primary()
            self.NextSuppressFireT = CurTime() + nextFire
        end
    elseif IsValid(enemy) then
        -- Обычная логика дистанции
        local dist = owner:GetPos():Distance(enemy:GetPos())
        if dist > 3250 then
            automatic = true
            timeUntil = 0.15
            nextFire = math.Rand(0.08, 0.35)
            spread = 0.2
        elseif dist > 1500 then
            automatic = true
            timeUntil = 0.15 
            nextFire = math.Rand(0.08, 0.18)
            spread = 0.3
        else
            automatic = true
            timeUntil = 0.15
            nextFire = 0.06
            spread = 0.9
        end
    end

    self.Primary.Automatic = automatic
    self.NPC_NextPrimaryFire = nextFire
    self.NPC_CustomSpread = spread
    self.NPC_TimeUntilFire = timeUntil
end

function SWEP:CustomOnPrimaryAttack_AfterShoot()
    if not IsValid(self) then return end

    local seq = self:LookupSequence("rotor")
    if seq == -1 then return end

    self:ResetSequence(seq)
    self:SetPlaybackRate(1)
end

function SWEP:OnReload(status)

	if status == "Start" then
		self:SetBodygroup(1, 1)	
	end
	if status == "Finish" then
		self:SetBodygroup(1, 0)
	end
end