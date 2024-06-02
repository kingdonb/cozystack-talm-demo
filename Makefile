all: none

none:
	echo "try 'make tailscale'"

tailscale:
	talosctl patch mc -p @configs/tailscale-config.yaml -n 10.17.13.207 -e 10.17.13.92
	talosctl patch mc -p @configs/tailscale-config.yaml -n 10.17.13.92 -e 10.17.13.92
