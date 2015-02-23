local CURRENT_ACTION = 1001

local S = class("GameScene", function() 
    return cc.Scene:create()
end)

function S.create(reload)
    local s = S.new()

    s.current = nil -- the flying cake
    s.basey = 152
    s.basew = 360
    s.baseh = 93  -- the cake's height
    s.precision = 15 -- min width of block
    s.floors = {} -- the stack
    s.speed = 180
    s.edge = {left=52, right=584}
    s.floor_num = nil
    s.paused = false
    
    if reload then
        s.loadres()
    end
    s.bg_layer = s:new_bg_layer()
    s:addChild(s.bg_layer)
    s.layer = s:alayer()
    s:addChild(s.layer)
    s.ui_layer = s:new_ui_layer()
    s:addChild(s.ui_layer, 10)
    s:newblock()
    
    return s
end

function S.loadres()
    cox.addsf("scene1/scene1.plist")
    cox.addsf("ui.plist")
end

function S:new_bg_layer()
    local layer = cc.Layer:create()

    local bg = cox.newspr{on=layer, tex="scene1/bg.jpg", y=0, ac={0.5, 0}}
    local bgsize = bg:getContentSize()
    local bg1 = cox.newspr{on=layer, tex="scene1/bg1.jpg", y=bgsize.height, ac={0.5,0}}
    local hill = cox.newspr{on=layer, texf="hill.png", y=400}
    local ground = cox.newspr{on=layer, texf="ground.png", y=0, ac={0.5,0}}

    function movcloud(x, y)
        local cloud = cox.newspr{
            on=layer, 
            texf=string.format("cloud-%d.png", math.random(1,3)), 
            x=x, 
            y=y
        }
        local x, y = cloud:getPosition()
        local size = cloud:getContentSize()
        local speed = math.random(5,10)
        cloud:runact{
            {"move", (x+size.width/2)/speed, -size.width/2, y},
            {"move", 0, G.W+size.width/2, y},
            {"move", (G.W+size.width/2-x)/speed, x, y},
            {"repeat", -1}
        }
    end
    movcloud(500, 600)
    movcloud(200, 700)
    movcloud(0,   900)
    movcloud(600, 1100)
    movcloud(200, 1200)
    
    return layer
end

function S:alayer()
    local layer = cc.Layer:create()
    
    local desk = cox.newspr{on=layer, texf="desk.png", y=0, ac={0.5,0}}
    
    -- on keyback pressed
    cox.bindkb(layer, function()
        G.switch("hello")
    end)
    
    -- on touch event
    cox.listen(layer, function(touch, e) 
        self:ontouch(touch)
        return true
    end, cc.Handler.EVENT_TOUCH_BEGAN, true) 
    
    return layer
end

function S:new_ui_layer()
    local layer = cc.Layer:create()

    -- UI
    local soundopen_b = cox.button{
        on=layer,
        normal="sound-11.png", 
        pressed="sound-12.png",
        x=G.W-70, y=G.H-70
    }
    local soundclose_b = cox.button{
        on=layer,
        normal="sound-21.png", 
        pressed="sound-22.png",
        x=G.W-70, y=G.H-70,
        show=false
    }
    soundopen_b:ontouch(function()
        soundopen_b:setVisible(false)
        soundclose_b:setVisible(true)
    end)
    soundclose_b:ontouch(function()
        soundclose_b:setVisible(false)
        soundopen_b:setVisible(true)
    end)

    local pause_b = cox.button{
        on=layer,
        normal="pause-1.png", 
        pressed="pause-2.png",
        x=70, y=G.H-70
    }
    pause_b:ontouch(function()
        if self.paused then
            self:resume()
        else
            self:pause()
        end
    end)
    
    local num = cox.charlabel("num-1.png", 52, 67, 48, {
        on=layer,
        x=G.W/2, 
        y=G.H-70,
        scale=0.8,
    })
    num:setstr(#self.floors)
    self.floor_num = num
    
    return layer
end

function S:pause()
    if self.current then
        local action = self.current:getActionByTag(CURRENT_ACTION)
        action:setSpeed(0)
    end
    self:open_menu()
    self.paused = true
end

function S:resume()
    if self.current then
        local action = self.current:getActionByTag(CURRENT_ACTION)
        action:setSpeed(1)
    end
    self:close_menu()
    self.paused = false
end

function S:gettopy()
    return self.basey + #self.floors * self.baseh
end

-- create a flying cake
function S:newblock()
    local block = cox.newspr{
                        on=self.layer, 
                        tex="scene1/dg-1-1.png", 
                        y=self:gettopy(),
                        ac={0,0.5},
                        }
    block:getTexture():setTexParameters(gl.LINEAR, gl.LINEAR, gl.REPEAT, gl.REPEAT)
    block:setTextureRect(cc.rect(0,0,self.basew,self.baseh))
    self.current = block
    local size = block:getContentSize()
    local x = 0
    if math.random() < 0.5 then
        x = 0
    else
        x = G.W - size.width
    end
    block:set{x=x}
    local x, y = block:getPosition()
    local speed = self.speed
    local action = nil
    if x <= 0 then
        action = cox.act{
            {"moveb", (G.W-size.width)/speed, G.W-size.width, 0},
            {"moveb", (G.W-size.width)/speed, -(G.W-size.width), 0},
            {"repeat", -1},
            {"speed", 1}
        }
    else
        action = cox.act{
            {"moveb", (G.W-size.width)/speed, -(G.W-size.width), 0},
            {"moveb", (G.W-size.width)/speed, G.W-size.width, 0},
            {"repeat", -1},
            {"speed", 1}
        }
    end
    action:setTag(CURRENT_ACTION)
    block:runAction(action)
end

function S:ontouch(touch)
    if self.current and not self.paused then
        self:putdown()
    end
end

function S:putdown()
    local block = self.current
    block:stopAllActions()
    local x, y = block:getPosition()
    local size = block:getContentSize()
    local left = x
    local right = x + size.width
    local edge = self.edge
    local tex_x = 0
    
    -- 不要太精确, 在粒度范围内, 自动对齐
    if math.abs(edge.left-left) <= self.precision then
        x = edge.left
        left = x
        right = x + size.width
        block:set{x=edge.left}
    end
    
    if right < edge.left or left > edge.right then
        cox.safedel(block)
        self:drop(x, y, size.width, 1)
        self:lose()
        return
    end

    if left < edge.left then
        size.width = size.width - (edge.left - left)
        self:drop(left, y, edge.left-left, -1)
        tex_x = edge.left - left
        left = edge.left
    end
    if right > edge.right then
        size.width = size.width - (right - edge.right)
        self:drop(edge.right, y, right-edge.right, 1)
        right = edge.right
    end
    block:setTextureRect(cc.rect(tex_x,0,right-left,size.height))
    block:set{x=left}
    edge.left = left
    edge.right = right
    
    table.append(self.floors, block)
    self.speed = self.speed + 30
    self.basew = right - left
    self.floor_num:setString(string.format("%d", #self.floors))
    if #self.floors % 2 == 0 and self.basew > 100 then
        block:runact{"fadeout", 0.3}
        self:putpillars(left, right, y)
    end
    self:newblock()
    if #self.floors > 5 then
        self:scroll()
    end
end

function S:newpillar(id, x, y)
    local p = cox.newspr{
        on=self.layer,
        tex=string.format("scene1/pillar-%d.png", id),
        x=x,
        y=y,
        z=-1
    }
end

function S:putpillars(left, right, y)
    local id = math.random(1,2)
    self:newpillar(id, left+20, y)
    self:newpillar(id, right-20, y)
    local w = right - left - 100
    for x = left+50, right-50, 60 do
        self:newpillar(id, x, y)
    end
end

function S:drop(x, y, w, direction)
    local block = cox.newspr{
        on=self.layer, 
        tex="scene1/dg-1-1.png",
        x=x,
        y=y,
        ac={0,0.5},
    }
    block:getTexture():setTexParameters(gl.LINEAR, gl.LINEAR, gl.REPEAT, gl.REPEAT)
    block:setTextureRect(cc.rect(0,0,w,self.baseh))
    block:runact{
        {
            {"moveb", 1, direction*30, -50},
            {"rotb", 1, direction*50},
            {"fadeout", 1},
            {"spawn", true}
        },
        {"remove"}
    }
end

function S:scroll()
    cox.runact(self.layer, {
        {"moveb", 0.5, 0, -self.baseh}
    })
    cox.runact(self.bg_layer, {
        {"moveb", 0.5, 0, -20}
    })
end

function S:lose()
    local ui_layer = self.ui_layer
    self.current = nil
    local best = G.getbest()
    if #self.floors > best then
        best = #self.floors
        G.setbest(best)
    end
    local bestcn = cox.newspr{
        on=ui_layer,
        texf="bestcn.png",
        x=G.W/2-60,
        y=G.H-200
    }

    local num = cox.charlabel("num-1.png", 52, 67, 48, {
        on=ui_layer,
        x=G.W/2+140, 
        y=G.H-200,
    })
    num:setstr(best)
    
    local restart_b = cox.button{
        on=ui_layer,
        normal="restart-1.png", 
        pressed="restart-2.png",
        y=200
    }
    restart_b:ontouch(function()
        G.switch("game")
    end)
    
end

function S:open_menu()
    local bg = cox.newspr{
        on=self.layer,
        name="menu",
        texf="menu-bg.png",
        x=G.W,
        y=G.H/2+50,
        ac={1,0.5}
    }
    local size = bg:getContentSize()
    local resume_b = cox.button{
        on=bg,
        normal="resume-1.png",
        pressed="resume-2.png",
        x=size.width-30,
        y=300,
        ac={1,0.5},
    }
    resume_b:ontouch(function()
        self:close_menu()
        self:resume()
    end)
    local about_b = cox.button{
        on=bg,
        normal="aboutus-1.png",
        pressed="aboutus-2.png",
        x=size.width-30,
        y=190,
        ac={1,0.5},
    }
    about_b:ontouch(function() 
    
    end)
    local restart_b = cox.button{
        on=bg,
        normal="restart-1.png",
        pressed="restart-2.png",
        x=size.width-30,
        y=80,
        ac={1,0.5},
    }
    restart_b:ontouch(function() 
        G.switch("game")
    end)
end

function S:close_menu()
    local menu = self.layer:getChildByName("menu")
    if menu then
        menu:removeFromParent()
    end
end

return S