-- settings.lua
-- v1 04 2026-03-09 @rew62

package.path = "./scripts/?.lua"

function conky_vars()
    border_COLOR = "0,0x2E8B57,1.00,0.5,0x2E8B57,1.00,1,0x2E8B57,1.00"
    bg_COLOR     = "0x353376,0.4"
    layer_2      = "0,0xffffff,0.5,0.5,0xc2c2c2,0.50,1,0xffffff,0.5"

    -- Window Dimensions 
    --width  = 200
    --height = 445
    conky_w = 198 
    conky_h = 445
end
