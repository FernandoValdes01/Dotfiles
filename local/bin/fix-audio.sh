#!/usr/bin/env bash

# esperar a que pipewire inicie
sleep 2

# desmutear sink pipewire
wpctl set-mute @DEFAULT_AUDIO_SINK@ 0

# volumen al 100%
wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0

# desmutear hardware alsa
amixer -D pulse sset Master unmute >/dev/null 2>&1
amixer sset Master unmute >/dev/null 2>&1
amixer sset Speaker unmute >/dev/null 2>&1
amixer sset Headphone unmute >/dev/null 2>&1

# subir volumen hardware
amixer sset Master 100% >/dev/null 2>&1

exit 0

