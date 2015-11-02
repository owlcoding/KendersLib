local pathOfThisFile = ...
local folderOfThisFile = (...):match("(.-)[^%.]+$")
local Log

module( pathOfThisFile, package.seeall )

local KLCache = {}
local Toast = {}
local KL = {}

local sb = require ("composer")
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

 trcToCache = transition.cancel
 transition.cancel = function ( tid )
     if tid then
         trcToCache ( tid )
     end
 end
         
 
function cancelAllTimers ()
    local c = 0
    for i, t in pairs ( timersStash ) do
        timer.cancel ( i )
        c = c + 1
    end
    timersStash = {}
    if c > 0 then
        Log (">>> Cancelled " .. c .. " timers <<<")
    end
end
function cancelAllTransitions ()
    local c = 0
    for i, t in pairs ( transitionStash ) do
        transition.cancel ( i )
        c = c + 1
    end
    transitionStash = {}
    if c > 0 then
        Log (">>> Cancelled " .. c .. " transitions <<<")
    end
end
_G['cancelAllTransitions'] = cancelAllTransitions
_G['cancelAllTimers'] = cancelAllTimers

KLCache [ 'gotoScene' ] = sb.gotoScene
sb.gotoScene = function ( s, t, tm )
    cancelAllTimers ()
    cancelAllTransitions ()
    Toast.destroyAllToasts ()
    KLCache [ 'gotoScene' ] ( s, t, tm )
end

              centerX = display.contentCenterX
              centerY = display.contentCenterY
              screenX = display.screenOriginX
              screenY = display.screenOriginY
          screenWidth = display.contentWidth - screenX * 2
         screenHeight = display.contentHeight - screenY * 2
           display.screenLeft = screenX
          display.screenRight = screenX + screenWidth
            display.screenTop = screenY
         display.screenBottom = screenY + screenHeight
         display.centerX = centerX
         display.centerY = centerY
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

function table.contains(t, element)
  for _, value in pairs(t) do
    if value == element then
      return true
    end
  end
  return false
end 

function table.removeObject ( t, element )
    if t == nil then return end
    for _, value in pairs ( t ) do 
        if value == element then
            table.remove ( t, _ )
            return
        end
    end
end
function table.joinTables ( t, otherT )
    for _, value in pairs ( otherT ) do
        if table.contains ( t, value ) then
        else
            t [ #t + 1 ] = value
        end
    end
end

function table.slice ( values, i1, i2 )
    local res = {}
    local n = #values
    -- default values for range
    i1 = i1 or 1
    i2 = i2 or n
    if i2 < 0 then
        i2 = n + i2 + 1
    elseif i2 > n then
        i2 = n
    end
    if i1 < 1 or i1 > n then
        return {}
    end
    local k = 1
    for i = i1,i2 do
        res[k] = values[i]
        k = k + 1
    end
    return res
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
                    if ( a.z == nil and a.layer == nil ) then
                        KLLog ( a.kind, "has z and layer property nil" )
                    end
                                return (a.z or a.layer or 1) < (b.z or b.layer or 1) -- "layer" is your custom z-index field
                end
        )
        for i = 1,n do
                myGroup:insert(kids[i])
        end
        return kids[n]
        -- return myGroup
    else
        KLLog ( "Group is nil" )
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
function isPointInRect ( point, rect )
    if point == nil or rect == nil or point.x == nil or point.y == nil then
        return false
    end
    if ( point.x > rect.xMin and point.x < rect.xMax and point.y > rect.yMin and point.y < rect.yMax ) then
        return true
    else
        return false
    end
end

function rectsOverlap ( rect1, rect2 )
    if rect1 == nil or rect2 == nil then 
        return false
    end
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
            -- Log (i, arg.n)
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
    -- dbgLabel:setReferencePoint ( display.TopLeftReferencePoint )
    dbgLabel.anchorY, dbgLabel.anchorX = 0, 0
    dbgLabel.x, dbgLabel.y = 10, 10
end
_G["KLDebug"] = KLDebug    
    

-- ****
-- dragable display objects
-- ****

local setDrag
setDrag = function ( obj, params )
    local xref, yref
    local touchId 
    if obj == nil then
        return 
    end
    if obj.__drag_added == nil then
        obj.__drag_added = false
    end
    if obj.__drag == nil then
        obj.__drag = function ( event )
            local ph = event.phase
            local s = event.target
            local x, y = event.x, event.y
            local __params = params
            if "began" == ph and s.touchId == nil then
                xref, yref = x - s.x, y - s.y
                display.getCurrentStage ():setFocus ( s )
                s.touchId = event.id
                if params and params.onTouch then
                    params.onTouch ( event )
                end
            end
            if "moved" == ph and s.touchId == event.id then
                s.x, s.y = x - xref, y - yref
                if params and params.onMove then
                    params.onMove ( event )
                end
            end
            if "ended" == ph and s.touchId == event.id then
                display.getCurrentStage ():setFocus ( nil )
                s.touchId = nil
                -- print ( "p, params.onRelease", params, params.onRelease )
                if params and params.onRelease then
                    params.onRelease ( event )
                end
            end         
        end
    end
    
    if params == nil then
        print ("Set Drag with nil parameter" )
        if obj ~= nil and obj.__drag ~= nil then
            print ("Removing touch")
            -- display.getCurrentStage ():setFocus ( nil )
            obj.__drag ( { phase = "ended", id = obj.touchId, target = obj })


            obj:removeEventListener ( "touch", obj.__drag )
            obj.__drag = nil
            obj.__drag_added = false
        end
    else
        if obj.__drag_added == true then
            print ("WARNING: Can't add second drag handler to the same object!")
        else
            print ("Adding touch")
            obj:addEventListener ( "touch", obj.__drag )
            obj.__drag_added = true
        end
    end
    function obj:cancelDrag ( )
        setDrag ( self, nil )
    end
end

-- set it for most display objects
KLCache.newGroup = display.newGroup
KLCache.newImage = display.newImage
KLCache.newImageRect = display.newImageRect
KLCache.newRect = display.newRect
KLCache.newText = display.newText

display.newRect = function ( ... )
    local g = KLCache.newRect ( unpack ( arg ))
    g.kind = "Rect"
    return g
end
display.newGroup = function () 
    local g = KLCache.newGroup()
    g.kind = "Group"
    g.setDrag = setDrag

    g.cachedInsert = g.insert
    
    function g:insert ( ... )
        if arg == nil then return end
        -- print ("ARGS", #arg)
        for i=1, #arg do
            -- print ( arg[i])
            if type(arg[i]) == type ( 1 ) then
            else
                -- print ( g, type ( arg [ i ]) )
                g.cachedInsert ( g, arg [ i ])
            end
        end
    end
    
    return g
end

display.newImageRect = function ( ... )
    local g = KLCache.newImageRect ( unpack ( arg ) )
    local n = ""
    if type ( arg [ 1 ] ) == type ( "string" ) then
        n = arg [ 1 ]
    elseif type ( arg [ 2 ] ) == type ("string") then
        n = arg [ 2 ] 
    end
    -- print ( n )
    g.kind = "ImageRect [" .. n .. "]"
    return g
end

display.newText = function ( ... )
    local g = KLCache.newText ( unpack ( arg ))
    local n = ""
    if ( #arg == 1 ) then
        n = arg [ 1 ] [ "text" ]
    elseif type ( arg [ 1 ] ) == type ( "string" ) then
        n = arg [ 1 ]
    else 
        n = arg [ 2 ] 
    end
    g.kind = "Text [" .. n .. "]"

    local stt = g.setFillColor
    g.setFillColor = function ( g, params )
        if type ( params ) == 'table' then
            stt (g, params [ 1 ], params [ 2 ], params [ 3 ] )
        else
            stt (g, params )
        end
    end

    return g
end
_G.setDrag = setDrag


-- persistent data storage, using GGData module ( https://github.com/GlitchGames/GGData.git )
local GGData = require ( folderOfThisFile .. "GG.GGData.corona.GGData" )
local savedState = GGData:new( "savedState" )
savedState:save()

_G["savedState"] = savedState


-- toast
Toast.allToasts = {}

local trueDestroy;
local newToast
local destroyToast
local destroyAllToasts

-------------------------------
-- private functions
-------------------------------
function trueDestroyToast(toast)
    if toast.destroyTimer then
        timer.cancel ( toast.destroyTimer )
    end
    toast.destroyTimer = nil
    
    toast:removeSelf();
    table.removeObject ( Toast.allToasts, toast )
    toast = nil;
end

-------------------------------
-- public functions
-------------------------------
function newToast(pText, pTime)
    local text = pText or "nil";
    local pTime = pTime;
    local toast = display.newGroup();

    toast.text                      = display.newText(toast, pText, 14, 12, native.systemFont, 20);
    toast.text.x                    = 0
    toast.text.y                    = 0
    toast.background                = display.newRoundedRect( toast, 0, 0, toast.text.width + 24, toast.text.height + 24, 16 );
    toast.background.strokeWidth    = 2
    toast.background:setFillColor(72/255, 64/255, 72/255)
    toast.background:setStrokeColor(96/255, 88/255, 96/255)
    toast.background.alpha = 0.8
    toast.text:toFront();

    -- toast:setReferencePoint(toast.width*.5, toast.height*.5)
    --utils.maintainRatio(toast);
    -- toast:setReferencePoint ( display.CenterReferencePoint )
    toast.anchorY, toast.anchorX = 0.5, 0.5
    toast.x, toast.y = display.contentWidth / 2, display.screenBottom - toast.contentHeight

    toast.alpha = 0;
    toast.transition = transition.to(toast, {time=250, alpha = 1});

    if pTime ~= nil then
        toast.destroyTimer = timer.performWithDelay(pTime, function() destroyToast(toast) end);
    end

    toast.x = display.contentWidth * .5 -- toast.contentWidth / 4
    toast.y = display.contentHeight * .9
    Toast.allToasts [ #Toast.allToasts + 1 ] = toast
    return toast;
end

function destroyToast(toast)
    toast.destroyTimer = nil
    toast.transition = transition.to(toast, {time=250, alpha = 0, onComplete = function() trueDestroyToast(toast) end});
end
function destroyAllToasts ()
    if ( #Toast.allToasts > 0 ) then
        Log ( ">>> Destroying " .. #Toast.allToasts .. " toasts <<<")
        while ( #Toast.allToasts > 0 ) do
            trueDestroyToast ( Toast.allToasts [ 1 ] )
        end
        Toast.allToasts = {}
    end
end

Toast.new = newToast
Toast.destroy = destroyToast
Toast.destroyAllToasts = destroyAllToasts
_G["Toast"] = Toast

local printTable 

local table2str

table2str = function ( t, indent )
    if t == nil then
        return
    end
    if indent == nil then indent = 1 end
    local s = ""
    local ind = ""
    for i = 1,indent do
       ind = ind .. " "
   end 
    for k, v in pairs ( t ) do
        if type ( v ) == "table" then
            s = s .. ind .. k .. " => { " .. table2str ( v, indent + 1 ) .. " }, " 
        else
            if type ( v ) == "boolean" then
                if v then
                    v = "true"
                else
                    v = "false"
                end
            end
            if type ( v ) == "function" then
                v = "function" 
            end
            if type ( v ) == "userdata" then
                v = "userdata"
            end
            s = s .. ind .. k .. " => " .. v .. ", "
        end
        -- s = "\n" .. s .. "\n"
    end
    return s
end

printTable = function ( t )
    print ( table2str ( t ))
end
_G [ "printTable" ] = printTable

KLCache.displayremove = display.remove

display.remove = function ( obj )
    if obj == nil then
        return
    end
    KLCache.displayremove ( obj )
    if obj and obj.dispatchEvent then
        obj:dispatchEvent ({ name = "objectRemoved" })
    end
end
function unrequire(m)
    package.loaded[m] = nil
    _G[m] = nil
end

_G [ "unrequire" ] = unrequire

local logs = {}
local str = function ( o )
    if o == nil then return "nil" end
    if type ( o ) == "boolean" then
        if o == true then
            return "true"
        else
            return "false"
        end
    elseif type ( o ) == "table" then
        return "table"
    elseif type ( o ) == "function" then
        for k, v in pairs ( debug.getinfo ( o )) do
            -- print ("F", k, v )
        end
        return "" .. "function"
    elseif type ( o ) == "userdata" then
        return "" .. "userdata"
    else
        return "" .. o
    end
end
Log = function ( ... )
    local dbg = debug.getinfo ( 2 )
    local line = dbg.currentline
    local file = split ( dbg.source, "/")
    file = file [ #file ]
    for _, v in pairs ( dbg ) do
        -- print  ("!!!", _, v )
    end
    
    local args = ""
    for i = 1, arg.n do
        args = args .. "\t" .. str ( arg [ i ] )
    end
    
    local logline = file .. ":" .. line .. args
    logs [ #logs + 1 ] = logline
    print ( logline )
end
local GetLogs = function ( ) 
    local l = ""
    for i=1, #logs do
        l = l .. logs [ i ] .. "\n"
    end
    return l
end

_G [ "KLLog" ] = Log
_G [ "KLGetLogs" ] = GetLogs

KL.interactionsAllowed = true

local function newImageRect (group, path, width, height)
    if height == nil then
        height = width
        width = path
        path = group
        group = nil
    end
    local ir = display.newImageRect ( group, path, width, height )
    ir.isActive = true
    ir:addEventListener("touch", function ( event )
        -- KLLog ("In tap listener, (x, y) = ", "(" .. event.x .. ", " .. event.y .. ")" )
        if event.phase == "began" and ir.isActive and ir.action and ir.isVisible and ir.alpha == 1 and KL.interactionsAllowed then
            return ir.action ( event )
        end
        return false
    end)
    return ir
end

KL.newImageRect = newImageRect
_G ["KL"] = KL

local function showTextByChar ( txtLabel )
    local x, y, w, h = txtLabel.x, txtLabel.y, txtLabel.contentWidth, txtLabel.contentHeight
    local text = txtLabel.text
    txtLabel.text = ""
    txtLabel.isVisible = true
    for i=1, string.len( text ) do
        timer.performWithDelay( 10 * i , function ( )
            local l = string.sub( text, i , i )
            -- print ( l )
            if txtLabel and txtLabel.text then 
                txtLabel.text = txtLabel.text .. l
            end
        end )
    end
end

_G [ "showTextByChar" ] = showTextByChar

local resourceLoader = {}

function resourceLoader:new ( resourceFileName )
    local r = json ( resourceFileName )
    self.resources = r
end

function resourceLoader:resource ( key )
    return self.resources [ key ]
end

_G [ "resourceLoader" ] = resourceLoader

local function anchor00 ( displayObject )
    displayObject.anchorX = 0
    displayObject.anchorY = 0
end

display.anchor00 = anchor00

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

table.copy = shallowcopy

local widget = require ( "widget" )
local origNewButton = widget.newButton

widget.newButton = function ( params )
    local w = origNewButton ( params )
    w.origSetEnabled = w.setEnabled
    w.setEnabled = function ( button, enabled )
        print ("Inside setEnabled for button" )
        button.origSetEnabled ( button, enabled )
        if enabled then
            button.alpha = 1
        else
            button.alpha = 0.5
        end
    end
    return w
end

local function cleanHtml ( t ) -- from https://gist.github.com/HoraceBury/9001099
    local cleaner = {
        { "&amp;", "&" }, -- decode ampersands
        { "&#151;", "-" }, -- em dash
        { "&#146;", "'" }, -- right single quote
        { "&#147;", "\"" }, -- left double quote
        { "&#148;", "\"" }, -- right double quote
        { "&#150;", "-" }, -- en dash
        { "&#160;", " " }, -- non-breaking space
        { "<br ?/?>", "\n" }, -- all <br> tags whether terminated or not (<br> <br/> <br />) become new lines
        { "</p>", "\n" }, -- ends of paragraphs become new lines
        { "(%b<>)", "" }, -- all other html elements are completely removed (must be done last)
        { "\r", "\n" }, -- return carriage become new lines
        { "[\n\n]+", "\n" }, -- reduce all multiple new lines with a single new line
        { "^\n*", "" }, -- trim new lines from the start...
        { "\n*$", "" }, -- ... and end
    }
 
    -- clean html from the string
    for i=1, #cleaner do
        local cleans = cleaner[i]
        t = string.gsub( t, cleans[1], cleans[2] )
    end
     
    -- print("["..t.."]") -- print the string with end indicators
    return t
end
_G ["cleanHtml"] = cleanHtml

local function fileExists(fileName, base)
  assert(fileName, "fileName does not exist")
  local base = base or system.ResourceDirectory
  local filePath = system.pathForFile( fileName, base )
  local exists = false
 
  if (filePath) then
    local fileHandle = io.open( filePath, "r" )
    if (fileHandle) then
      exists = true
      io.close(fileHandle)
    end
  end
 
  return(exists)
end

local InMemoryCache = {}

local function remoteImage ( url, filename, width, height )
    local p = system.pathForFile ( filename, system.CachesDirectory )
    local g = display.newGroup ()
    local ri 

    local remSelf = g.removeSelf
    function g:removeSelf ( )
        print ( "Removing remote Image" )
        if ri and ri.parent then
            ri:removeSelf ()
        end
        remSelf ( g )
    end

    -- print ( "path", p, InMemoryCache [ p ] )
    local exists = fileExists ( filename, system.CachesDirectory )
    if not exists then
        ri = display.newImageRect ( "assets/graphics/dummy.png", width, height )
    else
        -- displaying image from cache
        -- print ( "displaying image from cache (" .. filename .. ")" )
        ri = display.newImageRect ( filename, system.CachesDirectory, width, height )
    end
    g:insert ( ri )


    if url and not exists then
        network.download ( url, "GET", function ( ev )
            if ev.phase == "ended" then
                if g and g.parent then
                    local ri2 = display.newImageRect ( filename, system.CachesDirectory, width, height )

                    if g and g.parent then
                        g:insert ( ri2 )
                    end
                    if ri and ri.parent then
                        ri:removeSelf ()
                    end
                    ri = ri2
                end
            end
        end, filename, system.CachesDirectory )
    end
    return g
end
display.remoteImage = remoteImage

