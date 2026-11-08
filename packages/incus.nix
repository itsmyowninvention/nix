_: {
  virtualisation.incus = {
    enable = true;
    # Automatically run `incus admin init --preseed` on first start, skipping interactive initialization:
    # dir storage pool + NAT bridge incusbr0, containers work out of the box.
    preseed = {
      config = {};
      networks = [
        {
          config = {
            "ipv4.address" = "10.100.0.1/24";
            "ipv4.nat" = "true";
          };
          description = "";
          name = "incusbr0";
          type = "bridge";
        }
      ];
      profiles = [
        {
          config = {
            "security.nesting" = "true";
          };
          description = "Default profile";
          devices = {
            eth0 = {
              name = "eth0";
              network = "incusbr0";
              type = "nic";
            };
            root = {
              path = "/";
              pool = "default";
              type = "disk";
            };
          };
          name = "default";
        }
      ];
      storage_pools = [
        {
          config = {};
          description = "";
          name = "default";
          driver = "dir";
        }
      ];
      projects = [];
    };
  };

  # Don't give regular users the incus / incus-admin groups: the incus group grants full API access,
  # which can mount arbitrary host paths into containers (equivalent to root).
}
