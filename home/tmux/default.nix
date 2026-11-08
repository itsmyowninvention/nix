{pkgs, ...}: let
  oh-my-tmux = pkgs.fetchFromGitHub {
    owner = "gpakosz";
    repo = ".tmux";
    rev = "af33f07134b76134acca9d01eacbdecca9c9cda6";
    hash = "sha256-nXm664l84YSwZeRM4Hsweqgz+OlpyfwXcgEdyNGhaGA=";
  };
in {
  programs.tmux = {
    enable = true;
    # Must disable the sensible plugin that Home Manager enables by default, so it doesn't conflict with Oh My Tmux's built-in logic [2]
    sensibleOnTop = false;
  };

  xdg.configFile."tmux/tmux.conf".source = "${oh-my-tmux}/.tmux.conf";

  xdg.configFile."tmux/tmux.conf.local".source = ./tmux.conf.local;
}
