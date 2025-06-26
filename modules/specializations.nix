{ config, lib, pkgs, ... }: {
	config = {
	  # specializations for different scenarios
		specialisation = {			
			debug.configuration = {
				# a debug configuration that starts a deskop manager
			  services.xserver = {
			    desktopManager.xfce = {
				    noDesktop = lib.mkForce false;
					};
			  };
			  programs.thunar.enable = lib.mkForce true;
			  services.gvfs.enable = lib.mkForce true;
				systemd.user.services.kiosk-browser = lib.mkForce {};
			};
		};
		
		environment.shellAliases = {
		  "switch-to-debug" = "nixos-rebuild switch --specialisation debug && sudo systemctl restart display-manager.service";
		};
		
	};
}