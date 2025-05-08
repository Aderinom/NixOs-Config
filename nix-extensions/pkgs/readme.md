# Testing Packages

You can test if a certain package builds by using:

```sh
nix build .#packages.x86_64-linux.<pkg> -L -K 
```
