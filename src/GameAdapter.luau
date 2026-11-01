-- Experimental integration inferred from public third-party source, NOT verified in BABFT.
local GameAdapter = {}
GameAdapter.__index = GameAdapter
local zoneNames = {black='BlackZone',blue='Really blueZone',green='CamoZone',red='Really redZone',white='WhiteZone',yellow='New YellerZone',magenta='MagentaZone'}
function GameAdapter.new(player, world, wait, frame)
    return setmetatable({player=player, world=world, wait=wait, frame=frame, origin=nil},GameAdapter)
end
function GameAdapter:inventory()
    local data = self.player:FindFirstChild('Data')
    local item = data and data:FindFirstChild('WoodBlock')
    if not item or not item:IsA('ValueBase') or type(item.Value) ~= 'number' or item.Value < 0 or item.Value % 1 ~= 0 then
        return nil, 'Data.WoodBlock не найден или не является целым числом; инвентарь неизвестен'
    end
    return {wood=item.Value}
end
function GameAdapter:ready()
    if not self.origin then return nil,'Сначала сохраните исходную точку' end
    local p = self.player
    local team = p.Team
    local zone = team and self.world:FindFirstChild(zoneNames[string.lower(team.Name)] or '')
    local backpack = p:FindFirstChildOfClass('Backpack')
    local tool = (p.Character and p.Character:FindFirstChild('BuildingTool')) or (backpack and backpack:FindFirstChild('BuildingTool'))
    local rf = tool and tool:FindFirstChild('RF')
    local settings = p:FindFirstChild('Settings')
    local share = settings and settings:FindFirstChild('ShareBlocks')
    if not share or not share:IsA('BoolValue') or share.Value then return nil,'Невозможно подтвердить личный инвентарь: ShareBlocks отсутствует или включён' end
    local blocks = self.world:FindFirstChild('Blocks')
    local owned = blocks and blocks:FindFirstChild(p.Name)
    if not zone or not rf or not rf:IsA('RemoteFunction') or not owned then return nil,'Не найдены зона, BuildingTool.RF или папка Blocks игрока' end
    local inv, err = self:inventory(); if not inv then return nil,err end
    return {zone=zone,rf=rf,owned=owned}
end
function GameAdapter:transform(block)
    if not self.origin then error('Сначала сохраните исходную точку',0) end
    local p,r=block.position,block.rotation
    return self.origin * self.frame.new(p.x,p.y,p.z) * self.frame.Angles(math.rad(r.x),math.rad(r.y),math.rad(r.z))
end
function GameAdapter:place(block)
    local context, err = self:ready(); if not context then return false,err end
    local inventory, inventoryErr = self:inventory(); if not inventory then return false,inventoryErr end
    if inventory.wood < 1 then return false,'Data.WoodBlock: нет доступных блоков' end
    local before = {}; for _, inst in ipairs(context.owned:GetChildren()) do before[inst]=true end
    local target = self:transform(block)
    -- A successful network call is not confirmation of a placed block.
    local ok, response = pcall(function() return context.rf:InvokeServer('WoodBlock',inventory.wood,context.zone,target,true) end)
    if not ok then return false,'Ошибка вызова BuildingTool: '..tostring(response) end
    local observedNew, observedWood, closest = 0, 0, nil
    for _ = 1, 40 do
        observedNew, observedWood, closest = 0, 0, nil
        for _, candidate in ipairs(context.owned:GetChildren()) do
            if not before[candidate] then
                observedNew += 1
                if candidate.Name == 'WoodBlock' then
                    observedWood += 1
                    local part
                    if candidate:IsA('BasePart') then
                        part = candidate
                    else
                        -- Public BABFT source identifies the model's PPart as its geometry.
                        part = candidate:FindFirstChild('PPart')
                        if not part or not part:IsA('BasePart') then part = candidate:FindFirstChildWhichIsA('BasePart',true) end
                    end
                    if part then
                        local distance = (part.Position-target.Position).Magnitude
                        closest = math.min(closest or distance,distance)
                        if distance < 2 then
                            return true,'Замечен новый WoodBlock у цели; свойства и происхождение не проверены'
                        end
                    end
                end
            end
        end
        self.wait(0.2)
    end
    local inventoryAfter = self:inventory()
    local countAfter = inventoryAfter and tostring(inventoryAfter.wood) or '?'
    local distanceText = closest and string.format('%.1f',closest) or 'нет'
    return false, string.format('Блок у цели не найден за 8 с: новых объектов %d, WoodBlock %d, расстояние %s, инвентарь %d → %s, ответ %s. Проверьте участок перед повтором.',observedNew,observedWood,distanceText,inventory.wood,countAfter,type(response))
end
return GameAdapter
