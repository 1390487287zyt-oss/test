if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end
---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.Base 						= "weapon_vj_base"
SWEP.Spawnable					= false
	-- Main Settings ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.WorldModel 				= "models/weapons/w_m32.mdl"
SWEP.UseHands					= true
SWEP.HoldType 					= "crossbow"
SWEP.MadeForNPCsOnly 			= true -- Is tihs weapon meant to be for NPCs only?
	-- NPC Settings ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.NPC_NextPrimaryFire 		= 1.5 -- Next time it can use primary fire
-- World Model ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.WorldModel_UseCustomPosition = true
SWEP.WorldModel_CustomPositionAngle = Vector(-8,90,180)
SWEP.WorldModel_CustomPositionOrigin = Vector(-4, -1, 1)
SWEP.WorldModel_CustomPositionBone = "ValveBiped.Bip01_R_Hand"
	-- Primary Fire ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.Primary.DisableBulletCode 	= true
SWEP.Primary.ClipSize 			= 8 -- Max amount of bullets per clip
SWEP.Primary.Delay 				= 0.5
SWEP.Primary.Ammo 				= "RPG_Round" -- Ammo type
SWEP.Primary.Automatic 			= true -- Is it automatic?
SWEP.Primary.Sound				= {"ADV_GL_FireClose"}
SWEP.PrimaryEffects_SpawnShells = false
SWEP.PrimaryEffects_MuzzleAttachment = "1"
SWEP.PrimaryEffects_MuzzleParticles = {"vj_rifle_full"}
SWEP.PrimaryEffects_SpawnDynamicLight = true
SWEP.PrimaryEffects_DynamicLightColor = Color(255, 150, 60)
	-- Reload Settings ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.HasReloadSound 			= true -- Does it have a reload sound? Remember even if this is set to false, the animation sound will still play!
SWEP.ReloadSound 				= {"ADV_GL_Reload"}
SWEP.NPC_ExtraFireSound = {"ADV_GL_Drum1","ADV_GL_Drum2"}
SWEP.NPC_ExtraFireSoundTime = 0.4
	-- Idle Settings ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.ProjectileForce = 30000

SWEP.ProjectileEntClass = "obj_vj_adv_40mm_he_grenade"

function SWEP:OnProjectilePreSpawn(ent)
end

function SWEP:OnProjectileSpawn(ent)
end

function SWEP:OnPrimaryAttack(status, statusData)
    if status == "Init" then
        if CLIENT then return end
        local owner = self:GetOwner()
        local projectile = ents.Create(self.ProjectileEntClass)
        local spawnPos = self:GetBulletPos()

        if IsValid(projectile) then
            projectile:SetPos(spawnPos)

            self:OnProjectilePreSpawn(projectile)

            projectile:SetAngles(self:GetAngles())
            projectile:SetOwner(owner)
            projectile:Activate()
            projectile:Spawn()

            self:OnProjectileSpawn(projectile)

            local phys = projectile:GetPhysicsObject()
            if IsValid(phys) then
                local enemy = owner:GetEnemy()
                local upMult = 1

                if IsValid(enemy) and owner:GetPos():Distance(enemy:GetPos()) > 3600 then
                    upMult = 2
                end

                local vel = VJ.CalculateTrajectory(owner, enemy, "Line", spawnPos, 1, self.ProjectileForce)
                vel = vel + Vector(0, 0, upMult * 1000)
                local spread = 100
                vel = vel + Vector(
                    math.Rand(-spread, spread),
                    math.Rand(-spread, spread),
                    math.Rand(-spread * 0.06, spread * 0.06)
                )

                phys:SetVelocity(vel)
                projectile:SetAngles(projectile:GetVelocity():GetNormal():Angle())
            end
        end
    end
end

function SWEP:OnReload(status)

	if status == "Start" then
		self:SetBodygroup(1, 1)	
	end
	if status == "Finish" then
		self:SetBodygroup(1, 0)
	end
end