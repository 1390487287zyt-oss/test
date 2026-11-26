AddCSLuaFile("shared.lua")
include('shared.lua')
/*-----------------------------------------------
	*** Copyright (c) 2012-2016 by DrVrej, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
-----------------------------------------------*/
ENT.HullType = HULL_MEDIUM
	-- ====Variant Variables==== --
ENT.Model = {"models/lubbi/test/autoship.mdl"} -- The game will pick a random model from the table when the SNPC is spawned | Add as many as you want
ENT.StartHealth = 20000
	-- ====== Blood-Related Variables ====== --
ENT.Bleeds = false -- Does the SNPC bleed? (Blood decal, particle, etc.)
ENT.Immune_Dissolve = true -- Immune to Dissolving | Example: Combine Ball
ENT.Immune_AcidPoisonRadiation = true -- Immune to Acid, Poison and Radiation
ENT.Immune_Bullet = true -- Immune to Bullets
ENT.Immune_Physics = true -- Immune to Physics
ENT.GibOnDeathDamagesTable = {"All"} -- Damages that it gibs from | "UseDefault" = Uses default damage types | "All" = Gib from any damage
ENT.HasDeathRagdoll = false

	-- Relationships ---------------------------------------------------------------------------------------------------------------------------------------------
ENT.HasAllies = true -- Put to false if you want it not to have any allies
ENT.VJ_NPC_Class = {"CLASS_SANGVIS", "CLASS_AUT"} -- NPCs with the same class with be allied to each other
ENT.ConstantlyFaceEnemy_IfVisible = false -- Should it only face the enemy if it's visible?
ENT.CallForHelpAnimationFaceEnemy = false-- Should it face the enemy when playing the animation?
-- ENT.AnimTbl_WeaponAttackFiringGesture = {} -- Firing Gesture animations used when the SNPC is firing the weapon
-- ENT.AnimTbl_TakingCover = {} -- The animation it plays when hiding in a covered position
ENT.AnimTbl_MoveToCover = {ACT_RUN} -- The animation it plays when moving to a covered position
ENT.AnimTbl_ShootWhileMovingRun = {ACT_RUN} -- Animations it will play when shooting while running | NOTE: Weapon may translate the animation that they see fit!
ENT.AnimTbl_ShootWhileMovingWalk = {ACT_RUN} -- Animations it will play when shooting while walking | NOTE: Weapon may translate the animation that they see fit!
ENT.AnimTbl_WeaponReload = {ACT_ARM} -- Animations that play when the SNPC reloads
ENT.DisableFootStepSoundTimer = true -- If set to true, it will disable the time system for the footstep sound code, allowing you to use other ways like model events
ENT.MovementType = VJ_MOVETYPE_STATIONARY
ENT.Behavior = VJ_BEHAVIOR_PASSIVE_NATURE
ENT.UnitCost = {
	{Name = "deichgraf", Cost = 1},
}
ENT.lights = {
	LeftLight1 = {Attachment = "Thruster_L_F_2", Color = "255 100 0", Scale = 4, Offset = Vector(0, 0, 0)},
	RightLight1 = {Attachment = "Thruster_R_F_2", Color = "255 100 0", Scale = 4, Offset = Vector(0, 0, 0)},
	BLeftLight1 = {Attachment = "Thruster_L_B_2", Color = "255 100 0", Scale = 4, Offset = Vector(0, 0, 0)},
	BRightLight1 = {Attachment = "Thruster_R_B_2", Color = "255 100 0", Scale = 4, Offset = Vector(0, 0, 0)},
	TailLight1 = {Attachment = "Tail_L", Color = "255 0 0", Scale = 0.5, Offset = Vector(0, 0, 0)},
	TailLight2 = {Attachment = "Tail_R", Color = "255 0 0", Scale = 0.5, Offset = Vector(0, 0, 0)},
	EngineLight1 = {Attachment = "Engine_L", Color = "255 0 0", Scale = 0.5, Offset = Vector(0, 0, 0)},
	EngineLight2 = {Attachment = "Engine_R", Color = "255 0 0", Scale = 0.5, Offset = Vector(0, 0, 0)},
}

ENT.AnimTbl_Spawn = {
	"Spawn",
}

ENT.AnimTbl_Leave = {
	"Leave",
}

ENT.AnimTbl_Idle = {
	"Idle",
}
function ENT:CustomOnPreInitialize()
	self.SpawnAnim = table.Random(self.AnimTbl_Spawn)
	self.LeaveAnim = table.Random(self.AnimTbl_Leave)

end

local function findAttachment(ent, name)
	local id = ent:LookupAttachment(name)
	if id <= 0 then return end
	local attachment = ent:GetAttachment(id)
	if attachment and attachment.Pos then return attachment, id end
end

function ENT:SpawnLights()
	local missingAttachments = {}
	for _, light in pairs(self.lights) do
		local attachment, attachmentID
		local position
		if light.Attachment ~= "" then
			attachment, attachmentID = findAttachment(self, light.Attachment)
			if attachment then
				position = attachment.Pos
			else
				missingAttachments[#missingAttachments + 1] = light.Attachment
			end
		else
			local offset = light.Offset
			position = self:GetPos() + self:GetForward() * offset.x + self:GetRight() * offset.y + self:GetUp() * offset.z
		end

		if position then
			local sprite = ents.Create("env_sprite")
			if IsValid(sprite) then
				sprite:SetPos(position)
				sprite:SetKeyValue("rendermode", "9")
				sprite:SetKeyValue("renderamt", "255")
				sprite:SetKeyValue("model", "blueflare1_noz.vmt")
				sprite:SetKeyValue("GlowProxySize", "10")
				sprite:SetKeyValue("rendercolor", tostring(light.Color))
				sprite:SetKeyValue("scale", tostring(light.Scale))
				sprite:Spawn()
				sprite:Activate()
				sprite:SetMoveType(MOVETYPE_NONE)
				if attachmentID then
					sprite:SetParent(self, attachmentID)
					sprite:SetLocalPos(vector_origin)
				else
					sprite:SetParent(self)
				end
			end
		end
	end

	if #missingAttachments > 0 then
		print(("[Sangvis Ferri] %s (%s): missing light attachments: %s"):format(
			self:GetClass(), tostring(self:GetModel()), table.concat(missingAttachments, ", ")))
	end
end

function ENT:CustomOnInitialize()
	self.engineSound = CreateSound(self, "dropshipsounds/bots_dropship_7.wav")
	if self.engineSound then
		self.engineSound:SetSoundLevel(105)
		self.engineSound:Play()
		self.engineSound:ChangeVolume(0)
		self.engineSound:ChangeVolume(1, 5)
		self.engineSound:ChangePitch(150)
	end

	self.windSound = CreateSound(self, "dropshipsounds/bots_dropship_39.wav")
	if self.windSound then
		self.windSound:SetSoundLevel(105)
		self.windSound:Play()
		self.windSound:ChangeVolume(1, 5)
		self.windSound:ChangePitch(150)
	end

	self:SetCollisionBounds(Vector(-500, -300, -50), Vector(500, 300, 400))
	self:SetAngles(Angle(0, math.random(0, 360), 0))
	local trace = util.TraceLine({
		start = self:GetPos(),
		endpos = self:GetPos() + self:GetUp()*-10000,
		filter = self,
	})
	if (trace.Hit) then
		self:SetPos(trace.HitPos + Vector(0,0,math.random(400, 700)))
	end

	local spawnSequence = self:LookupSequence(self.SpawnAnim)
	local spawnDuration = spawnSequence >= 0 and self:SequenceDuration(spawnSequence) or 0
	timer.Simple(0.001, function()
		if not IsValid(self) then return end
		self:SpawnLights()
		if spawnSequence >= 0 then
			self:VJ_ACT_PLAYACTIVITY(self.SpawnAnim, true, spawnDuration, false)
		end
	end)
	self:SetNoDraw(true)
	timer.Simple(0.3, function()
		if (IsValid(self)) then
			self:SetNoDraw(false)
		end
	end)
	timer.Simple(spawnDuration, function()
		if (IsValid(self)) then
			self:SpawnDUDES()
		end
	end)
end

ENT.marines = {}
ENT.leaving = false
function ENT:SpawnDUDES()
	if self.windSound then self.windSound:Play() end

	self.Resource = 1
	local timerName = "Spawn" .. self:GetCreationID()
	self.DropTimerName = timerName
	timer.Create(timerName, 2, 0, function()
		if not IsValid(self) then
			timer.Remove(timerName)
			return
		end

		if self.Resource > 0 then
			local affordable = {}
			for _, option in ipairs(self.UnitCost) do
				if option.Cost > 0 and option.Cost <= self.Resource then
					affordable[#affordable + 1] = option
				end
			end
			local unit = table.Random(affordable)
			if not unit then
				self.Resource = 0
				return
			end

			local class = "npc_vj_gf2_" .. unit.Name
			local marine = ents.Create(class)
			if not IsValid(marine) then
				print(("[Sangvis Ferri] %s could not deploy %s. Check that the NPC is installed and registered."):format(
					self:GetClass(), class))
				self.Resource = 0
				return
			end

			local attachment = findAttachment(self, "Spawn")
			local dropPosition
			if attachment then
				dropPosition = attachment.Pos - Vector(0, 0, 50)
			else
				dropPosition = self:GetPos() - Vector(0, 0, 160)
				if not self.WarnedMissingSpawnAttachment then
					self.WarnedMissingSpawnAttachment = true
					print(("[Sangvis Ferri] %s (%s): missing Spawn attachment, deploying below the dropship."):format(
						self:GetClass(), tostring(self:GetModel())))
				end
			end

			marine:SetPos(dropPosition)
			marine:SetAngles(self:GetAngles() + Angle(0, 180, 0))
			marine:Spawn()
			self.Resource = self.Resource - unit.Cost
			if not IsValid(marine) then return end

			timer.Simple(0.5, function()
				if IsValid(self) and IsValid(marine) then
					marine:SetVelocity(Vector(math.random(-150, 150), math.random(-150, 150), 0))
				end
			end)
			timer.Simple(2, function()
				if IsValid(self) and IsValid(marine) and marine.VJ_TASK_COVER_FROM_ENEMY then
					marine:VJ_TASK_COVER_FROM_ENEMY()
				end
			end)
			constraint.NoCollide(self, marine, 0, 0)
			local npcData = list.Get("NPC")[class]
			local weapon = npcData and npcData.Weapons and table.Random(npcData.Weapons)
			if weapon then marine:Give(weapon) end
			return
		end

		if not self.depletedTime then
			self.depletedTime = CurTime()
			return
		end

		local assistSetting = GetConVar("vj_spv3_phantomAssistTime")
		local assistTime = assistSetting and assistSetting:GetFloat() or 0
		if IsValid(self.turret) and CurTime() < self.depletedTime + assistTime then return end

		self.leaving = true
		timer.Remove(timerName)
		local leaveSequence = self:LookupSequence(self.LeaveAnim)
		local leaveDuration = leaveSequence >= 0 and self:SequenceDuration(leaveSequence) or 0
		if leaveSequence >= 0 then
			self:VJ_ACT_PLAYACTIVITY(self.LeaveAnim, true, leaveDuration, false)
		end
		if self.engineSound then
			self.engineSound:ChangeVolume(0, 5)
			self.engineSound:ChangePitch(150)
		end
		if self.windSound then
			self.windSound:Play()
			self.windSound:ChangePitch(150)
		end
		timer.Simple(leaveDuration, function()
			if IsValid(self) then self:Remove() end
		end)
	end)
end

function ENT:CustomOnRemove()
	if self.DropTimerName then timer.Remove(self.DropTimerName) end
	if self.engineSound then
		self.engineSound:Stop()
		self.engineSound = nil
	end
	if self.windSound then
		self.windSound:Stop()
		self.windSound = nil
	end
end

function ENT:CustomOnAcceptInput(key, activator, caller, data)
	local pitch, windVolume
	if key == "Engine_moving" then
		pitch, windVolume = 150, 0
	elseif key == "Engine_hovering" then
		pitch, windVolume = 100, 1
	else
		return
	end
	if self.engineSound then self.engineSound:ChangePitch(pitch, 3) end
	if self.windSound then self.windSound:ChangeVolume(windVolume, 3) end
end


local defAngle = Angle(0, 0, 0)

local sdExplosions = {"explosion/bots_interceptor_650.wav", "explosion/bots_interceptor_749.wav", "explosion/bots_interceptor_79.wav", "explosion/bots_interceptor_548.wav", "explosion/bots_interceptor_614.wav", }
function ENT:CustomOnInitialKilled(dmginfo, hitgroup)
	-- Spawn a animated model of the helicopter that explodes constantly and gets destroyed when it collides with something
	-- Based on source code
	local deathCorpse = ents.Create("prop_vj_animatable")
	if not IsValid(deathCorpse) then return end
	deathCorpse:SetModel(self:GetModel())
	deathCorpse:SetPos(self:GetPos())
	deathCorpse:SetAngles(self:GetAngles())
	function deathCorpse:Initialize()
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetMoveCollide(MOVECOLLIDE_FLY_BOUNCE)
		self:SetCollisionGroup(COLLISION_GROUP_NONE)
		self:SetSolid(SOLID_CUSTOM)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:EnableGravity(true)
			phys:SetBuoyancyRatio(0)
			phys:SetVelocity(self:GetVelocity())
			phys:AddAngleVelocity(Vector(math.Rand(-20, 20), math.Rand(-20, 20), 200))
		end
	end
	deathCorpse.NextExpT = 0
	deathCorpse:Spawn()
	deathCorpse:Activate()
	
		-- Explode as it goes down
	function deathCorpse:Think()
		self:ResetSequence("idle_move")
		if CurTime() > self.NextExpT then
			self.NextExpT = CurTime() + 0.2
			local expPos = self:GetPos() + Vector(math.Rand(-150, 150), math.Rand(-150, 150), math.Rand(-150, -50))
			ParticleEffect("vj_explosion2", self:GetPos(), defAngle, nil)

			
			util.BlastDamage(self, self, expPos, 300, 100)
			VJ_EmitSound(self, sdExplosions, 100, 100)
		end
	
		self:NextThink(CurTime())
		return true
	end
	
	-- Get destroyed when it collides with something
	function deathCorpse:PhysicsCollide(data, phys)
		if self.Dead then return end
		self.Dead = true
		ParticleEffect("vj_explosion2", self:GetPos(), defAngle, nil)
		
		local expPos = self:GetPos() + Vector(0,0,math.Rand(-150, -150))
		local effectData = EffectData()
		effectData:SetOrigin(expPos)
		effectData:SetScale(500)
		util.Effect("HelicopterMegaBomb", effectData)
		util.Effect("ThumperDust", effectData)
		--util.Effect("Explosion", effectData)
		util.Effect("VJ_medium_Explosion1", effectData)

		util.BlastDamage(self, self, expPos, 600, 200)
		VJ_EmitSound(self, sdExplosions, 100, 100)

		-- flags 0 = No fade!
		
		self:Remove()
	end
end