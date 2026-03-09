-- scripts/nowplaying.lua
-- Now Playing section: album art, artist/album/title, progress bar + times
-- Called from loadall.lua with a shared Cairo context
-- v1 01 2026-03-09 @rew62

local image_path = '/dev/shm/'

-- Progress bar config (positions are relative to section y_off)
local pt = {
    bg_color = 0xffffff, bg_alpha = 0.3,
    fg_color = 0xffffff, fg_alpha = 1.0,
    width = 240, height = 6,
    -- x/y set dynamically in draw_nowplaying
}

-- ── helpers ────────────────────────────────────────────────

local function rgb_to_rgba(color, alpha)
    return ((color / 0x10000) % 0x100) / 255,
           ((color / 0x100)   % 0x100) / 255,
           (color              % 0x100) / 255,
           alpha
end

local function exec_cmd(cmd)
    local h = io.popen(cmd)
    local r = h:read("*a")
    h:close()
    return r
end

local function get_position()
    return tonumber(exec_cmd("playerctl position 2>/dev/null")) or 0
end

local function get_duration()
    return (tonumber(exec_cmd("playerctl metadata mpris:length 2>/dev/null")) or 0) / 1000000
end

local function fmt_time(s)
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    local ss = math.floor(s % 60)
    if h > 0 then return string.format("%d:%02d:%02d", h, m, ss) end
    return string.format("%02d:%02d", m, ss)
end

-- ── drawing helpers ────────────────────────────────────────

local function draw_image(cr, path, x, y, w, h)
    local f = io.open(path, "r")
    if not f then return end
    f:close()
    local img = cairo_image_surface_create_from_png(path)
    local iw  = cairo_image_surface_get_width(img)
    local ih  = cairo_image_surface_get_height(img)
    if iw == 0 or ih == 0 then cairo_surface_destroy(img); return end
    cairo_save(cr)
    cairo_translate(cr, x, y)
    cairo_scale(cr, w / iw, h / ih)
    cairo_set_source_surface(cr, img, 0, 0)
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
    cairo_paint(cr)
    cairo_restore(cr)
    cairo_surface_destroy(img)
    collectgarbage()
end

local function write_text(cr, x, y, text, f)
    f = f or {}
    local font   = f.font   or "Droid Sans"
    local size   = f.size   or 10
    local align  = f.align  or 'l'
    local bold   = f.bold   or false
    local ital   = f.italic or false
    local color  = f.color  or 0xffffff
    local alpha  = f.alpha  or 1.0

    local slant  = ital and CAIRO_FONT_SLANT_ITALIC  or CAIRO_FONT_SLANT_NORMAL
    local weight = bold and CAIRO_FONT_WEIGHT_BOLD   or CAIRO_FONT_WEIGHT_NORMAL

    local te = cairo_text_extents_t:create()
    tolua.takeownership(te)
    cairo_select_font_face(cr, font, slant, weight)
    cairo_set_font_size(cr, size)
    cairo_text_extents(cr, text, te)

    local x_a, y_a = 0, 0
    if align == 'c' then
        x_a = -(te.width / 2 + te.x_bearing)
        y_a = -(te.height / 2 + te.y_bearing)
    elseif align == 'r' then
        x_a = -(te.width + te.x_bearing)
    end

    -- shadow
    cairo_set_source_rgba(cr, 0, 0, 0, 0.8)
    cairo_move_to(cr, x + 1 + x_a, y + 1 + y_a)
    cairo_show_text(cr, text)
    cairo_stroke(cr)
    -- main
    cairo_set_source_rgba(cr, rgb_to_rgba(color, alpha))
    cairo_move_to(cr, x + x_a, y + y_a)
    cairo_show_text(cr, text)
    cairo_stroke(cr)
end

local function draw_progress_bar(cr, pct, cfg)
    -- background track
    cairo_rectangle(cr, cfg.x, cfg.y, cfg.width, cfg.height)
    cairo_set_source_rgba(cr, rgb_to_rgba(cfg.bg_color, cfg.bg_alpha))
    cairo_fill(cr)
    -- filled portion
    cairo_rectangle(cr, cfg.x, cfg.y, cfg.width * pct, cfg.height)
    cairo_set_source_rgba(cr, rgb_to_rgba(cfg.fg_color, cfg.fg_alpha))
    cairo_fill(cr)
end

local function draw_times(cr, cfg, pos, total, y_off)
    local elapsed = fmt_time(pos)
    local dur     = fmt_time(total)
    write_text(cr, cfg.x,               y_off, elapsed, {font="Droid Sans", size=11, align="l"})
    write_text(cr, cfg.x + cfg.width,   y_off, dur,     {font="Droid Sans", size=11, align="r"})
end

-- ── section label ──────────────────────────────────────────

local function draw_section_label(cr, label, x, y)
    -- small pill label
    cairo_set_source_rgba(cr, 1, 1, 1, 0.08)
    cairo_rectangle(cr, x - 4, y - 13, 90, 17)
    cairo_fill(cr)
    write_text(cr, x, y, label, {font="Good Times", size=14, color=0x98FB98, alpha=0.9})
end

-- ── public entry point ─────────────────────────────────────

-- y_off: top y coordinate of this section within the conky window
function draw_nowplaying(cr, y_off)
    local status = exec_cmd("playerctl status 2>/dev/null"):gsub("%s+", "")
    if status ~= "Playing" then
        -- Draw a "not playing" placeholder
        write_text(cr, 170, y_off + 80, "Not Playing",
            {font="Droid Sans", size=14, align="c", color=0x888888, alpha=0.7})
        return
    end

    -- Fetch metadata
    local artist = exec_cmd("playerctl metadata xesam:artist 2>/dev/null"):gsub("%s+$", "")
    local album  = exec_cmd("playerctl metadata xesam:album  2>/dev/null"):gsub("%s+$", "")
    local title  = exec_cmd("playerctl metadata xesam:title  2>/dev/null"):gsub("%s+$", "")
    local art    = image_path .. "tmp.png"

    -- Extract album art
    os.remove(art)
    local url_cmd = "playerctl metadata xesam:url 2>/dev/null"
    local cmd = string.format(
        "ffmpeg -y -i \"$(echo $(%s) | sed 's|file://||;s/%%20/ /g;s/%%40/@/g')\" " ..
        "-an -vcodec png -vframes 1 %s >/dev/null 2>&1", url_cmd, art)
    os.execute(cmd)

    -- Layout constants
    local art_x, art_y    = 15,  y_off
    local art_size        = 130
    local meta_x          = art_x + art_size + 15   -- 160
    local label_color     = 0x8dddff
    local bar_y           = y_off + art_size + 12
    local bar_x           = 20 
    local bar_w           = 310
    local times_y         = bar_y + 18

    -- Album art
    draw_image(cr, art, art_x, art_y, art_size, art_size)

    -- Section label
    draw_section_label(cr, "Now Playing", meta_x, y_off + 10)

    -- Metadata labels
    write_text(cr, meta_x, y_off + 35, "Artist", {font="Droid Sans", size=9,  align="l", color=label_color})
    write_text(cr, meta_x, y_off + 65, "Album",  {font="Droid Sans", size=9,  align="l", color=label_color})
    write_text(cr, meta_x, y_off + 100,"Title",  {font="Droid Sans", size=9,  align="l", color=label_color})

    -- Metadata values (truncate long strings to fit ~165px column)
    local function trunc(s, maxlen)
        if #s > maxlen then return s:sub(1, maxlen - 1) .. "…" end
        return s
    end
    write_text(cr, meta_x, y_off + 50,  trunc(artist, 22), {font="Nimbus Sans", size=13, align="l"})
    write_text(cr, meta_x, y_off + 80,  trunc(album,  22), {font="Play",        size=13, align="l"})
    write_text(cr, meta_x, y_off + 115, trunc(title,  22), {font="Play",        size=13, align="l"})

    -- Progress bar
    local pos   = get_position()
    local total = get_duration()
    if total > 0 then
        local bar_cfg = {
            x = bar_x, y = bar_y,
            width = bar_w, height = 5,
            bg_color = pt.bg_color, bg_alpha = pt.bg_alpha,
            fg_color = pt.fg_color, fg_alpha = pt.fg_alpha,
        }
        draw_progress_bar(cr, pos / total, bar_cfg)
        draw_times(cr, bar_cfg, pos, total, times_y)
    end
end

