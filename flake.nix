{
  # Schemify's published release binaries as a Nix package (the source is private).
  # `nix run github:Scouren/Schemify-Releases` starts the editor; `#schemify` is the CLI.
  # sources.json lists every release archive with its sha256 (updated with each release).
  description = "Schemify: schematic capture with simulation, docs pages and plugins (release binaries)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      sources = lib.importJSON ./sources.json;
      latest = lib.last (lib.sort lib.versionOlder (lib.attrNames sources));
      # Intel macOS is not here: nixpkgs unstable dropped x86_64-darwin; Intel Macs use the
      # Homebrew tap (brew install scouren/schemify/schemify).
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      eula = {
        shortName = "schemify-eula";
        fullName = "Schemify End-User Licence Agreement";
        spdxId = "LicenseRef-Schemify-EULA";
        free = false;
        redistributable = false;
      };
      # This flake allows its own unfree package by name and nothing else.
      forAll =
        f:
        lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
              config.allowUnfreePredicate = pkg: lib.getName pkg == "schemify";
            }
          )
        );
      # Libraries the editor loads at run time (window, input, GPU).
      runtimeLibs =
        pkgs:
        lib.optionals pkgs.stdenv.hostPlatform.isLinux (
          with pkgs;
          [
            fontconfig
            wayland
            libxkbcommon
            vulkan-loader
            libGL
            libx11
            libxcursor
            libxi
            libxrandr
          ]
        );
      fromRelease =
        pkgs: v: source:
        pkgs.stdenvNoCC.mkDerivation {
          pname = "schemify";
          version = v;
          src = pkgs.fetchurl { inherit (source) url sha256; };
          sourceRoot = ".";
          nativeBuildInputs = [ pkgs.makeWrapper ] ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.autoPatchelfHook;
          buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            pkgs.stdenv.cc.cc.lib
            pkgs.glibc
          ];
          dontStrip = true;
          installPhase = ''
            runHook preInstall
            cd schemify-v${v}-*
            install -Dm755 schemify schemify-gui -t $out/bin
            install -Dm644 LICENSE -t $out/share/licenses/schemify
            runHook postInstall
          '';
          postFixup = ''
            for p in schemify schemify-gui; do
              wrapProgram $out/bin/$p \
                ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath (runtimeLibs pkgs)}"} \
                --suffix PATH : ${lib.makeBinPath [ pkgs.git pkgs.curl ]}
            done
          '';
          meta = {
            description = "Schematic capture with simulation, docs pages and plugins (release binaries)";
            homepage = "https://github.com/Scouren/Schemify-Releases";
            license = eula;
            sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
            mainProgram = "schemify-gui";
            platforms = systems;
          };
        };
    in
    {
      packages = forAll (
        pkgs:
        let
          system = pkgs.stdenv.hostPlatform.system;
          built = lib.mapAttrs (v: s: fromRelease pkgs v s.${system}) (
            lib.filterAttrs (_: s: s ? ${system}) sources
          );
        in
        built
        // rec {
          schemify-gui = built.${latest};
          default = schemify-gui;
          schemify = pkgs.writeShellScriptBin "schemify" ''exec ${schemify-gui}/bin/schemify "$@"'';
        }
      );
      apps = forAll (pkgs: {
        default = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/schemify-gui";
        };
        schemify = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/schemify";
        };
      });
      formatter = forAll (pkgs: pkgs.nixfmt);
    };
}
