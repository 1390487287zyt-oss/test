local visual = include("gfl_ares/config.lua").shieldVisual
local offset = Vector(17, 0, 108)
local facing = Angle(0, 90, 0)

return function(self, now)
    if self:GetAA02ShieldHP() <= 0 or now - self:GetAA02ShieldStart() < visual.deployTime then return end

    local model = self.AA02ShieldModel
    if not IsValid(model) then
        model = ClientsideModel(visual.model, RENDERGROUP_TRANSLUCENT)
        if not IsValid(model) then return end
        self.AA02ShieldModel = model
        model:SetNoDraw(true)
        model:DrawShadow(false)
        model:SetSkin(visual.skin)
        model:SetModelScale(visual.scale, 0)
        self:CallOnRemove("AA02ShieldModel", function(_, shield)
            if IsValid(shield) then shield:Remove() end
        end, model)
    end

    local position, angle = LocalToWorld(offset, facing, self:GetPos(), self:GetAngles())
    model:SetPos(position)
    model:SetAngles(angle)
    model:SetupBones()
    model:DrawModel()
end
