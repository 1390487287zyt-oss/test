local config = include("gfl_tactical_npcs/config.lua")
local soldierIds = {"kcco_m1", "kcco_m2", "kcco_m3", "kcco_m4"}
local waveSize = 4
local cooldown = 45
local searchRadii = {76, 132, 190}
local hullMins = Vector(-16, -16, 0)
local hullMaxs = Vector(16, 16, 76)
local step = Vector(0, 0, 2)
local floorSearchAbove = Vector(0, 0, 48)
local floorSearchBelow = Vector(0, 0, 96)
local chest = Vector(0, 0, 40)
local minimumSpacingSquared = 48 * 48

local function findWavePositions(commander)
    local origin = commander:GetPos()
    local yaw = commander:GetAngles().y
    local positions = {}
    for ring, radius in ipairs(searchRadii) do
        for direction = 0, 7 do
            local angle = Angle(0, yaw + direction * 45 + (ring - 1) * 22.5, 0)
            local spot = origin + angle:Forward() * radius
            local floor = util.TraceLine({
                start = spot + floorSearchAbove,
                endpos = spot - floorSearchBelow,
                filter = commander,
                mask = MASK_NPCSOLID_BRUSHONLY,
            })
            if floor.Hit and not floor.StartSolid and not floor.HitSky and floor.HitNormal.z >= 0.65 then
                local pos = floor.HitPos + step
                local distinct = true
                for _, reserved in ipairs(positions) do
                    if reserved:DistToSqr(pos) < minimumSpacingSquared then
                        distinct = false
                        break
                    end
                end
                if distinct and util.IsInWorld(pos) then
                    local clearPath = util.TraceLine({
                        start = origin + chest,
                        endpos = pos + chest,
                        filter = commander,
                        mask = MASK_NPCSOLID_BRUSHONLY,
                    })
                    local space = util.TraceHull({
                        start = pos,
                        endpos = pos,
                        mins = hullMins,
                        maxs = hullMaxs,
                        mask = MASK_NPCSOLID,
                    })
                    if not clearPath.Hit and not space.Hit and not space.StartSolid then
                        positions[#positions + 1] = pos
                        if #positions == waveSize then return positions end
                    end
                end
            end
        end
    end
end

local function removeWave(squad)
    for _, soldier in ipairs(squad) do
        if IsValid(soldier) then soldier:Remove() end
    end
end

local function spawnWave(commander, enemy, classes)
    local positions = findWavePositions(commander)
    if not positions then return false end

    local squad = {}
    local targetPosition = enemy:GetPos()
    for _, pos in ipairs(positions) do
        local soldier = ents.Create(classes[math.random(#classes)])
        if not IsValid(soldier) then
            removeWave(squad)
            return false
        end
        local facing = (targetPosition - pos):Angle()
        soldier:SetPos(pos)
        soldier:SetAngles(Angle(0, facing.y, 0))
        squad[#squad + 1] = soldier
    end
    for _, soldier in ipairs(squad) do
        soldier:Spawn()
        if not IsValid(soldier) then
            removeWave(squad)
            return false
        end
        soldier:Activate()
        if not IsValid(soldier) then
            removeWave(squad)
            return false
        end
    end
    if IsValid(commander) and IsValid(enemy) and commander:CheckRelationship(enemy) == D_HT then
        for _, soldier in ipairs(squad) do
            soldier:ForceSetEnemy(enemy)
        end
    end
    return true
end

return function(ent, side)
    local classes = {}
    for _, id in ipairs(soldierIds) do
        classes[#classes + 1] = config.Variant(id, side).class
    end

    function ent:OnDamaged(damage, _, status)
        if status == "PreDamage" then
            damage:ScaleDamage(0.5)
        end
    end

    function ent:OnThinkActive()
        local now = CurTime()
        if self.Dead or self:Health() <= 0 or now < (self.GFLTacticalNextReinforcement or 0) then return end

        local enemy = self:GetEnemy()
        if not IsValid(enemy) or self:CheckRelationship(enemy) ~= D_HT then return end
        self.GFLTacticalNextReinforcement = now + 0.5
        if self:Visible(enemy) and spawnWave(self, enemy, classes) and IsValid(self) then
            self.GFLTacticalNextReinforcement = now + cooldown
        end
    end
end
