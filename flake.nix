{
  description = "A Nix-flake-based Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # dev environment packages go here
          ];
        };
      });
      packages = forEachSupportedSystem ({ pkgs, ... }: rec { 
        default = electron;
        tauri = pkgs.callPackage ./nix/build-tauri.nix { inherit (pkgs.stdenv) system; };
        electron = pkgs.callPackage ./nix/build-electron.nix { inherit (pkgs.stdenv) system; };
      });
    };
}
