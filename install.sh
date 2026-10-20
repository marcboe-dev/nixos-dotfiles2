# Nutzung: install <host> [laptop]
#   host: Ordnername unter hosts/ (z.B. thinkpad, vm)
#   laptop: nur nötig, wenn hosts/<host> noch nicht existiert
#           (legt einen neuen Laptop-Host mit den Daten dieser Maschine an)
NAME="${1:?Nutzung: install <host> [laptop]}"
TYP="${2:-}"

REPO="https://github.com/marcboe-dev/nixos-dotfiles2.git"
DIR="$HOME/nixos-dotfiles"
HOSTDIR="hosts/$NAME"
HW="$HOSTDIR/hardware-configuration.nix"

# systemd-boot braucht UEFI
if [ ! -d /sys/firmware/efi ]; then
  echo "FEHLER: System läuft nicht im UEFI-Modus. Die Config nutzt systemd-boot."
  echo "Im BIOS/UEFI auf UEFI-Boot umstellen und NixOS neu installieren."
  exit 1
fi

[ -d "$DIR" ] || git clone "$REPO" "$DIR"
cd "$DIR"

# ── Neuen Laptop-Host anlegen ──────────────────────────────────
if [ ! -d "$HOSTDIR" ]; then
  if [ "$TYP" != "laptop" ]; then
    echo "Host '$NAME' existiert nicht unter hosts/."
    echo "Neuen Laptop anlegen mit: install $NAME laptop"
    exit 1
  fi

  mkdir -p "$HOSTDIR"

  # Internes Display (EDID) dieser Maschine direkt aus /sys lesen
  EDIDFILE=""
  for f in /sys/class/drm/card*-eDP-*/edid /sys/class/drm/card*-LVDS-*/edid; do
    if [ -e "$f" ]; then EDIDFILE="$f"; break; fi
  done

  if [ -n "$EDIDFILE" ]; then
    PANEL="$(basename "$(dirname "$EDIDFILE")" | sed 's/^card[0-9]*-//')"
    EDID="$(od -An -tx1 "$EDIDFILE" | tr -d ' \n')"
  else
    PANEL="eDP-1"
    EDID=""
    echo "WARNUNG: Kein internes Display gefunden. autorandr bleibt aus,"
    echo "         bis edidLaptop in $HOSTDIR/machine.nix gesetzt ist."
  fi

  cat > "$HOSTDIR/default.nix" <<'EOF'
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    (import ../laptop-common.nix (import ./machine.nix))
  ];
}
EOF

  cat > "$HOSTDIR/machine.nix" <<EOF
{
  panel = "$PANEL";
  edidLaptop = "$EDID";
  speakerCard = null; # optional: Soundkarten-Name aus pactl list cards short
}
EOF

  echo "Neuer Laptop-Host '$NAME' angelegt."
fi

# ── Hardware-Config dieser Maschine übernehmen ─────────────────
# Bei der VM ist ein Unterschied normal (jede VM hat neue UUIDs), daher keine Rückfrage.
if [ "$NAME" != "vm" ] && [ -f "$HW" ] && ! cmp -s /etc/nixos/hardware-configuration.nix "$HW"; then
  echo "ACHTUNG: Die Hardware-Config von '$NAME' weicht von dieser Maschine ab."
  echo "Normal bei einer Neuinstallation DERSELBEN Maschine."
  echo "FALSCH, wenn das eine andere Maschine ist (dann bootet der andere Rechner nicht mehr)."
  read -r -p "Hardware-Config von '$NAME' ersetzen? [j/N] " ANTWORT
  [ "$ANTWORT" = "j" ] || { echo "Abgebrochen."; exit 1; }
fi
cp /etc/nixos/hardware-configuration.nix "$HW"

# Flakes sehen nur Dateien, die Git kennt
git add -A "$HOSTDIR"

sudo nixos-rebuild switch --flake ".#nixos-$NAME" --option experimental-features "nix-command flakes"

echo
if [ "$NAME" = "vm" ]; then
  echo "Fertig. Für die VM ist kein Commit nötig."
else
  echo "Fertig. Zum Sichern dieser Maschine im Repo:"
  echo "  cd ~/nixos-dotfiles && git commit -m \"Host $NAME\" && git push"
fi
