# Nutzung: install <host> [laptop|vm]
#   host: Ordnername unter hosts/ (z.B. thinkpad, laptop-alt, vm)
#   typ:  nur nötig, wenn hosts/<host> noch nicht existiert (legt den Host neu an)
NAME="${1:?Nutzung: install <host> [laptop|vm]}"
TYP="${2:-}"

DIR="$HOME/nixos-dotfiles"
HOSTDIR="hosts/$NAME"
HW="$HOSTDIR/hardware-configuration.nix"

[ -d "$DIR" ] || git clone https://github.com/marcboe-dev/my-nixos.git "$DIR"
cd "$DIR"

# ── Neuen Host anlegen ─────────────────────────────────────────
if [ ! -d "$HOSTDIR" ]; then
  case "$TYP" in
    laptop|vm) ;;
    *)
      echo "Host '$NAME' existiert nicht."
      echo "Neu anlegen mit: install $NAME laptop   (oder: install $NAME vm)"
      exit 1
      ;;
  esac

  mkdir -p "$HOSTDIR"

  if [ "$TYP" = "vm" ]; then
    cat > "$HOSTDIR/default.nix" <<'EOF'
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../vm-common.nix
  ];
}
EOF
  else
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
  speakerCard = null; # optional: Soundkarten-Name aus wpctl/pactl
}
EOF
  fi

  echo "Neuer Host '$NAME' angelegt ($TYP)."
fi

# ── Hardware-Config dieser Maschine übernehmen ─────────────────
if [ -f "$HW" ] && ! cmp -s /etc/nixos/hardware-configuration.nix "$HW"; then
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
echo "Fertig. Zum Sichern der neuen Maschine im Repo:"
echo "  cd ~/nixos-dotfiles && git commit -m \"Host $NAME\" && git push"
