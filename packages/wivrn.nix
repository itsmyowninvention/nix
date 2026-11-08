{pkgs, ...}: {
  # WiVRn — OpenXR wireless streaming (standalone headsets like Quest)
  services.wivrn = {
    enable = true;
    autoStart = true; # start automatically on login
    openFirewall = true; # open port 9757 automatically
    highPriority = true; # async reprojection needs cap_sys_nice
    monadoEnvironment = {
      IPC_EXIT_ON_DISCONNECT = "off";
      XRT_COMPOSITOR_LOG = "debug";
      XRT_PRINT_OPTIONS = "on";
    };
    steam = {
      enable = true;
      importOXRRuntimes = true; # sets PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1 system-wide
    };
  };

  # Monado — OpenXR runtime (xrizer fallback + local VR app support)
  services.monado = {
    enable = true;
    defaultRuntime = false;
    highPriority = true;
  };

  # OpenVR->OpenXR bridge + Wayland VR compositor
  environment.systemPackages = with pkgs; [
    opencomposite
    xrizer
    wayvr
  ];
}
