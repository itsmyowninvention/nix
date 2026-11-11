{
  networking = {
    nftables.enable = true;
    # incusbr0 (incus NAT bridge): dnsmasq's DHCP/DNS service needs the host to allow inbound traffic,
    # otherwise VMs get no IPv4 and can't resolve names (RA is sent unsolicited, so only IPv6 configures itself)
    firewall.trustedInterfaces = ["incusbr0"];
    firewall.filterForward = true;
    firewall.allowedTCPPorts = [
      8000 # SillyTavern
      5244 # Openlist
    ];
    # Expose http://10.146.251.23:8000 (SillyTavern in incus container) to 192.168.50.0/24:
    # DNAT tcp/192.168.50.12:8000 -> 10.146.251.23:8000
    firewall.extraForwardRules = ''
      iifname "wlp11s0" oifname "incusbr0" ip saddr 192.168.50.0/24 ip daddr 10.146.251.23 tcp dport 8000 accept
      iifname "incusbr0" oifname "wlp11s0" ct state established,related accept
    '';
  };
  networking.nat = {
    enable = true;
    externalInterface = "wlp11s0";
    forwardPorts = [
      {
        proto = "tcp";
        sourcePort = 8000;
        destination = "10.146.251.23:8000";
      }
    ];
  };
}
