AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
local config = include("gfl_ares/config.lua")
local hull = Vector(3, 3, 3)
local right = Vector(0, 0, 1)

function ENT:Initialize()
    self:SetModel("models/weapons/w_missile_closed.mdl")
    self:SetCollisionBounds(-hull, hull)
    self:SetSolid(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    self:DrawShadow(false)
    local now = CurTime()
    self.AA02Born, self.AA02LastStep = now, now
    self.AA02Forward = self:GetForward()
    local trail = util.SpriteTrail(self, 0, Color(209, 213, 200, 180), false, 11, 1, .48, .08, "trails/smoke")
    if IsValid(trail) then self:DeleteOnRemove(trail) end
end

function ENT:Think()
    local owner = self:GetOwner()
    local now = CurTime()
    local age = now - self.AA02Born
    if not IsValid(owner) or owner.Dead or not self.AA02Target or age > 4 then
        self:Remove()
        return
    end
    local dt = math.Clamp(now - self.AA02LastStep, 0, .095)
    self.AA02LastStep = now
    local pos = self:GetPos()
    local remaining = self.AA02Target - pos
    local forward = self.AA02Forward
    if age >= .15 then
        forward = LerpVector(math.min(1, dt * 9), forward, remaining:GetNormalized()):GetNormalized()
        self.AA02Forward = forward
    end
    local distance = Lerp(math.Clamp(age * 2, 0, 1), 820, 1830) * self.AA02Speed * dt
    local arrived = age > .15 and remaining:Length() <= distance
    local dest = arrived and self.AA02Target or pos + forward * distance
    local trace = util.TraceHull({
        start = pos, endpos = dest, mins = -hull, maxs = hull, mask = MASK_SHOT,
        filter = function(ent) return ent ~= self and ent ~= owner and ent:GetClass() ~= "gfl_aa02_rocket" end,
    })
    if trace.Hit or arrived then
        if not trace.HitSky then
            local impact = trace.Hit and trace.HitPos + trace.HitNormal * 3 or dest + right * 2
            owner:AA02Blast(impact, trace.Entity, forward, self.AA02Damage, self.AA02Damage, config.rocketRadius, .95)
        end
        self:Remove()
        return
    end
    self:SetPos(dest)
    self:SetAngles(forward:Angle())
    self:NextThink(now)
    return true
end
