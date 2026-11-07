{...}: {
  programs.fish.shellAliases = {
    rn = "hyprctrl dispatch exec";

    mkubectl = "minikube kubectl -- ";

    bazel = "bazelisk";

    check-ops-vpn = "sudo systemctl status openvpn-ops-vpn.service";
    start-ops-vpn = "sudo systemctl start openvpn-ops-vpn.service";
    stop-ops-vpn = "sudo systemctl stop openvpn-ops-vpn.service";
  };
}
