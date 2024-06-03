all: none

none:
	echo "try 'make tailscale'"

install:
	kubectl create ns cozy-system
	kubectl apply -f configs/cozystack-config.yaml
	kubectl apply -f https://github.com/aenix-io/cozystack/raw/v0.7.0/manifests/cozystack-installer.yaml

tailscale:
	# talosctl patch mc -p @configs/tailscale-config.yaml -n 10.17.13.207 -e 10.17.13.92
	talosctl patch mc -p @configs/tailscale-config.yaml -n 10.17.13.92 -e 10.17.13.92

storage:
	kubectl create -f configs/storage/

metallb:
	kubectl create -f configs/metallb-config.yaml

mrproper: clean-kubeconfig clean-talosconfig clean-secrets

clean-kubeconfig:
	rm kubeconfig

clean-talosconfig:
	rm talosconfig

clean-secrets:
	rm secrets.yaml
