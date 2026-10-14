{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    let
      # Everything CI needs to vet, render, publish and release manifests.
      ciPackages = with pkgs; [
        cue
        oras
        cosign
        jq
        yq-go
        gh
        talosctl
      ];
    in
    {
      devshells.default = {
        name = "awesome-cue-infra";
        packages =
          ciPackages
          ++ (with pkgs; [
            age
            argocd
            fluxcd
            kubectl
            kubectx
            kubelogin-oidc
            kubernetes-helm
            kustomize
            pinact
            secretspec
            sops
            zizmor
          ]);
        devshell.startup = {
          pre-commit.text = config.pre-commit.installationScript;
        };
      };

      devshells.ci = {
        name = "awesome-cue-infra-ci";
        packages = ciPackages;
      };
    };
}
