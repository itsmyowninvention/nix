# Hardware configuration for Hades
# Partuuids restored from commit 25e427b^ (pre-LIANLI snapshot).
{
  self,
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  boot = {
    initrd = {
      systemd.enable = true;
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = ["tpm_tis"];
      luks.devices = {
        "crypt1" = {
          device = "/dev/disk/by-partuuid/cec43cac-f70a-4ef5-9f52-bbbf7225b0c5";
          crypttabExtraOpts = ["tpm2-device=auto"];
        };
        "crypt2" = {
          device = "/dev/disk/by-partuuid/7941ceaf-15e2-4711-af3c-bffdc2b9c345";
          crypttabExtraOpts = ["tpm2-device=auto"];
        };
        "crypt-swap" = {
          device = "/dev/disk/by-partuuid/38dfabec-d147-4061-8fbb-b3f9a295f847";
          crypttabExtraOpts = ["tpm2-device=auto"];
        };
      };
    };
    kernelModules = [
      "kvm-amd"
      "amdgpu"
      "overlay"
      "br_netfilter"
      "nct6775"
    ];
    # ASUS Super I/O region is claimed by ACPI; lax lets nct6775 probe it
    kernelParams = ["acpi_enforce_resources=lax"];
    extraModulePackages = [];
    loader = {
      systemd-boot.enable = lib.mkForce false;
      systemd-boot.configurationLimit = 100;
      efi.canTouchEfiVariables = true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      configurationLimit = 8; # measured boot 要求 ≤8（策略最多 8 个引导变体）
      measuredBoot = {
        enable = true;
        # PCR 7 预测受 systemd #40381 影响（AMD fTPM authority 事件序错乱），
        # 预测值 ≠ 实际值导致解锁失败，上游修复后再加回
        pcrs = [0 4];
      };
    };
    kernelPackages = pkgs.linuxPackages_zen;
    resumeDevice = "/dev/mapper/crypt-swap";
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "compress=zstd"
      ];
    };
    "/home" = {
      device = "/dev/disk/by-label/NIXOS";
      fsType = "btrfs";
      options = [
        "subvol=@home"
        "compress=zstd"
      ];
    };
    "/nix" = {
      device = "/dev/disk/by-label/NIXOS";
      fsType = "btrfs";
      options = [
        "subvol=@nix"
        "compress=zstd"
      ];
    };
    "/var/log" = {
      device = "/dev/disk/by-label/NIXOS";
      fsType = "btrfs";
      options = [
        "subvol=@log"
        "compress=zstd"
      ];
    };
    "/boot" = {
      device = "/dev/disk/by-partuuid/18e87963-c993-4917-aae9-ef795fcced43";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };

  swapDevices = [
    {
      device = "/dev/mapper/crypt-swap";
      priority = -1;
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
        rocmPackages.rocm-runtime
      ];
    };
  };

  environment = {
    systemPackages = with pkgs; [
      sbctl # Secure Boot 管理 (调试用: sbctl status/verify)
    ];

    variables = {
      ROC_ENABLE_PRE_VEGA = "1";
      ROCR_VISIBLE_DEVICES = "1";
      HIP_VISIBLE_DEVICES = "1";
    };
  };
}
