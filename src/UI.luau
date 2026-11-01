local UI = {}
function UI.start(Schema, Loader, Planner, Builder, GameAdapter)
    if game.PlaceId ~= 537413528 then warn('BABFT Auto Builder: требуется Build A Boat For Treasure (place 537413528)'); return end
    local Players = game:GetService('Players')
    local HttpService = game:GetService('HttpService')
    local UIS = game:GetService('UserInputService')
    local player = Players.LocalPlayer
    if not player then warn('BABFT Auto Builder: LocalPlayer недоступен'); return end
    local guiParent = player:FindFirstChildOfClass('PlayerGui')
    if not guiParent then warn('BABFT Auto Builder: PlayerGui недоступен'); return end
    local previous = guiParent:FindFirstChild('BabftAutoBuilder')
    if previous then warn('BABFT Auto Builder уже открыт; повторный запуск запрещён, пока он существует'); return end
    local oldPreview = workspace:FindFirstChild('BabftAutoBuilderLocalPreview')
    if oldPreview then oldPreview:Destroy() end
    local gui = Instance.new('ScreenGui')
    gui.Name='BabftAutoBuilder'; gui.ResetOnSpawn=false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.DisplayOrder=100; gui.Parent=guiParent
    local colors = {background=Color3.fromRGB(21,28,33),surface=Color3.fromRGB(32,42,47),field=Color3.fromRGB(43,54,59),text=Color3.fromRGB(235,243,239),muted=Color3.fromRGB(169,185,178),accent=Color3.fromRGB(55,147,116),warning=Color3.fromRGB(244,190,115)}
    local function create(class, props, parent)
        local inst = Instance.new(class)
        for key,value in pairs(props) do inst[key]=value end
        inst.Parent=parent
        return inst
    end
    local function corner(object, radius) create('UICorner',{CornerRadius=UDim.new(0,radius)},object) end
    local function label(parent,text,height,color)
        return create('TextLabel',{BackgroundTransparency=1,Size=UDim2.new(1,0,0,height),AutomaticSize=Enum.AutomaticSize.Y,Text=text,TextColor3=color or colors.text,Font=Enum.Font.Gotham,TextSize=15,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center},parent)
    end
    local function button(parent,text,height)
        local b=create('TextButton',{BackgroundColor3=colors.field,BorderSizePixel=0,Size=UDim2.new(1,0,0,height or 48),Text=text,TextColor3=colors.text,Font=Enum.Font.GothamMedium,TextSize=15,TextWrapped=true,AutoButtonColor=true},parent)
        corner(b,7); return b
    end
    local function textbox(parent,placeholder,default)
        local b=create('TextBox',{BackgroundColor3=colors.field,BorderSizePixel=0,Size=UDim2.new(1,0,0,44),Text=default or '',PlaceholderText=placeholder,PlaceholderColor3=colors.muted,TextColor3=colors.text,Font=Enum.Font.Gotham,TextSize=15,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left},parent)
        create('UIPadding',{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},b);corner(b,7);return b
    end
    local open = button(gui,'BABFT',44)
    open.Position=UDim2.new(0,12,0.5,-22);open.Size=UDim2.fromOffset(76,44);open.Visible=false;open.BackgroundColor3=colors.accent
    local window = create('Frame',{Name='Window',BackgroundColor3=colors.background,BorderSizePixel=0,Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(460,570)},gui)
    corner(window,10)
    local function sizeWindow()
        local camera=workspace.CurrentCamera
        if not camera then return end
        local v=camera.ViewportSize
        window.Size=UDim2.fromOffset(math.max(1,math.min(500,v.X-24)),math.max(1,math.min(600,v.Y-36)))
        -- Orientation changes can otherwise leave a dragged window off-screen.
        window.Position=UDim2.fromScale(0.5,0.5)
    end
    sizeWindow()
    local cameraConnection
    local function watchCamera()
        if cameraConnection then cameraConnection:Disconnect() end
        local camera=workspace.CurrentCamera
        if camera then cameraConnection=camera:GetPropertyChangedSignal('ViewportSize'):Connect(sizeWindow) end
        sizeWindow()
    end
    local cameraChanged=workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(watchCamera);watchCamera()
    local header=create('Frame',{BackgroundColor3=colors.surface,BorderSizePixel=0,Size=UDim2.new(1,0,0,48),Active=true},window);corner(header,10)
    local title=create('TextLabel',{BackgroundTransparency=1,Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-76,1,0),Text='BABFT AUTO BUILDER',TextColor3=colors.text,Font=Enum.Font.GothamBold,TextSize=15,TextXAlignment=Enum.TextXAlignment.Left,Active=true},header)
    local hide=button(header,'—',36);hide.Size=UDim2.fromOffset(48,36);hide.Position=UDim2.new(1,-54,0,6)
    hide.Activated:Connect(function() window.Visible=false;open.Visible=true end)
    open.Activated:Connect(function() window.Visible=true;open.Visible=false end)
    local dragStart, startPosition, activeInput
    local function dragBegin(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragStart=input.Position;startPosition=window.Position;activeInput=input end
    end
    header.InputBegan:Connect(dragBegin);title.InputBegan:Connect(dragBegin)
    local inputEnded=UIS.InputEnded:Connect(function(input) if input==activeInput then activeInput=nil end end)
    local inputMoved=UIS.InputChanged:Connect(function(input)
        if not activeInput then return end
        if input==activeInput or (activeInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then
            local delta=input.Position-dragStart
            local camera=workspace.CurrentCamera; if not camera then return end
            local v=camera.ViewportSize;local size=window.AbsoluteSize
            local x=math.clamp(startPosition.X.Scale*v.X+startPosition.X.Offset+delta.X,size.X/2,v.X-size.X/2)
            local y=math.clamp(startPosition.Y.Scale*v.Y+startPosition.Y.Offset+delta.Y,size.Y/2,v.Y-size.Y/2)
            window.Position=UDim2.fromOffset(x,y)
        end
    end)
    local tabs=create('Frame',{BackgroundTransparency=1,Position=UDim2.fromOffset(10,54),Size=UDim2.new(1,-20,0,42)},window)
    local tabLayout=create('UIListLayout',{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},tabs)
    local body=create('Frame',{BackgroundTransparency=1,Position=UDim2.fromOffset(10,102),Size=UDim2.new(1,-20,1,-112),ClipsDescendants=true},window)
    local pages={}
    local tabButtons={}
    for index,name in ipairs({'Схема','Стройка','Золото','Журнал'}) do
        local tab=button(tabs,name,42);tab.Size=UDim2.new(1/4,-4.5,1,0);tab.LayoutOrder=index;tabButtons[name]=tab
        local page=create('ScrollingFrame',{Name=name,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=5,Visible=index==1},body)
        create('UIPadding',{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,14),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,10)},page)
        create('UIListLayout',{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},page)
        pages[name]=page
        tab.Activated:Connect(function() for n,p in pairs(pages) do p.Visible=(n==name);tabButtons[n].BackgroundColor3=(n==name and colors.accent or colors.field) end end)
    end
    tabButtons['Схема'].BackgroundColor3=colors.accent
    local schemaPage,buildPage,goldPage,logPage=pages['Схема'],pages['Стройка'],pages['Золото'],pages['Журнал']
    local counter=0
    local function order(inst) counter+=1;inst.LayoutOrder=counter;return inst end
    local logs={}
    local logLabel=order(label(logPage,'Журнал пуст',100,colors.muted)); logLabel.TextYAlignment=Enum.TextYAlignment.Top
    local function log(message)
        table.insert(logs,os.date('%H:%M:%S')..' '..message)
        if #logs>18 then table.remove(logs,1) end
        logLabel.Text=table.concat(logs,'\n');print('[BABFT Auto Builder] '..message)
    end
    order(label(schemaPage,'СХЕМА И ПРЕДПРОСМОТР',28,colors.accent))
    order(label(schemaPage,'GitHub Raw URL — публичный JSON',25,colors.muted))
    local url=order(textbox(schemaPage,'https://raw.githubusercontent.com/...','https://raw.githubusercontent.com/ffffddggt277-debug/babft-auto-builder/main/examples/test_build.json'))
    local load=order(button(schemaPage,'Загрузить и проверить JSON'))
    local summary=order(label(schemaPage,'Схема не загружена',68,colors.muted))
    local planText=order(label(schemaPage,'',80,colors.muted));planText.TextYAlignment=Enum.TextYAlignment.Top
    order(label(schemaPage,'Превью локальное: это не блоки в игре.',32,colors.warning))
    local previewButton=order(button(schemaPage,'Показать / убрать локальное превью'))
    order(label(buildPage,'ПОСТРОЙКА',28,colors.accent))
    order(label(buildPage,'Внимание: игровой адаптер не проверен. Размер и цвет при постройке не применяются.',55,colors.warning))
    local inventoryLabel=order(label(buildPage,'Инвентарь: неизвестен',48,colors.muted))
    local inventoryButton=order(button(buildPage,'Прочитать Data.WoodBlock'))
    local originButton=order(button(buildPage,'Сохранить позицию персонажа как начало'))
    local originLabel=order(label(buildPage,'Начальная точка не задана',40,colors.muted))
    local orderButton=order(button(buildPage,'Порядок: как в JSON'))
    local speed=order(textbox(buildPage,'Интервал в секундах (0.2–10)','0.5'))
    local consent=order(button(buildPage,'Разрешить эксперимент и принять потерю цвета/размера: НЕТ',55))
    local start=order(button(buildPage,'Начать экспериментальную постройку'));start.BackgroundColor3=colors.accent
    local pause=order(button(buildPage,'Пауза / продолжить'))
    local cancel=order(button(buildPage,'Отменить'))
    local progress=order(label(buildPage,'Ожидание · 0 / 0',55,colors.muted))
    order(label(buildPage,'Отмена не откатывает уже размещённые блоки и не прерывает запрос к серверу.',45,colors.muted))
    order(label(goldPage,'ЗОЛОТО',28,colors.accent))
    order(label(goldPage,'Автоматический заработок пока недоступен: текущий игровой способ не проверен. Фиктивной кнопки здесь нет.',70,colors.warning))
    order(label(goldPage,'В обычной игре золото выдают за прохождение этапов и достижение сокровища. Источники и ограничения описаны в README.',70,colors.muted))
    local goldStatus=order(label(goldPage,'Баланс и карта не проверены.',50,colors.muted))
    local inspectGold=order(button(goldPage,'Проверить баланс и карту'))
    local adapter=GameAdapter.new(player,workspace,task.wait,CFrame)
    local blueprint, busy, consented, orderMode, preview = nil,false,false,'original',nil
    local function clearPreview() if preview then preview:Destroy();preview=nil end end
    local builder=Builder.new(adapter,function(state,done,total,message)
        progress.Text=state..' · '..done..' / '..total..'\n'..message; log(message)
    end,task.wait)
    local function running() return busy or builder.state=='running' or builder.state=='paused' or builder.state=='cancelling' end
    local function safe(fn)
        local ok,err=pcall(fn); if not ok then log('ОШИБКА: '..tostring(err));progress.Text='Ошибка: '..tostring(err) end
    end
    inspectGold.Activated:Connect(function() safe(function()
        local data=player:FindFirstChild('Data')
        local gold=data and data:FindFirstChild('Gold')
        local balance='недоступен'
        if gold and gold:IsA('ValueBase') and type(gold.Value)=='number' then balance=tostring(gold.Value) end
        local stages=workspace:FindFirstChild('BoatStages')
        stages=stages and stages:FindFirstChild('NormalStages')
        local found=0
        if stages then
            for i=1,10 do
                local stage=stages:FindFirstChild('CaveStage'..i)
                if stage and stage:FindFirstChild('DarknessPart') then found+=1 end
            end
        end
        local ending=stages and stages:FindFirstChild('TheEnd')
        local chest=ending and ending:FindFirstChild('GoldenChest')
        local trigger=chest and chest:FindFirstChild('Trigger')
        local chestText=trigger and 'найден' or 'не найден'
        goldStatus.Text='Data.Gold: '..balance..'\nРазделителей этапов найдено: '..found..' из 10\nТриггер сундука: '..chestText..'\nЭто проверка объектов, а не проверка заработка.'
        log('Диагностика золота: Data.Gold='..balance..'; этапов='..found..'/10; триггер='..chestText)
    end) end)
    local function updateSummary()
        if not blueprint then summary.Text='Схема не загружена';planText.Text='';return end
        summary.Text=blueprint.name..' · блоков: '..#blueprint.blocks..'\nТолько wood. Размер и цвет хранятся в схеме, но не применяются.'
        local plan=Planner.plan(blueprint,orderMode);local lines={}
        for i=1,math.min(5,#plan) do local b=plan[i];table.insert(lines, string.format('%d. %s (%g, %g, %g)',i,b.type,b.position.x,b.position.y,b.position.z)) end
        if #plan>5 then table.insert(lines,'... ещё '..(#plan-5)..' блоков') end
        planText.Text=table.concat(lines,'\n')
    end
    local function readInventory()
        local inv,err=adapter:inventory()
        if not inv then inventoryLabel.Text='Инвентарь неизвестен: '..err;return nil end
        local required=blueprint and Planner.count(blueprint).wood or 0
        inventoryLabel.Text='Data.WoodBlock: '..inv.wood..' · нужно '..required..' · не хватает '..math.max(0,required-inv.wood)..'\nЗначение опирается на сторонний исходник; не проверено в игре.'
        return inv
    end
    load.Activated:Connect(function()
        if running() then log('Дождитесь окончания текущей операции');return end
        busy=true;blueprint=nil;clearPreview();updateSummary();summary.Text='Загрузка…';log('Загрузка схемы')
        task.spawn(function()
            local finished,result,fetchError=false,nil,nil
            task.spawn(function()
                local ok,value=pcall(function() return Loader.load(url.Text,function(u) return game:HttpGet(u) end,function(text) return HttpService:JSONDecode(text) end,Schema) end)
                if ok then result=value else fetchError=value end
                finished=true
            end)
            local started=os.clock()
            while not finished and os.clock()-started<12 do task.wait(0.1) end
            if not finished then summary.Text='Тайм-аут загрузки';log('Тайм-аут загрузки (запрос executor может продолжаться)')
            elseif fetchError then summary.Text=tostring(fetchError);log('Ошибка загрузки: '..tostring(fetchError))
            else blueprint=result;updateSummary();readInventory();log('Схема проверена: '..#blueprint.blocks..' блоков') end
            busy=false
        end)
    end)
    inventoryButton.Activated:Connect(function() safe(readInventory) end)
    originButton.Activated:Connect(function() safe(function()
        if running() then error('Нельзя менять начало во время работы') end
        local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart');if not root then error('Персонаж не найден') end
        adapter.origin=CFrame.new(root.Position);clearPreview();originLabel.Text=string.format('Начало: %.1f, %.1f, %.1f',root.Position.X,root.Position.Y,root.Position.Z);log('Начальная точка сохранена')
    end) end)
    orderButton.Activated:Connect(function() if running() then return end;orderMode=(orderMode=='original' and 'bottom-up' or 'original');orderButton.Text=(orderMode=='original' and 'Порядок: как в JSON' or 'Порядок: снизу вверх');updateSummary() end)
    consent.Activated:Connect(function() if running() then return end;consented=not consented;consent.Text='Разрешить эксперимент и принять потерю цвета/размера: '..(consented and 'ДА' or 'НЕТ') end)
    previewButton.Activated:Connect(function() safe(function()
        if preview then clearPreview();log('Превью удалено');return end
        if not blueprint or not adapter.origin then error('Загрузите схему и задайте начало') end
        preview=Instance.new('Folder');preview.Name='BabftAutoBuilderLocalPreview';preview.Parent=workspace
        for _,b in ipairs(blueprint.blocks) do
            local part=Instance.new('Part');part.Name='Preview';part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Transparency=0.55
            part.Size=Vector3.new(b.size.x,b.size.y,b.size.z)
            local p,r=b.position,b.rotation;part.CFrame=adapter.origin*CFrame.new(p.x,p.y,p.z)*CFrame.Angles(math.rad(r.x),math.rad(r.y),math.rad(r.z));part.Color=Color3.fromRGB(tonumber(b.color:sub(2,3),16),tonumber(b.color:sub(4,5),16),tonumber(b.color:sub(6,7),16));part.Parent=preview
        end
        log('Показано локальное превью; это не размещение')
    end) end)
    start.Activated:Connect(function() safe(function()
        if running() then error('Процесс уже запущен') end
        if not consented then error('Требуется явно разрешить эксперимент и согласиться, что размер и цвет не применяются') end
        if not blueprint then error('Сначала загрузите схему') end
        local interval=tonumber(speed.Text);if not interval or interval<0.2 or interval>10 then error('Интервал должен быть от 0.2 до 10 секунд') end
        local ready,err=adapter:ready();if not ready then error(err) end
        local inv=readInventory();if not inv then error('Инвентарь неизвестен') end
        local missing=Planner.compare(Planner.count(blueprint),inv);if missing.wood>0 then error('Не хватает wood: '..missing.wood) end
        local plan=Planner.plan(blueprint,orderMode);busy=true
        task.spawn(function() local ok,message=pcall(function() builder:start(plan,interval) end);busy=false;if not ok then log('Ошибка выполнения: '..tostring(message)) end end)
    end) end)
    pause.Activated:Connect(function() if builder.state=='paused' then builder:resume() else builder:pause() end end)
    cancel.Activated:Connect(function() builder:cancel() end)
    gui.Destroying:Connect(function() clearPreview();inputEnded:Disconnect();inputMoved:Disconnect();cameraChanged:Disconnect();if cameraConnection then cameraConnection:Disconnect() end;builder:cancel() end)
    log('Загружен executor-интерфейс. Экспериментальный адаптер в игре не проверен.')
end
return UI
