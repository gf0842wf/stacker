cc.FileUtils:getInstance():setPopupNotify(true)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")
cox = require "cox"
G = require "global"
require "cocos.cocos2d.Opengl"
require "cocos/cocos2d/OpenglConstants"

local function main()
    cox.setrso(G.W, G.H, 2)
    cox.d:setDisplayStats(false)
    math.randomseed(os.time())

    G.switch("hello")
end

cox.xpcall(main)
