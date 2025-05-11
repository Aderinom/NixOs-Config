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

2. **Change** `flake-variables.nix`
3. **Replace** `hardware-configuration.nix`
4. **Run** `./scripts/install.sh`
5. **Reboot**

Note!:  
In case there is a "vars.<xxxx>" is undefined  
I most likely forgot to push a new placeholder for the `flake-variables.nix`  
You will have to add the variable to the `flake-variables.nix`  

## Structure

```sh
├── assets           -- Wallpapers, Images, etc.
├── host-setup/      -- System Setup
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

## 



## (Un)License

This project is licensed under the Unlicense - do whatever you want with it!
