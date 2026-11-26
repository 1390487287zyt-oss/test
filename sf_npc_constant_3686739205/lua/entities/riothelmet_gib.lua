-- lua/entities/scar_projectile.lua
AddCSLuaFile()

ENT.Type        = "anim"
ENT.Base        = "base_anim"
ENT.PrintName   = "Tactical Combine Helmet Gib"
ENT.Author      = "Rycch"
ENT.Purpose     = "Banana."
ENT.Category    = "Rycch's Custom NPCs"

ENT.Spawnable   = true
ENT.AdminOnly   = false

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/props/riothelmet.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:DrawShadow(false)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        self:SetHealth(10420)
        self:SetMaxHealth(self:Health())

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end

        -- Set both to use alpha rendering
        self:SetRenderMode(RENDERMODE_TRANSALPHA)

        -- lifetime bookkeeping
        self.SpawnTime  = CurTime()
        self.FadeStart  = self.SpawnTime + 5    -- start fade at +5s
        self.RemoveTime = self.FadeStart + 1    -- fully gone at +6s
    end

    function ENT:Think()

        local ct = CurTime()
        if ct >= self.FadeStart then
            -- compute fade fraction 0→1 over the 1s fade window
            local t = (ct - self.FadeStart) / (self.RemoveTime - self.FadeStart)
            local alpha = math.Clamp(255 * (1 - t), 0, 255)

            local col = self:GetColor()
            col.a = alpha
            self:SetColor(col)

            if ct >= self.RemoveTime then
                self:Remove()
                return
            end
        end

        self:NextThink(ct)
        return true
    end

    --function ENT:PhysicsCollide(data, phys)
    --    if data.Speed > 50 and data.Speed < 300 then
    --        self:EmitSound("physics/metal/metal_canister_impact_soft" .. math.random(1,3) .. ".wav", 75, math.random(90,110))
    --    elseif data.Speed >= 300 then
    --        self:EmitSound("physics/metal/metal_canister_impact_hard" .. math.random(1,3) .. ".wav", 75, math.random(90,110))
    --    end
    --end

    function ENT:OnTakeDamage(dmginfo)
        self:TakePhysicsDamage(dmginfo)
        self:SetHealth(self:Health() - dmginfo:GetDamage())
        self:EmitSound("physics/metal/metal_sheet_impact_bullet" .. math.random(1,2) .. ".wav", 75, math.random(90,110))
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end
