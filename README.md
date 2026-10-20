# NixOS-Konfiguration

Hosts: `nixos-thinkpad` (Bare Metal), `nixos-vm` (VMware Workstation Pro).
Weitere Laptops werden beim ersten Install automatisch als eigener Host angelegt.

## Neuinstallation

1. NixOS mit dem grafischen Installer installieren
   - Benutzer: `marc`
   - Im UEFI-Modus booten (`ls /sys/firmware/efi` muss existieren)
   - Desktop egal, wird durch die Config ersetzt
2. Nach dem ersten Login mit dem Internet verbinden und ausführen:

   Bekannte Maschine (Ordner unter `hosts/` existiert):

       nix --extra-experimental-features "nix-command flakes" run github:marcboe-dev/nixos-dotfiles2 --refresh -- thinkpad

   VMware-VM:

       nix --extra-experimental-features "nix-command flakes" run github:marcboe-dev/nixos-dotfiles2 --refresh -- vm

   Neuer Laptop (legt `hosts/<name>/` mit den Daten dieser Maschine an):

       nix --extra-experimental-features "nix-command flakes" run github:marcboe-dev/nixos-dotfiles2 --refresh -- <name> laptop

3. Neu starten und beim Login die Qtile-Sitzung wählen.

Das Skript klont das Repo nach `~/nixos-dotfiles`, übernimmt die
Hardware-Config der Maschine und baut das System inkl. Home Manager.

## Danach

Bei einem neuen Laptop die neue Maschine ins Repo sichern
(die VM braucht das nicht):

    gh auth login
    cd ~/nixos-dotfiles
    git commit -m "Host <name>"
    git push

Google Drive einrichten: siehe `apps/google-drive_README.md`.

## Manueller Fallback (falls das Skript nicht läuft)

    nix-shell -p git
    git clone https://github.com/marcboe-dev/nixos-dotfiles2.git ~/nixos-dotfiles
    cd ~/nixos-dotfiles
    cp /etc/nixos/hardware-configuration.nix hosts/<host>/   # <host> = thinkpad oder vm
    git add .
    sudo nixos-rebuild switch --flake .#nixos-<host> --option experimental-features "nix-command flakes"

## Im Alltag

    nrs                    # System neu bauen
    nix flake update       # Pakete aktualisieren, danach nrs

Der Hostname der Maschine entspricht dem Ordnernamen mit Präfix
(`hosts/thinkpad` → `nixos-thinkpad`). Deshalb findet `nrs` die richtige
Konfiguration automatisch.

## Hinweise

- Das Repo muss in `~/nixos-dotfiles` liegen, sonst fehlen Dotfiles und
  Hintergrundbild.
- Jede physische Maschine braucht einen eigenen Ordner unter `hosts/` mit
  eigener `hardware-configuration.nix`. Nie die Hardware-Config einer anderen
  Maschine übernehmen, sonst bootet sie nicht mehr.
- Dock- und Monitor-Daten stehen in `hosts/laptop-common.nix`. Nur das
  interne Display (`edidLaptop`) steht pro Maschine in `machine.nix`.
