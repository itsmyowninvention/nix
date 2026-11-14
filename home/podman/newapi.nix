# New API — LLM API gateway/aggregation (QuantumNous/new-api, one-api family)
#
# What gets deployed:
#   - newapi: the New API server — OpenAI-compatible relay with a web console for
#     managing upstream channels (OpenAI/DeepSeek/...), tokens, quotas and usage
#     stats, host port 3000
#
# Data dir: ~/.config/newapi/ (SQLite DB one-api.db, uploads and logs persist here)
#
# After first start:
#   1. WebUI http://localhost:3000 — the setup wizard creates the admin account on
#      first access (no default root password; whoever opens the page first claims it)
#   2. Add upstream channels and create relay tokens in the WebUI; clients then call
#      the OpenAI-compatible endpoint at http://<host>:3000/v1
#
# Deployment notes:
#   - SQLite (the default) is the official choice for single-node personal use;
#     PostgreSQL/Redis are only required for multi-node or shared-cache setups.
#   - SESSION_SECRET is intentionally unset (single node): container restarts then
#     only invalidate WebUI login sessions, no data loss. Wire it via sops if this
#     ever grows past one node.
{config, ...}: let
  dataDir = config.home.homeDirectory + "/.config/newapi";
in {
  services.podman.containers.newapi = {
    image = "docker.io/calciumion/new-api:latest";
    autoStart = true;

    ports = [
      "0.0.0.0:3000:3000" # WebUI + OpenAI-compatible relay endpoint
    ];

    environment = {
      TZ = "Asia/Shanghai";
      ERROR_LOG_ENABLED = "true"; # record upstream error logs (official compose default)
      BATCH_UPDATE_ENABLED = "true"; # batch DB writes for high-frequency usage stats (official compose default)
      NODE_NAME = "hades"; # node identity in audit logs (recommended for container deploys)
    };

    volumes = [
      "${dataDir}:/data" # SQLite DB, config, uploads — must persist
      "${dataDir}/logs:/app/logs" # relay/system logs
    ];

    exec = "--log-dir /app/logs"; # official compose startup args

    extraConfig = {
      Service = {
        # unlike compose, quadlet doesn't auto-create host mount dirs; create them before startup
        ExecStartPre = ["/run/current-system/sw/bin/mkdir -p ${dataDir} ${dataDir}/logs"];
      };
    };
  };
}
