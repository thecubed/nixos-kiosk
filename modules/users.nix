{ config, lib, pkgs, ... }: 
let
	kioskUsers = config.modules.nixos-kiosk.users;
in {
	config = {
		security.sudo.wheelNeedsPassword = false;
	  users.users = {
			"${kioskUsers.admin}" = {
				isNormalUser = true;
				extraGroups = [ "wheel" ];
				packages = with pkgs; [
					vim
				];
			};
	
			"${kioskUsers.kiosk}" = {
			  isNormalUser = true;
			  #extraGroups = [ ];
			  hashedPassword = "";  # Passwordless login
			};
	  };
	};
}