# Official Linux beta of Claude Desktop (Chat / Cowork / Claude Code Desktop).
# Source is Anthropic's official apt repo (downloads.claude.ai), not a community repack.
# Based on github:tomsch/claude-desktop-nix (MIT); difference: the wrapper uses
# --ozone-platform-hint=auto to adapt automatically between X11 (KDE) and Wayland (Hyprland) sessions,
# while upstream's hardcoded --ozone-platform=wayland cannot connect to the display in a pure X11 session.
#
# Updating versions: check Version + SHA256 in the apt index, then edit version/hash below:
#   curl -fsSL https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages | grep -E '^(Version|SHA256):'
{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  makeWrapper,
  autoPatchelfHook,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libGL,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  pipewire, # claude-native-binding.node links against libpipewire-0.3.so.0
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxcb,
  libxshmfence,
  systemdLibs, # libudev.so.1
  libseccomp,
  libcap_ng,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "claude-desktop";
  version = "4.4212.0";

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${finalAttrs.version}_amd64.deb";
    hash = "sha256-T89ljg/IlTkKuCWTKHKB37ziYbDsPqkAYOgti/v9eoQ=";
  };

  nativeBuildInputs = [
    dpkg
    makeWrapper
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libGL
    libxkbcommon
    mesa
    nspr
    nss
    pango
    pipewire
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    libxshmfence
    libseccomp
    libcap_ng
    systemdLibs
  ];

  dontConfigure = true;
  dontBuild = true;

  # Inside the sandbox, `dpkg-deb -x` tries to restore the setuid bit on chrome-sandbox and gets rejected,
  # so extract via a tar stream and drop permissions/ownership.
  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile $src | tar --no-same-permissions --no-same-owner -x
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/bin $out/share
    cp -r usr/lib/claude-desktop $out/lib/claude-desktop
    cp -r usr/share/icons $out/share/
    cp -r usr/share/applications $out/share/

    # Chromium's SUID sandbox is unavailable in the Nix store (no setuid possible), so --no-sandbox is required;
    # ozone-platform-hint=auto picks X11/Wayland automatically based on the session;
    # the wayland-ime flag is ignored under X11 and serves fcitx5 under Wayland (Hyprland).
    makeWrapper "$out/lib/claude-desktop/claude-desktop" "$out/bin/claude-desktop" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.buildInputs}" \
      --add-flags "--no-sandbox" \
      --add-flags "--enable-features=UseOzonePlatform,WaylandWindowDecorations" \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--enable-wayland-ime" \
      --add-flags "--wayland-text-input-version=3"

    # all three Exec entries (main entry + NewChat/NewCode actions) point to the wrapper
    substituteInPlace $out/share/applications/com.anthropic.Claude.desktop \
      --replace-fail "Exec=claude-desktop" "Exec=$out/bin/claude-desktop"

    runHook postInstall
  '';

  meta = {
    description = "Claude Desktop App (official Linux beta)";
    homepage = "https://claude.com/download";
    license = lib.licenses.unfree;
    platforms = ["x86_64-linux"];
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    mainProgram = "claude-desktop";
  };
})
