-- AA-02 adaptation of the supplied LVS Strider beam and Gunship ground impact.
local beam = Material("sprites/bluelaser1")
local muzzle = Material("effects/strider_muzzle")
local warp = Material("particle/warp5_warp")
local glow = Material("sprites/light_glow02_add")
local lifetime = .4

local function flash(pos, brightness, size, duration)
    local light = DynamicLight(math.random(20000, 29999))
    if not light then return end
    light.pos = pos
    light.r, light.g, light.b = 80, 200, 255
    light.brightness = brightness
    light.Decay = 1500
    light.Size = size
    light.DieTime = CurTime() + duration
end

function EFFECT:Init(data)
    self.source = data:GetStart()
    self.impact = data:GetOrigin()
    self.normal = data:GetNormal()
    self.hit = data:GetFlags() == 0
    self.ends = CurTime() + lifetime
    self:SetRenderBoundsWS(self.source, self.impact, Vector(400, 400, 400))
    flash(self.source, 6, 650, lifetime)
    if not self.hit then return end

    local effect = EffectData()
    effect:SetOrigin(self.impact + self.normal * 8)
    effect:SetNormal(self.normal)
    effect:SetRadius(256)
    util.Effect("AR2Explosion", effect)

    local burst = EffectData()
    burst:SetOrigin(self.impact + self.normal * 12)
    burst:SetNormal(self.normal)
    burst:SetMagnitude(6)
    burst:SetScale(3)
    burst:SetRadius(8)
    util.Effect("cball_explode", burst)
    flash(self.impact + self.normal * 40, 8, 1000, .7)
end

function EFFECT:Think()
    return CurTime() < self.ends
end

function EFFECT:Render()
    local t = math.Clamp((self.ends - CurTime()) / lifetime, 0, 1)
    render.SetMaterial(beam)
    render.DrawBeam(self.source, self.impact, 70 * t, 0, 1, Color(255, 255, 255, 255 * t))
    render.DrawBeam(self.source, self.impact, 22 * t, 0, 1, Color(150, 230, 255, 255 * t))
    render.SetMaterial(muzzle)
    render.DrawSprite(self.source, 90 * t, 90 * t, Color(255, 255, 255, 255 * t))
    if not self.hit then return end

    local origin = self.impact + self.normal * 20
    render.SetMaterial(warp)
    local ripple = (1 - t) * 760
    render.DrawSprite(origin, ripple, ripple, Color(255, 255, 255, 150 * t))
    render.SetMaterial(glow)
    render.DrawSprite(origin, 460 * t, 460 * t, Color(100, 210, 255, 255 * t))
end
