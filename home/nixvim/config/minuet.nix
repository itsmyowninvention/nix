{
  # AI code completion (Copilot-style ghost text). Backend is the local New API gateway
  # (container behind passt on port 3000), key exported by sops as NEW_API_KEY (see sops.nix).
  # The gateway speaks plain HTTP only: minuet passes end_point verbatim to curl, so
  # https:// here made curl exit 35 (CURLE_SSL_CONNECT_ERROR, "wrong version number"),
  # and the full /v1/chat/completions path must be included.
  plugins.minuet = {
    enable = true;
    settings = {
      provider = "openai_compatible";
      throttle = 1500;
      debounce = 600;
      # gateway models reason implicitly, so usable content arrives after the reasoning
      # tokens; under streaming, an early timeout simply means no suggestion — keep headroom
      request_timeout = 8;
      # one suggestion is enough for ghost text; fewer output candidates also shortens the model's reasoning
      n_completions = 1;
      notify = "warn";

      provider_options.openai_compatible = {
        # minuet reads the env var name; the value is exported by sops
        api_key = "NEW_API_KEY";
        # minuet passes this verbatim to curl. The local New API gateway is HTTP-only
        # (https:// gives curl exit 35) and needs the full chat-completions path.
        end_point = "http://localhost:3000";
        # Model must exist on the local gateway (space-bunny was an OpenCode Go remote model
        # and returns model_not_found here). glm-5.3-flash is the fastest reasoning model
        # available; its reasoning_content is short enough to fit inside max_tokens.
        model = "glm-5.3-flash";
        name = "OpenCode Go";
        stream = true;
        # OpenCode Go requires the client to send a user-agent plus a stable session header.
        # v0.9.0's curl_extra_args doesn't support functions (the README is ahead of the implementation and it
        # crashes right in ipairs), so inject via transform instead; per-nvim-instance session id below.
        # Harmless against the local gateway, which ignores unknown headers.
        transform.__raw = ''
          {
            function(t)
              t.headers['User-Agent'] = 'minuet-nixvim/1.0'
              t.headers['x-opencode-session'] = vim.g.minuet_session_id or 'nixvim'
              return t
            end,
          }
        '';
        optional = {
          # gateway models reason implicitly; leave enough room so the reasoning doesn't overflow and swallow the completion
          max_tokens = 512;
          top_p = 0.9;
        };
      };

      virtualtext = {
        # keep rendering ghost text while the blink menu is open, so "menu open without selection + Tab" can accept a suggestion
        show_on_completion_menu = true;
        # same language set as lsp.nix / metals.nix: automatic; other files trigger manually with <A-]>
        auto_trigger_ft = [
          "nix"
          "rust"
          "python"
          "c"
          "cpp"
          "typescript"
          "typescriptreact"
          "javascript"
          "javascriptreact"
          "lua"
          "sh"
          "bash"
          "json"
          "yaml"
          "toml"
          "scala"
          "sbt"
        ];
        keymap = {
          accept = "<A-A>"; # accept the full suggestion
          accept_line = "<A-a>"; # accept line by line
          accept_n_lines = "<A-z>"; # accept n lines (prompts for a number)
          next = "<A-]>"; # next one; triggers manually when no suggestion is showing
          prev = "<A-[>";
          dismiss = "<A-e>";
        };
      };
    };
  };

  # one stable session ID per Neovim instance, for the x-opencode-session header
  extraConfigLua = ''
    do
      math.randomseed(vim.loop.hrtime())
      local t = {}
      for _ = 1, 16 do
        t[#t + 1] = string.format("%02x", math.random(0, 255))
      end
      vim.g.minuet_session_id = table.concat(t)
    end
  '';
}
