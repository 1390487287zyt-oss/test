include("shared.lua")

local rig = include("gfl_npc_pack_hydra/rig.lua")
local groundShadow = include("gfl_npc_pack/ground_shadow.lua")
local hydraClass = include("gfl_npc_pack_hydra/spawn.lua").class
local assetPath = "data_static/gfl_hydra_snpc/"
local materialPath = "models/gfl_hydra_snpc/"
local neutralLight = Vector(1, 1, 1)
local maxBatchVertices = 30000
local emissionOffset = 0.24
local auxFlashLifetime = 0.105
local mainFlashLifetime = 0.24
local maxAuxFlashes = 4
local maxAuxPacketAge = 0.35
local auxiliary = rig.attacks[1]
local striderFlash = Material("models/gfl_hydra_snpc/strider_flash")
local renderParts
local meshFailed = false
local activeWeaponEffects = {}

local function expireAuxFlashes(flashes, now)
    for index = #flashes, 1, -1 do
        if now - flashes[index].time >= auxFlashLifetime then
            table.remove(flashes, index)
        end
    end
end

local function presentAuxShot(hydra, now)
    local queue = hydra.HydraPendingAuxShots
    if not queue then return end

    while queue[1] and now - queue[1].serverTime > maxAuxPacketAge do
        table.remove(queue, 1)
    end
    if #queue == 0 then
        hydra.HydraPendingAuxShots = nil
        return
    end

    local nextTime = hydra.HydraNextAuxEffect
    if nextTime and now + 0.0001 < nextTime then return end
    local shot = table.remove(queue, 1)
    if #queue == 0 then hydra.HydraPendingAuxShots = nil end
    -- A client can receive several messages together. Present at most one
    -- per shot interval instead of playing their reports all at once.
    local baseline = nextTime and now - nextTime < auxiliary.interval and nextTime or now
    hydra.HydraNextAuxEffect = baseline + auxiliary.interval

    local flashes = hydra.HydraAuxFlashes or {}
    expireAuxFlashes(flashes, now)
    if #flashes >= maxAuxFlashes then table.remove(flashes, 1) end
    shot.time = now
    flashes[#flashes + 1] = shot
    hydra.HydraAuxFlashes = flashes
    hydra.HydraFiredAt = hydra.HydraFiredAt or {}
    hydra.HydraFiredAt[shot.barrel] = now
    hydra.HydraFrame = nil
    sound.Play(rig.auxFireSound, shot.source, 100, 98, 0.85)
end

local function clearMainFlash(hydra)
    hydra.HydraMainFlash = nil
    local muzzle = hydra.HydraAPCMuzzle
    if not muzzle then return end
    hydra.HydraAPCMuzzle = nil
    hydra:RemoveCallOnRemove("HydraAPCMuzzle")
    if IsValid(muzzle.proxy) then muzzle.proxy:Remove() end
end

local function expireWeaponEffects(hydra, now)
    local flashes = hydra.HydraAuxFlashes
    if flashes then
        expireAuxFlashes(flashes, now)
        if #flashes == 0 then hydra.HydraAuxFlashes = nil end
    end

    local main = hydra.HydraMainFlash
    if main and now - main.time >= mainFlashLifetime then
        clearMainFlash(hydra)
    end
    if not hydra.HydraMainFlash and not hydra.HydraAuxFlashes and not hydra.HydraPendingAuxShots then
        activeWeaponEffects[hydra] = nil
    end
end

hook.Add("Think", "GFLPackHydraWeaponEffectsCleanup", function()
    if not next(activeWeaponEffects) then return end
    local now = CurTime()
    for hydra in pairs(activeWeaponEffects) do
        if IsValid(hydra) then
            presentAuxShot(hydra, now)
            expireWeaponEffects(hydra, now)
        else
            activeWeaponEffects[hydra] = nil
        end
    end
end)

net.Receive(rig.auxShotMessage, function()
    local hydra = net.ReadEntity()
    local barrel = auxiliary.barrels[net.ReadUInt(4) + 1]
    local serverTime = net.ReadFloat()
    local source = net.ReadVector()
    local impact = net.ReadVector()
    if not IsValid(hydra) or hydra:GetClass() ~= hydraClass or hydra.HydraBreaking then return end
    local now = CurTime()
    if now - serverTime > maxAuxPacketAge then return end
    local queue = hydra.HydraPendingAuxShots or {}
    if #queue >= maxAuxFlashes then table.remove(queue, 1) end
    queue[#queue + 1] = {barrel = barrel, serverTime = serverTime, source = source, impact = impact}
    hydra.HydraPendingAuxShots = queue
    activeWeaponEffects[hydra] = true
    presentAuxShot(hydra, now)
end)

net.Receive(rig.mainShotMessage, function()
    local hydra = net.ReadEntity()
    if not IsValid(hydra) or hydra:GetClass() ~= hydraClass or hydra.HydraBreaking then return end
    local now = CurTime()
    hydra.HydraFiredAt = hydra.HydraFiredAt or {}
    hydra.HydraFiredAt.main_gun = now
    hydra.HydraFrame = nil
    hydra.HydraMainFlash = {time = now, pending = true}
    activeWeaponEffects[hydra] = true
end)

local function readMesh(part, armor, emission)
    local path = assetPath .. part.name .. ".txt"
    local reader = file.Open(path, "rb", "GAME")
    if not reader then return nil, "Missing mesh: " .. path end
    local magic, count, faceVertices = reader:Read(4), reader:ReadULong(), reader:ReadULong()
    if magic ~= "HDM1" or count < 3 or count > 65535 or faceVertices < 3
        or faceVertices % 3 ~= 0 or reader:Size() ~= 12 + count * 48 + faceVertices * 2 then
        reader:Close()
        return nil, "Malformed mesh: " .. path
    end

    local vertices, lightVertices = {}, {}
    for index = 1, count do
        local pos = Vector(reader:ReadFloat(), reader:ReadFloat(), reader:ReadFloat()) - part.pivot
        local nx, ny, nz = reader:ReadFloat(), reader:ReadFloat(), reader:ReadFloat()
        local u, v = reader:ReadFloat(), reader:ReadFloat()
        reader:Read(16)
        local direct = math.Clamp(nx * 0.32 - ny * 0.40 + nz * 0.86, 0, 1)
        local shade = math.floor(255 * (0.72 + direct * 0.28) + 0.5)
        local color = Color(shade, shade, shade, 255)
        vertices[index] = {pos = pos, u = u, v = v, color = color}
        -- Keep the light overlay just above the opaque surface to prevent depth flicker.
        local lightPos = pos + Vector(nx, ny, nz) * emissionOffset
        lightVertices[index] = {pos = lightPos, u = u, v = v, color = color}
    end

    local indices = {}
    for index = 1, faceVertices do
        local vert = reader:ReadUShort() + 1
        if vert > count then
            reader:Close()
            return nil, "Invalid mesh index: " .. path
        end
        indices[index] = vert
    end
    reader:Close()

    local batches = {}
    for start = 1, faceVertices, maxBatchVertices do
        local data, lightData = {}, {}
        for index = start, math.min(start + maxBatchVertices - 1, faceVertices) do
            local vert = indices[index]
            data[#data + 1] = vertices[vert]
            lightData[#lightData + 1] = lightVertices[vert]
        end
        local armorMesh, emissionMesh = Mesh(armor), Mesh(emission)
        armorMesh:BuildFromTriangles(data)
        emissionMesh:BuildFromTriangles(lightData)
        batches[#batches + 1] = {armor = armorMesh, emission = emissionMesh}
    end
    return batches
end

local function getRenderParts()
    if renderParts or meshFailed then return renderParts end
    local loaded = {}
    for index, part in ipairs(rig.parts) do
        local stem = materialPath .. "hydra_" .. part.texture
        local armor = Material(stem .. "_armor")
        local emission = Material(stem .. "_emission")
        local batches, problem = readMesh(part, armor, emission)
        if not batches then
            for _, drawable in ipairs(loaded) do
                for _, batch in ipairs(drawable.batches) do
                    batch.armor:Destroy()
                    batch.emission:Destroy()
                end
            end
            ErrorNoHalt("[Hydra] " .. problem .. "\n")
            meshFailed = true
            return nil
        end
        loaded[index] = {armor = armor, emission = emission, batches = batches}
    end
    renderParts = loaded
    return renderParts
end

local function lightChannel(value)
    return 0.15 + 0.85 * math.sqrt(math.Clamp(value, 0, 1))
end

local function sampleLight(position)
    local ok, light = pcall(render.ComputeLighting, position)
    if not ok or not isvector(light) then return neutralLight end
    return Vector(lightChannel(light.x), lightChannel(light.y), lightChannel(light.z))
end

local createDeathWreck = include("gfl_npc_pack_hydra/death_fx.lua")(rig, getRenderParts, sampleLight)
net.Receive(rig.deathMessage, function()
    local hydra = net.ReadEntity()
    local position = net.ReadVector()
    local angle = net.ReadAngle()
    local pose
    if IsValid(hydra) and hydra:GetClass() == hydraClass then
        if hydra.HydraBreaking then return end
        hydra.HydraBreaking = true
        hydra.HydraPendingAuxShots = nil
        hydra.HydraAuxFlashes = nil
        activeWeaponEffects[hydra] = nil
        clearMainFlash(hydra)
        if hydra.HydraPoses and hydra.HydraPoses.lower_body then pose = hydra.HydraPoses end
    end
    createDeathWreck(position, angle, pose)
end)

function ENT:Init()
    self:SetRenderBounds(rig.mins, rig.maxs)
    self:DrawShadow(false)
    self.HydraDrawMatrix = Matrix()
    self.HydraPoses = {}
    self.HydraLight = {}
    self.HydraGaitPhase = 0
    self.HydraGaitWeight = 0
    self.HydraGaitDirection = 1
end

local function updatePose(self, now)
    local frame = FrameNumber()
    if self.HydraFrame == frame then return end
    self.HydraFrame = frame

    local pos = self:GetPos()
    local elapsed = now - self:GetHydraAttackStart()
    local attack = self:GetHydraAttack()
    local profile = rig.attacks[attack]
    local isFiring = profile and elapsed >= 0 and elapsed <= profile.duration
    local dt = math.Clamp(RealFrameTime(), 0.001, 0.075)
    local offset = pos - (self.HydraLastPos or pos)
    local travel = offset:Length2D()
    if travel > rig.maxGaitTravel then travel = 0 end
    self.HydraLastPos = pos

    local movement = math.Clamp(travel / (dt * 125 * rig.moveScale), 0, 1)
    self.HydraGaitWeight = Lerp(math.min(1, dt * 9), self.HydraGaitWeight, isFiring and 0 or movement)
    if travel > 0.05 then
        self.HydraGaitDirection = offset:Dot(self:GetForward()) < -travel * 0.25 and -1 or 1
    end
    if not isFiring then
        self.HydraGaitPhase = (self.HydraGaitPhase + travel / rig.strideDistance) % 1
    end

    local pitch, aimYaw = 0, 0
    if isFiring then
        pitch, aimYaw = rig.AimOffset(attack, self:WorldToLocal(self:GetHydraAttackTarget()))
    end
    rig.Pose(self.HydraPoses, self.HydraGaitPhase, self.HydraGaitWeight, self.HydraGaitDirection,
        attack, elapsed, pitch, aimYaw, false, now, self.HydraFiredAt)
end

local noAngles = Angle(0, 0, 0)
local zeroPosition = Vector(0, 0, 0)

local function getAPCMuzzle(self)
    local muzzle = self.HydraAPCMuzzle
    if muzzle and IsValid(muzzle.proxy) then return muzzle end

    -- The native APC effect reads an engine attachment. Hydra's Lua rig
    -- positions this invisible model so its muzzle matches the visible cannon.
    local proxy = ClientsideModel("models/combine_apc.mdl", RENDERGROUP_OTHER)
    if not IsValid(proxy) then return end
    proxy:SetNoDraw(true)
    proxy:DrawShadow(false)
    proxy:SetupBones()

    local index = proxy:LookupAttachment("muzzle")
    local attachment = index > 0 and proxy:GetAttachment(index)
    if not attachment then
        proxy:Remove()
        return
    end

    local localPos, localAng = WorldToLocal(attachment.Pos, attachment.Ang, proxy:GetPos(), proxy:GetAngles())
    local offset, angles = WorldToLocal(zeroPosition, noAngles, localPos, localAng)
    muzzle = {proxy = proxy, index = index, offset = offset, angles = angles}
    self.HydraAPCMuzzle = muzzle
    self:CallOnRemove("HydraAPCMuzzle", function(_, model)
        if IsValid(model) then model:Remove() end
    end, proxy)
    return muzzle
end

local function drawMainFlash(self, now, position, angle)
    local flash = self.HydraMainFlash
    if not flash or now < (flash.nextUpdate or 0) then return end
    flash.nextUpdate = now + 1 / 30

    local localMuzzle, localAngle = rig.MuzzleLocal(self.HydraPoses, "main_gun")
    local origin, direction = LocalToWorld(localMuzzle, localAngle, position, angle)
    local attachment = getAPCMuzzle(self)
    if attachment then
        local pos, ang = LocalToWorld(attachment.offset, attachment.angles, origin, direction)
        local proxy = attachment.proxy
        proxy:SetPos(pos)
        proxy:SetAngles(ang)
        proxy:InvalidateBoneCache()
        proxy:SetupBones()
    end

    if not flash.pending then return end
    flash.pending = false
    local effect = EffectData()
    effect:SetOrigin(origin)
    effect:SetAngles(direction)
    effect:SetScale(1)
    if attachment then
        effect:SetEntity(attachment.proxy)
        effect:SetAttachment(attachment.index)
        util.Effect("ChopperMuzzleFlash", effect)
    else
        self.HydraMainFlash = nil
        util.Effect("MuzzleEffect", effect)
    end
end

local function drawAuxFlashes(self, now, position, angle)
    local flashes = self.HydraAuxFlashes
    if not flashes then return end

    for _, flash in ipairs(flashes) do
        local age = now - flash.time
        local localMuzzle, localAngle = rig.MuzzleLocal(self.HydraPoses, flash.barrel)
        local muzzle, direction = LocalToWorld(localMuzzle, localAngle, position, angle)
        if flash.impact then
            local tracer = EffectData()
            tracer:SetStart(muzzle)
            tracer:SetOrigin(flash.impact)
            tracer:SetScale(4500)
            util.Effect("StriderTracer", tracer)
            flash.impact = nil
        end

        local strength = 1 - math.Clamp(age / auxFlashLifetime, 0, 1)
        local forward, right, up = direction:Forward(), direction:Right(), direction:Up()
        local color = Color(255, 255, 255, math.floor(255 * strength))
        local center = muzzle + forward * 2.4
        local rays = center + forward * 3.8
        local span = 4.0 * strength
        local tip = 4.5 * strength
        render.SetMaterial(striderFlash)
        render.DrawSprite(center, 6 + 8 * strength, 6 + 8 * strength, color)
        render.DrawSprite(rays + up * span, tip, tip, color)
        render.DrawSprite(rays - up * (span * 0.5) + right * span, tip, tip, color)
        render.DrawSprite(rays - up * (span * 0.5) - right * span, tip, tip, color)
    end
end

local function drawShadowParts(projector, poses)
    for index, drawable in ipairs(renderParts) do
        groundShadow.DrawPart(projector, poses[rig.parts[index].name], drawable.batches, "armor")
    end
end

function ENT:Draw()
    if self.HydraBreaking then return end
    local parts = getRenderParts()
    if not parts then return end
    if not self.HydraPoses then self:Init() end

    local now = CurTime()
    updatePose(self, now)
    if not self.HydraLightTime or now >= self.HydraLightTime then
        for index, part in ipairs(rig.parts) do
            local pose = self.HydraPoses[part.name]
            local sample = LocalToWorld(part.sample - part.pivot, noAngles, pose.pos, pose.ang)
            self.HydraLight[index] = sampleLight(self:LocalToWorld(sample))
        end
        self.HydraLightTime = now + 0.09
    end

    local position, angle = self:GetPos(), self:GetAngles()
    local matrix = self.HydraDrawMatrix
    for index, drawable in ipairs(parts) do
        local pose = self.HydraPoses[rig.parts[index].name]
        local worldPos, worldAng = LocalToWorld(pose.pos, pose.ang, position, angle)
        matrix:SetTranslation(worldPos)
        matrix:SetAngles(worldAng)
        cam.PushModelMatrix(matrix)
        drawable.armor:SetVector("$color", self.HydraLight[index])
        render.SetMaterial(drawable.armor)
        for _, batch in ipairs(drawable.batches) do batch.armor:Draw() end
        cam.PopModelMatrix()
    end
    -- Draw the opaque meshes first so all parts occlude the emissive pass.
    for index, drawable in ipairs(parts) do
        local pose = self.HydraPoses[rig.parts[index].name]
        local worldPos, worldAng = LocalToWorld(pose.pos, pose.ang, position, angle)
        matrix:SetTranslation(worldPos)
        matrix:SetAngles(worldAng)
        cam.PushModelMatrix(matrix)
        render.SetMaterial(drawable.emission)
        for _, batch in ipairs(drawable.batches) do batch.emission:Draw() end
        cam.PopModelMatrix()
    end
    if activeWeaponEffects[self] then expireWeaponEffects(self, now) end
    drawAuxFlashes(self, now, position, angle)
    drawMainFlash(self, now, position, angle)
    groundShadow.Queue(self, position, angle, rig, self.HydraPoses, drawShadowParts)
end
