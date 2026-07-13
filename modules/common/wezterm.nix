{ pkgs, ... }:

{
  programs.wezterm = {
    enable = true;

    extraConfig = ''
      local wezterm = require 'wezterm'
      local act = wezterm.action
      local config = wezterm.config_builder()

      local is_mac = wezterm.target_triple:find 'darwin' ~= nil
      -- One modifier for all custom pane bindings: CMD+SHIFT on macOS,
      -- CTRL+SHIFT on Linux.
      local mod = is_mac and 'CMD|SHIFT' or 'CTRL|SHIFT'

      -- 1. Appearance
      config.color_scheme = 'Catppuccin Mocha'
      -- Same Nerd Font as VS Code / the rest of the config; installed
      -- system-wide via fonts.packages in common.nix.
      config.font = wezterm.font 'JetBrainsMono Nerd Font'
      config.font_size = 13.0

      -- 2. Window Settings
      config.window_background_opacity = 0.85
      config.window_decorations = 'RESIZE'
      config.hide_tab_bar_if_only_one_tab = true

      config.window_padding = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 25, -- keep the prompt off the screen edge
      }

      config.scrollback_lines = 10000

      -- 3. Keybindings
      config.keys = {
        -- OPT+arrows jump by word
        { key = 'LeftArrow', mods = 'OPT', action = act.SendString '\x1bb' },
        { key = 'RightArrow', mods = 'OPT', action = act.SendString '\x1bf' },

        -- Panes. Navigation between panes is builtin: CTRL+SHIFT+arrows.
        { key = 'd', mods = mod, action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
        { key = 'e', mods = mod, action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
        { key = 'z', mods = mod, action = act.TogglePaneZoomState },
        -- Close pane instead of whole tab (closes the tab when it's the
        -- last pane anyway)
        { key = 'w', mods = mod, action = act.CloseCurrentPane { confirm = true } },
      }

      -- 4. Disable bell (audible + visual)
      config.audible_bell = 'Disabled'
      config.visual_bell = {
        fade_in_function = 'Constant',
        fade_out_function = 'Constant',
        fade_in_duration_ms = 0,
        fade_out_duration_ms = 0,
      }

      return config
    '';
  };
}
