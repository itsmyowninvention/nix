_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      # Local desktop: use the 1Password agent.
      # When logged in over SSH (SSH_CONNECTION set): don't set IdentityAgent; use the forwarded SSH_AUTH_SOCK instead.
      "Match exec \"test -z \\\"$SSH_CONNECTION\\\"\"" = {
        IdentityAgent = "~/.1password/agent.sock";
      };

      "Host github.com" = {
        HostName = "ssh.github.com";
        Port = 443;
        User = "git";
      };
    };
  };
}
