--@name quadtree example
--@author yeet_sneet
--@shared
--@include quadtree.txt

local quadtree = dofile("quadtree.txt")

local data = {
    1, 1, 1, 1, 0, 0, 0, 0,
    1, 1, 1, 1, 0, 0, 0, 0,
    1, 1, 1, 1, 0, 0, 0, 0,
    1, 1, 1, 1, 0, 0, 0, 0,
    0, 0, 0, 0, 1, 1, 1, 1,
    0, 0, 0, 0, 1, 1, 1, 1,
    0, 0, 0, 0, 1, 1, 1, 1,
    0, 0, 0, 0, 1, 1, 1, 1,
}

local width, height = 8, 8
local maxcpu = cpuMax()*0.2

local QTree = quadtree.create(data, width, height, function (Data, sx, sy, w, h, totalWidth)
    local ov = Data[sx + sy * totalWidth + 1]
    
    for y = sy, sy + h - 1 do
        local offset = y * totalWidth + 1
        for x = sx, sx + w - 1 do
            if Data[offset + x] ~= ov then
                return false
            end
        end
    end
    
    return true, ov
end, maxcpu)

hook.add("think", "create", function () 
    if QTree:think() then
        print("done")
        printTable(QTree)
        hook.remove("think", "create")
    end
end)
