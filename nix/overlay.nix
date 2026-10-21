{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          (_: prev: {
            # Pin CUE to v0.18.0-rc.1 (language v0.18.0, see cue.mod/module.cue)
            # until a v0.18.0 release reaches nixpkgs; then drop this override
            # and let flake.lock pick the version again.
            #
            # Installed from the upstream release tarball (a static binary)
            # rather than built from source, which no binary cache would have.
            cue =
              let
                cueVersion = "0.18.0-rc.1";
                assets = {
                  "x86_64-linux" = {
                    arch = "linux_amd64";
                    hash = "sha256-ITtBaw8L67DjXgMpiNiHYYf5NczYdzUm1oGb2TRvoQQ=";
                  };
                  "aarch64-linux" = {
                    arch = "linux_arm64";
                    hash = "sha256-1+a62JOhKb/zgKMqs1qFmfKEXtQHxduupBv2/J8vIu0=";
                  };
                  "x86_64-darwin" = {
                    arch = "darwin_amd64";
                    hash = "sha256-k7yPxUFyb4nPIb5/ewN2o1xrT/mOv3i0ug/h4pJVQ60=";
                  };
                  "aarch64-darwin" = {
                    arch = "darwin_arm64";
                    hash = "sha256-HBIvdaexnA9P+Icagd+SccVYxS8a06nN8BmDF03QA/c=";
                  };
                };
                asset = assets.${system} or (throw "cue: unsupported system ${system}");
              in
              prev.stdenvNoCC.mkDerivation {
                pname = "cue";
                version = cueVersion;
                src = prev.fetchurl {
                  url = "https://github.com/cue-lang/cue/releases/download/v${cueVersion}/cue_v${cueVersion}_${asset.arch}.tar.gz";
                  inherit (asset) hash;
                };
                sourceRoot = ".";
                dontBuild = true;
                installPhase = ''
                  runHook preInstall
                  install -Dm755 cue "$out/bin/cue"
                  runHook postInstall
                '';
                meta = {
                  description = "CUE is an open source data constraint language";
                  homepage = "https://cuelang.org";
                  license = prev.lib.licenses.asl20;
                  mainProgram = "cue";
                  platforms = builtins.attrNames assets;
                };
              };
          })
        ];
      };
    in
    {
      _module.args.pkgs = pkgs;
      packages.cue = pkgs.cue;
    };
}
