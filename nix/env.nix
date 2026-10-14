{
  perSystem = {
    devshells.default = {
      env = [
        {
          name = "KUBECONFIG";
          eval = "$PRJ_ROOT/.secrets/kubernetes/config";
        }
        {
          name = "TALOSCONFIG";
          eval = "$PRJ_ROOT/.secrets/talos/config";
        }
        {
          # age identity for SOPS (see .sops.yaml); back it up outside the repo.
          name = "SOPS_AGE_KEY_FILE";
          eval = "$PRJ_ROOT/.secrets/sops/age.key";
        }
        {
          # Headless Argo CD: talk to the cluster directly through kubeconfig.
          name = "ARGOCD_OPTS";
          value = "--core";
        }
      ];
    };
  };
}
