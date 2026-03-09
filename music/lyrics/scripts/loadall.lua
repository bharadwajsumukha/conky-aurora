-- scripts/loadall.lua - Loads and calls Lua Modules
-- by @wim66 -- v4.1 May 2, 2025
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

-- ============================================================
-- conky_main  (lua_draw_hook_pre)
-- Draws: background border, nowplaying section, volume section
-- ============================================================
function conky_main()
    if conky_window == nil then return end

    -- Background + border (from background.lua)
    conky_draw_background()
end
