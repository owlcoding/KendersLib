-- ************************************************************************************************************************
-- Navigation code, simulating the UINavigationController behavior on iOS
-- should support: pushScene ( 'scene' ), popScene () 
-- should handle displaying of navigation top bar (if set to visible) and the 'back button' on it, when a scene is pushed
-- ************************************************************************************************************************

-- to use the navigation bar you should 
--   set navigator.isNavigationBarVisible to true,
-- add your displayObjects to a new group, instead of scene.view
-- and set that group as scene.group
-- 
--    local view = display.newGroup ()
--    scene.group = view
-- 
-- then the navigation bar will auto-lower the other display objects...  
-- Don't know how to do it other way, to allow easier integration with the current code
-- 

local storyboard = require ( "storyboard" )
local widget = require ( "widget" )
storyboard.navigator = {}
local navigator = storyboard.navigator

navigator.navigationStack = {}
navigator.currentScene = nil
navigator.isNavigationBarVisible = false
navigator.navigationBarColor = nil
navigator.navigationBarImage = nil
navigator.navigationBarHiddenScenes = {}

local function handleKeyEvent ( event )
    local phase = event.phase
    local keyName = event.keyName
	if phase == "down" and keyName == "back" then
        return navigator:popScene ()
	end
	return false
end

function navigator:pushScene ( sceneName, params )
    Runtime:removeEventListener ( "key", handleKeyEvent )
    Runtime:addEventListener ( "key", handleKeyEvent )
    
    local currentScene = storyboard.getCurrentSceneName()
    print ( "Pushing. ", currentScene, " --> ", sceneName )
    -- if ( ( #self.navigationStack == 0 and currentScene ~= nil ) or self.navigationStack [ #self.navigationStack ] ~= currentScene ) then
    --     self.navigationStack [ #self.navigationStack + 1 ] = currentScene
    -- end
    if params == nil then
        params = {}
    end
    
    local newScene = storyboard.loadScene ( sceneName, false, params.params )
    self.navigationStack [ #self.navigationStack + 1 ] = { newScene, newScene.title, sceneName, params }
    if newScene.group then
        newScene.view:insert ( newScene.group )        
    end
    
    local isBarVisible = navigator.isNavigationBarVisible
    
    if table.contains ( navigator.navigationBarHiddenScenes, sceneName ) then
        isBarVisible = false
    end
    
    if isBarVisible then
        if newScene.group then
            local rectG = display.newGroup ()
            newScene.view:insert ( rectG )
            if self.navigationBarImage == nil then
                local rect = display.newRect( rectG, display.screenLeft, display.screenTop, display.contentWidth, 33 )
                local color = { 255, 255, 255, 255 }
                if navigator.navigationBarColor ~= nil then
                    print ( "Color is defined" )
                    color = navigator.navigationBarColor
                    if color [ 4 ] == nil then
                        color [ 4 ] = 255
                    end
                end
                print ( color [ 4 ])
                rect:setFillColor ( color [ 1 ], color [ 2 ], color [ 3 ], color [ 4 ])
                rectG:insert ( rect )
            else
                local img = display.newImageRect ( rectG, self.navigationBarImage, display.contentWidth, 33 )
                img.x, img.y = display.screenLeft, display.screenTop
                rectG:insert ( img )
            end
            newScene.group.y = newScene.group.y + 33
            if #self.navigationStack > 1 then
                local title = self.navigationStack [ #self.navigationStack - 1 ]
                if title [ 2 ] == nil then
                    title = "Back"
                else
                    title = title [ 2 ]
                end
                
                local backB = widget.newButton ({
                    label = "<- " .. title,
                    width = 80,
                    height = 29,
                    fontSize = 9,
                    onRelease = function ()
                        self:popScene ()
                    end,
                })
                backB.x = display.screenLeft + 40 + 2
                backB.y = display.screenTop + 16
                rectG:insert ( backB )
            end
        end
    end
    storyboard.gotoScene ( sceneName, params )
end

function navigator:popScene ()
    
    if ( #self.navigationStack > 1 ) then
        local currentScene = storyboard.getCurrentSceneName()
        local cs = table.popLast ( self.navigationStack )
        local newScene = self.navigationStack [ #self.navigationStack ]
        if type ( newScene [ 1 ] ) == "string" then
            -- it's a released scene in stack - we need to recreate it now
            newScene [ 1 ] = storyboard.loadScene ( newScene [ 3 ], false, newScene [ 4 ] )
        end
        print ( "Popping. ", currentScene, " --> ", newScene [ 3 ] )
        local params = newScene [ 4 ]
        if type ( params ) == "string" then
            params = { effect = params }
        end
        print ( "Params: ", params )
        if cs [ 4 ] and cs [ 4 ].effect then
            local effect = cs [ 4 ].effect            
            if effect == "slideDown" then
                params.effect = "slideUp"
            end
            if effect == "slideLeft" then
                params.effect = "slideRight"
            end
            if effect == "crossFade" then
                params.effect = effect
            end
        end
        storyboard.gotoScene ( newScene [3], params )
        storyboard.purgeScene ( currentScene )
        return true
    end
    return false
end

function navigator:freeMem ()
    for i=1, #self.navigationStack - 1 do
        self.navigationStack [ i ] [ 1 ] = "freed mem"
        storyboard.purgeScene ( self.navigationStack [ 3 ])
        print ( "Freed some memory" )
    end
    print ("Collect garbage: ", collectgarbage ( "count" ))
end

storyboard.pushScene = function ( sceneName, params )
    storyboard.navigator:pushScene ( sceneName, params )
end

storyboard.popScene = function () 
    storyboard.navigator:popScene ()
end

storyboard.freeMem = function ()
    storyboard.navigator:freeMem ()
end
