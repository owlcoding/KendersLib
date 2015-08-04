-- device detection on steroids
-- http://www.coronalabs.com/blog/2012/12/11/device-detection-on-steroids/

-- Create a table that will contain all of our tests we are setting up.
local M = {}
 
-- Set up some defaults...
M.isApple = false
M.isAndroid = false
M.isGoogle = false
M.isKindleFire = false
M.isNook = false
M.isConsole = false
M.isSamsung = false
M.is_iPad = false
M.isTall = false
M.isSimulator = false
M.platform = nil

local model = system.getInfo("model")

M.model = model
M.targetAppStore = system.getInfo( "targetAppStore" )
print ("Target app store: ", M.targetAppStore )
-- Are we on the Simulator?
if ( "simulator" == system.getInfo("environment") ) then
    M.isSimulator = true
end
if ( (display.pixelHeight/display.pixelWidth) > 1.5 ) then
    M.isTall = true
end
 
-- Now identify the Apple family of devices:
if ( string.sub( model, 1, 2 ) == "iP" ) then
    -- We are an iOS device of some sort
    M.isApple = true
 
    if ( string.sub( model, 1, 4 ) == "iPad" ) then
        M.is_iPad = true
    end
else
    -- Not Apple, so it must be one of the Android devices
    M.isAndroid = true
 
    -- Let's assume we are on Google Play for the moment
    M.isGoogle = true
 
    -- All of the Kindles start with "K", although Corona builds before #976 returned
    -- "WFJWI" instead of "KFJWI" (this is now fixed, and our clause handles it regardless)
    if ( model == "Kindle Fire" or model == "WFJWI" or string.sub( model, 1, 2 ) == "KF" ) then
        M.isKindleFire = true
        M.isGoogle = false --revert Google Play to false
    end
 
    -- Are we on a Nook?
    if ( string.sub( model, 1 ,4 ) == "Nook") or ( string.sub( model, 1, 4 ) == "BNRV" ) then
        M.isNook = true
        M.isGoogle = false --revert Google Play to false
    end
    
    if ( string.sub ( model, 1, 9 ) == "GameStick") or ( string.sub ( model, 1, 4 ) == "OUYA" ) then
        M.isGoogle = false
        M.isConsole = true
    end
end
print ( "Model: " )
for _, v in pairs ( M ) do
    if ( v ) then
        print (_, " => ", v)
    end
end

function M:appStore ( )
    local platform = nil
    if self.targetAppStore and self.targetAppStore ~= "none" then
        platform = self.targetAppStore
    else
        if self.isApple then
            platform = "apple"
        elseif self.isConsole then
            platform = nil
        elseif self.isAndroid then
            -- if android, but no store selected, return nil
            -- to prevent accidental going to wrong store (for example, Amazon store if app was installed on Kindle via Google Play)
            platform = nil
        elseif self.isKindleFire then
            platform = "kindle"
        elseif self.isNook then
            platform = "nook"
        elseif self.isGoogle then
            platform = "google"
        end
    end
    return platform
end

function M:linkToAppstore ( linksTable )
    local store = self:appStore ()
    local link = linksTable [ store ]
    if link ~= nil and link ~= "" then
        return link
    else
        return nil
    end
end
_G["_MODEL"] = M

