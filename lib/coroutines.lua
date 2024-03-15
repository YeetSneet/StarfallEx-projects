--@name coroutines
--@author yeet_sneet

-- can run on sever and/or client
--@client
if CLIENT and player() ~= owner() then return end


print("loaded coroutines")

Coroutine = {}
Coroutine.DEBUG = false
Coroutine.Coroutines = {}
Coroutine.ActiveCoroutines = {}
Coroutine.MaxCpu = cpuMax()*0.75

function Coroutine.Event(eventName, data)
    if Coroutine.DEBUG then print(eventName.." : {"..table.concat(data, ", ").."}") end
    for _, v in pairs(Coroutine.Coroutines) do
        v:Event(eventName, data)
    end
end

function Coroutine.RunCoroutines()
    for _, v in pairs(Coroutine.ActiveCoroutines) do
        Coroutine.Coroutines[v]:Run()
    end
end

local function updateCpu()
    local ac =  Coroutine.ActiveCoroutines
    local cpuMul = Coroutine.MaxCpu/#ac
    for idx, name in pairs(ac) do
        Coroutine.Coroutines[name].MaxCpu = cpuMul*idx
    end
end

function Coroutine.Create(name, startActive, func)
    local obj = {}
    
    if Coroutine.Coroutines[name] then 
        error("name is being used") 
    end
    
    obj.Name = name
    obj.MaxCpu = 0
    obj.Coroutine = coroutine.create(func)
    Coroutine.Coroutines[name] = obj
    
    function obj:Run()
        local c = self.Coroutine
        if coroutine.status(c) ~= "dead" then
            coroutine.resume(c, self)
        else
            self:Kill()
        end
    end
    
    function obj:Cpu()
        if cpuUsed() >= self.MaxCpu then coroutine.yield() end
    end
    
    function obj:Kill()
        table.removeByValue(Coroutine.ActiveCoroutines, self.Name)
        Coroutine.Coroutines[self.Name] = nil
        updateCpu()
        Coroutine.Event("Died", {self.Name})
    end
    
    function obj:Activate()
        if table.keyFromValue(Coroutine.ActiveCoroutines, self.Name) then
            print(self.Name.." is already Activated") return
        end
        table.insert(Coroutine.ActiveCoroutines, self.Name)
        updateCpu()
        Coroutine.Event("Started", {self.Name})
    end

    -- "Died"->{name}
    -- "Started"->{name}
    -- is a normal function not a coroutine
    function obj:Event(eventName, data) end
    
    if startActive then
        obj:Activate()
    end
    
    return obj
end






-- example
print("example started")
Coroutine.DEBUG = true

local function randomStr()
    local out = ""
    for _=1, 15 do
        out = out .. string.char(math.random(0,255))
    end
    return out
end

for i=1, 15 do
    Coroutine.Create("example : "..i, true, function (self) 
        local i = 0
        local l = i + 1000
        while i<5000 do
            if i >= l then 
                print(self.Name.." - "..i) 
                l = i + 1000
            end
            i = i + 1
            bit.sha256(randomStr())
            self:Cpu()
        end
    end)
end

hook.add("think", "run Coroutines",Coroutine.RunCoroutines)


