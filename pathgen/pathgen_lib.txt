--@name pathgen lib
--@author yeet_sneet
--@shared

if player() ~= owner() then return end

pathgen = {}
pathgen.counter = 0
if CLIENT then
    pathgen.pathgenJobs = {}
    function pathgen.startProcessingJobs()
        --[[
            [idx]{
                1 path,
                2 pathLen,
                3 curentIdx,
                4 doneCallback,
                5 failedCallback,
            }
        ]]
        local pathgenJobs = pathgen.pathgenJobs
        
        hook.add("Net", "pathgen-Client", function (nm)
            if nm:sub(1,8) ~= "pathgen-" then return end
            
            local mName = nm:sub(9,#nm):split("-")
            local id = mName[2]
            mName = mName[1]
            
            local data = pathgenJobs[id]
            if mName == "PathLen" then
                data[2] = net.readUInt(32)
                data[3] = 0
            elseif mName == "SendingPath" then
                local path = data[1]
                for i=1, net.readUInt(16) do
                    data[3] = data[3] + 1
                    table.insert(path, net.readVector())
                end
                if data[3] == data[2] then
                   data[4](data[1])
                end
            elseif mName == "Failed" then
                data[5](net.readString())
            end
        end)
        
    end
    
    function pathgen.gen(startPos, targetPos, res, doneCallback, failedCallback, botSettings)
        local id = math.random(0, 999999)
        while pathgen.pathgenJobs[id] ~= nil do 
            id = math.random(0, 999999)
        end
        id = tostring(id)
        pathgen.pathgenJobs[id] = {
            {}, 
            2^32,
            0,
            doneCallback,
            failedCallback
        }
        
        net.start("pathgen-clientStart")
        net.writeString(id)
        net.writeVector(startPos)
        net.writeVector(targetPos)
        net.writeFloat(res)
        net.writeTable(botSettings or {})
        net.send()
    end
else
    pathgen.pathgenJobs = {}
    function pathgen.startProcessingJobs(maxCpu)
        local pathgenJobs = pathgen.pathgenJobs
        --[[ { 
                1 bot,
                2 target,
                3 pathTable,
                4 doneCallback,
                5 failedCallback,
                6 stuckTimeTracker,
                7 botLastPos,
                8 res,
            }
        ]]    
        
        local pathgenJobsLen = #pathgenJobs
        local idx = 0
        hook.add("think", "pathgen-manageBots", function () 
            pathgenJobsLen = #pathgenJobs // slow but there should not be more then 100 jobs
            for _=1, pathgenJobsLen do
                
                idx = idx % (pathgenJobsLen) + 1
                local data = pathgenJobs[idx]
                
                local bot = data[1]
                if not bot:isValid() then 
                    data[5]("invalid bot", bot)
                    table.remove(pathgenJobs, idx)
                    pathgenJobsLen = pathgenJobsLen - 1
                    break 
                end
                
                if bot:getGotoPos() ~= data[2] then bot:setGotoPos(data[2]) end
                
                local botPos = bot:getPos()
                local distFromTar = botPos:getDistance(data[2])
                
                if botPos:getDistance(data[7]) > data[8] then
                    table.insert(data[3], botPos)
                    data[6] = timer.curtime()
                    data[7] = botPos 
                end
                
                if distFromTar < data[8] then
                    table.insert(data[3], data[2])
                    table.remove(pathgenJobs, idx)
                    pathgenJobsLen = pathgenJobsLen - 1
                    data[4](data[3], bot)
                    break
                end
                
                if data[6]+(data[8]/66+2) < timer.curtime() then
                    table.remove(pathgenJobs, idx)
                    pathgenJobsLen = pathgenJobsLen - 1
                    data[5]("bot stuck", bot)
                    break
                end
                
                if cpuUsed() > maxCpu then
                    break 
                end
            end
        end)
    end
    
    function pathgen.gen(startPos, targetPos, res, doneCallback, failedCallback, bot)
        if bot == nil or not bot:isValid() then
            if nextbot.canSpawn() then
                bot = nextbot.create(startPos, "models/gman_high.mdl")
            else
                failedCallback("bot valid check failed")
                return 
            end
        else
            bot:setPos(startPos)
        end
        
        table.insert(pathgen.pathgenJobs, {
            bot,
            targetPos,
            {},
            doneCallback,
            failedCallback,
            timer.curtime(),
            startPos,
            res
        })
        return bot
    end
    
    net.receive("pathgen-clientStart", function (len, ply) 
        local idx = net.readString()
        local bot = pathgen.gen(
            net.readVector(), 
            net.readVector(), 
            net.readFloat(),
            function (path, bot) 
                local pathLen = #path
                net.start("pathgen-PathLen-"..idx)
                net.writeUInt(pathLen ,32)
                net.send(ply)
                
                hook.add("tick", "pathgen-sendPath-"..idx.."-"..tostring(ply), function () 
                    if pathLen == 0 then
                        hook.remove("tick", "pathgen-sendPath-"..idx.."-"..tostring(ply))
                    else
                        local num = math.clamp(net.getBytesLeft()/24 - 22, 0, pathLen)
                        if num <= 0 then return end
                        net.start("pathgen-SendingPath-"..idx)
                        net.writeUInt(num, 16)
                        for i=1, num do 
                            pathLen = pathLen - 1
                            net.writeVector(path[i])
                        end
                        net.send(ply)
                    end
                    if bot and bot:isValid() then
                        bot:remove()
                    end
                end)
            end,
            function (msg, bot) 
                net.start("pathgen-failed-"..idx)
                net.writeString(msg)
                net.send(ply)
                if bot and bot:isValid() then
                    bot:remove()
                end
            end
        )
        if bot and bot:isValid() then
            local botSettings = net.readTable()
            
            for func, val in pairs(botSettings) do
                bot[func](bot, val)
            end
        end
    end)
end


