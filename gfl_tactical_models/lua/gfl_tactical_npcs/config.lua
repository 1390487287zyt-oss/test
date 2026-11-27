local config = {}

config.category = "[GFL] Tactical NPC"
config.baseClass = "npc_vj_gfl_tactical_base"
config.classPrefix = "npc_vj_gfl_tactical_"
config.resistanceTag = "CLASS_GFL_TACTICAL_RESISTANCE"

local elmo = "CLASS_GIRLS_FRONTLINE_ELMO"
local factions = {
    kcco = {
        "CLASS_GFL_TACTICAL_KCCO",
        "CLASS_TAU", "CLASS_KCCO", "CLASS_URNC", "CLASS_GFL_KCCO", "CLASS_GFL_URNC",
        "CLASS_GFL_MILITARY", "CLASS_GFL2_KCCO", "CLASS_GFL2_URNC", "CLASS_GFL2_MILITARY",
        "CLASS_KSSO", "CLASS_GIRLS_FRONTLINE_URNC", "CLASS_RU_MILITARY",
        "CLASS_UNITED_STATES", "CLASS_HECU",
    },
    gk = {"CLASS_GFL_TACTICAL_GK", elmo},
    elmo = {elmo, config.resistanceTag},
    underbroker = {"CLASS_GFL_TACTICAL_UNDERBROKER"},
    underbroker_specops = {"CLASS_GFL_TACTICAL_UNDERBROKER_SPECOPS"},
    gunfox = {"CLASS_GFL_TACTICAL_GUNFOX", elmo},
    yo_ponika = {"CLASS_GFL_TACTICAL_YO_PONIKA"},
    briefmerc = {"CLASS_GFL_TACTICAL_BRIEFMERC"},
    bgb = {"CLASS_GFL_TACTICAL_BGB"},
    lab_ingrid = {"CLASS_GFL_TACTICAL_LAB_INGRID", elmo},
}

config.sides = {"ally", "enemy"}
local sideData = {
    ally = {suffix = "（友军）", weapon = "weapon_vj_smg1"},
    enemy = {suffix = "（敌军）", weapon = "weapon_vj_ar2"},
}

config.units = {
    {"kcco_female_officer", "KCCO - 女军官", "kcco/officer/gfl2_commander_female_ksso", "kcco"},
    {"kcco_male_officer", "KCCO - 男军官", "kcco/officer/gfl2_commander_male_ksso", "kcco"},
    {"kcco_f1", "KCCO - 女性士兵 1 型", "kcco/solder/kcco_f1_medic", "kcco"},
    {"kcco_f2", "KCCO - 女性士兵 2 型", "kcco/solder/kcco_f2_medic", "kcco"},
    {"kcco_yegor", "KCCO - Yegor", "kcco/solder/kcco_yegor", "kcco"},
    {"kcco_m1", "KCCO - 男性士兵 1 型", "kcco/solder/kcco_m1", "kcco"},
    {"kcco_m2", "KCCO - 男性士兵 2 型", "kcco/solder/kcco_m2", "kcco"},
    {"kcco_m3", "KCCO - 男性士兵 3 型", "kcco/solder/kcco_m3", "kcco"},
    {"kcco_m4", "KCCO - 男性士兵 4 型", "kcco/solder/kcco_m4", "kcco"},
    {"kcco_specops", "KCCO - 特种作战士兵", "kcco/specops/kcco_specops", "kcco"},
    {"gk_female_officer", "G&K - 女指挥官", "g&k/officer/gfl2_commander_griffin_female", "gk"},
    {"gk_male_officer", "G&K - 男指挥官", "g&k/officer/gfl2_commander_griffin_male", "gk"},
    {"gk_soldier", "G&K - 普通士兵", "g&k/solder/gfl15_gk_solder", "gk"},
    {"gk_specops", "G&K - 特种作战士兵", "g&k/specoops/gfl15_gk_specoops", "gk"},
    {"underbroker", "Underbroker - 普通单位", "underbroker/solo/underbtoker", "underbroker"},
    {"underbroker_specops", "Underbroker - 特种作战单位", "underbroker/solo_specops/underbtoker_specops", "underbroker_specops"},
    {"gunfox_carp", "Gunfox Carp", "tactical/fox_ar/gunfox_carp", "gunfox"},
    {"yo_ponika", "Yo-Ponika - 私人军事承包商", "gfl/yo-ponika_pmc", "yo_ponika"},
    {"briefmerc", "Briefmerc - 男性雇佣兵", "brief/startmodel/briefmerc_man", "briefmerc"},
    {"bgb", "BGB - 快速反应组", "bgb_fast_groop_pm", "bgb"},
    {"lab_ingrid", "Lab Ingrid", "tucket1/labingrid", "lab_ingrid"},

    {"elmo_aglleader", "The Elmo AGL Leader", "sheepylord/butthead/aglleader", "elmo", "Aglleader"},
    {"elmo_aglcoleader", "The Elmo AGL Co-Leader", "sheepylord/butthead/aglcoleader", "elmo", "Aglcoleader"},
    {"elmo_aglsupport", "The Elmo AGL Support", "sheepylord/butthead/aglsupport", "elmo", "Aglsupport"},
    {"elmo_atg_member_a", "The Elmo ATG Member A", "sheepylord/girls_frontline_2/atg_member_a", "elmo", "ATG Member A"},
    {"elmo_atg_member_b", "The Elmo ATG Member B", "sheepylord/girls_frontline_2/atg_member_b", "elmo", "ATG Member B"},
    {"elmo_atg_member_c", "The Elmo ATG Member C", "sheepylord/girls_frontline_2/atg_member_c", "elmo", "ATG Member C"},
    {"elmo_ecm_member_a", "The Elmo ECM Member A", "sheepylord/girls_frontline_2/ecm_member_a", "elmo", "ECM Member A"},
    {"elmo_ecm_member_b", "The Elmo ECM Member B", "sheepylord/girls_frontline_2/ecm_member_b", "elmo", "ECM Member B"},
    {"elmo_ecm_member_c", "The Elmo ECM Member C", "sheepylord/girls_frontline_2/ecm_member_c", "elmo", "ECM Member C"},
    {"elmo_fac_member_a", "The Elmo FAC Member A", "sheepylord/girls_frontline_2/fac_member_a", "elmo", "FAC Member A"},
    {"elmo_fac_member_b", "The Elmo FAC Member B", "sheepylord/girls_frontline_2/fac_member_b", "elmo", "FAC Member B"},
    {"elmo_fac_member_c", "The Elmo FAC Member C", "sheepylord/girls_frontline_2/fac_member_c", "elmo", "FAC Member C"},
    {"elmo_mtr_member_a", "The Elmo MTR Member A", "sheepylord/girls_frontline_2/mtr_member_a", "elmo", "MTR Member A"},
    {"elmo_mtr_member_b", "The Elmo MTR Member B", "sheepylord/girls_frontline_2/mtr_member_b", "elmo", "MTR Member B"},
    {"elmo_mtr_member_c", "The Elmo MTR Member C", "sheepylord/girls_frontline_2/mtr_member_c", "elmo", "MTR Member C"},
    {"elmo_uav_member_a", "The Elmo UAV Member A", "sheepylord/girls_frontline_2/uav_member_a", "elmo", "UAV Member A"},
    {"elmo_uav_member_b", "The Elmo UAV Member B", "sheepylord/girls_frontline_2/uav_member_b", "elmo", "UAV Member B"},
    {"elmo_uav_member_c", "The Elmo UAV Member C", "sheepylord/girls_frontline_2/uav_member_c", "elmo", "UAV Member C"},
}

local byId = {}
for _, unit in ipairs(config.units) do
    byId[unit[1]] = unit
end

function config.Variant(id, side)
    local unit = assert(byId[id], id)
    local variant = assert(sideData[side], side)
    local ally = side == "ally"
    local tags = {}
    for _, tag in ipairs(factions[unit[4]]) do tags[#tags + 1] = tag end
    if ally then tags[#tags + 1] = "CLASS_PLAYER_ALLY" end

    return {
        class = config.classPrefix .. id .. "_" .. side,
        name = unit[2] .. variant.suffix,
        model = "models/" .. unit[3] .. ".mdl",
        faction = unit[4],
        tags = tags,
        weapon = variant.weapon,
        ally = ally,
    }
end

function config.Apply(ent, id, side)
    local variant = config.Variant(id, side)
    ent.Base = config.baseClass
    ent.Type = "ai"
    ent.PrintName = variant.name
    ent.Category = config.category
    ent.Spawnable = false
    ent.Model = {variant.model}
    ent.GFLTacticalWeapon = variant.weapon
    ent.GFLTacticalFaction = variant.faction
    ent.VJ_NPC_Class = variant.tags
    ent.FollowPlayer = variant.ally

    if variant.faction == "elmo" then
        -- VJ backup calls can recruit allied NPCs into combat against a player.
        if variant.ally then
            ent.CanReceiveOrders = false
        else
            ent.CallForHelp = false
        end
    end

    if id == "kcco_f1" or id == "kcco_f2" then
        ent.IsMedic = true
        ent.Medic_HealAmount = 25
        ent.Medic_TimeUntilHeal = 0.65
    end

    if id == "kcco_yegor" then
        ent.StartHealth = 500
        ent.MeleeAttackDamage = 20
        ent.GFLTacticalBulletDamageScale = 2
    end
end

return config
