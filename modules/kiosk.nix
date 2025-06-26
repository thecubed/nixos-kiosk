{ config, lib, pkgs, ... }: 
let
	kioskConfig = config.modules.nixos-kiosk;
	
	# Script that waits for X session to be ready before launching Firefox
	kioskStartScript = pkgs.writeShellScript "kiosk-start" ''		
		# Wait for X server to respond
		while ! ${pkgs.xorg.xset}/bin/xset q >/dev/null 2>&1; do
			sleep 1
		done
		
		# Wait for window manager to be running (check for _NET_WM_NAME)
		while ! ${pkgs.xorg.xprop}/bin/xprop -root _NET_WM_NAME >/dev/null 2>&1; do
			sleep 1
		done

		exec ${pkgs.firefox}/bin/firefox --kiosk ${kioskConfig.kiosk.url}
	'';
in {
	config = {
	  # Firefox kiosk mode
	  systemd.user.services.kiosk-browser = {
	    description = "Start Firefox in kiosk mode";
	    wantedBy = [ "graphical-session.target" ];
			after = [ "graphical-session.target" ];
			# Ensure the service waits for the desktop session to be fully ready
			wants = [ "xfce4-session.target" ];
			after = [ "xfce4-session.target" ];
	    serviceConfig = {
	      ExecStart = kioskStartScript;
	      Restart = "always";
	      RestartSec = "5s";
	    };
	  };
  
	  services.xserver = {
	    displayManager = {
	      autoLogin = {
	        enable = true;
	        user = kioskConfig.users.kiosk;
	      };
			};
	  };
	};
}