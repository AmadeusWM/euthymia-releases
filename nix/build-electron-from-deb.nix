{ pkgs, lib, makeDesktopItem, commandLineArgs ? "", ... }:

let
  pname = "euthymia";
  version = "0.1.10";
  src = pkgs.fetchurl {
    url = "https://github.com/AmadeusWM/euthymia-releases/releases/download/v${version}/euthymia-electron_1.0.0_amd64.deb";
    sha256 = "sha256-bAESu1rk8jxhBKxUmcrzqKkK9OV8eqDChrfhPdacLdg=";
  };
  
  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "Euthymia (Electron)";
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
    # System libraries required by Electron
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    mesa # for libgbm and libGL
    expat
    xorg.libxcb
    libxkbcommon
    systemd # for libudev
    alsa-lib # for libasound
    at-spi2-atk # for libatspi
    stdenv.cc.cc.lib # for libgcc_s
    # Additional dependencies for Electron
    nss
    nspr
    cups
    gtk3
    pango
    cairo
    # OpenGL support
    libGL
    electron
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src . || true
    # Fix permissions for chrome-sandbox if it exists
    if [ -f usr/lib/euthymia-electron/chrome-sandbox ]; then
      chmod 755 usr/lib/euthymia-electron/chrome-sandbox
    fi
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    
    # Copy the entire lib directory to preserve all electron files
    mkdir -p $out/lib
    cp -r usr/lib/euthymia-electron $out/lib/
    
    # Create a wrapper script
    mkdir -p $out/bin
    cat > $out/bin/euthymia << EOF
#!/usr/bin/env bash
export ELECTRON_OVERRIDE_DIST_PATH="$out/lib/euthymia-electron"
cd "$out/lib/euthymia-electron"
exec "./euthymia-electron" --no-sandbox "\$@"
EOF
    chmod +x $out/bin/euthymia
    
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
    # Make the main binary executable and fix permissions on chrome-sandbox
    chmod +x $out/lib/euthymia-electron/euthymia-electron
    if [ -f $out/lib/euthymia-electron/chrome-sandbox ]; then
      chmod 4755 $out/lib/euthymia-electron/chrome-sandbox || chmod 755 $out/lib/euthymia-electron/chrome-sandbox
    fi
    
    # Set environment variables for the wrapped binary
    wrapProgram $out/bin/euthymia \
      --set WEBKIT_DISABLE_COMPOSITING_MODE 1 \
      --prefix LD_LIBRARY_PATH : "$out/lib/euthymia-electron"
  '';

  meta = with lib; {
    description = "Euthymia knowledge base (Electron version)";
    homepage = "https://github.com/AmadeusWM/euthymia-releases";
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
