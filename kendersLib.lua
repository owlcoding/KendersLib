module( ..., package.seeall )

local KLCache = {}


local sb = require ("storyboard")
timersStash = {}
tmPerformCache = timer.performWithDelay
timer.performWithDelay = function ( t, f, r )
    local tm = tmPerformCache ( t, f, r )
    timersStash [ tm ] = tm 
    return tm
end
transitionStash = {}
trToCache = transition.to
 transition.to = function ( o, p )
     if o == nil or o.contentWidth == nil then 
         return
     end
     local tr = trToCache ( o, p )
     transitionStash [ tr ] = tr 
     return tr
 end
 
function cancelAllTimers ()
    print (">>> Canceling all timers <<<")
    for i, t in pairs ( timersStash ) do
        timer.cancel ( i )
    end
    timersStash = {}
end
function cancelAllTransitions ()
    print (">>> Canceling all transitions <<<")
    for i, t in pairs ( transitionStash ) do
        transition.cancel ( i )
    end
    transitionStash = {}
end
_G['cancelAllTransitions'] = cancelAllTransitions
_G['cancelAllTimers'] = cancelAllTimers

KLCache [ 'gotoScene' ] = sb.gotoScene
sb.gotoScene = function ( s, t, tm )
    cancelAllTimers ()
    cancelAllTransitions ()
    KLCache [ 'gotoScene' ] ( s, t, tm )
end

              centerX = display.contentCenterX
              centerY = display.contentCenterY
              screenX = display.screenOriginX
              screenY = display.screenOriginY
          screenWidth = display.contentWidth - screenX * 2
         screenHeight = display.contentHeight - screenY * 2
           screenLeft = screenX
          screenRight = screenX + screenWidth
            screenTop = screenY
         display.screenBottom = screenY + screenHeight
   KLCache.contentWidth = display.contentWidth
  KLCache.contentHeight = display.contentHeight
 display.contentWidth = screenWidth
display.contentHeight = screenHeight


local js = require "json"
local split = function(s, pattern, maxsplit)
  local pattern = pattern or ' '
  local maxsplit = maxsplit or -1
  local s = s
  local t = {}
  local patsz = #pattern
  while maxsplit ~= 0 do
    local curpos = 1
    local found = string.find(s, pattern)
    if found ~= nil then
      table.insert(t, string.sub(s, curpos, found - 1))
      curpos = found + patsz
      s = string.sub(s, curpos)
    else
      table.insert(t, string.sub(s, curpos))
      break
    end
    maxsplit = maxsplit - 1
    if maxsplit == 0 then
      table.insert(t, string.sub(s, curpos - patsz - 1))
    end
  end
  return t
end
-- jsonFile() loads json file & returns contents as a string
local jsonFile = function( filename, base )
	
	-- set default base dir if none specified
	if not base then base = system.ResourceDirectory; end
	
	-- create a file path for corona i/o
	local path = system.pathForFile( filename, base )
	
	-- will hold contents of file
	local contents
	
	-- io.open opens a file at path. returns nil if no file found
	local file = io.open( path, "r" )
	if file then
	   -- read all contents of file into a string
	   contents = file:read( "*a" )
	   io.close( file )	-- close the file after using it
	end
	
	return contents
end
function json ( filename, key )
	local t = js.decode( jsonFile( filename ) )
	if key then
		for k,v in pairs ( split ( key, "|" )) do
			t = t [v]
		end
		-- t = t [ key ]
	end
	return t
end
_G["json"] = json

-- **** 
-- table methods
-- **** 
function table.popRandom ( t ) 
    local i = math.random ( #t )
    local el = t [ i ]
    table.remove ( t, i )
    return el
end

function table.pop ( t, i )
    local el = t [ i ]
    table.remove ( t, i )
    return el
end

function table.shuffle ( t )
    local t2 = {}
    while #t > 0 do
        t2 [ #t2 + 1 ] = table.popRandom ( t )
    end
    return t2
end

function table.popLast ( t )
    local el = t [ #t ]
    table.remove ( t, #t )
    return el
end

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end


-- **** 
-- display group sorting
-- ****
function zSort(myGroup)
    if myGroup ~= nil then
        local n = myGroup.numChildren
        local kids = {}
        for i=1,n do
                kids[i] = myGroup[i]
        end
        table.sort(kids,  
                function(a, b)
                                return (a.z or a.layer or 1) < (b.z or b.layer or 1) -- "layer" is your custom z-index field
                end
        )
        for i = 1,n do
                myGroup:insert(kids[i])
        end
        return kids[n]
        -- return myGroup
    end
end
_G["zSort"] = zSort

-- ****
-- random fix
-- ****

math.randomseed ( os.time ())
-- this is due to OSX/BSD problem with rand implementation
-- http://lua-users.org/lists/lua-l/2007-03/msg00564.html
math.random (); math.random (); math.random (); 

-- ****
-- rect methods
-- ****
function isPointInRect ( point, rect, optionalArgThatIsARect )
    if (optionalArgThatIsARect  ~= nil) then
        -- 3-arguments call. 
        -- so first 2 arguments are point coordinates and last one is a rect
        local x = point
        local y = rect
        rect = optionalArgThatIsARect 
        point = {x = x, y = y}
    end
    if ( point.x > rect.xMin and point.x < rect.xMax and point.y > rect.yMin and point.y < rect.yMax ) then
        return true
    else
        return false
    end
end

function rectsOverlap ( rect1, rect2 )
    if (rect1.xMax < rect2.xMin or rect1.xMin > rect2.xMax or rect1.yMax < rect2.yMin or rect1.yMin > rect2.yMax) then
        return false
    end
    if (rect2.xMax < rect1.xMin or rect2.xMin > rect1.xMax or rect2.yMax < rect1.yMin or rect2.yMin > rect1.yMax) then
        return false
    end
    return true
end
_G.isPointInRect = isPointInRect
_G.rectsOverlap = rectsOverlap

-- **** 
-- debugging label
-- ****
local debugText = ""
local DEBUG_LINES = 5
local dbgLabel = display.newEmbossedText ( "", 10, 10, 470 , 300, native.systemFont, 12 )
local DISABLE_DEBUG = true
function KLDebug ( ... )
    if DISABLE_DEBUG == true then
        return
    end
    str = ""
    local arr = split(debugText, "\n")
    if arr then
        for i=#arr-(DEBUG_LINES - arg.n - 1), #arr do
            -- print (i, arg.n)
            if arr[i] then
                str = str .. "\n" .. arr[i]
            end
        end
    end
    
    for i=1,arg.n do
        str = str .. "\n" .. arg[i]
    end
    debugText = str
    dbgLabel:setText ( str )
    dbgLabel:setReferencePoint ( display.TopLeftReferencePoint )
    dbgLabel.x, dbgLabel.y = 10, 10
end
_G["KLDebug"] = KLDebug    
    

-- ****
-- dragable display objects
-- ****

local setDrag = function ( obj, params )
    local xref, yref
    local touchId 
    if obj.__drag_added == nil then
        obj.__drag_added = false
    end
    if obj.__drag == nil then
        obj.__drag = function ( event )
            local ph = event.phase
            local s = event.target
            local x, y = event.x, event.y
            
            if "began" == ph and s.touchId == nil then
                xref, yref = x - s.x, y - s.y
                display.getCurrentStage ():setFocus ( s )
                s.touchId = event.id
                if params.onTouch then
                    params.onTouch ( event )
                end
            end
            if "moved" == ph and s.touchId == event.id then
                s.x, s.y = x - xref, y - yref
                if params.onMove then
                    params.onMove ( event )
                end
            end
            if "ended" == ph and s.touchId == event.id then
                display.getCurrentStage ():setFocus ( nil )
                s.touchId = nil
                if params.onRelease then
                    params.onRelease ( event )
                end
            end         
        end
    end
    
    if params == nil then
        print ("Removing touch")
        obj:removeEventListener ( "touch", obj.__drag )
        obj.__drag = nil
        obj.__drag_added = false
    else
        if obj.__drag_added == true then
            print ("WARNING: Can't add second drag handler to the same object!")
        else
            print ("Adding touch")
            obj:addEventListener ( "touch", obj.__drag )
            obj.__drag_added = true
        end
    end
end

-- set it for most display objects
KLCache.newGroup = display.newGroup
KLCache.newImage = display.newImage
KLCache.newImageRect = display.newImageRect

display.newGroup = function () 
    local g = KLCache.newGroup()
    g.setDrag = setDrag
    return g
end

_G.setDrag = setDrag


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
M.is_iPad = false
M.isTall = false
M.isSimulator = false

local model = system.getInfo("model")
M.model = model
print (">>> MODEL: >>> ", model)
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
    print ("Not Apple")
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
 
end

_G["_MODEL"] = M