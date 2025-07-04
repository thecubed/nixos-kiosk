# hass
# frigate
# zwavejs
# ?
{ config, lib, pkgs, ... }: 
let
	kioskConfig = config.modules.nixos-kiosk;
	containerConfig = kioskConfig.services.containers;
	# device rules to only allow rw access to devices of certain classes (zwave, zigbee, usbserial)
	deviceRules = map (rule: "--device-cgroup-rule=${rule}") [
	  # we expose /dev to the container, but scope to only necessary dev nodes
	  # ttyAMA / ttySAC
	  "c 204:* rwm"
	  # ttyUSB
	  "c 188:* rwm"
	  # ttyACM
	  "c 166:* rwm"
	  # /dev/bus/usb
	  "c 189:* rwm"
	];
in {
	config = {

		networking = lib.mkIf containerConfig.homeassistant.enable {
			firewall = {
				# add hass to the firewall
				allowedTCPPorts = [ 8123 ];
			};
		};
		
		virtualisation.oci-containers = {
		    backend = "docker";
		    containers = {
				homeassistant = lib.mkIf containerConfig.homeassistant.enable {
					image = "linuxserver/homeassistant:${containerConfig.homeassistant.version}";
					# no ports exposed, this container runs in host networking mode
					environment = {
						PUID = "911";
						PGID = "911";
					};
					volumes = [
						"/etc/localtime:/etc/localtime:ro"
						"homeassistant_data:/config"
					];
					extraOptions = [
						"--restart=unless-stopped"
						# override nixos default
						"--rm=false"
						# run in host networking mode, accessible via all interfaces
						"--network=host"
						"--cap-add=NET_ADMIN"
						"--cap-add=NET_RAW"
						"--privileged"
					] ++ map (volume: "--volume=${volume}") [
						# intel dri for ffmpeg 
						"/dev/dri:/dev/dri"
						# expose zw/zb sticks (device rules prevent accessing insecure devices)
						"/dev:/dev:ro"
						# bluetooth access - might want to review security of this
						"/run/dbus:/var/run/dbus:ro"
					] ++ deviceRules;
				};
					
				zwavejs = lib.mkIf containerConfig.zwavejs.enable {
					image = "zwavejs/zwave-js-ui:${containerConfig.zwavejs.version}";
					ports = [ "8091:8091" ];
					environment = {
						ZWAVEJS_EXTERNAL_CONFIG = "/usr/src/app/store/.config-db";
					};
					volumes = [
						"zwavejs_data:/usr/src/app/store"
						# expose zw/zb sticks (device rules prevent accessing insecure devices)
						"/dev:/dev:ro"
					];
					extraOptions = [
						"--restart=unless-stopped"
						# override nixos default
						"--rm=false"
					] ++ deviceRules;
				};
					
				frigate = lib.mkIf containerConfig.frigate.enable {
					image = "ghcr.io/blakeblackshear/frigate:${containerConfig.frigate.version}";
					ports = [
						"8971:8971"
						#"5000:5000" # Internal unauthenticated access. Expose carefully.
						"8554:8554" # RTSP feeds
						"8555:8555/tcp" # WebRTC over tcp
						"8555:8555/udp" # WebRTC over udp
					];
					environment = {
						# TODO: this doesn't matter for now, but definitely change it later
						FRIGATE_RTSP_PASSWORD = "myrtsppassword123";
						# TODO: seems like the container runtime isn't putting libcuda somewhere ld can find it, so we'll just add it here
						# we also need to ensure that we don't break the existing LD_LIBRARY_PATH by overriding it entirely
						LD_LIBRARY_PATH = "/usr/local/lib/python3.9/dist-packages/tensorrt:/usr/local/cuda/lib64:/usr/local/lib/python3.9/dist-packages/nvidia/cufft/lib:/usr/local/nvidia/lib64";
					};
					volumes = [
						"/etc/localtime:/etc/localtime:ro"
						"frigate_config:/config"
						"frigate_media:/media/frigate"
					];
					extraOptions = [
						"--restart=unless-stopped"
						# override nixos default
						"--rm=false"
						"--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=2000000000" # 2GB tmpfs
						"--shm-size=1024m"
						"--device=nvidia.com/gpu=all"
					];
				};

				# mosquitto broker, needs listen 0.0.0.0/anonymous access enabled manually
				# TODO: switch to different container image with this enabled by default
				mosquitto = lib.mkIf containerConfig.mosquitto.enable {
					image = "eclipse-mosquitto:${containerConfig.mosquitto.version}";
					ports = [
						"1883:1883"
					];
					volumes = [
						"mosquitto_config:/mosquitto/config"
					];
					extraOptions = [
						"--restart=unless-stopped"
						# override nixos default
						"--rm=false"
					];
		      	};
		    };
		};
	};
}

