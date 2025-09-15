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
    # Base system
    stdenv.cc.cc.lib
    glibc
    
    # Graphics libraries for EGL/OpenGL support
    libGL
    libGLU
    mesa
    libgbm
    
    # Additional graphics and windowing libraries
    libdrm
    libxkbcommon
    wayland
    
    # X11 libraries
    xorg.libX11
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
    
    # GTK and related libraries
    gtk3
    glib
    cairo
    pango
    atk
    gdk-pixbuf
    
    # Text rendering libraries
    fribidi
    harfbuzz
    
    # Audio libraries
    alsa-lib
    pulseaudio
    
    # System libraries
    fontconfig
    freetype
    dbus
    systemd
    zlib
    openssl
    curl
    expat
    libxml2
    libxslt
    sqlite
    libgpg-error
    libgcrypt
    e2fsprogs  # for libcom_err
    gmp        # for libgmp
    
    # WebKit for Tauri webview
    webkitgtk_4_1
    
    # Vulkan support
    vulkan-loader
    vulkan-validation-layers
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
