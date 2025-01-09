--@name Quadtree
--@author yeet_sneet

local quadtree = {}

local floor = math.floor
function quadtree.unpack(obj)
    local x, w = obj[1], obj[2]
    
    local y = floor(x/33554432)
    x = x % 33554432
             
    local h = floor(w/33554432)
    w = w % 33554432
    return x, y, w, h, obj[3]
end

function quadtree.pack(x, y, w, h, data)
    return {x + y*33554432, w + h*33554432, data}
end


function quadtree.create(initData, width, height, homogeneousFunc, maxcpu)
    local leafArray = {}
    local leafLen = 0
    local stack = {}
    local stacklen = 2
    local cpuTime = 0
    
    maxcpu = maxcpu or cpuMax()*0.2
    
    local obj = {}
    
    stack[1] = 0
    stack[2] = width + height*33554432
    
    local floor = math.floor

    function obj:think()
        
        while cpuUsed() < maxcpu and stacklen>0 do
            local x = stack[stacklen-1]
            local y = floor(x/33554432)
            x = x % 33554432
            
            
            local w = stack[stacklen]
            local h = floor(w/33554432)
            w = w % 33554432
            
            local isHomogeneous, value = homogeneousFunc(initData, x, y, w, h, width)
            if isHomogeneous then 
                stacklen = stacklen - 2
                if value ~= nil then
                    leafLen = leafLen + 1
                    leafArray[leafLen] = {x+y*33554432, w+h*33554432, value}
                end
            else
                local half_w = floor(w / 2)
                local half_h = floor(h / 2)*33554432
                h = h * 33554432
                y = y * 33554432
                
                stacklen = stacklen+6
                
                stack[stacklen-7] = x + y;
                stack[stacklen-6] = half_w + half_h;             
                
                stack[stacklen-5] = x + half_w + y; 
                stack[stacklen-4] = (w - half_w) + half_h;       
                
                stack[stacklen-3] = x + (y + half_h);
                stack[stacklen-2] = half_w + (h - half_h);      
                
                stack[stacklen-1] = (x + half_w) + (y + half_h);
                stack[stacklen  ] = (w - half_w) + (h - half_h); 
            end
        
        end
        cpuTime = cpuTime + cpuUsed()
        
        return stacklen<=0
    end
    
    function obj:finish()
        for k, _ in pairs(self) do
            self[k] = nil
        end
        
        self.leafLen = leafLen
        self.cpuTime = cpuTime
        self.leafArray = leafArray
        
        leafArray = nil
        leafLen = nil
        stack = nil
        stacklen = nil
        cpuTime = nil
    end
    
    return obj
end


return quadtree
