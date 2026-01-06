{ pkgs, ... }:

{
  programs.wezterm = {
    enable = true;

    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()

      -- 1. Appearance
      config.color_scheme = 'Catppuccin Mocha'
      config.font = wezterm.font 'JetBrains Mono'
      config.font_size = 13.0

      -- 2. Window Settings
      config.window_background_opacity = 0.85
      config.window_decorations = "RESIZE"
      config.hide_tab_bar_if_only_one_tab = true

      -- FIX: Added 'config.' prefix here
      config.window_padding = {
          left = 0,
          right = 0,
          top = 0,
          bottom = 25, -- Push the text up by 5 pixels
      }

      -- 3. Keybindings
      config.keys = {
        { key = 'LeftArrow', mods = 'OPT', action = wezterm.action.SendString '\x1bb' },
        { key = 'RightArrow', mods = 'OPT', action = wezterm.action.SendString '\x1bf' },
      }

      -- 4. Disable bell (audible + visual)
      config.audible_bell = "Disabled"
      config.visual_bell = {
        fade_in_function = "Constant",
        fade_out_function = "Constant",
        fade_in_duration_ms = 0,
        fade_out_duration_ms = 0,
      }

      return config
    '';
  };
}
