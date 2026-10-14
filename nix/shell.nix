{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      devshells.default = {
        name = "awesome-cue-infra";
        packages = with pkgs; [
          argocd
          cue
          kubectl
          kubectx
          kubelogin-oidc
          kubernetes-helm
          kustomize
          talosctl
          oras
          pinact
          zizmor
          secretspec
        ];
        devshell.startup = {
          pre-commit.text = config.pre-commit.installationScript;
        };
      };
    };
}
