ENT.Base = "npc_vj_creature_base"
ENT.Type = "ai"
ENT.PrintName = "KCCO - Hydra"
ENT.Category = "[GFL] NPC PACK"
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Spawnable = false

-- The uploaded KCCO / URNC pack uses CLASS_TAU.
ENT.VJ_NPC_Class = {
    "CLASS_TAU",
    "CLASS_KCCO",
    "CLASS_URNC",
    "CLASS_GFL_KCCO",
    "CLASS_GFL_URNC",
    "CLASS_GFL_MILITARY",
    "CLASS_GFL2_KCCO",
    "CLASS_GFL2_URNC",
    "CLASS_GFL2_MILITARY",
    "CLASS_KSSO",
    "CLASS_UNITED_STATES",
}

function ENT:SetupDataTables()
    local base = self.BaseClass
    if base and base.SetupDataTables then base.SetupDataTables(self) end
    self:NetworkVar("Int", 0, "HydraAttack")
    self:NetworkVar("Float", 0, "HydraAttackStart")
    self:NetworkVar("Vector", 0, "HydraAttackTarget")
end
