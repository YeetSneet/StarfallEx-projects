--@name render only my and world entitys
--@author
--@client

if player() ~= owner() then return end

local pertick = 1


local hidEnts = {}
local function findEnts() 
    return find.all(function (ent) 
        local own = ent:getOwner()
        if own and own~=owner() and own~=world then
            return true
        end
        return false
    end)
end

local testq = findEnts() 

local world = game.getWorld()
pertick = pertick-1
hook.add("OnEntityCreated", "add", function (ent) 
    if ent==nil or not ent:isValid() then return end
    local own = ent:getOwner()
    if own~=nil and own~=owner() and own~=world then
        table.insert(testq, ent)
    end
end)

hook.add("think", "hide", function () 
    local len = #testq
    if len==0 then return end
    for i=0, pertick do
        local idx = len-i
        if idx<=0 then break end
        local ent = testq[idx]
        if ent:isValid() then
            ent:setNoDraw(true)
            if ent:getNoDraw() then
                table.insert(hidEnts, ent)
                table.remove(testq,idx)
            end
        else
            table.remove(testq,idx)
        end
    end
end)


local keys = {}
hook.add("inputPressed", "control", function (key) 
    keys[key] = true
    
    if keys[66] and keys[64] then -- backspace enter
        print("Reverting...") 
        
        hook.remove("OnEntityCreated", "add")
        hook.remove("think", "hide")
        hook.remove("inputReleased", "control")
        hook.remove("inputPressed", "control")
        
        hook.add("think", "show", function () 
            local len = #hidEnts
            if len==0 then print("done Reverting") hook.remove("think", "show") return end
            for i=0, pertick do
                local idx = len-i
                if idx<=0 then break end
                local ent = hidEnts[idx]
                if ent:isValid() then
                    ent:setNoDraw(false)
                    if not ent:getNoDraw() then
                        table.remove(hidEnts, idx)
                    end
                else
                    table.remove(hidEnts, idx)
                end
            end
        end)
    end
end)

hook.add("inputReleased", "control", function (key) 
    keys[key] = false
end)



