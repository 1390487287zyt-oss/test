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
SWEP.Primary.Damage				= 40                   
SWEP.Primary.PlayerDamage 		= "Double"
SWEP.Primary.Force				= 6
SWEP.Primary.Tracer				= 1
SWEP.Primary.TracerType			= "magnetic_rifle_tracer"
SWEP.Primary.Automatic			= true                   -- Включён автоматический режим для высокой скорострельности
SWEP.Primary.Delay              = 0.1                    -- Задержка между выстрелами (для игрока, но оружие только для NPC — оставлено для совместимости)
SWEP.Primary.Ammo				= "ar2"
SWEP.Primary.Sound				= {"MF1","MF2","MF3"}
SWEP.PrimaryEffects_MuzzleFlash = true
SWEP.PrimaryEffects_MuzzleParticles = {"magnet_muzzleflash"}
SWEP.PrimaryEffects_MuzzleAttachment = "1"
SWEP.PrimaryEffects_SpawnShells = false
SWEP.PrimaryEffects_DynamicLightColor = Color(255, 0, 0)

-- Параметры для NPC (автоматический огонь с высоким темпом и большим разбросом)
SWEP.NPC_NextPrimaryFire        = 0.4                   -- Интервал между выстрелами (было 0.4) – теперь стрельба очень быстрая
SWEP.NPC_CustomSpread           = 0.8                    -- Большой разброс (было 0.2)
SWEP.NPC_TimeUntilFire          = 0.1                    -- Быстрый старт стрельбы

-- Анимация перезарядки (смена bodygroup)
function SWEP:OnReload(status)
	if status == "Start" then
		self:SetBodygroup(1, 1)	
	end
	if status == "Finish" then
		self:SetBodygroup(1, 0)
	end
end