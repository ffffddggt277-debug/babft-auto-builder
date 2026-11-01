-- Mock-only harness: no Roblox client, renderer, network or executor is involved.
local created = {}
local function signal()
    local s={callbacks={}}
    function s:Connect(fn) table.insert(self.callbacks,fn);return {Disconnect=function() end} end
    function s:fire(...) for _,fn in ipairs(self.callbacks) do fn(...) end end
    return s
end
local function fakeEnum() return setmetatable({}, {__index=function(_,k) return k end}) end
local Enum=setmetatable({}, {__index=function(_,k) if k=='Font' or k=='UserInputType' or k=='TextXAlignment' or k=='TextYAlignment' or k=='ZIndexBehavior' or k=='SortOrder' or k=='RaycastFilterType' or k=='SurfaceType' or k=='ScreenInsets' or k=='AutomaticSize' or k=='FillDirection' then return fakeEnum() end end})
local UDim={new=function(a,b) return {Scale=a,Offset=b} end}
local UDim2={new=function(a,b,c,d) return {X=UDim.new(a,b),Y=UDim.new(c,d)} end,fromOffset=function(x,y) return {X=UDim.new(0,x),Y=UDim.new(0,y)} end,fromScale=function(x,y) return {X=UDim.new(x,0),Y=UDim.new(y,0)} end}
local Vector2={new=function(x,y) return {X=x,Y=y} end}
local vectorMt={};vectorMt.__add=function(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},vectorMt) end
local Vector3={new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},vectorMt) end}
local Color3={fromRGB=function(r,g,b) return {r,g,b} end}
local frameMt={};frameMt.__mul=function(a,b) return setmetatable({Position=a.Position+b.Position},frameMt) end
local CFrame={new=function(x,y,z) return setmetatable({Position=Vector3.new(x or 0,y or 0,z or 0)},frameMt) end,Angles=function() return setmetatable({Position=Vector3.new(0,0,0)},frameMt) end}
local RaycastParams={new=function() return {} end}
local task={wait=function() end,spawn=function(fn) fn() end}
local function new(class)
    local item={_class=class, _children={},Name=class,Activated=signal(),InputBegan=signal(),Destroying=signal(),AbsoluteSize={X=460,Y=570}}
    local mt={}
    mt.__newindex=function(t,k,v) if k=='Parent' then rawset(t,k,v); if v and v._children then table.insert(v._children,t) end else rawset(t,k,v) end end
    function item:FindFirstChild(n) for _,v in ipairs(self._children) do if v.Name==n then return v end end end
    function item:FindFirstChildOfClass(n) for _,v in ipairs(self._children) do if v._class==n then return v end end end
    function item:GetPropertyChangedSignal(name) self._signals=self._signals or {};self._signals[name]=self._signals[name] or signal();return self._signals[name] end
    function item:Destroy() self.Destroying:fire(); if self.Parent and self.Parent._children then for i,v in ipairs(self.Parent._children) do if v==self then table.remove(self.Parent._children,i);break end end end;rawset(self,'Parent',nil) end
    setmetatable(item,mt);table.insert(created,item);return item
end
local Instance={new=new}
local workspace=new('Workspace')
workspace.CurrentCamera=new('Camera');workspace.CurrentCamera.ViewportSize={X=390,Y=844}
local player=new('Player');player.Name='Tester';local playerGui=new('PlayerGui');playerGui.Parent=player
local character=new('Model');player.Character=character;local humanoidRoot=new('Part');humanoidRoot.Name='HumanoidRootPart';humanoidRoot.Position=Vector3.new(10,3,20);humanoidRoot.CFrame={LookVector=Vector3.new(1,0,0)};humanoidRoot.Parent=character
function workspace:Raycast(start,dir,params) assert(dir.Y==-100 and params.FilterType=='Exclude' and params.FilterDescendantsInstances[1]==character);return {Position=Vector3.new(start.X,0,start.Z)} end
local Players={LocalPlayer=player}
local HttpService={}
function HttpService:JSONDecode(text)
    assert(text=='{}')
    return {version=1,name='mock',blocks={{type='wood',position={x=0,y=0,z=0},size={x=1,y=1,z=1},rotation={x=0,y=0,z=0},color='#ABCDEF'}}}
end
local UIS={InputChanged=signal(),InputEnded=signal()}
local game={PlaceId=537413528}
function game:GetService(name) return ({Players=Players,HttpService=HttpService,UserInputService=UIS})[name] end
function game:HttpGet(url) assert(string.find(url,'raw.githubusercontent.com',1,true));return '{}' end
local function warn(...) print(...) end
