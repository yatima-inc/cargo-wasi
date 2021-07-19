{
  inputs = {
    utils.url = "github:yatima-inc/nix-utils";
  };

  outputs =
    { self
    , utils
    }:
    let
      flake-utils = utils.inputs.flake-utils;
    in
    flake-utils.lib.eachDefaultSystem (system:
    let
      lib = utils.lib.${system};
      pkgs = utils.nixpkgs.${system};
      inherit (lib) buildRustProject testRustProject rustDefault filterRustProject;
      rust = rustDefault;
      crateName = "cargo-wasi";
      root = ./.;
      buildInputs = with pkgs; [ openssl pkg-config ];
    in
    {
      packages.${crateName} = buildRustProject { inherit root buildInputs; };

      apps.${crateName} = flake-utils.mkApp {
        name = crateName;
        drv = self.packages.${crateName};
      };

      checks.${crateName} = testRustProject { doCheck = true; inherit root buildInputs; };

      defaultPackage = self.packages.${system}.${crateName};

      # `nix develop`
      devShell = pkgs.mkShell {
        inputsFrom = builtins.attrValues self.packages.${system};
        nativeBuildInputs = [ rust ];
        buildInputs = with pkgs; [
          rust-analyzer
          clippy
          rustfmt
        ];
      };
    });
}
