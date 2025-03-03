{ config, lib, pkgs, ... }: {
	config = {
	  # Power management - don't sleep when lid is closed
	  services.logind = {
	    lidSwitch = "ignore";
	    lidSwitchDocked = "ignore";
	    extraConfig = ''
	      HandlePowerKey=ignore
	      HandleSuspendKey=ignore
	      HandleHibernateKey=ignore
	    '';
	  };

	  powerManagement = {
	    enable = false;
	    powertop.enable = false;
	  };

	  # Screen blanking
	  services.xserver.serverFlagsSection = ''
	    Option "BlankTime" "15"
	    Option "StandbyTime" "0"
	    Option "SuspendTime" "0"
	    Option "OffTime" "0"
	  '';
	};
}