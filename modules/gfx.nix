{ config, lib, pkgs, ... }: 
let
  kioskConfig = config.modules.nixos-kiosk;
in {
	config = {
	  # Enable OpenGL
	  hardware.opengl = {
	    enable = true;
	    driSupport = true;
	  };
  
	  hardware.nvidia = mkIf kioskConfig.system.nvidia {
	    modesetting.enable = true;
	    powerManagement.enable = false;  # Since this is a server
  
	    # Needed for Docker to access GPU
	    nvidiaSettings = true;
	    package = config.boot.kernelPackages.nvidiaPackages.stable;
	  };
  
	  virtualisation.docker = mkIf kioskConfig.system.nvidia {
	    enableNvidia = true;
	  };
  
	  # run an xserver
	  services.xserver = {
	    enable = true;
			videoDrivers = [ "nvidia" ];
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
	  programs.thunar.enable = false;
  
	  # xfce enables gvfs, we don't need it
	  services.gvfs.enable = false;
  
	  # xfce brings along speechd, and we don't need that either
	  services.speechd.enable = false;
	};
}