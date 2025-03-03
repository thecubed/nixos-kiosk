{
	description = "nixos kiosk with home assistant and frigate nvr";
	
	outputs = { ... }: {
		# export a default module from this flake to be consumed by a machine-specific flake
		nixosModules.default = ({ lib, config, ... }: {
			# import all the nix configs in ./modules
			imports = map (name: ./modules/${name})
        (builtins.attrNames (builtins.readDir ./modules));
			
		  options = {
				# define some options in the `modules.nixos-kiosk.*` namespace
				modules.nixos-kiosk = {
					system.nvidia = lib.mkEnableOption "nvidia graphics drivers";
					users.admin = lib.mkOption {
						description = "Name of the administrative user to create";
						default = "admin";
						type = lib.types.str;
					};
				  users.kiosk = lib.mkOption {
						description = "Name of the limited (kiosk) user to create. This user will automatically login at machine start.";
						default = "kiosk";
						type = lib.types.str;
					};
				  kiosk.url = lib.mkOption {
						description = "URL for kiosk-mode browser to display on login";
						default = "http://localhost:8123/";
						type = lib.types.str;
					};
					
					services = {
						containers = {
							homeassistant = {
								enable = lib.mkEnableOption "homeassistant container";
								version = lib.mkOption {
									description = "Container version (tag)";
									default = "latest";
									type = lib.types.str;
								};
							};
							zwavejs = {
								enable = lib.mkEnableOption "zwavejs container";
								version = lib.mkOption {
									description = "Container version (tag)";
									default = "latest";
									type = lib.types.str;
								};
							};
							frigate = {
								enable = lib.mkEnableOption "frigate nvr container";
								version = lib.mkOption {
									description = "Container version (tag)";
									default = "stable-tensorrt";
									type = lib.types.str;
								};
							};
						};
						
						darkstat = {
							enable = lib.mkEnableOption "darkstat bandwidth monitoring";
						};
						zerotier = {
							enable = lib.mkEnableOption "zerotier vpn";
							networkId = lib.mkOption {
								description = "ZeroTier network ID to join";
								default = "";
								type = lib.types.str;
							};
						};
					};
					
					wlan = {
						enable = lib.mkEnableOption "wlan broadcast";
						iface = lib.mkOption {
							description = "WLAN interface name";
							default = "wlan0";
							type = lib.types.str;
						};
						ssid = lib.mkOption {
							description = "WLAN SSID to broadcast";
							default = "NixOS-Kiosk";
							type = lib.types.str;
						};
						passphrase = lib.mkOption {
							description = "WPA2 passphrase for WLAN SSID";
							default = "nixos-kiosk";
							type = lib.types.str;
						};
						cidr = lib.mkOption {
							description = "IPv4 CIDR for WLAN broadcast";
							default = "192.168.81.0/24";
							# yep, validating cidrs here with a janky regex.
							type = lib.types.strMatching "^(([1-9]{0,1}[0-9]{0,2}|2[0-4][0-9]|25[0-5])\.){3}([1-9]{0,1}[0-9]{0,2}|2[0-4][0-9]|25[0-5])\/([1-2][0-9]|3[0-1])$";
						};
						reservedIPs = lib.mkOption {
							description = "Reserved IPs in WLAN DHCP range";
							default = 10;
							type = lib.types.int;
						};
						domain = lib.mkOption {
							description = "Domain name for the WLAN DNS";
							default = "nixos-kiosk.local";
							type = lib.types.str;
						};
						nat = {
							enable = lib.mkEnableOption "wlan to internet nat";
							iface = lib.mkOption {
								description = "Interface to route traffic through for WLAN -> internet NAT";
								default = "eth0";
								type = lib.types.str;
							};
						};
						
					};
					
				};
			};
		});
	};
}