local G = {}

local BG_MUSIC = "music/bg.mp3"
local SELECT_SOUND = "music/select.mp3"

G.debug = true

-- design resolution
G.W = 640
G.H = 960

function G.openms()
    cox.setud("music_on", true)
    cox.playms(BG_MUSIC, true)
end

function G.closems()
    cox.setud("music_on", false)
    cox.stopms()
end

function G.ismson()
    return cox.getud("music_on", true)
end

function G.isefon()
    return cox.getud("effect_on", true)
end

function G.openef()
    cox.setud("effect_on", true)
end

function G.closeef()
    cox.setud("effect_on", false)
end

function G.playef(filename)
    if G.isefon() then
        cox.playef(filename)
    end
end

-- play the "select" sound
function G.playsel()
    G.playef(SELECT_SOUND)
end

function G.newscene(name, ...)
    cox.fc:removeUnusedSpriteFrames()
    local arg = {...}
    return require(name).create(unpack(arg))
end

-- replace to next scene with package name
function G.switch(name, ...)
    local next = require(name).create(...)
    cox.switch(next)
end

function G.getbest()
    return cox.getud("best", 0)
end

function G.setbest(nfloor)
    cox.setud("best", nfloor)
end

return G