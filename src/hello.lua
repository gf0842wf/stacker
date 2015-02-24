local S = class("HelloScene", function() 
    return cc.Scene:create()
end)

function S.create()
    local s = S.new()

    s.loadres()
    s.layer = s:alayer()
    s:addChild(s.layer)

    return s
end

function S.loadres()
    cox.addsf("scene1/scene1.plist")
    cox.addsf("ui.plist")
end

function S:alayer()
    local layer = cc.Layer:create()
    
    -- on keyback pressed
    cox.bindkb(layer, function()
        cox.d:endToLua()
    end)
    
    local bg = cox.newspr{on=layer, tex="scene1/bg.jpg", y=0, ac={0.5, 0}}
    local hill = cox.newspr{on=layer, texf="hill.png", y=400}
    local cloud1 = cox.newspr{on=layer, texf="cloud-1.png", x=0, y=900}
    local cloud2 = cox.newspr{on=layer, texf="cloud-2.png", x=200, y=700}
    local cloud3 = cox.newspr{on=layer, texf="cloud-3.png", x=500, y=600}
    local ground = cox.newspr{on=layer, texf="ground.png", y=0, ac={0.5,0}}
    local desk = cox.newspr{on=layer, texf="desk.png", y=0, ac={0.5,0}}
    local logo = cox.newspr{on=layer, texf="logo.png", y=700}
    
    function movcloud(cloud, speed)
        local x, y = cloud:getPosition()
        local size = cloud:getContentSize()
        cloud:runact{
            {"move", (x+size.width/2)/speed, -size.width/2, y},
            {"move", 0, G.W+size.width/2, y},
            {"move", (G.W+size.width/2-x)/speed, x, y},
            {"repeat", -1}
        }
    end
    movcloud(cloud1, 15)
    movcloud(cloud2, 20)
    movcloud(cloud3, 10)
    
    local start_b = cox.button{
                        on=layer, 
                        normal="start-1.png", 
                        pressed="start-2.png",
                        y = 250,
                        }
    start_b:ontouch(function()
        G.switch("game", true)
    end)
    
    return layer
end

return S