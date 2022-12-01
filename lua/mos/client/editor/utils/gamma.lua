local gamma = {}
local gammaMultiplier = cvars.Number( "mat_monitorgamma_tv_exp", 2.5 ) / cvars.Number( "mat_monitorgamma", 2.2 )

local round = math.Round

function gamma.applyToColor( color )
    color.r = round( color.r * gammaMultiplier )
    color.g = round( color.g * gammaMultiplier )
    color.b = round( color.b * gammaMultiplier )
end

function gamma.applyToRGB( r, g, b, a )
    r = round( r * gammaMultiplier )
    g = round( g * gammaMultiplier )
    b = round( b * gammaMultiplier )
    return r, g, b, a
end

return gamma
