{
  description = "beeper-matrix-proxy (minibridge) — bridge a remote Matrix homeserver into Beeper";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        version = "0.1.0";
      in {
        packages.default = pkgs.buildGoModule {
          pname = "minibridge";
          inherit version;
          src = ./.;

          # Pure-Go olm (no libolm system dependency). CGO is still used for
          # go-sqlite3, which buildGoModule handles via the stdenv C compiler.
          tags = [ "goolm" ];

          # Only build the bridge entrypoint, not the separate beepersource/ tools.
          subPackages = [ "." ];

          # Updated by `nix run .#update-vendor` (or copy the hash nix prints on mismatch).
          vendorHash = "sha256-yEqbJnCAm6fXjmme7TmmxPgUY3yr7ceIhJ28AaEP1qY=";

          ldflags = [
            "-s" "-w"
            "-X main.Tag=v${version}"
            "-X main.Commit=${self.rev or self.dirtyRev or "nix"}"
          ];

          doCheck = false;

          postInstall = ''
            # Upstream calls the binary "minibridge"; go names it after the module.
            if [ -e "$out/bin/beeper-matrix-proxy" ]; then
              mv "$out/bin/beeper-matrix-proxy" "$out/bin/minibridge"
            fi
          '';

          meta = {
            description = "Matrix-to-Beeper bridgev2 proxy for private Matrix homeservers";
            mainProgram = "minibridge";
          };
        };
      });
}
