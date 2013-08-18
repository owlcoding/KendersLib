-- ************************************************************************************************************************
-- Navigation code, simulating the UINavigationController behavior on iOS
-- should support: pushScene ( 'scene' ), popScene () 
-- should handle displaying of navigation top bar (if set to visible) and the 'back button' on it, when a scene is pushed
-- ************************************************************************************************************************

-- to use the navigation bar you should 
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

function navigator:pushScene ( sceneName, params )
    local currentScene = storyboard.getCurrentSceneName()
    print ( "Current scene: ", currentScene )
    -- if ( ( #self.navigationStack == 0 and currentScene ~= nil ) or self.navigationStack [ #self.navigationStack ] ~= currentScene ) then
    --     self.navigationStack [ #self.navigationStack + 1 ] = currentScene
    -- end
    self.navigationStack [ #self.navigationStack + 1 ] = currentScene
    if params == nil then
        params = {}
    end
    
    local newScene = storyboard.loadScene ( sceneName, false, params.params )
    if newScene.group then
        newScene.view:insert ( newScene.group )        
    end
    if navigator.isNavigationBarVisible then
        if newScene.group then
            newScene.group.y = newScene.group.y + 33
            local rectG = display.newGroup ()
            local rect = display.newRect( rectG, 0, 0, display.contentWidth, 33 )
            newScene.view:insert ( rectG )
            rectG:insert ( rect )
            if #self.navigationStack >= 1 then
                local title = self.navigationStack [ #self.navigationStack ]
                local backB = widget.newButton ({
                    label = "<- " .. title,
                    width = 80,
                    height = 29,
                    fontSize = 9,
                    onRelease = function ()
                        self:popScene ()
                    end,
                })
                backB.x = 100
                backB.y = 16
                rectG:insert ( backB )
            end
        end
    end
    storyboard.gotoScene ( sceneName, params )
end

function navigator:popScene ()
    
    if ( #self.navigationStack > 0 ) then
        local currentScene = storyboard.getCurrentSceneName()
        local newScene = table.popLast ( self.navigationStack )
        storyboard.gotoScene ( newScene )
        storyboard.purgeScene ( currentScene )
    end
end

