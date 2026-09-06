#!/bin/bash
WP="/home/jrodriiguezg/.config/hypr/wallpapers/image.jpg"

# Matar instancias previas y arrancar el demonio limpio
killall hyprpaper 2>/dev/null
hyprpaper &
sleep 0.3

# Inyectar precarga y asignacion por IPC
hyprctl hyprpaper preload "$WP"
hyprctl hyprpaper wallpaper "eDP-1,$WP"
hyprctl hyprpaper wallpaper "HDMI-A-1,$WP"
