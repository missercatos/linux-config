#!/usr/bin/env bash
# 用法: ff.sh [theme]  默认 tokyonight
theme="${1:-tokyonight}"
conf="$HOME/.config/fastfetch/config-$theme.jsonc"
[ -f "$conf" ] || conf="$HOME/.config/fastfetch/config.jsonc"
fastfetch --config "$conf"
