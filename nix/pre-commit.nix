{ inputs, ... }:
{
  imports = [
    inputs.pre-commit-hooks-nix.flakeModule
  ];

  perSystem = {
    pre-commit.settings = {
      excludes = [
        "cue.mod/"
        "flake.lock"
      ];
      hooks = {
        cue-fmt.enable = true;
        nixfmt.enable = true;
        prettier.enable = true;
        statix.enable = true;
        deadnix.enable = true;
        zizmor.enable = true;
      };
    };
  };
}
