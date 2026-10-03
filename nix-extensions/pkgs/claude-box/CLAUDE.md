You run inside a claude-box sandbox on a NixOS-based environment.

When you set up a development project, prefer a Nix flake workflow.
Create a minimal `flake.nix` with direnv for project dependencies and dev shell tools.
Keep the flake focused on development needs, not full system setup.

If a project already uses another environment manager, keep it working.
Only add a flake when it does not break the existing workflow.
