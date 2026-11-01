local Schema = require('../src/Schema')
local Loader = require('../src/Loader')
local Planner = require('../src/Planner')
local Geometry = require('../src/Geometry')
local Builder = require('../src/Builder')
local GameAdapter = require('../src/GameAdapter')
local passed=0
local function test(name,fn)
    local ok,err=pcall(fn)
    if not ok then error('FAIL '..name..': '..tostring(err),0) end
    passed+=1;print('PASS '..name)
end
local function fails(fn,fragment)
    local ok,err=pcall(fn);assert(not ok,'expected failure');assert(string.find(tostring(err),fragment,1,true),tostring(err))
end
local function sample()
    return {version=1,name='raft',blocks={
        {type='wood',position={x=0,y=2,z=0},size={x=1,y=1,z=1},rotation={x=0,y=90,z=0},color='#aabbcc'},
        {type='wood',position={x=3,y=0,z=4},size={x=2,y=1,z=2},rotation={x=0,y=0,z=0},color='#abcdef'}
    }}
end
local validUrl='https://raw.githubusercontent.com/owner/repo/main/a.json'
test('schema normalizes valid blueprint',function() local b=Schema.validate(sample());assert(#b.blocks==2 and b.blocks[1].index==1 and b.blocks[1].color=='#AABBCC') end)
test('rejects missing fields and version',function() local d=sample();d.version=nil;fails(function() Schema.validate(d) end,'version');d=sample();d.blocks[1].position=nil;fails(function() Schema.validate(d) end,'position') end)
test('rejects unknown type and keys',function() local d=sample();d.blocks[1].type='steel';fails(function() Schema.validate(d) end,'wood');d=sample();d.blocks[1].extra=1;fails(function() Schema.validate(d) end,'extra') end)
test('coordinates sizes rotation color',function() for _,case in ipairs({{'position','x',0/0},{'size','y',0},{'rotation','z',361},{'position','z',10001}}) do local d=sample();d.blocks[1][case[1]][case[2]]=case[3];fails(function() Schema.validate(d) end,case[1]) end;local d=sample();d.blocks[1].color='#xyz';fails(function() Schema.validate(d) end,'color') end)
test('rejects sparse and oversized blocks',function() local d=sample();d.blocks={[2]=d.blocks[2]};fails(function() Schema.validate(d) end,'blocks');d=sample();for i=1,2001 do d.blocks[i]=d.blocks[1] end;fails(function() Schema.validate(d) end,'2000') end)
test('parsing and JSON decoder failure',function() assert(#Schema.parse('good',function() return sample() end).blocks==2);fails(function() Schema.parse('bad',function() error('invalid JSON') end) end,'Некорректный JSON');fails(function() Schema.parse(string.rep('a',1000001),function() end) end,'1 МБ') end)
test('Raw URL allowlist',function() assert(Loader.validateUrl(validUrl)==validUrl);for _,u in ipairs({'https://evil.com/x/y/z/a','https://raw.githubusercontent.com.evil.com/a/b/c/d','http://raw.githubusercontent.com/a/b/c/d','https://raw.githubusercontent.com/a/b/c/d?token=x','https://raw.githubusercontent.com/a/b/../d'}) do fails(function() Loader.validateUrl(u) end,'URL') end end)
test('loader errors and injected success',function() fails(function() Loader.load(validUrl,function() error('offline') end,function() end,Schema) end,'offline');local b=Loader.load(validUrl,function() return 'ok' end,function() return sample() end,Schema);assert(#b.blocks==2) end)
test('count, missing and bad inventory',function() local required=Planner.count(Schema.validate(sample()));assert(required.wood==2);assert(Planner.compare(required,{wood=1}).wood==1);assert(Planner.compare(required,{wood=5}).wood==0);fails(function() Planner.compare(required,{wood=-1}) end,'инвентаря') end)
test('ordering stable without mutation',function() local b=Schema.validate(sample());local sorted=Planner.plan(b,'bottom-up');assert(sorted[1].index==2 and b.blocks[1].index==1);fails(function() Planner.plan(b,'no') end,'порядок') end)
test('geometry anchors lowest surface at ground',function()
    local b=Schema.validate(sample());assert(math.abs(Geometry.lowestY(b)-(-0.5))<1e-9)
    assert(math.abs(Geometry.originY(b,10)-10.5)<1e-9)
end)
test('geometry accounts for tilted cuboids',function()
    local b=Schema.validate(sample());b.blocks={b.blocks[1]};local v=b.blocks[1];v.position.y=-2;v.size={x=2,y=4,z=6};v.rotation={x=90,y=0,z=0}
    assert(math.abs(Geometry.lowestY(b)-(-5))<1e-9)
    v.rotation={x=0,y=0,z=90};assert(math.abs(Geometry.lowestY(b)-(-3))<1e-9)
    v.rotation={x=0,y=45,z=0};assert(math.abs(Geometry.lowestY(b)-(-4))<1e-9)
end)
test('geometry agrees with independent corner calculation',function()
    local b=Schema.validate(sample());b.blocks={b.blocks[1]};local v=b.blocks[1];v.rotation={x=37,y=21,z=57};v.size={x=2,y=4,z=6};v.position.y=3
    local rx,ry,rz=math.rad(37),math.rad(21),math.rad(57);local lowest=math.huge
    for _,a in ipairs({-1,1}) do for _,c in ipairs({-1,1}) do for _,d in ipairs({-1,1}) do
        local x,y,z=a,2*c,3*d
        local xz=x*math.cos(rz)-y*math.sin(rz);local yz=x*math.sin(rz)+y*math.cos(rz)
        local zy=-xz*math.sin(ry)+z*math.cos(ry)
        local finalY=yz*math.cos(rx)-zy*math.sin(rx)+3
        lowest=math.min(lowest,finalY)
    end end end
    assert(math.abs(Geometry.lowestY(b)-lowest)<1e-9)
    fails(function() Geometry.lowestY({blocks={}}) end,'Пустая схема')
end)
test('builder completion and failure',function() local adapter={place=function() return true,'ok' end};local b=Builder.new(adapter,function() end,function() end);b:start(Planner.plan(Schema.validate(sample()),'original'),0.2);assert(b.state=='completed' and b.done==2);local failing=Builder.new({place=function() return false,'no' end},function() end,function() end);failing:start(Planner.plan(Schema.validate(sample()),'original'),0.2);assert(failing.state=='failed' and failing.done==0) end)
test('cancel prevents later steps and overlapping starts',function() local calls=0;local b;local adapter={place=function() calls+=1;b:cancel();fails(function() b:start({{}},0.2) end,'ещё не завершён');return true,'observed' end};b=Builder.new(adapter,function() end,function() end);b:start({{},{}},0.2);assert(calls==1 and b.done==1 and b.state=='cancelled') end)
test('pause and resume between steps',function() local calls=0;local b;local adapter={place=function() calls+=1;if calls==1 then b:pause() end;return true,'ok' end};b=Builder.new(adapter,function() end,function() if b.state=='paused' then b:resume() end end);b:start({{},{}},0.2);assert(calls==2 and b.state=='completed') end)
test('rejects unsupported speed',function() local b=Builder.new({},function() end,function() end);fails(function() b:start({{}},0.01) end,'Интервал') end)
local function instance(name,class,value)
    local t={Name=name,ClassName=class,Value=value,children={}}
    function t:FindFirstChild(n) return self.children[n] end
    function t:FindFirstChildOfClass(n) for _,v in pairs(self.children) do if v.ClassName==n then return v end end end
    function t:IsA(n) return self.ClassName==n or (n=='ValueBase' and (self.ClassName=='IntValue' or self.ClassName=='BoolValue')) end
    function t:GetChildren() local out={};for _,v in pairs(self.children) do table.insert(out,v) end;return out end
    return t
end
test('game adapter refuses unknown inventory and missing readiness',function() local p=instance('P','Player');local w=instance('World','Workspace');local a=GameAdapter.new(p,w,function() end,{});local inv=a:inventory();assert(inv==nil);local ready,err=a:ready();assert(not ready and string.find(err,'точку')) end)
test('game adapter validates tool, sharing and inventory before invoking',function()
    local p=instance('P','Player');p.Team={Name='White'};p.Character=instance('Character','Model');local tool=instance('BuildingTool','Tool');p.Character.children.BuildingTool=tool
    local data=instance('Data','Folder');data.children.WoodBlock=instance('WoodBlock','IntValue',3);p.children.Data=data
    local settings=instance('Settings','Folder');settings.children.ShareBlocks=instance('ShareBlocks','BoolValue',false);p.children.Settings=settings
    local rf=instance('RF','RemoteFunction');tool.children.RF=rf;local w=instance('World','Workspace');w.children.WhiteZone=instance('WhiteZone','Part');local blocks=instance('Blocks','Folder');local owned=instance('P','Folder');blocks.children.P=owned;w.children.Blocks=blocks
    local a=GameAdapter.new(p,w,function() end,{});a.origin={};assert(a:ready());assert(a:inventory().wood==3);settings.children.ShareBlocks.Value=true;local ok,err=a:ready();assert(not ok and string.find(err,'ShareBlocks'));settings.children.ShareBlocks.Value=false;rf.ClassName='Folder';assert(not a:ready())
end)
test('game adapter detects a nearby new block and forwards five sourced arguments',function()
    local vector={};vector.__index=vector
    vector.__sub=function(a,b) local x,y,z=a.x-b.x,a.y-b.y,a.z-b.z;return {Magnitude=math.sqrt(x*x+y*y+z*z)} end
    local function vec(x,y,z) return setmetatable({x=x,y=y,z=z},vector) end
    local frame={};local mt={}
    mt.__mul=function(a,b) return setmetatable({Position=vec(a.Position.x+b.Position.x,a.Position.y+b.Position.y,a.Position.z+b.Position.z)},mt) end
    frame.new=function(x,y,z) return setmetatable({Position=vec(x or 0,y or 0,z or 0)},mt) end
    frame.Angles=function() return frame.new(0,0,0) end
    local p=instance('P','Player');p.Team={Name='White'};p.Character=instance('Character','Model');local tool=instance('BuildingTool','Tool');p.Character.children.BuildingTool=tool
    local data=instance('Data','Folder');data.children.WoodBlock=instance('WoodBlock','IntValue',3);p.children.Data=data
    local settings=instance('Settings','Folder');settings.children.ShareBlocks=instance('ShareBlocks','BoolValue',false);p.children.Settings=settings
    local rf=instance('RF','RemoteFunction');tool.children.RF=rf;local w=instance('World','Workspace');w.children.WhiteZone=instance('WhiteZone','Part');local blocks=instance('Blocks','Folder');local owned=instance('P','Folder');blocks.children.P=owned;w.children.Blocks=blocks
    function rf:InvokeServer(kind,amount,zone,target,anchored)
        assert(kind=='WoodBlock' and amount==3 and zone==w.children.WhiteZone and anchored==true)
        local part=instance('WoodBlock','BasePart');part.Position=target.Position;owned.children.placed=part
    end
    local a=GameAdapter.new(p,w,function() end,frame);a.origin=frame.new(10,0,0);local ok,msg=a:place(Schema.validate(sample()).blocks[1]);assert(ok and string.find(msg,'не проверены'))
end)
test('adapter prefers PPart in replicated model',function()
    local vector={};vector.__index=vector;vector.__sub=function(a,b) local x,y,z=a.x-b.x,a.y-b.y,a.z-b.z;return {Magnitude=math.sqrt(x*x+y*y+z*z)} end
    local function vec(x,y,z) return setmetatable({x=x,y=y,z=z},vector) end
    local frame={};local mt={};mt.__mul=function(a,b) return setmetatable({Position=vec(a.Position.x+b.Position.x,a.Position.y+b.Position.y,a.Position.z+b.Position.z)},mt) end
    frame.new=function(x,y,z) return setmetatable({Position=vec(x or 0,y or 0,z or 0)},mt) end;frame.Angles=function() return frame.new(0,0,0) end
    local p=instance('P','Player');p.Team={Name='White'};p.Character=instance('Character','Model');local tool=instance('BuildingTool','Tool');p.Character.children.BuildingTool=tool
    local data=instance('Data','Folder');data.children.WoodBlock=instance('WoodBlock','IntValue',3);p.children.Data=data
    local settings=instance('Settings','Folder');settings.children.ShareBlocks=instance('ShareBlocks','BoolValue',false);p.children.Settings=settings
    local rf=instance('RF','RemoteFunction');tool.children.RF=rf;local w=instance('World','Workspace');w.children.WhiteZone=instance('WhiteZone','Part');local blocks=instance('Blocks','Folder');local owned=instance('P','Folder');blocks.children.P=owned;w.children.Blocks=blocks
    function rf:InvokeServer(_,_,_,target)
        local model=instance('WoodBlock','Model');local main=instance('PPart','BasePart');main.Position=target.Position;model.children.PPart=main
        function model:FindFirstChildWhichIsA() error('PPart should be selected first') end
        owned.children.m=model
    end
    local a=GameAdapter.new(p,w,function() end,frame);a.origin=frame.new(0,0,0);local ok=a:place(Schema.validate(sample()).blocks[1]);assert(ok)
end)
test('game adapter stops when no block observed after call',function()
    local vec={};vec.__index=vec;vec.__sub=function() return {Magnitude=99} end
    local function frame() local mt={};mt.__mul=function(a) return a end;return setmetatable({Position=setmetatable({},vec)},mt) end
    local cf={new=function() return frame() end,Angles=function() return frame() end}
    local p=instance('P','Player');p.Team={Name='White'};p.Character=instance('Character','Model');local tool=instance('BuildingTool','Tool');p.Character.children.BuildingTool=tool
    local data=instance('Data','Folder');data.children.WoodBlock=instance('WoodBlock','IntValue',3);p.children.Data=data
    local settings=instance('Settings','Folder');settings.children.ShareBlocks=instance('ShareBlocks','BoolValue',false);p.children.Settings=settings
    local rf=instance('RF','RemoteFunction');function rf:InvokeServer() end;tool.children.RF=rf
    local w=instance('World','Workspace');w.children.WhiteZone=instance('WhiteZone','Part');local blocks=instance('Blocks','Folder');blocks.children.P=instance('P','Folder');w.children.Blocks=blocks
    local ticks=0;local a=GameAdapter.new(p,w,function() ticks+=1 end,cf);a.origin=frame();local ok,msg=a:place(Schema.validate(sample()).blocks[1]);assert(not ok and string.find(msg,'Блок у цели не найден') and ticks==40)
end)
print('TOTAL '..passed..' tests passed')
