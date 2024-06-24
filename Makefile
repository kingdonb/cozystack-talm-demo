all: none

none:
	echo "try 'make tailscale'"

install:
	kubectl create ns cozy-system
	kubectl apply -f configs/cozystack-config.yaml
	# remote:# kubectl apply -f https://github.com/aenix-io/cozystack/raw/v0.7.0/manifests/cozystack-installer.yaml
	# local:# kubectl apply -f cozystack-installer.yaml

tailscale:
	# talosctl patch mc -p @configs/tailscale-config.yaml -n 10.17.13.207 -e 10.17.13.92
	talosctl patch mc -p @configs/tailscale-config.yaml -n 10.17.13.92 -e 10.17.13.92

storage:
	kubectl create -f configs/storage/

metallb:
	kubectl create -f configs/metallb-config.yaml

init:
	talm init --preset cozystack

template:
	mkdir -p nodes
	talm template -e 10.17.13.92 -n 10.17.13.92 -t templates/controlplane.yaml -i > nodes/hpworker01.yaml
	talm template -e 10.17.13.92 -n 10.17.13.207 -t templates/worker.yaml -i > nodes/moo.yaml

apply: apply-moo apply-hpworker01

apply-moo:
	talm apply -f nodes/moo.yaml -i
apply-hpworker01:
	talm apply -f nodes/hpworker01.yaml -i

bootstrap:
	talm bootstrap -f nodes/hpworker01.yaml

dashboard:
	talm dashboard -f nodes/hpworker01.yaml -f nodes/moo.yaml

kubeconfig:
	talm kubeconfig kubeconfig -f nodes/hpworker01.yaml

clean: clean-kubeconfig clean-talosconfig clean-secrets

mrproper: clean clean-template

clean-kubeconfig:
	rm -f kubeconfig

clean-talosconfig:
	rm -f talosconfig

clean-secrets:
	rm secrets.yaml

clean-template:
	rm -rf charts Chart.yaml values.yaml templates

clean-nodes:
	rm -r nodes

nuke-all-nodes:
	@echo "Be sure you know what you are doing!!"
	@echo "====================================="
	@echo "talm reset -f nodes/moo.yaml --reboot \\ \n\
		--wipe-mode all --user-disks-to-wipe /dev/sdb,/dev/sdc \\ \n\
		--graceful=false; talm reset -f nodes/hpworker01.yaml --reboot \\ \n\
		--wipe-mode all --user-disks-to-wipe /dev/sda --graceful=false"
	@echo "====================================="
	@echo "Don't say you weren't warned! Danger!"

nuke-only-storage:
	@echo "Be sure you know what you are doing!!"
	@echo "====================================="
	@echo "talm reset -f nodes/moo.yaml --reboot \\ \n\
		--wipe-mode user-disks --user-disks-to-wipe /dev/sdb,/dev/sdc \\ \n\
		--graceful=false; talm reset -f nodes/hpworker01.yaml --reboot \\ \n\
		--wipe-mode user-disks --user-disks-to-wipe /dev/sda --graceful=false"
	@echo "====================================="
	@echo "Don't say you weren't warned! Danger!"
