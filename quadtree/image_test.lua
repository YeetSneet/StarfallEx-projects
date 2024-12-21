--@name quadtree test
--@client
--@owneronly
--@include Quadtree.txt


local fileName = "splash.ppm"
local backgroundColor = Color(255, 0, 255)

local CpuMax = cpuMax() * 0.20

---- Render modes
-- 1 = normal
-- 2 = random Colored border
-- 3 = wireframe
local RenderMode = 3




local quadtree = dofile("Quadtree.txt")
local quadtreeObj
local startTime
local data = {}

local renderFuncs = {
    [1] = render.drawRect,
    [2] = function(x, y, w, h)
        render.drawRect(x, y, w, h)
        render.setColor(Color(math.random(0, 255), math.random(0, 255), math.random(0, 255)))
        render.drawRectOutline(x + 1, y + 1, w - 1, h - 1)
    end,
    [3] = function(x, y, w, h)
        render.drawRectOutline(x, y, w, h)
        render.drawLine(x, y, x + w, y + h)
    end,
}

render.createRenderTarget("quadtreeImage")
local RENDER = false

local function RGB2RGBN(r, g, b)
    return r * 65536 + g * 256 + b
end

local function RGBN2RGB(num)
    return (num / 65536) % 256, (num / 256) % 256, num % 256
end

--[[
local function homogeneous(initData, sx, sy, w, h, totalWidth) -- built for speed
    local ov = initData[sx + sy * totalWidth + 1]
    local r, g, b = (ov / 65536) % 256, (ov / 256) % 256, ov % 256
    local sqrt = math.sqrt
    for y = sy, sy + h - 1 do
        local offset = y * totalWidth + 1
        for x = sx, sx + w - 1 do
            local v = initData[x + offset]
            if v ~= ov and sqrt((r - (v / 65536) % 256) ^ 2 + (g - (v / 256) % 256) ^ 2 + (b - v % 256) ^ 2) > ((15)) then -- change number in (()) to change its tolerance. higher is more tolerant
                return false
            end
        end
    end
    return true, ov
end
--]]

--[
local function homogeneous(initData, sx, sy, w, h, totalWidth) -- built for looks
    local ov = initData[sx + sy * totalWidth + 1]
    local r, g, b = (ov / 65536) % 256, (ov / 256) % 256, ov % 256
    
    local sqrt, round = math.sqrt, math.round
    local pixelCount = 0
    for y = sy, sy + h - 1 do
        for x = sx, sx + w - 1 do
            local v = initData[x + y * totalWidth + 1]
            local r2, g2, b2 = (v / 65536) % 256, (v / 256) % 256, v % 256
                if sqrt( (r-r2)^2 +(g-g2)^2 + (b-b2)^2) > ((15)) then -- change number in (()) to change its tolerance. higher is more tolerant
                return false
            end
            
            pixelCount = pixelCount + 1
            r = r + (r2 - r) / pixelCount
            g = g + (g2 - g) / pixelCount
            b = b + (b2 - b) / pixelCount
        end
    end
    
    
    return true, (round(r)*65536 + round(g)*256 + round(b))
end--]]



local function readPPM(filename)
    local file = file.open(filename, "rb")
    if not file then error("Could not open file: " .. filename) end

    if file:read(2) ~= "P6" then error("Invalid PPM file: " .. filename) end
    file:read(1)

    local width, height, max_val
    repeat
        local line = file:readLine()
        if line and not line:match("^#") then
            width, height = line:match("(%d+) (%d+)")
            width, height = tonumber(width), tonumber(height)
        end
    until width and height

    repeat
        local line = file:readLine()
        if line and not line:match("^#") then
            max_val = tonumber(line)
        end
    until max_val

    if max_val ~= 255 then error("Unsupported max value in PPM file: " .. max_val) end

    local data_length = width * height * 3
    local data_string = file:read(data_length)
    file:close()

    return width, height, data_string
end

local width, height, strdata = readPPM(fileName)
local renderScale = math.min(1024 / width, 1024 / height)

local function part2()
    RENDER = true
    print("Rendering...")

    local i, len = 0, quadtreeObj.leafLen
    local renderFunc = renderFuncs[RenderMode]
    local leafArray = quadtreeObj.leafArray

    hook.add("RenderOffscreen", "draw quadtree", function()
        render.selectRenderTarget("quadtreeImage")
        while cpuUsed() < CpuMax do
            i = i + 1
            if i > len then
                hook.remove("RenderOffscreen", "draw quadtree")
                break
            end
            if i == 1 then
                render.setColor(backgroundColor)
                render.drawRectFast(0, 0, 1024, 1024)
            end
            local leaf = leafArray[i]
            local x, y, w, h = leaf[1] * renderScale, leaf[2] * renderScale, leaf[3] * renderScale, leaf[4] * renderScale
            local r, g, b = RGBN2RGB(leaf[5])
            render.setColor(Color(r, g, b))
            renderFunc(x, y, w, h)
        end
    end)
end

local function part1()
    startTime = timer.curtime()
    print("Creating Quadtree...")
    quadtreeObj = quadtree.create(data, width, height, homogeneous)
    hook.add("think", "p1", function()
        if quadtreeObj:think() then
            hook.remove("think", "p1")
            local et = timer.curtime() - startTime
            print("Time: " .. et)
            print("Cells/sec: " .. math.round(((width * height) / et) / 1e3, 3) .. "k")
            print("Leaf nodes: " .. quadtreeObj.leafLen)
            part2()
        end
    end)
end

local function part0()
    print("Parsing file...")
    local i, len = 1, width * height
    hook.add("think", "p0", function()
        while cpuUsed() < CpuMax do
            if i > len then
                hook.remove("think", "p0")
                part1()
                break
            else
                local of = i * 3
                local a, b, c = string.byte(strdata, of - 2, of)
                data[i] = a * 65536 + b * 256 + c
            end
            i = i + 1
        end
    end)
end

hook.add("PlayerChat", "chat_commands", function(ply, text)
    if ply ~= player() or text[1] ~= "." then return end
    local args = text:split(" ")
    local cmd = args[1]:lower()
    table.remove(args, 1)

    if cmd == ".debug" then
        RenderMode = tonumber(args[1]) + 1 or RenderMode
        part2()
        return true
    elseif cmd == ".redraw" then
        part2()
        return true
    end
end)

hook.add("render", "draw_texture", function()
    if RENDER then
        render.setRenderTargetTexture("quadtreeImage")
        render.setFilterMin(1)
        render.setFilterMag(1)
        render.drawTexturedRect(0, 0, 512, 512)
    else
        render.drawText(10, 10, "CPU: " .. math.round((cpuAverage() / cpuMax()) * 100, 3) .. "%")
        render.drawText(10, 30, "RAM: " .. math.round(ramAverage() / 1000, 3) .. "MB")
        render.drawText(10, 50, "RAM Usage: " .. math.round((ramAverage() / ramMax()) * 100, 3) .. "%")
    end
end)

part0()
