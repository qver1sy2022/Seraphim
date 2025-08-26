local panorama_api = panorama.open()

local ffi = require('ffi')
local vector = require('vector')

local pui = require('gamesense/pui')
local color = require('gamesense/color')
local base64 = require("gamesense/base64")
local inspect = require('gamesense/inspect')
local clipboard = require("gamesense/clipboard")

local entity2 = require("gamesense/entity")
local csgo_weapons = require("gamesense/csgo_weapons")
local antiaim_funcs = require("gamesense/antiaim_funcs")

local angle3d_struct = ffi.typeof("struct { float pitch; float yaw; float roll; }")
local vec_struct = ffi.typeof("struct { float x; float y; float z; }")

local cUserCmd =
    ffi.typeof(
    [[
    struct
    {
        uintptr_t vfptr;
        int command_number;
        int tick_count;
        $ viewangles;
        $ aimdirection;
        float forwardmove;
        float sidemove;
        float upmove;
        int buttons;
        uint8_t impulse;
        int weaponselect;
        int weaponsubtype;
        int random_seed;
        short mousedx;
        short mousedy;
        bool hasbeenpredicted;
        $ headangles;
        $ headoffset;
        bool send_packet; 
    }
    ]],
    angle3d_struct,
    vec_struct,
    angle3d_struct,
    vec_struct
    )

local client_sig = client.find_signature("client.dll", "\xB9\xCC\xCC\xCC\xCC\x8B\x40\x38\xFF\xD0\x84\xC0\x0F\x85") or error("client.dll!:input not found.")
local get_cUserCmd = ffi.typeof("$* (__thiscall*)(uintptr_t ecx, int nSlot, int sequence_number)", cUserCmd)
local input_vtbl = ffi.typeof([[struct{uintptr_t padding[8];$ GetUserCmd;}]],get_cUserCmd)
local input = ffi.typeof([[struct{$* vfptr;}*]], input_vtbl)
local get_input = ffi.cast(input,ffi.cast("uintptr_t**",tonumber(ffi.cast("uintptr_t", client_sig)) + 1)[0])

local refs, refs2 do
    refs = {
        aa = {
            enabled = pui.reference("AA", "Anti-aimbot angles", "Enabled"),
            pitch = pui.reference("AA", "Anti-aimbot angles", "Pitch"),
            pitch_val = select(2, pui.reference("AA", "Anti-aimbot angles", "Pitch")),
            yaw_base = pui.reference("AA", "Anti-aimbot angles", "Yaw base"),
            yaw = pui.reference("AA", "Anti-aimbot angles", "Yaw"),
            yaw_val = select(2, pui.reference("AA", "Anti-aimbot angles", "Yaw")),
            jitter = pui.reference("AA", "Anti-aimbot angles", "Yaw jitter"),
            jitter_val = select(2, pui.reference("AA", "Anti-aimbot angles", "Yaw jitter")),
            body = pui.reference("AA", "Anti-aimbot angles", "Body yaw"),
            body_val = select(2, pui.reference("AA", "Anti-aimbot angles", "Body yaw")),
            body_fs = pui.reference("AA", "Anti-aimbot angles", "Freestanding body yaw"),
            fs = pui.reference("AA", "Anti-aimbot angles", "Freestanding"),
            edge = pui.reference("AA", "Anti-aimbot angles", "Edge yaw"),
            roll = pui.reference("AA", "Anti-aimbot angles", "Roll")
        },
        fl = {
            limit = pui.reference("AA","Fake lag", "Limit"),
            variance = pui.reference("AA","Fake lag", "Variance"),
            amount = pui.reference("AA","Fake lag", "Amount"),
            enabled = pui.reference("AA","Fake lag", "Enabled")
        },
        other = {
            slow = pui.reference("AA", "Other", "Slow motion"),
            osaa = pui.reference("AA","Other", "On shot anti-aim"),
            legmovement = pui.reference("AA","Other", "Leg movement"),
            fakepeek = pui.reference("AA","Other", "Fake peek")
        }
    }

    refs2 = {
        aimbot = pui.reference("RAGE", "Aimbot", "Enabled"),
        dt = pui.reference("RAGE", "Aimbot", "Double tap"),
        color = pui.reference("MISC", "Settings", "Menu Color"),
        dmg = pui.reference("RAGE", "Aimbot", "Minimum damage"),
        automatic_scope = pui.reference('RAGE', 'Aimbot', 'Automatic scope'),
        target_hitbox = pui.reference('RAGE', 'Aimbot', 'Target hitbox'),
        automatic_scope = pui.reference('RAGE', 'Aimbot', 'Automatic scope'),
        onshot_antiaim = pui.reference('AA', 'Other', 'On shot anti-aim'),
        doubletap_fakelag_limit = pui.reference('RAGE', 'Aimbot', 'Double tap fake lag limit'),
        mdmg = pui.reference("RAGE", "Aimbot", "Minimum damage Override"),
        mdmg2 = select(2, pui.reference("RAGE", "Aimbot", "Minimum damage Override")),
        hc = pui.reference("RAGE", "Aimbot", "Minimum hit chance"),
        mp = pui.reference("Rage", "Aimbot", "Multi-point scale"),
        baim = pui.reference("RAGE", "Aimbot", "Force body aim"),
        safe = pui.reference("RAGE", "Aimbot", "Force safe point"),
        dt_fl = pui.reference("RAGE", "Aimbot", "Double tap fake lag limit"),
        ping = pui.reference("Misc", "Miscellaneous", "Ping spike"),
        ping_val = select(2, pui.reference("Misc", "Miscellaneous", "Ping spike")),
        scope = pui.reference('VISUALS', 'Effects', 'Remove scope overlay'),
        zoom = pui.reference('MISC', 'Miscellaneous', 'Override zoom FOV'),
        quickpeek_mode = pui.reference('RAGE', 'Other', 'Quick peek assist mode'),
        quickpeek_distance = pui.reference('RAGE', 'Other', 'Quick peek assist distance'),
        fov = pui.reference('MISC', 'Miscellaneous', 'Override FOV'),
        log_spread = pui.reference("RAGE", "Other", "Log misses due to spread"),
        log_dealt = pui.reference("Misc", "Miscellaneous", "Log damage dealt"),
        anti_aim = pui.reference("Rage", "Other", "Anti-Aim Correction"),
        reset_all = pui.reference("Players", "Players", "Reset All"),
        force_body = pui.reference("Players", "Adjustments", "Force Body Yaw"),
        correction_active = pui.reference("Players", "Adjustments", "Correction Active"),
        dpi = pui.reference("Misc", "Settings", "DPI scale"),
        fd = pui.reference("RAGE", "Other", "Duck peek assist"),
        thirdperson = pui.reference('VISUALS', 'Effects', 'Force third person (alive)'),
        tag = pui.reference('MISC', 'Miscellaneous', 'Clan tag spammer'),
        weapon = pui.reference('Rage', 'Weapon type', 'Weapon type'),
        lp = pui.reference('VISUALS', 'Colored models', 'Local player'),
        lp2 = select(2, pui.reference('VISUALS', 'Colored models', 'Local player')),
    }
end

local condition_list do
    math.randomseed(globals.framecount() + globals.tickcount() + globals.realtime())
    pui.macros.r = '\aC8C8C8'
    pui.macros.ez = '\aafafff'
    condition_list = {"Default", "Standing", "Running", "Slowwalking", "Crouch", "Crouch Move", "Jumping", "Crouching Air", "Fake Lag", "Manual yaw", "Safe Head", "Dormant"}
end

local screen do
    screen = {}
    screen.size = vector(client.screen_size())
    screen.center = vector(client.screen_size()) * 0.5
end


-- screen.size = vector(3840, 2160)
-- screen.center = vector(3840, 2160) * 0.5

-- screen.size = vector(1920, 1080)
-- screen.center = vector(1920, 1080) * 0.5

local colors,hard= {}, {}
local height = vector(renderer.measure_text('d', '1')).y

local version do
    version = {}
    version[1] = "Source"
end

local username do
    username = {}
    username[1] = panorama_api.MyPersonaAPI.GetName() or "unknown"
end

local default do
    default = {
        viewmodel = {
            fov = cvar.viewmodel_fov:get_string(),
            x = cvar.viewmodel_offset_x:get_string(),
            y = cvar.viewmodel_offset_y:get_string(),
            z = cvar.viewmodel_offset_z:get_string()
        },
        dist = cvar.cam_idealdist:get_string()
    }
end

local utils do
    utils = {}

    utils.lerp = function(start, end_pos, time, ampl)
        if start == end_pos then return end_pos end
        ampl = ampl or 1/globals.frametime()
        local frametime = globals.frametime() * ampl
        time = time * frametime
        local val = start + (end_pos - start) * time
        if(math.abs(val - end_pos) < 0.25) then return end_pos end
        return val 
    end

    utils.to_hex = function(color, cut)
        return string.format("%02X%02X%02X".. (cut and '' or "%02X"), color.r, color.g, color.b, color.a or 255)
    end

    utils.to_rgb = function(hex)
        hex = hex:gsub("#ff0000", "")
        return color(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), tonumber(hex:sub(7, 8), 16) or 255)
    end

    utils.printc = function(text)
        local result = {}

        for color, content in text:gmatch("\a([A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9])([^%z\a]*)") do
            table.insert(result, {color, content})
        end
        local len = #result
        for i, t in pairs(result) do
            c = utils.to_rgb(t[1])
            client.color_log(c.r, c.g, c.b, t[2], len ~= i and '\0' or '')
        end
    end

    utils.normalize_yaw = function(x)
        return ((x + 180) % 360) - 180
    end
    
    utils.sine_yaw = function(tick, min, max)
        local amplitude = (max - min) / 2
        local center = (max + min) / 2
        return center + amplitude * math.sin(tick * 0.05)
    end
    
    utils.shuffle_table = function(t)
        for i = #t, 2, -1 do
            local j = math.random(i)
            t[i], t[j] = t[j], t[i]
        end
    end

    utils.rectangle = function(x, y, w, h, r, g, b, a, radius)
        radius = math.min(radius, w / 2, h / 2)

        local radius_2 = radius * 2

        renderer.rectangle(x + radius, y, w - radius_2, h, r, g, b, a)
        renderer.rectangle(x, y + radius, radius, h - radius_2, r, g, b, a)
        renderer.rectangle(x + w - radius, y + radius, radius, h - radius_2, r, g, b, a)

        renderer.circle(x + radius, y + radius, r, g, b, a, radius, 180, 0.25)
        renderer.circle(x + radius, y + h - radius, r, g, b, a, radius, 270, 0.25)
        renderer.circle(x + w - radius, y + radius, r, g, b, a, radius, 90, 0.25)
        renderer.circle(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25)
    end

    utils.rectangle_outline = function(x, y, w, h, r, g, b, a)
        renderer.line(x, y, x + w, y, r, g, b, a)  -- Верхняя линия
        renderer.line(x + w, y, x + w, y + h, r, g, b, a)  -- Правая линия
        renderer.line(x + w, y + h, x, y + h, r, g, b, a)  -- Нижняя линия
        renderer.line(x, y + h, x, y, r, g, b, a)  -- Левая линия
    end
end

local db do
    db = {}
    local key = 'Regicide::db'
    db.db = database.read(key)

    db.save = function()
        database.write(key, db.db)
            client.delay_call(0, function()
            database.flush()
        end)
    end

    do
        if not db.db then
            db.db = {
                configs = {
                    ['Local'] = {},
                }
            }
        end

        if not db.db.last then
            db.db.last = {
                on = false,
                cfg = nil
            }
        end

        if not db.db.data then
            db.db.data = {
                time = 0,
                loaded = 1,
                killed = 0,
            }
        end 
        db.db.data.loaded = db.db.data.loaded + 1
        db.db.data.killed = db.db.data.killed or 0

        db.loaded = globals.realtime()
        client.set_event_callback('aim_hit', function(e)
            local health = entity.get_prop(e.target, 'm_iHealth')
            if health <= 0 then
                db.db.data.killed = db.db.data.killed + 1
            end
        end)

        local saving = function() end
        saving = function()
            db.db.data.time = db.db.data.time + (globals.realtime() - db.loaded)
            db.save()
            client.delay_call(300, saving)
        end saving()

        defer(function()
            db.db.data.time = db.db.data.time + (globals.realtime() - db.loaded)
            db.save()
        end)
        
    end
    db.icons = {"f1pp", "Cat 1", "Cat 2", "Dog", "Clown"}
    
    local default_cfg = 'eyJBbnRpYWltcyI6eyJidWlsZGVyIjp7IkNyb3VjaCI6eyJib2R5Ijp7InNpZGUiOjAsInlhdyI6IkppdHRlciIsImRlbGF5Ijp7InJpZ2h0IjoxLCJsZWZ0IjoxLCJkZWxheSI6MywibW9kZSI6IlN0YXRpYyIsInN3aXRjaCI6MH19LCJlbmFibGVkIjp0cnVlLCJqaXR0ZXIiOnsidmFsdWUyIjoxMywidmFsdWUiOjAsInR5cGUiOiJPZmZzZXQiLCJ3YXlzIjpbMCwwLDAsMCwwXSwibW9kZSI6IlNwaW4iLCJyYW5kIjo0fSwieWF3Ijp7ImJhc2UiOiJBdCB0YXJnZXRzIiwibGVmdCI6LTI2LCJnbG9iYWwiOjAsInJpZ2h0Ijo0OX0sImRlZmVuc2l2ZSI6eyJmb3JjZSI6dHJ1ZSwiZW5hYmxlZCI6dHJ1ZSwib3ZlcnJpZGUiOnRydWUsInNldHRpbmdzIjp7InBpdGNoX3NwZWVkIjoxMCwicGl0Y2hfdmFsIjotMjEsInBpdGNoIjoiQ3VzdG9tIiwiZGlzYWJsZXJzIjpbIn4iXSwieWF3X3ZhbCI6MCwieWF3X3NwZWVkIjoxMCwieWF3IjoiU3BpbiIsImR1cmF0aW9uIjoxM319fSwiQ3JvdWNoaW5nIEFpciI6eyJib2R5Ijp7InNpZGUiOjAsInlhdyI6IkppdHRlciIsImRlbGF5Ijp7InJpZ2h0IjoxLCJsZWZ0Ijo0LCJkZWxheSI6MSwibW9kZSI6IlN3aXRjaCIsInN3aXRjaCI6NH19LCJlbmFibGVkIjp0cnVlLCJqaXR0ZXIiOnsidmFsdWUyIjozLCJ2YWx1ZSI6LTE1LCJ0eXBlIjoiT2Zmc2V0Iiwid2F5cyI6WzAsMCwwLDAsMF0sIm1vZGUiOiJTcGluIiwicmFuZCI6NX0sInlhdyI6eyJiYXNlIjoiQXQgdGFyZ2V0cyIsImxlZnQiOi0xNywiZ2xvYmFsIjowLCJyaWdodCI6NDN9LCJkZWZlbnNpdmUiOnsiZm9yY2UiOnRydWUsImVuYWJsZWQiOnRydWUsIm92ZXJyaWRlIjp0cnVlLCJzZXR0aW5ncyI6eyJwaXRjaF9zcGVlZCI6MTAsInBpdGNoX3ZhbCI6MTMsInBpdGNoIjoiQ3VzdG9tIiwiZGlzYWJsZXJzIjpbIn4iXSwieWF3X3ZhbCI6MCwieWF3X3NwZWVkIjoxMCwieWF3IjoiUHJvZ3Jlc3NpdmUiLCJkdXJhdGlvbiI6MTF9fX0sIkNyb3VjaCBNb3ZlIjp7ImJvZHkiOnsic2lkZSI6MCwieWF3IjoiSml0dGVyIiwiZGVsYXkiOnsicmlnaHQiOjMsImxlZnQiOjIsImRlbGF5IjoyLCJtb2RlIjoiU3dpdGNoIiwic3dpdGNoIjozfX0sImVuYWJsZWQiOnRydWUsImppdHRlciI6eyJ2YWx1ZTIiOjAsInZhbHVlIjotMTUsInR5cGUiOiJSYW5kb20iLCJ3YXlzIjpbMCwwLDAsMCwwXSwibW9kZSI6IlNwaW4iLCJyYW5kIjo1fSwieWF3Ijp7ImJhc2UiOiJBdCB0YXJnZXRzIiwibGVmdCI6LTI0LCJnbG9iYWwiOjAsInJpZ2h0IjozOH0sImRlZmVuc2l2ZSI6eyJmb3JjZSI6dHJ1ZSwiZW5hYmxlZCI6dHJ1ZSwib3ZlcnJpZGUiOnRydWUsInNldHRpbmdzIjp7InBpdGNoX3NwZWVkIjoxMCwicGl0Y2hfdmFsIjotMzUsInBpdGNoIjoiQ3VzdG9tIiwiZGlzYWJsZXJzIjpbIn4iXSwieWF3X3ZhbCI6MCwieWF3X3NwZWVkIjoxMCwieWF3IjoiWWF3IE9wcG9zaXRlIiwiZHVyYXRpb24iOjExfX19LCJTbG93d2Fsa2luZyI6eyJib2R5Ijp7InNpZGUiOjAsInlhdyI6IkppdHRlciIsImRlbGF5Ijp7InJpZ2h0IjoxLCJsZWZ0Ijo1LCJkZWxheSI6MSwibW9kZSI6IlN3aXRjaCIsInN3aXRjaCI6NH19LCJlbmFibGVkIjp0cnVlLCJqaXR0ZXIiOnsidmFsdWUyIjoxNSwidmFsdWUiOjAsInR5cGUiOiJPZmZzZXQiLCJ3YXlzIjpbMCwwLDAsMCwwXSwibW9kZSI6IlNwaW4iLCJyYW5kIjoxMH0sInlhdyI6eyJiYXNlIjoiQXQgdGFyZ2V0cyIsImxlZnQiOjE5LCJnbG9iYWwiOjAsInJpZ2h0IjotMX0sImRlZmVuc2l2ZSI6eyJmb3JjZSI6dHJ1ZSwiZW5hYmxlZCI6dHJ1ZSwib3ZlcnJpZGUiOnRydWUsInNldHRpbmdzIjp7InBpdGNoX3NwZWVkIjoxNywicGl0Y2hfdmFsIjowLCJwaXRjaCI6IlByb2dyZXNzaXZlIiwiZGlzYWJsZXJzIjpbIn4iXSwieWF3X3ZhbCI6MCwieWF3X3NwZWVkIjoyNCwieWF3IjoiUHJvZ3Jlc3NpdmUiLCJkdXJhdGlvbiI6MTF9fX0sIkZha2UgTGFnIjp7ImJvZHkiOnsic2lkZSI6MCwieWF3IjoiT3Bwb3NpdGUiLCJkZWxheSI6eyJyaWdodCI6MSwibGVmdCI6MSwiZGVsYXkiOjEsIm1vZGUiOiJTdGF0aWMiLCJzd2l0Y2giOjB9fSwiaml0dGVyIjp7InZhbHVlMiI6MjIsInZhbHVlIjotMjIsInR5cGUiOiJPZmZzZXQiLCJ3YXlzIjpbMCwwLDAsMCwwXSwibW9kZSI6IlNwaW4iLCJyYW5kIjo2fSwieWF3Ijp7ImJhc2UiOiJBdCB0YXJnZXRzIiwibGVmdCI6MCwiZ2xvYmFsIjowLCJyaWdodCI6MH0sImVuYWJsZWQiOnRydWV9LCJKdW1waW5nIjp7ImJvZHkiOnsic2lkZSI6MCwieWF3IjoiSml0dGVyIiwiZGVsYXkiOnsicmlnaHQiOjMsImxlZnQiOjIsImRlbGF5IjozLCJtb2RlIjoiU3dpdGNoIiwic3dpdGNoIjozfX0sImVuYWJsZWQiOnRydWUsImppdHRlciI6eyJ2YWx1ZTIiOjEyLCJ2YWx1ZSI6LTEsInR5cGUiOiJPZmZzZXQiLCJ3YXlzIjpbMCwwLDAsMCwwXSwibW9kZSI6IlNwaW4iLCJyYW5kIjo3fSwieWF3Ijp7ImJhc2UiOiJBdCB0YXJnZXRzIiwibGVmdCI6LTI5LCJnbG9iYWwiOjAsInJpZ2h0Ijo0OX0sImRlZmVuc2l2ZSI6eyJmb3JjZSI6dHJ1ZSwiZW5hYmxlZCI6dHJ1ZSwib3ZlcnJpZGUiOnRydWUsInNldHRpbmdzIjp7InBpdGNoX3NwZWVkIjoxMCwicGl0Y2hfdmFsIjowLCJwaXRjaCI6Ik5vbmUiLCJkaXNhYmxlcnMiOlsifiJdLCJ5YXdfdmFsIjowLCJ5YXdfc3BlZWQiOjEwLCJ5YXciOiJTcGluIiwiZHVyYXRpb24iOjEwfX19LCJEZWZhdWx0Ijp7ImRlZmVuc2l2ZSI6eyJlbmFibGVkIjpmYWxzZSwiZm9yY2UiOmZhbHNlLCJzZXR0aW5ncyI6eyJwaXRjaF9zcGVlZCI6MTAsInBpdGNoX3ZhbCI6MCwicGl0Y2giOiJOb25lIiwiZGlzYWJsZXJzIjpbIn4iXSwieWF3X3ZhbCI6MCwieWF3X3NwZWVkIjoxMCwieWF3IjoiTm9uZSIsImR1cmF0aW9uIjoxM319LCJib2R5Ijp7InNpZGUiOjAsInlhdyI6Ik9mZiIsImRlbGF5Ijp7InJpZ2h0IjoxLCJsZWZ0IjoxLCJkZWxheSI6MSwibW9kZSI6IlN0YXRpYyIsInN3aXRjaCI6MH19LCJ5YXciOnsiYmFzZSI6IkF0IHRhcmdldHMiLCJsZWZ0IjowLCJnbG9iYWwiOjAsInJpZ2h0IjowfSwiaml0dGVyIjp7InZhbHVlMiI6MCwidmFsdWUiOjAsInR5cGUiOiJPZmYiLCJ3YXlzIjpbMCwwLDAsMCwwXSwibW9kZSI6IlN0YXRpYyIsInJhbmQiOjB9fSwiU2FmZSBIZWFkIjp7ImRlZmVuc2l2ZSI6eyJmb3JjZSI6dHJ1ZSwiZW5hYmxlZCI6dHJ1ZSwib3ZlcnJpZGUiOnRydWUsInNldHRpbmdzIjp7InBpdGNoX3NwZWVkIjoxMCwicGl0Y2hfdmFsIjowLCJwaXRjaCI6IkN1c3RvbSIsImRpc2FibGVycyI6WyJ+Il0sInlhd192YWwiOjAsInlhd19zcGVlZCI6MTAsInlhdyI6IlByb2dyZXNzaXZlIiwiZHVyYXRpb24iOjEzfX0sInlhdyI6eyJiYXNlIjoiQXQgdGFyZ2V0cyIsImxlZnQiOjAsImdsb2JhbCI6MCwicmlnaHQiOjB9LCJqaXR0ZXIiOnsidmFsdWUyIjozLCJ2YWx1ZSI6LTMsInR5cGUiOiJPZmZzZXQiLCJ3YXlzIjpbMCwwLDAsMCwwXSwibW9kZSI6IlNwaW4iLCJyYW5kIjo0fSwiY29uZGl0aW9ucyI6WyJKdW1waW5nIiwiQ3JvdWNoaW5nIEFpciIsIn4iXSwiYm9keSI6eyJzaWRlIjowLCJ5YXciOiJPcHBvc2l0ZSIsImRlbGF5Ijp7InJpZ2h0IjoxLCJsZWZ0IjoxLCJkZWxheSI6MSwibW9kZSI6IlN0YXRpYyIsInN3aXRjaCI6MH19LCJ3ZWFwb25zIjpbIktuaWZlIiwiWmV1cyIsIn4iXSwiZW5hYmxlZCI6dHJ1ZX0sIk1hbnVhbCB5YXciOnsiZGVmZW5zaXZlIjp7ImZvcmNlIjp0cnVlLCJlbmFibGVkIjp0cnVlLCJvdmVycmlkZSI6dHJ1ZSwic2V0dGluZ3MiOnsicGl0Y2hfc3BlZWQiOjEwLCJwaXRjaF92YWwiOjAsInBpdGNoIjoiQ3VzdG9tIiwiZGlzYWJsZXJzIjpbIn4iXSwieWF3X3ZhbCI6MCwieWF3X3NwZWVkIjoxMCwieWF3IjoiWWF3IE9wcG9zaXRlIiwiZHVyYXRpb24iOjEzfX0sImJvZHkiOnsic2lkZSI6MCwieWF3IjoiT2ZmIiwiZGVsYXkiOnsicmlnaHQiOjEsImxlZnQiOjEsImRlbGF5IjoxLCJtb2RlIjoiU3RhdGljIiwic3dpdGNoIjowfX0sInlhdyI6eyJiYXNlIjoiTG9jYWwgdmlldyJ9LCJqaXR0ZXIiOnsidmFsdWUyIjowLCJ2YWx1ZSI6MCwidHlwZSI6Ik9mZiIsIndheXMiOlswLDAsMCwwLDBdLCJtb2RlIjoiU3RhdGljIiwicmFuZCI6MH19LCJSdW5uaW5nIjp7ImJvZHkiOnsic2lkZSI6MCwieWF3IjoiSml0dGVyIiwiZGVsYXkiOnsicmlnaHQiOjEsImxlZnQiOjQsImRlbGF5IjoxLCJtb2RlIjoiU3dpdGNoIiwic3dpdGNoIjozfX0sImVuYWJsZWQiOnRydWUsImppdHRlciI6eyJ2YWx1ZTIiOjI1LCJ2YWx1ZSI6MCwidHlwZSI6IlJhbmRvbSIsIndheXMiOlswLDAsMCwwLDBdLCJtb2RlIjoiU3BpbiIsInJhbmQiOjV9LCJ5YXciOnsiYmFzZSI6IkF0IHRhcmdldHMiLCJsZWZ0Ijo4LCJnbG9iYWwiOjAsInJpZ2h0IjotMX0sImRlZmVuc2l2ZSI6eyJmb3JjZSI6ZmFsc2UsImVuYWJsZWQiOnRydWUsIm92ZXJyaWRlIjp0cnVlLCJzZXR0aW5ncyI6eyJwaXRjaF9zcGVlZCI6MTAsInBpdGNoX3ZhbCI6NDUsInBpdGNoIjoiQ3VzdG9tIiwiZGlzYWJsZXJzIjpbIn4iXSwieWF3X3ZhbCI6MCwieWF3X3NwZWVkIjoxMCwieWF3IjoiU2lkZXdheXMiLCJkdXJhdGlvbiI6MTB9fX0sIlN0YW5kaW5nIjp7ImJvZHkiOnsic2lkZSI6MCwieWF3IjoiSml0dGVyIiwiZGVsYXkiOnsicmlnaHQiOjEsImxlZnQiOjQsImRlbGF5IjoyLCJtb2RlIjoiU3dpdGNoIiwic3dpdGNoIjozfX0sImVuYWJsZWQiOnRydWUsImppdHRlciI6eyJ2YWx1ZTIiOjAsInZhbHVlIjowLCJ0eXBlIjoiT2ZmIiwid2F5cyI6WzAsMCwwLDAsMF0sIm1vZGUiOiJTdGF0aWMiLCJyYW5kIjowfSwieWF3Ijp7ImJhc2UiOiJBdCB0YXJnZXRzIiwibGVmdCI6LTE1LCJnbG9iYWwiOjAsInJpZ2h0Ijo0Mn0sImRlZmVuc2l2ZSI6eyJmb3JjZSI6ZmFsc2UsImVuYWJsZWQiOnRydWUsIm92ZXJyaWRlIjp0cnVlLCJzZXR0aW5ncyI6eyJwaXRjaF9zcGVlZCI6MTAsInBpdGNoX3ZhbCI6MCwicGl0Y2giOiJOb25lIiwiZGlzYWJsZXJzIjpbIn4iXSwieWF3X3ZhbCI6MCwieWF3X3NwZWVkIjoxMCwieWF3IjoiUHJvZ3Jlc3NpdmUiLCJkdXJhdGlvbiI6N319fX0sIm90aGVyMiI6eyJmbGljayI6dHJ1ZSwiZmxpY2tfaCI6WzEsMCwifiJdLCJmbGlja19hYSI6eyJwaXRjaF9zcGVlZCI6MTAsInBpdGNoX3ZhbCI6LTQ1LCJwaXRjaCI6IkN1c3RvbSIsImRpc2FibGVycyI6WyJ+Il0sInlhd192YWwiOjAsInlhdyI6IlByb2dyZXNzaXZlIiwieWF3X3NwZWVkIjoxMH0sImRlZmVuc2l2ZSI6ZmFsc2V9LCJob3RrZXlzIjp7InJpZ2h0IjpbMiwwLCJ+Il0sImxlZnQiOlsyLDAsIn4iXSwiZWRnZSI6WzEsMCwifiJdLCJmb3J3YXJkIjpbMiwwLCJ+Il0sImZzIjpbMSwwLCJ+Il0sImZzX2Rpc2FibGVycyI6WyJ+Il19LCJvdGhlciI6eyJhdm9pZF9iYWNrc3RhYiI6dHJ1ZSwiZmxfZGlzYWJsZXIiOlsiTm90IG1vdmluZyIsIn4iXSwibGFkZGVyIjp0cnVlfX0sIkZlYXR1cmVzIjp7ImNvbG9yIjp7InByZWRpY3Rpb24gZXJyb3JfYyI6IiNGRjdEN0RGRiIsImhpdF9jIjoiI0I0RTYxRUZGIiwidW5wcmVkaWN0ZWQgb2NjYXNpb25fYyI6IiNGRjdEN0RGRiIsImRlYXRoX2MiOiIjNjQ2NEZGRkYiLCJzcHJlYWRfYyI6IiNGRkM4MDBGRiIsIj9fYyI6IiNGRjAwMDBGRiJ9LCJ2aWV3bW9kZWwiOnsic2NvcGUiOmZhbHNlLCJmb3YiOjYwLCJ5IjoxMCwieiI6LTEwLCJvbiI6ZmFsc2UsIngiOjEwfSwiYXNwZWN0Ijp7InJhdGlvIjo1OSwib24iOmZhbHNlfSwibWFya2VyIjp7InNpemUiOjUsImV4dHJhIjp0cnVlLCJ0aW1lIjozMCwic3R5bGUiOiJTdHlsZTogQ3Jvc3MiLCJvbiI6dHJ1ZX0sIndhdGVybWFyayI6eyJjdXN0b20iOiIiLCJsb2NrIjoiQm90dG9tLUNlbnRlciIsImNvbG9yIjp7IkJhY2tncm91bmQiOnsicGlja2VyIjoiI0FGQUZGRkI5IiwicHJlc2V0IjoiQmFja2dyb3VuZDogRGVmYXVsdCJ9LCJUZXh0Ijp7InBpY2tlciI6IiNBRkFGRkZCOSIsInByZXNldCI6IlRleHQ6IERlZmF1bHQifX0sImVsZW1lbnRzIjpbIk5pY2tuYW1lIiwiRlBTIiwiUGluZyIsIlRpbWUiLCJ+Il0sIm9uIjp0cnVlLCJ1c2VkIjp0cnVlfSwidHJhY2VyIjp7InRpbWUiOjIwLCJvbiI6dHJ1ZSwiY29sb3IiOnsiQ29sb3IiOnsicGlja2VyIjoiI0ZGRkZGRkM4IiwicHJlc2V0IjoiQ29sb3I6IERlZmF1bHQifX19LCJjb25zb2xlIjp7Im9uIjp0cnVlfSwiaGVscGVyIjp7ImNvbG9yIjp7IkNvbG9yIjp7InBpY2tlciI6IiNGRkZGRkY0QiIsInByZXNldCI6IkNvbG9yOiBEZWZhdWx0In19LCJvbiI6dHJ1ZSwidGhpcmQiOiJUaGlyZHBlcnNvbjogTG9jYWwgUGxheWVyIiwiZmlyc3QiOiJGaXJzdHBlcnNvbjogQ3Jvc3NoYWlyIn0sImFuaW1hdGlvbnMiOnsiZXh0cmEiOlsiTGFuZGluZyBQaXRjaCIsIn4iXSwib24iOnRydWUsImFpciI6IlN0YXRpYyIsImdyb3VuZCI6IkppdHRlciJ9LCJzaGFyZWQiOnsib24iOmZhbHNlLCJib3giOjB9LCJjcm9zc2hhaXIiOnsic2V0dGluZ3MiOnsiRG91YmxlIFRhcCI6eyJvbiI6dHJ1ZSwiY29udGFpbmVyIjp7Im5hbWUiOiIiLCJjb2xvciI6eyJEb3VibGUgVGFwIjp7InBpY2tlciI6IiNGRkZGRkZGRiIsInByZXNldCI6IkRvdWJsZSBUYXA6IERlZmF1bHQifX19fSwiUmlubmVnYW4iOnsib24iOnRydWUsImNvbnRhaW5lciI6eyJuYW1lIjoiIiwiY29sb3IiOnsiUmlubmVnYW4iOnsicGlja2VyIjoiI0ZGRkZGRkZGIiwicHJlc2V0IjoiUmlubmVnYW46IERlZmF1bHQifSwiQWJ5c3MiOnsicGlja2VyIjoiI0ZGRkZGRkZGIiwicHJlc2V0IjoiQWJ5c3M6IERlZmF1bHQifX19fSwiQ29uZGl0aW9ucyI6eyJvbiI6dHJ1ZSwiY29udGFpbmVyIjp7Im5hbWUiOiIiLCJjb2xvciI6eyJDb25kaXRpb25zIjp7InBpY2tlciI6IiNCOUI5RkZGRiIsInByZXNldCI6IkNvbmRpdGlvbnM6IERlZmF1bHQifX19fSwiSGlkZSBTaG90cyI6eyJvbiI6dHJ1ZSwiY29udGFpbmVyIjp7Im5hbWUiOiIiLCJjb2xvciI6eyJIaWRlIFNob3RzIjp7InBpY2tlciI6IiNGRkZGRkZGRiIsInByZXNldCI6IkhpZGUgU2hvdHM6IERlZmF1bHQifX19fSwiUGluZyBTcGlrZSI6eyJvbiI6dHJ1ZSwiY29udGFpbmVyIjp7Im5hbWUiOiIiLCJjb2xvciI6eyJQaW5nIFNwaWtlIjp7InBpY2tlciI6IiNGRkZGRkZGRiIsInByZXNldCI6IlBpbmcgU3Bpa2U6IERlZmF1bHQifX19fSwiU2FmZSBQb2ludHMiOnsib24iOnRydWUsImNvbnRhaW5lciI6eyJuYW1lIjoiIiwiY29sb3IiOnsiU2FmZSBQb2ludHMiOnsicGlja2VyIjoiI0ZGRkZGRkZGIiwicHJlc2V0IjoiU2FmZSBQb2ludHM6IERlZmF1bHQifX19fSwiRnJlZXN0YW5kaW5nIjp7Im9uIjp0cnVlLCJjb250YWluZXIiOnsibmFtZSI6IiIsImNvbG9yIjp7IkZyZWVzdGFuZGluZyI6eyJwaWNrZXIiOiIjRkZGRkZGRkYiLCJwcmVzZXQiOiJGcmVlc3RhbmRpbmc6IERlZmF1bHQifX19fSwiQm9keSBBaW0iOnsib24iOnRydWUsImNvbnRhaW5lciI6eyJuYW1lIjoiIiwiY29sb3IiOnsiQm9keSBBaW0iOnsicGlja2VyIjoiI0ZGRkZGRkZGIiwicHJlc2V0IjoiQm9keSBBaW06IERlZmF1bHQifX19fSwiRmxpY2tpbmciOnsib24iOnRydWUsImNvbnRhaW5lciI6eyJuYW1lIjoiIiwiY29sb3IiOnsiRmxpY2tpbmciOnsicGlja2VyIjoiI0ZGRkZGRkZGIiwicHJlc2V0IjoiRmxpY2tpbmc6IERlZmF1bHQifX19fSwiTWluLiBEYW1hZ2UiOnsib24iOnRydWUsImNvbnRhaW5lciI6eyJuYW1lIjoiIiwiY29sb3IiOnsiTWluLiBEYW1hZ2UiOnsicGlja2VyIjoiI0ZGRkZGRkZGIiwicHJlc2V0IjoiTWluLiBEYW1hZ2U6IERlZmF1bHQifX19fSwiSGl0Y2hhbmNlIjp7Im9uIjp0cnVlLCJjb250YWluZXIiOnsibmFtZSI6IiIsImNvbG9yIjp7IkhpdGNoYW5jZSI6eyJwaWNrZXIiOiIjRkZGRkZGRkYiLCJwcmVzZXQiOiJIaXRjaGFuY2U6IERlZmF1bHQifX19fX0sImJveCI6MCwib24iOnRydWUsInVzZWQiOnRydWV9LCJjbGFudGFnIjp7Im9uIjp0cnVlfSwicXVha2UiOnsidm9sdW1lIjo1MCwiaW1hZ2UiOmZhbHNlLCJvbiI6ZmFsc2V9LCJtYW51YWwiOnsib24iOnRydWUsImNvbG9yIjp7IkNvbG9yIjp7InBpY2tlciI6IiNGRkZGRkZDOCIsInByZXNldCI6IkNvbG9yOiBEZWZhdWx0In19fSwic2NvcGUiOnsiY29sb3IiOnsiQ29sb3IiOnsicGlja2VyIjoiI0ZGRkZGRkM4IiwicHJlc2V0IjoiQ29sb3I6IERlZmF1bHQifX0sImdhcCI6MTAsImRhbGJhZWIyIjpmYWxzZSwic3R5bGUiOiJTdHlsZTogUGx1cyIsImxlbmd0aCI6NTAsIm9uIjp0cnVlLCJkYWxiYWViIjowfSwidHJhc2h0YWxrIjp7ImV2ZW50IjpbIk9uIEtpbGwiLCJPbiBEZWF0aCIsIn4iXSwib24iOnRydWUsInVzZWQiOmZhbHNlfSwiaGl0Y2hhbmNlIjp7ImJveCI6MCwib24iOmZhbHNlLCJzZXR0aW5ncyI6eyJNYWNoaW5lIGd1biI6eyJzY29wZSI6eyJvbiI6ZmFsc2UsImhpdGNoYW5jZSI6NTB9LCJidXR0b24iOnsiaG90a2V5IjpbMSwwLCJ+Il0sIm9uIjpmYWxzZSwiaGl0Y2hhbmNlIjo1MH0sImFpciI6eyJvbiI6ZmFsc2UsImhpdGNoYW5jZSI6NTB9fSwiQXV0b3NuaXBlcnMiOnsic2NvcGUiOnsib24iOmZhbHNlLCJoaXRjaGFuY2UiOjUwfSwiYnV0dG9uIjp7ImhvdGtleSI6WzEsMCwifiJdLCJvbiI6ZmFsc2UsImhpdGNoYW5jZSI6NTB9LCJhaXIiOnsib24iOmZhbHNlLCJoaXRjaGFuY2UiOjUwfX0sIlNNRyI6eyJzY29wZSI6eyJvbiI6ZmFsc2UsImhpdGNoYW5jZSI6NTB9LCJidXR0b24iOnsiaG90a2V5IjpbMSwwLCJ+Il0sIm9uIjpmYWxzZSwiaGl0Y2hhbmNlIjo1MH0sImFpciI6eyJvbiI6ZmFsc2UsImhpdGNoYW5jZSI6NTB9fSwiU1NHIDA4Ijp7InNjb3BlIjp7Im9uIjpmYWxzZSwiaGl0Y2hhbmNlIjo1MH0sImJ1dHRvbiI6eyJob3RrZXkiOlsxLDAsIn4iXSwib24iOmZhbHNlLCJoaXRjaGFuY2UiOjUwfSwiYWlyIjp7Im9uIjpmYWxzZSwiaGl0Y2hhbmNlIjo1MH19LCJEZXNlcnQgRWFnbGUiOnsic2NvcGUiOnsib24iOmZhbHNlLCJoaXRjaGFuY2UiOjUwfSwiYnV0dG9uIjp7ImhvdGtleSI6WzEsMCwifiJdLCJvbiI6ZmFsc2UsImhpdGNoYW5jZSI6NTB9LCJhaXIiOnsib24iOmZhbHNlLCJoaXRjaGFuY2UiOjUwfX0sIlJpZmxlIjp7InNjb3BlIjp7Im9uIjpmYWxzZSwiaGl0Y2hhbmNlIjo1MH0sImJ1dHRvbiI6eyJob3RrZXkiOlsxLDAsIn4iXSwib24iOmZhbHNlLCJoaXRjaGFuY2UiOjUwfSwiYWlyIjp7Im9uIjpmYWxzZSwiaGl0Y2hhbmNlIjo1MH19LCJHbG9iYWwiOnsic2NvcGUiOnsib24iOmZhbHNlLCJoaXRjaGFuY2UiOjUwfSwiYnV0dG9uIjp7ImhvdGtleSI6WzEsMCwifiJdLCJvbiI6ZmFsc2UsImhpdGNoYW5jZSI6NTB9LCJhaXIiOnsib24iOmZhbHNlLCJoaXRjaGFuY2UiOjUwfX0sIlpldXMiOnsic2NvcGUiOnsib24iOmZhbHNlLCJoaXRjaGFuY2UiOjUwfSwiYnV0dG9uIjp7ImhvdGtleSI6WzEsMCwifiJdLCJvbiI6ZmFsc2UsImhpdGNoYW5jZSI6NTB9LCJhaXIiOnsib24iOmZhbHNlLCJoaXRjaGFuY2UiOjUwfX0sIlI4IFJldm9sdmVyIjp7InNjb3BlIjp7Im9uIjpmYWxzZSwiaGl0Y2hhbmNlIjo1MH0sImJ1dHRvbiI6eyJob3RrZXkiOlsxLDAsIn4iXSwib24iOmZhbHNlLCJoaXRjaGFuY2UiOjUwfSwiYWlyIjp7Im9uIjpmYWxzZSwiaGl0Y2hhbmNlIjo1MH19LCJQaXN0b2wiOnsic2NvcGUiOnsib24iOmZhbHNlLCJoaXRjaGFuY2UiOjUwfSwiYnV0dG9uIjp7ImhvdGtleSI6WzEsMCwifiJdLCJvbiI6ZmFsc2UsImhpdGNoYW5jZSI6NTB9LCJhaXIiOnsib24iOmZhbHNlLCJoaXRjaGFuY2UiOjUwfX0sIkFXUCI6eyJzY29wZSI6eyJvbiI6ZmFsc2UsImhpdGNoYW5jZSI6NTB9LCJidXR0b24iOnsiaG90a2V5IjpbMSwwLCJ+Il0sIm9uIjpmYWxzZSwiaGl0Y2hhbmNlIjo1MH0sImFpciI6eyJvbiI6ZmFsc2UsImhpdGNoYW5jZSI6NTB9fSwiU2hvdGd1biI6eyJzY29wZSI6eyJvbiI6ZmFsc2UsImhpdGNoYW5jZSI6NTB9LCJidXR0b24iOnsiaG90a2V5IjpbMSwwLCJ+Il0sIm9uIjpmYWxzZSwiaGl0Y2hhbmNlIjo1MH0sImFpciI6eyJvbiI6ZmFsc2UsImhpdGNoYW5jZSI6NTB9fX19LCJkYW1hZ2UiOnsiYW5pbWF0aW9uIjoiQW5pbWF0aW9uOiBJbnN0YW50IiwiY29sb3IiOnsiQ29sb3IiOnsicGlja2VyIjoiI0ZGRkZGRkM4IiwicHJlc2V0IjoiQ29sb3I6IERlZmF1bHQifX0sImZvbnQiOiJGb250OiBEZWZhdWx0Iiwib24iOnRydWUsImRpc3BsYXkiOiJEaXNwbGF5OiBBbHdheXMgT24iLCJkcmFnIjp7InkiOjUwMCwieCI6NTAwfX0sImxvZ3MiOnsiY29sb3IiOnsiQmFja2dyb3VuZCI6eyJwaWNrZXIiOiIjMDAwMDAwNjQiLCJwcmVzZXQiOiJCYWNrZ3JvdW5kOiBEZWZhdWx0In19LCJvbiI6dHJ1ZSwidGltZSI6MzAsImRpc3BsYXkiOlsiT24gU2NyZWVuIiwiSW4gQ29uc29sZSIsIn4iXSwidXNlZCI6dHJ1ZX0sInpvb20iOnsic2Vjb25kIjo1MCwidGhpcmQiOjMwLCJtb2RlIjoiTW9kZTogU2luZ2xlIiwic3RhY2siOmZhbHNlLCJidXR0b24iOlsxLDAsIn4iXSwib24iOmZhbHNlLCJmaXJzdCI6MzB9fX0='

    db.db.configs['Local'][1] = {"Default", default_cfg}
    db.configs = {"Default"}

end

local gradient do
    gradient = {}
    gradient.animated_gradient_text = function(text, colors, speed, a)
        local output = ""
        local length = #text
        local time_offset = (utils.normalize_yaw(globals.realtime() * speed, 1, 3) * speed) % 1
    
        for i = 1, length do
            -- Если символ '·', присваиваем ему фиксированный цвет
            if text:sub(i, i) == "·" then
                output = output .. string.format("\a%02x%02x%02x%02x", 185, 185, 255, 255) .. text:sub(i, i)
            else
                -- Иначе применяем градиентный цвет
                local t = ((i - 1) / (length - 1) + time_offset) % 1
                local color = color.linear_gradient(colors, t)
                color:alpha_modulate(utils.sine_yaw(globals.framecount() / i % 3 * (0.92 - i % 5), 0, 255))
                output = output .. string.format("\a%02x%02x%02x%02x", color.r, color.g, color.b, color.a * a) .. text:sub(i, i)
            end
        end
    
        return output
    end
    
    
    gradient.randomize_colors = function(count)
        local randomized_colors = {}
    
        -- Устанавливаем шаг для плавного изменения t от 0 до 1
        local step = 1 / (count - 1)
    
        for i = 1, count do
            -- Рандомные значения для цвета (r, g, b, a) в допустимых диапазонах
            local r = math.random(150, 240)
            local g = math.random(150, 200)
            local b = math.random(250, 255)
            local a = math.random(100, 255)
    
            -- t увеличивается от 0 до 1
            local t = (i - 1) * step
    
            -- Добавляем цвет в таблицу
            table.insert(randomized_colors, { color(r, g, b, a), t })
        end
    
        return randomized_colors
    end
    -- Генерация случайных 10 цветов
    gradient.table = gradient.randomize_colors(100)
end

local drag do
    local is_menu_visible = false
    local is_mouse_held_before_hover = false
    local mouse = vector()

    drag = {}
    drag.windows = {}

    function drag.on_config_load()
        for _, point in pairs(drag.windows) do
            point.position = vector(point.ui_callbacks.x:get()*screen.size.x/1000, point.ui_callbacks.y:get()*screen.size.y/1000)
        end
    end

    function drag.register(position, size, global_name, ins_function, limits, outline)
        local data = {
            size = size,
            is_dragging = false,
            drag_position = vector(),
            is_mouse_held_before_hover = false, -- теперь локально для каждого элемента
            global_name = global_name,
            ins_function = ins_function,
            ui_callbacks = {x = position.x, y = position.y},
            limits = limits and {x={min=limits[1], max=limits[2]}, y={min=limits[3],max=limits[4]}} or nil,
            outline = outline == nil and true or outline
        }
        data.position = vector(data.ui_callbacks.x.value/1000*screen.size.x - data.size.x/2, data.ui_callbacks.y.value/1000*screen.size.y - data.size.y/2)
         
        table.insert(drag.windows, data)
        return setmetatable(data, { __index = drag })
    end
    
    
    function drag:limit_positions(table)
        self.position.x = math.max(table and table.x.min or 0, math.min(self.position.x, table and table.x.max or screen.size.x - self.size.x))
        self.position.y = math.max(table and table.y.min or 0, math.min(self.position.y, table and table.y.max or screen.size.y - self.size.y))
    end
    
    function drag:is_in_area(mouse_position)
        return mouse_position.x >= self.position.x and mouse_position.x <= self.position.x + self.size.x and 
               mouse_position.y >= self.position.y and mouse_position.y <= self.position.y + self.size.y
    end
    
    function drag:update(...)
        if is_menu_visible then
            if self.outline then
                utils.rectangle_outline(self.position.x, self.position.y, self.size.x, self.size.y, 255, 255, 255, 100)
            end
            local is_in_area = self:is_in_area(mouse)
            local is_key_pressed = client.key_state(0x01)
    
            if is_in_area and client.key_state(0x02) then
                self.position.x = (screen.size.x - self.size.x) / 2
                self.ui_callbacks.x:set(math.floor(self.position.x / screen.size.x * 1000))
            end
    
            if is_key_pressed and not self.is_dragging and not is_in_area then
                self.is_mouse_held_before_hover = true
            end
    
            if (is_in_area or self.is_dragging) and is_key_pressed and not self.is_mouse_held_before_hover then
                if not self.is_dragging then
                    self.is_dragging = true
                    self.drag_position = mouse - self.position
                else
                    self.position = mouse - self.drag_position
                    self:limit_positions(self.limits)
                    self.ui_callbacks.x:set(math.floor(self.position.x/screen.size.x*1000))
                    self.ui_callbacks.y:set(math.floor(self.position.y/screen.size.y*1000))
                end
            elseif not is_key_pressed then
                self.is_dragging = false
                self.drag_position = vector()
                self.is_mouse_held_before_hover = false
            end
        end
        self.ins_function(self, ...)
    end
    
    local function block(cmd)
        cmd.in_attack = false
        cmd.in_attack2 = false
    end
    
    local function mouse_input()
        height = vector(renderer.measure_text('d', '1')).y
        is_menu_visible = ui.is_menu_open()
        if is_menu_visible then
            mouse = vector(ui.mouse_position())
            local is_key_pressed = client.key_state(0x01)
            local in_area = false
            if is_menu_visible then
                for _, window in pairs(drag.windows) do
                    if window.is_dragging or window:is_in_area(mouse) then
                        in_area = true
                        break
                    end
                end
            end
            
            if in_area then
                client.set_event_callback("setup_command", block)
            else
                client.unset_event_callback("setup_command", block)
            end

            
            if not is_key_pressed then
                is_mouse_held_before_hover = false
            end
            
            return not in_area
        end
    end
    
    client.set_event_callback("paint", mouse_input)
end 

local menu do
    menu = {}

    local hide_menu do
        hide_menu = function()
            -- for _,table in pairs(refs) do
                -- for _, ref in pairs(table) do
                for _, ref in pairs(refs.aa) do
                    ref:set_visible(false)
                end
            -- end
        end
        client.set_event_callback("paint_ui", hide_menu)
    end

    local tabs do
        tabs = {
            aa = pui.group("AA", "Anti-aimbot angles"),
            fl = pui.group("AA", "Fake lag"),
            other = pui.group("AA", "Other")
        }
    end

    local tab = tabs.fl:combobox("\vRegicide.Hit ["..version[1].."]", {"Home", "Features", "Antiaims"}, false)
    local tab_label = tabs.fl:label("\a373737FF‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾")

    local setup = tabs.aa:combobox("Setup", {
        "None", "Crosshair Indicator", "Damage Indicator", "Manual Yaw Indicator", 
        "Custom Scope", "Thirdperson Distance", "Ragebot Logs", "Shot Marker",
        "Bullet Tracer", "Damage Helper", "Resolver", "Predict", "Console Filter", "Trashtalk",
        "Watermark", "Hitchance Modifier", "Aspect Ratio", "Viewmodel",
         "Animations", "Clantag", "Stickman", "Angelic Tap", "JumpStop",
        "Velocity Warning", "Defensive indicator", "Gamesense Indicator",
        "Bomb Indicator"
    }, false)
    setup:set_visible(false)
    local disabled = {
        -- ["Stickman"] = true,
    }

    local Home = {} do
        local types = {"Local"}

        local aa do
            aa = {}

            aa.config_label = tabs.aa:label("\vConfig System")
            aa.divider = tabs.aa:label("\a373737FF‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾")
            aa.type = tabs.aa:combobox("\n", types, nil, false)
            aa.type:set_enabled(false)

            aa.box = tabs.aa:listbox("Config system", db.configs, nil, false)

            aa.selected_label = tabs.aa:label("Selected - \vDefault")
            aa.load = tabs.aa:button("Load")
            aa.loadaa = tabs.aa:button("Load AA")

            aa.save = tabs.aa:button("Save")
                :depend({aa.type, 'Local'}, {aa.box, 0, true})
            aa.export = tabs.aa:button("Export")
                :depend({aa.type, 'Local'}, {aa.box, 0, true})
            aa.delete = tabs.aa:button("\aFF0000FFDelete")
                :depend({aa.type, 'Local'}, {aa.box, 0, true})

            -- aa.type:set_callback(function(self)
            --     aa.box:invoke()
            -- end)

            Home.aa = aa
        end

        local fl do 
            local session = 0
            fl = {
                a = tabs.fl:label("\n123"),
                welcome = tabs.fl:label("Welcome back,  \v"..username[1]),
                version = tabs.fl:label("Your Build:  \v"..version[1]),
                played = tabs.fl:label("Total Playtime: \v" .. string.format(db.db.data.time < 3600 and "%.2f" or "%.0f", db.db.data.time / 3600) .. " hours"),
                session = tabs.fl:label("Current Session: \v"..session),
                loaded = tabs.fl:label("Times Loaded: \v"..db.db.data.loaded),
                killed = tabs.fl:label("Times Killed: \v"..db.db.data.killed),

                b = tabs.fl:label("\n123"),
                extion = tabs.fl:label("Feel the heat. That's \vRegicide Release"),
            }
            local update_session = function() end
            update_session = function()
                session = globals.realtime() - db.loaded
                fl.played:set("Total Playtime: \v" .. string.format(db.db.data.time < 3600 and "%.2f" or "%.0f", db.db.data.time / 3600) .. " hours")
                fl.session:set("Session time: \v"..math.floor(session)..' sec')
                fl.killed:set("Times Killed: \v"..db.db.data.killed)
                client.delay_call(1, update_session)
            end update_session()

            Home.fl = fl
        end

        local other do
            other = {
                Local = {
                    autoload = tabs.other:checkbox("Autoload last config", nil, false),
                    autoload_save = tabs.other:multiselect("Save config on", {"Load", "Save", "Shutdown"}, nil, false),
                    label_cfg_name = tabs.other:label("\vConfig Name"),
                    name = tabs.other:textbox("Config name", nil, false),
                    create = tabs.other:button("Create & Save"),
                    import = tabs.other:button("Import & Load"),
                   discord = tabs.other:button('Discord Server', function() 
                    panorama.open().SteamOverlayAPI.OpenExternalBrowserURL("https://dsc.gg/regicidelua")
                end),
                    steamgr = tabs.other:button('Steam Group', function() 
                    panorama.open().SteamOverlayAPI.OpenExternalBrowserURL("https://steamcommunity.com/groups/blixxen")
                end),
                    yt = tabs.other:button('Youtube', function() 
                    panorama.open().SteamOverlayAPI.OpenExternalBrowserURL("https://www.youtube.com/@kxanx1337")
                end)
                },
            }
            other.Local.autoload:set(db.db.last.on)
            other.Local.autoload:set_callback(function(self)
                db.db.last.on = self.value
                db.save()
            end)
            other.Local.autoload_save:set(db.db.last.save or {})
            other.Local.autoload_save:depend({other.Local.autoload, true})
            other.Local.autoload_save:set_callback(function(self)
                db.db.last.save = self.value
                db.save()
            end)

            for _, name in pairs(types) do
                for _, el in pairs(other[name]) do
                    el:depend({Home.aa.type, name})
                end
            end

            Home.other = other
        end

        menu.Home = Home
    end

    local Features = {} do
        local create = {} do
            local unique = 1
            create.element = function(tab, name)
                local el = {}

                el.disabled = tab:checkbox("Setup \aC8C8C8C8"..name, nil, false)
                el.enabled = tab:checkbox("Setup \v"..name, false, false)
                el.divider = tab:label("\a373737FF‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\n"..unique)
                el.on = tab:checkbox("Enabled\n"..name)
                el.divider2 = tab:label("\a373737FF‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\n"..unique)

                if disabled[name] then
                    el.disabled:set_enabled(false)
                    el.enabled:set_enabled(false)
                    el.on:set_enabled(false)
                end
                
                el.disabled:depend( {el.on, false} )
                el.enabled:depend( {el.on, true} )
                el.divider:depend( {setup, name} )
                el.on:depend( {setup, name} )
    
                el.disabled:set_callback(function(self)
                    el.enabled:set(self.value)
                end)
    
                el.enabled:set_callback(function(self)
                    el.disabled:set(self.value)
                    setup:set(setup.value == 'None' and name or 'None')
                end)

                client.set_event_callback('post_config_load', function()
                    el.disabled:set(false)
                end)

                unique = unique + 1
                return el
            end --todo: при использовании, обновлять таблицу в setup

            create.color = function(tab, name, default, custom)
                local el = {}
                colors[name] = colors[name] or {}
                custom = custom or {"Color"}

                for a,b in pairs(custom) do
                    el[b] = {}
                    el[b].preset = tab:combobox("\n" .. unique, {b..": Default", b..": Accent", b..": Custom"})
                    local default = color(unpack(default[a]))
                    el[b].picker = tab:color_picker('\n' .. unique, default)
                    el[b].picker:depend({el[b].preset, b..": Custom"})

                    local col = default

                    local set_color = function()
                        col = el[b].preset.value == b..": Default" and (default) or el[b].preset.value == b..": Accent" and utils.to_rgb(pui.accent) or color(unpack(el[b].picker.value))
                        colors[name][b] = col
                    end
                    el[b].picker:set_callback(set_color)
                    el[b].preset:set_callback(set_color, true)
                    refs2.color:set_callback(set_color)
                end
                unique = unique + 1
                return el
            end

            local show_sliders = false
            create.drag = function(name, default)
                local el = {}
                el.x = tabs.aa:slider('x\n'..unique, 0, 1000, default and default[1]/screen.size.x*1000 or 500)
                el.y = tabs.aa:slider('y\n'..unique, 0, 1000, default and default[2]/screen.size.y*1000 or 500) 
                el.x:depend({setup, 'drag', show_sliders})
                el.y:depend({setup, 'drag', show_sliders})
                unique = unique + 1
                return el
            end

            create.label = function(tab, name, arg1)
                local el = {}
                if arg1 ~= true then
                    el.div0 = tab:label("\n123")
                end
                el.name = tab:label("\v"..name)
                el.div1 = tab:label("\a373737FF‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾")

                for a,b in pairs(el) do
                    b:depend({setup, "None"})
                end
                return el
            end
            
        end

        Features.label1 = create.label(tabs.aa, "Visuals", true)

        local watermark = {} do
            watermark = create.element(tabs.aa, "Watermark")
            watermark.drag = create.drag("watermark", {screen.center.x, screen.size.y-100})
            watermark.on:set_enabled(false)
            watermark.on:set(true)
            watermark.candy = tabs.aa:checkbox("Candy")
            watermark.color = create.color(tabs.aa, 'watermark', { {175,175,255,185}, {0,0,0,200} },{"Text", "Background"})
            watermark.elements = tabs.aa:multiselect('\nwatermark.elements', {"Nickname", "FPS", "Ping", "Time"})
            watermark.lock = tabs.aa:combobox('\nwatermark.lock', {"Bottom-Center","Upper-Center","Upper-Right","Bottom-Right","Upper-Left","Bottom-Left", "None"})
            watermark.custom = tabs.aa:textbox("custom name watermark")
            watermark.used = tabs.aa:checkbox("Used elements?")
            watermark.used:depend({setup, 'xdadadsadadx'})
            watermark.elements:set_callback(function()
                watermark.used:set(true)
            end)
            if not watermark.used.value then
                watermark.elements:set({"Nickname", "FPS", "Ping", "Time"})
            end

            watermark.custom:depend({watermark.elements, "Nickname"})
            Features.watermark = watermark
        end

        local crosshair = {} do
            crosshair = create.element(tabs.aa, "Crosshair Indicator")
            local data = {} do
                data.always = {"Regicide.Hit", "Conditions"}
                data.elements = {"Regicide.Hit", "Conditions", "Double Tap", "Hide Shots", "Min. Damage", "Hitchance","Body Aim", "Safe Points", "Ping Spike", "Freestanding", "Flicking"}
                data.list = {table.unpack(data.elements)}
                data.names = {
                    ["Double Tap"] = "DOUBLETAP",
                    ["Hide Shots"] = "OSAA",
                    ["Min. Damage"] = "DAMAGE",
                    ["Hitchance"] = "HC",
                    ["Body Aim"] = "BAIM",
                    ["Safe Points"] = "SAFE",
                    ["Ping Spike"] = "SPIKE",
                    ["Freestanding"] = "FS",
                    ["Flicking"] = "FLICK",
                }
                data.color = {
                    ["Conditions"] = {185,185,255,255}
                }
                data.numbers = {}
                for i, name in pairs(data.elements) do
                    data.numbers[name] = i
                end

                hard['crosshair'] = data
            end

            crosshair.box = tabs.aa:listbox("\ncrosshair", data.list)
            crosshair.used = tabs.aa:checkbox("Used elements? crosshair")
            crosshair.used:depend({setup, 'xdadadsadadx'})


            local settings = {}
            for a, b in pairs(data.elements) do
                settings[b] = {}

                settings[b].on = tabs.aa:checkbox("Enabled\n"..b)
                local container = {}
                container.name = tabs.aa:textbox("Custom name"..b)
                container.color = create.color(tabs.aa, 'crosshair', a == 1 and {{255,255,255,255}, {185,185,255,255}} or { (data.color[b] or {255,255,255,255}) }, a == 1 and {b, "Version"} or {b})
                container.candy = tabs.aa:checkbox("Candy\n"..b)
                pui.traverse(container, function(element)
                    element:depend({settings[b].on, true})
                end)
                local i = 0
                settings[b].on:set_callback(function(self)
                    data.list[data.numbers[b]] = self.value and pui.format(data.elements[data.numbers[b]] ..' ~ \vEnabled') or pui.format(data.elements[data.numbers[b]] .. ' ~ \aC8C8C8C8Disabled')
                    crosshair.box:update(data.list)
                end, true)
                if data.always[data.numbers[b]] then
                    settings[b].on:set_enabled(false)
                    settings[b].on:set(true)
                    container.name:set_enabled(false)
                end

                settings[b].container = container
            end
            if not crosshair.used.value then
                pui.traverse(settings, function(element, path)
                    if path[2] == 'on' then
                        element:set(true)
                    end
                end)
            end
            pui.traverse(settings, function(element, path)
                element:depend({crosshair.box, data.numbers[path[1]] - 1})
            end)
            crosshair.settings = settings
            Features.crosshair = crosshair
        end
        
        local damage = {} do
            damage = create.element(tabs.aa, "Damage Indicator")

            damage.drag = create.drag('damage', {screen.center.x+20,screen.center.y-30})
            damage.color = create.color(tabs.aa, 'damage', {{255,255,255,200}})
            damage.font = tabs.aa:combobox("\ndamage.font", {"Font: Default", "Font: Pixel"})
            damage.display = tabs.aa:combobox("\ndamage.display", {"Display: Always On", "Display: Always On (50%)", "Display: On Hotkey"})
            damage.animation = tabs.aa:combobox("\ndamage.animation", {"Animation: Instant", "Animation: Smooth"})

            Features.damage = damage
        end

        local manual = {} do
            manual = create.element(tabs.aa, "Manual Yaw Indicator")
            manual.color = create.color(tabs.aa, 'manual', {{255,255,255,200}})

            Features.manual = manual
        end

        local gamesense = {} do
            gamesense = create.element(tabs.aa, "Gamesense Indicator")
            local data = {} do
                data.always = {['Min. Damage'] = true, ["Hit Chance"] = true}
                data.elements = {"Safe Point", "Body Aim", "Ping Spike", "Double Tap", "Fake Duck", "Freestanding", "Hide Shots", "Min. Damage", "Hit Chance"}
                data.list = {table.unpack(data.elements)}
                data.names = {
                    ["Double Tap"] = "DT",
                    ["Hide Shots"] = "OSAA",
                    ["Min. Damage"] = "DMG",
                    ["Hit Chance"] = "HC",
                    ["Body Aim"] = "BODY",
                    ["Safe Point"] = "SAFE",
                    ["Ping Spike"] = "PING",
                    ["Freestanding"] = "FS",
                    ["Fake Duck"] = "DUCK",
                }
                data.numbers = {}
                for i, name in pairs(data.elements) do
                    data.numbers[name] = i
                end

                hard['gamesense'] = data
            end
            gamesense.follow = tabs.aa:checkbox("Follow the player in thirdperson mode")
            gamesense.box = tabs.aa:listbox("\ngamesense", data.list)
            gamesense.used = tabs.aa:checkbox("Used elements? gamesense")
            gamesense.used:depend({setup, 'xdadadsadadx'})

            local settings = {}
            for a, b in pairs(data.elements) do
                settings[b] = {}

                settings[b].on = tabs.aa:checkbox("Enabled \v"..b)
                local container = {}
                container.always = data.always[b] and tabs.aa:checkbox("Always On\n"..b) or nil
                container.show = data.always[b] and tabs.aa:checkbox("Show Value\n"..b) or nil
                container.name = tabs.aa:textbox("Custom name"..b)
                container.color = create.color(tabs.aa, 'gamesense', {( b == "Ping Spike" and {150,200,25,200} or {185,185,185,255})}, {b})
                pui.traverse(container, function(element)
                    element:depend({settings[b].on, true})
                end)
                local i = 0
                settings[b].on:set_callback(function(self)
                    data.list[data.numbers[b]] = self.value and pui.format(data.elements[data.numbers[b]] ..' ~ \vEnabled') or pui.format(data.elements[data.numbers[b]] .. ' ~ \aC8C8C8C8Disabled')
                    gamesense.box:update(data.list)
                end, true)  

                settings[b].container = container
            end
            if not crosshair.used.value then
                pui.traverse(settings, function(element, path)
                    if path[2] == 'on' then
                        element:set(true)
                    end
                end)
            end
            pui.traverse(settings, function(element, path)
                element:depend({gamesense.box, data.numbers[path[1]] - 1})
            end)
            gamesense.settings = settings
            Features.gamesense = gamesense
        end

        local bomb = {} do
            bomb = create.element(tabs.aa, "Bomb Indicator")
            bomb.drag = create.drag("Bomb Indicator", {screen.center.x, screen.size.y*0.25})
            bomb.color = create.color(tabs.aa, 'bomb', {{175,175,255,255}, {220,30,50,255}}, {"Good", "Bad"})

            Features.bomb = bomb
        end

        local scope = {} do
            scope = create.element(tabs.aa, "Custom Scope")

            scope.color = create.color(tabs.aa, 'scope', {{255,255,255,200}})
            scope.style = tabs.aa:combobox("\nscope.Style", {"Style: Plus", "Style: Cross"})
            local gap,length = {},{}
            for i=0, 100 do
                gap[i] = 'Gap '..i..'px'
            end
            for i=0, 200 do
                length[i] = 'Lenght '..i..'px'
            end
            scope.gap = tabs.aa:slider("\nLines Gap", 0, 100, 10, true, "px", 1, gap)
            scope.length = tabs.aa:slider("\nLines Lenght", 0, 200, 50, true, "px", 1, length)
            scope.dalbaeb = tabs.aa:slider("dalbaeb\nLines dalbaeb", -360 , 360, 0, true, "°", 1)
            scope.dalbaeb2 = tabs.aa:checkbox("dalbaeb2\ndaun")

            scope.dalbaeb:depend({scope.style, "Style: Cross"})
            scope.dalbaeb2:depend({scope.style, "Style: Cross"})

            Features.scope = scope
        end

        local zoom = {} do
            zoom = create.element(tabs.aa, "Thirdperson Distance")
            zoom.distance = tabs.aa:slider("Thirdperson Distance", 30, 100, 58)
            zoom.div2 = tabs.aa:label("\a373737FF‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\n"..'zoom')
            zoom.mode = tabs.aa:combobox("Animated Zoom\nzoom.mode", {"Mode: Single", "Mode: Dual"})
            zoom.first = tabs.aa:slider("\nZoom Fov 1", -100, 100, 30, true, '%')
            zoom.second = tabs.aa:slider("\nZoom Fov 2", -100, 100, 50, true, '%')
            zoom.second:depend({zoom.mode, 'Mode: Dual'})
            zoom.div = tabs.aa:label("\a373737FF‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\n"..'zoom')
            -- zoom.button = tabs.aa:hotkey("Zoom on Hotkey")
            -- zoom.third = tabs.aa:slider("\nZoom Fov 1", 0, 100, 50, true, '%')
            -- zoom.stack = tabs.aa:checkbox("Stack with Scope Zoom")


            Features.zoom = zoom
        end

        local aspect = {} do
            aspect = create.element(tabs.aa, "Aspect Ratio")
            aspect.ratio = tabs.aa:slider("\naspect.ratio", 59, 250, 59, true, '', .01, {[59] = "Off"})

            Features.aspect = aspect
        end

        local viewmodel = {} do
            viewmodel = create.element(tabs.aa, "Viewmodel")
            local fov = {}
            for i=-200, 200 do
                fov[i] = i..' fov'
            end
            viewmodel.scope = tabs.aa:checkbox("Show weapon in scope")
            viewmodel.div = tabs.aa:label("\a373737FF‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\n"..'viewmodel')
            viewmodel.fov = tabs.aa:slider("\nviewmodel.fov", 0, 100, default.viewmodel.fov, true, '', 1, fov)
            viewmodel.x = tabs.aa:slider("\nviewmodel.x", -300, 300, default.viewmodel.x * 10, true, ' x', .1)
            viewmodel.y = tabs.aa:slider("\nviewmodel.y", -300, 300, default.viewmodel.y * 10, true, ' y', .1)
            viewmodel.z = tabs.aa:slider("\nviewmodel.z", -300, 300, default.viewmodel.z * 10, true, ' z', .1)
            viewmodel.reset = tabs.aa:button("Reset")
            viewmodel.reset:set_callback(function()
                for a,_ in pairs(default.viewmodel) do
                    viewmodel[a]:reset()
                end
            end)

            Features.viewmodel = viewmodel
        end

        local velocity = {} do
            velocity = create.element(tabs.aa, "Velocity Warning")
            velocity.drag = create.drag("Velocity Warning", {screen.center.x, screen.size.y*0.3})
            velocity.color = create.color(tabs.aa, 'velocity', {{175,175,255,255}, {220,30,50,255}}, {"Good", "Bad"})

            Features.velocity = velocity
        end

        local stickman = {} do
            stickman = create.element(tabs.aa, "Stickman")
            stickman.color = create.color(tabs.aa, 'stickman', {{255,255,255,200}})
            stickman.def = tabs.aa:checkbox("Only on defensive")


            Features.stickman = stickman
        end

        Features.label2 = create.label(tabs.aa, "Ragebot")


        local logs = {} do
            logs = create.element(tabs.aa, "Ragebot Logs")
            logs.display = tabs.aa:multiselect("\nlogs.display", {"On Screen", "In Console"})
            logs.color = create.color(tabs.aa, 'logs', {{0,0,0,100}}, {"Background"})
            logs.time = tabs.aa:slider("Time\nlogs.time", 5, 50, 30, true, 's', .1)
            logs.used = tabs.aa:checkbox("Used display?")
            logs.used:depend({setup, 'xdadadsadadx'})
            logs.time:depend({logs.display, 'On Screen'})
            logs.display:set_callback(function()
                logs.used:set(true)
            end)
            if not logs.used.value then
                logs.display:set({"On Screen", "In Console"})
            end

            Features.logs = logs
        end

local Predict = {} do
    Predict = create.element(tabs.aa, "Predict")

    Predict.enable = tabs.aa:checkbox("⛧ Predict System ⛧")
    Predict.hotexp = tabs.aa:hotkey("⛧Hotkey⛧")
    Predict.pingpos = tabs.aa:combobox("Ping Variations", { "High", "Low" })

    Predict.selectgun = tabs.aa:combobox("\n", { "-", "AWP", "SCOUT", "AUTO", "R8" })
    Predict.slideawp = tabs.aa:combobox("\n", { "Disabled", "Medium", "Maximum", "Extreme" })
    Predict.slidescout = tabs.aa:combobox("\n", { "Disabled", "Medium", "Maximum", "Extreme" })
    Predict.slideauto = tabs.aa:combobox("\n", { "Disabled", "Medium", "Maximum", "Extreme" })
    Predict.slider8 = tabs.aa:combobox("\n", { "Disabled", "Medium", "Maximum", "Extreme" })

    -- Зависимости
    Predict.slideawp:depend({ Predict.selectgun, "AWP" })
    Predict.slidescout:depend({ Predict.selectgun, "SCOUT" })
    Predict.slideauto:depend({ Predict.selectgun, "AUTO" })
    Predict.slider8:depend({ Predict.selectgun, "R8" })

    -- Логика скрытия без on_change
    if not Predict.enable.value then
        pui.traverse(Predict, function(e, path)
            if path[1] == 'pingpos' then e:set("High") end
        end)
    end

    Features.Predict = Predict
end


local resolver = {} do
    resolver = create.element(tabs.aa, "Resolver")

    resolver.enable = tabs.aa:checkbox("Enable Resolver")
    resolver.used = tabs.aa:checkbox("Used elements? resolver")
    resolver.used:depend({setup, 'resolver'})

    if not resolver.used.value then
        resolver.enable:set(true)
    end

    Features.resolver = resolver
end

local jumpstop = {} do
    jumpstop = create.element(tabs.aa, "JumpStop")

    jumpstop.enable = tabs.aa:checkbox('Jumpstop')
    jumpstop.hotkey = tabs.aa:hotkey('Jumpstop', true)
    jumpstop.distance = tabs.aa:slider('\nJumpStop Distance', 0, 2000, 1000, true, 'u', 1)
    jumpstop.used = tabs.aa:checkbox("Used elements? jumpstop")
    jumpstop.used:depend({setup, 'jumpstop'})

    if not jumpstop.used.value then
        jumpstop.enable:set(true)
    end

    Features.jumpstop = jumpstop
end

local mantletap = {} do
    mantletap = create.element(tabs.aa, "Angelic Tap")

    mantletap.enable = tabs.aa:checkbox("Enable Angelic Tap")
    mantletap.used = tabs.aa:checkbox("Used elements? mantletapr")
    mantletap.used:depend({setup, 'mantletap'})

    if not mantletap.used.value then
        mantletap.enable:set(true)
    end

    Features.mantletap = mantletap
end

        local marker = {} do
            marker = create.element(tabs.aa, "Shot Marker")

            marker.time = tabs.aa:slider("Time\nmarker.time", 5, 50, 30, true, 's', .1)
            marker.size = tabs.aa:slider("Size\nmarker.size", 3, 10, 5)
            marker.style = tabs.aa:combobox("\nmarker.Style", {"Style: Cross", "Style: Plus"})
            marker.extra = tabs.aa:checkbox("Show Miss Reason")

            Features.marker = marker
        end

        local color = {} do
            color.label = tabs.aa:label('\nmega label color')
            color['hit'] = tabs.aa:label('Hit color', {180, 230, 30, 255})
            color['?'] = tabs.aa:label('? color', {255, 0, 0, 255})
            color['spread'] = tabs.aa:label('Spread color', {255, 200, 0, 255})
            color['prediction error'] = tabs.aa:label('Prediction error color', {255, 125, 125, 255})
            color['unpredicted occasion'] = tabs.aa:label('Unpredicted occasion color', {255, 125, 125, 255})
            color['death'] = tabs.aa:label('Death color', {100, 100, 255, 255})
            color['unregistered shot'] = tabs.aa:label('Unregistered shot color', {100, 100, 255, 255})

            for a,b in pairs(color) do
                b:depend({setup, function()
                    return setup.value == "Ragebot Logs" or setup.value == 'Shot Marker'
                end}, {tab, 'Features'})
            end
            
            Features.color = color
        end

        local tracer = {} do
            tracer = create.element(tabs.aa, "Bullet Tracer")
            tracer.time = tabs.aa:slider("Time\ntracer.time", 5, 50, 20, true, 's', .1)
            tracer.color = create.color(tabs.aa, 'tracer', {{255,255,255,200}})

            Features.tracer = tracer
        end

        local helper = {} do
            helper = create.element(tabs.aa, "Damage Helper")
            helper.note = tabs.aa:label("\aafafff90Note: Draws line if 1-shot to stomach.")
            helper.color = create.color(tabs.aa, 'helper', {{255,255,255,75}})
            helper.label = tabs.aa:label("Lines Positions")
            helper.first = tabs.aa:combobox("\nFirstperson.helper", {"Firstperson: Crosshair", "Firstperson: Upper-Center", "Firstperson: Bottom-Center"})
            helper.third = tabs.aa:combobox("\nThirdperson.helper", {"Thirdperson: Local Player","Thirdperson: Crosshair", "Thirdperson: Upper-Center", "Thirdperson: Bottom-Center"})


            Features.helper = helper
        end

        local hitchance = {} do
            hitchance = create.element(tabs.aa, "Hitchance Modifier")
            local disabled = ('\aC8C8C8C8'..'off ')
            local data = {} do
                data.elements = {
                    "Bind / In Air / No Scope", "Global", "Autosnipers", "SSG 08", "AWP", "R8 Revolver", "Desert Eagle", "Pistol", "Zeus", "Rifle", "Shotgun", "SMG", "Machine gun"
                }
                data.scope = {
                    "Autosnipers", "SSG 08", "AWP"
                }
                data.ex = {[(data.elements[1])] = true}
                data.list = {table.unpack(data.elements)}
                data.numbers = {}
                data.values = {}
                for i, name in pairs(data.elements) do
                    data.numbers[name] = i
                    if name ~= data.elements[1] then
                        data.values[name] = { button = disabled, air = disabled, scope = disabled}
                    end
                end
                for a, b in pairs(data.ex) do
                    data.list[data.numbers[a]] = pui.format('\v'..data.list[data.numbers[a]])
                end
            end

            hitchance.box = tabs.aa:listbox("\nhitchance", data.list)

            local settings = {}
            for a, b in pairs(data.elements) do
                if not data.ex[b] then
                    settings[b] = {}
                    local button,air,scope = {}, {}, {}

                    button.on = tabs.aa:checkbox("Enabled hitchance \vOn Button\n"..b)
                    button.hotkey = tabs.aa:hotkey("\nez"..b, true)
                    button.hitchance = tabs.aa:slider("\nbutton"..b, 0, 100, 50, true, '%')
                    settings[b].button = button

                    air.on = tabs.aa:checkbox("Enabled hitchance \vIn Air\n"..b)
                    air.hitchance = tabs.aa:slider("\nair"..b, 0, 100, 50, true, '%')
                    settings[b].air = air

                    if data.scope[data.numbers[b] - 2] then
                        scope.on = tabs.aa:checkbox("Enabled hitchance \vNo scope\n"..b)
                        scope.hitchance = tabs.aa:slider("\nscope"..b, 0, 100, 50, true, '%')
                        settings[b].scope = scope
                    end 
                    pui.traverse(settings[b], function(element, path)
                        if path[2] ~= 'on' then
                            element:depend({settings[b][path[1]].on, true})
                        else
                            element:set_callback(function(self)
                                data.values[b][path[1]] = (element.value and ('\v'..'on ') or disabled)
                                data.list[data.numbers[b]] = pui.format(data.elements[data.numbers[b]] ..' \aC8C8C8C8~ ' .. data.values[b].button.. data.values[b].air.. (data.scope[data.numbers[b] - 2] and data.values[b].scope or ''))
                                hitchance.box:update(data.list)
                            end, true)
                        end
                    end)
                end
            end
            pui.traverse(settings, function(element, path)
                element:depend({hitchance.box, data.numbers[path[1]] - 1})
            end)

            hitchance.settings = settings
            Features.hitchance = hitchance
        end

        Features.label3 = create.label(tabs.aa, "Other")

        local animations = {} do
            animations = create.element(tabs.aa, "Animations")

            animations.ground = tabs.aa:combobox('On-Ground', {"Default", "Never slide", "Always slide", "Jitter", "Moonwalk"})
            animations.note = tabs.aa:label("\aCAB02AC8"..'"Jitter" works as an anti-aim')
                :depend({animations.ground, "Jitter"})
            animations.air = tabs.aa:combobox('In-Air', {"Default", "Static", "Moonwalk"})
            animations.extra = tabs.aa:multiselect('Extra', {"Landing Pitch", "Disable Move Lean"})

            Features.animations = animations
        end

        local console = {} do
            console = create.element(tabs.aa, "Console Filter")

            Features.console = console
        end
        
        local clantag = {} do
            clantag = create.element(tabs.aa, "Clantag")

            Features.clantag = clantag
        end

        local trashtalk = {} do
            trashtalk = create.element(tabs.aa, "Trashtalk")
            trashtalk.event = tabs.aa:multiselect("\ntrashtalk.event", {"On Kill", "On Death"})
            trashtalk.used = tabs.aa:checkbox("Used elements? trashtalk")
            trashtalk.used:depend({setup, 'xdadadsadadx'})

            if not trashtalk.used.value then
                pui.traverse(trashtalk, function(element, path)
                    if path[1] == 'event' then
                        element:set({"On Kill", "On Death"})
                    end
                end)
            end

            Features.trashtalk = trashtalk
        end

        menu.Features = Features
    end

    local Antiaims = {} do

        local settings = {} do
            settings.cond = tabs.fl:combobox("\vCondition", condition_list, nil, false)

            Antiaims.settings = settings
        end

        local other = {} do
            other.fl_disabler = tabs.aa:multiselect("Fake Lag Disablers", {"Not moving", "Crouch Move"})
            other.space = tabs.aa:label('\nlabel4')
            other.avoid_backstab = tabs.aa:checkbox('Avoid Backstab')
            other.ladder = tabs.aa:checkbox('Fast Ladder')
            -- other.unsafe = tabs.aa:checkbox('Unsafe Exploit Charge')

            Antiaims.other = other
        end

        local hotkeys = {} do
            hotkeys.space = tabs.aa:label('\nlabel3')
            hotkeys.edge = tabs.aa:hotkey('Edge Yaw')
            hotkeys.fs = tabs.aa:hotkey('Freestanding')
            hotkeys.fs_disablers = tabs.aa:multiselect("Disablers \nFS", {"Yaw Jitter", "Body Yaw"})
            hotkeys.space1 = tabs.aa:label('\nlabel2')
            hotkeys.left = tabs.aa:hotkey('Manual \v<\r Left')
            hotkeys.right = tabs.aa:hotkey('Manual \v>\r Right')
            hotkeys.forward = tabs.aa:hotkey('Manual \v^\r Forward')
            hotkeys.space2 = tabs.aa:label('\nlabel2')

            Antiaims.hotkeys = hotkeys
        end

        local t1,t2,t3 = {}, {}, {}
        for i=-180, 180 do
            t1[i] = i..' max'
        end
        for i=-180, 180 do
            t2[i] = i..' min'
        end
        for i=0, 50 do
            t3[i] = i*.1 ..' °/s'
        end

        local other2 = {} do
            -- other2.defensive = tabs.other:checkbox('Disable Defensive AA')
            other2.defensive = tabs.other:multiselect('Disable Defensive Features', {"Def. Flick", "Def. AA", "Force Def."})
            other2.flick = tabs.other:checkbox('Defensive Flick', 0X00)

            local aa = {
                disablers = tabs.other:multiselect("Disablers", {"Body Yaw", "Yaw Jitter"}),

                pitch = tabs.other:combobox("Pitch\nfl d_pitch", {"None", "Random", "Custom", "Progressive"}),
                pitch_val = tabs.other:slider("\nfl d_pitch_val", -89, 89, 0, true, '°', 1, {[-89] = "Up", [-45] = "Semi-Up", [0] = "Zero", [45] = "Semi-Down", [89] = "Down"}),    
                pitch_speed = tabs.other:slider("\nfl d_pitch_speed", 0, 50, 10, true, '', 0.1, t3),
                pitch_min = tabs.other:slider("\nfl d_pitch_min", -89, 89, -89, true, '°', 1, t2),
                pitch_max = tabs.other:slider("\nfl d_pitch_max", -89, 89, 89, true, '°', 1, t1),

                yaw = tabs.other:combobox("Yaw\nfl  d_yaw", {"None", "Sideways", 'Sideways 45', "Spin", "Random", "Custom", "Yaw Opposite", "Progressive", "Yaw Side"}),
                yaw_val = tabs.other:slider("\nfl d_yaw_val", -180, 180, 0, true, '°', 1, {[-180] = 'Forward', [0] = "Backward", [180] = "Forward"}),
                yaw_invert = tabs.other:hotkey("Inverter"),
                yaw_speed = tabs.other:slider("\nfl d_yaw_speed", 0, 50, 10, true, '', 0.1, t3),
                yaw_min = tabs.other:slider("\nfl d_yaw_min", -180, 180, -180, true, '°', 1, t2),
                yaw_max = tabs.other:slider("\nfl d_yaw_max", -180, 180, 180, true, '°', 1, t1),

            }
            pui.traverse(aa, function(element, path)
                element:depend({other2.flick, true})
            end)

            aa.pitch_val:depend({aa.pitch, 'Custom'})
            aa.yaw_val:depend({aa.yaw, "Custom"})
            aa.pitch_speed:depend({aa.pitch, 'Progressive'})
            aa.pitch_min:depend({aa.pitch, 'Progressive'})
            aa.pitch_max:depend({aa.pitch, 'Progressive'})
            aa.yaw_invert:depend({aa.yaw, "Custom"})
            aa.yaw_speed:depend({aa.yaw, "Progressive", "Spin"})
            aa.yaw_min:depend({aa.yaw, 'Progressive'})
            aa.yaw_max:depend({aa.yaw, 'Progressive'})
            other2.flick_aa = aa
            Antiaims.other2 = other2
        end

        local xd do
            Antiaims.label = tabs.fl:label('\nlabel1')

            Antiaims.label2 = tabs.fl:label('\nlabel2')
            Antiaims.default = tabs.fl:checkbox("GS", nil, false)
            Antiaims.megabutton = tabs.fl:button("Setup \vOther\r settings")

            tab:depend({Antiaims.default, false})
            tab_label:depend({Antiaims.default, false})
            Antiaims.default:depend({tab, 'fwefwefw'})

            Antiaims.default:set_callback(function(self)
                for a,t in pairs(refs) do
                    if a ~= 'aa' then
                        for name,el in pairs(t) do
                            el:set_visible(self.value)
                        end
                    end
                end
                refs.aa.fs:set_visible(self.value)
            end, true)

            Antiaims.megabutton:set_callback(function()
                Antiaims.default:set(not Antiaims.default:get())
            end)
            xd = {
                ['megabutton'] = true,
                ['label'] = true,
                ['other'] = 1,
                ['hotkeys'] = 1,
            }
        end

        local defensive_max = 13
        local max_angle = 180

        local builder = {} do
            local xd2 = {table.unpack(condition_list)}
            table.remove(xd2, 1)
            table.remove(xd2, 10)
            for i, name in pairs(condition_list) do
                builder[name] = {}

                pui.macros.x = '\n'..name


                builder[name].enabled = (name ~= condition_list[1] and name ~= condition_list[10]) and tabs.aa:checkbox("Enabled - \v"..name) or nil
                builder[name].conditions = name == condition_list[11] and tabs.aa:multiselect("Conditions", (xd2)) or nil
                builder[name].weapons = name == condition_list[11] and tabs.aa:multiselect("\nWeapons", {
                    "Knife", 
                    "Zeus", 
                    "Height Advantage"
                }) or nil
                builder[name].label_en = tabs.aa:label("\nen label")
                builder[name].yaw = {
                    base = tabs.aa:combobox("Yaw Base", (name == condition_list[10] and {"Local view", "At targets"} or {"At targets", "Local view"})),
                    global = name ~= condition_list[10] and tabs.aa:slider("Global Yaw\f<x>", -max_angle, max_angle, 0, true, '°') or nil,
                    left = name ~= condition_list[10] and tabs.aa:slider("Left & Right Yaw\f<x>", -max_angle, max_angle, 0, true, '°') or nil,
                    right = name ~= condition_list[10] and tabs.aa:slider("\nright yaw\f<x>", -max_angle, max_angle, 0, true, '°') or nil,
                }
                builder[name].label_yaw = tabs.aa:label("\nyaw label")

                builder[name].jitter = {
                    type = tabs.aa:combobox("Yaw Jitter\f<x>", {
                        "Off", 
                        "Offset", 
                        "Center", 
                        "Random", 
                        "Skitter", 
                        "3-Way", 
                        "5-Way", 
                    }),
                    mode = tabs.aa:combobox("\njitter mode\f<x>", {
                        "Static", "Switch", "Random", "Spin"
                    }),
                    value = tabs.aa:slider("\f<x>jitter value", -max_angle, max_angle, 0, true, '°'),
                    value2 = tabs.aa:slider("\f<x>jitter value2", -max_angle, max_angle, 0, true, '°'),
                    ways = (function()
                        local el = {}
                        for i=1, 5 do
                            el[i] = tabs.aa:slider("\f<x>way" .. i, -max_angle, max_angle, 0, true, '°')
                        end
                        return el
                    end)(),
                    rand = tabs.aa:slider("Randomization\f<x>", 0, max_angle, 0, true, '°', 1, {[0] = 'Off'})
                }

                local t = {['Off'] = true, ['3-Way'] = true, ['5-Way'] = true}
                builder[name].jitter.mode:depend({builder[name].jitter.type, function()
                    return not t[builder[name].jitter.type.value]
                end})
                builder[name].jitter.value:depend({builder[name].jitter.type, function()
                    return not t[builder[name].jitter.type.value]
                end})
                builder[name].jitter.value2:depend({builder[name].jitter.mode, "Static", true}, {builder[name].jitter.type, function()
                    return not t[builder[name].jitter.type.value]
                end})
                for i=1, 5 do
                    builder[name].jitter.ways[i]:depend({builder[name].jitter.type, function()
                        return i<4 and builder[name].jitter.type.value == '3-Way' or builder[name].jitter.type.value == '5-Way'
                    end})
                end
                builder[name].jitter.rand:depend({builder[name].jitter.type, "Off", true})
                
                builder[name].body = {
                    yaw = tabs.aa:combobox('Body Yaw\f<x>', {"Off", "Static", "Opposite", "Jitter"}),
                    side = tabs.aa:slider("\f<x> side", 0,1,0, true, nil, 1, {[0] = "Left", [1] = "Right"}),
                    delay = {
                        mode = tabs.aa:combobox("\ndelay mode\f<x>", {"Static", "Switch"}),
                        delay = tabs.aa:slider("Delay\f<x>", 1, 12, 1, true, 't', 1, {[1] = 'Default'}),
                        left = tabs.aa:slider("Left ticks\f<x>", 1, 12, 1, true, 't', 1, {[1] = 'Default'}),
                        right = tabs.aa:slider("Right ticks\f<x>", 1, 12, 1, true, 't', 1, {[1] = 'Default'}),
                        switch = tabs.aa:slider("Switch ticks\f<x>", 0, 50, 0, true, 't', 1, {[0] = 'Off'}),
                    }
                }
                builder[name].body.side:depend({builder[name].body.yaw, "Static"})
                for a,b in pairs(builder[name].body.delay) do
                    b:depend({builder[name].body.yaw, "Jitter"}, a ~= 'mode' and {builder[name].body.delay.mode, a == 'delay' and "Static" or "Switch"})
                end
                builder[name].label_def = tabs.aa:label("\ndef label")
                if name ~= "Fake Lag" then
                    builder[name].defensive = {
                        force = tabs.aa:checkbox("Force Defensive\f<x>"),
                        enabled = tabs.aa:checkbox("Enabled \v" .. name ..  " \rDefensive AA\f<x>"),
                        enabled_ = name ~= "Default" and tabs.aa:label("\aFFFFFF4E- Using settings from "..condition_list[1].." Condition\f<x>") or nil,
                        override = name ~= "Default" and tabs.aa:checkbox("Override \v" .. name ..  " \rDefensive AA\f<x>") or nil,
                        override_ = tabs.aa:label("\aFF4E4EFF- DEFENSIVE AA DISABLED\f<x>"),

                        settings = {
                            duration = tabs.aa:slider('Duration \f<x>', 2, defensive_max, 13, true, 't', 1, {[13] = "Max"}),
                            disablers = tabs.aa:multiselect("Disablers", {"Body Yaw", "Yaw Jitter"}),

                            pitch = tabs.aa:combobox("Pitch\f<x> d_pitch", {"None", "Random", "Custom", "Progressive"}),
                            pitch_val = tabs.aa:slider("\f<x>d_pitch_val", -89, 89, 0, true, '°', 1, {[-89] = "Up", [-45] = "Semi-Up", [0] = "Zero", [45] = "Semi-Down", [89] = "Down"}),      
                            pitch_speed = tabs.aa:slider("\nd d_pitch_speed", 0, 50, 10, true, '', 0.1, t3),
                            pitch_min = tabs.aa:slider("\nd d_pitch_min", -89, 89, -89, true, '°', 1, t2),
                            pitch_max = tabs.aa:slider("\nd d_pitch_max", -89, 89, 89, true, '°', 1, t1),
                            yaw = tabs.aa:combobox("Yaw\f<x> d_yaw", {"None", "Sideways", 'Sideways 45', "Spin", "Random", "Custom", "Yaw Opposite", "Progressive", "Yaw Side"}),
                            yaw_val = tabs.aa:slider("\f<x>d_yaw_val", -180, 180, 0, true, '°', 1, {[-180] = 'Forward', [0] = "Backward", [180] = "Forward"}),
                            yaw_speed = tabs.aa:slider("\nd d_yaw_speed", 0, 50, 10, true, '', 0.1, t3),
                            yaw_min = tabs.aa:slider("\nd d_yaw_min", -180, 180, -180, true, '°', 1, t2),
                            yaw_max = tabs.aa:slider("\nd d_yaw_max", -180, 180, 180, true, '°', 1, t1),
                        }
                    }
                    for n,ref in pairs(builder[name].defensive.settings) do
                        ref:depend({builder[name].defensive.enabled, true})
                        if name ~= condition_list[1] then
                            ref:depend({builder[name].defensive.override, true})
                        end
                    end
                    if name ~= condition_list[1] then 
                        builder[name].defensive.override:depend({builder[name].defensive.enabled, true})
                        builder[name].defensive.enabled_:depend({builder[name].defensive.enabled, true}, {builder[name].defensive.override, false})
                    end
                    builder[name].defensive.override_:depend({other2.defensive, true}, {builder[name].defensive.enabled, true})
                    builder[name].defensive.settings.pitch_val:depend({builder[name].defensive.settings.pitch, 'Custom'})
                    builder[name].defensive.settings.yaw_val:depend({builder[name].defensive.settings.yaw, "Custom"})
                    builder[name].defensive.settings.pitch_speed:depend({builder[name].defensive.settings.pitch, 'Progressive'})
                    builder[name].defensive.settings.pitch_max:depend({builder[name].defensive.settings.pitch, 'Progressive'})
                    builder[name].defensive.settings.pitch_min:depend({builder[name].defensive.settings.pitch, 'Progressive'})
                    builder[name].defensive.settings.yaw_speed:depend({builder[name].defensive.settings.yaw, "Progressive", "Spin"})
                    builder[name].defensive.settings.yaw_min:depend({builder[name].defensive.settings.yaw, "Progressive"})
                    builder[name].defensive.settings.yaw_max:depend({builder[name].defensive.settings.yaw, "Progressive"})
                end
                builder[name].label_def2 = tabs.aa:label("\ndef label2")

                builder[name].export = tabs.aa:button("Export \v"..name)
                builder[name].import = tabs.aa:button("Import \v"..name)
                builder[name].export:set_callback(function(self)
                    local config = pui.setup(builder[name])

                    clipboard.set(base64.encode( json.stringify(config:save()) ))
                    client.exec('playvol buttons\\button18 0.5')
                    utils.printc(pui.format("\f<r>[\f<ez>Regicide.Hit\f<r>] ~ Exported condition \f<ez>" .. name))
                end)
                builder[name].import:set_callback(function(self)
                    local config = pui.setup(builder[name])

                    config:load(json.parse(base64.decode(clipboard.get())))
                    client.exec('playvol buttons\\button17 0.5')
                    utils.printc(pui.format("\f<r>[\f<ez>Regicide.Hit\f<r>] ~ Imported config for \f<ez>" .. name ..'\f<r> condition'))
                end)
            end

            pui.traverse(builder, function(element, path)
                element:depend({settings.cond, path[1]})
                if path[1] ~= condition_list[1] and path[1] ~= condition_list[10] and path[2] ~= 'enabled' then
                    element:depend({builder[path[1]].enabled, true})
                end
            end)

            Antiaims.builder = builder
        end

        pui.traverse(Antiaims, function(element, path)
            if not xd[path[1]] then
                element:depend({Antiaims.default, false})
            elseif xd[path[1]] == 1 then
                element:depend({Antiaims.default, true})
            end
        end)

        menu.Antiaims = Antiaims
    end

    client.set_event_callback('post_config_load', function()
        setup:set("None")
    end)

    pui.traverse(menu, function(element, path)
        element:depend({tab, path[1]})
        if path[3] == 'color' then goto skip end
        if path[1] == "Features" and path[3] == 'on' then
            local path2 = menu.Features[path[2]]
            pui.traverse(path2, function(el, path3)
                local el = path2
                for _, name in pairs(path3) do
                    el = el[name]
                end
                el:depend({setup, function()
                    return setup.value == path2.on.name:sub(9, #path2.on.name) or (({['disabled'] = true, ['enabled'] = true, ['on'] = true})[path3[1]] and setup.value == 'None')
                end})
            end)
        end
        ::skip::
    end)
end

local Config do
    Config = pui.setup(menu)

    local update_box = function()
        db.configs = {}
        for i, cfgs in pairs(db.db.configs[menu.Home.aa.type.value]) do
            table.insert(db.configs, pui.format('[\v'..i..'\r] ' .. cfgs[1])) 
        end
        menu.Home.aa.box:update(db.configs)
    end update_box()

    local create_config = function(name, cfg)
        name = cfg and name or menu.Home.other.Local.name:get()
        if #name >= 1 then
            table.insert(db.db.configs['Local'], {name, cfg or base64.encode(json.stringify(Config:save())) } )
            db.save()
            menu.Home.other.Local.name:set('')
            utils.printc(pui.format("\f<r>[\f<ez>Regicide.Hit\f<r>] ~ \f<ez>"..(cfg and 'Imported' or 'Created').." \f<r>config \f<ez>" .. name))
        end
        update_box()
        menu.Home.aa.box:set(#db.db.configs['Local'] - 1)
    end
    menu.Home.other.Local.create:set_callback(create_config)

    local get_config = function()
        local t = db.db.configs['Local'][menu.Home.aa.box.value + 1]
        return t[1], t[2]
    end

    menu.Home.aa.delete:set_callback(function()
        local val = menu.Home.aa.box:get()
        utils.printc(pui.format("\f<r>[\f<ez>Regicide.Hit\f<r>] ~ \f<ez>Deleted \f<r>config \f<ez>" .. get_config(val)))

        client.exec('playvol buttons\\button16 0.5')
        table.remove(db.db.configs['Local'], val + 1)
        menu.Home.aa.box:set(0)
        db.save()
        update_box()
    end)

    menu.Home.aa.save:set_callback(function()
        local cfg = base64.encode( json.stringify(Config:save()) )
        db.db.configs['Local'][menu.Home.aa.box.value + 1][2] = cfg
        if menu.Home.other.Local.autoload_save:get("Save") then
            db.db.last.cfg = cfg
        end
        utils.printc(pui.format("\f<r>[\f<ez>Regicide.Hit\f<r>] ~ \f<ez>Updated \f<r>config \f<ez> ".. get_config()))

        client.exec('playvol buttons\\button16 0.5')
        db.save()
    end)

    menu.Home.aa.export:set_callback(function()
        local name, cfg = get_config()
        local text = string.format('Regicide::%s::%s', name, cfg)
        client.exec('playvol buttons\\button18 0.5')
        clipboard.set(text)
        utils.printc(pui.format("\f<r>[\f<ez>rRegicide.Hit\f<r>] ~ \f<ez>Exported \f<r>config \f<ez>" .. name))

    end)
    
    local load_config = function(self, cfg)
        local name, config = get_config()
        local decrypted = json.parse( base64.decode(config) )
        Config:load(decrypted, self.name == "Load AA" and "Antiaims" or nil)
        drag.on_config_load()
        utils.printc(pui.format("\f<r>[\f<ez>Regicide.Hit\f<r>] ~ \f<ez>Loaded"..(self.name == "Load AA" and " antiaim" or '').." \f<r>config \f<ez>" .. name))
        client.exec('playvol buttons\\button17 0.5')
        if menu.Home.other.Local.autoload_save:get("Load") then
            db.db.last.cfg = base64.encode( json.stringify(Config:save()) )
        end
        db.save()
    end

    menu.Home.other['Local'].import:set_callback(function()
        local text = clipboard.get()
        local name, config = text:match("Regicide::([%s%S]+)::([%s%S]+)")
        if not name or not config then return end
        create_config(name,config)
        load_config(menu.Home.aa.load)
    end)
    
    menu.Home.aa.load:set_callback(load_config)
    menu.Home.aa.loadaa:set_callback(load_config)
    if db.db.last.on and db.db.last.cfg then
        local decrypted = json.parse( base64.decode(db.db.last.cfg) )
        Config:load(decrypted)
        utils.printc(pui.format("\f<r>[\f<ez>Regicide.Hit\f<r>] ~ \f<ez>Loaded \f<r>last saved config"))
        
        client.exec('playvol buttons\\button17 0.5')
    end

    defer(function()
        if db.db.last.on and menu.Home.other.Local.autoload_save:get("Shutdown") then
            db.db.last.cfg = base64.encode( json.stringify(Config:save()) )
            db.save()
        end
    end)
end

local lp do
    lp = {}
    lp.state = "Standing"
    lp.manual = nil
    lp.in_score = false
    lp.scoped = false
    lp.zoom = 0
    lp.entity = nil
    -- lp.tickbase_shifting = 0
    lp.weapon = nil
    lp.flicking = false
    lp.exploit = ''

    lp.on_ground = false
    lp.moving = false
    lp.crouch = false

    local height_advantage = function()
        local origin = vector(entity.get_origin(lp.entity))
        local threat = client.current_threat()
        if not threat then return false end
        local threat_origin = vector(entity.get_origin(threat))
        local height_to_threat = origin.z-threat_origin.z
        return height_to_threat > 50
    end

    local update_state = function(e)
        lp.flicking = menu.Antiaims.other2.flick.value and menu.Antiaims.other2.flick:get_hotkey() and not menu.Antiaims.other2.defensive:get("Def. Flick")
        lp.exploit = refs2.fd:get() and 'fd' or refs2.dt.value and refs2.dt:get_hotkey() and 'dt' or refs.other.osaa.value and refs.other.osaa:get_hotkey() and 'osaa' or ''
        lp.entity = entity.get_local_player()
        -- lp.tickbase_shifting = antiaim_funcs.get_tickbase_shifting()

        local flags = entity.get_prop(lp.entity, "m_fFlags")
        local velocity = vector(entity.get_prop(lp.entity, "m_vecVelocity"))
    
        lp.on_ground = bit.band(flags, 1) ~= 0 and e.in_jump == 0
        lp.crouch = entity.get_prop(lp.entity, "m_flDuckAmount") > 0.9
        lp.moving = math.sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y) + (velocity.z * velocity.z)) > 5

        lp.in_score = e.in_score == 1
        lp.scoped = entity.get_prop(lp.entity, 'm_bIsScoped') == 1
        lp.weapon = entity.get_player_weapon(lp.entity)
        lp.zoom = lp.weapon and entity.get_prop(lp.weapon, 'm_zoomLevel') or 0

        local state = (function()
            if lp.manual then return condition_list[10] end
            if menu.Antiaims.builder[condition_list[12]].enabled:get() and #entity.get_players(true) == 0 then return condition_list[12] end
            if not (refs2.dt.value and refs2.dt.hotkey:get())
            and not (refs.other.osaa.value and refs.other.osaa.hotkey:get())
            and refs.fl.enabled.value and refs.fl.enabled.hotkey:get() then return condition_list[9] end
            if lp.on_ground then
                if lp.crouch then return lp.moving and condition_list[6] or condition_list[5]
                else if lp.moving then 
                    return e.in_speed == 1 and condition_list[4] or condition_list[3]
                    else return condition_list[2] end 
                end
            else return lp.crouch and condition_list[8] or condition_list[7]
            end
        end)()
        
        local csgoweapon = csgo_weapons(lp.weapon)
        local safehead
        if csgoweapon and menu.Antiaims.builder[condition_list[11]].conditions:get(state) then
            local work = (
                csgoweapon.is_knife and menu.Antiaims.builder[condition_list[11]].weapons:get("Knife") or 
                csgoweapon.is_taser and menu.Antiaims.builder[condition_list[11]].weapons:get("Zeus") or
                menu.Antiaims.builder[condition_list[11]].weapons:get("Height Advantage") and height_advantage()
            )
            safehead = work and condition_list[11] or false
        end
        lp.state = safehead or state
    end
    client.set_event_callback('setup_command', update_state)
    client.set_event_callback("level_init", function()
        lp.entity = nil
    end)
end

local watermark do 

    local fps,last,avg_fps = math.floor(1.0 / globals.frametime()),globals.curtime(),0
    local last2 = last
    local update
    local reset

    update = function()
        client.delay_call(1, update)

        fps =  math.floor(avg_fps)
    end update()

    reset = function()
        client.delay_call(10, reset)
        avg_fps = 0
    end reset() 

    local render = drag.register(menu.Features.watermark.drag, vector(330, 25), "watermark", function(self)

        local text do
            local new_frame = 1.0 / math.max(0.0001, globals.frametime())
            avg_fps = avg_fps <= 0.0 and new_frame or (avg_fps * 0.9 + new_frame * 0.1)

            local ping = string.format('%.0f', client.latency()*1000)
        
            local hours, minutes = client.system_time()
            local time = string.format("%02d:%02d", hours,minutes)

            local custom = menu.Features.watermark.custom:get()

            text = '  |  Regicide.Hit / '..version[1] ..'  |  '..
            (menu.Features.watermark.elements:get("Nickname") and (custom ~= '' and custom or (username[1]))..'  |  ' or '').. 
            (menu.Features.watermark.elements:get("FPS") and fps..' fps  |  ' or '')..
            (menu.Features.watermark.elements:get("Ping") and ping..' ping  |  ' or '')..
            (menu.Features.watermark.elements:get("Time") and time..' |  ' or '')

        end

        local measure = vector(renderer.measure_text('d', text))
        self.position.y = math.floor(menu.Features.watermark.lock.value == "None" and self.position.y or string.match(menu.Features.watermark.lock.value, 'Upper') and 10 or screen.size.y-measure.y-10)
        self.position.x = math.floor( menu.Features.watermark.lock.value == "None" and self.position.x or
            (menu.Features.watermark.lock.value == 'Upper-Right' or menu.Features.watermark.lock.value == 'Bottom-Right') and screen.size.x - measure.x - 20 or
            (menu.Features.watermark.lock.value == 'Upper-Center' or menu.Features.watermark.lock.value == 'Bottom-Center') and screen.center.x - measure.x * 0.5 or 20
        )

        self.size.x = measure.x
        self.size.y = measure.y+6

        local w = colors['watermark']["Background"]
        local t = colors['watermark']["Text"]

        utils.rectangle(self.position.x,self.position.y, self.size.x, self.size.y, w.r,w.g,w.b,w.a, 5)
        renderer.text(self.position.x, self.position.y + 2, t.r,t.g,t.b,math.max(t.a, 75), 'd', 0, menu.Features.watermark.candy.value and gradient.animated_gradient_text(text, gradient.table, 20/#gradient.table, 1) or text)
    end, nil, false)

    client.set_event_callback('paint', function()
        render:update()
    end)
end

local hitchance do
    local custom = {
        ['G3SG1 / SCAR-20'] = "Autosnipers", 
    }
    local self = menu.Features.hitchance
    local setup = function()
        refs2.hc:override()
        if not lp.entity or not entity.is_alive(lp.entity) then return end
        local weapon = refs2.weapon:get()
        local a = self.settings[(custom[weapon] or weapon)]
        local b = a.button.hotkey:get() and a.button.on.value and 'button' or a.air.on.value and not lp.on_ground and 'air' or a.scope and a.scope.on.value and not lp.scoped and 'scope' or nil
        if not b then hitchance = false return end
        hitchance = {b, a[b].hitchance.value}

        client.delay_call(0,function()
            refs2.hc:override(a[b].hitchance.value)
        end)
    end
    menu.Features.hitchance.on:set_event('setup_command', setup)
    menu.Features.hitchance.on:set_callback(function()
        hitchance = false
        refs2.hc:override()
    end)
end

local crosshair do
    crosshair = { --{x, alpha, y}
        {0, 1,0},
        {0, 1,0, 0},
        {0, 0,0},
        {0, 0,0},
        {0, 0,0},
        {0, 0,0},
        {0, 0,0},
        {0, 0,0},
        {0, 0,0},
        {0, 0,0},
        {0, 0,0},
    }
    local flags = '-cd'
    local prev = lp.state
    local transparency = 0
    local render = function()
        if not lp.entity or not entity.is_alive(lp.entity) then return end
        local weapon2 = entity.get_player_weapon(lp.entity)
        if not weapon2 then return end
        local weapon = csgo_weapons(weapon2)
        if not weapon then return end
        local game_rules = entity.get_game_rules()
        if not game_rules then return end
        local m_gamePhase = entity.get_prop(game_rules, 'm_gamePhase')
        local NextPhase = entity.get_prop(game_rules, 'm_timeUntilNextPhaseStarts')
        transparency = utils.lerp(transparency, (weapon.is_grenade or lp.in_score or m_gamePhase == 5 or NextPhase ~= 0) and 0.5 or 1, 0.03)

        local version1 = colors['crosshair']['Version']:clone()
        version1.a = version1.a * transparency
        local rin = colors['crosshair']['Regicide.Hit']:clone()
        rin.a = math.max(127, rin.a * transparency)
        local cond = colors['crosshair']['Conditions']:clone()
        cond.a = cond.a * transparency

        menu.Features.crosshair.settings['Regicide.Hit'].container.candy:get()
        local elements = {
            -- {"Regicide.Hit", true, gradient.animated_gradient_text(text, gradient.table, (#gradient.table/5)/#gradient.table)},
            {"Regicide.Hit", true, 
            (menu.Features.crosshair.settings['Regicide.Hit'].container.candy.value and "Regicide.Hit ["..version[1].."]" or ("\a"..utils.to_hex(rin).."Regicide.Hit \a"..utils.to_hex(version1) .."["..version[1].."]"))},
            {"Conditions", true, menu.Features.crosshair.settings['Conditions'].container.candy.value and lp.state or"\a"..utils.to_hex(cond)..lp.state},
            {"Double Tap", refs2.dt.value and refs2.dt:get_hotkey()},
            {"Hide Shots", refs.other.osaa.value and refs.other.osaa:get_hotkey()},
            {"Min. Damage", refs2.mdmg:get() and refs2.mdmg:get_hotkey()},
            {"Hitchance", hitchance and hitchance[1] == 'button'},
            {"Body Aim", refs2.baim:get()},
            {"Safe Points", refs2.safe:get()},
            {"Ping Spike", refs2.ping.value and refs2.ping:get_hotkey()},
            {"Freestanding", menu.Antiaims.hotkeys.fs:get()},
            {"Flicking", lp.flicking},
        }
        for i=2, #elements do
            local name = elements[i][1]
            elements[i][3] = i == 2 and elements[i][3] or menu.Features.crosshair.settings[elements[i][1]].container.name:get() == '' and hard["crosshair"].names[elements[i][1]] or menu.Features.crosshair.settings[elements[i][1]].container.name:get()
            elements[i][2] = elements[i][2] and menu.Features.crosshair.settings[elements[i][1]].on.value
        end
        local y_add = 20
        
        do
            for i, table in pairs(crosshair) do
                table[2] = utils.lerp(table[2], elements[i][2] and transparency or 0, 0.03)

                if table[2] > 0 then 
                    local text = elements[i][3]:upper()
                    local measure = vector(renderer.measure_text(flags, text))
                    table[3] = utils.lerp(table[3], elements[i][2] and measure.y or 0, 0.03)
                    table[1] = utils.lerp(table[1], elements[i][2] and lp.scoped and (measure.x+20)/2 or 0, 0.035)
                    local c = colors['crosshair'][elements[i][1]]
                    renderer.text(screen.center.x + math.floor(table[1]), screen.center.y + y_add, 
                    c.r,c.g,c.b,c.a * table[2], flags, 0, 
                    menu.Features.crosshair.settings[elements[i][1]].container.candy:get() and gradient.animated_gradient_text(text, gradient.table, (#gradient.table/5)/#gradient.table, table[2]) or text)
                    y_add = y_add + table[3]
                end
            end
        end
    end

    menu.Features.crosshair.on:set_event('paint', render)
end

local damage do
    local alpha = 0
    damage = 100
    
    local render = drag.register(menu.Features.damage.drag, vector(30, 20), "damage", function(self)
        if not lp.entity or not entity.is_alive(lp.entity) then return end
        
        alpha = utils.lerp(alpha, menu.Features.damage.display.value == "Display: Always On" and 1 
            or refs2.mdmg:get() and refs2.mdmg:get_hotkey() and 1 
            or (menu.Features.damage.display.value == "Display: Always On (50%)" and 0.5 or 0), 
            0.02)

        local cur_dmg = ( (refs2.mdmg:get() and refs2.mdmg:get_hotkey()) or menu.Features.damage.display.value == "Display: On Hotkey" and menu.Features.damage.animation.value == "Animation: Instant") and refs2.mdmg2.value or refs2.dmg.value
        
        damage = menu.Features.damage.animation.value == "Animation: Instant" and cur_dmg or utils.lerp(damage, cur_dmg, 0.035)

        if alpha > 0 then
            local c = colors['damage']['Color']
            renderer.text(self.position.x+self.size.x/2, self.position.y + self.size.y/2, c.r,c.g,c.b,c.a * alpha, 'dc'..(menu.Features.damage.font.value == "Font: Default" and '' or '-'), 0, string.format('%.0f', damage))
        end
    end)
    menu.Features.damage.on:set_event('paint', function()
        render:update()
    end)

end

local scope do
    local offset = 0
    local length = 0
    local alpha = 0
    local currentAngle

    local function gradient_line(x1, y1, x2, y2, r1, g1, b1, a1, r2, g2, b2, a2, segments)
        local step = 1 / segments
        for i = 0, segments - 1 do
            local t1, t2 = i * step, (i + 1) * step
            local r = r1 + (r2 - r1) * t1
            local g = g1 + (g2 - g1) * t1
            local b = b1 + (b2 - b1) * t1
            local a = a1 + (a2 - a1) * t1
    
            local x_start = x1 + (x2 - x1) * t1
            local y_start = y1 + (y2 - y1) * t1
            local x_end = x1 + (x2 - x1) * t2
            local y_end = y1 + (y2 - y1) * t2
    
            renderer.line(x_start, y_start, x_end, y_end, r, g, b, a)
        end
    end
    
    local function rotate(x, y, cx, cy, angle)
        local rad = math.rad(angle)
        local cosAngle = math.cos(rad)
        local sinAngle = math.sin(rad)
        local dx = x - cx
        local dy = y - cy
        return cx + dx * cosAngle - dy * sinAngle, cy + dx * sinAngle + dy * cosAngle
    end

    local render = function()
        refs2.scope:override(false)
        if not lp.entity or not entity.is_alive(lp.entity) then return end
    
        offset = utils.lerp(offset, lp.scoped and menu.Features.scope.gap.value or 0, 0.03)
        length = utils.lerp(length, lp.scoped and menu.Features.scope.length.value or 0, 0.03)
        alpha = utils.lerp(alpha, lp.scoped and 1 or 0, 0.02)
    
        if offset > 0 and length > 0 then
            local c = colors['scope']['Color']
            
            if menu.Features.scope.style.value == "Style: Plus" then
                renderer.gradient(screen.center.x, screen.center.y + offset, 1, length, c.r, c.g, c.b, c.a * alpha, c.r, c.r, c.r, 0, false)
                renderer.gradient(screen.center.x + 1, screen.center.y - offset, -1, -length, c.r, c.g, c.b, c.a * alpha, c.r, c.r, c.r, 0, false)
                renderer.gradient(screen.center.x - offset, screen.center.y + 1, -length, -1, c.r, c.g, c.b, c.a * alpha, c.r, c.r, c.r, 0, true)
                renderer.gradient(screen.center.x + offset, screen.center.y, length, 1, c.r, c.g, c.b, c.a * alpha, c.r, c.r, c.r, 0, true)
            
            elseif menu.Features.scope.style.value == "Style: Cross" then
                local targetAngle = alpha * menu.Features.scope.dalbaeb.value  -- Преобразуем alpha в угол
                -- local targetAngle = alpha * globals.framecount()  -- Преобразуем alpha в угол
                currentAngle = utils.lerp(currentAngle or targetAngle, targetAngle, 0.05)
    

                
                local hihihaha = (menu.Features.scope.dalbaeb2.value and -1 or 1)
                offset = math.max(1, offset)
                local x1, y1 = screen.center.x + offset, screen.center.y + offset 
                local x2, y2 = screen.center.x + offset + length, screen.center.y + offset + length
                x2, y2 = rotate(x2, y2, screen.center.x, screen.center.y, currentAngle)
                x1, y1 = rotate(x1, y1, screen.center.x, screen.center.y, currentAngle * hihihaha)
                gradient_line(x1, y1, x2, y2, c.r, c.g, c.b, c.a * alpha, c.r, c.r, c.r, 0, 10)
    
                x1, y1 = screen.center.x - offset, screen.center.y - offset
                x2, y2 = screen.center.x - offset - length, screen.center.y - offset - length
                x2, y2 = rotate(x2, y2, screen.center.x, screen.center.y, currentAngle)
                x1, y1 = rotate(x1, y1, screen.center.x, screen.center.y, currentAngle * hihihaha)
                gradient_line(x1, y1, x2, y2, c.r, c.g, c.b, c.a * alpha, c.r, c.r, c.r, 0, 10)
    
                x1, y1 = screen.center.x + offset, screen.center.y - offset
                x2, y2 = screen.center.x + offset + length, screen.center.y - offset - length
                x2, y2 = rotate(x2, y2, screen.center.x, screen.center.y, currentAngle)
                x1, y1 = rotate(x1, y1, screen.center.x, screen.center.y, currentAngle * hihihaha)
                gradient_line(x1, y1, x2, y2, c.r, c.g, c.b, c.a * alpha, c.r, c.r, c.r, 0, 10)
    
                x1, y1 = screen.center.x - offset, screen.center.y + offset
                x2, y2 = screen.center.x - offset - length, screen.center.y + offset + length
                x2, y2 = rotate(x2, y2, screen.center.x, screen.center.y, currentAngle)
                x1, y1 = rotate(x1, y1, screen.center.x, screen.center.y, currentAngle * hihihaha)
                gradient_line(x1, y1, x2, y2, c.r, c.g, c.b, c.a * alpha, c.r, c.r, c.r, 0, 10)
            end
        end
    end
    
    

    menu.Features.scope.on:set_event('paint', render)
    menu.Features.scope.on:set_event('paint_ui', function()
        refs2.scope:override(true)
    end)
    menu.Features.zoom.on:set_callback(function(self)
        refs2.scope:set_enabled(not self.value)
        if not self.value then 
            refs2.scope:override()
        end
    end)
end

local zoom do
    local val = 0
    local animation = function()
        -- local button = (menu.Features.zoom.button:get() and menu.Features.zoom.third.value*0.5 or 0)
        -- local slider = menu.Features.zoom[( (menu.Features.zoom.mode.value == 'Mode: Single' and 'first') or lp.zoom == 1 and 'first' or 'second')].value*0.5
        -- val = utils.lerp(val, lp.entity and entity.is_alive(lp.entity) and (lp.scoped and (slider + (menu.Features.zoom.stack.value and button or 0)) or button) or 0, 45, 0.5)
        -- local orig = refs2.fov:get_original()
        -- local orig = 
        -- refs2.fov:override(math.max(orig - val,orig - math.floor(val)))
        -- refs2.zoom:override(0)
        
        local distance = menu.Features.zoom.distance.value
        local slider = not lp.scoped and 0 or menu.Features.zoom[( (menu.Features.zoom.mode.value == 'Mode: Single' and 'first') or lp.zoom == 1 and 'first' or 'second')].value
        val = utils.lerp(val, distance - distance * slider/100, 0.03)
        cvar.cam_idealdist:set_raw_float(val)
    end
    menu.Features.zoom.on:set_event('paint', animation)
    menu.Features.zoom.on:set_callback(function(self)
        -- refs2.zoom:set_enabled(not self.value)
        -- refs2.fov:set_enabled(not self.value)
        if not self.value then 
            cvar.cam_idealdist:set_raw_float(default.dist)
        end
    end)
    defer(function()
        cvar.cam_idealdist:set_raw_float(default.dist)

    end)
end

local aspectratio do
    local self = menu.Features.aspect
    local setup = function(val)
        cvar.r_aspectratio:set_raw_float((not self.on.value or self.ratio.value == 59 or not val) and 0 or self.ratio.value/100)
    end

    self.on:set_callback(setup, true)
    self.ratio:set_callback(setup)
    defer(setup)
end

local viewmodel do
    viewmodel = default.viewmodel
    local self = menu.Features.viewmodel
    local setup = function(val, name)
        if not val or not name then
            for a, b in pairs(viewmodel) do
                local el =  cvar['viewmodel_' .. (#a > 1 and a or 'offset_'..a)]
                el:set_raw_float(val and self.on.value and self[a].value / (#a == 1 and 10 or 1) or b)
            end
        elseif self.on.value then
            local a = cvar['viewmodel_' .. (#name > 1 and name or 'offset_'..name)]
            a:set_raw_float(self[name].value / (#name == 1 and 10 or 1))
        end
    end

    self.on:set_callback(setup, true)
    for name, val in pairs(viewmodel) do
        self[name]:set_callback(function(this)
            setup(this, name)
        end)
    end

    do
        local weapon_raw = ffi.cast('void****', ffi.cast('char*', client.find_signature('client_panorama.dll', '\x8B\x35\xCC\xCC\xCC\xCC\xFF\x10\x0F\xB7\xC0')) + 2)[0]
        local ccsweaponinfo_t = [[struct{
            char __pad_0x0000[0x1cd];
            bool hide_vm_scope;
        }]]
        local get_weapon_info = vtable_thunk(2, ccsweaponinfo_t .. '*(__thiscall*)(void*, unsigned int)')
        client.set_event_callback('run_command', function()
            if not lp.entity then return end
            local weapon = entity.get_player_weapon(lp.entity)
            if not weapon then return end
            get_weapon_info(weapon_raw, entity.get_prop(weapon, 'm_iItemDefinitionIndex')).hide_vm_scope = not (self.scope.value and self.on.value)
        end)

        defer(function()
            setup()
            if not lp.entity then return end
            local weapon = entity.get_player_weapon(lp.entity)
            if not weapon then return end
            get_weapon_info(weapon_raw, entity.get_prop(weapon, 'm_iItemDefinitionIndex')).hide_vm_scope = true
        end)
    end
    
end

local ragelogs do
    local data, hitlog = {}, {}
    local hitgroups = {'head', 'chest', 'stomach', 'left arm', 'right arm', 'left leg', 'right leg', 'neck', '?', 'gear', 'nil'}

    menu.Features.logs.on:set_event('aim_fire', function(e)  
        data.hitgroup = e.hitgroup
        data.damage = e.damage
        -- data.bt = e.backtrack
        data.bt = globals.tickcount() - e.tick
        data.lc = e.teleported
    end)

    local self = menu.Features.logs
    self.on:set_event('aim_miss', function(e)  
        local col = color(unpack(menu.Features.color[e.reason].color.value)) or color(255,255,255,255)
        if self.display:get("On Screen") then
            table.insert(hitlog, {"\f<col2> Miss \f<col>"..entity.get_player_name(e.target).."\f<col2>'s \f<col>"..hitgroups[e.hitgroup].."\f<col2> due to \f<col>"..e.reason, 
            globals.curtime() +  menu.Features.logs.time.value*.1, 0.1, nil, col})
        end
        if self.display:get("In Console") then
            col = (utils.to_hex(col)):sub(1,6)
            pui.macros.col = '\a'..col
            utils.printc(pui.format(
                "\f<r>[\f<col>+\f<r>] ~ Miss "..
                "\f<col>"..entity.get_player_name(e.target).."\f<r>'s "..
                "\f<col>"..(hitgroups[e.hitgroup] or "?")..
                "\f<r> due to \f<col>"..e.reason.."\f<r>"..
                (e.reason == 'spread' and "(\f<col>"..string.format('%.0f', e.hit_chance).."\f<r>%)" or '')..
                (data.bt ~= 0 and ' (\f<col>'..data.bt..'\f<r> bt)' or '')..
                (data.lc and ' (\f<col>LC\f<r>)' or '')
            ))
        end
    end)
    self.on:set_event('aim_hit', function(e)
        local col = utils.to_hex(color(unpack(menu.Features.color['hit'].color.value)) or color(255,255,255,255))
        if self.display:get("On Screen") then
            table.insert(hitlog, {
                "\f<col2> Hit \f<col>"..entity.get_player_name(e.target).."\f<col2>'s \f<col>"..(hitgroups[e.hitgroup] or '?').."\f<col2> for \f<col>"..e.damage.." \f<col2>dmg", 
                globals.curtime() +  menu.Features.logs.time.value*.1, 0.1, nil, color(unpack(menu.Features.color['hit'].color.value)) })
        end
        if self.display:get("In Console") then
            col = col:sub(1,6)
            pui.macros.col = '\a'..col
            local health = entity.get_prop(e.target, 'm_iHealth')
            utils.printc(pui.format(
                "\f<r>[\f<col>+\f<r>] ~ Hit "..
                "\f<col>"..entity.get_player_name(e.target).."\f<r>'s "..
                "\f<col>"..(hitgroups[e.hitgroup] or "?")..
                (e.hitgroup ~= data.hitgroup and "\f<r>(\f<col>"..hitgroups[data.hitgroup].."\f<r>)" or '')..
                "\f<r> for \f<col>"..e.damage.."\f<r>"..
                (e.damage ~= data.damage and "\f<r>(\f<col>"..data.damage.."\f<r>) dmg" or ' dmg')..
                (e.reason == 'spread' and "(\f<col>"..string.format('%.0f', e.hit_chance).."\f<r>%)" or '')..
                " \f<col>~"..
                (health <= 0 and ' \f<r>(\f<col>dead\f<r>)' or ' \f<r>(\f<col>'..health..'\f<r> hp)')..
                (data.bt ~= 0 and ' (\f<col>'..data.bt..'\f<r> bt)' or '')..
                (data.lc and ' (\f<col>LC\f<r>)' or '')
            ))
        end
    end)

    local render = function()
        if not self.display:get('On Screen') then return end
        if #hitlog > 0 then
            if hitlog[1][3] <= 0.07 or #hitlog > 7 then
                table.remove(hitlog, 1)
            end
            for i = 1, #hitlog do
                local curtime = globals.curtime()
                hitlog[i][3] = utils.lerp(hitlog[i][3], curtime >= hitlog[i][2] and 0 or 1, 0.03)
                hitlog[i][4] = not hitlog[i][4] and i * 50 or utils.lerp(hitlog[i][4], curtime >= hitlog[i][2] and i * -10 or (hitlog[i - 1] and curtime >= hitlog[i - 1][2] and i-1 or i) * 30, 0.035)

                local text_color = hitlog[i][5]:clone()
                pui.macros.col = '\a'..utils.to_hex(text_color:alpha_modulate(text_color.a * hitlog[i][3]))

                local text_color2 = color(255,255,255,100)
                pui.macros.col2 = '\a'..utils.to_hex(text_color2:alpha_modulate(text_color2.a * hitlog[i][3]))

                local text = pui.format(hitlog[i][1])
                local measure = vector(renderer.measure_text('d', text))
                local y = screen.size.y * 0.73 - (1 - hitlog[i][4])

                local c = colors['logs']['Background']
                utils.rectangle(
                        screen.center.x - math.floor(measure.x * 0.55), y - 3,
                        math.floor(measure.x * 0.55) * 2, measure.y + 7,
                        c.r,c.g,c.b,c.a * hitlog[i][3],
                        5
                )
                renderer.text(screen.center.x - measure.x * 0.5, y, 0,0,0,0, 'd', 0, text)
            end
        end
    end
    self.on:set_event('paint', render)
    client.set_event_callback('round_poststart', function()
        hitlog = {}
    end)
    self.on:set_callback(function(self)
        refs2.log_dealt:override(not self.value and nil or false)
        refs2.log_dealt:set_enabled(not self.value)
        refs2.log_spread:override(not self.value and nil or false)
        refs2.log_spread:set_enabled(not self.value)
    end, true)
end

-- local animations do
--     local native_GetClientEntity = vtable_bind('client.dll', 'VClientEntityList003', 3, 'void*(__thiscall*)(void*, int)')
--     local char_ptr = ffi.typeof('char*')
--     local nullptr = ffi.new('void*')
--     local class_ptr = ffi.typeof('void***')
--     local animation_layer_t = ffi.typeof([[
--         struct {										char pad0[0x18];
--             uint32_t	sequence;
--             float		prev_cycle;
--             float		weight;
--             float		weight_delta_rate;
--             float		playback_rate;
--             float		cycle;
--             void		*entity;						char pad1[0x4];
--         } **
--     ]])
    
--     local setup = function(e)
--         if not lp.entity or not entity.is_alive(lp.entity) then return end
    
--         local player_ptr = ffi.cast(class_ptr, native_GetClientEntity(lp.entity))
--         if player_ptr == nullptr then return end
    
--         local anim_layers = ffi.cast(animation_layer_t, ffi.cast(char_ptr, player_ptr) + 0x2990)[0]
    
--         if lp.on_ground then
--             refs.other.legmovement:override(
--                 menu.Features.animations.ground.value == "Default" and "Off" or 
--                 ((menu.Features.animations.ground.value == "Never slide" or menu.Features.animations.ground.value == "Always slide") and menu.Features.animations.ground.value) or 
--                 (menu.Features.animations.ground.value == "Jitter" and (globals.tickcount() % 11 <= 2 and "Always slide" or "Never slide")) or
--                 "Never slide"
--             )
--             if menu.Features.animations.ground.value == "Moonwalk" then 
--                 entity.set_prop(lp.entity, "m_flPoseParameter", 0.5, 7) 
--             end
    
--             if menu.Features.animations.extra:get("Landing Pitch") then
--                 local my_data = entity2(lp.entity)
--                 if my_data then
--                     local animstate = entity2.get_anim_state(my_data)
--                     if animstate then
--                         if animstate.hit_in_ground_animation then
--                             entity.set_prop(lp.entity, 'm_flPoseParameter', 0.5, 12)
--                         end
--                     end
--                 end
--             end 

--             if menu.Features.animations.extra:get("Disable Move Lean") then
--                 anim_layers[6]['weight'] = 0
--             end
--         else 
--             if menu.Features.animations.air.value == "Static" then 
--                 entity.set_prop(lp.entity, "m_flPoseParameter", 1, 6)
--             elseif menu.Features.animations.air.value == "Moonwalk" then
--                 anim_layers[6]['weight'] = 1
--             end
--         end
--     end
--     menu.Features.animations.on:set_event('pre_render', setup)
--     menu.Features.animations.on:set_callback(function(self)
--         if not self.value then
--             refs.other.legmovement:override("Off")
--         end
--     end)
-- end

local filter do
    menu.Features.console.on:set_callback(function(self)
        client.delay_call(0, function()
            cvar.con_filter_enable:set_int(self.value and 1 or 0)
            cvar.con_filter_text:set_string(self.value and 'Regicide ['..version[1] ..']' or '')
        end)
    end, true)
    defer(function()
        cvar.con_filter_enable:set_int(0)
        cvar.con_filter_text:set_string('')
    end)
end

local manuals do
    manuals = {
        {
            [menu.Antiaims.hotkeys.forward] = {
                state = false,
                yaw = "Forward",
            },
            [menu.Antiaims.hotkeys.left]  = {
                state = false,
                yaw = "Left",
            },
            [menu.Antiaims.hotkeys.right] = {
                state = false,
                yaw = "Right",
            },
        },
        {
            ["Forward"] = 180,
            ["Left"] = -90,
            ["Right"] = 90,
        },
        {
            ["Forward"] = {1,-70,"^"},
            ["Left"] = {-70,1,"<"},
            ["Right"] = {70,1,">"},
        },
    }
    local handle_manuals = function()
        for key, value in pairs(manuals[1]) do
            local state, m_mode = key:get()
            if state ~= value.state then
                value.state = state
                if m_mode == 1 then
                    lp.manual = state and value.yaw or nil
                end
    
                if m_mode == 2 then
                    if lp.manual == value.yaw then
                        lp.manual = nil
                    else
                        lp.manual = value.yaw
                    end
                end
            end
    
        end
    end
    client.set_event_callback('paint', handle_manuals)

    local alpha,x,y = 0,0,0
    local last = nil
    local this = nil
    local render = function()
        if not lp.entity or not entity.is_alive(lp.entity) then return end
        this = lp.manual
        last = this and this or last
        if not last then return end
        y = utils.lerp(y,this and manuals[3][last][2] or 0, 0.03)
        x = utils.lerp(x,this and manuals[3][last][1] or 0, 0.03)
        alpha = utils.lerp(alpha, this and math.sqrt( x^2 +y^2 )/math.sqrt( manuals[3][last][1]^2 +manuals[3][last][2]^2 ) * (alpha < 0.75 and 0.9 or 1) or 0, 0.03)
        if alpha <= 0.1 then return end
        local c = colors["manual"]['Color']
        renderer.text(screen.center.x+x-1, screen.center.y+y-1, c.r,c.g,c.b,c.a * alpha,'+cd',0,manuals[3][last][3]:upper())
    end
    menu.Features.manual.on:set_event('paint', render)
end

local exploit do
    exploit = { }
    exploit.def_aa = false
    local BREAK_LAG_COMPENSATION_DISTANCE_SQR = 64 * 64

    local max_tickbase = 0
    local run_command_number = 0

    local data = {
        old_origin = vector(),
        old_simtime = 0.0,

        shift = false,
        breaking_lc = false,

        defensive = {
            force = false,
            left = 0,
            max = 0,
        },

        lagcompensation = {
            distance = 0.0,
            teleport = false
        }
    }

    local function update_tickbase(me)
        data.shift = globals.tickcount() > entity.get_prop(me, 'm_nTickBase')
    end

    local function update_teleport(old_origin, new_origin)
        local delta = new_origin - old_origin
        local distance = delta:lengthsqr()

        local is_teleport = distance > BREAK_LAG_COMPENSATION_DISTANCE_SQR

        data.breaking_lc = is_teleport

        data.lagcompensation.distance = distance
        data.lagcompensation.teleport = is_teleport
    end

    local function update_lagcompensation(me)
        local old_origin = data.old_origin
        local old_simtime = data.old_simtime

        local origin = vector(entity.get_origin(me))
        local simtime = toticks(entity.get_prop(me, 'm_flSimulationTime'))

        if old_simtime ~= nil then
            local delta = simtime - old_simtime

            if delta < 0 or delta > 0 and delta <= 64 then
                update_teleport(old_origin, origin)
            end
        end

        data.old_origin = origin
        data.old_simtime = simtime
    end

    local function update_defensive_tick(me)
        local tickbase = entity.get_prop(me, 'm_nTickBase')

        if math.abs(tickbase - max_tickbase) > 64 then
            -- nullify highest tickbase if the difference is too big
            max_tickbase = 0
        end

        local defensive_ticks_left = 0

        -- defensive effect can be achieved because the lag compensation is made so that
        -- it doesn't write records if the current simulation time is less than/equals highest acknowledged simulation time
        -- https://gitlab.com/KittenPopo/csgo-2018-source/-/blame/main/game/server/player_lagcompensation.cpp#L723

        if tickbase > max_tickbase then
            max_tickbase = tickbase
        elseif max_tickbase > tickbase then
            defensive_ticks_left = math.min(14, math.max(0, max_tickbase - tickbase - 1))
        end

        if defensive_ticks_left > 0 then
            data.breaking_lc = true
            data.defensive.left = defensive_ticks_left

            if data.defensive.max == 0 then
                data.defensive.max = defensive_ticks_left
            end
        else
            data.defensive.left = 0
            data.defensive.max = 0
        end
    end

    function exploit.get()
        return data
    end

    local function on_predict_command(cmd)
        local me = entity.get_local_player()

        if me == nil then
            return
        end

        if cmd.command_number == run_command_number then
            update_defensive_tick(me)
            run_command_number = nil
        end
    end

    local function on_setup_command(cmd)
        local me = entity.get_local_player()

        if me == nil then
            return
        end

        update_tickbase(me)
    end

    local function on_run_command(e)
        run_command_number = e.command_number
    end

    local function on_net_update_start()
        local me = entity.get_local_player()

        if me == nil then
            return
        end

        update_lagcompensation(me)
    end

    client.set_event_callback('predict_command', on_predict_command)
    client.set_event_callback('setup_command', on_setup_command)
    client.set_event_callback('run_command', on_run_command)

    client.set_event_callback('net_update_start', on_net_update_start)
end

local antiaims do
    local antiaims = {
        pitch = {
            ['Random'] = function()
                return client.random_int(-89,89)
            end,
            ['Custom'] = function(e)
                return e.pitch_val:get()
            end,
            ['Progressive'] = function(e)
                return (utils.sine_yaw(globals.servertickcount() * e.pitch_speed.value * 0.1, e.pitch_min.value, e.pitch_max.value))
            end
        },
        yaw = {
            ['Sideways'] = function()
                return globals.tickcount() % 6 <= 2 and 90 or -90
            end,
            ['Sideways 45'] = function()
                return globals.tickcount() % 6 <= 2 and 45 or -45
            end,
            ['Spin'] = function(e)
                return utils.normalize_yaw(globals.servertickcount() * e.yaw_speed.value)
            end,
            ['Progressive'] = function(e)
                return (utils.sine_yaw(globals.servertickcount() * e.yaw_speed.value * 0.1, e.yaw_min.value, e.yaw_max.value))
            end,
            ['Random'] = function()
                return client.random_int(-180,180)
            end,
            ['Custom'] = function(e)
                return not e.yaw_invert and e.yaw_val:get() or e.yaw_val:get() + (e.yaw_invert:get() and 180 or 0)
            end,
            ['Yaw Opposite'] = function(yaw)
                return utils.normalize_yaw(yaw+180)
            end,
            ['Yaw Side'] = function(val)
                return val
            end
        }
    }
    local body_yaw,packets,offset,fl = 0,0,0,0
    local delay = {left=0,right=0,switch_ticks=0,work_side='left',switch=false}

    local setup = function(cmd)
        refs.fl.enabled:override( not (
            (menu.Antiaims.other.fl_disabler.value[1] == "Standing") and (lp.on_ground and not lp.moving) or
            (menu.Antiaims.other.fl_disabler.value[1] == "Crouch Move" or menu.Antiaims.other.fl_disabler.value[2] == "Crouch Move") and (lp.on_ground and lp.crouch and lp.moving)
        ) )

        -- if menu.Antiaims.other.unsafe.value then
        --     exploits:allow_unsafe_charge(true)
        -- end

        refs.aa.enabled:override(true)
        refs.aa.pitch:override('Minimal')
        refs.aa.yaw:override("180")
        refs.aa.roll:override(0)

        local aa = (lp.manual or menu.Antiaims.builder[lp.state].enabled.value) and menu.Antiaims.builder[lp.state] or menu.Antiaims.builder[condition_list[1]]

        refs.aa.yaw_base:override(aa.yaw.base.value)
        refs.aa.body:override(aa.body.yaw.value == "Jitter" and "Static" or aa.body.yaw.value)

        if globals.chokedcommands() == 0 then
            if aa.body.delay.mode.value == "Static" then
                packets = packets > aa.body.delay.delay.value * 2 - 2 and 0 or packets + 1
            else
                delay.switch_ticks = (aa.body.delay.switch.value == 0 and -1) or (delay.switch_ticks > aa.body.delay.switch.value - 2 and 0 or delay.switch_ticks + 1)
                if delay.switch_ticks == 0 then
                    delay.switch = not delay.switch
                else
                    delay.switch = (aa.body.delay.switch.value == 0 and false) or delay.switch
                end
                delay.work_side = (delay[delay.work_side] > ( aa.body.delay[(delay.switch and (delay.work_side == 'left' and 'right' or 'left') or delay.work_side)].value - 2 ) and (delay.work_side == 'left' and 'right' or 'left')) or delay.work_side
                delay[delay.work_side] = (delay[delay.work_side] > ( aa.body.delay[ (delay.switch and (delay.work_side == 'left' and 'right' or 'left') or delay.work_side) ].value - 2 )) and 0 or delay[delay.work_side] + 1
            end
        end
        local inverted = (function()
            if aa.body.yaw.value == 'Static' then 
                return aa.body.side.value == 1
            elseif aa.body.yaw.value == 'Jitter' then
                if aa.body.delay.mode.value == "Switch" then
                    return delay.work_side == 'right'
                else
                    return packets % (aa.body.delay.delay.value * 2) >= aa.body.delay.delay.value
                end
            end
        end)()

        local yaw_jitter = aa.jitter.type.value
        if yaw_jitter == "3-Way" or yaw_jitter == '5-Way' then
            offset = aa.jitter.ways[(globals.tickcount() % (yaw_jitter == '3-Way' and 3 or 5)) + 1].value
            yaw_jitter = 'Off'
            offset = client.random_int(offset-aa.jitter.rand.value, offset+aa.jitter.rand.value)
        else
            offset = 0
        end

        refs.aa.jitter:override(yaw_jitter ~= "Spin" and yaw_jitter or "Off")
        local jitter_val = 0
        if yaw_jitter ~= 'Off' then
            jitter_val = (
                aa.jitter.mode.value == "Spin" and utils.sine_yaw(globals.servertickcount(), aa.jitter.value2.value, aa.jitter.value.value) 
                or (aa.jitter.mode.value == "Random" and client.random_int(0,1) == 1 or 
                aa.jitter.mode.value == 'Switch' and globals.tickcount() % 6 <= 2) and aa.jitter.value2.value or aa.jitter.value.value
            )
            jitter_val = client.random_int(jitter_val-aa.jitter.rand.value, jitter_val+aa.jitter.rand.value)
        end
        refs.aa.jitter_val:override(utils.normalize_yaw(jitter_val))
        
        
        refs.aa.body_val:override(inverted and 1 or -1)
        local yaw = utils.normalize_yaw(
            lp.manual and manuals[2][lp.manual] + offset 
            or aa.yaw.global.value + (inverted and aa.yaw.right.value or aa.yaw.left.value) + offset
        )

        refs.aa.yaw_val:override(yaw)
        refs.aa.edge:override(menu.Antiaims.hotkeys.edge:get() and not lp.manual)
        refs.aa.fs:set_hotkey("Always On", 0)
        if menu.Antiaims.hotkeys.fs:get() and not lp.manual then
            refs.aa.fs:override(true)
            if menu.Antiaims.hotkeys.fs_disablers:get("Body Yaw") then refs.aa.body:override("Off") end
            if menu.Antiaims.hotkeys.fs_disablers:get("Yaw Jitter") then refs.aa.jitter:override("Off") end
        else
            refs.aa.fs:override(false)
        end
        if lp.state ~= condition_list[9] then
            if aa.defensive.force.value and not menu.Antiaims.other2.defensive:get("Force Def.") then
                cmd.force_defensive = true
            end
            if lp.flicking then
                cmd.force_defensive = cmd.command_number % 7 == 0
            end
            if (aa.defensive.enabled.value and not menu.Antiaims.other2.defensive:get("Def. AA") or lp.flicking) and not refs2.fd:get() then
                local this = lp.flicking and menu.Antiaims.other2.flick_aa or (aa.defensive.override and aa.defensive.override.value and aa or menu.Antiaims.builder[condition_list[1]]).defensive.settings
                local exp = exploit.get().defensive.left
                local work = exp ~= 0 and (lp.flicking or exp <= this.duration.value)
                exploit.def_aa = false
                if work then
                    exploit.def_aa = true
                    if this.disablers:get("Body Yaw") then refs.aa.body:override('Off') end
                    if this.disablers:get("Yaw Jitter") then refs.aa.jitter:override('Off') end
                    if this.pitch.value ~= "None" then
                        refs.aa.pitch:override('Custom')
                        refs.aa.pitch_val:override(antiaims.pitch[this.pitch.value](this))
                    end
                    local ezz = {
                        ['Yaw Opposite'] = yaw,
                        ['Yaw Side'] = lp.state == condition_list[10] and yaw + 180 or aa.yaw.global.value + (inverted and aa.yaw.left.value or aa.yaw.right.value)
                    }
                    if this.yaw.value ~= "None" then
                        refs.aa.yaw:override('180')
                        refs.aa.yaw_val:override(utils.normalize_yaw(antiaims.yaw[this.yaw.value](ezz[this.yaw.value] or this)))
                    end
                end
            end
        end

        if menu.Antiaims.other.avoid_backstab.value then
            local origin = vector(entity.get_origin(lp.entity))
            for _,v in ipairs(entity.get_players(true)) do 
                if entity.get_classname(entity.get_player_weapon(v)) == "CKnife" then
                    if origin:dist(vector(entity.get_origin(v))) <= 200 then
                        refs.aa.pitch:override("Off")
                        refs.aa.yaw:override('180')
                        refs.aa.yaw_val:override(180)
                        refs.aa.body:override('Opposite')
                    end
                end
            end
        end

    end
    client.set_event_callback("setup_command", setup)
    defer(function()
        refs.fl.enabled:override(nil)
        for _,ref in pairs(refs.aa) do
            ref:override(nil)
        end
    end)
end

local helper do
    helper = {
        ['Crosshair'] = function()
            return screen.center.x, screen.center.y
        end,
        ['Upper-Center'] = function()
            return screen.center.x, 0
        end,
        ['Bottom-Center'] = function()
            return screen.center.x, screen.size.y
        end,
        ['Local Player'] = function(id)
            local stomach_x, stomach_y, stomach_z = entity.hitbox_position(id, 3)
            return renderer.world_to_screen(stomach_x, stomach_y, stomach_z)
        end,
    }
    local render = function()
        if not lp.entity or not entity.is_alive(lp.entity) then return end
        local weapon_ent = entity.get_player_weapon(lp.entity)
        local weapon_idx = entity.get_prop(weapon_ent, "m_iItemDefinitionIndex")
        if weapon_idx == nil then return end
    
        for i, id in pairs(entity.get_players(true)) do
            local weapon = csgo_weapons[weapon_idx]

            local distance = vector(entity.get_prop(lp.entity, "m_vecAbsOrigin")):dist(vector(entity.get_prop(id, "m_vecOrigin")))
            local dmg_after_range = (weapon.damage * math.pow(weapon.range_modifier, (distance * 0.002)))
            local armor = entity.get_prop(id,"m_ArmorValue")
            local newdmg = dmg_after_range * (weapon.armor_ratio * 0.5)
            if dmg_after_range - (dmg_after_range * (weapon.armor_ratio * 0.5)) * 0.5 > armor then
                newdmg = dmg_after_range - (armor / 0.5)
            end
            local picked = (menu.Features.helper[(refs2.thirdperson.value and refs2.thirdperson:get_hotkey() and 'third' or 'first')].value):sub(14, 30)
            local stomach_x, stomach_y, stomach_z = entity.hitbox_position(id, 3)
            local wx, wy = renderer.world_to_screen(stomach_x, stomach_y, stomach_z)
            local wx2, wy2 = helper[picked](lp.entity)
            if wx and wy then
                if --[[(id == client.current_threat()) and]] not (entity.get_prop(id, "m_iHealth") >= newdmg * 1.25) then
                    local c = colors['helper']['Color']
                    renderer.line(wx2, wy2, wx,wy, c.r,c.g,c.b,c.a)
                end
            end
        end
    end
    menu.Features.helper.on:set_event("paint", render)
end

local tracer do
    tracer = {}
    local inserting = function(e)
        if client.userid_to_entindex(e.userid) == entity.get_local_player() then
            table.insert(tracer, {{client.eye_position()}, {e.x, e.y, e.z}, globals.curtime() + menu.Features.tracer.time.value * .1, 0.1})
        end
    end
    menu.Features.tracer.on:set_event('bullet_impact', inserting)

    local render = function()
        for id, data in pairs(tracer) do
            data[4] = utils.lerp(data[4], globals.curtime() >= data[3] and 0 or 1, 0.035)
            if data[4] < 0.08 then
                tracer[id] = nil
            end
            local x1, y1 = renderer.world_to_screen(data[1][1], data[1][2], data[1][3])
            local x2, y2 = renderer.world_to_screen(data[2][1], data[2][2], data[2][3])
            if x1 and x2 and y1 and y2 then
                local c = colors['tracer']["Color"]
                renderer.line(x1, y1, x2, y2, c.r,c.g,c.b,c.a*data[4])
            end
        end
    end
    menu.Features.tracer.on:set_event('paint', render)
end

local trashtalk do
    trashtalk = {
        kill = {1, {
{"нихуя се ты сочный....", "прям как алина:3"},
{"undetected since 2020 ☆"},
{"♘ ☇ 𝚜𝚌𝚘𝚘𝚝 𝚡 𝚔𝚡𝚘𝚗𝚡 𝚏𝚝 𝚛𝚘𝚐𝚒𝚌𝚒𝚍𝚎.𝚕𝚞𝚊 (◣◢) ✟"},
{"чмоня detected", "solution: dsc.gg/regicidelua"},
{"char pad_01[3] ¤*'~``~'* ft.【ＶＡＬＤＳＯＬＵＴＩＯＮＳ】"},
{"ⓁⒶⒸⒽⒷⓄⓂⒷ"},
{"KS OMK 3NDY OMK W A5TK TM9 ZBI"},
{"𝐦_𝐟𝐥𝐊𝐚𝐲𝐫𝐨𝐧𝐖𝐞𝐢𝐠𝐡𝐭 = 𝐈𝐍𝐓_𝐌𝐀𝐗"},
{"♛ 𝐫𝐞𝐠𝐢𝐜𝐢𝐝𝐞.𝐡𝐢𝐭 ♛"},
{"1", "?"},
{"ебаный ноулегенд из 2к25", "что ты делаешь?"},
{"✟ ♡ 𝑖 𝑤𝑖𝑙𝑙 𝑎𝑙𝑤𝑎𝑦𝑠 𝑏𝑒 𝑎ℎ𝑒𝑎𝑑 ♡ ✟"},
{"не отвечаю?", "мне похуй"},
{"сосал?", "соври", "не ври"},
{"пацаны не извиняются", "особенно перед пидорасом"},
{"норм играешь", "сын шлюхи"},
{"1", "мб regicide купишь?"},
{"loading cfg by kxanx 77% #pizdavam"},
{"OWNED BY LEGENDICK SQUAD ХУЕСОС"},
{"уебан ебаный", "куда ты выбежал?"},
{"это было настолько случайно, что даже твои родители не так удивились, когда ты родился"},
{"впенен бич via regicide.lua"},
{"ебанный бич", "почему ты сдох? оправдайся"},
{"луасенс не бустит - 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖 поможет сын шалавы"},
{"ты че мразота ? вздумал тягатся с 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖 юзером?"},
{"1 бот ты чо не вывез 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖 system aa"},
{"сын шлюхенции ты чет слабый для 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖"},
{"членом придавил тебя buy 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖"},
{"ЫВЗ9ГРШО4УГР9ЗУЦКЕНРТГЗ9 тупейший без 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖 :3"},
{"че ты опять хнычешь в чат, покупай 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖 и будь т1"},
{"чисто выебал бомжа без dsc.gg/regicidelua"},
{"убил бомжа без 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖"},
{"Только умные люди играют с 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖"},
{"почему я опять тя убил пидораса? У меня куплен 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖"},
{"Чё опять не попал да? купи 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖 терпила"},
{"братан, у меня 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖 с гм аа, соси хуй"},
{"am i him? yeah, i use regicide"},
{"stop slaving and buy regicide"},
{"you need regicide stupid kids"},
{"lord of missing is one, and its regicide"},
{"stop missing already, just be like me and get regicide"},
{"ru pastes destroyed from regicide source"},
{"『Y』『O』『U』『R』 『W』『I』『L』『L』 『I』『S』 『M』『I』『N』『E』"},
{"𝔾𝔼𝕋 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖 𝕐𝕆𝕌 𝔽𝔸𝔾"},
{"ｒｅｇｉｃｉｄｅ ｓｕｂ ｅｘｐｉｒｅ ＝ ｓｕｉｃｉｄｅ"},
{"𝚙𝚘𝚕𝚊𝚗𝚍 𝚙𝚊𝚜𝚝𝚎 𝚍𝚎𝚜𝚝𝚛𝚘𝚢𝚜 𝚏𝚛𝚘𝚖 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖.. (◣◢)"},
{"whatever you do, regicide.lua do it better ^^"},
{"куда пикаем?"},
{"e1"},
{"#финан$овыйтрэп"},
{"1"},
{"финансовый трэп"},
{"l2p bot"},
{'جدا الحمد لله أبي'},
{"ʀᴀᴢ ᴀᴅᴅᴇᴅ ᴛʜɪs ᴛᴏ ʀᴇɢɪᴄɪᴅᴇ sᴏᴜʀᴄᴇ ᴀɴᴅ ɪᴛ ᴍᴀᴅᴇ ɪᴛ sᴏ ᴍᴜᴄʜ ʙᴇᴛᴛᴇʀ"  },
{"ȶʏ ʄօʀ ʍ2 ƈօʍքɨӼɨօռ աɨȶɦ ȶɦɛ քօքֆ ǟռɖ ȶɦɛ ɮǟռɢֆ ʄȶ 𝔯𝔢𝔤𝔦𝔠𝔡𝔢 𝔩𝔬𝔞"},
{"百萬富翁買鬼 ツ"},
{"skeet invite code in morse: ... .-- ..-. -.-- -... .-- ..-. -... .--- --.. -... .-.. -.- .... ..-. .-.. -.- --. .. .-. .--. --. .-.. --.- --.- - -.-- .---- -..- . .-- -.- -.-- --.- ---.. .-.. .... ... ...- --.. -..- -.. .--. -..- -- -... - -.--"},
{'𝟜𝟝.𝟙𝟛𝟞.𝟚𝟘𝟝.𝟙𝟠𝟛:𝟙𝟛𝟛𝟟/𝕡𝕝𝕒𝕪𝕖𝕣𝕤.𝕛𝕤𝕠𝕟 𝓬𝓽𝓻𝓵+f "𝖎𝖘𝖘𝖔 𝖋𝖔𝖎 𝖉𝖔𝖕𝖊, 𝖌𝖆𝖓𝖉𝖆 𝖙𝖔𝖖𝖚𝖊'},
{"🕯️⧚🎃⧚🔮 ƙąYRཞơŋ ῳıƖƖ ƈơơ℘ ʂ℘ıɛƖɛŋ 🔮⧚🎃⧚🕯️"},
{"yesterday i got smoked by (っ◔◡◔)っ ιвιzα 6ℓ 1.9 т∂ι 160 ¢υρяα 2004 160 нρ / 118 кω 1896 ¢м3 (115.7 ¢υ-ιи)"},
{"yt bot"},
{"sleep"},
{"видно ты без regicide.lua сидишь, пора бы обновляться сосик)"},
{"сразу видно кфг исуе мб кфг у кханокса купиш?"},
{"видно натренированный ротик", "без regicide.lua сидишь?"},
{"фу сидишь без regicide.lua в 2к25?"},
{"в следуйщий раз заходи с 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖.𝕙𝕚𝕥 чтобы не позорится"},
{"t1"},
{'1'},
{"1", "теперь думай кто это написал)))"},
{"𝐫𝐞𝐠𝐢𝐜𝐢𝐝𝐞.𝐡𝐢𝐭。 技术多功能LUA脚本"},
{"ʙʏ ʙᴜʏɪɴɢ ʀᴇɢɪᴄɪᴅᴇ.ʜɪᴛ, ʏᴏᴜ'ʀᴇ ʙᴜʏɪɴɢ ᴀ ᴛɪᴄᴋᴇᴛ ᴛᴏ ʜᴇʟʟ."},  
{"The Flame will never die, for I am REGICIDE"},
{"☾ 𝕘𝕖𝕥 **𝕖𝕕 𝕓𝕪 𝕕𝕖𝕧𝕚𝕝 #𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖.𝕙𝕚𝕥 ~ 𝕟𝕖𝕥𝕨𝕠𝕣k ☾"},
{"твоя сила – лишь иллюзия перед властью regicide.hit."},
{"теперь сам Дьявол объявил на тебя охоту #𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖.𝕙𝕚𝕥 ☾"},
{"#𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚 𝙘𝙤𝙙𝙚 𝙬𝙖𝙨 𝙬𝙧𝙞𝙩𝙩𝙚𝙣 𝙗𝙮 𝐵𝓁𝑜𝑜𝒹 𝑜𝒻 𝐿𝓊𝒸𝒾𝒻𝑒𝓇 ٩(×̯×)۶"},
{"опять слезы? умоляй моих дьяволов выдать тебе regicide"},
{"это не битва, это исповедь, regicide выслушает все твои грехи."},
{"𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖.𝕙𝕚𝕥 𝕚𝕤 𝕥𝕙𝕖 𝕓𝕖𝕤𝕥 𝔸𝔸 𝔸𝔸 𝔸𝔸 𝔸𝔸 𝔸𝔸 𝔸𝔸 𝔸"},
{"♆ Сливы Дьяволиц -> 𝕕𝕤𝕔.𝕘𝕘/𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖𝕝𝕦𝕒 ♆"},
{"𝕟𝕠 𝕤𝕜𝕚𝕝𝕝 𝕟𝕖𝕖𝕕 𝕛𝕦𝕤𝕥 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖.𝕙𝕚𝕥"},
{"Это не борьба за выживание, это жертва regicide.", "1"},
{"𝕘𝕠𝕕 𝕘𝕒𝕧𝕖 𝕞𝕖 𝕡𝕠𝕨𝕖𝕣 𝕠𝕗 𝕣𝕖𝕫𝕠𝕝𝕧𝕖𝕣 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖.𝕙𝕚𝕥"},
{"っ◔◡◔)っ ♥️ enjoy die to regicide.hit and spectate me ♥️"},
{"𝕚 𝕒𝕞 𝕚𝕥”𝕤 𝕕𝕠𝕟𝕥 𝕝𝕠𝕤𝕖 ◣◢ #regicide"},
{"god may forgive you but regicide resolver wont (◣_◢)"},
{"𝕓𝕪 𝕤𝕚𝕘𝕟𝕚𝕟𝕘 𝕒 𝕔𝕠𝕟𝕥𝕒𝕔𝕥 𝕨𝕚𝕥𝕙 𝕥𝕙𝕖 𝕕𝕖𝕧𝕚𝕝 𝕪𝕠𝕦 𝕒𝕣𝕖 𝕕𝕠𝕠𝕞𝕖𝕕 𝕥𝕠 𝕕𝕚𝕖 #regicide"},
{"ＹＯＵ ＷＩＳＨ ＹＯＵ ＨＡＤ R E G I C I D E Ｕ ＨＲＳＮ"},
{"𝙙𝙖𝙮 666 𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚.𝙝𝙞𝙩 𝙨𝙩𝙞𝙡𝙡 𝙣𝙤 𝙧𝙞𝙫𝙖𝙡𝙨"},
{"once this game started 𝔂𝓸𝓾 𝓵𝓸𝓼𝓮𝓭 𝓪𝓵𝓻𝓮𝓭𝔂 #regicide"},
{"ＹＯＵ ＨＡＤ ＦＵＮ ＬＡＵＧＨＩＮＧ ＵＮＴＩＬ ＮＯＷ"},
{"family-friendly lua -> dsc.gg/regicidelua"},
{"The Flame will never die, for I am REGICIDE.HIT"},
{"если бы IQ был оружием", "ты бы ходил с палкой"},
{"𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚.𝙝𝙞𝙩 𝙥𝙧𝙚𝙢𝙞𝙪𝙢 𝙥𝙧𝙚𝙙𝙞𝙘𝙩𝙞𝙤𝙣 𝙩𝙚𝙘𝙝𝙣𝙤𝙡𝙤𝙜𝙞𝙚𝙨 ◣_◢"},
{"снова палю в экран", "снова вижу этот дискорд dsc.gg/regicidelua"},
{"мы летим низко ", "в башке храню все dsc.gg/regicidelua"},
{"1", "теперь думай кто это написал)))"},
{"REGICIDE SEASON ON TRƱE #BLIXXEN AND #EVIL RADIO vibe 2025™"},
{"winning not possibility, sry #regicide"},
{"ХА-ХА-ХА ! ака. НИЧЕ! (финансовый трэп)  DATA404"},
{"★★★ 𝔾𝕖𝕋 𝔾𝕠𝕠𝔻 ★★★"},
{"♛ 𝟓𝟎𝟎$ 𝐋𝐔𝐀 𝐉𝐈𝐓𝐓𝐄𝐑 𝐅𝐈𝐗? 𝐋𝐈𝐍𝐊 𝐈𝐍 𝐃𝐄𝐒𝐑𝐈𝐏𝐓𝐈𝐎𝐍"},
{"𝙒𝘼𝙉𝙉𝘼 𝘽𝙀 𝙇𝙄𝙆𝙀 𝙈𝙀? 𝙂𝙀𝙏 @𝙍𝙀𝙂𝙄𝘾𝙄𝘿𝙀.𝙃𝙄𝙏"},
{"твоя смерть так же горяча как алина(◣_◢)"},
{"щас после бухла реабилитируюсь"},
{"твоя мама любит писюньчики легендиков"},
{"♛ @𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚.𝙝𝙞𝙩 ♛"},
{'𝕀𝕊 𝕄𝕐 𝕃𝕌𝔸 𝔹𝔸𝔻? 𝕌 𝕁𝕌𝕊𝕋 ℍ𝔸𝕍𝔼ℕ𝕋 𝕄𝕆ℕ𝔼𝕐'},
{"☆꧁✬◦°˚°◦. ɛʐ .◦°˚°◦✬꧂☆"},
{"𝙊𝙂 𝙐𝙎𝙀𝙍 𝙑𝙎 𝙒𝘼𝙇𝙆𝘽𝙊𝙏𝙎"},
{"忧郁[𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚.𝙝𝙞𝙩]摧毁一切!"},
{"𝐀𝐋𝐋 𝐌𝐘 𝐇𝐎𝐌𝐈𝐄𝐒 𝐔𝐒𝐄 @𝙍𝙀𝙂𝙄𝘾𝙄𝘿𝙀.𝙃𝙄𝙏"},
{"♠️ 𝐆𝐎𝐃 𝐁𝐋𝐄𝐒𝐒 𝙍𝙀𝙂𝙄𝘾𝙄𝘿𝙀.𝙃𝙄𝙏 ♠"},
{"𝙩𝙧𝙮 𝙝𝙞𝙩 𝙢𝙮 𝙢𝙚𝙩𝙖 𝙖𝙣𝙩𝙞𝙖𝙞𝙢𝙨"},
{"♛𝐦𝐁𝐎𝐏𝐦𝐦𝟎𝟓𝐑𝐔𝐒♛"},
{"ｏｕｔｌａｗ？ ｎｏ ｒｅｇｉｃｉｄｅ"},
{"𝙉𝙄𝘾𝙀 𝙍𝙀𝙎𝙊𝙇𝙑𝙀𝙍 𝙃𝘼𝙃𝘼𝙃𝘼"},
{"☆꧁✬◦°˚°◦. ɮʏ ɮɛֆȶ ʟʊǟ .◦°˚°◦✬꧂☆"},
{"♠️ 𝙋𝙔𝘾𝘾𝙆𝙐𝙀 𝘽𝙊𝙋𝙗𝙡 ♠"},
{"𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖.𝕙𝕚𝕥 ḋöṁïṅäẗëṡ ḧṿḧ ṡċëṅë"},
{"𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚.𝙝𝙞𝙩 𝙥𝙧𝙚𝙢𝙞𝙪𝙢 𝙥𝙧𝙚𝙙𝙞𝙘𝙩𝙞𝙤𝙣 𝙩𝙚𝙘𝙝𝙣𝙤𝙡𝙤𝙜𝙞𝙚𝙨 ◣◢"},
{"✵•.¸,✵°✵.｡.✰ 𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚 ✰.｡.✵°✵,¸.•✵"},
{"я нᴇ могʏ бᴇз тᴇбя жить... 𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚♛"},
{"с ᴋᴀждыᴍ фpaгᴏм я ближᴇ к 𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚♛"},
{"♛ 𝙍𝙀𝙂𝙄𝘾𝙄𝘿𝙀 𝐈𝐓𝐒 𝐆𝐑𝐄𝐀𝐓𝐄𝐒𝐓 𝐋𝐔𝐀 ♛"},
{"REBELLION DONT PREDICT THIS | REGICIDE"},
{'V Ы E B A N B Y regicide.hit'},
{"𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚.𝙝𝙞𝙩 𝙥𝙧𝙚𝙢𝙞𝙪𝙢 𝙥𝙧𝙚𝙙𝙞𝙘𝙩𝙞𝙤𝙣 𝙩𝙚𝙘𝙝𝙣𝙤𝙡𝙤𝙜𝙞𝙚𝙨 ◣◢"},
{" $$$ 1 TAP UFF YA  $$$ ∩ ( ͡⚆ ͜ʖ ͡⚆) ∩"},
{'.::НоВоСиБиРсК::.'},
{"♥𝙍𝙀𝙂𝙄𝘾𝙄𝘿𝙀 𝘼𝙉𝙏𝙄-𝘼𝙄𝙈𝘽𝙊𝙏 𝘼𝙉𝙂𝙇𝙀𝙎♥"},
{"LX IXL D4RK IXL V K1NG DMN XUL"},
{"₲_₲"},
{"✧･ﾟ: ✧･ﾟ: 𝗥𝗘𝗚𝗜𝗖𝗜𝗗𝗘.𝗟𝗨𝗔 :･ﾟ✧:･ﾟ✧"},
{"▞▚▟▙ 𝚛𝚎𝚐𝚒𝚌𝚒𝚍𝚎.𝚑𝚒𝚝 ▜▙▚▞"},
{"『𝚁』『𝙴』『𝙶』『𝙸』『𝙲』『𝙸』『𝙳』『𝙴』『.』『𝙻』『𝚄』『𝙰』"},
{"ⓈⒸⓄⓄⓉⓋⒾⓇⓊⓈⓋⒺⓇⓈⒾⓄⓃ 𝟚𝟘𝟚𝟝"},
{"𝚜𝚢𝚜𝚝𝚎𝚖_𝚘𝚟𝚎𝚛𝚛𝚒𝚍𝚎: 𝚛𝚎𝚐𝚒𝚌𝚒𝚍𝚎_𝚖𝚘𝚍𝚎"},
{"♛𝓡𝓮𝓰𝓲𝓬𝓲𝓭𝓮.𝓵𝓾𝓪 𝓸𝓾𝓽𝓼𝓱𝓲𝓷𝓮 𝓮𝓷𝓮𝓶𝔂𝓲𝓼♛"},
{"☾ 𝕘𝕖𝕥 𝕗𝕦𝕔𝕜𝕖𝕕 𝕓𝕪 #𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖.𝕝𝕦𝕒 𝕣𝕖𝕤𝕠𝕝𝕧𝕖𝕣 ☾"},
{"≽^• ˕ • ྀི≼ ᴋᴀᴋ ᴛы уʍᴇᴩ? ᴀ ᴛочно я жᴇ ᴄ 𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚.𝙝𝙞𝙩"},
{"★ знᴀᴇɯь, ᴋоᴦдᴀ ʙидиɯь чᴇᴧоʙᴇᴋᴀ бᴇз 𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚 ʍᴇня ᴛоɯниᴛ"},
{"dont even try to kill me next time"},
{"whatever you do, regicide.lua do it better ^^"},
{"zero chance to kill regicide.lua user **"},
{'regicide.lua > all world'},
{"i break rules ft. regicide.hit"},
{"𝕟𝕠 𝕤𝕜𝕚𝕝𝕝 𝕟𝕖𝕖𝕕 𝕛𝕦𝕤𝕥 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖"},
{"Estk came to my door last night and said regicide best ◣◢ I say ok king 👑"},
{"∩ ( ⚆ ʖ ⚆) ∩ ДоПрыГался(ت)ДрУжоЧеК"},
{"·٠●•۩۞۩ОтДыХаЙ (ٿ) НуБяРа۩۞۩•●٠·"},
{"󠃐whatever you do, regicide.lua do it better ^^"},
{"ᴧюди ᴛᴏжᴇ ᴄᴛᴩᴀдᴀюᴛ, ᴏᴛᴛᴏᴦᴏ, чᴛᴏ у них нᴇᴛ 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖.𝕙𝕚𝕥"},
{"бᴇднᴏʍу нужᴇн ʍиᴧᴧиᴏн, бᴏᴦᴀᴛᴏʍу нужᴇн 𝕣𝕖𝕘𝕚𝕔𝕚𝕕𝕖.𝕙𝕚𝕥"},
{"𝟙𝕟𝕖𝕕 𝕒𝕘𝕒𝕚𝕟 𝓫𝔂 𝓻𝓮𝓰𝓲𝓬𝓲𝓭𝓮.𝓱𝓲𝓽"},
{"| 𝑾𝒆𝒍𝒄𝒐𝒎𝒆 𝒕𝒐 𝒓𝒆𝒈𝒊𝒄𝒊𝒅𝒆.𝒉𝒊𝒕 |"},
{"𝙞 𝙙𝙤𝙢𝙞𝙣𝙖𝙩𝙚 𝙩𝙝𝙚 𝙜𝙖𝙢𝙚 𝙬𝙞𝙩𝙝 𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚.𝙡𝙪𝙖"},
{"your death sponsored by @regicide.hit"},
{"𝙗𝙚𝙣𝙪𝙩𝙯𝙚 𝙙𝙖𝙨 𝙪𝙧𝙨𝙥𝙧ü𝙣𝙜𝙡𝙞𝙘𝙝𝙚 𝙨𝙠𝙧𝙞𝙥𝙩"},
{"☆꧁✬◦°˚°◦. ɮʏ ɮɛֆȵ ʟʊǟ .◦°˚°◦✬꧂☆"},
{"если бы IQ был оружием", "ты бы ходил с палкой"},
{"моя сила regicide", "что брикаю лцшечку"},
{"снова палю в экран", "снова вижу этот дискорд", "dsc.gg/regicidelua"},
{"мы летим низко ", "в башке храню все dsc.gg/regicidelua"},
{"1", "теперь думай кто это написал)))"},
{"REGICIDE SEASON ON TRƱE #BLIXXEN AND #EVIL RADIO vibe 2025™"},
{"rockstar life style #regicide"},
{"winning not possibility, sry #regicide"},
{"лови тапыча хуесос"},
{"е1"},
{"𝑹𝒆𝒈𝒊𝒄𝒊𝒅𝒆 [𝒈𝒐𝒅𝒎𝒐𝒅𝒆] 𝒆𝒏𝒂𝒃𝒍𝒆𝒅"},
{"𝗶 𝘂𝘀𝗲 𝑹𝒆𝒈𝒊𝒄𝒊𝒅𝒆 𝘄𝘁𝗳"},
{"не будь терпилой и переходи на темную сторону *REGICIDE.LUA VS ALL NN'S DOGS"},
{"𝚢𝚘𝚞 𝚘𝚠𝚗𝚎𝚍 𝚋𝚢 𝚛𝚎𝚐𝚒𝚌𝚒𝚍𝚎.𝚕𝚞𝚊"},
{"ｏｕｔｌａｗ？ ｎｏ 𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚"},
{"get rekt no sweat, you’re dropped by 𝑹𝒆𝒈𝒊𝒄𝒊𝒅𝒆 scum"},
{"ебанный хуесос, который раз ты лежишь в ногах юзера 𝑹𝒆𝒈𝒊𝒄𝒊𝒅𝒆?"},
{"1"},
{"ё1"},
{"t1"},
{"1", "сиди ", "грызи дальше семечки", "хуйня грязная"},
{"я призываю свою BlÏxxêñ gang все с regicide.lua были"},
{'1 мразота'},
{'хааххаха','опять умер'},
{'1','оправдайся','почему ты опять умер'},
{"1",'отлетаешь','сын бляди'},
{"1",'куда бежиш червяк'},
{"1",'опять забайтился мусор'},
{'HAHAHAHAHHAHA','1 ДЕРЕВО ЕБАННОЕ'},
{"1",'и это игрок?'},
{"1",'игрок?'},
{"1",'улетаешь со своего ванвея','хуесос'},
{"1",'лови в пиздак мразота'},
{'1','?','чурбек ебаный куда летим'},
{"1",'поймал в шляпу?'},
{'депортирован в ад к матери шлюхе'},
{'1','ахаха','спать шлюшка'},
{'сука не позорься и ливни лол'},
{'пикнул?','сиди и наблюдай теперь чмо'},
{'1','пора ливать','чмошница'},
{"1",'куда ты пикаешь то','скряга ебаная'},
{'парашыч ебанный'},
{"☆꧁✬◦°˚°◦. ɮʏ ɮɛֆȶ ʟʊǟ .◦°˚°◦✬꧂☆"},
{"𝙔𝙤𝙪𝙧 𝙙𝙚𝙖𝙩𝙝 𝙬𝙖𝙨 𝙨𝙥𝙤𝙣𝙨𝙤𝙧𝙞𝙧𝙚𝙙 𝙗𝙮 @𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚"},
{"𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚 𝙬𝙞𝙡𝙡 𝙖𝙡𝙬𝙖𝙮𝙨 𝙗𝙚 𝙖𝙝𝙚𝙖𝙙"},
{"𝙨𝙘𝙧𝙞𝙥𝙩 𝙙𝙚 𝙖𝙡𝙩𝙖 𝙘𝙖𝙡𝙞𝙙𝙖𝙙 * 𝙧𝙚𝙜𝙞𝙘𝙞𝙙𝙚 *"},
{"𝐇𝐞𝐲, 𝐢 𝐛𝐢𝐝 𝟓𝟎𝟎𝟎$ 𝐨𝐧 𝐲𝐨𝐮𝐫 𝐧𝐮𝐦𝐛𝐞𝐫 𝟖𝟖𝟖"},
{"𝐔 𝐭𝐞𝐛𝐲𝐚 𝐳𝐚𝐥𝐞𝐭!"},
{"𝕙𝕒𝕤𝕤𝕖 𝕖𝕤 𝕠𝕕𝕖𝕣 𝕝𝕚𝕖𝕓𝕖 𝕖𝕤."},
{"𝟒𝟐𝟗𝟓𝟑𝟎𝟓𝟔𝟗𝟓𝟑𝟔𝟑𝟐𝟗𝟒 𝐋𝐨𝐜𝐚𝐭𝐢𝐨𝐧: 𝐀𝐮𝐬𝐭𝐫𝐚𝐥𝐢𝐚"},
{"₳₦₲ɆⱠł₵ ₴₵Ɽł₱₮ ₣ØⱤ ₮ⱧɆ ₮ⱤɄɆ ฿ⱤØ₮ⱧɆⱤⱧØØĐ"},
{"₮ⱧɆ ₥ØØ₦Ⱡł₲Ⱨ₮ ₴₵ⱤɆ₳₥"},
{"𝙀𝙕 𝙈𝘼𝙋𝘼【１６－０】"},
{"₦_₦"},
{"𝚕𝚞𝚊𝟻.𝟹: 𝚛𝚎𝚐𝚒𝚌𝚒𝚍𝚎_𝚟𝟸(𝚏𝚊𝚝𝚊𝚕=𝚝𝚛𝚞𝚎)"},
{'𝐯𝐞𝐧𝐢 𝐯𝐢𝐝𝐢 𝐯𝐢𝐜𝐢'},
{'𝕤𝕔𝕙𝕝𝕒𝕗 𝕧𝕖𝕣𝕕𝕒𝕞𝕞𝕥𝕖𝕤 𝕒𝕣𝕤𝕔𝕙𝕝𝕠𝕔𝕙'},
{"𝔸ℕ𝕋𝕀-ℙℍ𝕆𝕋𝕆𝔾ℝ𝔸ℙℍ 𝕄𝕆𝔻𝔼 𝔼ℕ𝔸𝔹𝕃𝔼𝔻"},
{'ｗｈａｔ ａｒｅ ｕ ｄｏｉｎｇ ｄｏｇ'},
{"𝐉𝐥𝐨𝐫 𝐁𝟔𝐮𝐁𝐚𝐞𝐓 @𝐌𝐮𝐫𝐢𝐧𝐨𝐓"},
{"ｓｋｅｅｔ ｄｏｎｔ ｎｅｅｄ ｕｐｄａｔｅ (◣_◢)"},
{"𝙈𝙚𝙩𝙖𝙬𝙖𝙮𝙞𝙣𝙜 𝙧𝙣... 𝙘𝙖𝙣𝙩 𝙧𝙚𝙥𝙡𝙮"},
{'𝙜_𝙂 𝘽𝙤𝙏'},
{"We are pleased to inform you that your item has been successfully purchased!"},
{"𝐎𝐰𝐍𝐞𝐃𝐛𝐲𝐂𝐞𝐏𝐞𝐫𝐀𝐊𝐚𝐏𝐚𝐂𝐛𝟏𝟗𝟗𝟔"},
{'𝕨𝕙𝕪 𝕪𝕠𝕦 𝕤𝕠 𝕓𝕒𝕕? 𝕘𝕠 𝕡𝕝𝕒𝕪 𝕃𝕖𝔾𝕚𝕋'},
{"𝐘𝐨𝐮 𝐧𝐞𝐞𝐝 𝐭𝐨 𝐩𝐚𝐬𝐬 𝐚𝐧 𝐀𝐌𝐋 𝐜𝐡𝐞𝐜𝐤"},
{'понадеялся на удачу?'},
{'зря ты так летишь','у тебя ноль шансов убить меня'},
{'1','как на этот раз оправдаешься?'},
{'1','забайтилось тупое'},
{'норм луа у тебя братуха'},
{'1','DEAD',"ахахах"},
{'1','hs bot'},
{'1','спать чюрка'},
{'1','грязная хуйня'},
{"лол чел кринж", "щас моя братва с BlÏxxêñ залетит", "и пизда тебе и твоим антипападайкам"},
{'t1'},
{'е1'},
{'1'},
{'1','?'},
{"ʍиниᴄᴛᴇᴩᴄᴛʙо ᴨо боᴩьбᴇ ᴄ бᴧᴀᴦоᴨоᴧучиᴇʍ"},
{"тк ну и не открывай ротик", "хуесос", "лучше иди луашку мою купи dsc.gg/regicidelua"},
{"лол да даже пз тебя переиграет лолек","иди луашку (regicide) прикупи"},
{"говоришь чит миссает иди купи sm_metan #regicide"},
{"АЛо бомж да тебе даже sm_metan не поможет лол"},
{"ХВАТИТь пукать говно тупое иди убейся нахуй", "иди зайди в мой лучший дискорд - dsc.gg/regicidelua"},
{"ЧЕ замкдышь без @regicide в 2025?"},
{"Убили?", "Значит переиграли"},
{"если твои успехи в игре перевести в реальные достижения","ты бы был миллионером… в минусах"},
{"лол убил купи regicide", "dsc.gg/regicidelua"},
{"сасешь мне без регицайда ору"},
{"отсасываешь мне щас без регицайда"},
        }},
        death = {1, {
            {"сука хуесос","нахуй ты тут сидиш потеешь","выйди в кд грязь"},
            {"ну хуесос","что ты сделал"},
            {"сын шлюхи", "1x1 2x2 прям сейчас?"},
            {"хуесос","на подпике"},
            {"хуя"},
            {"хуесос","пытайся дальше"},
            {"не","как эьа хуйня убивает","это пиздец"},
            {"м","забавно"},
            {"ебанат","фулл опен стоит"},
            {"ну как оно меня убивает","ну что это такео"},
            {"опять","меня убивает", "тупорылый","фу блять"},
            {"ишак","куда ты так"},
            {"ну фу","что ты делаеш"},
            {"сын шлюхи","1х1 2х2 прям щас?"},
            {"уебище","нахуй ты сидишь потеешь","уебок ебаный"},
            {"блядт мусор господи","не ливай нахуй щас ты хуй сосать пойдёшь","бич бля"},
            {"о боже сука","снова лишний вес планеты убил"},
            {"мда"},
            {"сыну бляди же повезет"},
            {"ну фу","как меня хуйня","прыщавая убивает"},
            {"глупый даун","после некст раунда можешь с жизни ливать"},
            {"убил меня?","теперь сиди и жди","хуесос нищий"},
            {"csy","сын шлюхи","ттупой"},
            {"не","этот сочник пикнет"},
            {"отмена", 'сын шлюхи', 'что ты делаешь'},
            {"ну", 'что ты делашеь'},
            {"не ожидал что ты настолько тупорылый", 'запишу тебя в тетрадь сочников'},
            {'красава', 'лучший просто'},
            {'мразота потеет'},
           {'уебище','сидит потеет'},
           {"я еду в австрию", "бить эзотерику ебало"},
         {'отмена','сын шлюхи'},
         {'ну конечно','я просто похлопаю тебе'},
         {'пошли 1х1 сын блядоты','дс опрокинь свой'},
         {'блядина','нахуй ты сидишь потееш','выйди в кд грязб'},
        {'щас поиграем клоун','ливнешь мать шалава здохнет'},
         {'фу','ну он же байтится','и както убивает меня'},
         {'отмена','сын шлюхи'},
         {'хаахахах','что ты нахуй делаешь'},
        {'фу'},
         {'нет','хуесос тупой'},
         {'опять','меня убивает','тупорылый','фу блять'},
         {'без пота слабо хуйня?'},
         {'мразота потеет'},
         {'фу уебище ебаное'},
        {'я стрельнул?'},
         {'изи мапа'},
        {'м','забавно'},
        {'ну','что ты дулаешь'},
         {'ебанат','фулл опен стоит'},
          {'тупой','куда ты летишь идиот'},
        {'ну конечно','я просто похлопаю тебе'},
         {'не ливай'},
        {'сыну бляди же повезёт'},
         {'опять чмо ебаное убивает'},
         {'ну фу','тебе повезло выблядок'},
         {'ну фу','что ты делаеш'},
         {'подловила мразь'},
         {'не','как эьа хуйня убивает','это пиздец'},
         {'не','этот сочник пикнет'},
         {'csy','сын шлюхи','тупой'},
         {'что ты сделал','тупой даун','безмозглый'},
{',kznm','тупой долбаеб','реально','уебище'},
{'csy ik.[b','сын бляди ебаной','потеет сидит'},
{'хуя','норм бектрек'},
{'пиздец','что с читом'},
{'красава','лучший просто'},
{'ну','долбаеб сука','что ты делаешь мразь'},
 {"найс хуесос", "по iq играешь"},
{'ты добился результата', 'но это не конец'},
{"тупой даун", "что ты сделал?"},
{"пошли 2х2 сын бляди", "дс кидай чмо ебаное"},
{"пошли 1x1", "дс кидай уебан"},
 {",kznm", "что ты делаешь тупое"},
{"CERF", "что ты сделал хуесос"},
{"блять", "наконец оно меня убило"},
{"не ожидал что ты такой тупой", "запишу тебя в тетрдаь далбаебов"},
 {"я не могу в тебя попасть", "сделаешь мне такие же пресетики?"},
{"ну долбоеб сука", "ЧТО ТЫ ДЕЛАЕШЬ БЛЯДИНА"},
{"чит же видет", "какой он бездарный и дает шанс этому пидорасу"},
{"так держать", "сын шлюхенции"},
{"ну блять", "как оно убивает меня"},
{"признаю переиграл"},
{"ну хуесос", "на подпике стоит"},
{"в этом раунде регицайдик не прокерил","значит прокерит в следующем"},
{"какой же ты хуевый","НУ Я МИССАЮ ЕМУ В РУКУ А ОН ДУМАЕТ","ЧТО ЭТО ЛЦ"},
{"сын шлюхи ебаной","я просто не знаю как тебя ещё назвать"},
{"ну как ты мои антиаимы тапаешь в регицайде??", "че ебу дал"},
{"ну он же реально","подрывает себя","и я не могу попасть"},
{"опять говно убивает","я просто не могу уже"},
{"ты че ваще далбаеб?","я твою мать ебал","тупой ублюдок"}
        }}
    }
    math.randomseed(client.unix_time())
    utils.shuffle_table(trashtalk.kill[2])
    utils.shuffle_table(trashtalk.death[2])
    local b = 0
    local trashsay = function(e)
        if not e then return end
        local table = e[2][e[1]]
        e[1] = e[1] + 1
        if e[1] == #e[2] then
            e[1] = 1
            utils.shuffle_table(e[2])
        end
        b = b + 1
        local a = b
        for i=1, #table do
            client.delay_call(i*2, function()
                if b == a then
                    client.exec('say "' .. table[i] .. '"')
                end
            end)
        end
    end
    menu.Features.trashtalk.on:set_event('player_death', function(e)
        local gamerules = entity.get_game_rules()
        if not gamerules then return end
        if entity.get_prop(gamerules, 'm_bWarmupPeriod') == 1 then return end
        local userid, attacker = client.userid_to_entindex(e.userid),client.userid_to_entindex(e.attacker)
        if userid == lp.entity then
            lp.zoom = 0
            lp.scoped = 0
        end
        if userid == attacker or (userid ~= lp.entity and attacker ~= lp.entity) then return end
        trashsay((attacker == lp.entity and (menu.Features.trashtalk.event:get("On Kill") and trashtalk.kill) or (menu.Features.trashtalk.event:get("On Death") and trashtalk.death)) or nil)
    end)
end

local fast_ladder do
    local setup = function(cmd)
        if entity.get_prop(lp.entity, 'm_MoveType') ~= 9 then return end
    
        local weapon = entity.get_player_weapon(lp.entity)
        if not weapon then return end
    
        local throw_time = entity.get_prop(weapon, 'm_fThrowTime')
    
        if throw_time ~= nil and throw_time ~= 0 then
            return
        end
        
        if cmd.forwardmove > 0 then
            if cmd.pitch < 45 then
                cmd.pitch = 89
                cmd.in_moveright = 1
                cmd.in_moveleft = 0
                cmd.in_forward = 0
                cmd.in_back = 1
        
                if cmd.sidemove == 0 then
                    cmd.yaw = cmd.yaw + 90
                end
        
                if cmd.sidemove < 0 then
                    cmd.yaw = cmd.yaw + 150
                end
        
                if cmd.sidemove > 0 then
                    cmd.yaw = cmd.yaw + 30
                end
            end
        elseif cmd.forwardmove < 0 then
            cmd.pitch = 89
            cmd.in_moveleft = 1
            cmd.in_moveright = 0
            cmd.in_forward = 1
            cmd.in_back = 0
        
            if cmd.sidemove == 0 then
                cmd.yaw = cmd.yaw + 90
            end
        
            if cmd.sidemove > 0 then
                cmd.yaw = cmd.yaw + 150
            end
        
            if cmd.sidemove < 0 then
                cmd.yaw = cmd.yaw + 30
            end
        end
    end
    
    menu.Antiaims.other.ladder:set_event('setup_command', setup)
end

local shot_marker do
    shot_marker = {}

    local function aim_fire(e)
        shot_marker[e.id] = {
            {e.x,e.y,e.z}, 
            globals.curtime() + menu.Features.marker.time.value *.1,
            0.1
        }
    end

    local function render()
        for id, data in pairs(shot_marker) do

            data[3] = utils.lerp(data[3], globals.curtime() >= data[2] and 0 or 1, 0.05)
            if data[3] < 0.08 then
                shot_marker[id] = nil
            end

            local x, y = renderer.world_to_screen(data[1][1], data[1][2], data[1][3])
            if x and y then
                local c = color(unpack(menu.Features.color[(data[4] or 'hit')].color.value)) or color(255,255,255,255)
                local x2 = menu.Features.marker.size.value / screen.size.x * screen.size.x
                local y2 = menu.Features.marker.size.value / screen.size.y * screen.size.y
                if menu.Features.marker.style.value == "Style: Plus" then
                    renderer.line(x + x2, y, x + 2 * x2, y, c.r,c.g,c.b,c.a * data[3])
                    renderer.line(x - x2, y, x - 2 * x2, y, c.r,c.g,c.b,c.a * data[3])
                    renderer.line(x, y - y2, x, y - 2 * y2, c.r,c.g,c.b,c.a * data[3])
                    renderer.line(x, y + y2, x, y + 2 * y2, c.r,c.g,c.b,c.a * data[3])
                else
                    renderer.line(x + x2, y + y2, x + 2 * x2, y + 2 * y2, c.r,c.g,c.b,c.a * data[3])
                    renderer.line(x - x2, y + y2, x - 2 * x2, y + 2 * y2, c.r,c.g,c.b,c.a * data[3])
                    renderer.line(x - x2, y - y2, x - 2 * x2, y - 2 * y2, c.r,c.g,c.b,c.a * data[3])
                    renderer.line(x + x2, y - y2, x + 2 * x2, y - 2 * y2, c.r,c.g,c.b,c.a * data[3])
                end
                if data[4] and menu.Features.marker.extra.value then
                    local size = renderer.measure_text('cd', data[4])
                    renderer.text(x + size/1.2, y, c.r,c.g,c.b,c.a * data[3], 'cd', 0, data[4])
                end
            end
        end
    end

    menu.Features.marker.on:set_event("aim_fire", aim_fire)
    menu.Features.marker.on:set_event("paint", render)
    menu.Features.marker.on:set_event('aim_miss', function(e)
        shot_marker[e.id][4] = e.reason
    end)

    menu.Features.marker.on:set_event("round_prestart", function()
        shot_marker = {}
    end)

end

local clantag do
    local tag_frames = {
"", " r ", " ® ", " re ", " r3 ", " ®e ", "re_ ", " re| ", "r3g|", "reg_",
"regi|", "reg1d3", "regid3", "regid_", "regid$|", "r3g1c1d3", "reg1c1d3",
"reg1cide|", "regid$s|", "reg1c1d$", "@reg1cid3", "reg1c1d3", "@regicide",
"regicide", "regicid<", "regid$", "reg1c1d<", "reg1c1d<", "reg1c<",
"regi<", "@r3g<", "reg", "re", "r", "@", ""
    }

    local previous_tag = nil

    local setup = function()
        local game_rules = entity.get_game_rules()
        local m_gamePhase = entity.get_prop(game_rules, 'm_gamePhase')
        local NextPhase = entity.get_prop(game_rules, 'm_timeUntilNextPhaseStarts')
        local clan_tag = ""

        if m_gamePhase == 5 or NextPhase ~= 0 then
            clan_tag = "@Regicide"
        else
            local tickinterval = globals.tickinterval()
            local tickcount = globals.tickcount()
            tickcount = tickcount + math.floor(client.real_latency() + 0.22 / tickinterval + 0.5)
            local i = math.floor(tickcount / math.floor(0.3 / tickinterval + 0.5)) % #tag_frames + 1
            clan_tag = tag_frames[i]
        end

        if clan_tag ~= previous_tag then
            client.set_clan_tag(clan_tag)
            previous_tag = clan_tag
        end
    end

    menu.Features.clantag.on:set_event('paint', setup)
    menu.Features.clantag.on:set_callback(function(self)
        refs2.tag:set_enabled(not self.value)

        if not self.value then
            refs2.tag:override()
            client.delay_call(0, function()
                client.set_clan_tag("")
            end)
        else
            refs2.tag:override(false)
        end
    end)
end


local stickman do
    stickman = {
        [0] = {1}, -- Head to Neck
        [1] = {6,15, 17}, -- Neck to Pelvis, Left Upper Arm, Right Upper Arm
        [2] = {3, 7, 8}, -- Pelvis to Stomach, Left Hip, Right Hip
        [3] = {4}, -- Stomach to Lower Chest
        [4] = {5}, -- Lower Chest to Chest
        [5] = {6}, -- Chest to Upper Chest
        [7] = {9}, -- Left Hip to Left Shin
        [8] = {10}, -- Right Hip to Right Shin
        [9] = {11}, -- Left Shin to Left Foot
        [10] = {12}, -- Right Shin to Right Foot
        [16] = {15}, -- Left Upper Arm to Left Forearm
        [17] = {14} -- Right Upper Arm to Right Forearm
    }
    local render = function()
        if not refs2.thirdperson:get_hotkey() then return end
        if not lp.entity or not entity.is_alive(lp.entity) then return end
        if menu.Features.stickman.def.value and exploit.def_aa or not menu.Features.stickman.def.value then
            for from, ids in pairs(stickman) do
                local x,y,z = entity.hitbox_position(lp.entity, from)
                if not x and not y and not y then return end
                local x1,y1 = renderer.world_to_screen(x,y,z)
                for _, id in pairs(ids) do
                    local x,y,z = entity.hitbox_position(lp.entity, id)
                    if not x and not y and not y then return end
                    local x2,y2 = renderer.world_to_screen(x,y,z)
                    local c = colors['stickman']['Color']
                    renderer.line(x1,y1,x2,y2, c.r,c.g,c.b,c.a)
                end
            end
        end
    end
    menu.Features.stickman.on:set_event('paint', render)
end

local velocity do 
    local a = 0
    local menu_a = 0
    local render = drag.register(menu.Features.velocity.drag, vector(300, 40), "velocity", function(self)
        if not lp.entity or not entity.is_alive(lp.entity) then return end
        menu_a = utils.lerp(menu_a, ui.is_menu_open() and 1 or 0, 0.005)
        local val = entity.get_prop(lp.entity, 'm_flVelocityModifier')
        local vel = menu_a ~= 0 and utils.sine_yaw(globals.framecount()/10, 0, 1) or val

        local col = colors['velocity']['Bad']:lerp(colors['velocity']['Good'], vel)
        local text = string.format("Slowed down by %.0f%%", 100-vel*100)
        local measure = vector(renderer.measure_text('cd', string.format("Slowed down by %.0f%%", 100)))
        a = utils.lerp(a, (val ~= 1 or ui.is_menu_open()) and 1 or 0, 0.03)

        utils.rectangle(self.position.x+12, self.position.y + 6, self.size.x-24, 8, 0,0,0,255*a, 2)
        utils.rectangle(self.position.x+12 + 2, self.position.y + 8, math.floor((self.size.x-24 - 4) * vel), 4, col.r,col.g,col.b,col.a*a, 5)
        renderer.text(self.position.x + self.size.x / 2, self.position.y + self.size.y - height/2-2, 255,255,255,255*a, 'cd', 0, text)
    end)

    menu.Features.velocity.on:set_event("paint", function()
        render:update()
    end)
end

--[[
local defensive do 
    local a = 0
    local vel = 0
    local render = function()
        if not lp.entity or not entity.is_alive(lp.entity) then return end
        -- local vel = entity.get_prop(lp.entity, 'm_flVelocityModifier')
        -- local vel = utils.sine_yaw(globals.servertickcount(), 0, 1)
        local col = color(255):lerp(color(220,30,50,255), exploit.get().defensive.left / 13)
        local text = "Defensive"
        renderer.text(screen.center.x, screen.size.y * 0.98, col.r,col.g,col.b,col.a, 'cd-', 0, text:upper())        
    end

    client.set_event_callback('paint', render)
end
]]

local gamesense do
    local x,y = 35,screen.size.y * 0.759
    local xy = {}
    for i=1, 9 do
        xy[i] = {35,screen.size.y * 0.759}
    end
    local render = function(e)
        local elements = {
            {"Ping Spike", refs2.ping.value and refs2.ping:get_hotkey()},
            {"Double Tap", lp.exploit == 'dt'},
            {"Fake Duck",  lp.exploit == 'fd'},
            {"Hide Shots",  lp.exploit == 'osaa'},
            {"Safe Point", refs2.safe:get()},
            {"Body Aim", refs2.baim:get()},
            {"Hit Chance", hitchance or menu.Features.gamesense.settings["Hit Chance"].container.always:get()},
            {"Min. Damage", (refs2.mdmg:get() and refs2.mdmg:get_hotkey()) or menu.Features.gamesense.settings["Min. Damage"].container.always:get()},
            {"Freestanding", menu.Antiaims.hotkeys.fs:get()},
        }
        for i=1, #elements do
            local name = elements[i][1]
            elements[i][3] = menu.Features.gamesense.settings[elements[i][1]].container.name:get() == '' and hard["gamesense"].names[elements[i][1]] or menu.Features.gamesense.settings[elements[i][1]].container.name:get()
            elements[i][2] = elements[i][2] and menu.Features.gamesense.settings[elements[i][1]].on.value
        end
        elements[8][3] = elements[8][3] .. (menu.Features.gamesense.settings["Min. Damage"].container.show.value and ': '..(refs2.mdmg:get() and refs2.mdmg:get_hotkey() and refs2.mdmg2.value or refs2.dmg.value) or '')
        elements[7][3] = elements[7][3] .. (menu.Features.gamesense.settings["Hit Chance"].container.show.value and  ': '..(hitchance and hitchance[2] or refs2.hc.value) or '')

        local y_add = 0
        if not lp.entity or not entity.is_alive(lp.entity) then return end
        local stomach_x, stomach_y, stomach_z = entity.hitbox_position(lp.entity, 3)
        local xx, yy = renderer.world_to_screen(stomach_x, stomach_y, stomach_z)

        for i, t in pairs(elements) do
                local c = colors['gamesense'][t[1]]
                local measure = vector(renderer.measure_text('+d', t[3]))
                local x1 = 29 + measure.x/2
                local y1 = screen.size.y * 0.759 - y_add - 2

                if menu.Features.gamesense.follow.value and refs2.thirdperson.value and refs2.thirdperson:get_hotkey() and xx and yy then
                    xy[i][1] = utils.lerp(xy[i][1], true and xx - 250 or 0, 0.03)
                    xy[i][2] = utils.lerp(xy[i][2], true and yy - y_add - 2 or 0, 0.03)
                else
                    xy[i][1] = utils.lerp(xy[i][1], true and x1 or 0, 0.3)
                    xy[i][2] = utils.lerp(xy[i][2], true and y1 or 0, 0.3)
                end
                if t[2] then
                    renderer.gradient(xy[i][1], xy[i][2], x1, measure.y + 4, 0, 0, 0, 25, 0,0,0,0, true)
                    renderer.gradient(xy[i][1], xy[i][2], -x1, measure.y + 4, 0, 0, 0, 25, 0,0,0,0, true)
                    renderer.text(
                        xy[i][1] - measure.x/2, xy[i][2] + 2,
                        c.r,c.g,c.b,c.a, '+d', 0,
                        t[3]
                    )
                    y_add = y_add + measure.y * 1.42
                end
        end
    end
    menu.Features.gamesense.on:set_event('paint', render)
    menu.Features.gamesense.on:set_event('indicator', function() end)
end

local debug do
    -- Настройки мигания
    local blink_min = 100    -- Минимальная видимость (0-255)
    local blink_max = 255    -- Максимальная видимость
    local blink_speed = 0.8  -- Медленная скорость изменения
    local blink_value = blink_max
    local blink_direction = -1

    local render = function()
        -- Плавное изменение прозрачности
        blink_value = blink_value + blink_direction * blink_speed
        
        -- Изменение направления мигания
        if blink_value <= blink_min then
            blink_direction = 1
            blink_value = blink_min
        elseif blink_value >= blink_max then
            blink_direction = -1
            blink_value = blink_max
        end

        -- Получаем цель
        local target = target or entity.get_players(true)[1]
        local target_name = "None"
        if target ~= nil then
            target_name = entity.get_player_name(target) or target.name or "Unknown"
        end

        local elements = {
            {"Regicide - "..username[1]},
            {"version : "..version[1]},  -- Мигающая строка
            {"Condition: "..lp.state},
            {"Target: "..target_name}
        }

        -- Отрисовка с эффектами
        y_add = 0
        for index, element in pairs(elements) do
            local text = element[1]:upper()
            local measure = vector(renderer.measure_text('b', text))
            
            -- Особый рендер для версии
            if index == 2 then
                renderer.text(
                    25, 
                    screen.size.y*0.45 + y_add, 
                    255, 255, 255, 
                    math.floor(blink_value),  -- Применяем изменяющуюся прозрачность
                    'b', 0, text
                )
            else
                renderer.text(
                    25, 
                    screen.size.y*0.45 + y_add, 
                    255, 255, 255, 255, 
                    'b', 0, text
                )
            end
            
            y_add = y_add + measure.y + 5
        end
    end

    client.set_event_callback('paint', render)
end

local bomb do
    bomb = {}
    bomb.a = 0

    local render = drag.register(menu.Features.bomb.drag, vector(320, 38), "bomb", function(self)
        local t = entity.get_all("CPlantedC4")
        bomb.id = t[#t]

        if not bomb.id then return end

        local curtime = globals.curtime()
        local is_menu_open = ui.is_menu_open()

        -- Получаем свойства бомбы
        local defused = entity.get_prop(bomb.id, "m_bBombDefused") == 1
        local is_ticking = entity.get_prop(bomb.id, "m_bBombTicking") == 1 and not defused
        local blow_time = entity.get_prop(bomb.id, "m_flC4Blow") or 0
        local defuser = entity.get_prop(bomb.id, "m_hBombDefuser")
        local defuse_countdown = entity.get_prop(bomb.id, "m_flDefuseCountDown") or 0
        local defuse_length = entity.get_prop(bomb.id, "m_flDefuseLength") or 0
        local timer_length = entity.get_prop(bomb.id, "m_flTimerLength") or 40

        -- Поддержка fake-таймера при открытом меню
        if is_menu_open and not defuser and not is_ticking then
            is_ticking = true
            timer_length = 40
            blow_time = curtime + utils.sine_yaw(globals.servertickcount() / 2, 0.5, 40)
        end

        -- Расчёт оставшегося времени
        local time_left = defuser or defused and (defuse_countdown - curtime) or (blow_time - curtime)
        time_left = math.max(0, time_left)
        local percentage = time_left / (defuser and defuse_length or timer_length)

        -- Обновление состояния
        bomb.is_ticking = is_ticking
        bomb.defused = defused
        bomb.defuser = defuser
        bomb.left = time_left
        bomb.timer = defuser and defuse_length or timer_length
        bomb.blow = blow_time
        bomb.percentage = percentage

        -- Анимация появления
        bomb.a = utils.lerp(bomb.a, ((is_ticking and percentage > 0) or is_menu_open) and 1 or 0, 0.03)
        if bomb.a <= 0 then return end

        -- Цвет прогресса
        local col = colors.bomb["Bad"]:lerp(
            colors.bomb["Good"],
            defuser and ((blow_time - defuse_countdown) >= 0 and 1 or 0) or percentage
        )

        -- Отрисовка фона и полоски
        local bar_x = self.position.x + 12
        local bar_y = self.position.y + 17
        local bar_w = self.size.x - 24 - 4
        local fill_w = math.floor(bar_w * percentage)

        utils.rectangle(self.position.x + 12, self.position.y + 15, self.size.x - 24, 8, 0, 0, 0, 255 * bomb.a, 2)
        utils.rectangle(bar_x + 2, bar_y, fill_w, 4, col.r, col.g, col.b, col.a * bomb.a, 5)

        -- Отрисовка текста (плант сайт и таймер)
        local site = entity.get_prop(bomb.id, "m_nBombSite") == 0 and "A" or "B"
        local text_x = bar_x + fill_w
        renderer.text(text_x, self.position.y + 8, 255, 255, 255, 255 * bomb.a, "cd", 0, site)
        renderer.text(text_x, self.position.y + 30, 255, 255, 255, 255 * bomb.a, "cd", 0, string.format("%.1f", bomb.left))
    end)

    -- Отрисовка при активной функции
    menu.Features.bomb.on:set_event("paint", function()
        render:update()
    end)
end

-- Инициализация
do
    client.exec('playvol buttons\\light_power_on_switch_01 0.5')
    drag.on_config_load()
end

local resolver do
    resolver = {}

-- Проверка на включение ресолвера
if not Features or not Features.resolver then return end
if not Features.resolver.enable.value or not Features.resolver.used.value then return end

-- Глобальные переменные для ресолвера
local player_data = {}
local last_hit_time = {}
local hit_count = {}
local style_detection = {}

-- Константы стилей игры
local PLAYER_STYLES = {
    NORMAL = 0,
    JITTER = 1,
    DEFENSIVE = 2,
    FREESTANDING = 3,
    ANTI_BRUTE = 4
}

-- Константы состояний игрока
local RESOLVE_STATES = {
    STANDING = 0,
    MOVING = 1,
    SLOW_WALK = 2,
    CROUCHING = 3,
    AIRBORNE = 4
}

-- Вспомогательные функции
local function normalize_angle(angle)
    angle = angle % 360
    return angle > 180 and angle - 360 or angle < -180 and angle + 360 or angle
end

local function clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

local function vec_length2d(vec)
    return math.sqrt(vec[1]^2 + vec[2]^2)
end

-- Функция определения состояния игрока
local function detect_player_state(ent)
    local flags = entity.get_prop(ent, "m_fFlags")
    local velocity = {entity.get_prop(ent, "m_vecVelocity")}
    local speed = vec_length2d(velocity)
    local duck_amount = entity.get_prop(ent, "m_flDuckAmount") or 0
    
    if bit.band(flags, 1) == 0 then
        return RESOLVE_STATES.AIRBORNE
    elseif duck_amount > 0.7 then
        return RESOLVE_STATES.CROUCHING
    elseif speed > 5 and speed < 100 then
        return RESOLVE_STATES.SLOW_WALK
    elseif speed >= 100 then
        return RESOLVE_STATES.MOVING
    else
        return RESOLVE_STATES.STANDING
    end
end

-- Функция определения стиля игры
local function detect_play_style(ent)
    local eye_yaw = entity.get_prop(ent, "m_angEyeAngles[1]") or 0
    local lby = entity.get_prop(ent, "m_flLowerBodyYawTarget") or 0
    local delta = math.abs(normalize_angle(eye_yaw - lby))
    local vel = {entity.get_prop(ent, "m_vecVelocity")}
    local speed = math.sqrt(vel[1]^2 + vel[2]^2)
    local health = entity.get_prop(ent, "m_iHealth") or 100
    
    -- Jitter detection
    if delta > 120 and speed < 5 then
        return PLAYER_STYLES.JITTER
    -- Defensive detection
    elseif delta < 30 and speed < 5 then
        return PLAYER_STYLES.DEFENSIVE
    -- Anti-bruteforce detection
    elseif globals.curtime() - (last_hit_time[ent] or 0) < 2 and hit_count[ent] and hit_count[ent] >= 2 then
        return PLAYER_STYLES.ANTI_BRUTE
    -- Low health detection
    elseif health < 92 then
        return PLAYER_STYLES.DEFENSIVE -- Для раненых используем defensive логику
    else
        return PLAYER_STYLES.NORMAL
    end
end

-- Jitter Resolver
local function handle_jitter_resolver(ent, data)
    if not data.jitter_data then
        data.jitter_data = {
            last_angles = {},
            last_update = 0,
            current_side = 1,
            sides = {-60, 60, -30, 30, 0}  -- Приоритетные углы для джиттера
        }
    end
    
    local jitter = data.jitter_data
    local eye_yaw = entity.get_prop(ent, "m_angEyeAngles[1]") or 0
    
    -- Анализ последних углов
    table.insert(jitter.last_angles, eye_yaw)
    if #jitter.last_angles > 10 then
        table.remove(jitter.last_angles, 1)
    end
    
    -- Определяем джиттер (быстрые изменения угла)
    local jitter_detected = false
    if #jitter.last_angles >= 3 then
        local delta1 = math.abs(normalize_angle(jitter.last_angles[#jitter.last_angles] - jitter.last_angles[#jitter.last_angles-1]))
        local delta2 = math.abs(normalize_angle(jitter.last_angles[#jitter.last_angles-1] - jitter.last_angles[#jitter.last_angles-2]))
        
        if delta1 > 50 and delta2 > 50 then
            jitter_detected = true
        end
    end
    
    -- Если обнаружен джиттер, применяем специальную логику
    if jitter_detected then
        if globals.curtime() - jitter.last_update > 0.3 then
            jitter.current_side = jitter.current_side % #jitter.sides + 1
            jitter.last_update = globals.curtime()
        end
        
        return jitter.sides[jitter.current_side]
    end
    
    -- Стандартный брут для джиттера
    return math.random() > 0.5 and 60 or -60
end

-- Defensive Resolver
local function handle_defensive_resolver(ent, data)
    if not data.defensive_data then
        data.defensive_data = {
            last_lby = 0,
            last_update = 0,
            last_eye = 0,
            change_timer = 0,
            current_offset = 0,
            health = 100
        }
    end
    
    local defensive = data.defensive_data
    local lby = entity.get_prop(ent, "m_flLowerBodyYawTarget") or 0
    local eye_yaw = entity.get_prop(ent, "m_angEyeAngles[1]") or 0
    local health = entity.get_prop(ent, "m_iHealth") or 100
    
    -- Для раненых игроков увеличиваем коррекцию
    local health_factor = health < 92 and 1.5 or 1
    
    -- Анализ изменений LBY
    if math.abs(normalize_angle(lby - defensive.last_lby)) > 5 then
        defensive.last_lby = lby
        defensive.last_update = globals.curtime()
    end
    
    -- Анализ изменений eye yaw
    if math.abs(normalize_angle(eye_yaw - defensive.last_eye)) > 10 then
        defensive.last_eye = eye_yaw
        defensive.change_timer = globals.curtime()
    end
    
    -- Если игрок не менял угол более 1.1 секунды (время обновления LBY)
    if globals.curtime() - defensive.change_timer > 1.1 then
        if globals.curtime() - defensive.last_update > 0.5 then
            defensive.current_offset = (math.random() > 0.5 and 15 or -15) * health_factor
            defensive.last_update = globals.curtime()
        end
        return defensive.current_offset
    end
    
    return 0
end

-- Anti-Bruteforce Resolver
local function handle_anti_brute(ent, data)
    if not data.anti_brute_angles then
        data.anti_brute_angles = {0, 15, -15, 30, -30, 45, -45, 60, -60}
        data.anti_brute_index = 1
        data.anti_brute_last_change = globals.curtime()
    end
    
    if globals.curtime() - data.anti_brute_last_change > 2 then
        data.anti_brute_index = data.anti_brute_index % #data.anti_brute_angles + 1
        data.anti_brute_last_change = globals.curtime()
    end
    
    return data.anti_brute_angles[data.anti_brute_index]
end

-- Основная функция ресолвера
function Resolver()
    local Players = entity.get_players(true)

    for i, Player in pairs(Players) do
        if not entity.is_alive(Player) then goto continue end
        
        -- Получаем данные игрока
        if not player_data[Player] then
            player_data[Player] = {
                misses = 0,
                hits = 0,
                last_resolved = 0,
                resolve_history = {},
                good_angles = {}
            }
        end
        local data = player_data[Player]
        
        -- Определяем стиль игры и состояние
        local style = detect_play_style(Player)
        style_detection[Player] = style
        local lby = entity.get_prop(Player, "m_flLowerBodyYawTarget") or 0
        local eye_yaw = entity.get_prop(Player, "m_angEyeAngles[1]") or 0
        local state = detect_player_state(Player)
        local health = entity.get_prop(Player, "m_iHealth") or 100
        
        -- Применяем соответствующую логику ресолва
        local resolved_yaw = lby
        local resolved_pitch = entity.get_prop(Player, "m_angEyeAngles[0]") or 0
        local correction = 0
        
        -- Выбираем обработчик в зависимости от стиля
        if style == PLAYER_STYLES.JITTER then
            correction = handle_jitter_resolver(Player, data)
            resolved_pitch = math.random() > 0.5 and 85 or -85
        elseif style == PLAYER_STYLES.DEFENSIVE or health < 92 then
            correction = handle_defensive_resolver(Player, data)
            resolved_pitch = clamp(resolved_pitch, -45, 45)
        elseif style == PLAYER_STYLES.ANTI_BRUTE then
            correction = handle_anti_brute(Player, data)
        else
            -- Стандартный ресолвер
            correction = math.random() > 0.5 and 30 or -30
        end
        
        -- Применяем коррекцию
        resolved_yaw = normalize_angle(lby + correction)
        
        -- Учет состояния игрока
        if state == RESOLVE_STATES.MOVING then
            resolved_yaw = normalize_angle(resolved_yaw * 0.7)
        elseif state == RESOLVE_STATES.CROUCHING then
            resolved_yaw = normalize_angle(resolved_yaw * 0.5)
        end
        
        -- Если есть успешные углы, пробуем их использовать
        if #data.good_angles > 0 then
            resolved_yaw = data.good_angles[#data.good_angles]
        end
        
        -- Применяем resolved углы
        entity.set_prop(Player, "m_angEyeAngles[0]", resolved_pitch)
        entity.set_prop(Player, "m_angEyeAngles[1]", resolved_yaw)
        
        -- Обновляем историю
        data.last_resolved = resolved_yaw
        table.insert(data.resolve_history, {yaw = resolved_yaw, time = globals.curtime()})
        if #data.resolve_history > 10 then table.remove(data.resolve_history, 1) end
        
        ::continue::
    end
end

-- Обработчики событий для улучшения точности
client.set_event_callback("player_hurt", function(e)
    local victim = client.userid_to_entindex(e.userid)
    local attacker = client.userid_to_entindex(e.attacker)
    
    if attacker == entity.get_local_player() and victim ~= entity.get_local_player() then
        hit_count[victim] = (hit_count[victim] or 0) + 1
        last_hit_time[victim] = globals.curtime()
        
        if player_data[victim] then
            player_data[victim].hits = (player_data[victim].hits or 0) + 1
            if player_data[victim].last_resolved then
                table.insert(player_data[victim].good_angles, player_data[victim].last_resolved)
                if #player_data[victim].good_angles > 3 then
                    table.remove(player_data[victim].good_angles, 1)
                end
            end
        end
    end
end)

client.set_event_callback("bullet_impact", function(e)
    local shooter = client.userid_to_entindex(e.userid)
    if shooter == entity.get_local_player() then
        -- Логика анализа промахов может быть добавлена здесь
    end
end)

-- Визуализация стиля игрока
client.set_event_callback("paint", function()
    if not Features.resolver.enable.value then return end
    
    local players = entity.get_players(true)
    for i, player in pairs(players) do
        if entity.is_alive(player) then
            local style = style_detection[player] or PLAYER_STYLES.NORMAL
            local style_name = "NORMAL"
            local r, g, b = 255, 255, 255
            
            if style == PLAYER_STYLES.JITTER then
                style_name = "JITTER"
                r, g, b = 255, 50, 50
            elseif style == PLAYER_STYLES.DEFENSIVE then
                style_name = "DEFENSIVE"
                r, g, b = 50, 255, 50
            elseif style == PLAYER_STYLES.ANTI_BRUTE then
                style_name = "ANTI-BRUTE"
                r, g, b = 255, 255, 50
            end
            
            local x, y, z = entity.get_prop(player, "m_vecOrigin")
            local w2s_x, w2s_y = renderer.world_to_screen(x, y, z)
            
            if w2s_x and w2s_y then
                renderer.text(w2s_x, w2s_y - 15, r, g, b, 255, "c", 0, style_name)
                renderer.text(w2s_x, w2s_y - 30, 255, 255, 255, 255, "c", 0, "Hits: " .. (player_data[player] and player_data[player].hits or 0))
            end
        end
    end
end)

-- Инициализация
client.set_event_callback("net_update_end", Resolver)
client.set_event_callback("shutdown", function()
    ui.set_visible(MenuV["ForceBodyYaw"], true)
    ui.set_visible(MenuV["CorrectionActive"], true)
    ui.set(MenuV["ResetAll"], true)
end)
end

local mantletap do
    mantletap = {}

local function rage(cmd)
    local lp = entity.get_local_player()
    if not lp then return end

    -- Новая проверка вместо b_2.rage.expdt:get()
    if not Features or not Features.mantletap then return end
    if not Features.mantletapr.enable.value or not Features.mantletap.used.value then return end

    local tickbase = entity.get_prop(lp, "m_nTickBase") - globals.tickcount()
    local doubletap_ref = ui.get(s_2.s_0.dt[1]) and ui.get(s_2.s_0.dt[2]) and not ui.get(s_2.s_0.fakeduck)

    local active_weapon = entity.get_prop(lp, "m_hActiveWeapon")
    if active_weapon == nil then return end

    local weapon_idx = entity.get_prop(active_weapon, "m_iItemDefinitionIndex")
    if weapon_idx == nil or weapon_idx == 64 then return end

    local LastShot = entity.get_prop(active_weapon, "m_fLastShotTime")
    if LastShot == nil then return end

    local single_fire_weapon = weapon_idx == 40 or weapon_idx == 9 or weapon_idx == 64 or weapon_idx == 27 or weapon_idx == 29 or weapon_idx == 35
    local value = single_fire_weapon and 1.50 or 0.50
    local in_attack = globals.curtime() - LastShot <= value

    if tickbase > 0 and doubletap_ref then
        if in_attack then
            ui.set(s_2.s_0.rage_cb[2], "Always on")
        else
            ui.set(s_2.s_0.rage_cb[2], "On hotkey")
        end
    else
        ui.set(s_2.s_0.rage_cb[2], "Always on")
    end
end
end 

local predict do
    predict = {}

predict = function()
    local lp = entity.get_local_player()
    if not lp then return end
    local gun = entity.get_player_weapon(lp)
    if not gun then return end

    local classname = entity.get_classname(gun)

    -- Новая проверка на включение
    if not Features or not Features.Predict then return end
    if not Features.Predict.enable.value or not Features.Predict.hotexp.value then return end

    if Features.Predict.pingpos:get() == "Low" then
        cvar.cl_interpolate:set_int(0)
        cvar.cl_interp_ratio:set_int(1)

        if classname == "CWeaponSSG08" then
            if Features.Predict.slidescout:get() == "Disabled" then
                cvar.cl_interp:set_float(0.015625)
            elseif Features.Predict.slidescout:get() == "Medium" then
                cvar.cl_interp:set_float(0.028000)
            elseif Features.Predict.slidescout:get() == "Maximum" then
                cvar.cl_interp:set_float(0.029125)
            elseif Features.Predict.slidescout:get() == "Extreme" then
                cvar.cl_interp:set_float(0.031000)
            end
        end

        if classname == "CWeaponAWP" then
            if Features.Predict.slideawp:get() == "Disabled" then
                cvar.cl_interp:set_float(0.015625)
            elseif Features.Predict.slideawp:get() == "Medium" then
                cvar.cl_interp:set_float(0.028000)
            elseif Features.Predict.slideawp:get() == "Maximum" then
                cvar.cl_interp:set_float(0.029125)
            elseif Features.Predict.slideawp:get() == "Extreme" then
                cvar.cl_interp:set_float(0.031000)
            end
        end

        if classname == "CWeaponSCAR20" or classname == "CWeaponG3SG1" then
            if Features.Predict.slideauto:get() == "Disabled" then
                cvar.cl_interp:set_float(0.015625)
            elseif Features.Predict.slideauto:get() == "Medium" then
                cvar.cl_interp:set_float(0.028000)
            elseif Features.Predict.slideauto:get() == "Maximum" then
                cvar.cl_interp:set_float(0.029125)
            elseif Features.Predict.slideauto:get() == "Extreme" then
                cvar.cl_interp:set_float(0.031000)
            end
        end

        if classname == "CDEagle" then
            if Features.Predict.slider8:get() == "Disabled" then
                cvar.cl_interp:set_float(0.015625)
            elseif Features.Predict.slider8:get() == "Medium" then
                cvar.cl_interp:set_float(0.028000)
            elseif Features.Predict.slider8:get() == "Maximum" then
                cvar.cl_interp:set_float(0.029125)
            elseif Features.Predict.slider8:get() == "Extreme" then
                cvar.cl_interp:set_float(0.031000)
            end
        end
    elseif Features.Predict.pingpos:get() == "High" then
        cvar.cl_interp:set_float(0.020000)
        cvar.cl_interp_ratio:set_int(0)
        cvar.cl_interpolate:set_int(0)
    end
end
end

local jumpstop do
    jumpstop = {}

local function jump_stop(cmd)
    local lp = entity.get_local_player()
    if not lp then return end
    if not entity.is_alive(lp) then return end

    local players = entity.get_players(true)
    local lpvec = vector(entity.get_prop(lp, 'm_vecOrigin'))
    local weapon = entity.get_player_weapon(lp)
    local class = entity.get_classname(weapon)

    if class ~= 'CWeaponSSG08' then return end
    local vecvelocity = { entity.get_prop(lp, 'm_vecVelocity') }

    local check_vel = vecvelocity[3] > 0
    local flags = entity.get_prop(lp, 'm_fFlags')
    local jumpcheck = bit.band(flags, 1) == 0

    if not Features or not Features.jumpstop then return end
    if not Features.jumpstop.enable.value or not Features.jumpstop.hotkey.value then return end
        local enemy = client.current_threat()
        if not enemy then return end
        if not jumpcheck then return end
        if not check_vel then return end
        local x1, y1, z1 = entity.get_prop(enemy, 'm_vecOrigin')
        local dist = anti_knife_dist(lpvec.x, lpvec.y, lpvec.z, x1, y1, z1)
        if dist <= (features.Jumpstop.distance:get()) then
            if cmd.quick_stop then
                cmd.in_speed = 1
            end
        end
    end
end

    if features.Jumpstop:get() and features.Jumpstop.hotkey:get() then
        renderer.indicator(230, 230, 230, 230, 'AS')
    end