# Mango rice — modular, matugen-themed

Hand-built Mango (mangowc) setup. Behavior lives in `config.conf`; all colors
are generated from your wallpaper by matugen and written into per-app files.
Switch wallpaper → everything recolors at once.

## How the theming works (the whole trick)

```
wallpaper image
      │
      ▼
   matugen   ──reads──►  ~/.config/matugen/config.toml
      │                       │ (declares one [templates.X] per app)
      │                       ▼
      │                  templates/*  ── filled with palette ──►  each app's color file
      ▼                                                                │
 post_hooks reload each app  ◄───────────────────────────────────────┘
```

matugen extracts a Material Design 3 palette FROM THE WALLPAPER. That means your
colors track the image, not a fixed scheme. If you want a *locked* Tokyo Night
regardless of wallpaper, generate from a color instead:
`matugen color hex "#1a1b26"` — same templates, fixed input.

## Install

```sh
# deps
yay -S matugen-bin            # or build matugen from cargo
# you already have: waybar fuzzel mako foot swaybg grim slurp

# 1. compositor config + scripts
mkdir -p ~/.config/mango
cp config.conf autostart.sh theme-switch.sh ~/.config/mango/
# (keep your existing config.jsonc, style.css, screenshot.sh, waybar-reload.sh)
chmod +x ~/.config/mango/{autostart,theme-switch}.sh

# 2. matugen
mkdir -p ~/.config/matugen/templates
cp config.toml ~/.config/matugen/
cp templates/* ~/.config/matugen/templates/

# 3. wire each app to include its generated color file (ONE TIME):
#   waybar style.css  : add at top ->   @import "colors.css";
#   fuzzel.ini        : add        ->   include=~/.config/fuzzel/colors.ini
#   mako config       : add        ->   include=~/.config/mako/colors
#   foot.ini          : add        ->   include=~/.config/foot/colors.ini

# 4. first run — generates every color file + sets wallpaper
~/.config/mango/theme-switch.sh ~/Pictures/Wallpapers/your-wall.jpg
```

## Daily use

| Action | Command / bind |
| --- | --- |
| Pick wallpaper + retheme | `theme-switch.sh` (fuzzel menu) |
| Random wallpaper + retheme | `theme-switch.sh --random` |
| Reload mango config | `SUPER+SHIFT+R` (`mmsg -d reload_config`) |
| Reload waybar | `SUPER+R` |
| Check config for errors | `mango -p` |

Bind the switcher in `config.conf` if you want, e.g.:
`bind=SUPER+SHIFT,w,spawn,/home/kl/.config/mango/theme-switch.sh`

## Keybind map (SUPER = main mod)

- **focus**: SUPER + h/j/k/l
- **move/swap window**: SUPER+SHIFT + h/j/k/l
- **resize**: SUPER+CTRL + h/j/k/l
- **nudge floating**: SUPER+ALT + h/j/k/l
- **tags view**: SUPER + 1–9   ·   **send to tag**: SUPER+SHIFT + 1–9
- **launch**: SUPER+Return (foot), SUPER+space (fuzzel)
- **overview**: SUPER+grave   ·   **scratchpad**: SUPER+z
- arrows are intentionally free for use inside apps

## What I changed from your original

- Killed duplicate binds (SUPER+S/s, SUPER+R x2, SUPER+Tab conflict)
- Removed the doubled `source` of noctalia.conf, ripped noctalia entirely
- Colors moved out of config.conf into matugen-generated theme.conf
- `source-optional` so a fresh box doesn't hard-error before first matugen run
- Removed the portal double-spawn race (was both exec-once AND systemctl restart)
- **Added `XDG_SESSION_TYPE=wayland` to autostart** — this was breaking your GPU tooling
- autostart now restores last wallpaper on boot + launches mako
- tag 2 set to scroller layout so you keep a niri-style workflow

## Adding more apps to the theme later

1. write `templates/<app>-colors.<ext>` with `{{colors.NAME.default.hex}}` placeholders
2. add a `[templates.<app>]` block to `config.toml` (input/output/post_hook)
3. add the include line to that app's main config
4. re-run `theme-switch.sh`
