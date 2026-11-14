{
  networking = {
    nftables.enable = true;
    # incusbr0 (incus NAT bridge): dnsmasq's DHCP/DNS service needs the host to allow inbound traffic,
    # otherwise VMs get no IPv4 and can't resolve names (RA is sent unsolicited, so only IPv6 configures itself)
    firewall.trustedInterfaces = ["incusbr0"];
    firewall.allowedTCPPorts = [
      8000 # SillyTavern
      5244 # Openlist
      3000 # New API (LLM gateway)
    ];
  };
}
