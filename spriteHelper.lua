
local pathOfThisFile = ...
local folderOfThisFile = (...):match("(.-)[^%.]+$")

module( pathOfThisFile, package.seeall )

local sheetNames = {}
local mapFrameNameToSheet = {}
local imagesForSheets = {}


local function newSprite ( a, b, c )
    local sprite = display.newSprite ( a, b, c )
    
    function sprite:stopAtFrame ( idx )
        self:pause ()
        self:setFrame ( idx )
    end
    
    sprite:addEventListener ( "touch", function ( ev )
        if sprite and sprite.action and ev.phase == "began" then
            return sprite.action ( ev )
        end
        return false
    end)
    return sprite
end

local function loadSheets ( sheetsTable, dir )
    -- sheetsTable = { {"spritesheets.spritesheet1", "spritesheets/spritesheet1.png"}, {"spritesheets2.spritesheet2", "spritesheets2/spritesheet2.png"},  }
    -- or
    -- sheetsTable = { { "spritesheet1", "spritesheet1.png" }, { "spritesheet2", "spritesheet2.png"} } 
    --      and dir = "spritesheets"
    -- use dir when all spritesheets ( both lua and png ) reside in the same directory
    
    for i = 1, #sheetsTable do
        local thisSheetLua = sheetsTable [ i ] [ 1 ]
        local sheetInfo = require ( thisSheetLua )
        imagesForSheets [ sheetInfo ] = nil
        local frameIndex = sheetInfo.frameIndex
        for k, v in pairs ( frameIndex ) do
            mapFrameNameToSheet [ k ] = { sheetInfo = sheetInfo, textureName = sheetsTable [ i ] [ 2 ], frameIdx = v }
        end
    end
end

local function spriteForFrames ( framesList, speed, additionalParams )
    -- Requires all the frames to come from a single sheet!
    -- 
    -- Usage: 
    --      local sh = require "KendersLib.spriteHelper"
    --      sh.loadSheets ( { {"assets.Spritesheets.locomotive-numbers", "assets/Spritesheets/locomotive-numbers.png" } } )
    --      local s = sh.spriteForFrames ( { "No_1", "No_2", "No_3", "No_4" } )
    --      s.x, s.y = 100, 100
    
    local firstFrameName = framesList [ 1 ]
    local sheet = mapFrameNameToSheet [ firstFrameName ]
    if sheet == nil then
        print (" >>> No sprite of name ".. firstFrameName .. " could be found! ")
        return nil
    end
    local sheetInfo = sheet.sheetInfo
    local tex = imagesForSheets [ sheetInfo ]
    if tex == nil then
        tex = graphics.newImageSheet ( sheet.textureName, sheetInfo:getSheet () )
        imagesForSheets [ sheetInfo ] = myImageSheet
    end
    local frames = {}
    for i = 1, #framesList do
        frames [ i ] = sheetInfo:getFrameIndex ( framesList [ i ] )
    end
    local loopDir = "bounce"
    local loopCount = 0
    if additionalParams then
        if additionalParams.loopDirection then
            loopDir = additionalParams.loopDirection
        end
        if additionalParams.loopCount then
            loopCount = additionalParams.loopCount
        end
        if additionalParams.time then speed = additionalParams.time end
        
    end
    local sprite = newSprite ( tex , { frames = frames, time = speed, loopDirection = loopDir, loopCount = loopCount })
    sprite:setFrame ( 1 )
    return sprite
end

local function freeSomeMemoryFromSheet ( frameName )
    local sheet = mapFrameNameToSheet [ frameName ]
    local sheetInfo = sheet.sheetInfo
    imagesForSheets [ sheetInfo ] = nil
end

return { 
    loadSheets = loadSheets ,
    spriteForFrames = spriteForFrames,
    freeSomeMemoryFromSheet = freeSomeMemoryFromSheet ,
}
