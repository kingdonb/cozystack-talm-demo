all: none

# Define the list of node IPs or hostnames (space-separated)
# NODE_LIST := hpworker01.turkey.local dellwork01.turkey.local dellwork02.turkey.local hpworker03.turkey.local hpworker05.turkey.local hpworker04.turkey.local
# STORAGE_LIST := hpworker01.turkey.local dellwork01.turkey.local dellwork02.turkey.local hpworker03.turkey.local
NODE_LIST:= dellwork01.turkey.local dellwork02.turkey.local hpworker03.turkey.local hpworker06.turkey.local hpworker05.turkey.local
# STSLESS_LIST := hpworker04.turkey.local
STSLESS_LIST := hpworker05.turkey.local hpworker06.turkey.local

none:
	echo "try 'make tailscale'"

help:
	head -30 README.md

install:
	kubectl create ns cozy-system
	kubectl apply -f configs/cozystack-config.yaml
	# remote:# kubectl apply -f https://github.com/aenix-io/cozystack/raw/v0.18.0/manifests/cozystack-installer.yaml
	# local:# kubectl apply -f cozystack-installer.yaml

tailscale:
	# talosctl patch mc -p @configs/tailscale-config.yaml -n 10.17.13.6 -e 10.17.13.6
	# talosctl patch mc -p @configs/tailscale-config.yaml -n 10.17.13.86 -e 10.17.13.86
	# talosctl patch mc -p @configs/tailscale-config.yaml -n 10.17.13.173 -e 10.17.13.173
	# talosctl patch mc -p @configs/tailscale-config.yaml -n 10.17.13.101 -e 10.17.13.86
	# talosctl patch mc -p @configs/tailscale-config.yaml -n 10.17.13.144 -e 10.17.13.86
	talosctl patch mc -p @configs/tailscale-config.yaml -n 10.17.13.138 -e 10.17.13.86

storage:
	kubectl create -f configs/storage/

metallb:
	kubectl create -f configs/metallb-config.yaml

init:
	talm init --preset cozystack

template:
	mkdir -p nodes
	talm template -e 10.17.13.173 -n 10.17.13.173 -t templates/controlplane.yaml -i > nodes/dellwork01.yaml
	talm template -e 10.17.13.6 -n 10.17.13.6 -t templates/controlplane.yaml -i > nodes/dellwork02.yaml
	talm template -e 10.17.13.86 -n 10.17.13.86 -t templates/controlplane.yaml -i > nodes/hpworker03.yaml
	talm template -e 10.17.13.86 -n 10.17.13.101 -t templates/worker.yaml -i > nodes/hpworker05.yaml
	# talm template -e 10.17.13.86 -n 10.17.13.144 -t templates/worker.yaml -i > nodes/hpworker04.yaml
	# talm template -e 10.17.13.173 -n 10.17.13.73 -t templates/worker.yaml -i > nodes/hpworker01.yaml
	talm template -e 10.17.13.86 -n 10.17.13.138 -t templates/worker.yaml -i > nodes/hpworker06.yaml

patch-nodes:
	@echo "Merging patches into nodes/* : ..."
	@bash -c ' \
		NODES="$(NODE_LIST)"; \
		PATCHES="caching-proxy-patch no-kexec-patch domainname-patch"; \
		for node in $$NODES; do \
			short_name=$$(echo $$node | cut -d. -f1); \
			for patch in $$PATCHES; do \
				echo "nodes/$$short_name.yaml (configs/patches/$$patch.yaml)"; \
				yq -i ea ". as \$$item ireduce ({}; . * \$$item )" nodes/$${short_name}.yaml configs/patches/$${patch}.yaml; \
			done; \
		done \
	'

apply: apply-dellwork01 apply-dellwork02 apply-hpworker03 apply-hpworker04 apply-hpworker05 # apply-moo apply-hpworker01

apply-dellwork01:
	talm apply -f nodes/dellwork01.yaml -i
apply-dellwork02:
	talm apply -f nodes/dellwork02.yaml -i
apply-hpworker03:
	talm apply -f nodes/hpworker03.yaml -i
apply-hpworker06:
	talm apply -f nodes/hpworker06.yaml -i
apply-hpworker05:
	talm apply -f nodes/hpworker05.yaml -i
apply-hpworker04:
	talm apply -f nodes/hpworker04.yaml -i
# apply-moo:
# 	talm apply -f nodes/moo.yaml -i
# apply-hpworker01:
# 	talm apply -f nodes/hpworker01.yaml -i

bootstrap:
	talm bootstrap -f nodes/dellwork01.yaml

dashboard:
	talm dashboard -f nodes/dellwork01.yaml -f nodes/dellwork02.yaml -f nodes/hpworker03.yaml -f nodes/hpworker06.yaml -f nodes/hpworker05.yaml # -f nodes/hpworker04.yaml # -f nodes/hpworker01.yaml # -f nodes/moo.yaml

kubeconfig:
	talm kubeconfig kubeconfig -f nodes/dellwork01.yaml

clean: clean-kubeconfig clean-talosconfig clean-secrets

mrproper: clean clean-template

clean-kubeconfig:
	rm -f kubeconfig
	rm -f *-kubeconfig.yaml

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
	@echo "\\ \n\
	talm reset -f nodes/hpworker03.yaml --reboot \\ \n\
	  --wipe-mode all --user-disks-to-wipe /dev/sda --graceful=false; \\ \n\
	talm reset -f nodes/hpworker05.yaml --reboot \\ \n\
	  --wipe-mode all --graceful=false; \\ \n\
	talm reset -f nodes/dellwork02.yaml --reboot \\ \n\
	  --wipe-mode all --user-disks-to-wipe /dev/sdb --graceful=false; \\ \n\
	talm reset -f nodes/hpworker04.yaml --reboot \\ \n\
	  --wipe-mode all --graceful=false; \\ \n\
	talm reset -f nodes/dellwork01.yaml --reboot \\ \n\
	  --wipe-mode all --user-disks-to-wipe /dev/sda --graceful=false; \\ \n\
	talm reset -f nodes/hpworker01.yaml --reboot \\ \n\
	  --wipe-mode all --user-disks-to-wipe /dev/sda --graceful=false"
	@echo "====================================="
	@echo "Don't say you weren't warned! Danger!"

nuke-all-nodes-fast:
	@echo "Be sure you know what you are doing!!"
	@echo "====================================="
	@echo "\\ \n\
	talm reset -f nodes/hpworker03.yaml --reboot \\ \n\
	  --wipe-mode all --user-disks-to-wipe /dev/sda --graceful=false& \\ \n\
	talm reset -f nodes/hpworker05.yaml --reboot \\ \n\
	  --wipe-mode all --graceful=false& \\ \n\
	talm reset -f nodes/dellwork02.yaml --reboot \\ \n\
	  --wipe-mode all --user-disks-to-wipe /dev/sdb --graceful=false& \\ \n\
	talm reset -f nodes/hpworker04.yaml --reboot \\ \n\
	  --wipe-mode all --graceful=false& \\ \n\
	talm reset -f nodes/dellwork01.yaml --reboot \\ \n\
	  --wipe-mode all --user-disks-to-wipe /dev/sda --graceful=false& \\ \n\
	talm reset -f nodes/hpworker01.yaml --reboot \\ \n\
	  --wipe-mode all --user-disks-to-wipe /dev/sda --graceful=false"
	@echo "====================================="
	@echo "Don't say you weren't warned! Danger!"

nuke-only-storage:
	@echo "Be sure you know what you are doing!!"
	@echo "====================================="
	@echo "\\ \n\
	talm reset -f nodes/hpworker03.yaml --reboot \\ \n\
	  --wipe-mode user-disks --user-disks-to-wipe /dev/sda --graceful=false; \\ \n\
	talm reset -f nodes/dellwork02.yaml --reboot \\ \n\
	  --wipe-mode user-disks --user-disks-to-wipe /dev/sdb --graceful=false; \\ \n\
	talm reset -f nodes/dellwork01.yaml --reboot \\ \n\
	  --wipe-mode user-disks --user-disks-to-wipe /dev/sda --graceful=false; \\ \n\
	talm reset -f nodes/hpworker01.yaml --reboot \\ \n\
	  --wipe-mode user-disks --user-disks-to-wipe /dev/sda --graceful=false"
	@echo "====================================="
	@echo "Don't say you weren't warned! Danger!"

nuke-stateless:
	@echo "Be sure you know what you are doing!!"
	@echo "====================================="
	@echo "\\ \n\
	talm reset -f nodes/hpworker06.yaml --reboot \\ \n\
	  --wipe-mode all --graceful=false; \\ \n\
	talm reset -f nodes/hpworker05.yaml --reboot \\ \n\
	  --wipe-mode all --graceful=false; \\ \n\
	talm reset -f nodes/hpworker04.yaml --reboot \\ \n\
	  --wipe-mode all --graceful=false"
	@echo "====================================="
	@echo "Don't say you weren't warned! Danger!"


## Credit to the below goes to ChatGPT
# Define timeout values
DOWN_TIMEOUT := 900  # Time in seconds to wait for all nodes to go down

# Path to mock scripts
MOCK_PING := ./hack/mock_ping.sh
MOCK_REBOOT := ./hack/mock_reboot.sh

.PHONY: monitor-nodes-reboot force-reboot-all-nodes

monitor-nodes-reboot:
	@echo "Monitoring node reboot process for nodes: $(NODE_LIST)..."
	@bash -c ' \
		NODES="$(NODE_LIST)"; \
		DOWN_TIMEOUT=$(DOWN_TIMEOUT); \
		declare -A STATUS; \
		declare -A FAILURE_COUNT; \
		for node in $$NODES; do \
			STATUS[$$node]="up"; \
			FAILURE_COUNT[$$node]=0; \
		done; \
		function monitor_nodes { \
			for i in `seq 1 $$DOWN_TIMEOUT`; do \
				for node in $$NODES; do \
					short_name=$$(echo $$node | cut -d. -f1); \
					if ping -t 1 -c 1 $$node &> /dev/null; then \
						FAILURE_COUNT[$$node]=0; \
						if [[ $${STATUS[$$node]} == "down" ]]; then \
							STATUS[$$node]="down-up"; \
							echo "Node $$short_name is back up."; \
						fi; \
					else \
						FAILURE_COUNT[$$node]=$$((FAILURE_COUNT[$$node] + 1)); \
						if [[ $${FAILURE_COUNT[$$node]} -ge 3 ]]; then \
							if [[ $${STATUS[$$node]} == "up" ]]; then \
								STATUS[$$node]="down"; \
								echo "Node $$short_name is down."; \
							fi; \
						fi; \
					fi; \
				done; \
				sleep 1; \
				local all_done=true; \
				for node in $$NODES; do \
					if [[ $${STATUS[$$node]} != "down-up" ]]; then \
						all_done=false; \
						break; \
					fi; \
				done; \
				if $$all_done; then \
					echo "All nodes have rebooted successfully."; \
					return 0; \
				fi; \
			done; \
			echo "Error: Timeout waiting for all nodes to reboot."; \
			return 1; \
		}; \
		monitor_nodes \
	'

force-reboot-all-nodes:
	@echo "Forcing reboot for all nodes..."
	@bash -c ' \
		NODES="$(NODE_LIST)"; \
		for node in $$NODES; do \
			short_name=$$(echo $$node | cut -d. -f1); \
			echo "Rebooting node: $$short_name"; \
			talm reboot --wait=false -f nodes/$$short_name.yaml; \
		done \
	'
