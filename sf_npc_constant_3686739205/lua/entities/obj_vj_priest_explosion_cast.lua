AddCSLuaFile()
if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end

ENT.Type 			= "anim"
ENT.Base 			= "obj_vj_projectile_base"
ENT.PrintName		= "Explosion Cast Entity"
ENT.Author 			= "DrVrej"
ENT.Category		= "VJ Base"

ENT.Spawnable = false

if CLIENT then
	local Name = "Explosion Cast"
	local LangName = "obj_vj_explosion_cast"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(100,200,255,255))
end
---------------------------------------------------------------------------------------------------------------------------------------------
if !SERVER then return end
---------------------------------------------------------------------------------------------------------------------------------------------

ENT.Model = "models/hunter/plates/plate.mdl"
ENT.ProjectileType = VJ.PROJ_TYPE_PROP
ENT.CollisionBehavior = VJ.PROJ_COLLISION_NONE

---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:Init()

	-- Невидимость и отсутствие коллизии
	self:SetMoveType(MOVETYPE_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetColor(Color(255,255,255,0))
	self:SetMaterial("invisible")

	local basePos = self:GetPos()
	local glowPos = basePos + Vector(0, 0, 70)

	local fx = ents.Create("info_particle_system")
	if IsValid(fx) then
		fx:SetPos(glowPos)
		fx:SetAngles(Angle(0, 0, 0))
		fx:SetKeyValue("effect_name", "priest_amp_glow")
		fx:SetKeyValue("start_active", "1")
		fx:Spawn()
		fx:Activate()
		self.VJ_PFX_GLOW = fx
	end

	sound.Play("priest/priest_before_expcast.wav",basePos,80,100)

	timer.Simple(2, function()
		if !IsValid(self) then return end

		-- Убираем glow-частицу
		if IsValid(self.VJ_PFX_GLOW) then
			self.VJ_PFX_GLOW:Remove()
		end

		local finalPos = basePos + Vector(0, 0, 40)

		ParticleEffect("explosion_priest_cast", finalPos, Angle(0, 0, 0))

		-- Урон DMG_DISSOLVE в радиусе 500 юнитов
		local attacker = IsValid(self:GetOwner()) and self:GetOwner() or self
		for _, ent in ipairs(ents.FindInSphere(finalPos, 300)) do
			if IsValid(ent) then
                sound.Play("priest/priest_exp_cast.wav",basePos,70,100)
				local dmg = DamageInfo()
				dmg:SetDamage(100)
				dmg:SetDamageType(bit.bor(DMG_DISSOLVE, DMG_BLAST))
				dmg:SetAttacker(attacker)
				dmg:SetInflictor(self)
				dmg:SetDamagePosition(finalPos)
				ent:TakeDamageInfo(dmg)
			end
		end

		self:Remove()
	end)
end