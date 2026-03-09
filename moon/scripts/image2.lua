-- image2.lua - lua to draw images on top of background
-- v1 01 2026-0309 @rew62
--

function conky_draw_image(path, x, y, w, h)
    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(
        conky_window.display, conky_window.drawable,
        conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)

    -- Load the PNG
    local img = cairo_image_surface_create_from_png(path)
    if cairo_surface_status(img) ~= CAIRO_STATUS_SUCCESS then
        cairo_destroy(cr)
        cairo_surface_destroy(cs)
        return
    end

    local iw = cairo_image_surface_get_width(img)
    local ih = cairo_image_surface_get_height(img)

    cairo_translate(cr, x, y)
    cairo_scale(cr, w / iw, h / ih)
    cairo_set_source_surface(cr, img, 0, 0)
    -- KEY: use SOURCE so image paints over everything
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
    cairo_paint(cr)

    cairo_surface_destroy(img)
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end
