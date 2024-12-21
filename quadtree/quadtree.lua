--@name Quadtree
--@author yeet_sneet

local quadtree = {}

function quadtree.create(initData, width, height, homogeneousFunc, maxcpu)
    
    local leafArray = {}
    local stack = {}
    local stacklen = 4
    
    
    local maxCpu = maxcpu or cpuMax()*0.2
    
    local obj = {
        leafArray = leafArray,
        leafLen = leafLen
    }
    
    stack[1] = height
    stack[2] = width
    stack[3] = 0
    stack[4] = 0
    
    local remove, floor, insert = table.remove, math.floor, table.insert
    function obj:think()
        
        while cpuUsed() < maxCpu and stacklen>0 do
            
            local x, y, w, h = stack[stacklen], stack[stacklen-1], stack[stacklen-2], stack[stacklen-3]
            
            if w == 1 and h == 1 then
                stack[stacklen]=nil;stack[stacklen-1]=nil;stack[stacklen-2]=nil;stack[stacklen-3]=nil;
                stacklen = stacklen - 4
                self.leafLen = insert(leafArray, {x, y, w, h, initData[x + y * width + 1]})
            else
                local isHomogeneous, value = homogeneousFunc(initData, x, y, w, h, width)
                if isHomogeneous then 
                    stack[stacklen]=nil;stack[stacklen-1]=nil;stack[stacklen-2]=nil;stack[stacklen-3]=nil;
                    stacklen = stacklen - 4
                    self.leafLen = insert(leafArray, {x, y, w, h, value})
                else
                    local half_w = floor(w / 2)
                    local half_h = floor(h / 2)
            
                    stacklen = stacklen+12
                    stack[stacklen-15] = half_h;     stack[stacklen-14] = half_w;     stack[stacklen-13] = y;          stack[stacklen-12] = x;
                    stack[stacklen-11] = half_h;     stack[stacklen-10] = w - half_w; stack[stacklen-9]  = y;          stack[stacklen-8]  = x + half_w;
                    stack[stacklen-7]  = h - half_h; stack[stacklen-6]  = half_w;     stack[stacklen-5]  = y + half_h; stack[stacklen-4]  = x;
                    stack[stacklen-3]  = h - half_h; stack[stacklen-2]  = w - half_w; stack[stacklen-1]  = y + half_h; stack[stacklen]    = x + half_w;
                end
            end
        end
        
        return stacklen<=0
    end
    return obj
end

return quadtree

