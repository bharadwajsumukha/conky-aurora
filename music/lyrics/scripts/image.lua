require 'cairo'

home = os.getenv("HOME")
art_cache = home .. "/.cache/conky_album_art.png"

local function get_album_art()
    local cmd = "playerctl metadata mpris:artUrl 2>/dev/null"
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()

    if not result or result == "" then
        return nil
    end

    result = result:gsub("\n", "")

    -- local file
    if result:match("^file://") then
        local src = result:gsub("^file://", "")

        -- convert ANY image type to PNG for cairo
        os.execute(
            "ffmpeg -loglevel quiet -y -i '" .. src .. "' '" .. art_cache .. "'"
        )
        return art_cache
    end

    -- remote URL
    if result:match("^https?://") then
        os.execute(
            "wget -q -O '" .. art_cache .. "' '" .. result .. "'"
        )
        return art_cache
    end

    return nil
end

function conky_draw_album_art(x, y, w, h, arc)
    if conky_window == nil then return "" end

    local path = get_album_art()
    if not path then return "" end

    local cs = cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height
    )

    local img = cairo_image_surface_create_from_png(path)
    if cairo_surface_status(img) ~= CAIRO_STATUS_SUCCESS then
        cairo_surface_destroy(img)
        cairo_surface_destroy(cs)
        return ""
    end

    local w_img = cairo_image_surface_get_width(img)
    local h_img = cairo_image_surface_get_height(img)

    local cr = cairo_create(cs)

    cairo_translate(cr, x + w / 2, y + h / 2)
    if arc then cairo_rotate(cr, arc) end
    cairo_scale(cr, w / w_img, h / h_img)

    cairo_set_source_surface(cr, img, -w_img / 2, -h_img / 2)
    cairo_paint(cr)

    cairo_destroy(cr)
    cairo_surface_destroy(img)
    cairo_surface_destroy(cs)

    return ""
end

