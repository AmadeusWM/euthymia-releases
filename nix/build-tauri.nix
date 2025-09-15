{ pkgs, lib, makeDesktopItem, commandLineArgs ? "", ... }:

let
  pname = "euthymia";
  version = "0.1.7";
  src = pkgs.fetchurl {
    url = "https://github.com/AmadeusWM/euthymia-releases/releases/download/v${version}/Euthymia_${version}_amd64.deb";
    sha256 = "0x4kwwb38c10pzjiirp1ahrx7xqqigvaqvwmw8sixdd6hhpvagjv";
  };
  
  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "Euthymia (Tauri)";
    comment = "Knowledge base";
    icon = "euthymia";
    exec = pname;
    categories = [ "Office" ];
    mimeTypes = [ "x-scheme-handler/euthymia" ];
  };
in
pkgs.stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = with pkgs; [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = with pkgs; [
    # tauri stuff 
    at-spi2-atk
    atkmm
    cairo
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    librsvg
    libsoup_3
    pango
    webkitgtk_4_1
    openssl
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    
    # Copy the binary
    mkdir -p $out/bin
    cp -r usr/bin/* $out/bin/
    
    # Copy desktop file and icons
    mkdir -p $out/share
    if [ -d usr/share ]; then
      cp -r usr/share/* $out/share/
    fi
    
    # Install our custom desktop entry
    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/* $out/share/applications/
    
    runHook postInstall
  '';

  postFixup = ''
    # Set environment variables for the wrapped binary
    wrapProgram $out/bin/euthymia \
      --set WEBKIT_DISABLE_COMPOSITING_MODE 1
  '';

  meta = with lib; {
    description = "Euthymia knowledge base (Tauri version)";
    homepage = "https://github.com/AmadeusWM/euthymia-releases";
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
