{ config, lib, pkgs, ... }: 
let
  kioskConfig = config.modules.nixos-kiosk;
	dhcpConfig = (import ../lib/ipcalc.nix { inherit lib; }).calculateDhcpRange {
		cidr = kioskConfig.wlan.cidr;
		reservedIps = kioskConfig.wlan.reservedIPs;
	};
in {

	/*Failed assertions:
	       - The option definition `services.hostapd.wpaPassphrase' in `/nix/store/a2ikvsfwcmd4qkkmw6795k6g1a79c897-source/modules/network.nix' no longer has any effect; please remove it.
	       It has been replaced by `services.hostapd.radios.«interface».networks.«network».authentication.wpaPassword`.
	       While upgrading your config, please consider using the newer SAE authentication scheme
				 and one of the new `passwordFile`-like options to avoid putting the password into the world readable nix-store.
    Refer to the documentation of `services.hostapd.radios` for an example and more information.


    - The option definition `services.hostapd.ssid' in `/nix/store/a2ikvsfwcmd4qkkmw6795k6g1a79c897-source/modules/network.nix' no longer has any effect; please remove it.
    It has been replaced by `services.hostapd.radios.«interface».networks.«network».ssid`.
    Refer to the documentation of `services.hostapd.radios` for an example and more information.


    - The option definition `services.hostapd.extraConfig' in `/nix/store/a2ikvsfwcmd4qkkmw6795k6g1a79c897-source/modules/network.nix' no longer has any effect; please remove it.
    It has been replaced by `services.hostapd.radios.«interface».settings` and
    `services.hostapd.radios.«interface».networks.«network».settings` respectively
    for per-radio and per-network extra configuration. The module now supports a lot more
    options inherently, so please re-check whether using settings is still necessary.
    Refer to the documentation of `services.hostapd.radios` for an example and more information.


    - The option definition `services.hostapd.hwMode' in `/nix/store/a2ikvsfwcmd4qkkmw6795k6g1a79c897-source/modules/network.nix' no longer has any effect; please remove it.
    It has been replaced by `services.hostapd.radios.«interface».band`.
    Refer to the documentation of `services.hostapd.radios` for an example and more information.


    - The option definition `services.hostapd.interface' in `/nix/store/a2ikvsfwcmd4qkkmw6795k6g1a79c897-source/modules/network.nix' no longer has any effect; please remove it.
    All other options for this interface are now set via `services.hostapd.radios.«interface».*`.
    Refer to the documentation of `services.hostapd.radios` for an example and more information.


    - The option definition `hardware.opengl.driSupport' in `/nix/store/a2ikvsfwcmd4qkkmw6795k6g1a79c897-source/modules/gfx.nix' no longer has any effect; please remove it.
    The setting can be removed.

    - At least one radio must be configured with hostapd!
    - You must configure `hardware.nvidia.open` on NVIDIA driver versions >= 560.
    It is suggested to use the open source kernel modules on Turing or later GPUs (RTX series, GTX 16xx), and the closed source modules otherwise.

    - the list of hardware.enableAllFirmware contains non-redistributable licensed firmware files.
      This requires nixpkgs.config.allowUnfree to be true.
      An alternative is to use the hardware.enableRedistributableFirmware option.*/

	config = lib.mkIf kioskConfig.wlan.enable {
	  services.hostapd = {
			## TODO: change to services.hostapd.radios.«interface».<<param>>
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