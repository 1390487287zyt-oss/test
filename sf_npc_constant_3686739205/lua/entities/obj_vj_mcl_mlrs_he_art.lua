AddCSLuaFile()
if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end

ENT.Type 			= "anim"
ENT.Base 			= "obj_vj_projectile_base"
ENT.PrintName		= "155mm Shell (Balanced for 500 HP)"
ENT.Author 			= "Faris"
ENT.Contact 		= "https://steamcommunity.com/id/faris9696/"
ENT.Information		= "Balanced rocket: 150 damage, 350 radius"
ENT.Category		= "Minecraft-Lite - entities"
ENT.Spawnable = false

ENT.VJ_ID_Danger = true

if !SERVER then return end

ENT.Model = {"models/props_marines/tow_missile_projectile.mdl"}

-- ========== БАЛАНСИРОВКА ПОД 500 HP ==========
ENT.DoesRadiusDamage = true
ENT.RadiusDamageRadius = 350
ENT.RadiusDamage = 150
ENT.RadiusDamageUseRealisticRadius = true
ENT.RadiusDamageType = DMG_BLAST
ENT.RadiusDamageForce = 40
ENT.RadiusDamageFalloff = true
-- ===========================================

ENT.DecalTbl_DeathDecals = {"Scorch"}

ENT.SoundTbl_Idle = {"vj_ksso_t45coeus_shooteffects"}
ENT.SoundTbl_Startup = {"vj_ksso_t45coeus_shooteffects"}

ENT.StartupSoundLevel = 100
ENT.IdleSoundLevel = 90
ENT.IdleSoundPitch = VJ_Set(120, 120)

ENT.shell_artillery = true
local vecZ20 = Vector(0, 0, 40)

function ENT:Init()
	local startPos = self:GetPos()
	
	local effectData = EffectData()
	effectData:SetOrigin(startPos)

	if GetConVarNumber("vj_cv_mcl_backblast_rg") == 1 then
		util.Effect("vj_mcl_backblast_rg", effectData)
	end

	-- Основной спрайтовый след (густой дым)
	util.SpriteTrail(self, 0, Color(180, 180, 180, 200), false, 15, 0, 0.5, 0.1, "trails/smoke.vmt")
	
	-- Дополнительный оранжевый след от ракетного двигателя
	util.SpriteTrail(self, 1, Color(255, 160, 60, 200), false, 8, 0, 0.3, 0.05, "trails/fire.vmt")

	-- Оставляем оригинальный след, если конвар включен (для совместимости)
	if GetConVarNumber("vj_cv_mcl_rocket_spritetrail") == 1 then
		util.SpriteTrail(self, 0, colorTrailRed, false, 5, 100, 3, 1 / ((2 + 10) * 1), "vj_mcl/particle/missiletrail01")
	end
	
	self.IdleLoop = CreateSound(self,"unknown sounds/weapon/gun/fire_mortar_whistle/whistle9.wav")
	self.IdleLoop:SetSoundLevel(85)
	self.IdleLoop:Play()
	self.IdleLoop:ChangeVolume(5)
	
	if GetConVarNumber("vj_cv_mcl_rocket_entity") == 1 then
		local eyeglow2 = ents.Create("env_sprite")
		eyeglow2:SetPos( self:GetPos() +self:GetForward()*0 +self:GetRight()*0 +self:GetUp()*0 )
		eyeglow2:SetKeyValue( "renderfx", "14" )
		eyeglow2:SetKeyValue( "model", "vj_mcl/additional/light1.vmt")
		eyeglow2:SetKeyValue("scale","0.5")
		eyeglow2:SetKeyValue("rendermode","5")
		eyeglow2:SetKeyValue("rendercolor","255, 93, 0")
		eyeglow2:SetKeyValue("spawnflags","1")
		eyeglow2:Spawn()
		eyeglow2:SetParent(self)
		eyeglow2:Activate()
		self:DeleteOnRemove(eyeglow2)
	end
		
	if GetConVarNumber("vj_cv_mcl_rocket_entity") == 1 then
		self.glowfog = ents.Create("light_dynamic")
		self.glowfog:SetKeyValue("brightness", "5")
		self.glowfog:SetKeyValue("distance", "500")
		self.glowfog:SetLocalPos(self:GetPos())
		self.glowfog:SetLocalAngles( self:GetAngles() )
		self.glowfog:Fire("Color", "255 93 0")
		self.glowfog:SetParent(self)
		self.glowfog:Spawn()
		self.glowfog:Activate()
		self.glowfog:Fire("TurnOn", "", 0)
		self:DeleteOnRemove(self.glowfog)
	end
	
	if self.shell_artillery then
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetVelocity(self:GetForward()*2800)
			self:SetAngles(self:GetVelocity():GetNormal():Angle())
			timer.Simple(0.0, function()
				if IsValid(self) then
					local myPos = self:GetPos()
					local tr = util.TraceLine({
						start = myPos,
						endpos = myPos + self:GetUp()*math.random(10000, 10000),
						filter = self
					})
					local hitPos = tr.HitPos - vecZ20
					phys = self:GetPhysicsObject()
					if IsValid(phys) then
						phys:SetVelocity(VJ.CalculateTrajectory(self, NULL, "Line", myPos, hitPos, 10000))
						self:SetAngles(self:GetVelocity():GetNormal():Angle())
						timer.Simple(myPos:Distance(hitPos) / self:GetVelocity():Length(), function()
							if IsValid(self) then
								local owner = self:GetOwner()
								if IsValid(owner) then
									phys = self:GetPhysicsObject()
									local ene = owner:GetEnemy()
									if IsValid(phys) && IsValid(ene) then
										phys:SetVelocity(VJ.CalculateTrajectory(owner, ene, "Line", self:GetPos(), 1, 6000))
										self:SetAngles(self:GetVelocity():GetNormal():Angle())
									end
								end
							end
						end)
					end
				end
			end)
		end
	end
end

function ENT:OnDestroy(data, phys)
	local myPos = self:GetPos()
	util.ScreenShake(data.HitPos, 8, 150, 2, 1000)

	-- Стандартный визуальный эффект взрыва Source (спрайт, дым, звук)
	local effectData = EffectData()
	effectData:SetOrigin(myPos)
	util.Effect("Explosion", effectData)

	-- Нанесение урона через систему VJ Base (радиус, урон и сила заданы в ENT)
	self:DealDamage()
end

function ENT:CustomOnRemove()
	if self.IdleLoop then
		self.IdleLoop:Stop()
	end
end