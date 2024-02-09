{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    mnamer-src = {
      url = "github:jkwill87/mnamer/2.5.5";
      flake = false;
    };
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, mnamer-src, poetry2nix, ... }:
    flake-utils.lib.eachDefaultSystem ( system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        p2n = poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };
        inherit (p2n) mkPoetryApplication;
      in
        {
          packages.mnamer = mkPoetryApplication {
            projectDir = ./.;
            overrides = p2n.overrides.withDefaults (self: super: {
              babelfish = super.babelfish.overridePythonAttrs ( old: {
                buildInputs = ( old.buildInputs or [ ] ) ++ [ super.poetry-core ];
              });
            });
          };

          packages.default = self.packages.${system}.mnamer;

        }) // {
          overlays.mnamer = final: prev: { mnamer = self.packages.${prev.system}.mnamer; };
        };
}
