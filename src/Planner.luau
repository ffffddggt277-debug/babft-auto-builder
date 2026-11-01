local Planner = {}
function Planner.count(blueprint)
    local result = {}
    for _, block in ipairs(blueprint.blocks) do result[block.type] = (result[block.type] or 0) + 1 end
    return result
end
function Planner.compare(required, available)
    local missing = {}
    for kind, amount in pairs(required) do
        local n = available[kind]
        if type(n) ~= 'number' or n ~= n or n < 0 or n % 1 ~= 0 or n > 1000000000 then error('Недостоверное значение инвентаря: '..kind,0) end
        missing[kind] = math.max(0,amount-n)
    end
    return missing
end
function Planner.plan(blueprint, order)
    if order ~= 'original' and order ~= 'bottom-up' then error('Неизвестный порядок',0) end
    local result = table.clone(blueprint.blocks)
    if order == 'bottom-up' then
        table.sort(result,function(a,b)
            if a.position.y == b.position.y then return a.index < b.index end
            return a.position.y < b.position.y
        end)
    end
    return result
end
return Planner
