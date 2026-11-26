AddCSLuaFile()
if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end

ENT.Type 			= "anim"
ENT.Base 			= "obj_vj_projectile_base"
ENT.PrintName		= "«ADVENT» Incendiary Grenade"
ENT.Author 			= "DrVrej"
ENT.Category		= "VJ Base"

ENT.Spawnable = false

if !SERVER then return end

-- Основные параметры
ENT.Model = "models/advent/ADVENT_Incendiary_Grenade.mdl"
ENT.ProjectileType = VJ.PROJ_TYPE_PROP
ENT.DoesRadiusDamage = true
ENT.RadiusDamageRadius = 450
ENT.RadiusDamage = 25
ENT.RadiusDamageUseRealisticRadius = true
ENT.RadiusDamageType = bit.bor(DMG_BLAST, DMG_BURN)
ENT.RadiusDamageForce = 30
ENT.CollisionBehavior = VJ.PROJ_COLLISION_NONE
ENT.SoundTbl_OnCollide = "gren_collision"
ENT.FuseTime = 2.5
ENT.VJ_ID_Grenade = true
ENT.VJ_ID_Grabbable = true

---------------------------------------------------------------------------
function ENT:Init()
	self:SetUseType(SIMPLE_USE)
	self:AddFlags(FL_GRENADE)

	timer.Simple(self.FuseTime, function()
		if IsValid(self) then
			self:Destroy()
		end
	end)
end
---------------------------------------------------------------------------
function ENT:OnDamaged(dmginfo)
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:AddVelocity(dmginfo:GetDamageForce() * 0.02)
	end
end
---------------------------------------------------------------------------
function ENT:OnCollision(data, phys)
	local vel = phys:GetVelocity()
	local speed = vel:Length()
	if speed > 500 then phys:SetVelocity(vel * 0.7) end
	if speed > 100 then self:PlaySound("OnCollide") end
end
---------------------------------------------------------------------------
function ENT:OnDestroy()
	local pos = self:GetPos()
	local defAngle = Angle(0, 0, 0)

	-- След от ожога
	local tr = util.TraceLine({
		start = pos,
		endpos = pos - Vector(0,0,50),
		filter = self
	})
	if tr.Hit then
		util.Decal("Scorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
	end

	ParticleEffect("advent_inc_grenade", pos, defAngle)
	util.ScreenShake(pos, 10, 3, 1, 1000)
	sound.Play("INCExplode_close", pos)

	for _, ent in ipairs(ents.FindInSphere(pos, 450)) do
		if IsValid(ent) and (ent:IsNPC() or ent:IsPlayer() or ent:GetClass() == "prop_physics") then
			
			local targetPos = ent:WorldSpaceCenter()

			local tr = util.TraceLine({
				start = pos,
				endpos = targetPos,
				filter = {self, ent}
			})

			if not tr.Hit then
				ent:Ignite(math.random(8,15), 0)
			end
		end
	end

	self:DealDamage()

	local expLight = ents.Create("light_dynamic")
	if IsValid(expLight) then
		expLight:SetKeyValue("brightness", "8")
		expLight:SetKeyValue("distance", "600")
		expLight:SetLocalPos(pos)
		expLight:SetLocalAngles(self:GetAngles())
		expLight:Fire("Color", "255 150 0")
		expLight:SetParent(self)
		expLight:Spawn()
		expLight:Activate()
		expLight:Fire("TurnOn")
		self:DeleteOnRemove(expLight)

		-- Таймер плавного выключения через 3 секунды
		timer.Simple(3, function()
			if IsValid(expLight) then
				expLight:Fire("TurnOff")
				SafeRemoveEntity(expLight)
			end
		end)
	end
end
---------------------------------------------------------------------------
function ENT:Use(activator)
	if IsValid(activator) and activator:IsPlayer() and activator:Alive() then
		activator:PickupObject(self)
	end
end