flake.nix
configuration.nix            # oder system/default.nix, gemeinsam für alle Hosts
hosts/
├── laptop-common.nix        # geteilte Laptop-Logik: autorandr, Dock, picom, Bluetooth
├── thinkpad/
│   ├── default.nix          # importiert laptop-common.nix + machine.nix
│   ├── machine.nix          # nur edidLaptop (+ ggf. Soundkarte)
│   └── hardware-configuration.nix
├── laptop-alt/
│   └── (dasselbe)
└── vm/
    ├── default.nix
    └── hardware-configuration.nix
system/                      # NixOS-Ebene: brave-policy.nix, nordvpn.nix ...
home/
├── home.nix
├── apps/                    # brave, obsidian, google-drive, rofi-tmux
└── cli/                     # neovim, tmux, yazi, git, bash
config/                      # bleibt: Dotfiles (nvim, qtile, tmux ...)
