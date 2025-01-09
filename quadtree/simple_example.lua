--@name quadtree example
--@author yeet_sneet
--@client
--@include Quadtree.txt

local quadtree = dofile("Quadtree.txt")

local width, height = 10, 10

local data = {
    1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 
    1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 
    1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 
    1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 
    1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 1, 1, 1, 1, 1,    
    0, 0, 0, 0, 0, 1, 1, 1, 1, 1,  
    0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 
    0, 0, 0, 0, 0, 1, 1, 1, 1, 1,  
    0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 
}


local function homogeneous(initData, startX, startY, width, height, totalWidth)
    -- invalid sizes will happen when the width or height is not a power of 2
    if width == 0 or height == 0 then return true, nil end 
    
    local value = initData[startX + startY * totalWidth + 1]
    for y = startY, startY + height - 1 do
        for x = startX, startX + width - 1 do
            if initData[x + y * totalWidth + 1] ~= value then
                return false
            end
        end
    end
    
    return true, value
end


local QTree = quadtree.create(data, width, height, homogeneous, cpuMax()*0.2)

hook.add("think", "create", function () 
    if QTree:think() then
        QTree:finish()
        
        local data = QTree.leafArray
        local unpack = quadtree.unpack
        for i=1, QTree.leafLen do
            print(unpack(data[i]))
        end
        
        hook.remove("think", "create")
    end
end)
