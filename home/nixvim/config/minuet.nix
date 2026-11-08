{
  # AI code completion (Copilot-style ghost text). Backend is the OpenCode Go subscription:
  # endpoint https://opencode.ai/zen/go/v1/chat/completions, key exported by sops as
  # OPENCODE_GO_API_KEY (see sops.nix). For key changes/model switching see the Minuet section of the README.
  plugins.minuet = {
    enable = true;
    settings = {
      provider = "openai_compatible";
      # Official OpenCode Go example value: lowers the request rate, keeping rate limits from compounding with first-token latency
      throttle = 1500;
      debounce = 600;
      # with space-bunny, content arrives 2.4-5.6s after the gateway's reasoning; the README notes
      # that under streaming, an early timeout simply means no suggestion, so leave plenty of headroom
      request_timeout = 8;
      # one suggestion is enough for ghost text; fewer output candidates also shortens the model's reasoning
      n_completions = 1;
      notify = "warn";

      provider_options.openai_compatible = {
        # minuet reads the env var name; the value is exported by sops
        api_key = "OPENCODE_GO_API_KEY";
        end_point = "https://opencode.ai/zen/go/v1/chat/completions";
        # Empirical selection: the Go gateway routes all mainstream chat models (GLM/DeepSeek/Qwen families) into
        # forced reasoning (reasoning_content eats the token budget, and the disable-reasoning parameter is rejected by the gateway);
        # only space-bunny returns a correctly shaped incremental completion (~3s, stop, usable content).
        model = "space-bunny";
        name = "OpenCode Go";
        stream = true;
        # OpenCode Go requires the client to send a user-agent plus a stable session header.
        # v0.9.0's curl_extra_args doesn't support functions (the README is ahead of the implementation and it
        # crashes right in ipairs), so inject via transform instead; per-nvim-instance session id below.
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
