{
  perSystem = {
    devshells.default = {
      name = "awesome-cue-infra";
      env = [
        {
          name = "KUBECONFIG";
          eval = "$PRJ_ROOT/.secrets/kubernetes/config";
        }
        {
          name = "TALOSCONFIG";
          eval = "$PRJ_ROOT/.secrets/talos/config";
        }
      ];
    };
  };
}
