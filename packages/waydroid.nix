{
  lib,
  pkgs,
  ...
}: let
  waydroid = pkgs.waydroid-nftables;
  waydroidScript = pkgs.callPackage ./waydroid-script.nix {};
  user = "zhaochanglong";
  # Lineage 20 (Android 13) uses AIDL3. The NixOS module defaults to aidl2, which keeps the container from starting.
  gbinderConf = pkgs.writeText "waydroid.conf" ''
    [Protocol]
    /dev/binder = aidl3
    /dev/vndbinder = aidl3
    /dev/hwbinder = hidl

    [ServiceManager]
    /dev/binder = aidl3
    /dev/vndbinder = aidl3
    /dev/hwbinder = hidl
  '';
  initScript = pkgs.writeShellScript "waydroid-init-gapps" ''
    set -euo pipefail
    cfg=/var/lib/waydroid/waydroid.cfg
    if [[ -f "$cfg" ]] && grep -q 'system/lineage/waydroid_x86_64/GAPPS.json' "$cfg"; then
      exit 0
    fi
    if systemctl is-active --quiet waydroid-container.service; then
      systemctl stop waydroid-container.service
    fi
    # The existing image is VANILLA; its user data cannot be mixed with GApps.
    rm -rf /home/${user}/.local/share/waydroid
    ${waydroid}/bin/waydroid init -f -s GAPPS
  '';
  # waydroid_script treats any stderr output as failure, so wrap it to merge logs into stdout.
  waydroidQuiet = pkgs.writeShellScript "waydroid-quiet" ''
    exec ${waydroid}/bin/waydroid "$@" 2>&1
  '';
  waydroidBin = pkgs.runCommand "waydroid-libndk-bin" {} ''
    mkdir -p $out/bin
    ln -s ${waydroidQuiet} $out/bin/waydroid
  '';
  libndkScript = pkgs.writeShellScript "waydroid-install-libndk" ''
    set -euo pipefail
    cfg=/var/lib/waydroid/waydroid.cfg
    marker=/var/lib/waydroid/overlay/system/lib64/libndk_translation.so
    if [[ -e "$marker" ]] && grep -q 'libndk_translation.so' "$cfg"; then
      exit 0
    fi
    if systemctl is-active --quiet waydroid-container.service; then
      systemctl stop waydroid-container.service
    fi
    if [[ -S /run/user/1000/bus ]]; then
      ${pkgs.util-linux}/bin/runuser -u ${user} -- env \
        XDG_RUNTIME_DIR=/run/user/1000 \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
        WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-wayland-0} \
        ${waydroid}/bin/waydroid session stop || true
    fi
    export PATH="${waydroidBin}/bin:$PATH"
    export XDG_CACHE_HOME=/var/cache/waydroid-script
    # -a must come before the subcommand, otherwise 13 is treated as a component name.
    ${waydroidScript}/bin/waydroid-script -a 13 install libndk
    ${waydroid}/bin/waydroid container stop || true
  '';
  androidId = pkgs.writeShellScriptBin "waydroid-android-id" ''
    set -euo pipefail
    db="$HOME/.local/share/waydroid/data/data/com.google.android.gsf/databases/gservices.db"
    if [[ ! -f "$db" ]]; then
      echo "还没有 gservices.db。请先运行 waydroid show-full-ui，打开一次 Play 商店后再执行本命令。" >&2
      exit 1
    fi
    id=$(${pkgs.sqlite}/bin/sqlite3 "$db" "select value from main where name = 'android_id';")
    if [[ -z "''${id}" ]]; then
      echo "android_id 还没生成。先关掉 VPN，确认 Waydroid 能访问外网，打开一次 Play 商店后再试。" >&2
      exit 1
    fi
    echo "Android ID: $id"
    echo "用谷歌账号打开并注册这个 ID："
    echo "https://www.google.com/android/uncertified/"
    echo "注册后等 10 到 20 分钟，再执行 waydroid session stop，然后重新打开 Waydroid。"
  '';
in {
  virtualisation.waydroid = {
    enable = true;
    # Kernels 6.17+ (currently 7.1 zen) can no longer use the iptables variant.
    package = waydroid;
  };

  environment.etc."gbinder.d/waydroid.conf".source = lib.mkForce gbinderConf;

  environment.systemPackages = [androidId];

  systemd.services.waydroid-init-gapps = {
    description = "Initialize Waydroid with Google Apps images";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    before = ["waydroid-container.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "45min";
      ExecStart = initScript;
    };
  };

  systemd.services.waydroid-libndk = {
    description = "Install Waydroid libndk ARM translation";
    wantedBy = ["multi-user.target"];
    after = [
      "network-online.target"
      "waydroid-init-gapps.service"
    ];
    wants = [
      "network-online.target"
      "waydroid-init-gapps.service"
    ];
    before = ["waydroid-container.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "30min";
      ExecStart = libndkScript;
    };
  };

  systemd.services.waydroid-container = {
    after = [
      "waydroid-init-gapps.service"
      "waydroid-libndk.service"
    ];
    requires = [
      "waydroid-init-gapps.service"
      "waydroid-libndk.service"
    ];
  };
}
