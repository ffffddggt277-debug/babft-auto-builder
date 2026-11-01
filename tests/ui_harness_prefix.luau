-- Mock-only harness: no Roblox client, renderer, network or executor is involved.
local created = {}
local function signal()
    local s={callbacks={}}
    function s:Connect(fn) table.insert(self.callbacks,fn);return {Disconnect=function() end} end
    function s:fire(...) for _,fn in ipairs(self.callbacks) do fn(...) end end
    return s
end
local function fakeEnum() return setmetatable({}, {__index=function(_,k) return k end}) end
local Enum=setmetatable({}, {__index=function(_,k) if k=='Font' or k=='UserInputType' or k=='TextXAlignment' or k=='TextYAlignment' or k=='ZIndexBehavior' or k=='SortOrder' or k=='AutomaticSize' or k=='FillDirection' then return fakeEnum() end end})
local UDim={new=function(a,b) return {Scale=a,Offset=b} end}
local UDim2={new=function(a,b,c,d) return {X=UDim.new(a,b),Y=UDim.new(c,d)} end,fromOffset=function(x,y) return {X=UDim.new(0,x),Y=UDim.new(0,y)} end,fromScale=function(x,y) return {X=UDim.new(x,0),Y=UDim.new(y,0)} end}
local Vector2={new=function(x,y) return {X=x,Y=y} end}
local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
local Color3={fromRGB=function(r,g,b) return {r,g,b} end}
local CFrame={new=function(...) return {...} end,Angles=function(...) return {...} end}
local task={wait=function() end,spawn=function(fn) fn() end}
local function new(class)
    local item={_class=class, _children={},Name=class,Activated=signal(),InputBegan=signal(),Destroying=signal(),AbsoluteSize={X=460,Y=570}}
    local mt={}
    mt.__newindex=function(t,k,v) if k=='Parent' then rawset(t,k,v); if v and v._children then table.insert(v._children,t) end else rawset(t,k,v) end end
    function item:FindFirstChild(n) for _,v in ipairs(self._children) do if v.Name==n then return v end end end
    function item:FindFirstChildOfClass(n) for _,v in ipairs(self._children) do if v._class==n then return v end end end
    function item:GetPropertyChangedSignal() return signal() end
    function item:Destroy() self.Destroying:fire() end
    setmetatable(item,mt);table.insert(created,item);return item
end
local Instance={new=new}
local workspace=new('Workspace')
workspace.CurrentCamera=new('Camera');workspace.CurrentCamera.ViewportSize={X=390,Y=844}
local player=new('Player');player.Name='Tester';local playerGui=new('PlayerGui');playerGui.Parent=player
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
