{ pkgs, lib, makeDesktopItem, commandLineArgs ? "", ... }:
let
  electron = pkgs.electron_36;
in pkgs.stdenv.mkDerivation rec {
  pname = "euthymia-electron";
  version = "main";

  src = pkgs.fetchzip {
    url = "https://github.com/AmadeusWM/euthymia-releases/releases/download/main/euthymia-electron-linux-x64.zip";
    sha256 ="sha256-sPZ8T+W9M/xfS/LjmtB7wLtPRuLBNK9EAzwbTjYGies=";
  };

  # version = "v0.1.3";

  # src = pkgs.fetchzip {
  #   url = "https://github.com/AmadeusWM/euthymia-releases/releases/download/${version}/euthymia-electron-linux-x64.zip";
  #   sha256 = "sha256-cTv5JxupIS/Kz2uH9tqwFHDoKoRRTj39AqZmTnz9y2Y=";
  # };

  desktopItem = makeDesktopItem {
    name = "euthymia";
    desktopName = "Euthymia";
    comment = "Knowledge base";
    icon = "euthymia";
    exec = "euthymia-electron";
    categories = [ "Office" ];
    mimeTypes = [ "x-scheme-handler/euthymia" ];
  };

  buildInputs = pkgs.lib.optionals true ([
    # NODE
    
    electron
    
  ]);

  nativeBuildInputs =
    pkgs.lib.optionals true ([
      pkgs.unzip
    ])
    ++ buildInputs
    ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs.makeWrapper
    ];

  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
  ELECTRON_OVERRIDE_DIST_PATH="${electron}/bin/";
  ELECTRON_SKIP_BINARY_DOWNLOAD="1";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    ls -la
    makeWrapper ${electron}/bin/electron $out/bin/euthymia-electron \
      --add-flags $out/share/euthymia/app.asar \
      --add-flags ${lib.escapeShellArg commandLineArgs}

    install -m 444 -D resources/app.asar $out/share/euthymia/app.asar
    install -m 444 -D "${desktopItem}/share/applications/"* \
           -t $out/share/applications/

    runHook postInstall
  '';
}
