local config = include("gfl_ares/config.lua")
local rig = include("gfl_ares/rig.lua")
local meshes = include("gfl_ares/meshes.lua")
local groundShadow = include("gfl_npc_pack/ground_shadow.lua")
local profile = config.profiles[ENT.AA02Class]
local hasMainCannon = profile.cannonShots > 0
local zero, zeroAngles = Vector(), Angle()
local white = Vector(1, 1, 1)
local drawShield = include("gfl_ares/shield.lua")
local beam = Material("sprites/bluelaser1")
local chargeWarp = Material("particle/warp5_warp")
local chargeCore = Material("sprites/strider_blackball")
local glow = Material("sprites/light_glow02_add")
local strider = Material("models/gfl_hydra_snpc/strider_flash")
local mainPoint = Vector(0, 0, 103)

local function isAA02(ent)
    return IsValid(ent) and config.profiles[ent:GetClass()] ~= nil
end

local function kickAPC(self, index, source, angles)
    self.AA02FlashProxies = self.AA02FlashProxies or {}
    local mount = self.AA02FlashProxies[index]
    if not mount then
        local model = ClientsideModel("models/combine_apc.mdl", RENDERGROUP_OTHER)
        if IsValid(model) then
            model:SetNoDraw(true)
            model:DrawShadow(false)
            model:SetupBones()
            local id = model:LookupAttachment("muzzle")
            local attachment = id > 0 and model:GetAttachment(id)
            if attachment then
                local pos, ang = WorldToLocal(attachment.Pos, attachment.Ang, model:GetPos(), model:GetAngles())
                local offset, rotation = WorldToLocal(zero, zeroAngles, pos, ang)
                mount = {model = model, id = id, offset = offset, rotation = rotation}
                self.AA02FlashProxies[index] = mount
                self:CallOnRemove("AA02APCMuzzle_" .. index, function(_, proxy)
                    if IsValid(proxy) then proxy:Remove() end
                end, model)
            else
                model:Remove()
            end
        end
    end
    local effect = EffectData()
    effect:SetOrigin(source)
    effect:SetAngles(angles)
    effect:SetScale(1)
    if mount and IsValid(mount.model) then
        local pos, angle = LocalToWorld(mount.offset, mount.rotation, source, angles)
        local model = mount.model
        model:SetPos(pos)
        model:SetAngles(angle)
        model:InvalidateBoneCache()
        model:SetupBones()
        effect:SetEntity(model)
        effect:SetAttachment(mount.id)
        util.Effect("ChopperMuzzleFlash", effect)
    else
        util.Effect("MuzzleEffect", effect)
    end
end

net.Receive(config.shotMessage, function()
    local ent = net.ReadEntity()
    local skill, index, time = net.ReadUInt(2), net.ReadUInt(2) + 1, net.ReadFloat()
    local source, impact = net.ReadVector(), net.ReadVector()
    if not isAA02(ent) or (skill ~= 1 and skill ~= 2) or CurTime() - time > .6 then return end
    ent.AA02Fired = ent.AA02Fired or {}
    ent.AA02Flashes = ent.AA02Flashes or {}
    local kind = skill == 2 and "rocket" or config.attacks[1].ports[index]
    ent.AA02Fired[kind] = time
    local dir = (impact - source):Angle()
    if skill == 2 then
        kickAPC(ent, index, source, dir)
        return
    end
    ent.AA02Flashes[kind] = {pos = source, time = time}
    local tracer = EffectData()
    tracer:SetStart(source)
    tracer:SetOrigin(impact)
    tracer:SetScale(6400)
    util.Effect("StriderTracer", tracer)
end)

net.Receive(config.laserMessage, function()
    local entity, time = net.ReadEntity(), net.ReadFloat()
    local source, impact = net.ReadVector(), net.ReadVector()
    local normal, hit = net.ReadNormal(), net.ReadBool()
    if CurTime() - time > .6 then return end
    if isAA02(entity) then
        if config.profiles[entity:GetClass()].cannonShots == 0 then return end
        entity.AA02Fired = entity.AA02Fired or {}
        entity.AA02Fired.main = time
    end

    local effect = EffectData()
    effect:SetStart(source)
    effect:SetOrigin(impact)
    effect:SetNormal(normal)
    effect:SetFlags(hit and 0 or 1)
    util.Effect("gfl_aa02_warp_cannon", effect)
end)

local destroyed = {}
net.Receive(config.deathMessage, function()
    local ent, pos, angle = net.ReadEntity(), net.ReadVector(), net.ReadAngle()
    local mainCannon = net.ReadBool()
    if isAA02(ent) then ent.AA02Destroyed = true end
    local effect = EffectData()
    effect:SetOrigin(pos + Vector(0, 0, 83))
    effect:SetMagnitude(5)
    effect:SetScale(2)
    util.Effect("ManhackSparks", effect)
    if #destroyed >= 4 then table.remove(destroyed, 1) end
    destroyed[#destroyed + 1] = {
        pos = pos, angle = angle, start = CurTime(), pose = {}, matrix = Matrix(), mainCannon = mainCannon,
    }
end)

local function environment(position)
    local ok, light = pcall(render.ComputeLighting, position)
    if not ok or not isvector(light) then return white end
    local function channel(n) return .12 + .88 * math.sqrt(math.Clamp(n, 0, 1)) end
    return Vector(channel(light.x), channel(light.y), channel(light.z))
end

local function drawBody(poses, matrix, position, angle, lower, upper, abandoned, mainCannon)
    local parts, seams = meshes.Body()
    if not parts then return false end
    for id, group in ipairs(parts) do
        if mainCannon or not group.mainCannon then
            local pose = poses[id]
            local light = pose.pos.z < 77 and lower or upper
            local origin, orientation = LocalToWorld(pose.pos, pose.ang, position, angle)
            matrix:SetTranslation(origin)
            matrix:SetAngles(orientation)
            cam.PushModelMatrix(matrix)
            for _, batch in ipairs(group) do
                batch.material:SetVector("$color", batch.luminous and (abandoned and Vector(.018,.035,.05) or Vector(.09,.42,1)) or light)
                render.SetMaterial(batch.material)
                batch.mesh:Draw()
            end
            cam.PopModelMatrix()
        end
    end
    matrix:SetTranslation(position)
    matrix:SetAngles(angle)
    cam.PushModelMatrix(matrix)
    for _, seam in ipairs(seams) do
        seam.material:SetVector("$color", lower)
        render.SetMaterial(seam.material)
        mesh.Begin(MATERIAL_TRIANGLES, #seam.verts / 3)
        for _, v in ipairs(seam.verts) do
            local pose = poses[v.part]
            mesh.Position(LocalToWorld(v.pos, zeroAngles, pose.pos, pose.ang))
            mesh.TexCoord(0, v.u, v.v)
            mesh.Color(v.color.r, v.color.g, v.color.b, 255)
            mesh.AdvanceVertex()
        end
        mesh.End()
    end
    cam.PopModelMatrix()
    return true
end

hook.Add("PostDrawOpaqueRenderables", "GFL_AA02_Wreck", function(depth, sky)
    if depth or sky then return end
    local now = CurTime()
    for index = #destroyed, 1, -1 do
        local wreck = destroyed[index]
        local age = now - wreck.start
        if age >= 6 then
            table.remove(destroyed, index)
        elseif EyePos():DistToSqr(wreck.pos) < 4500 ^ 2 then
            local collapse = math.Clamp(age / 1.15, 0, 1)
            local sink = math.max(0, age - 4.45) * 130
            rig.Pose(wreck.pose, 0, 0, 0, 0, 0, zeroAngles, {}, collapse, 0)
            local light = wreck.light or environment(wreck.pos + mainPoint)
            wreck.light = light
            drawBody(wreck.pose, wreck.matrix, wreck.pos - Vector(0, 0, sink), wreck.angle, light, light, true, wreck.mainCannon)
        end
    end
end)

hook.Add("PostCleanupMap", "GFL_AA02_ClearWreck", function() destroyed = {} end)

function ENT:Init()
    self:DrawShadow(false)
    self:SetRenderBounds(rig.mins, rig.maxs)
    self.AA02Matrix = Matrix()
    self.AA02Pose = {}
    self.AA02Travel, self.AA02Move = 0, 0
end

local function updatePose(self, now, pos)
    local frame = FrameNumber()
    if frame == self.AA02DrawFrame then return end
    self.AA02DrawFrame = frame
    local skill = self:GetAA02Skill()
    if skill > #profile.cooldowns then skill = 0 end
    local t = (now - self:GetAA02SkillStart()) * profile.speed
    local stunLeft = self:GetAA02StunEnd() - now
    local stagger = 0
    if skill == 0 and stunLeft > 0 then
        self.AA02StaggerStart = self.AA02StaggerStart or now
        stagger = math.Clamp((now - self.AA02StaggerStart) / .73, 0, 1) * math.Clamp(stunLeft / .9, 0, 1)
    else
        self.AA02StaggerStart = nil
    end
    local delta = pos - (self.AA02LastPos or pos)
    local travel = delta:Length2D()
    if travel > 95 then travel = 0 end
    self.AA02LastPos = pos
    local dt = math.Clamp(RealFrameTime(), .001, .075)
    local fullGaitSpeed = 95 * config.groundMoveScale
    local move = skill == 0 and stunLeft <= 0 and math.Clamp(travel / (dt * fullGaitSpeed), 0, 1) or 0
    self.AA02Move = Lerp(math.min(1, dt * 8), self.AA02Move, move)
    local direction = delta:Dot(self:GetForward()) < -travel * .25 and -1 or 1
    -- The slower server motion advances the same stride over more time.
    self.AA02Travel = (self.AA02Travel + travel * direction) % (rig.stride * 300)
    local fired = {}
    for port, time in pairs(self.AA02Fired or {}) do
        if port ~= "main" or profile.cannonShots > 0 then fired[port] = now - time end
    end
    local target = self:WorldToLocal(self:GetAA02Aim())
    local aim = (target - mainPoint):Angle()
    local brace = self:GetAA02ShieldHP() > 0 and math.Clamp(1 - math.abs(now - self:GetAA02ShieldStart() - .26) / .45, 0, 1) or 0
    rig.Pose(self.AA02Pose, (self.AA02Travel / rig.stride) % 1, self.AA02Move, self.AA02Travel,
        skill, t, aim, fired, stagger, brace, profile.cannonShots, target)
end

local function drawShadowParts(projector, poses)
    local parts, seams = meshes.Body()
    for id, group in ipairs(parts) do
        if hasMainCannon or not group.mainCannon then
            groundShadow.DrawPart(projector, poses[id], group, "mesh")
        end
    end
    for _, seam in ipairs(seams) do groundShadow.DrawSeams(projector, poses, seam.verts) end
end

function ENT:Draw()
    if self.AA02Destroyed then return end
    if not self.AA02Pose then self:Init() end
    local now, pos, angle = CurTime(), self:GetPos(), self:GetAngles()
    updatePose(self, now, pos)
    if not self.AA02LightAt or now >= self.AA02LightAt then
        self.AA02LightAt = now + .11
        self.AA02Lower = environment(self:LocalToWorld(Vector(4, 0, 38)))
        self.AA02Upper = environment(self:LocalToWorld(mainPoint))
    end
    if drawBody(self.AA02Pose, self.AA02Matrix, pos, angle, self.AA02Lower, self.AA02Upper, false, hasMainCannon) then
        groundShadow.Queue(self, pos, angle, rig, self.AA02Pose, drawShadowParts)
    else
        self:DrawModel()
    end
end

function ENT:DrawTranslucent()
    if self.AA02Destroyed then return end
    local now = CurTime()
    drawShield(self, now)
    for slot, flash in pairs(self.AA02Flashes or {}) do
        local strength = 1 - (now - flash.time) / .125
        if strength <= 0 then
            self.AA02Flashes[slot] = nil
        elseif strength <= 1 then
            local size = 11 + 21 * strength
            render.SetMaterial(strider)
            render.DrawSprite(flash.pos, size, size, Color(255, 232, 201, 255 * strength))
        end
    end
    if profile.cannonShots == 0 or self:GetAA02Skill() ~= 3 or not self.AA02Pose or not self.AA02Pose[1] then return end
    local attack = config.attacks[3]
    local elapsed = (now - self:GetAA02SkillStart()) * profile.speed
    local charge
    if elapsed < attack.windup then
        charge = elapsed / attack.windup
    elseif profile.cannonShots == 2 and elapsed < config.lastShotTime(3, profile) then
        charge = (elapsed - attack.windup) / attack.interval
    end
    if not charge or charge <= .22 then return end

    local localMuzzle = rig.Muzzle(self.AA02Pose, "main")
    local muzzle = self:LocalToWorld(localMuzzle)
    local trace = util.TraceLine({start = muzzle, endpos = self:GetAA02Aim(), mask = MASK_SOLID_BRUSHONLY, filter = self})
    render.SetMaterial(chargeWarp)
    local ripple = charge ^ 2 * 185
    render.DrawSprite(muzzle, ripple, ripple, Color(255, 255, 255, 110))
    render.SetMaterial(glow)
    local flare = charge * 105
    render.DrawSprite(muzzle, flare, flare, Color(55, 185, 255, 205))
    render.SetMaterial(chargeCore)
    local core = charge * 43
    render.DrawSprite(muzzle, core, core, Color(255, 255, 255, 240 * charge))
    render.SetMaterial(beam)
    render.DrawBeam(muzzle, trace.HitPos, 1 + charge ^ 2 * 5, 0, 1, Color(120, 220, 255, 170 * charge))
end
