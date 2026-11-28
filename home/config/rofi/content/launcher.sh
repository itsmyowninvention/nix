#!/usr/bin/env bash
# -----------------------------------------------------
# ML4W-style application launcher (rofi)
#
# Replicates the behaviour of ml4w-launcher from the ML4W
# dotfiles: https://github.com/mylinuxforwork/dotfiles
#
#  - Toggling: a running rofi is closed instead of opening a second one
#  - Left panel shows the blurred preview of the active
#    linux-wallpaperengine wallpaper (ML4W shows the blurred wallpaper)
#  - Colors are Material You values extracted from that wallpaper with
#    matugen, like ML4W does (mode follows the GTK dark preference)
#
# Runtime artifacts are cached in ~/.cache/rofi/ and regenerated when the
# source image changes (mtime check).
# -----------------------------------------------------

set -euo pipefail

# XDG-aware cache location (GLib/rofi expand ~ via XDG_CACHE_HOME when set)
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/rofi"
MATUGEN_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/matugen/config.toml"

# -----------------------------------------------------
# Toggle: if a rofi instance is running, close it and exit (like ml4w:
# "pkill rofi || rofi -show drun -replace -i")
# -----------------------------------------------------
if pkill -x rofi 2>/dev/null; then
    exit 0
fi

# -----------------------------------------------------
# Resolve the source image for the left panel + color extraction.
# Priority: ROFI_LAUNCHER_IMAGE env var, then the preview of the
# wallpaper currently used by linux-wallpaperengine.
# -----------------------------------------------------
resolve_image() {
    if [ -n "${ROFI_LAUNCHER_IMAGE:-}" ] && [ -f "${ROFI_LAUNCHER_IMAGE}" ]; then
        printf '%s\n' "${ROFI_LAUNCHER_IMAGE}"
        return 0
    fi

    local cmdline assets ids dir preview
    cmdline=$(pgrep -af linux-wallpaperengine 2>/dev/null | grep -v 'pgrep' | head -1 || true)
    [ -n "$cmdline" ] || return 1

    assets=$(printf '%s\n' "$cmdline" | grep -oE -- '--assets-dir [^ ]+' | cut -d' ' -f2 || true)
    assets="${assets:-$HOME/.local/share/Steam/steamapps/workshop/content/431960}"

    # first --bg <id> on the command line
    ids=$(printf '%s\n' "$cmdline" | grep -oE -- '--bg [0-9]+' | cut -d' ' -f2 || true)
    [ -n "$ids" ] || return 1

    dir="$assets/$(printf '%s\n' "$ids" | head -1)"
    # project.json names the preview file (usually preview.jpg)
    preview=$(grep -oE '"preview"[[:space:]]*:[[:space:]]*"[^"]+"' "$dir/project.json" 2>/dev/null \
        | sed -E 's/.*"([^"]+)"$/\1/' | tail -1 || true)
    preview="${preview:-preview.jpg}"

    if [ -f "$dir/$preview" ]; then
        printf '%s\n' "$dir/$preview"
        return 0
    fi
    return 1
}

# -----------------------------------------------------
# Material You scheme mode, like ml4w-wallpaper: dark when the GTK
# theme prefers dark, light otherwise.
# -----------------------------------------------------
theme_mode() {
    local pref
    pref=$(grep -E '^gtk-application-prefer-dark-theme=' \
        "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null \
        | head -1 | cut -d= -f2 | tr -d '[:space:]' || true)
    case "$pref" in
        1 | true) echo "dark" ;;
        *) echo "light" ;;
    esac
}

# Emergency palette if matugen is unavailable or fails (Catppuccin Mocha).
write_fallback_colors() {
    cat >"$CACHE/colors.rasi" <<'EOF'
* {
    background: rgba(30, 30, 46, 0.75);
    primary: #cba6f7;
    primary-fixed: #cba6f7;
    primary-fixed-dim: #cba6f7;
    on-primary: #1e1e2e;
    on-primary-fixed: #1e1e2e;
    on-primary-fixed-variant: #1e1e2e;
    primary-container: #9a7cd8;
    on-primary-container: #1e1e2e;
    secondary: #bac8db;
    secondary-fixed: #d6e4f7;
    secondary-fixed-dim: #bac8db;
    on-secondary: #1e1e2e;
    on-secondary-fixed: #1e1e2e;
    on-secondary-fixed-variant: #45475a;
    secondary-container: #45475a;
    on-secondary-container: #d6e4f7;
    tertiary: #d6bee5;
    tertiary-fixed: #f2daff;
    tertiary-fixed-dim: #d6bee5;
    on-tertiary: #1e1e2e;
    on-tertiary-fixed: #1e1e2e;
    on-tertiary-fixed-variant: #45475a;
    tertiary-container: #45475a;
    on-tertiary-container: #f2daff;
    error: #f38ba8;
    on-error: #1e1e2e;
    error-container: #f38ba8;
    on-error-container: #1e1e2e;
    surface: #313244;
    on-surface: #cdd6f4;
    on-surface-variant: #cdd6f4;
    outline: #cdd6f4;
    outline-variant: #585b70;
    shadow: #000000;
    scrim: #000000;
    inverse-surface: #cdd6f4;
    inverse-on-surface: #1e1e2e;
    inverse-primary: #cba6f7;
    surface-dim: #1e1e2e;
    surface-bright: #45475a;
    surface-container-lowest: #11111b;
    surface-container-low: #181825;
    surface-container: #313244;
    surface-container-high: #45475a;
    surface-container-highest: #585b70;
}
EOF
}

mkdir -p "$CACHE"

src=$(resolve_image || true)

if [ -n "$src" ]; then
    # Blurred wallpaper for the left panel (ml4w: -resize 75%, blur 50x30).
    # Cached by source path stamp (plus mtime as a safety net).
    if [ ! -f "$CACHE/wallpaper.source" ] \
        || [ "$(cat "$CACHE/wallpaper.source" 2>/dev/null || true)" != "$src" ] \
        || [ ! -f "$CACHE/blurred_wallpaper.png" ] \
        || [ "$src" -nt "$CACHE/blurred_wallpaper.png" ]; then
        magick "$src" -resize 75% "$CACHE/blurred_wallpaper.png"
        magick "$CACHE/blurred_wallpaper.png" -blur 50x30 "$CACHE/blurred_wallpaper.png"
        printf '%s\n' "$src" >"$CACHE/wallpaper.source"
    fi
    printf '* { current-image: url("%s", height); }\n' \
        "$CACHE/blurred_wallpaper.png" >"$CACHE/current_wallpaper.rasi"

    # Material You colors from the same image (ml4w mechanism).
    # Cached by "source path + scheme mode" stamp; retried when matugen
    # fails so the palette always converges back to the wallpaper.
    mode=$(theme_mode)
    stamp="$src|$mode"
    if [ ! -f "$CACHE/colors.rasi" ] \
        || [ ! -f "$CACHE/colors.source" ] \
        || [ "$(cat "$CACHE/colors.source" 2>/dev/null || true)" != "$stamp" ]; then
        if command -v matugen >/dev/null 2>&1 && [ -f "$MATUGEN_CONFIG" ]; then
            if matugen image "$src" --source-color-index 0 -m "$mode" \
                -c "$MATUGEN_CONFIG" >/dev/null 2>&1; then
                printf '%s\n' "$stamp" >"$CACHE/colors.source"
            fi
        fi
        # keep previously generated colors if any, else emergency palette
        [ -f "$CACHE/colors.rasi" ] || write_fallback_colors
    fi
else
    # No wallpaper found: plain frosted launcher without the image
    printf '* { current-image: none; }\n' >"$CACHE/current_wallpaper.rasi"
    [ -f "$CACHE/colors.rasi" ] || write_fallback_colors
fi

exec rofi -show drun -replace -i
