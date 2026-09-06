-- ~/.config/hypr/hyprland.lua
-- Config manual sin ML4W. Hyprland 0.55+ usa Lua en vez del antiguo hyprlang (.conf).
-- Referencia oficial: https://wiki.hypr.land/Configuring/Start/

------------------
---- MONITORS ----
------------------
-- Ajusta los nombres de salida si difieren (comprueba con: hyprctl monitors)
hl.monitor({
    output = "eDP-1",
    mode = "preferred",
    position = "0x0",
    scale = "auto",
})

hl.monitor({
    output = "HDMI-A-1",
    mode = "preferred",
    position = "auto-right",
    scale = "auto",
})

---------------------
---- MY PROGRAMS ----
---------------------
local terminal = "kitty"
local fileManager = "dolphin"
local menu = "~/.config/rofi/launchers/type-1/launcher.sh"

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

-------------------
---- AUTOSTART ----
-------------------
-- Todo lo que quieres que se lance al entrar en la sesión
hl.on("hyprland.start", function()
    -- Agente de autenticación (necesario para diálogos de permisos elevados,
    -- p.ej. actualizar software gráfico, montar discos, etc.)
    hl.exec_cmd("/usr/libexec/polkit-gnome-authentication-agent-1")

    -- Barra superior
    hl.exec_cmd("waybar")

    hl.exec_once("swaybg -i ~/.config/hypr/wallpapers/image.jpg -m fill")
    -- Gestión de inactividad / bloqueo automático (config en hypridle.conf)
    hl.exec_cmd("hypridle")

    -- Notificaciones
    hl.exec_cmd("dunst")
    
    -- Portapapeles
    hl.exec_cmd("copyq --start-server")

    -- Daemon de KDE Connect, para ver el móvil en la barra
    hl.exec_cmd("kdeconnectd")
    -- Guardar historial de texto e imágenes
    hl.exec_once("wl-paste --type text --watch cliphist store")
    hl.exec_once("wl-paste --type image --watch cliphist store")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(89b4faee)", "rgba(cba6f7ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 0.95,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = 0xee1a1a1a,
        },
        blur = {
            enabled = true,
            size = 3,
            passes = 2,
            vibrancy = 0.17,
        },
    },
    animations = {
        enabled = true,
        bezier = {
            { name = "wind", cp = { 0.05, 0.9, 0.1, 1.05 } },
          { name = "winIn", cp = { 0.1, 1.1, 0.1, 1.1 } },
          { name = "winOut", cp = { 0.3, -0.3, 0, 1 } },
          { name = "liner", cp = { 0, 0, 1, 1 } },
        },
        animation = {
            "windows, 1, 4, wind, slide",
          "windowsIn, 1, 4, winIn, slide",
          "windowsOut, 1, 3, winOut, slide",
          "windowsMove, 1, 4, wind, slide",
          "border, 1, 1, liner",
          "borderangle, 1, 30, liner, loop",
          "fade, 1, 4, default",
          "workspaces, 1, 3, wind, slide",
        },
    },
    dwindle = {
        preserve_split = true,
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
    },
    cursor = {
        inactive_timeout = 5,
    },
    windowrulev2 = {
        -- Flotantes y centradas para utilidades de control
        "float, class:^(pavucontrol)$",
        "center, class:^(pavucontrol)$",
        "size 650 450, class:^(pavucontrol)$",

        "float, class:^(blueman-manager)$",
        "center, class:^(blueman-manager)$",

        "float, class:^(nm-connection-editor)$",

        -- Diálogos de guardar/abrir archivo
        "float, title:^(Abrir archivo|Guardar archivo|Open File|Save File)$",

        -- Opacidad y blur selectivo
        "opacity 0.94 0.88, class:^(kitty)$",
        "opacity 1.0 override 1.0 override, class:^(chromium-browser)$",
        "opacity 1.0 override 1.0 override, class:^(feishin)$",
    },

    input = {
        kb_layout = "es",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
        },
    },
})


-- Animaciones básicas (puedes ampliarlas luego con el ejemplo oficial)
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("linear", { type = "bezier", points = { {0, 0}, {1, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "easeOutQuint" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "linear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide" })

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + CTRL + Return", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- solo dwindle
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("hyprctl dispatch exit"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("~/.config/eww/launch_dashboard"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
-- Yazi en una ventana de kitty dedicada
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd(terminal .. " --title yazi -e yazi"))

-- Foco entre ventanas con flechas
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))

-- Cambiar/mover a workspace 1-10
for i = 1, 10 do
    local key = i % 10 -- el 10 se mapea a la tecla 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll del ratón para cambiar de workspace
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Mover/redimensionar ventanas con el ratón
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volumen y Mute con OSD flotante
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })

-- Brillo de pantalla con OSD flotante
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { locked = true, repeating = true })
require("hyprcaffeine-keybinds")

-- Control de reproducción multimedia (Play/Pause, Siguiente, Anterior)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Desactivar pantalla interna al cerrar tapa, reactivarla al abrir
-- Desactivar pantalla interna al cerrar tapa, reactivarla al abrir
-- hl.bind(", switch:on:Lid Switch", hl.dsp.exec_cmd("hyprctl keyword monitor 'eDP-1, disable'"))
-- hl.bind(", switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl keyword monitor 'eDP-1, preferred, auto, 1'"))
