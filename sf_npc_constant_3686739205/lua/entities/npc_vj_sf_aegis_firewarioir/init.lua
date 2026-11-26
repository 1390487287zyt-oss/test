AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = {"models/npc/gfl2_aegis_swap_myrmidon_npc.mdl"}
ENT.StartHealth = 6000
ENT.VJ_NPC_Class = {"CLASS_SANGVIS"}
ENT.BloodColor = "oil"

-- [ДОБАВЛЕНО] Настройки для взрыва при смерти
ENT.HasDeathRagdoll = false          -- Отключаем обычный труп
ENT.HasDeathAnimation = false        -- Отключаем анимацию смерти (взрыв сразу)
ENT.HasGibOnDeath = true             -- Разрешаем создание гибов
ENT.GibOnDeathDamagesTable = {"UseDefault"}

ENT.MeleeAttackDamage = 200

ENT.CallForHelpDistance = 10000
ENT.InvestigateSoundDistance = 18

ENT.CanFlinch = 1
ENT.FlinchChance = 4

ENT.FootStepTimeRun = 0.3
ENT.FootStepTimeWalk = 0.5

ENT.HasItemDropsOnDeath = false
ENT.ItemDropsOnDeathChance = 2
ENT.ItemDropsOnDeath_EntityList = {
    "item_ammo_smg1_grenade",
    "item_battery",
    "item_healthvial",
    "weapon_frag",
}

ENT.Soldier_SniperSpread = 0.75
ENT.Soldier_WeaponSpread = 1.5

ENT.HasGrenadeAttack = false
ENT.GrenadeAttackEntity = "npc_grenade_frag"
ENT.ThrowGrenadeChance = math.random(0, 4)
ENT.ConstantlyFaceEnemyDistance = 700

ENT.CanBeMedic = false

ENT.CanHaveTurret = false
ENT.TurretDeployDist = 2000

-- Параметры прыжкового ранца (больше не используются)
ENT.JumpParams = {
    Enabled     = true,
    MaxRise     = 500,
    MaxDrop     = 1000,
    MaxDistance = 300,
}

-- Sound levels
ENT.FootStepSoundLevel          = 60
ENT.IdleSoundLevel              = 65
ENT.IdleDialogueSoundLevel      = 65
ENT.IdleDialogueAnswerSoundLevel= 65
ENT.CombatIdleSoundLevel        = 70
ENT.InvestigateSoundLevel       = 70
ENT.LostEnemySoundLevel         = 65
ENT.AlertSoundLevel             = 70
ENT.WeaponReloadSoundLevel      = 60
ENT.GrenadeAttackSoundLevel     = 70
ENT.OnGrenadeSightSoundLevel    = 70
ENT.OnDangerSightSoundLevel     = 70
ENT.OnKilledEnemySoundLevel     = 70
ENT.AllyDeathSoundLevel         = 70
ENT.PainSoundLevel              = 70
ENT.DeathSoundLevel             = 70

ENT.wep = "weapon_vj_ar1"

local DefaultSoundTbl_MedicAfterHeal = {"items/smallmedkit1.wav"}

---------------------------------------------------------------------------
-- OnPlayCreateSound: Play radio sounds around pain and heal events
---------------------------------------------------------------------------
function ENT:OnPlayCreateSound(sdData, sdFile)
    if not ((VJ_HasValue(self.SoundTbl_Pain, sdFile) and not VJ_HasValue(self.SoundTbl_Hurt, sdFile)) or
           VJ_HasValue(DefaultSoundTbl_MedicAfterHeal, sdFile) or
           VJ_HasValue(self.DefaultSoundTbl_MeleeAttack, sdFile) or
           VJ_HasValue(self.SoundTbl_NovaProspektIdle, sdFile)) then

        self:EmitSound(table.Random(self.SoundTbl_RadioOn), 90, math.random(85, 115))
        timer.Simple(SoundDuration(sdFile), function()
            if IsValid(self) and sdData:IsPlaying() then
                self:EmitSound(table.Random(self.SoundTbl_RadioOff), 70, math.random(85, 115))
            end
        end)
    end
end

---------------------------------------------------------------------------
-- SoldierInit (empty placeholder)
---------------------------------------------------------------------------
function ENT:SoldierInit() end

---------------------------------------------------------------------------
-- CustomOnInitialize: Set up weapons, sounds, medic flag and jump variables
---------------------------------------------------------------------------
function ENT:CustomOnInitialize()
    self:Give(self.wep)

    self.SoundTbl_FootStep = {
        "npc/combine_soldier/gear1.wav",
        "npc/combine_soldier/gear2.wav",
        "npc/combine_soldier/gear3.wav",
        "npc/combine_soldier/gear4.wav",
        "npc/combine_soldier/gear5.wav",
        "npc/combine_soldier/gear6.wav",
    }

    self.SoundTbl_Idle = {
        "npc/combine_soldier/vo/gridsundown46.wav",
        "npc/combine_soldier/vo/noviscon.wav",
        "npc/combine_soldier/vo/ovewatchorders3ccstimboost.wav",
        "npc/combine_soldier/vo/reportallpositionsclear.wav",
        "npc/combine_soldier/vo/reportallradialsfree.wav",
        "npc/combine_soldier/vo/reportingclear.wav",
        "npc/combine_soldier/vo/sectorissecurenovison.wav",
        "npc/combine_soldier/vo/sightlineisclear.wav",
        "npc/combine_soldier/vo/stabilizationteamhassector.wav",
        "npc/combine_soldier/vo/stabilizationteamholding.wav",
        "npc/combine_soldier/vo/teamdeployedandscanning.wav",
        "npc/combine_soldier/vo/unitisclosing.wav",
        "npc/combine_soldier/vo/wehavenontaggedviromes.wav",
    }
    self.SoundTbl_IdleDialogue = self.SoundTbl_Idle
    self.SoundTbl_IdleDialogueAnswer = {
        "npc/combine_soldier/vo/copy.wav",
        "npc/combine_soldier/vo/copythat.wav",
    }

    self.SoundTbl_Investigate = {
        "npc/combine_soldier/vo/motioncheckallradials.wav",
        "npc/combine_soldier/vo/overwatchreportspossiblehostiles.wav",
        "npc/combine_soldier/vo/prepforcontact.wav",
        "npc/combine_soldier/vo/readycharges.wav",
        "npc/combine_soldier/vo/readyextractors.wav",
        "npc/combine_soldier/vo/readyweapons.wav",
        "npc/combine_soldier/vo/readyweaponshostilesinbound.wav",
        "npc/combine_soldier/vo/stayalert.wav",
        "npc/combine_soldier/vo/stayalertreportsightlines.wav",
        "npc/combine_soldier/vo/weaponsoffsafeprepforcontact.wav",
        "npc/combine_soldier/vo/confirmsectornotsterile.wav",
    }

    self.SoundTbl_CombatIdle = {
        "npc/combine_soldier/vo/thatsitwrapitup.wav",
        "npc/combine_soldier/vo/gosharp.wav",
        "npc/combine_soldier/vo/hardenthatposition.wav",
        "npc/combine_soldier/vo/gosharpgosharp.wav",
        "npc/combine_soldier/vo/targetmyradial.wav",
        "npc/combine_soldier/vo/goactiveintercept.wav",
        "npc/combine_soldier/vo/unitisinbound.wav",
        "npc/combine_soldier/vo/unitismovingin.wav",
        "npc/combine_soldier/vo/sweepingin.wav",
        "npc/combine_soldier/vo/executingfullresponse.wav",
        "npc/combine_soldier/vo/containmentproceeding.wav",
        "npc/combine_soldier/vo/callhotpoint.wav",
        "npc/combine_soldier/vo/callcontacttarget1.wav",
        "npc/combine_soldier/vo/prosecuting.wav",
    }

    self.SoundTbl_Alert = {
        "npc/combine_soldier/vo/contact.wav",
        "npc/combine_soldier/vo/viscon.wav",
        "npc/combine_soldier/vo/alert1.wav",
        "npc/combine_soldier/vo/contactconfirmprosecuting.wav",
        "npc/combine_soldier/vo/contactconfim.wav",
        "npc/combine_soldier/vo/outbreak.wav",
        "npc/combine_soldier/vo/fixsightlinesmovein.wav",
    }

    self.SoundTbl_WeaponReload = {
        "npc/combine_soldier/vo/cover.wav",
        "npc/combine_soldier/vo/coverme.wav",
    }

    self.SoundTbl_GrenadeAttack = {
        "npc/combine_soldier/vo/extractoraway.wav",
        "npc/combine_soldier/vo/extractorislive.wav",
    }

    self.SoundTbl_OnDangerSight = {
        "npc/combine_soldier/vo/ripcordripcord.wav",
        "npc/combine_soldier/vo/displace.wav",
        "npc/combine_soldier/vo/displace2.wav",
    }

    self.SoundTbl_OnGrenadeSight = {
        "npc/combine_soldier/vo/flaredown.wav",
        "npc/combine_soldier/vo/bouncerbouncer.wav",
    }

    self.SoundTbl_OnKilledEnemy = {
        "npc/combine_soldier/vo/targetcompromisedmovein.wav",
        "npc/combine_soldier/vo/targetblackout.wav",
        "npc/combine_soldier/vo/affirmativewegothimnow.wav",
        "npc/combine_soldier/vo/overwatchconfirmhvtcontained.wav",
        "npc/combine_soldier/vo/overwatchtargetcontained.wav",
        "npc/combine_soldier/vo/overwatchtarget1sterilized.wav",
        "npc/combine_soldier/vo/onecontained.wav",
        "npc/combine_soldier/vo/payback.wav",
    }

    self.SoundTbl_AllyDeath = {
        "npc/combine_soldier/vo/heavyresistance.wav",
        "npc/combine_soldier/vo/overwatchrequestreinforcement.wav",
        "npc/combine_soldier/vo/overwatchrequestreserveactivation.wav",
        "npc/combine_soldier/vo/overwatchrequestskyshield.wav",
        "npc/combine_soldier/vo/overwatchrequestwinder.wav",
        "npc/combine_soldier/vo/overwatchsectoroverrun.wav",
        "npc/combine_soldier/vo/onedutyvacated.wav",
        "npc/combine_soldier/vo/sectorisnotsecure.wav",
        "npc/combine_soldier/vo/onedown.wav",
    }

    self.SoundTbl_Hurt = {
        "npc/combine_soldier/vo/requestmedical.wav",
        "npc/combine_soldier/vo/requeststimdose.wav",
        "npc/combine_soldier/vo/coverhurt.wav",
    }

    self.SoundTbl_Pain = {
        "npc/combine_soldier/pain1.wav",
        "npc/combine_soldier/pain2.wav",
        "npc/combine_soldier/pain3.wav",
        "npc/combine_soldier/vo/requestmedical.wav",
        "npc/combine_soldier/vo/requeststimdose.wav",
        "npc/combine_soldier/vo/coverhurt.wav",
    }

    self.SoundTbl_LostEnemy = {
        "npc/combine_soldier/vo/skyshieldreportslostcontact.wav",
        "npc/combine_soldier/vo/lostcontact.wav",
    }

    self.SoundTbl_Death = {
        "npc/combine_soldier/die1.wav",
        "npc/combine_soldier/die2.wav",
        "npc/combine_soldier/die3.wav",
    }

    self.SoundTbl_RadioOn = {
        "npc/combine_soldier/episodic_vo/on1.wav",
        "npc/combine_soldier/episodic_vo/on2.wav",
    }

    self.SoundTbl_RadioOff = {
        "npc/combine_soldier/episodic_vo/off1.wav",
        "npc/combine_soldier/episodic_vo/off2.wav",
        "npc/combine_soldier/episodic_vo/off2.wav",
    }

    self.SoundTbl_Jump = {
        "mec_jump1",
        "mec_jump2",
        "mec_jump3",
    }

    if math.random(1, 4) == 1 and self.CanBeMedic then
        self.IsMedicSNPC = true
    end

    self.WeaponCheckScheduled = true

    self:SoldierInit()
end

---------------------------------------------------------------------------
-- Target following
---------------------------------------------------------------------------
ENT.FollowTarget = nil
function ENT:SetTarget(target)
    self.FollowTarget = target
end

---------------------------------------------------------------------------
-- SoldierThink (empty placeholder)
---------------------------------------------------------------------------
function ENT:SoldierThink() end

---------------------------------------------------------------------------
-- CustomOnThink: General behavior and medic cover (jump pack removed)
---------------------------------------------------------------------------
function ENT:CustomOnThink()
    self:SoldierThink()
    local pos = self:GetPos()

    if self.TakingCoverT < CurTime() and self:Health() < self:GetMaxHealth() then
        for _, v in pairs(ents.FindInSphere(pos, 1000)) do
            if v:GetClass() == "npc_vj_overwatch_medic" and pos:Distance(v:GetPos()) > 310 then
                local offset = v:GetForward() * math.random(-60, 60) + v:GetRight() * math.random(-60, 60)
                self:SetLastPosition(v:GetPos() + offset)
                if self:GetWeaponState() == VJ_WEP_STATE_RELOADING then self:SetWeaponState() end
                self.TakingCoverT = CurTime() + 2
                canAttack = false
                self:VJ_TASK_GOTO_LASTPOS("TASK_RUN_PATH", function(task)
                    task:EngTask("TASK_FACE_ENEMY", 0)
                    task.CanShootWhenMoving = true
                    task.ConstantlyFaceEnemy = true
                end)
            end
        end
    end

    if IsValid(self.FollowTarget) then
        self:SetLastPosition(self.FollowTarget:GetPos())
        self:VJ_TASK_GOTO_LASTPOS("TASK_RUN_PATH", function(task) task:RunTask() end)
    end

    if self.WeaponCheckScheduled then
        local activeWep = self:GetActiveWeapon()
        if IsValid(activeWep) and activeWep:GetClass() == "weapon_vj_ar2" and self:GetModel() ~= "models/combine_super_soldier.mdl" then
            self.CanUseSecondaryOnWeaponAttack = false
        end
        self.WeaponCheckScheduled = nil
    end
end

---------------------------------------------------------------------------
-- IsNearDropshipDropPoint: Returns true if near a dropship's drop point
---------------------------------------------------------------------------
function ENT:IsNearDropshipDropPoint()
    local pos = self:GetPos()
    for _, dropship in pairs(ents.FindByClass("npc_vj_dropship_z")) do
        if dropship.DropshipDropPoint and dropship.DropshipDropPoint:Distance(pos) < 450 then
            return true
        end
    end
end

---------------------------------------------------------------------------
-- Controller Message
---------------------------------------------------------------------------
function ENT:Controller_IntMsg(ply, controlEnt)
    ply:ChatPrint("ALT (walk key): Deploy  (if available)")
end

---------------------------------------------------------------------------
-- CustomOnPriorToKilled: (пусто)
---------------------------------------------------------------------------
function ENT:CustomOnPriorToKilled(dmginfo, hitgroup)
end

---------------------------------------------------------------------------
-- SetUpGibesOnDeath (пусто)
---------------------------------------------------------------------------
function ENT:SetUpGibesOnDeath(dmginfo, hitgroup) end

---------------------------------------------------------------------------
-- [ФИНАЛЬНАЯ ВЕРСИЯ] ВЗРЫВ + ЗОНА ОГНЯ + ВСПЫШКА + ДОП. УРОН
---------------------------------------------------------------------------
function ENT:CustomOnDeath_BeforeCorpseSpawned(dmginfo, hitgroup)
    local selfPos = self:GetPos()
    local defAngle = Angle(0, 0, 0) -- направление вверх для вспышки

    -- Частицы ионного взрыва
    ParticleEffect("Weapon_Combine_Ion_Cannon_Explosion_f", selfPos, defAngle, nil)
    ParticleEffect("Weapon_Combine_Ion_Cannon_Explosion_j", selfPos, defAngle, nil)

    -- Вспышка как у Advent Purifier
    ParticleEffect("advent_inc_grenade", selfPos, defAngle)

    -- Звуки взрыва для каждого игрока с учётом расстояния
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local dist = ply:GetPos():Distance(selfPos)
            if dist <= 3000 then
                ply:EmitSound(table.Random({
                    "grenade/gren_expl1_close.wav",
                    "grenade/gren_expl3_close.wav"
                }), 150, 90)
            else
                ply:EmitSound(table.Random({
                    "grenade/gren_expl1_distant.wav",
                    "grenade/gren_expl3_dist2.wav"
                }), 150, 100)
            end
        end
    end

    -- Данные для визуальных эффектов
    local effectData = EffectData()
    effectData:SetOrigin(selfPos + self:OBBCenter())
    effectData:SetScale(20)
    effectData:SetFlags(3)
    effectData:SetColor(0)

    util.Effect("Explosion", effectData)
    util.Effect("vj_explosion2", effectData)
    util.Effect("ThumperDust", effectData)
    util.Effect("bloodspray", effectData)
    util.Effect("bloodspray", effectData)

    -- Динамический свет
    local light = ents.Create("light_dynamic")
    light:SetKeyValue("brightness", "4")
    light:SetKeyValue("distance", "300")
    light:SetPos(selfPos)
    light:SetAngles(self:GetAngles())
    light:Fire("Color", "255 150 0")
    light:Spawn()
    light:Activate()
    light:Fire("TurnOn", "", 1)
    self:DeleteOnRemove(light)

    -- Тряска экрана
    util.ScreenShake(selfPos, 100, 200, 1, 2500)

    -- Основной урон VJ
    util.VJ_SphereDamage(self, self, selfPos, 520, 175, DMG_BLAST, true, true, {Force = 150})

    -- Дополнительный урон (радиус 450, урон 25) как у Purifier
    util.BlastDamage(self, self, selfPos, 450, 25)

    -- Декаль подпалины
    local tr = util.TraceLine({
        start = selfPos,
        endpos = selfPos - Vector(0, 0, 50),
        filter = self
    })
    if tr.Hit then
        util.Decal("Scorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
    end

    -- Поджигаем всё в радиусе 600
    for _, ent in ipairs(ents.FindInSphere(selfPos, 600)) do
        if IsValid(ent) and (ent:IsNPC() or ent:IsPlayer() or ent:GetClass() == "prop_physics") then
            ent:Ignite(math.random(12, 20), 0)
        end
    end

    -- Гибы
    self:CreateGibEntity("prop_physics", "models/gibs/strider_gib4.mdl", {Pos = self:LocalToWorld(Vector(0, 0, 30))})
    self:CreateGibEntity("obj_vj_gib", "UseHuman_Big", {Pos = self:LocalToWorld(Vector(0, 0, 35))})
    self:CreateGibEntity("obj_vj_gib", "UseHuman_Small", {Pos = self:LocalToWorld(Vector(10, 5, 40))})
    self:CreateGibEntity("obj_vj_gib", "UseHuman_Small", {Pos = self:LocalToWorld(Vector(-10, -5, 45))})

    -- Удаляем тело NPC
    self:Remove()
end