{
  pkgs,
  inputs,
  ...
}: {
  programs.neovim.enable = true;

  # programs.neovim.plugins = with pkgs.awesomeNeovimPlugins; [
  #   pkgs.neovim
  #   yankring
  #   vim-nix
  #   {
  #     plugin = vim-startify;
  #     config = "let g:startify_change_to_vcs_root = 0";
  #   }
  # ];
}
