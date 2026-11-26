AddCSLuaFile()
if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end

ENT.Type        = "anim"
ENT.Base        = "obj_vj_projectile_base"
ENT.PrintName   = "«ADVENT» Grenade Launcher Shell"
ENT.Author      = "DrVrej"
ENT.Category    = "VJ Base"

ENT.Spawnable = false
ENT.AdminOnly = false

if !SERVER then return end

ENT.Model = "models/items/ar2_grenade.mdl"
ENT.ProjectileType = VJ.PROJ_TYPE_PROP
ENT.DoesRadiusDamage = true
ENT.RadiusDamageRadius = 350
ENT.RadiusDamage = 100
ENT.RadiusDamageUseRealisticRadius = true
ENT.RadiusDamageType = bit.bor(DMG_BLAST, DMG_BURN)
ENT.RadiusDamageForce = 30
ENT.CollisionBehavior = VJ.PROJ_COLLISION_NONE
ENT.FuseTime = 0  -- Без таймера, взрыв только при столкновении
ENT.VJ_ID_Grenade = true

-- Минимальная дистанция от стрелка до взрыва (чтобы не убить себя сразу)
local ARM_DISTANCE = 150

function ENT:Init()
    self.Armed = false
    self.Shooter = self:GetOwner()

    -- Взводим гранату после того как она отлетела достаточно далеко
    timer.Simple(0.15, function()
        if IsValid(self) then
            self.Armed = true
        end
    end)
end

function ENT:OnCollision(data, phys)
    if not self.Armed then return end

    -- Взрываемся при любом столкновении
    self:Destroy()
end

function ENT:OnDestroy()
    local pos = self:GetPos()
    local defAngle = Angle(0, 0, 0)

    local tr = util.TraceLine({
        start  = pos,
        endpos = pos - Vector(0, 0, 50),
        filter = self
    })
    if tr.Hit then
        util.Decal("Scorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
    end

    ParticleEffect("advent_frag_explosion", pos, defAngle)
    util.ScreenShake(pos, 10, 3, 1, 1000)

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local dist = ply:GetPos():Distance(pos)
            if dist <= 3000 then
                ply:EmitSound(table.Random({
                    "grenade/gren_expl1_close.wav",
                    "grenade/gren_expl3_close.wav"
                }), 150, 90)
            else
                ply:EmitSound(table.Random({
                    "grenade/gren_expl1_distant.wav",
                    "grenade/gren_expl3_dist2.wav"
                }), 150, 100)
            end
        end
    end

    self:DealDamage()
end