# Aderinoms Nixos Config

My Personal Hyprland + Nixos Setup

## Features

- **Desktop**: Hyprland + HyprLock + Waybar + Wofi + PyWal
- **Shell**: Fish + Staship
- **Color theming** through PyWal
- **Nixd LSP**: Setup for NixPkgs, Home Manager and flake internals
- **Feature Sets**: Feature sets to allow splitting usecases

## Install

1. **Clone** to wherever you would like the config to be - personally I use `$HOME/.nixos-config`

    ```sh
    git clone https://github.com/Aderinom/NixOs-Config.git 
    ```

2. **Run** `./scripts/install.sh`
3. **Change** `flake-variables.nix`
4. **Replace** `hardware-configuration.nix` with your actual hardware-configuration.nix
5. **Run** `./scripts/install.sh` (again)
6. **Reboot**

**Note!**
In case there is a "vars.<xxxx>" is undefined, there is likely a new variable in the `flakes-variables.nix`
Check out `./scripts/templates/flakes-variables.nix` to check.  

## Structure

```sh
├── assets           -- Wallpapers, Images, etc.
├── feature-sets/    -- Different Feature Sets which can be activated/deactivated
├── hosts/           -- Machine Type Specalization
│   ├── laptop
│   └── vm
├── nix-extensions/  -- Custom modules etc.
│   ├── modules
│   ├── overlays
│   └── pkgs
├── scripts/         -- Helper Scripts 
├── flake.nix       
├── flake-local.nix  -- Local Only Config
├── flake-variables.nix  -- Guess what - Variables for the flake      
├── hardware-config.nix
└── nix-config.nix   -- Sets up nixpkgs
```

## Hardware

If using Gaming Laptops, you might want to take a look at: <https://github.com/NixOS/nixos-hardware/tree/master>

## Git Hooks

Since I don't want to commit some files like e.g. hardware-configuration, the install script installs git hooks to not let you commit these.

## (Un)License

This project is licensed under the Unlicense - do whatever you want with it!
