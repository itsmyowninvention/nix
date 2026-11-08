{pkgs, ...}: {
  extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      pname = "agentic.nvim";
      version = "2026-08-23";
      src = pkgs.fetchFromGitHub {
        owner = "carlos-algms";
        repo = "agentic.nvim";
        rev = "81628c1dc07edadd1c2c3c27d8dbcb424da1dea0";
        hash = "sha256-gGesKupHCLVTQ27vj2OTllOPNG1hubZdUrYTqpofEVM=";
      };
      # Test modules live under lua/ and fail nvimRequireCheck.
      doCheck = false;
    })
  ];

  plugins = {
    # Render Agentic chat markdown.
    render-markdown = {
      enable = true;
      settings.file_types = [
        "markdown"
        "AgenticChat"
      ];
    };
  };

  extraConfigLua = ''
    require("agentic").setup({
      -- pi coding agent via ACP (the pi-acp adapter bridges pi --mode rpc).
      -- The model is configured in pi's ~/.pi/agent/settings.json; <leader>ap switches back to opencode-acp.
      provider = "pi-acp",
      acp_providers = {
        ["pi-acp"] = {
          -- resolves to the pi-acp adapter injected via nixvim extraPackages (spawns the system pi)
          command = "pi-acp",
          env = {
            HOME = vim.env.HOME,
            PATH = vim.env.PATH,
          },
        },

        -- kept as a fallback: OpenCode CLI via ACP (opencode-go subscription)
        ["opencode-acp"] = {
          command = "opencode",
          args = { "acp" },
          env = {
            HOME = vim.env.HOME,
            PATH = vim.env.PATH,
          },
        },
      },
      windows = {
        position = "right",
        width = "40%",
      },
    })

    -- Prefer destroy over background when replacing the current session
    -- (new_session / restore / in-widget "new"). Plugin has no config for this.
    do
      local SessionRegistry = require("agentic.session_registry")
      function SessionRegistry.choose_session_lifecycle(session, _prompt, on_selected)
        on_selected(session ~= nil)
      end
    end
  '';

  # Do not bind <C-\>: vim-tmux-navigator already uses it for last pane.
  keymaps = [
    {
      mode = ["n" "v"];
      key = "<leader>aa";
      action.__raw = "function() require('agentic').toggle() end";
      options.desc = "Toggle Agentic chat";
    }
    {
      mode = ["n" "v"];
      key = "<leader>at";
      action.__raw = "function() require('agentic').toggle() end";
      options.desc = "Toggle Agentic chat";
    }
    {
      mode = ["n" "v"];
      key = "<leader>an";
      action.__raw = "function() require('agentic').new_session() end";
      options.desc = "New Agentic session";
    }
    {
      mode = ["n" "v"];
      key = "<leader>ac";
      action.__raw = "function() require('agentic').add_selection_or_file_to_context() end";
      options.desc = "Add file or selection to Agentic";
    }
    {
      mode = "n";
      key = "<leader>ad";
      action.__raw = "function() require('agentic').add_current_line_diagnostics() end";
      options.desc = "Add line diagnostics to Agentic";
    }
    {
      mode = "n";
      key = "<leader>aD";
      action.__raw = "function() require('agentic').add_buffer_diagnostics() end";
      options.desc = "Add buffer diagnostics to Agentic";
    }
    {
      mode = "n";
      key = "<leader>ah";
      action.__raw = "function() require('agentic').restore_session() end";
      options.desc = "Restore Agentic session";
    }
    {
      mode = "n";
      key = "<leader>ap";
      action.__raw = "function() require('agentic').switch_provider() end";
      options.desc = "Switch Agentic provider";
    }
    {
      mode = "n";
      key = "<leader>as";
      action.__raw = "function() require('agentic').select_session() end";
      options.desc = "Select Agentic session";
    }
    {
      mode = "n";
      key = "<leader>ar";
      action.__raw = "function() require('agentic').rotate_layout() end";
      options.desc = "Rotate Agentic layout";
    }
    {
      mode = "n";
      key = "<leader>aS";
      action.__raw = "function() require('agentic').stop_generation() end";
      options.desc = "Stop Agentic generation";
    }
  ];
}
