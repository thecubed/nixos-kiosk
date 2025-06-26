{ config, lib, pkgs, ... }: 
let
  kioskConfig = config.modules.nixos-kiosk;
in {
	config = {
	  # Enable OpenGL
	  hardware.opengl = {
	    enable = true;
	    #driSupport = true;
	  };
  
	  hardware.nvidia = lib.mkIf kioskConfig.system.nvidia {
			open = true; # TODO: uhh??
	    modesetting.enable = true;
	    powerManagement.enable = false;  # Since this is a server
  
	    # Needed for Docker to access GPU
	    nvidiaSettings = true;
	    package = config.boot.kernelPackages.nvidiaPackages.stable;
	  };
  
	  # virtualisation.docker = lib.mkIf kioskConfig.system.nvidia {
	  #   enableNvidia = true;
	  # };

		hardware.nvidia-container-toolkit = lib.mkIf kioskConfig.system.nvidia {
			enable = true;
		};
  
	  # run an xserver
	  services.xserver = {
	    enable = true;
			videoDrivers = lib.mkIf kioskConfig.system.nvidia [ "nvidia" ];
	    displayManager = {
	      sddm.enable = true;
	    };
	    desktopManager.xfce = {
			  enable = true;
		    noDesktop = true;
		    enableScreensaver = false;
			};
	  };
  
	  # xfce comes with thunar daemon, we don't need it
	  programs.thunar.enable = lib.mkOverride 500 false;
  
	  # xfce enables gvfs, we don't need it
	  services.gvfs.enable = lib.mkOverride 500 false;
  
	  # xfce brings along speechd, and we don't need that either
	  services.speechd.enable = false;
	};
}