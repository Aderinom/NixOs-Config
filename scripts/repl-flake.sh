#!/usr/bin/env bash

nix repl --expr "{ flake=builtins.getFlake \"$PWD\"; }"