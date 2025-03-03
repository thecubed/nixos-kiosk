{ config, lib, pkgs, ... }: {
	config = {
	  # System packages
	  environment.systemPackages = with pkgs; [
	    firefox
	    git    # Needed for flake updates
	    vim    # For local editing if needed
	  ];
	};
}