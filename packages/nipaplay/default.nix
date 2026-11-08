# packages/nipaplay/package.nix
# NipaPlay-Reload Linux desktop: a Flutter application built from source (v1.11.9).
# Replicates the upstream official Linux build (.github/workflows/build-linux.yml):
#   - Flutter 3.47 (nixpkgs-unstable flutter347, same generation as upstream's pinned 3.47.0-0.3.pre beta)
#   - libmpv from nixpkgs mpv (upstream links the system libmpv2 via pkg-config)
#   - the "Erika" native playback kernel (AimesSoft/liberika v0.2.1): vendored deps built offline via xtask
#     FFmpeg 8.1.2 / dav1d / libass / harfbuzz / freetype / fribidi / zlib
#   - the Rust FRB library librust_lib_nipaplay.so is prebuilt and injected via the official
#     NIPAPLAY_RUST_LIBRARY hook, skipping cargokit entirely (avoids network access)
#   - pub dependencies resolved offline by pub2nix (pubspec.lock.json + git-hashes.json)
{
  lib,
  callPackage,
  nixpkgsPath,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  fetchgit,
  rustPlatform,
  cargo,
  rustc,
  cmake,
  ninja,
  meson,
  nasm,
  yasm,
  pkg-config,
  python3,
  zip,
  unzip,
  autoPatchelfHook,
  wrapGAppsHook3,
  flutter347,
  gst_all_1,
  gtk3,
  mimalloc,
  keybinder3,
  libayatana-appindicator,
  libevdev,
  alsa-lib,
  libpulseaudio,
  libepoxy,
  wayland,
  libva,
  libdrm,
  sqlite,
  mpv,
  vulkan-loader,
  llvmPackages,
  mdk-sdk,
  zlib,
}: let
  nipaplayVersion = "1.11.10";

  src = fetchFromGitHub {
    owner = "AimesSoft";
    repo = "NipaPlay-Reload";
    tag = "v${nipaplayVersion}";
    fetchSubmodules = true;
    hash = "sha256-g86p34N96VbwogPXq6oHtCn4RQZf3vV3GjixeA7Xdd4=";
  };

  # Linux build patch for liberika v0.2.1 from the NipaPlay repo.
  erikaPatch = fetchurl {
    url = "https://raw.githubusercontent.com/AimesSoft/NipaPlay-Reload/v${nipaplayVersion}/.github/patches/erika-linux-native-deps.patch";
    hash = "sha256:0as7cd9vb800wnsgyk6x26acn5vzh7z9j8a14v3g0gjzi76rv4xs";
  };

  # Vendored third-party source tarballs for liberika's xtask: once third_party/cache is pre-filled,
  # xtask runs fully offline, unpacking and building from these archives (third_party/src is generated identically).
  ffmpegTarball = fetchurl {
    url = "https://codeload.github.com/FFmpeg/FFmpeg/tar.gz/refs/tags/n8.1.2";
    hash = "sha256:1dvfazh8ppvjhcjy31kk5z8k83z4v4w6vslmw2pypfq52r8r5l4z";
  };
  dav1dTarball = fetchurl {
    url = "https://codeload.github.com/videolan/dav1d/tar.gz/refs/tags/1.5.1";
    hash = "sha256:15dnfjfwny8mzi9rlfxvhaamhk74bphq6z00hh9pn515vcmmwqzs";
  };
  libassTarball = fetchurl {
    url = "https://github.com/libass/libass/releases/download/0.17.5/libass-0.17.5.tar.xz";
    hash = "sha256:1k2ahs42433bh0kq40ddsgfy9hfah8zin0aj1gqdsdy8w302bjid";
  };
  harfbuzzTarball = fetchurl {
    url = "https://github.com/harfbuzz/harfbuzz/releases/download/14.2.1/harfbuzz-14.2.1.tar.xz";
    hash = "sha256:03ifj1bmlv58phdkznd0zhnpj13ppyy6gqrcfsxiz940jf75sjm5";
  };
  freetypeTarball = fetchurl {
    url = "https://codeload.github.com/freetype/freetype/tar.gz/refs/tags/VER-2-14-3";
    hash = "sha256:0qb2nl57dyyj7gvfzwlgwb9pbi22k16x6kbahzsfwrm205mxwjfw";
  };
  fribidiTarball = fetchurl {
    url = "https://github.com/fribidi/fribidi/releases/download/v1.0.16/fribidi-1.0.16.tar.xz";
    hash = "sha256:0p50krd2mn244y5fqw5li9623qq9lf40wbxyj6g4fh2x4ddxw70v";
  };
  zlibTarball = fetchurl {
    url = "https://codeload.github.com/madler/zlib/tar.gz/refs/tags/v1.3.2";
    hash = "sha256:18cmljadc32whgva13vcjgkg3g8w7gjg3i3qgvn614xsq230p6mr";
  };
  nvCodecHeadersTarball = fetchurl {
    url = "https://codeload.github.com/FFmpeg/nv-codec-headers/tar.gz/refs/tags/n13.0.19.0";
    hash = "sha256:05h1jhi1rnyqyhf57gwm8lkahzdszvmppifzmw73miqaghd5vlc6";
  };
  vulkanHeadersTarball = fetchurl {
    url = "https://codeload.github.com/KhronosGroup/Vulkan-Headers/tar.gz/refs/tags/v1.3.290";
    hash = "sha256:1xdwx6yqah652ggagh7434l9mfhw7gax4lws48m7marwz4xnb2pk";
  };

  librustLib = rustPlatform.buildRustPackage rec {
    pname = "librust_lib_nipaplay";
    version = nipaplayVersion;

    inherit src;
    sourceRoot = "source/rust";

    cargoDeps = rustPlatform.importCargoLock {
      lockFile = "${src}/rust/Cargo.lock";
    };

    doCheck = false;
  };

  erikaRuntime = stdenv.mkDerivation rec {
    pname = "liberika-runtime";
    version = "0.2.1";

    src = fetchgit {
      url = "https://github.com/AimesSoft/Erika";
      rev = "70f12bf325ce8d020d2155635f5992eff4654321";
      hash = "sha256-FKUAwOe06XFh1F5FYws5ekJZw9cYc5PEj30KMgrfgfA=";
    };

    cargoDeps = rustPlatform.importCargoLock {
      lockFile = "${src}/Cargo.lock";
    };

    nativeBuildInputs = [
      rustPlatform.cargoSetupHook
      cargo
      rustc
      cmake
      meson
      ninja
      llvmPackages.clang
      nasm
      yasm
      pkg-config
      python3
      zip
      unzip
    ];

    buildInputs = [
      libva
      libdrm
      libpulseaudio
      vulkan-loader
      zlib
    ];

    LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
    BINDGEN_EXTRA_CLANG_ARGS = "-I${llvmPackages.libclang.lib}/lib/clang/${llvmPackages.llvm.version}/include";
    # ffmpeg's --enable-libdrm/vaapi/vulkan/zlib flags go through pkg-config; provide the pc paths explicitly
    PKG_CONFIG_PATH = lib.strings.concatStringsSep ":" [
      "${lib.getDev libdrm}/lib/pkgconfig"
      "${lib.getDev libva}/lib/pkgconfig"
      "${lib.getDev vulkan-loader}/lib/pkgconfig"
      "${lib.getDev zlib}/lib/pkgconfig"
    ];

    # Erika is not a hand-written CMake project; xtask invokes cmake/meson itself for vendored deps
    dontUseCmakeConfigure = true;
    dontUseMesonConfigure = true;

    hardeningDisable = ["fortify"];

    prePatch = ''
      patch -p1 < ${erikaPatch}

      # CMake GNUInstallDirs picks lib64 in this environment, but xtask only accepts lib/pkgconfig:
      # pin CMAKE_INSTALL_LIBDIR=lib at the freetype build call sites
      sed -i 's|\.arg("-DFT_DISABLE_ZLIB=TRUE")|.arg("-DCMAKE_INSTALL_LIBDIR=lib") .arg("-DFT_DISABLE_ZLIB=TRUE")|' xtask/src/main.rs
      sed -i 's|\.arg("-DHB_BUILD_UTILS=OFF")|.arg("-DCMAKE_INSTALL_LIBDIR=lib") .arg("-DHB_BUILD_UTILS=OFF")|' xtask/src/main.rs
      sed -i 's|\.arg("-DZLIB_INSTALL=ON")|.arg("-DCMAKE_INSTALL_LIBDIR=lib") .arg("-DZLIB_INSTALL=ON")|' xtask/src/main.rs

      # pre-fill the xtask archive cache (third_party/cache) — this is what makes xtask fully offline
      mkdir -p third_party/cache
      cp ${ffmpegTarball} third_party/cache/ffmpeg-n8.1.2.tar.gz
      cp ${dav1dTarball} third_party/cache/dav1d-1.5.1.tar.gz
      cp ${libassTarball} third_party/cache/libass-0.17.5.tar.xz
      cp ${harfbuzzTarball} third_party/cache/harfbuzz-14.2.1.tar.xz
      cp ${freetypeTarball} third_party/cache/freetype-VER-2-14-3.tar.gz
      cp ${fribidiTarball} third_party/cache/fribidi-1.0.16.tar.xz
      cp ${zlibTarball} third_party/cache/zlib-1.3.2.tar.gz
    '';

    buildPhase = ''
      runHook preBuild

      # nv-codec-headers (FFmpeg NVENC/NVDEC declarations) -> own pkgconfig prefix,
      # and hand the nixpkgs libdrm/libva/vulkan pc dirs to xtask as well:
      # the patch resets the ffmpeg configure subprocess's PKG_CONFIG_PATH to
      # <dav1d dist>:<ERIKA_LINUX_PKG_CONFIG_DIRS>; on CI (Ubuntu) libdrm etc. are found via system
      # pc paths; under Nix this variable must explicitly point at the nixpkgs header dirs
      setupPrefix=$(mktemp -d)
      tar xf ${nvCodecHeadersTarball} -C "$setupPrefix" --strip-components=1
      make -C "$setupPrefix" install PREFIX="$setupPrefix/nvcodec"

      # Vulkan-Headers: FFmpeg 8's vulkan declarations are newer than the system headers
      mkdir -p "$setupPrefix/vulkan/include"
      tar xf ${vulkanHeadersTarball} -C "$setupPrefix/vulkan" --strip-components=1

      export ERIKA_LINUX_PKG_CONFIG_DIRS="$setupPrefix/nvcodec/lib/pkgconfig:${lib.makeSearchPathOutput "dev" "lib/pkgconfig" [libdrm libva vulkan-loader zlib]}"
      export CPATH="$setupPrefix/vulkan/include''${CPATH:+:$CPATH}"
      export ERIKA_USE_SYSTEM_LIBS=0
      export CFLAGS="''\${CFLAGS:-} -fPIC"
      export CXXFLAGS="''\${CXXFLAGS:-} -fPIC"
      export CARGO_TARGET_DIR="$PWD/target"
      export ERIKA_BUILD_JOBS="$NIX_BUILD_CORES"

      cargo run --locked -p xtask -- deps build --all --profile lgpl
      cargo rustc --locked --release -p erika_capi --lib -- \
        -C link-arg=-Wl,-soname,liberika_capi.so \
        -C link-arg=-Wl,-z,defs \
        -C link-arg=-lva -C link-arg=-lva-drm -C link-arg=-lva-x11 \
        -C link-arg=-ldrm -C link-arg=-ldl -C link-arg=-lm

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      # Reuse liberika's own packaging script (purely local staging, includes all licenses)
      GITHUB_SHA="70f12bf325ce8d020d2155635f5992eff4654321" \
        GITHUB_REF_NAME="v${version}" ERIKA_NATIVE_PROFILE=lgpl \
        bash packaging/bundle.sh erika-linux ./erika-linux.zip \
        target/release/liberika_capi.so
      unzip -q erika-linux.zip -d bundle
      mkdir -p $out
      cp -a bundle/erika-linux/. $out/

      # License files appended by the upstream script (scripts/build_erika_linux_runtime.sh)
      cp -a third_party/src/fribidi-1.0.16/COPYING $out/licenses/LICENSE.FriBidi
      cp -a third_party/build/licenses/Vulkan-Headers $out/licenses/Vulkan-Headers || true
      cp -a third_party/build/erika-linux/licenses/LICENSE.nv-codec-headers $out/licenses/LICENSE.nv-codec-headers 2>/dev/null || true

      test -f $out/lib/liberika_capi.so

      runHook postInstall
    '';

    meta = {
      description = "Erika native playback engine runtime for NipaPlay";
      homepage = "https://github.com/AimesSoft/Erika";
      license = lib.licenses.mpl20;
    };
  };

  # Instantiate buildFlutterApplication once so the Flutter SDK carries the web platform artifacts,
  # used for the web asset build equivalent to upstream's build_and_copy_web.
  buildFlutterApplication = callPackage "${nixpkgsPath}/pkgs/development/compilers/flutter/build-support/build-flutter-application.nix" {
    flutter = flutter347.override {
      supportedTargetFlutterPlatforms = ["universal" "linux" "web"];
    };
  };
in
  buildFlutterApplication {
    pname = "nipaplay-reload";
    version = nipaplayVersion;
    inherit src;

    pubspecLock = lib.importJSON ./pubspec.lock.json;
    gitHashes = lib.importJSON ./git-hashes.json;

    # Path dependencies resolve to the pristine fetched source (FOD): postPatch in overrideAttrs
    # never runs in fixed-output derivations -> must unpack, patch, and install via mkDerivation,
    # preserving the passthru.packageRoot semantics (isomorphic to the nixpkgs hosted builder).
    # fvp: wire the mdk dependency to nixpkgs mdk-sdk (otherwise unpacking its mdk-sdk tarball needs network)
    customSourceBuilders.fvp = {
      version,
      src,
      ...
    }:
      stdenv.mkDerivation {
        pname = "pub-fvp-src";
        inherit (src) passthru;
        inherit version;
        inherit src;
        dontBuild = true;
        postPatch = ''
          pushd "${src.passthru.packageRoot}"
          sed -i 's|.*libc++.so.1.*|${mdk-sdk}/lib/libc++.so.1|' linux/CMakeLists.txt
          substituteInPlace linux/CMakeLists.txt \
            --replace-fail "fvp_setup_deps()" "include(${mdk-sdk}/lib/cmake/FindMDK.cmake)"
          popd
        '';
        installPhase = ''
          runHook preInstall
          cp -r . "$out"
          runHook postInstall
        '';
      };

    # volume_controller: provide ALSA via pkg-config (Nix has no default system ALSA path)
    customSourceBuilders.volume_controller = {
      version,
      src,
      ...
    }:
      stdenv.mkDerivation {
        pname = "pub-volume-controller-src";
        inherit (src) passthru;
        inherit version;
        inherit src;
        dontBuild = true;
        postPatch = ''
          pushd "${src.passthru.packageRoot}"
          substituteInPlace linux/CMakeLists.txt \
            --replace-fail "# ALSA dependency for volume control" "find_package(PkgConfig REQUIRED)" \
            --replace-fail "find_package(ALSA REQUIRED)" "pkg_check_modules(ALSA REQUIRED alsa)"
          popd
        '';
        installPhase = ''
          runHook preInstall
          cp -r . "$out"
          runHook postInstall
        '';
      };

    # keep pub2nix's path relative to the root as "./" (by default it is cleared to an empty string -> becomes an absolute path starting with "/")
    packageRoot = ".";

    nativeBuildInputs = [
      autoPatchelfHook
      wrapGAppsHook3
      pkg-config
      cmake
      ninja
      python3
    ];

    buildInputs = [
      gtk3
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      mimalloc
      keybinder3
      libayatana-appindicator
      libevdev
      alsa-lib
      libpulseaudio
      libepoxy
      wayland
      libva
      libdrm
      sqlite
      mpv
    ];

    env = {
      ERIKA_LIBRARY_DIR = "${erikaRuntime}/lib";
      NIPAPLAY_RUST_LIBRARY = "${librustLib}/lib/librust_lib_nipaplay.so";
    };

    # flutter build linux invokes cmake/ninja itself according to the platform
    dontUseCmakeConfigure = true;

    # pubspec_overrides.linux.yaml is already reflected in pubspec.lock.json (linux profile);
    # enable the overrides file too, keeping semantics consistent with CI's configure step.
    # Note: path-dependency plugins build their CMake inside this source tree (ephemeral points at this tree), so
    # all patches to vendored plugins must edit this tree's files directly.
    postPatch = ''
      cp pubspec_overrides.linux.yaml pubspec_overrides.yaml
      python3 .github/workflows/scripts/generate-build-info-json.py assets/build_info.json
    '';

    flutterBuildFlags = [
      "--obfuscate"
      "--dart-define=NIPAPLAY_LINUX_ERIKA=true"
    ];

    # Fully replicate CI: build web -> copy assets -> flutter build linux --obfuscate
    buildPhase = ''
      runHook preBuild

      mkdir -p build/flutter_assets/fonts

      # web build (remote Web UI). Upstream convention: on failure, fall back to an empty assets/web and continue
      if ! flutter build web -v; then
        echo "WARNING: Flutter web build failed. Remote web UI disabled (upstream-equivalent fallback)."
      fi
      rm -rf assets/web
      mkdir -p assets/web
      if [ -d build/web ]; then
        cp -r build/web assets/web/
      fi

      flutter build linux --release --obfuscate --split-debug-info="$debug" \
        --dart-define=NIPAPLAY_LINUX_ERIKA=true

      test -f build/linux/x64/release/bundle/lib/liberika_capi.so
      mkdir -p build/linux/x64/release/bundle/lib/erika-licenses
      test -d ${erikaRuntime}/licenses && cp -a ${erikaRuntime}/licenses/. build/linux/x64/release/bundle/lib/erika-licenses/ || true
      chmod -R u+w build/linux/x64/release/bundle/lib/erika-licenses 2>/dev/null || true
      for f in ${erikaRuntime}/LICENSE ${erikaRuntime}/THIRD_PARTY_NOTICES.md ${erikaRuntime}/MANIFEST.txt; do
        test -f "$f" && cp "$f" build/linux/x64/release/bundle/lib/erika-licenses/ && chmod u+w build/linux/x64/release/bundle/lib/erika-licenses/$(basename "$f")
      done

      runHook postBuild
    '';

    # Dependency version declarations follow upstream: put the YAML pubspec.lock back (the app reads it as a pubspec.lock asset)
    postConfigure = ''
      rm -f pubspec.lock
      cp ${src}/pubspec.lock pubspec.lock
    '';

    postInstall = ''
      install -Dm644 ${src}/assets/linux/io.github.MCDFsteve.NipaPlay-Reload.desktop \
        $out/share/applications/io.github.MCDFsteve.NipaPlay-Reload.desktop
      install -Dm644 ${src}/assets/images/logo512.png \
        $out/share/icons/hicolor/512x512/apps/io.github.MCDFsteve.NipaPlay-Reload.png
      substituteInPlace $out/share/applications/io.github.MCDFsteve.NipaPlay-Reload.desktop \
        --replace-fail "Exec=/opt/nipaplay/launcher.sh %f" "Exec=$out/bin/NipaPlay %f"
    '';

    preFixup = ''
      patchelf --shrink-rpath --allowed-rpath-prefixes "$NIX_STORE" $out/app/nipaplay-reload/lib/lib*.so
    '';

    extraWrapProgramArgs = ''
      --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib:${vulkan-loader}/lib \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : ${
        lib.makeSearchPath "lib/gstreamer-1.0" [
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good
          gst_all_1.gst-plugins-bad
        ]
      }
    '';

    meta = {
      description = "A modern cross-platform local video player with danmaku support";
      homepage = "https://github.com/AimesSoft/NipaPlay-Reload";
      license = lib.licenses.gpl3Only;
      mainProgram = "NipaPlay";
      platforms = ["x86_64-linux"];
    };
  }
