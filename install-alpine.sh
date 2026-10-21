#!/bin/sh
# Install everything this dwl build needs on Alpine Linux, build and install
# dwl, and copy the configs in config/ into ~/.config.
# Run as your normal user (not root); privileged steps go through doas.
# Safe to re-run.
set -eu

REPO=$(cd "$(dirname "$0")" && pwd)
BIBATA_VERSION=v2.0.7
WAYFREEZE_TAG=0.2.1
MARKSMAN_VERSION=2026-02-08

say() { printf '\033[1;33m==> %s\033[0m\n' "$*"; }
ask() { printf '\033[1;33m==> %s [y/N] \033[0m' "$*"; read -r a; [ "$a" = y ] || [ "$a" = Y ]; }

[ "$(id -u)" -ne 0 ] || { echo "run as your normal user, not root" >&2; exit 1; }
command -v doas >/dev/null || { echo "doas is required" >&2; exit 1; }

# --- Packages ----------------------------------------------------------------

# cliphist, wl-clip-persist and wiremix only exist in edge/testing. They are
# pinned with @testing so nothing else gets pulled from edge.
if ! grep -q '^@testing ' /etc/apk/repositories; then
	say "Adding pinned @testing repository"
	mirror=$(grep -m1 -E '^https?://.*/main$' /etc/apk/repositories | sed -E 's#/(v[0-9.]+|edge)/main$##')
	echo "@testing $mirror/edge/testing" | doas tee -a /etc/apk/repositories >/dev/null
fi

say "Installing packages"
doas apk update
doas apk add \
	build-base pkgconf git curl xz \
	wayland-dev wayland-protocols wlroots0.20-dev libinput-dev \
	libxkbcommon-dev libxcb-dev xcb-util-wm-dev \
	cargo \
	dbus seatd xwayland mesa-dri-gallium \
	foot foot-themes fuzzel mako swaylock swaybg waybar \
	wl-clipboard grim slurp brightnessctl libnotify \
	pipewire pipewire-pulse wireplumber \
	iwd iwd-openrc impala openresolv \
	bluez bluez-openrc pipewire-spa-bluez \
	xdg-desktop-portal xdg-desktop-portal-wlr \
	font-meslo-nerd zzz yazi yazi-cli lazygit \
	cliphist@testing wl-clip-persist@testing wiremix@testing bluetui@testing

# brightnessctl's udev rule only applies on device add, so replay the events
# instead of needing a reboot before the brightness keys work
doas udevadm trigger --action=change --subsystem-match=backlight --subsystem-match=leds

# --- Programs not packaged for Alpine ------------------------------------------

if ! command -v wayfreeze >/dev/null; then
	say "Building wayfreeze $WAYFREEZE_TAG"
	tmp=$(mktemp -d)
	cargo install --locked --git https://github.com/Jappie3/wayfreeze \
		--tag "$WAYFREEZE_TAG" --root "$tmp" wayfreeze
	doas install -m755 "$tmp/bin/wayfreeze" /usr/local/bin/wayfreeze
	rm -rf "$tmp"
fi

if [ ! -d /usr/share/icons/Bibata-Modern-Ice ]; then
	say "Installing Bibata-Modern-Ice cursors $BIBATA_VERSION"
	tmp=$(mktemp -d)
	curl -fL -o "$tmp/bibata.tar.xz" \
		"https://github.com/ful1e5/Bibata_Cursor/releases/download/$BIBATA_VERSION/Bibata-Modern-Ice.tar.xz"
	xz -dc "$tmp/bibata.tar.xz" | doas tar -x -f - -C /usr/share/icons
	rm -rf "$tmp"
fi

# --- System services and permissions -------------------------------------------

say "Enabling services"
for svc in dbus seatd bluetooth; do
	doas rc-update add "$svc" default >/dev/null 2>&1 || true
	doas rc-service "$svc" start >/dev/null 2>&1 || true
done

for g in seat video input audio netdev; do
	id -nG | tr ' ' '\n' | grep -qx "$g" || doas addgroup "$(id -un)" "$g"
done

# Power actions from the dwl-cmd session menu run without a terminal
say "Writing /etc/doas.d/dwl.conf"
doas tee /etc/doas.d/dwl.conf >/dev/null <<-'EOF'
	permit nopass :wheel as root cmd /usr/sbin/zzz
	permit nopass :wheel as root cmd /sbin/reboot
	permit nopass :wheel as root cmd /sbin/poweroff
EOF
doas chmod 600 /etc/doas.d/dwl.conf

# Wi-Fi: replace wpa_supplicant with iwd so impala works (dwl-cmd control menu)
if ! rc-update show default 2>/dev/null | grep -qw iwd; then
	say "Wi-Fi switches from wpa_supplicant to iwd. This drops the current"
	say "connection (including SSH over Wi-Fi); reconnect afterwards with impala"
	say "or: iwctl station wlan0 connect <SSID>"
	if ask "Switch to iwd now?"; then
		doas tee /etc/iwd/main.conf >/dev/null <<-'EOF'
			[General]
			EnableNetworkConfiguration=true

			[Network]
			NameResolvingService=resolvconf
		EOF
		# iwd does its own DHCP: stop ifupdown from running udhcpc on wlan0
		doas sed -i -E 's/^(auto wlan0|iface wlan0.*)$/# \1  # managed by iwd/' /etc/network/interfaces
		doas rc-service wpa_supplicant stop >/dev/null 2>&1 || true
		doas rc-update del wpa_supplicant boot >/dev/null 2>&1 || true
		doas rc-update del wpa_supplicant default >/dev/null 2>&1 || true
		doas rc-update add iwd default >/dev/null 2>&1 || true
		doas rc-service iwd start
	else
		say "Skipped; the Wi-Fi entry in the control menu won't work until iwd runs"
	fi
fi

# --- dwl ---------------------------------------------------------------------

say "Building and installing dwl"
make -C "$REPO"
doas make -C "$REPO" install

# --- User config -------------------------------------------------------------

# Copied, not linked, so the desktop keeps working without this repo.
# Files that differ from the repo version are backed up before being replaced;
# anything else already in ~/.config is left alone.
say "Copying configs into ~/.config"
ts=$(date +%s)
for dir in "$REPO"/config/*/; do
	dst=$HOME/.config/$(basename "$dir")
	if [ -L "$dst" ]; then
		rm "$dst"
	fi
done
(cd "$REPO/config" && find . -type f) | while read -r f; do
	src=$REPO/config/${f#./}
	dst=$HOME/.config/${f#./}
	cmp -s "$src" "$dst" && continue
	mkdir -p "$(dirname "$dst")"
	if [ -e "$dst" ]; then
		mv "$dst" "$dst.bak.$ts"
		say "Backed up $dst"
	fi
	cp "$src" "$dst"
done

if [ ! -d "$HOME/.config/yazi/plugins/lazygit.yazi" ]; then
	say "Installing yazi lazygit plugin"
	ya pkg add Lil-Dank/lazygit || say "ya pkg add failed; run it again later"
fi

# --- Neovim (config/nvim) ------------------------------------------------------

say "Installing Neovim and language tooling"
doas apk add neovim tree-sitter-cli nodejs npm ripgrep fd \
	shfmt shellcheck taplo deno libxml2-utils dotnet10-sdk

# Not packaged for Alpine: npm servers into ~/.local, musl build of marksman
mkdir -p "$HOME/.local/bin" "$HOME/.local/share"
npm install -g --prefix "$HOME/.local" bash-language-server vscode-langservers-extracted

if [ ! -x "$HOME/.local/bin/marksman" ]; then
	say "Installing marksman $MARKSMAN_VERSION"
	curl -fL -o "$HOME/.local/bin/marksman" \
		"https://github.com/artempyanykh/marksman/releases/download/$MARKSMAN_VERSION/marksman-linux-musl-x64"
	chmod 755 "$HOME/.local/bin/marksman"
fi

# These land in ~/.dotnet/tools, which /etc/profile.d/dotnet.sh puts on PATH
dotnet tool update -g csharpier >/dev/null
dotnet tool update -g roslyn-language-server --prerelease >/dev/null

# Clone plugins (pinned by nvim-pack-lock.json) and compile treesitter parsers
say "Installing Neovim plugins and treesitter parsers"
nvim --headless +"lua require('nvim-treesitter').install(vim.g.ts_parsers):wait(300000)" +qa

if ! grep -q '^export EDITOR=' "$HOME/.profile" 2>/dev/null; then
	if [ -s "$HOME/.profile" ]; then
		sed -i '1i export EDITOR=nvim' "$HOME/.profile"
	else
		echo 'export EDITOR=nvim' >> "$HOME/.profile"
	fi
fi

# Start dwl through dwl-session when logging in on tty1
if [ -f "$HOME/.profile" ] && grep -q 'exec dbus-run-session dwl$' "$HOME/.profile"; then
	say "Updating ~/.profile to start dwl-session"
	sed -i 's/exec dbus-run-session dwl$/exec dwl-session/' "$HOME/.profile"
elif ! grep -q dwl-session "$HOME/.profile" 2>/dev/null; then
	say "Add this to ~/.profile to start dwl on tty1 login:"
	echo '  [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = /dev/tty1 ] && exec dwl-session'
fi

say "Done. Log out and back in on tty1 (group changes need a new login)."
