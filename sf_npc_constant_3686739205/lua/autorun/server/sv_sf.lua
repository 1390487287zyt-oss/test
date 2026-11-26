--[[
    ADVENT Officer — Mark Target System
    Файл: lua/autorun/server/sv_advent_mark_target.lua

    Глобальная таблица помеченных целей.
    ADVENT_MarkedTargets[entity] = expireTime
]]

if CLIENT then return end

ADVENT_MarkedTargets = ADVENT_MarkedTargets or {}

-- Базовый разброс ADVENT-солдат (соответствует ENT.WeaponSpread в их init.lua)
local BASE_SPREAD   = 1
local MARKED_SPREAD = 0.5  -- В 2 раза точнее

--==============================================================================
-- Утилиты
--==============================================================================

--- Проверяет, помечена ли цель сейчас
local function IsMarked(ent)
    if not IsValid(ent) then return false end
    local t = ADVENT_MarkedTargets[ent]
    return t ~= nil and CurTime() < t
end

--- Удаляет спрайт-маркер с сущности
local function RemoveMarkerSprite(ent)
    if not IsValid(ent) then return end
    local spr = ent.ADVENT_MarkSprite
    if IsValid(spr) then
        spr:Remove()
        ent.ADVENT_MarkSprite = nil
    end
end

local function AttachMarkerSprite(ent)
    RemoveMarkerSprite(ent)

    if ent:IsPlayer() then
        -- Спрайт не создаём для самого игрока
        ent.ADVENT_MarkSprite = nil
        return
    end

    local spr = ents.Create("env_sprite")
    if not IsValid(spr) then return end

    spr:SetKeyValue("model",        "sprites/redglow1.vmt")
    spr:SetKeyValue("rendermode",   "5")
    spr:SetKeyValue("rendercolor",  "255 80 80")
    spr:SetKeyValue("renderamt",    "220")
    spr:SetKeyValue("scale",        "2")
    spr:SetKeyValue("GlowProxySize","2")
    spr:SetKeyValue("spawnflags",   "1")

    spr:SetPos(ent:GetPos() + ent:OBBCenter())
    spr:SetParent(ent)
    spr:Spawn()
    spr:Activate()

    local att = ent:LookupAttachment("chest")
    if att and att > 0 then
        spr:Fire("SetParentAttachment", "chest")
    end

    ent.ADVENT_MarkSprite = spr
end

-- Снимаем метку при смерти любого игрока
hook.Add("PlayerDeath", "ADVENT_MarkTarget_PlayerDeath", function(ply)
    if IsMarked(ply) then
        ADVENT_MarkedTargets[ply] = nil
        RemoveMarkerSprite(ply)
    end
end)

-- Снимаем метку при удалении NPC/игрока
hook.Add("EntityRemoved", "ADVENT_MarkTarget_EntityRemoved", function(ent)
    if IsMarked(ent) then
        ADVENT_MarkedTargets[ent] = nil
        RemoveMarkerSprite(ent)
    end
end)

--==============================================================================
-- Основная функция отметки
--==============================================================================

local MARK_DURATION = 15  -- секунд
local MARK_COOLDOWN = 35  -- секунд

--- Отмечает цель. Вызывается офицером.
local function MarkTarget(officer, target)
    if not IsValid(officer) or not IsValid(target) then return end

    -- Кулдаун
    local curTime = CurTime()
    if (officer.ADVENT_NextMarkTime or 0) > curTime then return end
    officer.ADVENT_NextMarkTime = curTime + MARK_COOLDOWN

    -- Уже помечена?
    if IsMarked(target) then return end

    --== 1. Анимация офицера ==--
    officer:PlayAnim("signal_advance", true, false, true)

    --== 2. Звук ==--
    sound.Play("misc/officer_mark.wav", officer:GetPos(), 80, 100, 1)

    --== 3. Спрайт на цели ==--
    AttachMarkerSprite(target)

    --== 4. Регистрируем метку ==--
    local expireAt = curTime + MARK_DURATION
    ADVENT_MarkedTargets[target] = expireAt

    --== 5. Оповещаем всех CLASS_ADVENT о цели ==--
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.IsVJBaseSNPC and ent ~= officer then
            local classes = ent.VJ_NPC_Class
            if classes then
                local isAdvent = false
                for _, cls in ipairs(classes) do
                    if cls == "CLASS_ADVENT" then
                        isAdvent = true
                        break
                    end
                end
                if isAdvent and ent:Alive() then
                    -- Передаём знание о противнике
                    ent:ForceSetEnemy(target, false)
                end
            end
        end
    end

    --== 6. Снимаем метку через MARK_DURATION секунд ==--
    timer.Create("ADVENT_MarkExpire_" .. target:EntIndex(), MARK_DURATION, 1, function()
        ADVENT_MarkedTargets[target] = nil
        RemoveMarkerSprite(target)

        -- Возвращаем базовый разброс всем CLASS_ADVENT
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent.IsVJBaseSNPC then
                local classes = ent.VJ_NPC_Class
                if classes then
                    for _, cls in ipairs(classes) do
                        if cls == "CLASS_ADVENT" then
                            if ent.WeaponSpread == MARKED_SPREAD then
                                ent.WeaponSpread = BASE_SPREAD
                            end
                            break
                        end
                    end
                end
            end
        end
    end)
end

--==============================================================================
-- Хук: обновление разброса для CLASS_ADVENT при стрельбе по помеченной цели
-- Вешаем через ENT:CustomOnThink перехватить невозможно напрямую для чужих NPC,
-- поэтому используем глобальный хук Think.
--==============================================================================

hook.Add("Think", "ADVENT_MarkTarget_SpreadUpdate", function()
    -- Чистим просроченные метки
    local curTime = CurTime()
    for ent, expireAt in pairs(ADVENT_MarkedTargets) do
        if not IsValid(ent) or curTime >= expireAt then
            RemoveMarkerSprite(ent)
            ADVENT_MarkedTargets[ent] = nil
        end
    end

    -- Обновляем разброс для всех CLASS_ADVENT
    for _, npc in ipairs(ents.GetAll()) do
        if IsValid(npc) and npc.IsVJBaseSNPC and npc:Alive() then
            local classes = npc.VJ_NPC_Class
            if classes then
                local isAdvent = false
                for _, cls in ipairs(classes) do
                    if cls == "CLASS_ADVENT" then isAdvent = true break end
                end

                if isAdvent then
                    local enemy = npc:GetEnemy()
                    if IsValid(enemy) and IsMarked(enemy) then
                        npc.WeaponSpread = MARKED_SPREAD -- В 2 раза точнее
                    else
                        -- Возвращаем базовый только если он был изменён нами
                        if npc.WeaponSpread == MARKED_SPREAD then
                            npc.WeaponSpread = BASE_SPREAD
                        end
                    end
                end
            end
        end
    end
end)
--==============================================================================
-- Экспортируем функцию для использования в init.lua офицера
--==============================================================================

ADVENT_MarkTarget = MarkTarget
ADVENT_IsMarked   = IsMarked
