--@name render distance
--@author yeet_sneet
--@client

if player() ~= owner() then return end
enableHud(owner(), true)

--Controls

-- dist increment -- Page up -- 76
-- dist decrement -- Page Down -- 77
-- DEBUG tog -- Home -- 74


-- settings
local perFrame = 15 -- bigger = faster updating
local RenderDist = 500
local RefreshRate = 5

local distIncrement = 50
local SpamRate = 0.05
local SpamDelay = 0.2

local DEBUG = false

-- cannt nodraw a proptomesh
local ClassesList = {
    "gmod_wire_hologram", 
    "prop_physics", 
    "gmod_wire_expression2", 
    "prop_vehicle_prisoner_pod", 
    "func_door", 
    "func_brush", 
    "player", 
    "class C_BaseEntity"}


local TEXTX, TEXTY = render.getResolution()
TEXTX, TEXTY = math.round(TEXTX/50), math.round(TEXTY/50)
--


local ShowRenderDist = 0
local idx = 0
local hideQ
local Op = owner():getPos()

local function Inlist(List, data)
    for _, v in pairs(List) do
        if data == v then return false end
    end
    return true
end

local function validTarget(ent)
    -- if you flip the output of Inlist you can make a whitelist or a blacklist
    return ent:entIndex() ~= -1 and (ent:isWeapon() or not Inlist(ClassesList, ent:getClass()))
end

local function getAllEnts() 
    hideQ = find.all(validTarget)
end



getAllEnts()
timer.create("refresh", RefreshRate, 0, getAllEnts)

hook.add("inputPressed", "down", function (key) 
    if key == 74 then DEBUG = not DEBUG return end
    if key == 76 or key == 77 then
        if key == 77 then key = -1 else key = 1 end
        RenderDist = math.max(RenderDist+distIncrement*key, 0)
        ShowRenderDist = ShowRenderDist + 1
        timer.create("delay"..key, SpamDelay, 1, function ()
            timer.create("spam"..key, SpamRate, 0, function () 
                RenderDist = math.max(RenderDist+distIncrement*key, 0)
            end)
        end)
    end
end)
hook.add("inputReleased", "up", function (key) 
    
    if key == 76 or key == 77 then
        if key == 77 then key = -1 else key = 1 end
        timer.remove("delay"..key)
        timer.remove("spam"..key)
        ShowRenderDist = ShowRenderDist - 1
    end
end)

hook.add("think", "hideq", function () 
    Op = owner():getPos()
    for _=1, perFrame do
        idx = idx+1 
        if idx > #hideQ then idx=1 end
        local ent = hideQ[idx]
        if ent==nil or not ent:isValid() then table.remove(hideQ, idx) continue end
        local dc = ent:getPos():getDistance(Op) > RenderDist
        if ent:getNoDraw() ~= dc then
            if DEBUG then 
                local c = Color(0,255,0)
                if dc then c = Color(255,0,0) end
                print(c, ent, idx)
            end
            ent:setNoDraw(dc)
        end
    end
end)

hook.add("Removed", "fdfddf", function () 
    for k, ent in pairs(hideQ) do
        if ent and ent:isValid() then 
            ent:setNoDraw(false)
        end
    end
end)



hook.add("postdrawtranslucentrenderables", "display Sphere", function (depth, skybox, skybox3d)
    if skybox or skybox3d or (ShowRenderDist==0 and not DEBUG) then return end
    render.setColor(Color(0,255,0,10))
    render.draw3DSphere(Op, -RenderDist, 25, 25)
end)

hook.add("drawhud", "display Text", function ()
    if (ShowRenderDist==0 and not DEBUG) then return end
    render.setColor(Color(120,120,120,150))
    render.drawRectFast(TEXTX-3,TEXTY-3, 50, 25)
    render.setColor(Color(0,0,0,200))
    render.drawSimpleText(TEXTX, TEXTY, RenderDist)
    
end)
