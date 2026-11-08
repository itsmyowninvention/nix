# MaiBot + NapCat
#
# What gets deployed:
#   - maibot-core  : the MaiBot main program (LLM chat core + WebUI, host port 18001)
#   - maibot-napcat: the NapCat QQ protocol adapter (logs in the bot's QQ account, WebUI on host port 6099)
#   - network maibot : links the two containers; core reaches NapCat via the DNS name maibot-napcat:3001
#
# Data dir: ~/.config/maibot/ (config/data/plugins/logs/QQ login state all persist here)
#
# After first start:
#   1. WebUI (MaiBot)   http://localhost:18001 — find the token in the container logs:
#      systemctl --user status podman-maibot-core or podman logs maibot-core | grep Token
#   2. NapCat WebUI   http://localhost:6099 — scan the QR code to log in the bot's QQ account
#      (for the NapCat token see the container logs: systemctl --user status podman-maibot-napcat)
#   3. Configure the model API in the MaiBot WebUI and install the "Unified QQ Connector" plugin
#      (MaiBot-SnowLuma-Adapter), setting client.server to maibot-napcat and port to 3001;
#      in the NapCat WebUI, create a OneBot forward WebSocket service listening on 0.0.0.0:3001
{config, ...}: let
  dataDir = config.home.homeDirectory + "/.config/maibot";
in {
  services.podman.networks.maibot = {
    description = "MaiBot containers shared network (core <-> napcat)";
    driver = "bridge";
  };

  services.podman.containers.maibot-core = {
    image = "docker.io/sengokucola/maibot:latest";
    autoStart = true;
    network = "maibot.network";

    ports = [
      "0.0.0.0:18001:8001" # WebUI
    ];

    environment = {
      TZ = "Asia/Shanghai";
      EULA_AGREE = "8e6e7d647f7f82d6ea98456b73908656"; # built-in value from the official compose, do not change
      PRIVACY_AGREE = "91e5db7659c560bc3545e63859b6ebc0"; # built-in value from the official compose, do not change
      MAIBOT_LEGACY_0X_UPGRADE_CONFIRMED = "1"; # no interactive terminal; skip the legacy (0.x) upgrade confirmation
      MAIBOT_STATISTICS_REPORT_PATH = "/MaiMBot/data/maibot_statistics.html";
      HTTP_HOST = "0.0.0.0"; # must listen on all interfaces inside the container for the host to reach the WebUI
    };

    volumes = [
      "${dataDir}/config:/MaiMBot/config" # bot config (bot_config.toml etc.)
      "${dataDir}/data:/MaiMBot/data" # runtime data (including the database)
      "${dataDir}/data/plugins-data:/MaiMBot/data/plugins" # persistent plugin data
      "${dataDir}/data/emoji:/data/emoji" # sticker cache
      "${dataDir}/plugins:/MaiMBot/plugins" # plugin sources
      "${dataDir}/logs:/MaiMBot/logs" # logs
    ];

    extraConfig = {
      Service = {
        TimeoutStopSec = 70; # official stop_grace_period: the Runner waits at most 60s for the Worker
        # unlike compose, quadlet doesn't auto-create host mount dirs; create them before startup
        ExecStartPre = ["/run/current-system/sw/bin/mkdir -p ${dataDir}/config ${dataDir}/data ${dataDir}/data/plugins-data ${dataDir}/data/emoji ${dataDir}/plugins ${dataDir}/logs"];
      };
    };
  };

  services.podman.containers.maibot-napcat = {
    image = "docker.io/mlikiowa/napcat-docker:latest";
    autoStart = true;
    network = "maibot.network";
    networkAlias = ["napcat"];

    ports = [
      "0.0.0.0:6099:6099" # NapCat WebUI (for QR-code login)
    ];

    environment = {
      TZ = "Asia/Shanghai";
      NAPCAT_UID = "1000"; # matches the host user's UID
      NAPCAT_GID = "1000";
    };

    volumes = [
      "${dataDir}/napcat/config:/app/napcat/config" # NapCat config (including the OneBot listener settings)
      "${dataDir}/qq:/app/.config/QQ" # QQ app data (login state)
      "${dataDir}/data:/MaiMBot/data" # data dir shared with core
    ];

    extraConfig = {
      Service = {
        TimeoutStopSec = 30; # QQ spawns many processes; allow enough time for a graceful stop
        ExecStartPre = ["/run/current-system/sw/bin/mkdir -p ${dataDir}/napcat/config ${dataDir}/qq ${dataDir}/data"];
      };
    };
  };
}
