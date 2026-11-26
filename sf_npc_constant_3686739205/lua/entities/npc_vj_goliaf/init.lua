AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.Model = "models/golyat.mdl"
util.PrecacheModel(ENT.Model)

ENT.StartHealth = 500
ENT.HullType = HULL_MEDIUM

ENT.VJ_NPC_Class = {"CLASS_SANGVIS"}
ENT.BloodColor = "Oil"

ENT.AllowIgnition = false
ENT.Immune_Sonic = true
ENT.Immune_Dissolve = true

-- Отключаем стандартные атаки (логика камикадзе — через Think)
ENT.HasMeleeAttack = false
ENT.HasLeapAttack = false
ENT.HasRangeAttack = false
ENT.HasGrenadeAttack = false

-- Кровь и флинч отключены для надёжности
ENT.Bleeds = false
ENT.HasBloodParticle = false
ENT.HasBloodDecal = false
ENT.HasBloodPool = false
ENT.CanFlinch = false

-- Не взаимодействуем с пропами
ENT.PropInteraction = false

-- Смерть — сразу взрыв, без трупа
ENT.HasDeathCorpse = false
ENT.HasDeathAnimation = false
ENT.HasDeathRagdoll = false
ENT.HasGibOnDeath = true
ENT.GibOnDeathDamagesTable = {"UseDefault"}

-- Всегда смотрим на врага и быстро бежим
ENT.ConstantlyFaceEnemy = true
ENT.WalkSpeed = 20
ENT.RunSpeed = 300

-- Анимации
ENT.AnimTbl_IdleStand = {ACT_IDLE}
ENT.FootstepSoundTimerWalk = 0.4
ENT.FootstepSoundTimerRun = 0.2

-- Звуки (из нового набора)
ENT.SoundTbl_FootStep = {
    "sfx/golyat/footstep1.wav",
    "sfx/golyat/footstep2.wav",
    "sfx/golyat/footstep3.wav",
    "sfx/golyat/footstep4.wav",
    "sfx/golyat/footstep5.wav"
}
ENT.SoundTbl_Death = {
    "sfx/golyat/explode1.wav",
    "sfx/golyat/explode2.wav",
    "sfx/golyat/explode3.wav"
}
ENT.SoundTbl_Alert = {"sfx/golyat/explode1.wav"}

-- Дополнительный параметр для шкурки
ENT.GolyatSkin = 0

-----------------------------------------------------------------------------
-- Взрыв (используется и при самоподрыве, и при смерти)
-----------------------------------------------------------------------------
function ENT:Explode()
    if self.Exploded then return end
    self.Exploded = true

    local selfPos = self:GetPos()
    local defAngle = Angle(math.random(-90, 90), math.random(-90, 90), math.random(-90, 90))

    -- Частицы
    ParticleEffect("Weapon_Combine_Ion_Cannon_Explosion_f", selfPos, defAngle, nil)
    ParticleEffect("Weapon_Combine_Ion_Cannon_Explosion_j", selfPos, defAngle, nil)

    -- Звук взрыва (один из звуков смерти)
    self:EmitSound(table.Random(self.SoundTbl_Death), 100, 100)

    -- Эффекты
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

    -- Урон по области (радиус 520, урон 475)
    util.VJ_SphereDamage(self, self, selfPos, 520, 475, DMG_BLAST, true, true, {Force = 350})

    self:Remove()
end

-----------------------------------------------------------------------------
-- Инициализация
-----------------------------------------------------------------------------
function ENT:CustomOnInitialize()
    -- Устанавливаем шкурку
    self:SetSkin(self.GolyatSkin)

    -- Флаг, чтобы взрыв не срабатывал дважды
    self.Exploded = false
end

-----------------------------------------------------------------------------
-- Поведение: при появлении врага бежим к нему, вблизи взрываемся
-----------------------------------------------------------------------------
function ENT:CustomOnThink()
    if self.Exploded then return end
    local enemy = self:GetEnemy()
    if IsValid(enemy) then
        local dist = self:GetPos():Distance(enemy:GetPos())
        if dist < 150 then
            self:Explode()
        end
    end
end

-----------------------------------------------------------------------------
-- Взрыв при смерти (если не взорвался раньше)
-----------------------------------------------------------------------------
function ENT:CustomOnDeath_BeforeCorpseSpawned(dmginfo, hitgroup)
    if not self.Exploded then
        self:Explode()
    end
end

-- Заглушки для отключённых атак
function ENT:CustomOnRangeAttack() end
function ENT:CustomOnMeleeAttack() end