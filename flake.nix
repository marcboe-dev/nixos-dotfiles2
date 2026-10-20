{
  description = "NixOS from Scratch";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # versions nixpkgs & home-manger same
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  }: let
    lib = nixpkgs.lib;
    pkgs = nixpkgs.legacyPackages.x86_64-linux;

    # Jeder Ordner in hosts/ ist ein Host (Dateien wie laptop-common.nix werden ignoriert)
    hostNames = builtins.attrNames (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
    );

    # Funktion: bekommt einen Host-Namen, gibt ein komplettes System zurück
    mkHost = name:
      lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix # gemeinsam
          (./hosts + "/${name}") # rechnerspezifisch
          {networking.hostName = "nixos-${name}";}
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.marc = import ./home.nix;
              backupFileExtension = "backup";
            };
          }
        ];
      };
  in {
    nixosConfigurations = builtins.listToAttrs (map (name: {
        name = "nixos-${name}";
        value = mkHost name;
      })
      hostNames);

    apps.x86_64-linux.default = {
      type = "app";
      program = "${pkgs.writeShellApplication {
        name = "install";
        runtimeInputs = [pkgs.git pkgs.coreutils pkgs.gnused pkgs.diffutils];
        text = builtins.readFile ./install.sh;
      }}/bin/install";
    };
  };
}
