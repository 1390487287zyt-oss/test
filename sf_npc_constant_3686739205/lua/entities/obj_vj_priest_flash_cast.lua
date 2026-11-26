AddCSLuaFile()
if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end

ENT.Type = "anim"
ENT.Base = "obj_vj_projectile_base"
ENT.PrintName = "Flash Cast Entity"
ENT.Author = "DrVrej"
ENT.Category = "VJ Base"

ENT.Spawnable = false

if CLIENT then
	net.Receive("vj_flash_cast_hit", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		RunConsoleCommand("dsp_player", "32")
		ply:EmitSound("npc/manhack/mh_blade_loop1.wav", 150, 50, 1, CHAN_STATIC)

		timer.Simple(7, function()
			if IsValid(ply) then
				ply:StopSound("npc/manhack/mh_blade_loop1.wav")
			end
		end)

		local flashStart = CurTime()
		local BLIND_DURATION = 5
		local BLIND_FADE = 3
		local BLUR_DURATION = 11

		hook.Add("HUDPaint", "VJ_FlashCastEffect", function()
			if not IsValid(ply) or not ply:Alive() then
				hook.Remove("HUDPaint", "VJ_FlashCastEffect")
				RunConsoleCommand("dsp_player", "0")
				ply:StopSound("npc/manhack/mh_blade_loop1.wav")
				return
			end

			local elapsed = CurTime() - flashStart

			if elapsed >= BLIND_DURATION and elapsed < BLIND_DURATION + 3 then
				RunConsoleCommand("dsp_player", "0")
			end

			local whiteAlpha = 0
			if elapsed < BLIND_DURATION then
				whiteAlpha = 255
			elseif elapsed < BLIND_DURATION + BLIND_FADE then
				local fadeProgress = (elapsed - BLIND_DURATION) / BLIND_FADE
				whiteAlpha = math.Round(255 * (1 - fadeProgress))
			end

			if whiteAlpha > 0 then
				surface.SetDrawColor(255,255,255,whiteAlpha)
				surface.DrawRect(0,0,ScrW(),ScrH())
			end

			local blurStrength = 0
			if elapsed < BLIND_DURATION then
				blurStrength = 1
			elseif elapsed < BLUR_DURATION then
				local blurFade = (elapsed - BLIND_DURATION) / (BLUR_DURATION - BLIND_DURATION)
				blurStrength = 1 - blurFade
			end

			if blurStrength > 0 then
				DrawMotionBlur(0.4 * blurStrength, 0.8 * blurStrength, 0.05 * blurStrength)
				DrawBloom(0.6 * blurStrength, 2 * blurStrength, 6 * blurStrength, 6 * blurStrength, 1, 1 * blurStrength, 1 * blurStrength, 1 * blurStrength, 1 * blurStrength)
			end

			if elapsed >= BLUR_DURATION then
				hook.Remove("HUDPaint", "VJ_FlashCastEffect")
			end
		end)
	end)
end

if SERVER then
	util.AddNetworkString("vj_flash_cast_hit")

	function ENT:TriggerFlashForPlayers(pos)
		for _, ply in ipairs(player.GetAll()) do
			if not IsValid(ply) or not ply:Alive() then continue end

			local dist = ply:GetPos():Distance(pos)

			if dist <= 450 then
				net.Start("vj_flash_cast_hit")
				net.Send(ply)
				continue
			end

			if dist <= 1000 then
				local toFlash = (pos - ply:EyePos()):GetNormalized()
				local dot = ply:EyeAngles():Forward():Dot(toFlash)
				if dot > 0.5 then
					net.Start("vj_flash_cast_hit")
					net.Send(ply)
				end
			end
		end
	end
end

ENT.Model = "models/hunter/plates/plate.mdl"
ENT.ProjectileType = VJ.PROJ_TYPE_PROP
ENT.CollisionBehavior = VJ.PROJ_COLLISION_NONE

function ENT:Init()
	self:SetMoveType(MOVETYPE_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetColor(Color(255,255,255,0))
	self:SetMaterial("invisible")

	local basePos = self:GetPos()
	local glowPos = basePos + Vector(0,0,70)

	sound.Play("priest/priest_before_flashcast.wav",basePos,75,100)

	local fx = ents.Create("info_particle_system")
	if IsValid(fx) then
		fx:SetPos(glowPos)
		fx:SetAngles(Angle(0,0,0))
		fx:SetKeyValue("effect_name","priest_amp_glow")
		fx:SetKeyValue("start_active","1")
		fx:SetMoveType(MOVETYPE_NONE)
		fx:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		fx:Spawn()
		fx:Activate()
		self.VJ_PFX_GLOW = fx
	end

	timer.Simple(2,function()
		if not IsValid(self) then return end

		if IsValid(self.VJ_PFX_GLOW) then
			self.VJ_PFX_GLOW:Remove()
		end

		ParticleEffect("flash_priest_cast",glowPos,Angle(0,0,0))

		sound.Play("priest/priest_flash_cast.wav",basePos,150,100)

		self:TriggerFlashForPlayers(basePos)
		self:Remove()
	end)
end