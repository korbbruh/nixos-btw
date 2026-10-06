# nixos-btw

Two-host NixOS config. MangoWM with the Noctalia shell; Plasma 6 is installed
for presenting and for days when debugging is not an option. System config and
dotfiles live in this one repo.

## Hosts

| host | hostname | hardware | default session |
|---|---|---|---|
| g15 | `nixos-btw` | ASUS ROG Zephyrus G15 GA503QR, Renoir iGPU + RTX 3070 Mobile (PRIME offload), 2560x1440 165Hz `eDP-1` | Mango |
| terra | `terra` | Ryzen 7 5700X + RX 7800XT, 1080p `DP-2`, single AMD GPU | Plasma |

## Layout

```
flake.nix                two nixosConfigurations, shared module list
modules/common.nix       both machines: boot, locale, audio, networking + DNS,
                         bluetooth/power services, Thunar, Flatpak, Steam,
                         nix settings, packages
modules/desktop.nix      Mango, Plasma 6, Niri, Noctalia + greeter, portals,
                         mango-session.target, xwayland-satellite
hosts/g15/               NVIDIA offload, asusd, supergfxd, powertop, lid,
                         default session, 144 DPI for XWayland
hosts/terra/             default session; nothing else is Terra-specific
home/common.nix          home-manager: fish, starship, cursor, icon theme,
                         dotfile links
home/kl.nix              G15 user
home/keri.nix            Terra user
home/dotfiles/           mango, foot, btop, noctalia; symlinked into ~/.config
```

Each host sets `services.displayManager.defaultSession` directly. The G15 also
adds an `xrdb` step to the shared `xwayland-satellite` unit for 144 DPI; Terra
uses XWayland's default 96.

`home/dotfiles/` is linked with `mkOutOfStoreSymlink`, so `~/.config/mango`
etc. point at **writable** paths in this repo, not `/nix/store`. Two reasons:
edits take effect without a rebuild, and Noctalia writes its generated colour
files into these folders at runtime.

---

## Daily workflow

```
nixre        # rebuild only. the everyday one.
nixpush      # rebuild + commit (opens editor) + pull --rebase + push
nixpull      # pull the other machine's changes and rebuild
nixup        # flake update + rebuild + commit + push. WEEKLY, ONE MACHINE ONLY.
```

**Editing dotfiles** (anything under `home/dotfiles/`): edit, it takes effect
immediately, no rebuild. Mango: `SUPER+SHIFT+R` reloads, `mango -p` checks the
config for errors. Commit when you want it recorded:

```
cd ~/nixos && git add -A && git commit -m "..." && git push
```

**Editing system config** (`modules/`, `hosts/`, `home/common.nix`): edit,
then `nixre`. When unsure, `nixos-rebuild build --flake .#<host>` first.

**Checking the other host from this one** (evaluates, builds nothing):

```
nix eval .#nixosConfigurations.terra.config.system.build.toplevel.drvPath
```

**Adding a new dotfile directory**: create it under `home/dotfiles/`, add the
`xdg.configFile` line to `home/common.nix`, then `nixre`. First time only.

**Never run `nixup` on both machines.** Both regenerate `flake.lock` from the
same parent and it conflicts every time. Update on one, `nixpull` on the other.

**Never use `nixos-rebuild --upgrade`.** That is the channels workflow. This
is a flake.

---

## Recovery

```
nixos-rebuild build --flake ~/nixos      # evaluate + build, do not activate
sudo nixos-rebuild switch --rollback     # undo the last switch
```

Or pick an older generation from the systemd-boot menu. `git log --oneline`
is the other safety net.

If the session is broken and you cannot reach a terminal: `Ctrl+Alt+F2` for a
TTY. If only Mango is broken, log into Plasma from the greeter.

---

## Reading errors

Nix errors are verbose. The useful line is near the **bottom**; everything
above is stack trace.

| message | meaning |
|---|---|
| `The option 'x' does not exist` | wrong option name. look it up, do not guess |
| `attribute 'x' already defined at line N` | you pasted a block that already exists. grep before pasting |
| `syntax error, unexpected end of file` | unclosed `{` or missing `;` **earlier** than the reported line |
| `is not of type 'list of string'` | a list option got a bare string. wrap it: `[ "..." ]` |
| `Default graphical session, "...", not found` | `defaultSession` takes a session **name** (`mango`, `plasma`, `niri`), not a command. the error lists the valid names |
| `file 'nixos-config' was not found` | you dropped `--flake`, or used `--upgrade` |
| `path '//x' does not exist` | a flake input URL lost its `github:` prefix |
| `error: undefined variable 'prev'` | an overlay body without its `(final: prev: { ... })` wrapper |
| `hash mismatch ... got: sha256-...` | expected when using `lib.fakeHash`. paste the `got:` value in and rebuild |

Faster syntax check than a full rebuild:

```
nix-instantiate --parse <file> > /dev/null && echo OK
```

## Finding option names

Never guess. In order of usefulness:

```
man configuration.nix        # then search for the option
nix search nixpkgs <pkg>
```

search.nixos.org is the same data, easier to read. When docs are thin, read
the module source in nixpkgs. For Noctalia, `noctalia msg --help` lists every
IPC command and docs.noctalia.dev has the rest.

---

## Fresh install

1. Install NixOS (any installer; this config replaces whatever it sets up).
2. `sudo cp /etc/nixos/hardware-configuration.nix ~/hw-backup.nix`
3. `grep stateVersion /etc/nixos/configuration.nix`, and note the value.
4. `git clone https://github.com/korbbruh/nixos-btw.git ~/nixos`
   (HTTPS until you have an SSH key on the machine)
5. `cp ~/hw-backup.nix ~/nixos/hosts/<host>/hardware-configuration.nix`
6. Set `system.stateVersion` in `hosts/<host>/default.nix` to the value from step 3.
7. `cd ~/nixos && git add -A`. **Flakes ignore untracked files.**
8. `sudo nixos-rebuild switch --flake ~/nixos#<host>`
9. Log in. Noctalia generates its colour files on first start, using the
   templates listed in `home/dotfiles/noctalia/templates.toml`.

**`hardware-configuration.nix` is per machine.** It holds filesystem UUIDs.
Never reuse one host's on another.

### Not restored automatically

**SSH keys.**

```
ssh-keygen -t ed25519 -C "laceras.korb@gmail.com"
cat ~/.ssh/id_ed25519.pub    # add to GitHub, then:
cd ~/nixos && git remote set-url origin git@github.com:korbbruh/nixos-btw.git
```

**Noctalia's GUI settings.** Bar layout, idle timers, plugins and the wallpaper
directory live in `~/.local/state/noctalia/settings.toml`, not in this repo.
Only `templates.toml` is tracked. Copy `settings.toml` across, or move the
settings you care about into a `.toml` under `home/dotfiles/noctalia/`.

**Flatpak GTK theme.** Flatpak apps are sandboxed from host themes:

```
flatpak install flathub org.gtk.Gtk3theme.adw-gtk3-dark
flatpak override --user --env=GTK_THEME=adw-gtk3-dark
```

**Flatpak 32-bit runtimes** (Wine-based game launchers need them, and the
host's 32-bit libraries do not reach the sandbox):

```
flatpak install flathub org.freedesktop.Platform.Compat.i386//25.08
flatpak install flathub org.freedesktop.Platform.GL32.default//25.08
```

Match the branch to the installed `org.freedesktop.Platform`. The G15 also
wants the `GL32.nvidia-<driver>` extension matching its driver version.

**Neovim.** Stock LazyVim starter, not tracked here:

```
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

**Wallpapers.** `~/Pictures/Wallpapers`. Not in the repo.

---

## Noctalia

Noctalia provides the bar, launcher, OSD, notifications, polkit agent, idle,
lock screen, wallpaper, clipboard, night light, caffeine and colour theming.

- **Started from `autostart.sh`, not a systemd unit.** Its FAQ says to use the
  compositor's autostart. Running both launched it twice.
- **Keybinds call its IPC**: `noctalia msg <command>`. Everything is in
  `home/dotfiles/mango/keybinds.conf`.
- **Its widgets need system services** that live in `modules/common.nix`:
  NetworkManager, Bluetooth, power-profiles-daemon, upower.

---

## Theming

Noctalia owns colour. Its templates write per-app colour files; which ones run
is declared in `home/dotfiles/noctalia/templates.toml`. On a machine that
already has GUI settings, `~/.local/state/noctalia/settings.toml` overrides
that file, so toggle templates in Settings → Templates there too.

**Generated at runtime, gitignored:**

```
foot/themes/noctalia     btop/themes/noctalia.theme     mango/noctalia.conf
mango/monitors.conf      (Noctalia display plugin; not sourced, see below)
```

**GTK.** The `gtk3`/`gtk4` templates write `gtk-{3,4}.0/noctalia.css`, import
it from `gtk.css`, and switch GTK to `adw-gtk3`. **`adw-gtk3` must be
installed**: without it the hook silently skips setting the theme. GTK's
`settings.ini` is not managed by home-manager.

**Icons.** Papirus-Dark from the store, set by the `dconf.settings` line in
`home/common.nix`. Folder recolouring is not used: Noctalia's `papirus-icons`
template checks `/usr/share/icons`, which NixOS does not have, so it does
nothing here.

**Qt.** Apps launched from Mango read `QT_QPA_PLATFORMTHEME=gtk3` from
`env.conf`.

**Monitors.** `mango/monitor.conf` is hand-written and covers both machines.
The Noctalia display plugin writes `monitors.conf` per machine; it is
deliberately not sourced, because it would flip between G15 and Terra in a
shared repo.

---

## Gotchas that have actually bitten

- **Untracked files are invisible to flakes.** New file → `git add` it before
  rebuilding, or Nix acts like it does not exist.

- **Stale `.hm-bak` files break home-manager.** It refuses to overwrite an
  existing backup, so the second time it needs to back up the same path it
  fails the whole activation. `find ~ -maxdepth 3 -name '*.hm-bak' -delete`.

- **Plasma rewrites GTK files.** Logging into Plasma regenerates
  `~/.config/gtk-{3,4}.0/settings.ini` and `colors.css`, which then override
  Noctalia's GTK theme in Mango (light, Breeze-coloured apps). Move them aside
  and flip Noctalia's theme mode to re-render.

- **systemd user services do not inherit the compositor environment.** Anything
  set in mango's `env.conf` is invisible to them. Set it on the unit
  (`environment = { ... }`).

- **`graphical-session.target` is not reached by Mango on its own.** The
  `mango-session.target` unit in `modules/desktop.nix` plus these two lines in
  `autostart.sh` make it activate, which portals and `xwayland-satellite`
  depend on. Run them in order, **not** backgrounded with `&`:

  ```sh
  systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
  systemctl --user start mango-session.target
  ```

- **Overriding a package's version needs its `src` too.** Changing only
  `version` keeps the old source (or 404s on a tag that does not exist). Rust
  packages also need `cargoDeps`. Use `lib.fakeHash` and paste in each `got:`
  hash. Delete the overlay once nixpkgs catches up, or it pins you to the old
  version.

- **Router DNS was resolving in 5-8 seconds.** Everything felt slow while raw
  pings were fine. `common.nix` bypasses it with Cloudflare and
  `networkmanager.dns = "none"`. Check with:

  ```
  curl -o /dev/null -s -w "%{time_namelookup}\n" https://google.com
  ```

- **Kill old instances after converting something to a systemd unit.** An
  orphan from a manual test looks identical in `pgrep` and will silently keep
  working while the unit reports inactive. `pgrep -af <name>` shows the full
  command line, which is how you tell them apart.

- **`nixos-rebuild` does not always restart home-manager.** If a dotfile link
  does not appear after a rebuild, `systemctl restart home-manager-$USER`.

- **A rebuild that changes networking drops your wifi mid-command.** Do not
  chain a `git push` onto it.

- **Nix string interpolation.** Inside `''...''`, `${x}` interpolates and `$`
  needs escaping as `''$`. This is why pasting shell scripts into `.text = ''`
  blocks goes wrong. Prefer `.source = ./path/to/file` or
  `mkOutOfStoreSymlink`.

---

## Known unresolved

- **TwintailLauncher can't launch games.** Its SteamLinuxRuntime downloads come
  out incomplete (upstream TwintailTeam/TwintailLauncher#290, a CDN problem).
  Workaround from that thread: extract Valve's `SteamLinuxRuntime_sniper` and
  `SteamLinuxRuntime_4` tarballs into
  `~/.var/app/app.twintaillauncher.ttl/data/twintaillauncher/compatibility/runners/steamrt/steamrt3`
  and `steamrt4` with `tar -xf <tarball> -C <dir> --strip-components=1`. The
  launcher may re-download over them.

- **Noctalia compiles on every update.** Its flake input follows this repo's
  nixpkgs, which disables its binary cache.

- **G15 backlight above ~95% used to dim instead of brightening.** Newer
  kernels fixed it. If it returns, add `amdgpu.dcdebugmask=0x40000` to
  `boot.kernelParams` in `hosts/g15/default.nix`.
