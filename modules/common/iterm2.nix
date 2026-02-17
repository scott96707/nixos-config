{ lib, ... }:

{
  home.file."Library/Application Support/iTerm2/DynamicProfiles/codex.json".text = ''
    {
      "Profiles": [
        {
          "Name": "Codex",
          "Guid": "2E5F4E6F-ED5D-4F3B-9A9B-3C4A7C8F0D11",
          "Normal Font": "JetBrains Mono 13",
          "Color Preset": "Catppuccin Mocha",
          "Use Transparency": true,
          "Transparency": 0.15,
          "Option Key As Meta": true
        }
      ]
    }
  '';
}
