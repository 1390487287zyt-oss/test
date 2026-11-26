if !file.Exists("autorun/vj_base_autorun.lua","LUA") then return end

SWEP.Base 						= "weapon_vj_base"
SWEP.PrintName					= "Magnetic Rifle"
SWEP.Author 					= "Nikolai"
-- Main Settings ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.MadeForNPCsOnly 			= true
SWEP.WorldModel					= "models/dih/gf/vespid_rifle.mdl"
SWEP.HoldType 					= "ar2"
SWEP.Spawnable					= false
SWEP.AdminSpawnable				= false

-- NPC Settings ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.NPC_HasReloadSound 		= true
SWEP.NPC_ReloadSound 			= {"MagnetReload"}
SWEP.Primary.ClipSize 			= 100
SWEP.NPC_FiringDistanceScale 	= 1.5
-- World Model ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.WorldModel_UseCustomPosition = true
SWEP.WorldModel_CustomPositionAngle = Vector(-10,90,180)
SWEP.WorldModel_CustomPositionOrigin = Vector(-5.2, -1, 1)
SWEP.WorldModel_CustomPositionBone = "ValveBiped.Bip01_R_Hand"

-- Primary Fire ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.Primary.Damage				= 80
SWEP.Primary.PlayerDamage 		= "Double"
SWEP.Primary.Force				= 6
SWEP.Primary.Tracer				= 1
SWEP.Primary.TracerType			= "magnetic_rifle_tracer"
SWEP.Primary.Automatic			= false                 -- отключаем автоогонь (используем burst)
SWEP.Primary.Ammo				= "ar2"
SWEP.Primary.Sound				= {"MF1","MF2","MF3"}
SWEP.PrimaryEffects_MuzzleFlash = true
SWEP.PrimaryEffects_MuzzleParticles = {"magnet_muzzleflash"}
SWEP.PrimaryEffects_MuzzleAttachment = "1"
SWEP.PrimaryEffects_SpawnShells = false
SWEP.PrimaryEffects_DynamicLightColor = Color(255, 0, 0)

-- Burst fire settings (очереди по 3 выстрела)
SWEP.Primary.BurstLength        = 3
SWEP.Primary.BurstDelay         = 1.5     -- большая задержка между очередями → низкая скорострельность

-- Параметры для NPC (фиксированные, низкая скорострельность)
SWEP.NPC_NextPrimaryFire        = 0.4     -- интервал между выстрелами внутри очереди
SWEP.NPC_CustomSpread           = 0.2     -- небольшой разброс для точности
SWEP.NPC_TimeUntilFire          = 0.3     -- задержка перед первым выстрелом

-- (Опционально) если вы хотите, чтобы оружие адаптировалось под дистанцию, но оставалось медленным,
-- раскомментируйте функцию ниже и настройте значения.
--[[
function SWEP:CustomOnThink()
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsNPC() then return end

    local enemy = owner:GetEnemy()
    
    -- Базовые медленные значения
    local nextFire = 0.3
    local burstDelay = 1.2
    local spread = 0.1
    local timeUntil = 0.3

    if IsValid(enemy) then
        local dist = owner:GetPos():Distance(enemy:GetPos())

        if dist > 3250 then
            nextFire = 0.4
            burstDelay = 2.0
            spread = 0.1
            timeUntil = 0.4
        elseif dist > 1000 then
            nextFire = 0.35
            burstDelay = 1.5
            spread = 0.3
            timeUntil = 0.35
        else
            nextFire = 0.3
            burstDelay = 1.2
            spread = 0.7
            timeUntil = 0.3
        end
    end

    self.Primary.BurstDelay = burstDelay
    self.NPC_NextPrimaryFire = nextFire
    self.NPC_CustomSpread = spread
    self.NPC_TimeUntilFire = timeUntil
end
--]]

-- Анимация перезарядки (смена bodygroup)
function SWEP:OnReload(status)
	if status == "Start" then
		self:SetBodygroup(1, 1)	
	end
	if status == "Finish" then
		self:SetBodygroup(1, 0)
	end
end