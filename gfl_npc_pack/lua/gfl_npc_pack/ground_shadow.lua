if GFLPackGroundShadow then return GFLPackGroundShadow end

local shadow = {}
GFLPackGroundShadow = shadow

local pending = {}
local zero, zeroAngle = Vector(), Angle()
local drawDistance, gridStep = 2800, 32
local cast = Vector(.29, .21, -1)
local trace = {mask = MASK_SOLID_BRUSHONLY}
local stencilBit = 0x80
local surfaceBias = .6
local silhouette = CreateMaterial("gfl_npc_pack_shadow_stencil", "UnlitGeneric", {
    ["$basetexture"] = "color/white", ["$model"] = "1", ["$nocull"] = "1",
    ["$ignorez"] = "1", ["$nofog"] = "1",
})
local receiver = CreateMaterial("gfl_npc_pack_shadow_ground", "UnlitGeneric", {
    ["$basetexture"] = "color/white", ["$model"] = "1", ["$translucent"] = "1",
    ["$vertexalpha"] = "1", ["$vertexcolor"] = "1", ["$nocull"] = "1", ["$nofog"] = "1",
})

local function projectedBounds(rig, angle)
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    for _, x in ipairs({rig.mins.x, rig.maxs.x}) do
        for _, y in ipairs({rig.mins.y, rig.maxs.y}) do
            for _, z in ipairs({rig.mins.z, rig.maxs.z}) do
                local p = LocalToWorld(Vector(x, y, z), zeroAngle, zero, angle)
                local px, py = p.x + cast.x * p.z, p.y + cast.y * p.z
                minX, maxX = math.min(minX, px), math.max(maxX, px)
                minY, maxY = math.min(minY, py), math.max(maxY, py)
            end
        end
    end
    local border = 12
    return {
        x = minX - border, y = minY - border,
        width = maxX - minX + 2 * border, height = maxY - minY + 2 * border,
    }
end

local function sampleGround(x, y, z)
    trace.start = Vector(x, y, z + 56)
    trace.endpos = Vector(x, y, z - 154)
    local hit = util.TraceLine(trace)
    if not hit or not hit.Hit or hit.HitSky or hit.StartSolid or hit.HitNormal.z < .55 then return false end
    return {pos = hit.HitPos, normal = hit.HitNormal}
end

local function canJoin(a, b)
    -- Reject triangles that cross the edge of a receiving surface.
    local offset = a.pos - b.pos
    return math.abs(offset.z) <= gridStep and a.normal:Dot(b.normal) > .82
        and math.abs(offset:Dot(a.normal)) < 6 and math.abs(offset:Dot(b.normal)) < 6
end

local function addTriangle(surfaces, a, b, c)
    if not (a and b and c and canJoin(a, b) and canJoin(a, c) and canJoin(b, c)) then return end

    local normal, distance = a.normal, a.normal:Dot(a.pos)
    local surface
    for _, candidate in ipairs(surfaces) do
        if normal:Dot(candidate.normal) > .999 and math.abs(candidate.normal:Dot(a.pos) - candidate.distance) < 1 then
            surface = candidate
            break
        end
    end
    if not surface then
        surface = {normal = normal, distance = distance, vertices = {}}
        surfaces[#surfaces + 1] = surface
    end
    local vertices = surface.vertices
    vertices[#vertices + 1] = a.pos
    vertices[#vertices + 1] = b.pos
    vertices[#vertices + 1] = c.pos
end

local function terrain(position, bounds)
    local center = sampleGround(position.x, position.y, position.z)
    local base = center and center.pos.z - position.z or 0
    local padding = 56
    local minX = math.floor((position.x + bounds.x - cast.x * base - padding) / gridStep) * gridStep
    local minY = math.floor((position.y + bounds.y - cast.y * base - padding) / gridStep) * gridStep
    local columns = math.ceil((position.x + bounds.x + bounds.width - cast.x * base + padding - minX) / gridStep)
    local rows = math.ceil((position.y + bounds.y + bounds.height - cast.y * base + padding - minY) / gridStep)
    local samples, surfaces = {}, {}
    for row = 0, rows do
        for col = 0, columns do
            samples[#samples + 1] = sampleGround(minX + col * gridStep, minY + row * gridStep, position.z)
        end
    end
    local stride = columns + 1
    for row = 0, rows - 1 do
        for col = 1, columns do
            local i = row * stride + col
            local a, b = samples[i], samples[i + 1]
            local d, c = samples[i + stride], samples[i + stride + 1]
            addTriangle(surfaces, a, d, b)
            addTriangle(surfaces, d, c, b)
        end
    end
    return surfaces
end

local partMatrix = Matrix()
function shadow.DrawPart(projector, pose, batches, meshKey)
    partMatrix:SetTranslation(pose.pos)
    partMatrix:SetAngles(pose.ang)
    cam.PushModelMatrix(projector * partMatrix)
    for _, batch in ipairs(batches) do batch[meshKey]:Draw() end
    cam.PopModelMatrix()
end

function shadow.DrawSeams(projector, poses, vertices)
    cam.PushModelMatrix(projector)
    mesh.Begin(MATERIAL_TRIANGLES, #vertices / 3)
    for _, vertex in ipairs(vertices) do
        local pose = poses[vertex.part]
        mesh.Position(LocalToWorld(vertex.pos, zeroAngle, pose.pos, pose.ang))
        mesh.TexCoord(0, 0, 0)
        mesh.AdvanceVertex()
    end
    mesh.End()
    cam.PopModelMatrix()
end

local function projector(position, normal, distance)
    -- Project model-space offsets along the cast direction onto this floor plane.
    -- Leave a tiny normal scale so the matrix remains invertible.
    local ray = cast * (.9999 / normal:Dot(cast))
    local origin = position + ray * (distance - position:Dot(normal)) + normal * surfaceBias
    return Matrix({
        {1 - ray.x * normal.x, -ray.x * normal.y, -ray.x * normal.z, origin.x},
        {-ray.y * normal.x, 1 - ray.y * normal.y, -ray.y * normal.z, origin.y},
        {-ray.z * normal.x, -ray.z * normal.y, 1 - ray.z * normal.z, origin.z},
        {0, 0, 0, 1},
    })
end

local function clearStencilBit()
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
    render.SetStencilFailOperation(STENCILOPERATION_ZERO)
    render.PerformFullScreenStencilOperation()
    render.SetStencilFailOperation(STENCILOPERATION_KEEP)
end

local function drawReceiver(surface, position, opacity)
    render.SetMaterial(receiver)
    local bias = surface.normal * surfaceBias
    mesh.Begin(MATERIAL_TRIANGLES, #surface.vertices / 3)
    for _, vertex in ipairs(surface.vertices) do
        mesh.Position(vertex + bias)
        mesh.TexCoord(0, 0, 0)
        mesh.Color(0, 0, 0, math.floor(opacity * math.Clamp((142 + vertex.z - position.z) / 92, 0, 1)))
        mesh.AdvanceVertex()
    end
    mesh.End()
end

local function drawShadow(state)
    local rotation = Matrix()
    rotation:SetAngles(state.angle)
    local opacity = 112 * math.Clamp((drawDistance - math.sqrt(state.distance)) / 600, 0, 1)

    render.SetStencilEnable(true)
    render.SetStencilWriteMask(stencilBit)
    render.SetStencilTestMask(stencilBit)
    render.SetStencilReferenceValue(stencilBit)
    render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
    render.OverrideDepthEnable(true, false)
    render.OverrideAlphaWriteEnable(true, false)
    clearStencilBit()

    for _, surface in ipairs(state.terrain) do
        -- Build the whole silhouette directly in the current 3D view. Its parts
        -- share one mask, so overlapping triangles only shade the floor once.
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
        render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
        render.OverrideColorWriteEnable(true, false)
        render.SetMaterial(silhouette)
        state.drawParts(projector(state.position, surface.normal, surface.distance) * rotation, state.poses)
        render.OverrideColorWriteEnable(false, false)

        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
        render.SetStencilPassOperation(STENCILOPERATION_ZERO)
        drawReceiver(surface, state.position, opacity)
        clearStencilBit()
    end

    render.OverrideAlphaWriteEnable(false, false)
    render.OverrideDepthEnable(false, false)
    render.SetStencilEnable(false)
    render.SetStencilWriteMask(0xFF)
    render.SetStencilTestMask(0xFF)
    render.SetStencilReferenceValue(0)
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
    render.SetStencilPassOperation(STENCILOPERATION_KEEP)
end

function shadow.Queue(entity, position, angle, rig, poses, drawParts)
    local distance = EyePos():DistToSqr(position)
    if distance >= drawDistance ^ 2 then return end
    local state = entity.GFLPackShadow or {}
    state.position, state.angle, state.rig = position, angle, rig
    state.poses, state.drawParts = poses, drawParts
    state.distance, state.frame = distance, FrameNumber()
    entity.GFLPackShadow = state
    pending[entity] = state
end

hook.Add("PostDrawOpaqueRenderables", "GFLPackGroundShadow", function(depth, _, sky3D)
    if depth or sky3D or not next(pending) then return end
    local frame, now = FrameNumber(), RealTime()
    for entity, state in pairs(pending) do
        pending[entity] = nil
        if state.frame == frame and IsValid(entity) then
            if not state.terrain or now >= state.nextTrace or state.position:DistToSqr(state.tracePosition) > 26 ^ 2
                or math.abs(math.AngleDifference(state.angle.y, state.traceYaw)) > 9 then
                state.terrain = terrain(state.position, projectedBounds(state.rig, state.angle))
                state.nextTrace = now + .14
                state.tracePosition, state.traceYaw = state.position, state.angle.y
            end
            if #state.terrain > 0 then drawShadow(state) end
        end
    end
end)

return shadow
