AddCSLuaFile("shared.lua")
include("shared.lua")
/*-----------------------------------------------
	*** Copyright (c) 2012-2017 by DrVrej, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
-----------------------------------------------*/

	-- General ---------------------------------------------------------------------------------------------------------------------------------------------
ENT.Model = {"models/spitball_small.mdl"} -- The models it should spawn with | Picks a random one from the table
ENT.PhysicsInitType = SOLID_VPHYSICS
ENT.MoveType = MOVETYPE_VPHYSICS -- Move type, recommended to keep it as it is
ENT.MoveCollideType = MOVECOLLIDE_DEFAULT -- Move type | Some examples: MOVECOLLIDE_FLY_BOUNCE, MOVECOLLIDE_FLY_SLIDE
ENT.CollisionGroupType = COLLISION_GROUP_PROJECTILE -- Collision type, recommended to keep it as it is
ENT.SolidType = SOLID_CUSTOM -- Solid type, recommended to keep it as it is
ENT.ShouldSetOwner = true -- Should it set a owner?
ENT.RemoveOnHit = true -- Should it remove itself when it touches something? | It will run the hit sound, place a decal, etc.
ENT.PaintDecalOnCollide = false -- Should it paint decals when it collides with something? | Use this only when using a projectile that doesn't get removed when it collides with something
ENT.DecalTbl_OnCollideDecals = {} -- Decals that paint when the projectile collides with something | It picks a random one from this table
ENT.CollideCodeWithoutRemoving = false -- If RemoveOnHit is set to false, you can still make the projectile deal damage, place a decal, etc.
ENT.NextCollideCodeWithoutRemovingTime1 = 1 -- Time until it can run the code again | First number in math.random
ENT.NextCollideCodeWithoutRemovingTime2 = 1 -- Time until it can run the code again | Second number in math.random
ENT.ShakeWorldOnDeath = false -- Should the world shake when the projectile hits something?
ENT.ShakeWorldOnDeathAmplitude = 16 -- How much the screen will shake | From 1 to 16, 1 = really low 16 = really high
ENT.ShakeWorldOnDeathRadius = 6000 -- How far the screen shake goes, in world units
ENT.ShakeWorldOnDeathtDuration = 1.5 -- How long the screen shake will last, in seconds
ENT.ShakeWorldOnDeathFrequency = 200 -- The frequency
ENT.DoesRadiusDamage = false -- Should it do a blast damage when it hits something?
ENT.RadiusDamageRadius = 100 -- How far the damage go? The farther away it's from its enemy, the less damage it will do | Counted in world units
ENT.RadiusDamageUseRealisticRadius = false -- Should the damage decrease the farther away the enemy is from the position that the projectile hit?
ENT.RadiusDamage = 5 -- How much damage should it deal? Remember this is a radius damage, therefore it will do less damage the farther away the entity is from its enemy
ENT.RadiusDamageType = bit.bor(DMG_SLASH,DMG_SHOCK)  -- Damage type
ENT.RadiusDamageForce = false -- Put the force amount it should apply | false = Don't apply any force
ENT.RadiusDamageForce_Up = false -- How much up force should it have? | false = Let the base automatically decide the force using RadiusDamageForce value
ENT.RadiusDamageDisableVisibilityCheck = false -- Should it disable the visibility check? | true = Disables the visibility check
ENT.DoesDirectDamage = true -- Should it do a direct damage when it hits something?
ENT.DirectDamage = 8 -- How much damage should it do when it hits something
ENT.DirectDamageType = bit.bor(DMG_SLASH,DMG_SHOCK) -- Damage type
ENT.PaintDecalOnDeath = false -- Should it paint a decal when it hits something?
ENT.DecalTbl_DeathDecals = {} -- Decals that paint when the projectile dies | It picks a random one from this table

ENT.SoundTbl_Idle = {""}
ENT.SoundTbl_Startup = {""}
ENT.SoundTbl_OnCollide = {""}

function ENT:CustomPhysicsObjectOnInitialize(phys)
	phys:Wake()
	phys:EnableDrag(true)
        phys:EnableGravity(true)
	phys:SetBuoyancyRatio(0)
end
------------------------------------------------------------------------------------------
function ENT:CustomOnInitialize()
               self:SetModelScale(1)
               self:SetNoDraw(true)
			   self:SetAngles( self:GetAngles() + Angle(0,90,90) )
               ParticleEffectAttach("maliwanprojectileshocksecondary", PATTACH_ABSORIGIN_FOLLOW, self, 0)
	end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:DeathEffects(data,phys)
 
end
/*-----------------------------------------------
	*** Copyright (c) 2012-2017 by DrVrej, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
-----------------------------------------------*/