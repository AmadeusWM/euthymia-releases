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
      packages = forEachSupportedSystem ({ pkgs }: rec {
        default = euthymia-electron;
        euthymia-electron = pkgs.stdenv.mkDerivation rec {
          pname = "euthymia-electron";
          version = "main";

          src = pkgs.fetchzip {
            url = "https://github.com/AmadeusWM/euthymia-releases/releases/download/main/euthymia-electron-linux-x64.zip";
            sha256 = "sha256-YrsVrMhL8rQRIlekMabzpO6UgzNK2+Zi/0whjKFYOkM="; # Replace with actual hash
          };

          buildInputs = with pkgs; [
            # NODE
            node2nix
            nodejs
            pnpm
            yarn
            electron
            # Electron build
            rpm
            dpkg
            fakeroot
            libglibutil

            # these are important for running application built with electron forge package
            glib
            nss
            nspr
            dbus
            atk
            cups
            libdrm
            gtk3
            pango
            cairo
            xorg.libX11
            xorg.libXcomposite
            xorg.libXdamage
            xorg.libXext
            xorg.libXfixes
            xorg.libXrandr
            mesa
            expat
            xorg.libxcb
            libxkbcommon
            alsa-lib
          ];
          nativeBuildInputs =
            with pkgs; [ unzip ]
            ++ buildInputs
            ++ lib.optionals stdenv.hostPlatform.isLinux [
              autoPatchelfHook
              asar
              copyDesktopItems
              # override doesn't preserve splicing https://github.com/NixOS/nixpkgs/issues/132651
              # Has to use `makeShellWrapper` from `buildPackages` even though `makeShellWrapper` from the inputs is spliced because `propagatedBuildInputs` would pick the wrong one because of a different offset.
              (buildPackages.wrapGAppsHook3.override { makeWrapper = buildPackages.makeShellWrapper; })
            ];
        installPhase = ''
            addAutoPatchelfSearchPath ${pkgs.electron}/libexec/electron
            mkdir -p $out/bin
            ls -la
            cp -r ./* $out/bin/
            chmod +x $out/bin/euthymia-electron
            cp $out/bin/euthymia-electron $out/bin/euthymia-desktop
          '';
        };
      });
    };
}
