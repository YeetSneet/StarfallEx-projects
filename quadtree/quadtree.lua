--@name Quadtree
--@author yeet_sneet

local quadtree = {}

function quadtree.create(initData, width, height, homogeneousFunc, maxcpu)
    
    local leafArray = {}
    local stack = {}
    local stacklen = 1
    
    local remove, insert, floor = table.remove, table.insert, math.floor
    local maxCpu = maxcpu or cpuMax()*0.2
    
    local obj = {
        leafArray = leafArray,
        leafLen = leafLen
    }
    
    insert(stack, height)
    insert(stack, width)
    insert(stack, 0)
    insert(stack, 0)
    
    function obj:think()
        while cpuUsed() < maxCpu and stacklen>0 do
            
            local x, y, w, h = remove(stack), remove(stack), remove(stack), remove(stack)
            
            if w == 1 and h == 1 then
                stacklen = stacklen - 1
                self.leafLen = insert(leafArray, {x, y, w, h, initData[x + y * width + 1]})
            else
                local isHomogeneous, value = homogeneousFunc(initData, x, y, w, h, width)
                if isHomogeneous then 
                    stacklen = stacklen - 1
                    self.leafLen = insert(leafArray, {x, y, w, h, value})
                else
                    local half_w = floor(w / 2)
                    local half_h = floor(h / 2)
                    
                    stacklen = stacklen + 3
                    -- nwNode
                    insert(stack,half_h);insert(stack,half_w);insert(stack,y);insert(stack, x); 
                    -- neNode
                    insert(stack,half_h);insert(stack,w - half_w);insert(stack,y);insert(stack, x + half_w);
                    -- swNode
                    insert(stack,h - half_h);insert(stack,half_w);insert(stack,y + half_h);insert(stack, x);
                    -- seNode
                    insert(stack,h - half_h);insert(stack,w - half_w);insert(stack,y + half_h);insert(stack, x + half_w);
                end
            end
        end
        
        return stacklen<=0
    end
    return obj
end

return quadtree

