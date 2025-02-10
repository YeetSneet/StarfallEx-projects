--@name pathgen test
--@author yeet_sneet
--@shared
--@include pathgen_lib.txt

require("pathgen_lib.txt")

if player() ~= owner() or SERVER then return end


local movement = {}
function movement.stop()
    concmd("-moveright;-moveleft;-back;-forward;-speed;-left;-right;-walk;-jump")
end

hook.add("removed", "movement-stop", movement.stop)
hook.add("StarfallError", "movement-stop", function(chip)
    if chip == chip() then 
        movement.stop()
    end
end)

function movement.moveToPos(pos, speed) 
    local dir = (dir-player():getEyeAngles()[2]) % 360
    pathgen.moveDir(dir, speed)
end

function movement.moveDir(dir, speed) 
    concmd((speed and "+" or "-") ..  "speed")
    
    if dir >= 315 or dir < 45 then
        concmd("+forward;-back") 
    elseif dir >= 135 and dir < 225 then
        concmd("+back;-forward") 
    else
        concmd("-back;-forward")
    end
    
    if dir >= 45 and dir < 135 then
        concmd("+moveleft;-moveright") 
    elseif dir >= 225 and dir < 315 then
        concmd("+moveright;-moveleft")
    else
        concmd("-moveright;-moveleft")
    end
end

function movement.walkPath(path, camera)
        
    local nextPointHolo = hologram.create(Vector(), Angle(), "models/props_junk/propane_tank001a.mdl")
    local pathLen = #path
    
    local function done()
        hook.remove("tick", "walkPath")
        hook.remove("calcview", "camera")
        hook.remove("MouseMoved", "cameraControl")
        movement.stop()
    end
    
    if camera ~= false then
        local ang = player():getEyeAngles()
        local sens = convar.getFloat("sensitivity")
        enableHud(owner(), true)
        hook.add("MouseMoved", "cameraControl", function (x, y) 
            ang = ang + Angle(y,-x,0)*sens/45.4545
        end)
        hook.add("calcview", "camera", function (pos)
            return {
                origin = pos+Vector(0,0,75),
                angles = ang,
                drawviewer = true,
            }
        end) 
    end
    
    local stuckTimer = timer.curtime() 
    local curentPathIdx = 1
    local targetPos = path[curentPathIdx]
    hook.add("tick", "walkPath", function () 
        if targetPos == nil then 
            targetPos = path[curentPathIdx] 
            return 
        else
            nextPointHolo:setPos(targetPos)
        end
        
        local offset = (targetPos-player():getPos())
        local dist = (offset*Vector(1,1,0)):getLength()
        local yaw = ((offset):getAngle()[2] - player():getEyeAngles()[2]) % 360
        
        movement.moveDir(yaw, true)
        
        yaw = (yaw + 180) % 360 - 180
        
        if yaw < -5 then
            concmd("-left;+right;") 
        elseif yaw > 5 then
            concmd("-right;+left") 
        else
            concmd("-left;-right") 
        end
        
        if dist < 30 then
            if curentPathIdx >= pathLen then
                print("you have arived at your destination") 
                done()
                return
            end
            
            curentPathIdx = curentPathIdx + 1
            targetPos = nextPoint
            stuckTimer = timer.curtime()
        end
        
        if timer.curtime() > stuckTimer+5 then
            print("you got stuck")
            done() 
        end
    end) 
end

function movement.walkTo(targetPos, res, camera)
    local startPos = player():getPos()
    pathgen.gen(
        startPos, 
        targetPos, 
        res or 100, 
        function (path)  
            movement.walkPath(path, camera)
        end, 
        function (msg) 
            print("failed - "..msg) 
        end,
        {
            setNocollideAll = true,
            setAcceleration = 9999,
            setDeceleration = 9999,
            setMoveSpeed = 1000,
        }
    )
end
    
local holo = hologram.create(Vector(), Angle(), "models/props_junk/propane_tank001a.mdl")


print("press insert to auto walk to chip")
hook.add("InputPressed", "start", function (key) 
    if key ~= 72 then return end
    local target = chip()
    holo:setPos(chip():getPos())
    
    movement.walkTo(chip():getPos(), 50, true)
end)
    
    
