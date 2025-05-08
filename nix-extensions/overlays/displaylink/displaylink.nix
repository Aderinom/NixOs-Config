{
  final, # nix config before the overlay is applied
  prev, # nix config after the overlay was applied
}:
prev.displaylink.overrideAttrs (oldAttrs: {
  src = ./displaylink600.zip;
})
