{ config, lib, pkgs, ... }: 
let
	kioskConfig = config.modules.nixos-kiosk;
in {
	config = {
	  # Firefox kiosk mode
	  systemd.user.services.kiosk-browser = {
	    description = "Start Firefox in kiosk mode";
	    wantedBy = [ "graphical-session.target" ];
	    serviceConfig = {
	      ExecStart = ''
	        ${pkgs.firefox}/bin/firefox --kiosk ${kioskConfig.kiosk.url}
	      '';
	      Restart = "always";
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