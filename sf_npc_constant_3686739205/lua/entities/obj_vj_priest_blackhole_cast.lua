AddCSLuaFile()
if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end

ENT.Type           = "anim"
ENT.Base           = "obj_vj_projectile_base"
ENT.PrintName      = "Blackhole Cast Entity"
ENT.Author         = "DrVrej"
ENT.Category       = "VJ Base"

ENT.Spawnable = false

if CLIENT then
	local LangName = "obj_vj_blackhole_cast"
	language.Add(LangName, "Blackhole Cast")
	killicon.Add(LangName, "HUD/killicons/default", Color(80, 0, 150, 255))
end
---------------------------------------------------------------------------------------------------------------------------------------------
if !SERVER then return end
---------------------------------------------------------------------------------------------------------------------------------------------

ENT.Model              = "models/hunter/plates/plate.mdl"
ENT.ProjectileType     = VJ.PROJ_TYPE_PROP
ENT.CollisionBehavior  = VJ.PROJ_COLLISION_NONE

local PULL_RADIUS    = 800
local PULL_DURATION  = 8
local PLY_PULL_FORCE = 200
local PLY_PULL_MAX   = 200
local TICK           = 0.05
local WARN_DURATION  = 2

---------------------------------------------------------------------------------------------------------------------------------------------
local function CreateParticleSystem(effectName, pos)
	local fx = ents.Create("info_particle_system")
	if not IsValid(fx) then return nil end
	fx:SetPos(pos)
	fx:SetAngles(Angle(0, 0, 0))
	fx:SetKeyValue("effect_name", effectName)
	fx:SetKeyValue("start_active", "1")
	fx:SetMoveType(MOVETYPE_NONE)
	fx:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	fx:Spawn()
	fx:Activate()
	return fx
end

---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:Init()
	self:SetMoveType(MOVETYPE_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetColor(Color(0, 0, 0, 0))
	self:SetMaterial("invisible")

	local basePos = self:GetPos()
	local glowPos = basePos + Vector(0, 0, 70)

	sound.Play("ambient/atmosphere/cave_hit1.wav", basePos, 100, 55)
	self.VJ_PFX_WARN = CreateParticleSystem("priest_amp_glow", glowPos)

	local ent = self
	timer.Simple(WARN_DURATION, function()
		if not IsValid(ent) then return end

		if IsValid(ent.VJ_PFX_WARN) then ent.VJ_PFX_WARN:Remove() end

		ent.VJ_PFX_HOLE = CreateParticleSystem("blackhole_priest_cast", glowPos)
		sound.Play("priest/priest_blackhole_cast.wav", basePos, 100, 100)

		local pullTimer = "VJ_BlackHolePull_" .. ent:EntIndex()
		local elapsed   = 0

		timer.Create(pullTimer, TICK, 0, function()
			if not IsValid(ent) then
				timer.Remove(pullTimer)
				return
			end

			elapsed = elapsed + TICK
			if elapsed >= PULL_DURATION then
				timer.Remove(pullTimer)
				ent:BlackHoleExplode(basePos)
				return
			end

			for _, ply in ipairs(player.GetAll()) do
				if not IsValid(ply) or not ply:Alive() then continue end
				local toCenter = basePos - ply:GetPos()
				local dist = toCenter:Length()
				if dist > PULL_RADIUS then continue end

				if dist <= 100 then
					ply:SetVelocity(toCenter:GetNormalized() * 300 + Vector(0, 0, math.sin(elapsed * 5) * 30))
				else
					local strength = math.Clamp(20000 / (dist * dist) * PLY_PULL_FORCE, 5, PLY_PULL_MAX)
					local dir      = toCenter:GetNormalized()
					local tangent  = dir:Cross(Vector(0, 0, 1)):GetNormalized()
					ply:SetVelocity((dir * strength + tangent * strength * 0.4) * TICK * 20)
				end
			end
		end)
	end)
end

---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:BlackHoleExplode(center)
	if IsValid(self.VJ_PFX_HOLE) then self.VJ_PFX_HOLE:Remove() end

	sound.Play("priest/priest_blackhole_exp.wav", center, 135, 105)

	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) or not ply:Alive() then continue end
		if ply:GetPos():Distance(center) > PULL_RADIUS then continue end

		local dir = ((ply:GetPos() - center):GetNormalized() + VectorRand() * 0.2):GetNormalized()
		ply:SetVelocity(dir * math.random(800, 1400) + Vector(0, 0, math.random(300, 600)))

		local defaultWalk = ply:GetWalkSpeed()
		local defaultRun  = ply:GetRunSpeed()
		ply:SetWalkSpeed(100)
		ply:SetRunSpeed(100)
		timer.Simple(5, function()
			if not IsValid(ply) then return end
			ply:SetWalkSpeed(defaultWalk)
			ply:SetRunSpeed(defaultRun)
		end)
	end

	self:Remove()
end