AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"

local nearSounds = {
    "MM_Impact01",
    "MM_Impact02",
    "MM_Impact03",
    "MM_Impact04",
}

local farSounds = {
    "FRAGExplode_far1",
}

local incomingSounds = {
    "MM_InComing06",
    "MM_InComing07",
    "MM_InComing08",
    "MM_InComing09",
}

function ENT:Initialize()
    self:SetModel("models/Items/AR2_Grenade.mdl")

    self:SetMoveType(MOVETYPE_FLYGRAVITY)
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)

    self:SetMaterial("invisible")
    self:SetColor(Color(255, 140, 0, 0))
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:DrawShadow(false)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetVelocity(Vector(0, 0, -700))
    end

    self.SpawnTime = CurTime()
    self.FallTime = 2
    self.WooshPlayed = false
    self.Exploded = false
end

function ENT:Think()
    local lifeTime = CurTime() - self.SpawnTime

    if not self.WooshPlayed and lifeTime > (self.FallTime - 2) then
        self:EmitSound(table.Random(incomingSounds), 90)
        self.WooshPlayed = true
    end

    if lifeTime > self.FallTime then
        self:Detonate()
        return
    end

    self:NextThink(CurTime())
    return true
end

function ENT:PhysicsCollide(data, phys)
    if data.HitWorld then
        self:Detonate()
    end
end

function ENT:Detonate()
    if self.Exploded then return end
    self.Exploded = true

    local pos = self:GetPos()
    ParticleEffect("advent_frag_explosion", pos, Angle(-90, 0, 0))

    local nearestDistSqr = math.huge

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local distSqr = ply:GetPos():DistToSqr(pos)
            if distSqr < nearestDistSqr then
                nearestDistSqr = distSqr
            end
        end
    end

    if nearestDistSqr <= (2200 * 2200) then
        self:EmitSound(table.Random(nearSounds), 110)
    else
        self:EmitSound(table.Random(farSounds), 130)
    end
    local attacker = IsValid(self:GetOwner()) and self:GetOwner() or self
    util.BlastDamage(self, attacker, pos, 450, 180)
    util.ScreenShake(pos, 80, 60, 1, 1200)

        local tr = util.TraceLine({
            start = bulletOrigin,
            endpos = pos - Vector(0, 0, 40),
            filter = self
        })

        if tr.Hit then
            util.Decal("Scorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
        end
    self:SetNoDraw(true)
    self:SetSolid(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    self:Remove()
end
