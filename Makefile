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

clean: clean-kubeconfig clean-talosconfig clean-secrets

mrproper: clean clean-template

clean-kubeconfig:
	rm kubeconfig

clean-talosconfig:
	rm talosconfig

clean-secrets:
	rm secrets.yaml

clean-template:
	rm -rf charts Chart.yaml values.yaml templates

clean-nodes:
	rm -r nodes

nuke-all-nodes:
	@echo "Be sure you know what you are doing!!"
	@echo "====================================="
	@echo "talosctl reset -n 10.17.13.207 -e 10.17.13.207 \n\
		--wipe-mode all --user-disks-to-wipe /dev/sdb,/dev/sdc \n\
		--graceful=false; talosctl reset -n 10.17.13.92 -e 10.17.13.92 \n\
		--wipe-mode all --user-disks-to-wipe /dev/sda --graceful=false"
	@echo "====================================="
	@echo "Don't say you weren't warned! Danger!"
