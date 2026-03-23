#!/usr/bin/env bash

WALL="$HOME/.local/share/wallpapers/wallpaperflare.com_wallpaper.jpg"

# esperar un poco a que Hyprland termine de recargar
sleep 1

swww img "$WALL" --transition-type fade --transition-duration 1
