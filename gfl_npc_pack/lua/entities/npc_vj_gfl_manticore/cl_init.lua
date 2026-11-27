include("shared.lua")

local rig = include("gfl_manticore_snpc/rig.lua")
local groundShadow = include("gfl_npc_pack/ground_shadow.lua")
local meshPath = "data_static/gfl_manticore_snpc/"
local materialPath = "models/gfl_manticore_snpc/"
local material = {
    body = Material(materialPath .. "body"), leg = Material(materialPath .. "leg"),
    dark = Material(materialPath .. "dark"), lamp = Material(materialPath .. "lamp"),
}
local zero = Angle(0, 0, 0)
local fallbackLight = Vector(.24, .24, .24)
local chassisLightPoint = Vector(-14, 0, 70)
local renderParts, seams, meshFailed

local function readVertex(reader, lamp)
    local pos = Vector(reader:ReadFloat(), reader:ReadFloat(), reader:ReadFloat())
    local nx, ny, nz = reader:ReadFloat(), reader:ReadFloat(), reader:ReadFloat()
    local u, v = reader:ReadFloat(), reader:ReadFloat()
    local shade = lamp and 255 or 255 * (0.73 + 0.27 * math.Clamp(nx * 0.36 - ny * 0.38 + nz * 0.86, 0, 1))
    return pos, u, v, shade
end

local function readMesh(part, group)
    local source = meshPath .. part.name .. "_" .. group .. ".txt"
    local reader = file.Open(source, "rb", "GAME")
    if not reader then return nil, source end
    local magic, vertexCount, indexCount = reader:Read(4), reader:ReadULong(), reader:ReadULong()
    if magic ~= "MCM1" or vertexCount < 3 or vertexCount > 65535
        or indexCount < 3 or indexCount > 30000 or indexCount % 3 ~= 0
        or reader:Size() ~= 12 + vertexCount * 44 + indexCount * 2 then
        reader:Close()
        return nil, source
    end

    local vertices, triangles = {}, {}
    for i = 1, vertexCount do
        local pos, u, v, shade = readVertex(reader, group == "lamp")
        local r, g, b = reader:ReadFloat(), reader:ReadFloat(), reader:ReadFloat()
        vertices[i] = {pos = pos, u = u, v = v, color = Color(shade * r, shade * g, shade * b, 255)}
    end
    for i = 1, indexCount do
        local vertex = vertices[reader:ReadUShort() + 1]
        if not vertex then reader:Close() return nil, source end
        triangles[i] = vertex
    end
    reader:Close()
    local model = Mesh(material[group])
    model:BuildFromTriangles(triangles)
    return model
end

local function readSeams()
    local reader = file.Open(meshPath .. "seams.txt", "rb", "GAME")
    if not reader then return end
    local magic, count = reader:Read(4), reader:ReadULong()
    if magic ~= "MCS1" or count < 3 or count > 1024 or count % 3 ~= 0 or reader:Size() ~= 8 + count * 33 then
        reader:Close()
        return
    end
    local vertices = {}
    for i = 1, count do
        local part = rig.parts[reader:ReadByte()]
        if not part then reader:Close() return end
        local pos, u, v, shade = readVertex(reader, false)
        vertices[i] = {part = part.name, pos = pos, u = u, v = v, shade = shade}
    end
    reader:Close()
    return vertices
end

local function getRenderParts()
    if renderParts or meshFailed then return renderParts end
    local parts = {}
    seams = readSeams()
    if not seams then
        meshFailed = true
        ErrorNoHalt("[Manticore] Missing or invalid seam mesh.\n")
        return
    end
    for index, part in ipairs(rig.parts) do
        local groups = {}
        parts[index] = groups
        for _, group in ipairs(part.groups) do
            local model, badFile = readMesh(part, group)
            if not model then
                for _, list in ipairs(parts) do
                    for _, data in ipairs(list) do data.model:Destroy() end
                end
                meshFailed = true
                ErrorNoHalt("[Manticore] Missing or invalid mesh: " .. badFile .. "\n")
                return
            end
            groups[#groups + 1] = {group = group, model = model}
        end
    end
    renderParts = parts
    return renderParts
end

local function lightValue(value)
    return 0.035 + 0.965 * math.Clamp(value, 0, 1) ^ .74
end

local function sampleLight(pos, chassisLight)
    local light = render.ComputeLighting(pos)
    if not isvector(light) then light = chassisLight or fallbackLight end
    if chassisLight then light = light * .55 + chassisLight * .45 end
    return Vector(lightValue(light.x), lightValue(light.y), lightValue(light.z))
end

local function drawPart(groups, light, powered)
    for _, batch in ipairs(groups) do
        local key = batch.group
        local mat = material[key]
        if key == "lamp" and not powered then key, mat = "dark", material.dark end
        if key == "dark" then
            mat:SetVector("$color", Vector(.045 * light.x, .048 * light.y, .051 * light.z))
        elseif key ~= "lamp" then
            mat:SetVector("$color", light)
        end
        render.SetMaterial(mat)
        batch.model:Draw()
    end
end

local function drawSeams(poses, light, matrix, pos, angle)
    matrix:SetTranslation(pos)
    matrix:SetAngles(angle)
    cam.PushModelMatrix(matrix)
    local mat = material.leg
    mat:SetVector("$color", light)
    render.SetMaterial(mat)
    -- Only 64 faces span two bone groups. Skin those faces and keep the rigid meshes cached.
    mesh.Begin(MATERIAL_TRIANGLES, #seams / 3)
    for _, vertex in ipairs(seams) do
        local pose = poses[vertex.part]
        mesh.Position(LocalToWorld(vertex.pos, zero, pose.pos, pose.ang))
        mesh.TexCoord(0, vertex.u, vertex.v)
        mesh.Color(vertex.shade, vertex.shade, vertex.shade, 255)
        mesh.AdvanceVertex()
    end
    mesh.End()
    cam.PopModelMatrix()
end

local spawnWreck = include("gfl_manticore_snpc/death_fx.lua")(rig, getRenderParts, sampleLight, drawPart)
net.Receive(rig.deathMessage, function()
    local entity, pos, angle = net.ReadEntity(), net.ReadVector(), net.ReadAngle()
    local poses
    if IsValid(entity) and entity:GetClass() == "npc_vj_gfl_manticore" then
        if entity.ManticoreBreaking then return end
        entity.ManticoreBreaking = true
        if entity.ManticorePoses and entity.ManticorePoses.body then poses = entity.ManticorePoses end
    end
    spawnWreck(pos, angle, poses)
end)

net.Receive(rig.shotMessage, function()
    local entity, source, impact = net.ReadEntity(), net.ReadVector(), net.ReadVector()
    if IsValid(entity) and entity:GetClass() == "npc_vj_gfl_manticore" then
        if entity.ManticoreBreaking then return end
        entity.ManticoreFiredAt = CurTime()
        entity.ManticoreFrame = nil
    end
    local muzzle = EffectData()
    muzzle:SetOrigin(source)
    muzzle:SetAngles((impact - source):Angle())
    muzzle:SetScale(1)
    util.Effect("MuzzleEffect", muzzle)
    local tracer = EffectData()
    tracer:SetStart(source)
    tracer:SetOrigin(impact)
    tracer:SetScale(6200)
    util.Effect("GaussTracer", tracer)
end)

local function updatePose(self, now, pos)
    local frame = FrameNumber()
    if self.ManticoreFrame == frame then return end
    self.ManticoreFrame = frame
    local started = self:GetManticoreAttackStart()
    local elapsed = started > 0 and now - started or -1
    local firing = elapsed >= 0 and elapsed < rig.attackDuration
    local dt = math.Clamp(RealFrameTime(), 0.001, 0.075)
    local offset = pos - (self.ManticoreLastPos or pos)
    self.ManticoreLastPos = pos
    local travel = offset:Length2D()
    if travel > 100 then travel = 0 end
    local movement = math.Clamp(travel / (dt * 72), 0, 1)
    self.ManticoreGaitWeight = Lerp(math.min(1, dt * 9), self.ManticoreGaitWeight, firing and 0 or movement)
    if not firing and travel > 0.03 then
        self.ManticoreGaitPhase = (self.ManticoreGaitPhase + travel / rig.strideDistance) % 1
        self.ManticoreDirection = offset:Dot(self:GetForward()) < -travel * 0.25 and -1 or 1
    end
    local pitch, yaw = 0, 0
    if firing then pitch, yaw = rig.AimOffset(self:WorldToLocal(self:GetManticoreAttackTarget())) end
    local firedAgo = self.ManticoreFiredAt and now - self.ManticoreFiredAt
    rig.Pose(self.ManticorePoses, self.ManticoreGaitPhase, self.ManticoreGaitWeight, self.ManticoreDirection,
        elapsed, pitch, yaw, firedAgo)
end

function ENT:Init()
    self:SetRenderBounds(rig.mins, rig.maxs)
    self:DrawShadow(false)
    self.ManticoreMatrix = Matrix()
    self.ManticorePoses = {}
    self.ManticoreLights = {}
    self.ManticoreGaitPhase, self.ManticoreGaitWeight, self.ManticoreDirection = 0, 0, 1
end

local function drawShadowParts(projector, poses)
    for index, batches in ipairs(renderParts) do
        groundShadow.DrawPart(projector, poses[rig.parts[index].name], batches, "model")
    end
    groundShadow.DrawSeams(projector, poses, seams)
end

function ENT:Draw()
    if self.ManticoreBreaking then return end
    local parts = getRenderParts()
    if not parts then return end
    if not self.ManticorePoses then self:Init() end
    local now, pos, angle = CurTime(), self:GetPos(), self:GetAngles()
    local matrix, poses, lights = self.ManticoreMatrix, self.ManticorePoses, self.ManticoreLights
    updatePose(self, now, pos)
    local refreshLight = not self.ManticoreNextLight or now >= self.ManticoreNextLight
    local chassisLight
    if refreshLight then
        self.ManticoreNextLight = now + 0.1
        chassisLight = render.ComputeLighting(self:LocalToWorld(chassisLightPoint))
        if not isvector(chassisLight) then chassisLight = fallbackLight end
    end
    for index, part in ipairs(rig.parts) do
        local pose = poses[part.name]
        if refreshLight then
            local sample = LocalToWorld(part.sample - part.pivot, zero, pose.pos, pose.ang)
            lights[index] = sampleLight(self:LocalToWorld(sample), chassisLight)
        end
        local origin, orientation = LocalToWorld(pose.pos, pose.ang, pos, angle)
        matrix:SetTranslation(origin)
        matrix:SetAngles(orientation)
        cam.PushModelMatrix(matrix)
        drawPart(parts[index], lights[index], true)
        cam.PopModelMatrix()
    end
    drawSeams(poses, lights[1], matrix, pos, angle)
    groundShadow.Queue(self, pos, angle, rig, poses, drawShadowParts)
end
