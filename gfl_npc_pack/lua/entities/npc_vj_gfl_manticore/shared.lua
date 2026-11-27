ENT.Base = "npc_vj_creature_base"
ENT.Type = "ai"
ENT.PrintName = "Sangvis Ferri - Manticore"
ENT.Category = "[GFL] NPC PACK"
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Spawnable = false
-- The standalone Sangvis Ferri pack and vj_gfl_enemies_snpcs use different tags.
ENT.VJ_NPC_Class = {"CLASS_SANGVIS", "CLASS_AUT", "CLASS_SF"}

function ENT:SetupDataTables()
    local base = self.BaseClass
    if base and base.SetupDataTables then base.SetupDataTables(self) end
    self:NetworkVar("Float", 0, "ManticoreAttackStart")
    self:NetworkVar("Vector", 0, "ManticoreAttackTarget")
end
