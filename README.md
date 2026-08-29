# nixos-btw

Two-host NixOS config. MangoWM, no desktop environment. System config and
dotfiles live in this one repo.

## Hosts

| host | hostname | hardware |
|---|---|---|
| g15 | `nixos-btw` | ASUS ROG Zephyrus G15 GA503QR, Renoir iGPU + RTX 3070 Mobile (PRIME offload), 2560x1440 165Hz `eDP-1` |
| terra | `terra` | Ryzen 7 5700X + RX 7800XT, 1080p `DP-2`, single AMD GPU |

## Layout

```
flake.nix                two nixosConfigurations, shared module list
modules/common.nix       hardware-agnostic: packages, nix, locale, audio, shell
modules/desktop.nix      mango, greetd, portals, qt, systemd user services
                         declares korb.display.{output,dpi,autologinUser}
hosts/g15/               nvidia offload, asusd, power mgmt, iwd, backlight quirk
hosts/terra/             amdgpu only, iwd, no laptop anything
home/common.nix          home-manager: fish, starship, gtk, cursor, dotfile links
home/kl.nix              G15 user
home/keri.nix            Terra user
home/dotfiles/           the actual rice, symlinked into ~/.config
```

`home/dotfiles/` is linked with `mkOutOfStoreSymlink`, so `~/.config/mango`
etc. point at **writable** paths in this repo, not `/nix/store`. That is
deliberate: `theme-pick.sh` rewrites colour files at runtime and cannot write
to the store.

---

## Daily workflow

```
nixre        # rebuild only. the everyday one.
nixpush      # rebuild + commit (opens editor) + pull --rebase + push
nixpull      # pull the other machine's changes and rebuild
nixup        # flake update + rebuild + commit + push. WEEKLY, ONE MACHINE ONLY.
```

**Editing dotfiles** (anything under `home/dotfiles/`): edit, it takes effect
immediately, no rebuild. Commit when you want it recorded.

```
cd ~/nixos && git add -A && git commit -m "..." && git push
```

**Editing system config** (`modules/`, `hosts/`, `home/common.nix`): edit,
then `nixre`.

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
TTY.

---

## Reading errors

Nix errors are verbose. The useful line is near the **bottom**; everything
above is stack trace.

| message | meaning |
|---|---|
| `The option 'x' does not exist` | wrong option name. look it up, do not guess |
| `attribute 'x' already defined at line N` | you pasted a block that already exists. grep before pasting |
| `syntax error, unexpected end of file` | unclosed `{` or missing `;` **earlier** than the reported line |
| `file 'nixos-config' was not found` | you dropped `--flake`, or used `--upgrade` |
| `path '//x' does not exist` | a flake input URL lost its `github:` prefix |
| `error: undefined variable 'prev'` | an overlay body without its `(final: prev: { ... })` wrapper |

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
the module source in nixpkgs.

---

## Fresh install

1. Install NixOS (any installer; this config replaces whatever it sets up).
2. `sudo cp /etc/nixos/hardware-configuration.nix ~/hw-backup.nix`
3. `grep stateVersion /etc/nixos/configuration.nix` — note the value.
4. `git clone https://github.com/korbbruh/nixos-btw.git ~/nixos`
   (HTTPS until you have an SSH key on the machine)
5. `cp ~/hw-backup.nix ~/nixos/hosts/<host>/hardware-configuration.nix`
6. Set `system.stateVersion` in `hosts/<host>/default.nix` to the value from step 3.
7. `cd ~/nixos && git add -A` — **flakes ignore untracked files**
8. `sudo nixos-rebuild switch --flake ~/nixos#<host>`

**`hardware-configuration.nix` is per machine.** It holds filesystem UUIDs.
Never reuse one host's on another.

### Not restored automatically

**SSH keys.**

```
ssh-keygen -t ed25519 -C "laceras.korb@gmail.com"
cat ~/.ssh/id_ed25519.pub    # add to GitHub, then:
cd ~/nixos && git remote set-url origin git@github.com:korbbruh/nixos-btw.git
```

**Papirus icon recolouring.** `theme-pick.sh` recolours folders in place, so it
needs a writable user-owned copy. Papirus-Dark symlinks *into* Papirus, so you
must copy **both**, and with `cp -a` (plain `cp -r` dereferences the symlinks
and produces a broken theme that crashes Thunar):

```
p=$(nix build nixpkgs#papirus-icon-theme --no-link --print-out-paths)
cp -a $p/share/icons/Papirus      ~/.local/share/icons/
cp -a $p/share/icons/Papirus-Dark ~/.local/share/icons/
chmod -R u+w ~/.local/share/icons/Papirus{,-Dark}
```

**Flatpak GTK theme.** Flatpak apps are sandboxed from host themes:

```
flatpak install flathub org.gtk.Gtk3theme.adw-gtk3-dark
flatpak override --user --env=GTK_THEME=adw-gtk3-dark
```

**Neovim.** Stock LazyVim starter, not tracked here:

```
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

**Wallpapers.** `~/Pictures/Wallpapers`. Not in the repo.

Then run `~/.config/mango/theme-pick.sh` once to generate the colour files.

---

## Gotchas that have actually bitten

- **Untracked files are invisible to flakes.** New file → `git add` it before
  rebuilding, or Nix acts like it does not exist.

- **Stale `.hm-bak` files break home-manager.** It refuses to overwrite an
  existing backup, so the second time it needs to back up the same path it
  fails the whole activation. `find ~ -maxdepth 3 -name '*.hm-bak' -delete`.

- **systemd user services do not inherit the compositor environment.** Anything
  set in mango's `env.conf` is invisible to them. Set it on the unit
  (`environment = { ... }`), as the polkit agent does for `QT_QPA_PLATFORMTHEME`.

- **`graphical-session.target` is not reached by Mango on its own.** The
  `mango-session.target` unit in `modules/desktop.nix` plus these two lines in
  `autostart.sh` are what make it activate, which is what portals depend on:

  ```sh
  systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
  systemctl --user start mango-session.target
  ```

- **Kill old instances after converting something to a systemd unit.** An
  orphan from a manual test looks identical in `pgrep` and will silently keep
  working while the unit reports inactive. `pgrep -af <name>` shows the full
  command line, which is how you tell them apart.

- **`nixos-rebuild` does not always restart home-manager.** If a dotfile link
  does not appear after a rebuild, `systemctl restart home-manager-$USER`.

- **A rebuild that changes networking drops your wifi mid-command.** Do not
  chain a `git push` onto it.

- **`git add -A` is safe in this repo** (everything here is config) but was
  never safe in the old bare dotfiles repo, where the work tree was `$HOME`.

- **Nix string interpolation.** Inside `''...''`, `${x}` interpolates and `$`
  needs escaping as `''$`. This is why pasting shell scripts into `.text = ''`
  blocks goes wrong. Prefer `.source = ./path/to/file` or
  `mkOutOfStoreSymlink`.

- **Nerd Font glyphs do not survive copy-paste reliably.** Use `$'\ue30d'`
  escapes in scripts, and verify with `printf '\ue30d\n'` before committing.

---

## Theming boundary

`theme-pick.sh` rewrites these at runtime. They are gitignored and must stay
**writable**, which is why `home/dotfiles/` uses `mkOutOfStoreSymlink` rather
than plain home-manager file management:

```
foot/colors.ini          waybar/colors.css        rofi/colors.rasi
mango/theme.conf         mako/config              cava/config
swayosd/style.css        swaylock/config          yazi/
btop/themes/current.theme                nvim/lua/plugins/theme.lua
```

Also mutable and not tracked: `~/.local/share/icons/Papirus-Dark`
(papirus-folders recolours in place) and `~/.cache/current-*`.

**GTK theming ownership:** home-manager owns `gtk-3.0/settings.ini` and
`gtk-4.0/settings.ini`. `nwg-look` cannot write those (store symlinks) but it
*does* create the `gtk-4.0/{assets,gtk.css,gtk-dark.css}` symlinks that
libadwaita apps need, so keep it installed.

`iconTheme` has a `name` but deliberately **no `package`**. With a package,
GTK resolves Papirus-Dark from the store and the recoloured copy in
`~/.local/share/icons` is ignored.

**Qt theming:** apps launched from the compositor read
`QT_QPA_PLATFORMTHEME=gtk3` from `env.conf`. The polkit agent is a systemd
service so it gets `gnome` on its unit instead. Both work; do not "fix" either.

---

## Known unresolved

- **waybar `mango/*` modules.** nixpkgs waybar (0.15.0) predates them; using
  `ext/workspaces` as a stand-in. Building from git needs an overlay with a
  bumped `src`, `modemmanager` in `buildInputs`, and cava disabled. Revisit
  when nixpkgs ships a release that has them.

- **Backlight above ~95% dims instead of brightening.** Fixed with
  `amdgpu.dcdebugmask=0x40000`. Reproduced on CachyOS first, so it is a
  driver/panel quirk, not a config problem.

- **swayidle's `-w` flag** fails against systemd 261 (`BlockInhibited` parse
  error). Dropped; lock-before-suspend fires without waiting.
