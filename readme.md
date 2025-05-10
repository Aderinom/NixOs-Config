# Aderinoms Nixos Config

My Personal Hyprland + Nixos Setup

## Features

- **Desktop**: Hyprland + HyprLock + Waybar + Wofi + PyWal
- **Shell**: Fish + Staship
- **Color theming** through PyWal

## Install

1. **Clone** to wherever you would like the config to be - personally I use `$HOME/.nixos-config`

    ```sh
    git clone https://github.com/Aderinom/NixOs-Config.git 
    ```

2. **Change** `flake-variables.nix`
3. **Replace** `hardware-configuration.nix`
4. **Run** `./scripts/install.sh`
5. **Reboot**

## Structure

```sh
.
├── assets           -- Wallpapers, Images, etc.
├── host-setup/      -- Default system setup
│   ├── desktop/     -- Display Manager setup
│   │   ├── hyprland -- Contains System and User Config
│   │   └── kde6
│   ├── nixos        -- System wide config
│   └── user         -- User Based - Home Manager
├── hosts/           -- Machine Type Specalization
│   ├── laptop
│   └── vm
├── nix-extensions/  -- Custom modules etc.
│   ├── modules
│   ├── overlays
│   └── pkgs
├── scripts/         -- Helper Scripts 
├── flake.nix       
├── hardware-config.nix
└── nix-config.nix   -- Sets up nixpkgs
```

## (Un)License

This project is licensed under the Unlicense - do whatever you want with it!
