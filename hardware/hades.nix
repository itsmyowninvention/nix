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
      };
    };
    kernelModules = [
      "kvm-amd"
      "amdgpu"
      "overlay"
      "br_netfilter"
    ];
    extraModulePackages = [];
    loader = {
      systemd-boot.enable = lib.mkForce false;
      systemd-boot.configurationLimit = 100;
      efi.canTouchEfiVariables = true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
    kernelPackages = pkgs.linuxPackages_zen;
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
