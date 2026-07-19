{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    # Deliberately false: this option sets EDITOR/VISUAL to "nvim", which
    # collides with the explicit EDITOR = "vim" in the host home.nix files
    # (a hard eval error, not a silent override). vimAlias below means `vim`
    # resolves to this neovim anyway, so nothing is lost — and every host,
    # including the home-manager-less appliances, now names the editor the
    # same way.
    defaultEditor = false;
    viAlias = true;
    vimAlias = true;
    withRuby = true;
    withPython3 = true;

    # --- 1. PLUGINS (Replaces Lazy.nvim) ---
    plugins = with pkgs.vimPlugins; [

      # Dependencies (Explicitly added to be safe)
      plenary-nvim
      nvim-web-devicons
      nui-nvim

      # Add Indent Blankline (Vertical Context Lines)
      {
        plugin = indent-blankline-nvim;
        config = ''
          require("ibl").setup({
              scope = { enabled = true },  -- Highlight the current context
              indent = { char = "│" },     -- Use a solid vertical bar
          })
        '';
        type = "lua";
      }
      # Theme: Tokyo Night
      {
        plugin = tokyonight-nvim;
        config = "vim.cmd[[colorscheme tokyonight]]";
        type = "lua";
      }

      # File Explorer: Neo-tree
      {
        plugin = neo-tree-nvim;
        config = ''
          -- Keymaps for Neo-tree
          vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { desc = 'Toggle Explorer' })
        '';
        type = "lua";
      }

      # Fuzzy Finder: Telescope
      {
        plugin = telescope-nvim;
        config = ''
          local builtin = require('telescope.builtin')
          vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find File' })
          vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Find Text' })
        '';
        type = "lua";
      }

      # Status Line: Lualine
      {
        plugin = lualine-nvim;
        config = "require('lualine').setup()";
        type = "lua";
      }

      # Autopairs
      {
        plugin = nvim-autopairs;
        config = "require('nvim-autopairs').setup({})";
        type = "lua";
      }

      # Treesitter (Highlighting)
      # Note: We use 'withAllGrammars' so you don't need to manually install parsers
      # Note: nixpkgs 26.05 rewrote 'nvim-treesitter' with a new minimal API: setup()
      # only configures the parser install directory, and highlighting/indent are
      # enabled per-buffer instead of via configs.setup({ highlight, indent }).
      {
        plugin = nvim-treesitter.withAllGrammars;
        config = ''
          vim.api.nvim_create_autocmd('FileType', {
            callback = function()
              pcall(vim.treesitter.start)
              vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end,
          })
        '';
        type = "lua";
      }
    ];

    # --- 2. GENERAL SETTINGS (Your vim.opt options) ---
    initLua = ''
      vim.g.mapleader = " "
      vim.opt.clipboard = "unnamedplus"

      -- Mouse clicks won't move cursor
      vim.opt.mouse = ""
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
      vim.opt.softtabstop = 2
      vim.opt.ignorecase = true
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.scrolloff = 8
      vim.opt.smartcase = true
      vim.opt.termguicolors = true
      -- Highlights the specific column your cursor is on (can be noisy)
      vim.opt.cursorcolumn = true
      -- Clear search highlight on Esc
      vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
    '';
  };
}
