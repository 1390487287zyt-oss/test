AddCSLuaFile()
if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end

ENT.Type 			= "anim"
ENT.Base 			= "obj_vj_projectile_base"
ENT.PrintName		= "«ADVENT» Frag-Grenade"
ENT.Author 			= "DrVrej"
ENT.Category		= "VJ Base"

ENT.Spawnable = false

if !SERVER then return end

ENT.Model = "models/advent/ADVENT_Frag_Grenade.mdl"
ENT.ProjectileType = VJ.PROJ_TYPE_PROP
ENT.DoesRadiusDamage = true
ENT.RadiusDamageRadius = 350
ENT.RadiusDamage = 100
ENT.RadiusDamageUseRealisticRadius = true
ENT.RadiusDamageType = DMG_BLAST
ENT.RadiusDamageForce = 100
ENT.CollisionBehavior = VJ.PROJ_COLLISION_NONE
ENT.SoundTbl_OnCollide = "gren_collision"
ENT.FuseTime = 3
ENT.VJ_ID_Grenade = true
ENT.VJ_ID_Grabbable = true

function ENT:StartBlinking()
    local tickTime = 0.15
    local timerID = "vj_timer_blink_" .. self:EntIndex()
    
    timer.Create(timerID, tickTime, 0, function()
        if not IsValid(self) or self.Dead then
            timer.Remove(timerID)
            return
        end

        self:EmitSound("he_grenade_before_exp", 75, 100)
    end)
end

---------------------------------------------------------------------------
function ENT:Init()
    self:SetUseType(SIMPLE_USE)
    self:AddFlags(FL_GRENADE)

    -- Запуск пищания за 0.7 сек
    timer.Simple(self.FuseTime - 0.7, function()
        if IsValid(self) and not self.Dead then
            self:StartBlinking()
        end
    end)

    -- Таймер до взрыва
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
	timer.Remove("vj_timer_blink_" .. self:EntIndex()) -- Удаляем таймер звука
	local pos = self:GetPos()
	local defAngle = Angle(0, 0, 0)

	local tr = util.TraceLine({
		start = self:GetPos(),
		endpos = self:GetPos() - Vector(0,0,50),
		filter = self
	})
	if tr.Hit then
		util.Decal("Scorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
	end

	-- Эффекты и свет
	ParticleEffect("advent_frag_explosion", pos, defAngle)
	util.ScreenShake(pos, 10, 3, 1, 1000)

	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) then
			local dist = ply:GetPos():Distance(pos)

			if dist <= 3000 then
				ply:EmitSound(
					table.Random({
						"grenade/gren_expl1_close.wav",
						"grenade/gren_expl3_close.wav"
					}),
					70,
					60
				)
			else
				ply:EmitSound(
					table.Random({
						"grenade/gren_expl1_distant.wav",
						"grenade/gren_expl3_dist2.wav"
					}),
					70,
					60
				)
			end
		end
	end
	-- Основной урон
	self:DealDamage()
end
---------------------------------------------------------------------------
function ENT:Use(activator, caller)
	if IsValid(activator) and activator:IsPlayer() and activator:Alive() then
		activator:PickupObject(self)
	end
end