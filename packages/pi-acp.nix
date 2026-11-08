# pi-acp: ACP (Agent Client Protocol) adapter for pi coding agent.
# Bridges agentic.nvim (ACP client) with a `pi --mode rpc` subprocess.
# Upstream: https://github.com/svkozak/pi-acp (MIT).
# Needs the runtime pi binary (nixpkgs pi-coding-agent), which must be on PATH as well.
{
  fetchFromGitHub,
  buildNpmPackage,
  nodejs,
}:
buildNpmPackage {
  pname = "pi-acp";
  version = "0.0.34";
  nodejs = nodejs; # upstream requires node >=20

  src = fetchFromGitHub {
    owner = "svkozak";
    repo = "pi-acp";
    rev = "v0.0.34";
    hash = "sha256-QRwxOtTZOY+Np3PkAoy2o2PrUzEqjItM/372sCPlSMo=";
  };

  npmDepsHash = "sha256-BvLNtFfp1cMVjzWcMRSdhTqiJrTfbFoUbWkkPW9200o=";

  # layout: $out/lib/node_modules/pi-acp/dist/index.js + $out/bin/pi-acp (npmInstallHook defaults come from package.json bin)
}
