-- Blueprint coordinates describe block centres. Calculate the lowest point of
-- each rotated cuboid for CFrame.Angles' X-Y-Z rotation order.
local Geometry = {}
function Geometry.lowestY(blueprint)
    local lowest = math.huge
    for _, block in ipairs(blueprint.blocks) do
        local r, size = block.rotation, block.size
        local x,y,z = math.rad(r.x),math.rad(r.y),math.rad(r.z)
        local cx,sx,cy,sy,cz,sz = math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
        local yx = sx*sy*cz + cx*sz
        local yy = -sx*sy*sz + cx*cz
        local yz = -sx*cy
        local extent = (math.abs(yx)*size.x + math.abs(yy)*size.y + math.abs(yz)*size.z)/2
        lowest = math.min(lowest,block.position.y-extent)
    end
    if lowest == math.huge then error('Пустая схема',0) end
    return lowest
end
function Geometry.originY(blueprint, groundY)
    if type(groundY) ~= 'number' or groundY ~= groundY or math.abs(groundY) == math.huge then error('Неверная высота поверхности',0) end
    return groundY - Geometry.lowestY(blueprint)
end
return Geometry
