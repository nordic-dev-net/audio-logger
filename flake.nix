{
  description = "Audio Logger";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }: 
    let
      systems = with flake-utils.lib.system; [
        x86_64-linux
        aarch64-linux
      ];
    in
      flake-utils.lib.eachSystem systems (system: 
        let
          pkgs = import nixpkgs { inherit system; };
          lib = pkgs.lib;
        in
          {
            packages.audio-logger = nixpkgs.legacyPackages.${system}.callPackage ./default.nix {};

            nixosModules.audio-logger = { config, pkgs, ... }: {
              options.services.audio-logger = {
                enable = lib.mkEnableOption "audio-logger service";

                package = lib.mkOption {
                  type = lib.types.package;
                  default = pkgs.audio-logger;
                  description = "The package to use for the audio-logger service.";
                };

                config = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                  description = "Configuration for the audio-logger service.";
                };
              };

              config.systemd.services.audio-logger = lib.mkIf config.services.audio-logger.enable {
                description = "Audio Logger Service";
                after = [ "network.target" ];
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  ExecStart = "${config.services.audio-logger.package}/bin/audio-logger ${config.services.audio-logger.config}";
                };
              };
            };

            formatter = nixpkgs.legacyPackages.${system}.alejandra;
          }
      );
}
