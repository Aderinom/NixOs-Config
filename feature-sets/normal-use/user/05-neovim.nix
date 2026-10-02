{
  pkgs,
  inputs,
  ...
}: {
  programs.neovim.enable = true;
  programs.neovim.withRuby = true;
  programs.neovim.withPython3 = true;

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
