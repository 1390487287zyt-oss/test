AddCSLuaFile("shared.lua")
include("shared.lua")
/*-----------------------------------------------
	*** Copyright (c) 2012-2020 by Mayhem, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
-----------------------------------------------*/
ENT.Model = {"models/spitball_medium.mdl"} -- The models it should spawn with | Picks a random one from the table
ENT.ShakeWorldOnDeath = false -- Should the world shake when the projectile hits something?
ENT.ShakeWorldOnDeathAmplitude = 16 -- How much the screen will shake | From 1 to 16, 1 = really low 16 = really high
ENT.ShakeWorldOnDeathRadius = 6000 -- How far the screen shake goes, in world units
ENT.ShakeWorldOnDeathtDuration = 1.5 -- How long the screen shake will last, in seconds
ENT.ShakeWorldOnDeathFrequency = 200 -- The frequency
ENT.DoesRadiusDamage = true -- Should it do a blast damage when it hits something?
ENT.RadiusDamageRadius = 250 -- How far the damage go? The farther away it's from its enemy, the less damage it will do | Counted in world units
ENT.RadiusDamageUseRealisticRadius = true -- Should the damage decrease the farther away the enemy is from the position that the projectile hit?
ENT.RadiusDamage = 65 -- How much damage should it deal? Remember this is a radius damage, therefore it will do less damage the farther away the entity is from its enemy
ENT.RadiusDamageType = bit.bor(DMG_SLASH,DMG_GENERIC) -- Damage type
ENT.RadiusDamageForce = false -- Put the force amount it should apply | false = Don't apply any force
ENT.RadiusDamageForce_Up = false -- How much up force should it have? | false = Let the base automatically decide the force using RadiusDamageForce value
ENT.RadiusDamageDisableVisibilityCheck = false -- Should it disable the visibility check? | true = Disables the visibility check
ENT.DoesDirectDamage = true -- Should it do a direct damage when it hits something?
ENT.DirectDamage = 80 -- How much damage should it do when it hits something
ENT.DirectDamageType = bit.bor(DMG_SLASH,DMG_GENERIC) -- Damage type
ENT.SoundTbl_Startup = {}
ENT.SoundTbl_Idle = {}
ENT.SoundTbl_OnCollide = {"generic/bl3boom.mp3"}
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomPhysicsObjectOnInitialize(phys)
	phys:Wake()
	phys:EnableGravity(false)
	phys:EnableDrag(false)
	phys:SetBuoyancyRatio(0)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnInitialize()
	self:SetNoDraw(true)
	ParticleEffectAttach("krakenmissile", PATTACH_ABSORIGIN_FOLLOW, self, 0)
end 


	


---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:DeathEffects(data,phys)
	ParticleEffect("krakenmissileimpact", data.HitPos, Angle(0,0,0), nil)
end
/*-----------------------------------------------
	*** Copyright (c) 2012-2020 by Mayhem, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
-----------------------------------------------*/