local config = include("gfl_ares/config.lua")
local profile = config.profiles[ENT.AA02Class]

ENT.Base = "npc_vj_creature_base"
ENT.Type = "ai"
ENT.PrintName = profile.name
ENT.Category = "[GFL] NPC PACK"
ENT.StartHealth = profile.health
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Spawnable = false
ENT.VJ_NPC_Class = {
    "CLASS_TAU", "CLASS_KCCO", "CLASS_URNC", "CLASS_GFL_KCCO", "CLASS_GFL_URNC",
    "CLASS_GFL_MILITARY", "CLASS_GFL2_KCCO", "CLASS_GFL2_URNC", "CLASS_GFL2_MILITARY",
    "CLASS_KSSO", "CLASS_UNITED_STATES",
}

function ENT:SetupDataTables()
    local base = baseclass.Get("npc_vj_creature_base")
    if base.SetupDataTables then base.SetupDataTables(self) end
    self:NetworkVar("Int", 0, "AA02Skill")
    self:NetworkVar("Float", 0, "AA02SkillStart")
    self:NetworkVar("Float", 1, "AA02ShieldHP")
    self:NetworkVar("Float", 2, "AA02ShieldStart")
    self:NetworkVar("Float", 3, "AA02StunEnd")
    self:NetworkVar("Vector", 0, "AA02Aim")
end
