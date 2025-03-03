{ config, lib, pkgs, ... }: 
let
  kioskConfig = config.modules.nixos-kiosk;
	dhcpConfig = (import ../lib/ipcalc.nix { inherit lib; }).calculateDhcpRange {
		cidr = kioskConfig.wlan.cidr;
		reservedIPs = kioskConfig.wlan.reservedIPs;
	};
in {
	config = lib.mkIf kioskConfig.wlan.enable {
	  services.hostapd = {
	    enable = true;
	    interface = kioskConfig.wlan.iface; 
	    hwMode = "g";
	    ssid = kioskConfig.wlan.ssid;
	    wpaPassphrase = kioskConfig.wlan.passphrase;
	    extraConfig = ''
	      ieee80211n=1
	      wmm_enabled=1
	      channel=6
	      auth_algs=1
	      wpa=2
	      wpa_key_mgmt=WPA-PSK
	      rsn_pairwise=CCMP
	    '';
	  };

	  # Enable and configure dnsmasq for DHCP and DNS
	  services.dnsmasq = {
	    enable = true;
			settings = {
				interface = kioskConfig.wlan.iface;
				dhcp-range = "${dhcpConfig.start},${dhcpConfig.end},24h";
				dhcp-option = [
	        "option:router,${dhcpConfig.first}"
	        "option:dns-server,${dhcpConfig.first}"
	      ];
				dhcp-authoritative = true;
				
				domain = kioskConfig.wlan.domain;
	      #expand-hosts = true;
	      local = "/${kioskConfig.wlan.domain}/";
			};
	  };

	  # Configure networking
	  networking = {
	    firewall = {
				enable = true;
				allowedTCPPorts = [ 22 ]; # ssh only on all ifaces
				interfaces.${kioskConfig.wlan.iface}.allowedUDPPorts = [ 53 67 ];  # dns, dhcp
			};

	    nat = {
	      enable = kioskConfig.wlan.nat.enable;
	      externalInterface = kioskConfig.wlan.nat.iface;
	      internalInterfaces = [ kioskConfig.wlan.iface ];  # Your WiFi interface
	    };
	    interfaces.${kioskConfig.wlan.iface} = {
	      ipv4.addresses = [{
	        address = dhcpConfig.first;
	        prefixLength = dhcpConfig.prefixLength;
	      }];
	    };
	  };
		
		# probably not needed, but whatever
	  boot.kernel.sysctl = {
	    "net.ipv4.ip_forward" = 1;
	  };

	  # Enable wireless support
	  hardware.enableAllFirmware = true;
	  #boot.extraModulePackages = [ config.boot.kernelPackages.rtl8192cu ];

		# probably don't need this...
	  networking.networkmanager.enable = true;
	  networking.networkmanager.unmanaged = [ kioskConfig.wlan.iface ]; # Prevent NetworkManager from managing the AP interface
	};
}