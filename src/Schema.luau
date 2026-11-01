local Schema = {}
local function fail(message) error(message, 0) end
local function object(value, name)
    if type(value) ~= 'table' then fail(name .. ': нужен объект') end
end
local function keys(value, allowed, name)
    for k in pairs(value) do if not allowed[k] then fail(name .. ': неизвестное поле ' .. tostring(k)) end end
end
local function finite(n, min, max)
    return type(n) == 'number' and n == n and n >= min and n <= max
end
local function vector(value, name, min, max)
    object(value, name)
    keys(value, {x=true,y=true,z=true}, name)
    local out = {}
    for _, axis in ipairs({'x','y','z'}) do
        if not finite(value[axis], min, max) then fail(name .. '.' .. axis .. ': число вне допустимого диапазона') end
        out[axis] = value[axis]
    end
    return out
end
function Schema.validate(data)
    object(data, 'Схема')
    keys(data, {version=true,name=true,blocks=true}, 'Схема')
    if data.version ~= 1 then fail('version: поддерживается только 1') end
    local name = data.name
    if type(name) ~= 'string' then fail('name: требуется строка') end
    if #name < 1 or #name > 100 or not string.find(name, '%S') then fail('name: требуется непустое название до 100 байт') end
    if type(data.blocks) ~= 'table' then fail('blocks: нужен массив') end
    local count = 0
    for k in pairs(data.blocks) do
        if type(k) ~= 'number' or k < 1 or k % 1 ~= 0 then fail('blocks: нужен массив') end
        count += 1
    end
    if count < 1 or count > 2000 then fail('blocks: нужно 1–2000 блоков') end
    local blocks = {}
    for i = 1, count do
        local b = data.blocks[i]
        local path = 'blocks[' .. i .. ']'
        object(b, path); keys(b, {type=true,position=true,size=true,rotation=true,color=true}, path)
        if b.type ~= 'wood' then fail(path .. '.type: поддерживается только wood') end
        if type(b.color) ~= 'string' or not b.color:match('^#%x%x%x%x%x%x$') then fail(path .. '.color: нужен #RRGGBB') end
        blocks[i] = {type=b.type,position=vector(b.position,path..'.position',-10000,10000),size=vector(b.size,path..'.size',0.01,1000),rotation=vector(b.rotation,path..'.rotation',-360,360),color=b.color:upper(),index=i}
    end
    return {version=1,name=data.name,blocks=blocks}
end
function Schema.parse(text, decode)
    if type(text) ~= 'string' or #text > 1000000 then fail('JSON должен быть строкой до 1 МБ') end
    local ok, data = pcall(decode, text)
    if not ok then fail('Некорректный JSON: ' .. tostring(data)) end
    return Schema.validate(data)
end
return Schema
