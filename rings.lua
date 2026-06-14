require 'cairo'

-- ═══════════════════════════════════════════════════════════════
--  SIRA SYSTEM MONITOR  —  full Cairo dashboard
--  W=600, H=390
--  Header       y=0..34
--  Rings        cy=112, R=46
--  Divider      y=~172
--  Bottom panels y=180..380
-- ═══════════════════════════════════════════════════════════════

math.randomseed(os.time())

-- ── colours (pure black bg, deep blue accent) ─────────────────
local function rgba(r,g,b,a) return r/255,g/255,b/255,a or 1 end

local B1r,B1g,B1b = rgba(30,130,255)    -- #1E82FF  bright blue
local B2r,B2g,B2b = rgba( 8, 40,100)    -- track bg
local Wr,Wg,Wb    = 1,1,1
local Gr,Gg,Gb    = rgba(150,180,210)   -- blue-gray labels
-- background is pure black via own_window_colour='000000'

-- ── primitives ────────────────────────────────────────────────
local function set(cr,r,g,b,a) cairo_set_source_rgba(cr,r,g,b,a or 1) end

local function arc_ring(cr, cx,cy, rad, lw, pct, r,g,b,a, tr,tg,tb,ta)
    local s = -math.pi/2
    cairo_set_line_width(cr, lw)
    set(cr,tr,tg,tb,ta)
    cairo_arc(cr,cx,cy,rad,0,2*math.pi) cairo_stroke(cr)
    if pct>0 then
        set(cr,r,g,b,a)
        cairo_arc(cr,cx,cy,rad,s,s+2*math.pi*(pct/100)) cairo_stroke(cr)
        local ex=cx+rad*math.cos(s+2*math.pi*(pct/100))
        local ey=cy+rad*math.sin(s+2*math.pi*(pct/100))
        set(cr,r,g,b,1)
        cairo_arc(cr,ex,ey,lw/2+1.2,0,2*math.pi) cairo_fill(cr)
    end
end

local function txt(cr,x,y,str,sz,bold,r,g,b,a,anchor)
    cairo_select_font_face(cr,"JetBrains Mono",
        CAIRO_FONT_SLANT_NORMAL,
        bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr,sz)
    local e=cairo_text_extents_t:create()
    cairo_text_extents(cr,str,e)
    local ox=(anchor=="center") and (-e.width/2-e.x_bearing)
          or (anchor=="right")  and (-e.width-e.x_bearing)
          or (-e.x_bearing)
    cairo_move_to(cr,x+ox,y-e.height/2-e.y_bearing)
    set(cr,r,g,b,a or 1)
    cairo_show_text(cr,str)
end

local function hline(cr,x1,y,x2,r,g,b,a,lw)
    cairo_set_line_width(cr,lw or 0.5)
    set(cr,r,g,b,a) cairo_move_to(cr,x1,y) cairo_line_to(cr,x2,y) cairo_stroke(cr)
end

local function vline(cr,x,y1,y2,r,g,b,a)
    cairo_set_line_width(cr,0.5)
    set(cr,r,g,b,a) cairo_move_to(cr,x,y1) cairo_line_to(cr,x,y2) cairo_stroke(cr)
end

local function hbar(cr,x,y,w,h,pct,r,g,b)
    set(cr,B2r,B2g,B2b,1) cairo_rectangle(cr,x,y,w,h) cairo_fill(cr)
    set(cr,r,g,b,0.9)
    cairo_rectangle(cr,x,y,w*math.min(pct,100)/100,h) cairo_fill(cr)
end

-- ── data ──────────────────────────────────────────────────────
local function cpu()  return tonumber(conky_parse("${cpu cpu0}")) or 0 end
local function ramp() return tonumber(conky_parse("${memperc}"))  or 0 end
local function rmem() return conky_parse("${mem}").."/"..conky_parse("${memmax}") end
local function temp()
    local t=conky_parse("${execi 4 sensors|grep 'Tctl'|awk '{print $2}'|tr -d '+'}")
    return tonumber((t:gsub("[^%d%.]",""))) or 0
end
local function bat()    return tonumber(conky_parse("${battery_percent BAT0}")) or 0 end
local function bstatus()
    return (conky_parse("${execi 5 cat /sys/class/power_supply/BAT0/status}"):gsub("%s",""))
end
local function btime()
    local s=conky_parse("${battery_time BAT0}"):gsub("%s","")
    return (s==""or s=="unknown") and "calculating" or s
end
local function uptime() return conky_parse("${uptime}"):gsub("^%s+",""):gsub("%s+$","") end
local function upshort() return conky_parse("${uptime_short}"):gsub("%s","") end
local function netdn() return conky_parse("${downspeed wlp2s0}"):gsub("%s","") end
local function netup() return conky_parse("${upspeed wlp2s0}"):gsub("%s","") end
local function ssid()  return conky_parse("${wireless_essid wlp2s0}"):gsub("%s","") end
local function procs()
    local t={}
    for i=1,4 do
        local n=conky_parse("${top name "..i.."}"):gsub("^%s+",""):gsub("%s+$","")
        local c=tonumber(conky_parse("${top cpu "..i.."}")) or 0
        t[i]={n=n,c=c}
    end
    return t
end

local net_hist={}
for i=1,22 do net_hist[i]=math.random(3,16) end

-- ── main ──────────────────────────────────────────────────────
function conky_draw_rings()
    if conky_window==nil then return end
    local cs=cairo_xlib_surface_create(
        conky_window.display,conky_window.drawable,
        conky_window.visual,conky_window.width,conky_window.height)
    local cr=cairo_create(cs)

    local W=conky_window.width   -- 600
    local H=conky_window.height  -- 390

    -- ── HEADER  y=0..34 ──────────────────────────────────────
    -- Left accent stripe
    set(cr,B1r,B1g,B1b,1)
    cairo_rectangle(cr,12,9,3,18) cairo_fill(cr)

    -- Title: "SIRA" in bright blue, "SYSTEM MONITOR" in dim
    txt(cr,22,18,"SIRA",11,true,B1r,B1g,B1b,1)
    txt(cr,70,18,"SYSTEM MONITOR",11,false,Gr,Gg,Gb,0.65)

    -- Uptime right-aligned
    txt(cr,W-14,18,"UPTIME  "..uptime(),8,false,Gr,Gg,Gb,0.7,"right")

    hline(cr,12,32,W-12,B1r,B1g,B1b,0.2)

    -- ── RINGS  cy=112 ────────────────────────────────────────
    local cy  = 112
    local R1  = 46
    local R2  = 33
    local lw1 = 4.5
    local lw2 = 2

    local cols   = {75, 225, 375, 525}
    local clbls  = {"CPU USAGE","RAM USAGE","TEMP","UPTIME"}

    local cpuv = cpu()
    local ramv = ramp()
    local tmpv = temp()
    local tmpp = math.min(tmpv/100*100,100)
    local upv  = upshort()

    local vals={
        {pct=cpuv, big=cpuv.."%",                        sub=nil},
        {pct=ramv, big=ramv.."%",                        sub=rmem()},
        {pct=tmpp, big=string.format("%.0f°C",tmpv),    sub="CPU"},
        {pct=100,  big=upv:match("^[^%s]+") or upv,
                   sub=upv:match("%s(.+)$") or ""},
    }

    for i,cx in ipairs(cols) do
        local d=vals[i]

        -- column label above ring
        txt(cr,cx,cy-R1-14,clbls[i],7.5,false,Gr,Gg,Gb,0.65,"center")

        -- subtle outer glow
        cairo_set_line_width(cr,lw1+10)
        set(cr,B1r,B1g,B1b,0.04)
        cairo_arc(cr,cx,cy,R1+5,0,2*math.pi) cairo_stroke(cr)

        -- rings
        arc_ring(cr,cx,cy,R1,lw1,d.pct, B1r,B1g,B1b,1, B2r,B2g,B2b,0.9)
        arc_ring(cr,cx,cy,R2,lw2,d.pct*0.65, B1r,B1g,B1b,0.3, B2r,B2g,B2b,0.5)

        -- value
        txt(cr,cx,cy+(d.sub and -5 or 0),d.big,14,true,Wr,Wg,Wb,1,"center")

        -- sub
        if d.sub and d.sub~="" then
            txt(cr,cx,cy+13,d.sub,7.5,false,Gr,Gg,Gb,0.65,"center")
        end
    end

    -- ── DIVIDER ──────────────────────────────────────────────
    local divY = cy+R1+18   -- ~176
    hline(cr,12,divY,W-12,B1r,B1g,B1b,0.2)

    -- ── BOTTOM 3 PANELS ──────────────────────────────────────
    -- cols: 0..199 | 200..399 | 400..599  (200px each)
    local pY   = divY+8
    local c1x  = 14
    local c2x  = 214
    local c3x  = 414
    local panW = 184

    vline(cr,207,divY+2,H-8,B1r,B1g,B1b,0.18)
    vline(cr,407,divY+2,H-8,B1r,B1g,B1b,0.18)

    local function sec(x,title)
        txt(cr,x,pY+10,"· "..title,8,false,B1r,B1g,B1b,0.85)
        hline(cr,x,pY+15,x+panW,B1r,B1g,B1b,0.18)
    end

    -- ── NETWORK ──────────────────────────────────────────────
    sec(c1x,"NETWORK")
    local ny=pY+28
    txt(cr,c1x,ny,    "↓  "..netdn(),9,false,Gr,Gg,Gb,1)
    txt(cr,c1x,ny+18, "↑  "..netup(),9,false,Gr,Gg,Gb,1)
    txt(cr,c1x,ny+38, "SSID",7.5,false,B2r+0.15,B2g+0.25,B2b+0.4,0.7)
    txt(cr,c1x,ny+52, ssid(),9,false,Wr,Wg,Wb,0.88)

    -- mini bar graph
    table.remove(net_hist,1)
    table.insert(net_hist,math.random(3,16))
    local bY0=H-12
    for i,h in ipairs(net_hist) do
        set(cr,B1r,B1g,B1b,0.12+0.45*(i/#net_hist))
        cairo_rectangle(cr,c1x+(i-1)*7,bY0-h,5,h)
        cairo_fill(cr)
    end

    -- ── PROCESSES ────────────────────────────────────────────
    sec(c2x,"PROCESSES")
    local ps=procs()
    for i,p in ipairs(ps) do
        local ry=pY+26+(i-1)*28
        txt(cr,c2x,ry,p.n:sub(1,13),8,false,Gr,Gg,Gb,0.9)
        hbar(cr,c2x+96,ry-7,54,5,math.min(p.c*5,100),B1r,B1g,B1b)
        txt(cr,c2x+panW,ry,string.format("%.1f%%",p.c),8,false,B1r,B1g,B1b,1,"right")
    end

    -- ── BATTERY ──────────────────────────────────────────────
    sec(c3x,"BATTERY")
    local bv  = bat()
    local bcx = c3x+panW/2
    local bcy = pY+76

    arc_ring(cr,bcx,bcy,36,4.5,bv,  B1r,B1g,B1b,1, B2r,B2g,B2b,0.9)
    arc_ring(cr,bcx,bcy,26,2,  bv*0.65, B1r,B1g,B1b,0.3, B2r,B2g,B2b,0.5)

    txt(cr,bcx,bcy,bv.."%",14,true,Wr,Wg,Wb,1,"center")

    local bs=bstatus()
    local icon=(bs=="Charging") and " ⚡" or ""
    txt(cr,bcx,bcy+46,bs..icon,8,false,Gr,Gg,Gb,0.8,"center")
    txt(cr,bcx,bcy+60,btime(),8,false,B1r,B1g,B1b,0.85,"center")

    -- ── outer border ─────────────────────────────────────────
    cairo_set_line_width(cr,1)
    set(cr,B1r,B1g,B1b,0.15)
    cairo_rectangle(cr,1,1,W-2,H-2) cairo_stroke(cr)

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end
