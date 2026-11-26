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
ENT.RadiusDamageType = bit.bor(DMG_SLASH,DMG_BLAST,DMG_GENERIC) -- Damage type
ENT.RadiusDamageForce = false -- Put the force amount it should apply | false = Don't apply any force
ENT.RadiusDamageForce_Up = false -- How much up force should it have? | false = Let the base automatically decide the force using RadiusDamageForce value
ENT.RadiusDamageDisableVisibilityCheck = false -- Should it disable the visibility check? | true = Disables the visibility check
ENT.DoesDirectDamage = true -- Should it do a direct damage when it hits something?
ENT.DirectDamage = 80 -- How much damage should it do when it hits something
ENT.DirectDamageType = bit.bor(DMG_SLASH,DMG_BLAST,DMG_GENERIC) -- Damage type
ENT.SoundTbl_Startup = {}
ENT.SoundTbl_Idle = {}
ENT.SoundTbl_OnCollide = {"generic/bl3boom.mp3"}
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomPhysicsObjectOnInitialize(phys)
	phys:Wake()
	phys:EnableDrag(false)
	phys:SetBuoyancyRatio(0)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnInitialize()
	self:SetNoDraw(true)
	ParticleEffectAttach("krakenmissile", PATTACH_ABSORIGIN_FOLLOW, self, 0)
	
timer.Simple(1,function() if self:IsValid() then 
self:SetMoveType( MOVETYPE_NONE )	
timer.Simple(0.1,function() if self:IsValid() then 
if IsValid(self) && IsValid(self.Owner) && IsValid(self.Owner:GetEnemy()) then
local rangeprojectile12 = ents.Create("obj_vj_krakenmissiletrue") 
	rangeprojectile12:SetPos(self:GetPos())
		rangeprojectile12:SetAngles(Angle(0, 100, 0))
		rangeprojectile12:Spawn()
		rangeprojectile12:Activate() 
		rangeprojectile12:SetOwner(self.Owner) 
		rangeprojectile12:SetPhysicsAttacker(self.Owner)
		rangeprojectile12:GetPhysicsObject():Wake()
		rangeprojectile12:GetPhysicsObject():SetVelocity(self:RangeAttackCode_GetShootPos(projectile))
		end	
timer.Simple(0.1,function() if self:IsValid() then 
self:Remove()
end end)
end end)
end end)
end 


	

function ENT:RangeAttackCode_GetShootPos(projectile)
return self:CalculateProjectile("Line", self:GetPos(), self.Owner:GetEnemy():GetPos() + self.Owner:GetEnemy():OBBCenter(), 350) + self:GetUp()*math.Rand(100,-200) + self:GetRight()*math.Rand(400,-400)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:DeathEffects(data,phys)
end
/*-----------------------------------------------
	*** Copyright (c) 2012-2020 by Mayhem, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
-----------------------------------------------*/