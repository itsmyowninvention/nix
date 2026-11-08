{
  inputs,
  self,
  config,
  lib,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # Only configure SSH key paths if the key exists (not in CI)
  sops.age.sshKeyPaths = ["/root/.ssh/id_ed25519"];
  sops.secrets = {
    # Exa search engine API key
    exa_api_key = {
      sopsFile = "${self}/secrets/api_keys.yaml";
      owner = "zhaochanglong";
      mode = "0400";
    };
    deepseek_api_key = {
      sopsFile = "${self}/secrets/api_keys.yaml";
      owner = "zhaochanglong";
      mode = "0400";
    };
    # OpenCode Go subscription API key (nixvim minuet code completion)
    opencode_api_key = {
      sopsFile = "${self}/secrets/api_keys.yaml";
      owner = "zhaochanglong";
      mode = "0400";
    };
  };

  environment.extraInit = ''
    export EXA_API_KEY="$(cat ${config.sops.secrets.exa_api_key.path})"
    export DEEPSEEK_API_KEY="$(cat ${config.sops.secrets.deepseek_api_key.path})"
    export OPENCODE_GO_API_KEY="$(cat ${config.sops.secrets.opencode_api_key.path})"
  '';
}
