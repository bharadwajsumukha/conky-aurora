-- settings.lua
-- by @wim66
-- v5 May 6, 2025

-- Set the path to the scripts folder
package.path = "./scripts/?.lua"

function conky_vars()

    -- border_COLOR: Defines the gradient border for the Conky widget.
    -- Format: "start_angle,color1,opacity1,midpoint,color2,opacity2,steps,color3,opacity3"
    -- Example: "0,0x390056,1.00,0.5,0xff007f,1.00,1,0x390056,1.00" creates a purple-pink gradient.
    --border_COLOR = "0,0x6e7598,1.00,0.5,0x6e7598,1.00,1,0x6e7598,1.00"
    border_COLOR = "0,0x2E8B57,1.00,0.5,0x2E8B57,1.00,1,0x2E8B57,1.00"

    -- bg_COLOR: Background color and opacity for the widget.
    -- Format: "color,opacity"
    -- Example: "0x1d1e28,0.75" sets a dark purple background with 75% opacity.
    bg_COLOR = "0x353376,0.4"

    -- layer_2: Defines the gradient for the second layer of the Conky widget.
    -- Format: "start_angle,color1,opacity1,midpoint,color2,opacity2,steps,color3,opacity3"
    -- Example: "0,0x00007f,0.50,0.5,0x00aaff,0.50,1,0x00007f,0.50" creates a blue gradient with 50% opacity.
    layer_2 = "0,0xffffff,0.5,0.5,0xc2c2c2,0.50,1,0xffffff,0.5"

    -- Dimaensions
    conky_w = 200
    conky_h = 200
end

