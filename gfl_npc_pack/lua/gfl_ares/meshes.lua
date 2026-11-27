if GFL_AA02Meshes then return GFL_AA02Meshes end

local geometry = include("gfl_ares/geometry.lua")
local assets = "data_static/gfl_ares/"
local mats = {}
local meshes = {}
GFL_AA02Meshes = meshes

local function getMaterial(name)
    if not mats[name] then mats[name] = Material("models/gfl_ares/" .. name) end
    return mats[name]
end

local function vertex(reader, material)
    local position = Vector(reader:ReadFloat(), reader:ReadFloat(), reader:ReadFloat())
    local n = Vector(reader:ReadFloat(), reader:ReadFloat(), reader:ReadFloat())
    local u, v = reader:ReadFloat(), reader:ReadFloat()
    local light = 255
    if material ~= "lamp" then light = 255 * (.65 + .35 * math.Clamp(n.x * .42 - n.y * .3 + n.z * .85, 0, 1)) end
    return {pos = position, normal = n, u = u, v = v, color = Color(light, light, light)}
end

local function readRigid(name, material)
    local reader = file.Open(assets .. name .. ".txt", "rb", "GAME")
    if not reader then return end
    local magic, vertices, indices = reader:Read(4), reader:ReadULong(), reader:ReadULong()
    if magic ~= "AAM1" or vertices < 3 or vertices > 65535 or indices < 3 or indices > 22500
        or indices % 3 ~= 0 or reader:Size() ~= 12 + 32 * vertices + 2 * indices then
        reader:Close()
        return
    end
    local source, triangles = {}, {}
    for i = 1, vertices do source[i] = vertex(reader, material) end
    for i = 1, indices do
        local v = source[reader:ReadUShort() + 1]
        if not v then reader:Close() return end
        triangles[i] = v
    end
    reader:Close()
    local mat = getMaterial(material)
    local model = Mesh(mat)
    model:BuildFromTriangles(triangles)
    return {mesh = model, material = mat, luminous = material == "lamp"}
end

local function readSeam(desc)
    local file = file.Open(assets .. desc.file .. ".txt", "rb", "GAME")
    if not file then return end
    local magic, count = file:Read(4), file:ReadULong()
    if magic ~= "AAS1" or count > 2100 or count < 3 or count % 3 ~= 0 or file:Size() ~= 8 + count * 33 then
        file:Close()
        return
    end
    local verts = {}
    for i = 1, count do
        local id = file:ReadByte()
        if not geometry.parts[id] then file:Close() return end
        local v = vertex(file, desc.material)
        v.part = id
        verts[i] = v
    end
    file:Close()
    return {verts = verts, material = getMaterial(desc.material)}
end

local parts, seams, failed
function meshes.Body()
    if parts or failed then return parts, seams end
    local batches, joints = {}, {}
    for id, part in ipairs(geometry.parts) do
        batches[id] = {mainCannon = part.mainCannon}
        for _, desc in ipairs(part.meshes) do
            local batch = readRigid(desc.file, desc.material)
            if not batch then failed = desc.file break end
            batches[id][#batches[id] + 1] = batch
        end
        if failed then break end
    end
    if not failed then
        for id, desc in ipairs(geometry.seams) do
            joints[id] = readSeam(desc)
            if not joints[id] then failed = desc.file break end
        end
    end
    if failed then
        for _, group in ipairs(batches) do
            for _, batch in ipairs(group) do batch.mesh:Destroy() end
        end
        ErrorNoHalt("[AA-02] Missing or invalid mesh " .. failed .. "\n")
        return
    end
    parts, seams = batches, joints
    return parts, seams
end

local projectile
function meshes.Projectile()
    if projectile == nil then projectile = readRigid("projectile", "missile") or false end
    return projectile
end

return meshes
