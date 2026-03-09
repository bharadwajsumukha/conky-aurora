-- settings.lua
-- Unified Music Conky Settings
-- @rew62 2026

package.path = "./scripts/?.lua"

function conky_vars()
    border_COLOR = "0,0x2E8B57,1.00,0.5,0x2E8B57,1.00,1,0x2E8B57,1.00"
    bg_COLOR     = "0x353376,0.4"
    layer_2      = "0,0xffffff,0.5,0.5,0xc2c2c2,0.50,1,0xffffff,0.5"

    -- Unified window dimensions (must match music.rc minimum_width/height)
    width  = 200
    height = 200

    bg_x = 0
    bg_y = 0
end
