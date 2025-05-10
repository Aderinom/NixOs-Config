{
  imports = [ (throw ''
    Error: Replace Placeholder hardware-configuration.nix

    You have not replaced the placeholder hardware-configuration.nix file.

    You need to replace this file with your actual hardware configuration.
    To generate a proper hardware configuration, run:

      sudo nixos-generate-config --show-hardware-config

    Then, copy the output to replace the contents of this file.

    Remember to review and adjust the configuration as needed for your specific hardware.
  '') ];
}