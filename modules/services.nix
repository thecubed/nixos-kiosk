{ config, lib, pkgs, ... }: 
let
  kioskConfig = config.modules.nixos-kiosk;
in {
	config = {
	  services.openssh.enable = true;
	  services.openssh.settings.PermitRootLogin = "yes";
  
		environment.systemPackages = 
  		lib.optional kioskConfig.services.darkstat.enable pkgs.darkstat;
		
		#
		# Configure darkstat for bandwidth monitoring
		# TODO: this could probably move to a lightweight container - no need for it to be in the host scope
		#
	  systemd.services.darkstat = lib.mkIf kioskConfig.services.darkstat.enable {
	    description = "Darkstat network traffic analyzer";
	    wantedBy = [ "multi-user.target" ];
	    after = [ "network.target" ];
	    serviceConfig = {
	      ExecStart = ''
	        ${pkgs.darkstat}/bin/darkstat \
					  --user=nobody \
	          --interface=${kioskConfig.wlan.iface} \
	          --interface=${kioskConfig.wlan.nat.iface} \
	          --local-only \
	          --port=8119 \
	          --chroot-dir=/var/lib/darkstat \
	          --pidfile=/run/darkstat.pid \
	          --no-daemon
	      '';
	      Restart = "on-failure";
	      RestartSec = "30s";
	    };
	  };
		systemd.tmpfiles.settings = lib.mkIf kioskConfig.services.darkstat.enable {
      "darkstat" = {
        "/var/lib/darkstat" = {
          d = {
            mode = "0750";
            user = "nobody";
            group = "nogroup";
          };
        };
      };
    };
		
		#
		# zerotier
		#
		services.zerotierone = lib.mkIf kioskConfig.services.zerotier.enable {
	    enable = true;
	    joinNetworks = [
				kioskConfig.services.zerotier.networkId
	    ];
	  };
	  networking.firewall = {
	    allowedUDPPorts = [ 9993 ];
	  };
		
		# other services here...
	};
}
  