# Schemify-Releases
Public download binaries for Schemify (Linux, macOS, Windows)

## Install

| Platform | Command |
|---|---|
| Nix / NixOS | `nix run github:Scouren/Schemify-Releases` (the editor); `nix run github:Scouren/Schemify-Releases#schemify -- --version` (the CLI). Linux x86_64 and Apple-silicon macOS |
| NixOS configuration | add the flake input `schemify.url = "github:Scouren/Schemify-Releases";` and `schemify.packages.${pkgs.system}.default` to `environment.systemPackages` |
| macOS, incl. Intel (Homebrew) | `brew install scouren/schemify/schemify` |
| Linux, macOS, Windows | download an archive from [Releases](https://github.com/Scouren/Schemify-Releases/releases) and check it against `SHA256SUMS` |

Schemify is proprietary (see its licence agreement); the Nix package is marked unfree and this flake allows only itself.
