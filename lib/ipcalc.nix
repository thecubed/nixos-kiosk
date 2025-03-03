# Nix module for calculating DHCP ranges from CIDR notation
# special thanks to claude 3.7 for this helpful script!

{ lib, ... }:

let
  # IP address conversion utilities
  ipUtils = {
    # Convert IP address string to a list of integers
    ipToInts = ip: map (x: lib.toInt x) (lib.splitString "." ip);
    
    # Convert IP address string to a 32-bit integer
    ipToInt = ip:
      let
        octets = ipUtils.ipToInts ip;
        a = builtins.elemAt octets 0;
        b = builtins.elemAt octets 1;
        c = builtins.elemAt octets 2;
        d = builtins.elemAt octets 3;
      in
        (a * 16777216) + (b * 65536) + (c * 256) + d;
    
    # Convert 32-bit integer to IP address string
    intToIp = int:
      let
        a = builtins.div int 16777216;
        b = builtins.div (int - (a * 16777216)) 65536;
        c = builtins.div (int - (a * 16777216) - (b * 65536)) 256;
        d = int - (a * 16777216) - (b * 65536) - (c * 256);
      in
        "${toString a}.${toString b}.${toString c}.${toString d}";
  };

  # Parse CIDR notation "192.168.1.1/24" into {ip, prefix}
  parseCidr = cidr:
    let
      parts = lib.splitString "/" cidr;
      ip = builtins.elemAt parts 0;
      prefix = lib.toInt (builtins.elemAt parts 1);
    in
      { inherit ip prefix; };
  
  # Calculate DHCP range from CIDR with reserved IPs
  # Returns information for dnsmasq configuration
  calculateDhcpRange = { cidr, reservedIps ? 0 }:
    let
      parsed = parseCidr cidr;
      ip = parsed.ip;
      prefix = parsed.prefix;
      ipInt = ipUtils.ipToInt ip;
      
      # Calculate number of hosts (2^hostBits)
      hostBits = 32 - prefix;
      hostCount = 
        if hostBits == 0 
        then 1  # Handle /32 case
        else lib.foldl (a: b: a * 2) 1 (lib.range 1 hostBits);
      
      # Network address: floor down to multiple of hostCount
      networkInt = ipInt - lib.mod ipInt hostCount;
      firstIp = ipUtils.intToIp (networkInt + 1);
      
      # Calculate the start of the DHCP range (first IP + offset)
      startRangeInt = networkInt + reservedIps;
      startRange = 
        if startRangeInt >= (networkInt + hostCount)
        then throw "Reserved IPs exceed the available host count"
        else ipUtils.intToIp startRangeInt;
      
      # Broadcast address: add hostCount-1 to network address
      broadcastInt = networkInt + hostCount - 1;
      lastIp = ipUtils.intToIp broadcastInt;
      
      # Check if we have enough hosts in the network
      _ = 
        if reservedIps >= hostCount 
        then throw "Reserved IPs (${toString reservedIps}) must be less than the available host count (${toString hostCount})"
        else null;
      
      # Calculate subnet mask
      subnetMask = ipUtils.intToIp ((builtins.pow 2 prefix - 1) * builtins.pow 2 (32 - prefix));
      
    in
      { 
        first = firstIp;        # First IP (router)
        start = startRange;     # First usable IP for DHCP
        end = lastIp;           # Last usable IP
        subnet = subnetMask;    # Subnet mask
        prefixLength = prefix;  # CIDR prefix length
        totalHosts = hostCount; # Total number of addresses in network
        availableHosts = hostCount - reservedIps - 1; # Available for DHCP allocation
      };

in
{
  calculateDhcpRange = calculateDhcpRange;
}