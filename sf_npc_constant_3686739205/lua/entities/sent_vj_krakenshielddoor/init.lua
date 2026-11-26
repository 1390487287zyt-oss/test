if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end
AddCSLuaFile("shared.lua")
include("shared.lua")
/*--------------------------------------------------
	=============== riotshield ===============
--------------------------------------------------*/
ENT.VJ_AddEntityToSNPCAttackList = true
ENT.Model = {"models/metros/borderlands3/maliwan/krakenshield2.mdl"}
ENT.StartHealth = 10


ENT.Spawnable = true
ENT.AdminOnly = false
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:Initialize()
	if self:GetModel() == "models/error.mdl" then
	self:SetModel(Model(VJ_PICKRANDOMTABLE(self.Model))) end
	self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )	
	self:SetUseType(SIMPLE_USE)
	self:SetHealth(self.StartHealth)
	self:SetModelScale( self:GetModelScale() * 1.0, 0 )
	local phys = self:GetPhysicsObject()
	if phys and phys:IsValid() then
		phys:Wake()
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:PhysicsCollide(data, physobj)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:Think()
	timer.Simple(0,function()  if IsValid(self) then 
	self:SetAngles(self:GetAngles()+Angle(0,2,0)) -- quick simple spin
end end)	
for p, deflectableprojectile in pairs(ents.FindByClass( "obj_*" )) do
		if IsValid(deflectableprojectile.Owner) && deflectableprojectile:GetOwner() != self then
				if deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperassault" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_wotantheinvincible" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_wotantheinvincibleraidboss" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_arbalest" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadasscontaminator" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_badassfrontrunner" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadassicebreaker" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogbadass" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadasspowerhouse" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadasspyrotech" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperbadass" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperbreach" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_captaintraunt" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_troopercloak" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavycontaminator" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_deathsphere" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_defender" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_dropshipturret" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperflash" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_frontrunner" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_generaltraunt" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_noggigamind" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_gunwolf" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_harbinger" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_hoplite" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavyicebreaker" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperjet" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_katagawaball" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_katagawajr" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_kraken" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_troopermed" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogninja" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nog" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogromancer" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nullhound" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_oversphere" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavypowerhouse" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavypyrotech" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_reaper" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperreflect" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperriot" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_stinger" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_thor" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_valkyrie" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogdronesupport2" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogdronesupport1" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_captaintrauntmobileballfire" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_captaintrauntmobileballcorrosive"   then ---DO NOT DEFLECT PROJECTILES OF ALLIES!
			--	--PrintMessage(HUD_PRINTTALK,"Friendly Projectile")
				else --- LAUNCH THAT LITTLE SHIT!
						
		
							if self:GetPos():Distance(deflectableprojectile:GetPos()) < 200 then ----- check deflectableprojectile distance to shield, so we do not become the parry god with unlimited range
----PrintMessage(HUD_PRINTTALK,"ded projectile")
									deflectableprojectile:Remove() --- to add insult to the original owner of the projectile when he dies. also prevents projectile to be deflected again as its now an allied one
								
								end 
									
									
							
						end							

				end
			

		end
		
								for p, deflectableprojectile in pairs(ents.FindByClass( "prop_combine_ball" )) do
		if IsValid(deflectableprojectile.Owner) && deflectableprojectile:GetOwner() != self then
				if deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperassault" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_wotantheinvincible" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_wotantheinvincibleraidboss" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_arbalest" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadasscontaminator" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_badassfrontrunner" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadassicebreaker" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogbadass" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadasspowerhouse" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadasspyrotech" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperbadass" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperbreach" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_captaintraunt" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_troopercloak" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavycontaminator" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_deathsphere" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_defender" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_dropshipturret" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperflash" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_frontrunner" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_generaltraunt" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_noggigamind" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_gunwolf" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_harbinger" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_hoplite" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavyicebreaker" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperjet" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_katagawaball" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_katagawajr" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_kraken" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_troopermed" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogninja" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nog" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogromancer" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nullhound" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_oversphere" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavypowerhouse" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavypyrotech" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_reaper" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperreflect" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperriot" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_stinger" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_thor" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_valkyrie" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogdronesupport2" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogdronesupport1" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_captaintrauntmobileballfire" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_captaintrauntmobileballcorrosive" then ---DO NOT DEFLECT PROJECTILES OF ALLIES!
			--	--PrintMessage(HUD_PRINTTALK,"Friendly Projectile")
				else --- LAUNCH THAT LITTLE SHIT!
						
		
							if self:GetPos():Distance(deflectableprojectile:GetPos()) < 200 then ----- check deflectableprojectile distance to shield, so we do not become the parry god with unlimited range
----PrintMessage(HUD_PRINTTALK,"ded projectile")
									deflectableprojectile:Fire( "Explode" ) -- lets explode it for extra visuals
									deflectableprojectile:Remove() --- to add insult to the original owner of the projectile when he dies. also prevents projectile to be deflected again as its now an allied one
								
								end 
									
									
							
						end							

				end
			

		end
		
				for p, deflectableprojectile in pairs(ents.FindByClass( "grenade_ar2" )) do
		if IsValid(deflectableprojectile.Owner) && deflectableprojectile:GetOwner() != self then
				if deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperassault" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_wotantheinvincible" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_wotantheinvincibleraidboss" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_arbalest" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadasscontaminator" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_badassfrontrunner" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadassicebreaker" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogbadass" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadasspowerhouse" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadasspyrotech" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperbadass" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperbreach" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_captaintraunt" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_troopercloak" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavycontaminator" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_deathsphere" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_defender" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_dropshipturret" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperflash" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_frontrunner" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_generaltraunt" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_noggigamind" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_gunwolf" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_harbinger" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_hoplite" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavyicebreaker" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperjet" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_katagawaball" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_katagawajr" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_kraken" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_troopermed" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogninja" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nog" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogromancer" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nullhound" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_oversphere" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavypowerhouse" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavypyrotech" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_reaper" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperreflect" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperriot" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_stinger" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_thor" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_valkyrie" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogdronesupport2" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogdronesupport1" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_captaintrauntmobileballfire" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_captaintrauntmobileballcorrosive" then ---DO NOT DEFLECT PROJECTILES OF ALLIES!
			--	--PrintMessage(HUD_PRINTTALK,"Friendly Projectile")
				else --- LAUNCH THAT LITTLE SHIT!
						
		
							if self:GetPos():Distance(deflectableprojectile:GetPos()) < 200 then ----- check deflectableprojectile distance to shield, so we do not become the parry god with unlimited range
----PrintMessage(HUD_PRINTTALK,"ded projectile")
									deflectableprojectile:Remove() --- to add insult to the original owner of the projectile when he dies. also prevents projectile to be deflected again as its now an allied one
								
								end 
									
									
							
						end							

				end
			

		end
		
						for p, deflectableprojectile in pairs(ents.FindByClass( "rpg_missile" )) do
		if IsValid(deflectableprojectile.Owner) && deflectableprojectile:GetOwner() != self then
				if deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperassault" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_wotantheinvincible" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_wotantheinvincibleraidboss" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_arbalest" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadasscontaminator" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_badassfrontrunner" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadassicebreaker" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogbadass" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadasspowerhouse" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadasspyrotech" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperbadass" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperbreach" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_captaintraunt" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_troopercloak" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavycontaminator" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_deathsphere" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_defender" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_dropshipturret" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperflash" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_frontrunner" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_generaltraunt" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_noggigamind" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_gunwolf" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_harbinger" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_hoplite" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavyicebreaker" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperjet" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_katagawaball" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_katagawajr" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_kraken" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_troopermed" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogninja" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nog" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogromancer" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nullhound" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_oversphere" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavypowerhouse" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavypyrotech" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_reaper" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperreflect" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperriot" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_stinger" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_thor" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_valkyrie" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogdronesupport2" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogdronesupport1" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_captaintrauntmobileballfire" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_captaintrauntmobileballcorrosive" then ---DO NOT DEFLECT PROJECTILES OF ALLIES!
			--	--PrintMessage(HUD_PRINTTALK,"Friendly Projectile")
				else --- LAUNCH THAT LITTLE SHIT!
						
		
							if self:GetPos():Distance(deflectableprojectile:GetPos()) < 200 then ----- check deflectableprojectile distance to shield, so we do not become the parry god with unlimited range
----PrintMessage(HUD_PRINTTALK,"ded projectile")
					deflectableprojectile:EmitSound( "Missile.ShotDown" )
					deflectableprojectile:StopSound( "Missile.Ignite" )
					deflectableprojectile:StopSound( "Missile.Accelerate" )
									deflectableprojectile:Remove() --- to add insult to the original owner of the projectile when he dies. also prevents projectile to be deflected again as its now an allied one
								
								end 
									
									
							
						end							

				end
			

		end
		
								for p, deflectableprojectile in pairs(ents.FindByClass( "hunter_flechette" )) do
		if IsValid(deflectableprojectile.Owner) && deflectableprojectile:GetOwner() != self then
				if deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperassault" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_wotantheinvincible" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_wotantheinvincibleraidboss" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_arbalest" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadasscontaminator" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_badassfrontrunner" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadassicebreaker" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogbadass" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadasspowerhouse" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavybadasspyrotech" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperbadass" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperbreach" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_captaintraunt" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_troopercloak" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavycontaminator" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_deathsphere" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_defender" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_dropshipturret" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperflash" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_frontrunner" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_generaltraunt" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_noggigamind" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_gunwolf" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_harbinger" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_hoplite" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavyicebreaker" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperjet" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_katagawaball" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_katagawajr" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_kraken" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_troopermed" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogninja" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nog" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogromancer" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nullhound" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_oversphere" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavypowerhouse" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_heavypyrotech" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_reaper" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperreflect" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_trooperriot" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_stinger" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_thor" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_valkyrie" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogdronesupport2" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_nogdronesupport1" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_captaintrauntmobileballfire" or deflectableprojectile.Owner:GetClass() == "npc_vj_bl3_captaintrauntmobileballcorrosive" then ---DO NOT DEFLECT PROJECTILES OF ALLIES!
			--	--PrintMessage(HUD_PRINTTALK,"Friendly Projectile")
				else --- LAUNCH THAT LITTLE SHIT!
						
		
							if self:GetPos():Distance(deflectableprojectile:GetPos()) < 200 then ----- check deflectableprojectile distance to shield, so we do not become the parry god with unlimited range
----PrintMessage(HUD_PRINTTALK,"ded projectile")
									deflectableprojectile:Remove() --- to add insult to the original owner of the projectile when he dies. also prevents projectile to be deflected again as its now an allied one
								
								end 
									
									
							
						end							

				end
			

		end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:Use(activator, caller)

end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:OnTakeDamage(dmginfo)
end

---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:DoDeath()
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:OnRemove()
	self:StopParticles()
end
/*--------------------------------------------------
	=============== riotshield ===============
--------------------------------------------------*/
