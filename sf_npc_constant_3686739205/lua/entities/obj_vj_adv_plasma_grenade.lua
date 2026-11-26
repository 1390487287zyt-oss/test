AddCSLuaFile()
if not file.Exists("autorun/vj_base_autorun.lua","LUA") then return end

ENT.Type      = "anim"
ENT.Base      = "obj_vj_projectile_base"
ENT.PrintName = "«ADVENT» Plasma Grenade"
ENT.Author    = "DrVrej"
ENT.Category  = "VJ Base"
ENT.Spawnable = false

if not SERVER then return end

ENT.Model                          = "models/advent/ADVENT_Plasma_Grenade.mdl"
ENT.ProjectileType                 = VJ.PROJ_TYPE_PROP
ENT.DoesRadiusDamage               = true
ENT.RadiusDamageRadius             = 335
ENT.RadiusDamage                   = 500
ENT.RadiusDamageUseRealisticRadius = false
ENT.RadiusDamageType               = bit.bor(DMG_BLAST,DMG_DISSOLVE)
ENT.RadiusDamageForce              = 30
ENT.CollisionBehavior              = VJ.PROJ_COLLISION_NONE
ENT.SoundTbl_OnCollide             = "gren_collision"
ENT.FuseTime                       = 2
ENT.VJ_ID_Grenade                  = true
ENT.VJ_ID_Grabbable                = true

function ENT:Init()
    self:SetUseType(SIMPLE_USE)
    self:AddFlags(FL_GRENADE)
    timer.Simple(self.FuseTime,function()
        if IsValid(self) then self:Destroy() end
    end)
end

function ENT:OnDamaged(dmginfo)
    local phys=self:GetPhysicsObject()
    if IsValid(phys) then
        phys:AddVelocity(dmginfo:GetDamageForce()*0.1)
    end
end

function ENT:OnCollision(_,phys)
    local vel=phys:GetVelocity()
    local spd=vel:Length()
    if spd>500 then phys:SetVelocity(vel*0.5) end
    if spd>100 then self:PlaySound("OnCollide") end
end

function ENT:OnDestroy()
    local pos=self:GetPos()

    local tr=util.TraceLine({
        start=pos,
        endpos=pos-Vector(0,0,50),
        filter=self
    })
    if tr.Hit then
        util.Decal("Scorch",tr.HitPos+tr.HitNormal,tr.HitPos-tr.HitNormal)
    end

    ParticleEffect("advent_plasma_grenade",pos,angle_zero)
    util.ScreenShake(pos,10,10,2,1000)

    for _,ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local snd=(ply:GetPos():DistToSqr(pos)<=3000*3000) and "PLASMAExplode_close" or "PLASMAExplode_far"
            ply:EmitSound(snd,150,(snd=="PLASMAExplode_close") and 90 or 100)
        end
    end

    self:DealDamage()
end

function ENT:Use(activator)
    if IsValid(activator) and activator:IsPlayer() and activator:Alive() then
        activator:PickupObject(self)
    end
end