# NixOS Kiosk Flake

Use NixOS to provision a machine with Home Assistant and Frigate NVR, complete with a local graphical interface.

## Why?

Good question. I wanted to learn NixOS in depth, and this project has been a great learning exercise.

My goal was to take a Lenovo P53 laptop and use it as a "security system in a box" that could be transported around and set up without needing another machine to do the configuration (as would be normally necessary with something like a minipc or embedded device).

This means that the laptop will:
- Act as a wifi hotspot for wifi security devices (ip cams, thermostats, cheap home automation gear with local apis, etc)
- Run Frigate as a NVR for CCTV functionality
- Act as a Zigbee / Z-Wave coordinator for home automation support
- Run Home Assistant for integrating all above functions
- Present the Home Assistant dashboard on the built in display in kiosk mode (no browser toolbar, no window controls, etc)

