include("shared.lua")
local meshes = include("gfl_ares/meshes.lua")
function ENT:Initialize()
    self:SetRenderBounds(Vector(-22, -12, -12), Vector(22, 12, 12))
end

function ENT:Draw()
    local projectile = meshes.Projectile()
    if not projectile then self:DrawModel() return end
    self.AA02Matrix = self.AA02Matrix or Matrix()
    self.AA02Matrix:SetTranslation(self:GetPos())
    self.AA02Matrix:SetAngles(self:GetAngles())
    cam.PushModelMatrix(self.AA02Matrix)
    render.SetMaterial(projectile.material)
    projectile.mesh:Draw()
    cam.PopModelMatrix()
end
