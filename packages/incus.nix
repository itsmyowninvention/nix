_: {
  virtualisation.incus = {
    enable = true;
    # 首次启动时自动执行 `incus admin init --preseed`，免去交互初始化：
    # dir 存储池 + NAT 网桥 incusbr0，容器开箱即用。
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

  # 不给普通用户 incus / incus-admin 组：incus 组拥有完整 API 权限，
  # 可经容器挂载宿主任意路径（root 等效）。
}
