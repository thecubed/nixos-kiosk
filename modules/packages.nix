{ config, lib, pkgs, ... }: {
	config = {
		nixpkgs.config.allowUnfree = true;
		
	  # System packages
	  environment.systemPackages = with pkgs; [
	    firefox
	    git    # Needed for flake updates
	    vim    # For local editing if needed
			iw     # for wifi debugging
	  ];
	};
}