-- scripts/loadall.lua
-- loads and calls: background, nowplaying, volume
-- v1 01 2026-03-09 @rew62

package.path = "./scripts/?.lua"

local function try_require(modname)
    local ok, result = pcall(require, modname)
    if not ok then
        print("Error loading " .. modname .. ": " .. tostring(result))
    end
    return ok
end

try_require("background")
try_require("nowplaying")
try_require("volume")

-- ============================================================
-- conky_main  (lua_draw_hook_pre)
-- Draws: background border, nowplaying section, volume section
-- ============================================================
function conky_main()
    if conky_window == nil then return end

    -- 1. Background + border (from background.lua)
    conky_draw_background()

    -- shared Cairo surface for all remaining lua drawing
    local cs = cairo_xlib_surface_create(
        conky_window.display, conky_window.drawable,
        conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)

    -- 2. Now Playing section  (top of window, y-offset = 15)
    draw_nowplaying(cr, 15)

    -- 3. Volume section  (below nowplaying, y-offset = 200)
    draw_volume(cr, 200)

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end
