<div align="center">

# dotfiles

My Arch Linux desktop: Hyprland with a Lua config, a Quickshell bar and shell I wrote from scratch, and colors taken from the wallpaper for every themed app.

[![lint](https://github.com/gtsilogiannis/dotfiles/actions/workflows/lint.yml/badge.svg)](https://github.com/gtsilogiannis/dotfiles/actions/workflows/lint.yml)
![last commit](https://img.shields.io/github/last-commit/gtsilogiannis/dotfiles)
![license](https://img.shields.io/github/license/gtsilogiannis/dotfiles)

[How it works](#how-it-works) · [Packages](#packages) · [Install](#install) · [Keybinds](#keybinds)

</div>

| | |
|---|---|
| **WM** | [Hyprland](https://hyprland.org) (Lua config, split into modules) |
| **Shell** | [Quickshell](https://quickshell.org): bar, control center, launcher, notifications, overview, lock screen |
| **Colors** | [matugen](https://github.com/InioX/matugen), Material You from the current wallpaper |
| **Wallpapers** | `awww` for images, `mpvpaper` for video, `rembg` cutouts for depth |
| **Login** | SDDM with an own theme (`gtsilos`) |
| **Terminal** | kitty + zsh + starship, Maple Mono NF |
| **Editor** | Zed (Neovim next) |
| **Files** | Nautilus, yazi |
| **Fonts** | IBM Plex Sans, Maple Mono NF, Roboto Flex |
| **GTK** | adw-gtk3 + matugen colors, Bibata Modern Classic cursor |

## How it works

### Colors from the wallpaper

Picking a wallpaper runs `set-wallpaper.sh`. It sets the image (or a still of the video) and runs matugen, which renders one template per app:

| Template | Output |
|---|---|
| `hyprland.lua` | `~/.config/hypr/colors.lua` |
| `quickshell.json` | `~/.config/quickshell/colors.json` (Quickshell watches it) |
| `kitty.conf` | `~/.config/kitty/colors.conf` |
| `gtk.css` | `~/.config/gtk-{3,4}.0/colors.css` (+ `gsettings` for light / dark) |
| `starship.toml`, `zsh.zsh`, `yazi.toml` | their config folders |
| `zed.json` | `~/.config/zed/themes/gtsilos.json` (Zed reloads it on change) |

The outputs are generated, so they are not in the repo.

### Depth wallpapers

Wallpapers in `~/Pictures/wallpapers/depth/` get a cutout of their subject (`make-depth.sh`, rembg with the `birefnet-general` model, in its own uv venv). Quickshell then draws the clock and the cards between the wallpaper and the cutout, so the subject stands in front of them. Each cutout has a small `.depth.json` with its crop and the layout preset of the widgets.

### Video wallpapers

A video plays with mpvpaper on **one** output (the external monitor if there is one), so there is only one decoder. The other outputs and the lock screen show a still of its first frame. Playback pauses whenever that output shows windows: behind them every frame would make Hyprland redraw and blur the whole screen for nothing.

### Browsing and focus modes

`SUPER + CTRL + BackSpace` switches between two modes:

- **Browsing:** glass windows with blur, gradient borders, the full wallpaper (depth and video included).
- **Focus:** opaque windows, plain borders, its own wallpaper and color scheme, Do Not Disturb on (and back to how it was afterwards).

Each mode remembers its last wallpaper. `SUPER + BackSpace` switches the windows between glass and opaque in browsing. The state lives in `~/.local/state/desktop/` and both Hyprland (`modules/mode.lua`) and Quickshell read it.

### Lock screen

The lock screen is a separate `qs` instance (`lock.sh`) on `ext-session-lock`, so the bar can restart or crash without unlocking anything. The password goes through its own PAM file with `pam_unix` only: no `faillock`, so typos never lock the account, and no `nullok`. The form sits on the side of the wallpaper away from its subject (`form-side.sh`).

### Login screen

The wallpaper picker can also set the login background. `set-login-wallpaper.sh` takes the colors with `matugen --dry-run`, so the desktop colors stay as they are, and hands the image to `sddm-set-background` through `pkexec`. That helper only accepts a PNG or JPEG and a fixed set of theme keys before it writes anything as root.

## Packages

Full lists: [`pkglist.txt`](pkglist.txt) (official repos) and [`pkglist-aur.txt`](pkglist-aur.txt) (AUR).

| Category | Packages |
|---|---|
| Desktop | `hyprland`, `quickshell`, `hypridle`, `hyprsunset`, `hyprpolkitagent`, `xdg-desktop-portal-hyprland`, `sddm` |
| Wallpaper and color | `awww`, `mpvpaper`, `matugen`, `imagemagick`, `resvg` |
| Clipboard and screenshots | `cliphist`, `wl-clipboard`, `grim`, `slurp` |
| Audio and media | `pipewire`, `wireplumber`, `pavucontrol`, `playerctl`, `spotify-launcher` |
| Terminal | `kitty`, `zsh` (+ autosuggestions, syntax highlighting, `fzf-tab`), `starship`, `fastfetch`, `zoxide`, `fzf`, `eza`, `bat`, `ripgrep`, `fd`, `btop` |
| Files | `nautilus`, `nautilus-open-any-terminal`, `yazi`, `gvfs` |
| Editors | `zed`, `neovim`, `micro` |
| Development | `base-devel`, `clang`, `cmake`, `bear`, `valgrind`, `iverilog`, `verilator`, `uv`, `shellcheck`, `shfmt`, `github-cli` |
| Networking and security | `networkmanager`, `bluez`, `bluetui`, `nmap`, `tcpdump`, `python-scapy` |
| Apps | `firefox`, `evince`, `loupe`, `onlyoffice-bin`, `vesktop-bin`, `claude-desktop`, `pomotroid-bin` |
| System | `grub`, `os-prober`, `sbctl`, `zram-generator`, `thermald`, `nvidia-open-dkms`, `intel-media-driver` |
| Fonts and theme | `ttf-ibm-plex`, `maplemono-nf`, `ttf-roboto-flex`, `ttf-material-symbols-variable`, `noto-fonts-emoji`, `adw-gtk-theme`, `bibata-cursor-theme-bin` |

## Layout

Every top-level folder is a [GNU Stow](https://www.gnu.org/software/stow/) package that mirrors `$HOME`, except `system/`, which mirrors `/`.

```
dotfiles/
├── hypr/.config/hypr/
│   ├── hyprland.lua          loads the modules below
│   ├── hypridle.conf
│   ├── modules/
│   │   ├── monitors.lua      outputs and fallbacks
│   │   ├── autostart.lua
│   │   ├── env.lua
│   │   ├── look.lua          gaps, borders, blur, matugen colors
│   │   ├── animations.lua
│   │   ├── input.lua
│   │   ├── binds.lua
│   │   ├── rules.lua         window and layer rules
│   │   └── mode.lua          browsing / focus state
│   └── scripts/
├── quickshell/.config/quickshell/
│   ├── shell.qml             entry point
│   ├── *.qml                 bar, panels, menus, desktop widgets
│   ├── lock/                 lock screen (own qs instance, PAM file)
│   └── scripts/              wallpaper, modes, depth, lock, login
├── matugen/.config/matugen/  config.toml + templates/
├── kitty/ zsh/ fastfetch/ yazi/ zed/ micro/
├── gtk/ fontconfig/ mime/ desktop/ xdg-desktop-portal/ pacman/
├── system/                   files for /etc and /usr (installed with sudo install)
├── pkglist.txt
└── pkglist-aur.txt
```

## Install

> [!WARNING]
> These are the files of one machine (a hybrid Intel / NVIDIA laptop). Read before you copy, especially `system/`, `monitors.lua` and the hardware packages in `pkglist.txt`.

```sh
git clone https://github.com/gtsilogiannis/dotfiles ~/dotfiles
cd ~/dotfiles

sudo pacman -S --needed - < pkglist.txt
yay -S --needed - < pkglist-aur.txt

stow desktop fastfetch fontconfig gtk hypr kitty matugen micro mime pacman \
     quickshell xdg-desktop-portal yazi zed zsh
```

`.stowrc` sets `--no-folding`, so Stow links files and never whole folders. After adding new files to a package, run `stow -R <package>`.

Then generate the colors once. Until then Hyprland, Quickshell and zsh fall back to default colors:

```sh
~/.config/quickshell/scripts/set-wallpaper.sh ~/Pictures/wallpapers/static/<image>
```

Wallpapers go in `~/Pictures/wallpapers/{static,depth,video,focus}/`.

Files in `system/` are copied, not linked, for example:

```sh
sudo install -Dm644 system/etc/sddm.conf.d/theme.conf /etc/sddm.conf.d/theme.conf
sudo install -Dm755 system/usr/local/bin/sddm-set-background /usr/local/bin/sddm-set-background
sudo cp -r system/usr/share/sddm/themes/gtsilos /usr/share/sddm/themes/
```

## Keybinds

All binds are in [`binds.lua`](hypr/.config/hypr/modules/binds.lua).

**Apps and shell**

| Keys | Action |
|---|---|
| `SUPER + Enter` | kitty |
| `SUPER + SPACE` | launcher |
| `SUPER + B` | Firefox |
| `SUPER + D` / `SUPER + SHIFT + D` | Nautilus / yazi |
| `SUPER + N` | control center |
| `SUPER + W` | wallpaper picker |
| `SUPER + Tab` | workspace overview |
| `ALT + ,` | clipboard history |

**Windows and workspaces**

| Keys | Action |
|---|---|
| `SUPER + Q` | close window |
| `SUPER + V` | toggle floating |
| `SUPER + J` | toggle split |
| `SUPER + arrows` | move focus |
| `SUPER + 1-0` / `SUPER + SHIFT + 1-0` | go to / move window to workspace |
| `SUPER + LMB` / `SUPER + RMB` | move / resize window |

**Modes and session**

| Keys | Action |
|---|---|
| `SUPER + CTRL + BackSpace` | browsing / focus mode |
| `SUPER + BackSpace` | glass / opaque windows (browsing) |
| `SUPER + S` / `SUPER + SHIFT + S` | screenshot of the screen / a region to the clipboard |
| `SUPER + L` | lock |
| `ALT + F4` | power menu |
| `SUPER + M` | exit Hyprland |

## License

[GPL-3.0-or-later](LICENSE).
