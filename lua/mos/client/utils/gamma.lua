local gamma = {}

local mult = cvars.Number( "mat_monitorgamma_tv_exp", 2.5 ) / cvars.Number( "mat_monitorgamma", 2.2 )
local round = math.Round

function gamma.applyToColor( color )
    color.r = round( color.r * mult )
    color.g = round( color.g * mult )
    color.b = round( color.b * mult )
end

function gamma.applyToRGB( r, g, b, a )
    r = round( r * mult )
    g = round( g * mult )
    b = round( b * mult )
    return r, g, b, a
end

function gamma.colorFromColor( color )
    local r = round( color.r * mult )
    local g = round( color.g * mult )
    local b = round( color.b * mult )
    return Color( r, g, b, color.a )
end

function gamma.colorFromRGB( r, g, b, a )
    r = round( r * mult )
    g = round( g * mult )
    b = round( b * mult )
    return Color( r, g, b, a or 255 )
end

return gamma
