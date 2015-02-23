-- A lightweight unix style framework of Cocos2d-lua.
-- https://github.com/zii/cox
-- v0.2, support cocos2d-x 3.4.

require "cocos.cocos2d.Cocos2d"
require "cocos.cocos2d.Cocos2dConstants"
require "cocos.cocos2d.functions"
require "cocos.ui.GuiConstants"

local cox = {}

local D = cc.Director:getInstance()
local TC = D:getTextureCache()
local FC = cc.SpriteFrameCache:getInstance()
local SIZE = D:getWinSize()
local UD = cc.UserDefault:getInstance()
local SA = cc.SimpleAudioEngine:getInstance()
local FU = cc.FileUtils:getInstance()
local GR = ccs.GUIReader:getInstance()
local GV = D:getOpenGLView()
local FSIZE = GV:getFrameSize()

cox.d = D
cox.tc = TC
cox.fc = FC
-- design resolution
cox.w = SIZE.width
cox.h = SIZE.height
cox.ud = UD
cox.sa = SA
cox.fu = FU
cox.gr = GR
cox.gv = GV
-- real resolution
cox.fw = FSIZE.width
cox.fh = FSIZE.height

function cox.traceback(msg)
    print(debug.traceback())
    print("LUA ERROR: " .. tostring(msg))
    return msg
end

-- print error when the function panic
function cox.xpcall(main)
    local status, msg = xpcall(main, cox.traceback)
    if not status then
        error(msg)
    end
end

function table.append(t, elem)
    table.insert(t, #t+1, elem)
end

-- remove by element
function table.del(t, elem)
    for i, v in ipairs(t) do
        if v == elem then
            table.remove(t, i)
            break
        end
    end
end

-- merge attributes to another table
function table.update(dst, src)
    for k, v in pairs(src) do
        if type(k) ~= "number" then
            dst[k] = v
        end
    end
end

-- set resolution
function cox.setrso(w, h, type)
    D:getOpenGLView():setDesignResolutionSize(w, h, type)
    SIZE = D:getWinSize()
    cox.w = SIZE.width
    cox.h = SIZE.height
end

-- load sprite frames to texture cache
function cox.addsf(format, ...)
    cox.fc:addSpriteFrames(string.format(format, ...))
end

-- run or replace scene
function cox.switch(nextscene)
    if D:getRunningScene() then
        D:replaceScene(nextscene)
    else
        D:runWithScene(nextscene)
    end
end

function cox.setud(name, v)
    local t = type(v)
    if t == "boolean" then
        UD:setBoolForKey(name, v)
    elseif t == "number" then
        UD:setDoubleForKey(name, v)
    elseif t == "string" then
        UD:setStringForKey(name, v)
    end
end

function cox.getud(name, defv)
    local v
    local t = type(defv)
    if t == "boolean" then
        v = UD:getBoolForKey(name, defv)
    elseif t == "number" then
        v = UD:getDoubleForKey(name, defv)
    elseif t == "string" then
        v = UD:getStringForKey(name, defv)
    end
    if v == nil then
        v = defv
    end
    return v
end

--[[ bind key event
eg.
local function onrelease(code, event)
    if code == cc.KeyCode.KEY_BACK then
        cox.d:endToLua()
    end
end
cox.bindk(layer, onrelease)
]]
function cox.bindk(node, cb)
    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(cb, cc.Handler.EVENT_KEYBOARD_RELEASED)

    local eventDispatcher = node:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
end

--[[ bind KEY_BACK event
eg.
cox.bindkb(layer, function() cox.d:endToLua() end)
]]
function cox.bindkb(node, cb, ...)
    local arg = ...
    local function onpress(code, event)
        if code == cc.KeyCode.KEY_BACK then
            cb(arg)
        end
    end
    cox.bindk(node, onpress)
end

function cox.loadef(filename)
    SA:preloadEffect(filename)
end

function cox.playef(filename)
    SA:playEffect(filename)
end

function cox.playms(filename, loop)
    SA:playMusic(filename, loop)
end

function cox.stopms()
    SA:stopMusic()
end

--[[ create a cc.Sprite init with attributes.
@texf load texture with frame name
@tex  load texture with file name
@animf load texture with animation
eg.
local spr = cox.newspr{on=layer, texf="carrot.png", x=cox.w/2, y=276}
spr:set{scale=2, rot=90, name="carrot"}
spr:runact{"move", 1, 100, 100}
eg.
local spr = cox.newspr{on=layer, animf={"select_%02d.png", {1,2}, 0.2}}
spr.play()
]]
function cox.newspr(arg)
    local spr = nil
    local cls = cc.Sprite
    if arg.texf then
        spr = cls:createWithSpriteFrameName(arg.texf)
    elseif arg.tex then
        spr = cls:create(arg.tex)
    elseif arg.animf then
        spr = cox._animspr(arg.animf[1], arg.animf[2], arg.animf[3])
    else
        spr = cls:create()
    end
    cox.setspr(spr, arg)
    -- add some methods
    spr.set = cox.setspr
    spr.runact = cox.runact
    return spr
end

--[[ set sprite's attributes
eg.
tip:set{on=self, name="uptip", x=0, y=60, ac={0.5, 0.5}}
]]
function cox.setspr(spr, arg)
    if arg.x then
        spr:setPositionX(arg.x)
    end
    if arg.y then
        spr:setPositionY(arg.y)
    end
    if arg.z then
        spr:setLocalZOrder(arg.z)
    end
    if arg.gz then
        spr:setGlobalZOrder(arg.gz)
    end
    -- normalized position
    if arg.np then
        spr:setNormalizedPosition(cc.p(arg.np[1], arg.np[2]) )
    end
    -- anchor point
    if arg.ac then
        spr:setAnchorPoint(arg.ac[1], arg.ac[2])
    end
    if arg.name then
        spr:setName(arg.name)
    end
    if arg.rot then
        spr:setRotation(arg.rot)
    end
    if arg.scale then
        spr:setScale(arg.scale)
    end
    if arg.scalex then
        spr:setScaleX(arg.scalex)
    end
    if arg.scaley then
        spr:setScaleY(arg.scaley)
    end
    local parent = arg.parent or arg.on
    if parent then
        parent:addChild(spr)
        -- default in middle
        local size = parent:getContentSize()
        if not arg.x then
            spr:setPositionX(size.width/2)
        end
        if not arg.y then
            spr:setPositionY(size.height/2)
        end
    end
    if arg.frame then
        spr:setSpriteFrame(FC:getSpriteFrame(arg.frame))
    end
    if arg.show ~= nil then
        spr:setVisible(arg.show)
    end
    if arg.alpha then
        spr:setOpacity(arg.alpha)
    end
    if arg.flipx then
        spr:setFlippedX(true)
    end
    if arg.flipy then
        spr:setFlippedY(true)
    end
end


--[[ create a cc.Animate with frame names.
eg.
cox.animf("air%02d.png", {1,2,3,4,5}, 0.06)
]]
function cox.animf(format, numbers, dt)
    local frames = {}
    for i, num in ipairs(numbers) do
        local f = FC:getSpriteFrame(string.format(format, num))
        table.insert(frames, f)
    end
    local animation = cc.Animation:createWithSpriteFrames(frames,dt)
    local animate = cc.Animate:create(animation)
    return animate
end

function cox._animspr(format, numbers, dt)
    local ani = cox.animf(format, numbers, dt)
    local spr = cc.Sprite:createWithSpriteFrameName(string.format(format, numbers[1]))
    spr.play = function(self, times)
        if times == nil or times <= 0 then
            spr:runAction(cc.RepeatForever:create(ani))
        else
            spr:runAction(cc.Sequence:create(
                cc.Repeat:create(ani, times), 
                cc.RemoveSelf:create() 
            ))
        end
    end
    return spr
end

--[[ create a cc.Action with a config table.
eg.
luobo:runAction(cox.act{
{"delay", 3},
{
    {"animf", "hlb%d.png", {21,22,23,10}, 0.05},
    {"repeat", 2}
},
{"delay", 3},
{
    {"rotb", 0.2, 20},
    {"rotb", 0.4, -40},
    {"rotb", 0.2, 20},
    {"repeat", 4}
},
{"delay", 3},
{"repeat", -1}
})
]]
function cox.act(cfg)
    local tok = cfg[1]
    local act = nil
    if type(tok) == "string" then
        local act = nil
        local v = cfg
        if tok == "move" then
            act = cc.MoveTo:create(v[2], cc.p(v[3], v[4]))   
        elseif tok == "moveb" then
            act = cc.MoveBy:create(v[2], cc.p(v[3], v[4]))
        elseif tok == "obj" then
            act = v[2]
        elseif tok == "call" then
            if v[3] == nil then
                act = cc.CallFunc:create(v[2])
            else
                act = cc.CallFunc:create(v[2], v[3])
            end
        elseif tok == "delay" then
            act = cc.DelayTime:create(v[2])
        elseif tok == "rot" then
            act = cc.RotateTo:create(v[2], v[3])
        elseif tok == "rotb" then
            act = cc.RotateBy:create(v[2], v[3])
        elseif tok == "scale" then
            if v[4] then
                act = cc.ScaleTo:create(v[2], v[3], v[4])
            else
                act = cc.ScaleTo:create(v[2], v[3])
            end
        elseif tok == "scaleb" then
            act = cc.ScaleBy:create(v[2], v[3])
        elseif tok == "remove" then
            act = cc.RemoveSelf:create()
        elseif tok == "fadein" then
            act = cc.FadeIn:create(v[2])
        elseif tok == "fadeout" then
            act = cc.FadeOut:create(v[2])
        elseif tok == "animf" then
            act = cox.animf(v[2], v[3], v[4])
        elseif tok == "flipx" then
            act = cc.FlipX:create(v[2])
        elseif tok == "flipy" then
            act = cc.FlipY:create(v[2])
        elseif tok == "show" then
            act = cc.Show:create()
        elseif tok == "hide" then
            act = cc.Hide:create()
        elseif tok == "setframe" then
            local f = function(sender, arg)
                arg.spr:setSpriteFrame(FC:getSpriteFrame(arg.name))
            end
            act = cc.CallFunc:create(f, {spr=v[2], name=v[3]})
        elseif tok == "jumpb" then
            act = cc.JumpBy:create(v[2], v[3], v[4], v[5])
        end
        return act
    elseif type(tok) == "table" then
        local n = 1
        local speed = nil
        local seq = {}
        local spawn = false
        for _, v in ipairs(cfg) do
            local op = v[1]
            if op == "repeat" then
                n = v[2]
            elseif op == "speed" then
                speed = v[2]
            elseif op == "spawn" then
                spawn = true
            else
                local a = cox.act(v)
                if a then table.insert(seq, a) end
            end
        end
        local act = nil
        if #seq > 1 then
            act = spawn and cc.Spawn:create(seq) or cc.Sequence:create(seq)
        elseif #seq == 1 then
            act = seq[1]
        else
            return
        end
        if n < 0 then
            act = cc.RepeatForever:create(act)
        elseif n ~= 1 then
            act = cc.Repeat:create(act, n)
        end
        if speed ~= nil then
            act = cc.Speed:create(act, speed) 
        end

        return act
    end
end

function cox.runact(node, cfg)
    local act = cox.act(cfg)
    node:runAction(act)
    return act
end

-- load Cocos Studio ui config, return a GUI cc.Layer
function cox.loadui(path)
    local panel
    if string.sub(path, -4, -1) == ".csb" then
        panel = GR:widgetFromBinaryFile(path)
    else
        panel = GR:widgetFromJsonFile(path)
    end
    if panel then
        panel.seek = cox.seekui
    end
    return panel
end

function cox.seekui(node, name)
    local widget = ccui.Helper:seekWidgetByName(node, name)
    widget.seek = cox.seekui
    widget.ontouch = cox.ontouch
    widget.runact = cox.runact
    return widget
end

-- add ui touch event
function cox.ontouch(widget, cb, et)
    et = et or ccui.TouchEventType.ended
    widget:addTouchEventListener(function(sender, e)
        if e ~= et then return true end
        cb()
        return true
    end)
end

-- add event listener on node
function cox.listen(node, cb, et, swallow)
    local listener = cc.EventListenerTouchOneByOne:create()
    if swallow ~= false then
        listener:setSwallowTouches(true)
    end
    -- it must have EVENT_TOUCH_BEGAN
    if et ~= nil and et ~= cc.Handler.EVENT_TOUCH_BEGAN then
        listener:registerScriptHandler(function() 
            return true
        end, cc.Handler.EVENT_TOUCH_BEGAN)
    end
    listener:registerScriptHandler(cb, et or cc.Handler.EVENT_TOUCH_BEGAN)
    local dispatcher = node:getEventDispatcher()
    dispatcher:addEventListenerWithSceneGraphPriority(listener, node)
end

function cox.swallow(node)
    local listener1 = cc.EventListenerTouchOneByOne:create()
    listener1:setSwallowTouches(true)
    listener1:registerScriptHandler(function() return true end,cc.Handler.EVENT_TOUCH_BEGAN )
    local eventDispatcher = node:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener1, node)
end

-- removeFromParent has some bugs, use this instead
function cox.safedel(node)
    node:runAction(cc.RemoveSelf:create())
end

--- ui ---

function cox.button(arg)
    local spr = ccui.Button:create()
    if arg.normal then
        spr:loadTextureNormal(arg.normal, ccui.TextureResType.plistType)
    end
    if arg.pressed then
        spr:loadTexturePressed(arg.pressed, ccui.TextureResType.plistType)
    end
    cox.setspr(spr, arg)
    -- add some methods
    spr.set = cox.setspr
    spr.runact = cox.runact
    spr.ontouch = cox.ontouch
    return spr
end

--[[ create charmap label
eg.
local num = cox.charlabel("num-1.png", 52, 67, 48, {
on=layer, 
x=100, 
y=100
})
]]
function cox.charlabel(file, width, height, init_code, arg)
    local spr = cc.Label:createWithCharMap(file, width, height, init_code)
    cox.setspr(spr, arg)
    -- add meta methods
    spr.setstr = function(this, format, ...)
        this:setString(string.format(tostring(format), ...))
    end
    spr.set = cox.setspr
    spr.runact = cox.runact
    spr.ontouch = cox.ontouch
    return spr
end

-- add dragging sensitive to ccui.PageView
function cox.setpv(pageview, arg)
    local smooth = arg.smooth or 8
    local onpress = arg.onpress
    local pagen = #pageview:getPages()
    for i = 0, pagen-1 do
        local page = pageview:getPage(i)
        page:addTouchEventListener(function(sender, e)
            if e == ccui.TouchEventType.ended and onpress then
                onpress(i)
            elseif e == ccui.TouchEventType.canceled then 
                local s = page:getContentSize()
                local x, y = page:getPosition()
                if s.width/2 > x and x > s.width/smooth and i > 0 then
                    pageview:scrollToPage(i-1)
                elseif -s.width/2 < x and x < -s.width/smooth and i < pagen-1 then
                    pageview:scrollToPage(i+1)
                end
            end
        end)
    end
end

--- utils ---

-- transform angle < 180
local function normala(a)
    if a > 180 then a = -(360 - a)
    elseif a < -180 then a = 360 + a
    end
    return a
end

-- get angle difference in 180
function cox.diffa(a, b)
    local na = normala(a)
    local nb = normala(b)
    local dif = math.abs(na - nb)
    return dif <= 180 and dif or 360 - dif
end

-- get distance of p to line, p0-p1 is the segment end points 
function cox.p2l(p, p0, p1, dir)
    -- exchange x and y
    if math.abs(p1.x-p0.x) < math.abs(p1.y-p0.y) then
        p = cc.p(p.y, p.x)
        p0 = cc.p(p0.y, p0.x)
        p1 = cc.p(p1.y, p1.x)
    end
    -- exclude backward
    if dir == true then
        if (p.x-p0.x)*(p1.x-p0.x) < 0 then
            return 1/0
        end
    end
    local k = (p1.y-p0.y)/(p1.x-p0.x)
    local a = k
    local b = -1
    local c = p0.y - p0.x * k
    local d = (a*p.x+b*p.y+c) / (a*a+b*b)^0.5
    return math.abs(d)
end

function cox.schedule(callback, dt)
    return D:getScheduler():scheduleScriptFunc(callback, dt, false)
end

function cox.unschedule(entry)
    D:getScheduler():unscheduleScriptEntry(entry)
end

return cox
