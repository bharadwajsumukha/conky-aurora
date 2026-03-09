-- settings.lua
-- v1 01 2026-03-09 @rew62

package.path = "./scripts/?.lua"

function conky_vars()
    border_COLOR = "0,0x2E8B57,1.00,0.5,0x2E8B57,1.00,1,0x2E8B57,1.00"
    bg_COLOR     = "0x353376,0.4"
    layer_2      = "0,0xffffff,0.5,0.5,0xc2c2c2,0.50,1,0xffffff,0.5"

    -- Unified window dimensions (must match music.rc minimum_width/height)
    conky_w = 340
    conky_h = 260

    bg_x = 0
    bg_y = 0
end
