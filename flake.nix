{
  description = "liqwid-plutarch-extra";

  inputs = {
    nixpkgs.follows = "plutarch/nixpkgs";
    nixpkgs-latest.url = "github:NixOS/nixpkgs?rev=a0a69be4b5ee63f1b5e75887a406e9194012b492";
    # temporary fix for nix versions that have the transitive follows bug
    # see https://github.com/NixOS/nix/issues/6013
    nixpkgs-2111 = { url = "github:NixOS/nixpkgs/nixpkgs-21.11-darwin"; };

    haskell-nix-extra-hackage.follows = "plutarch/haskell-nix-extra-hackage";
    haskell-nix.follows = "plutarch/haskell-nix";
    iohk-nix.follows = "plutarch/iohk-nix";
    haskell-language-server.follows = "plutarch/haskell-language-server";

    # Plutarch and its friends
    plutarch = {
      url = "github:Plutonomicon/plutarch-plutus?ref=staging";

      inputs.emanote.follows =
        "plutarch/haskell-nix/nixpkgs-unstable";
      inputs.nixpkgs.follows =
        "plutarch/haskell-nix/nixpkgs-unstable";
    };

    plutarch-quickcheck.url =
      "github:liqwid-labs/plutarch-quickcheck?ref=connor/liqwid-nix";
    plutarch-numeric.url =
      "github:liqwid-labs/plutarch-numeric?ref=connor/liqwid-nix";
    plutarch-context-builder.url =
      "github:Liqwid-Labs/plutarch-context-builder?ref=connor/liqwid-nix";

    liqwid-nix.url = "github:Liqwid-Labs/liqwid-nix";
  };

  outputs = inputs@{ liqwid-nix, ... }:
    (liqwid-nix.buildProject
      {
        inherit inputs;
        src = ./.;
      }
      [
        liqwid-nix.haskellProject
        liqwid-nix.plutarchProject
        (liqwid-nix.addDependencies [
          "${inputs.plutarch-quickcheck}"
          "${inputs.plutarch-numeric}"
          "${inputs.plutarch-context-builder}"
        ])
        (liqwid-nix.addChecks {
          testSuite = "liqwid-plutarch-extra:test:liqwid-plutarch-extra-test";
          liqwid-plutarch-extra = "liqwid-plutarch-extra:lib:liqwid-plutarch-extra";
        })
        (liqwid-nix.enableFormatCheck [
          "-XTemplateHaskell"
          "-XOverloadedRecordDot"
          "-XTypeApplications"
          "-XPatternSynonyms"
        ])
        liqwid-nix.enableCabalFormatCheck
        liqwid-nix.enableNixFormatCheck
      ]
    ).toFlake;
}
