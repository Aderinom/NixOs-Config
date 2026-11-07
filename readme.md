# Aderinoms NixOS Config

My NixOS config. One flake builds every machine I run.

## Feature sets

A host turns on feature sets in its `vars.nix`.
Each folder in `feature-sets/` with a `default.nix` is one feature set.

`base` is the default for every host.
Other sets can turn on what they need, for example `normal-use` turns on `base` and `graphical-session`.

## Install

1. Clone the repo to `~/.nixos-config`, because `flakeRoot` in `flake-variables.nix` holds that path.

    ```sh
    git clone https://github.com/Aderinom/NixOs-Config.git ~/.nixos-config
    ```

2. Create `hosts/<hostname>/` with three files. Copy an existing host to start.
    - `default.nix` imports `./hardware-configuration.nix` and holds the config of this machine.
    - `vars.nix` holds the feature sets and state versions.
    - `hardware-configuration.nix` is the output of `nixos-generate-config --show-hardware-config`.
3. Run `./scripts/install.sh <hostname>`.
4. Reboot.

After the first install, `./scripts/switch.sh` or `nh os switch .` rebuilds the machine.
Both pick the host folder that matches the hostname.

## Structure

```sh
├── assets/              -- Wallpapers and images
├── feature-sets/        -- Feature sets, turned on per host in vars.features
├── hosts/<hostname>/    -- One folder per machine, see Install
├── nix-extensions/      -- Custom modules, overlays and packages
├── scripts/             -- Install, switch and VM test scripts
├── flake.nix            -- One nixosConfiguration per host folder
├── flake-variables.nix  -- Vars every host shares
└── flake-nix-config.nix -- Sets up nixpkgs and imports the feature sets
```

## Hardware

If you run a gaming laptop, look at <https://github.com/NixOS/nixos-hardware/tree/master>.

## (Un)License

The Unlicense covers this project, so do whatever you want with it!
