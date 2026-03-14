{inputs, lib, ...}: {
  imports = [
    inputs.sops-nix.darwinModules.sops
  ];

  # Only configure SSH key paths if the key exists (not in CI)
  sops.age.sshKeyPaths = lib.mkIf (lib.pathExists "/var/root/.ssh/id_ed25519") ["/var/root/.ssh/id_ed25519"];
}
