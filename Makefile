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

## Credit to the below goes to ChatGPT
# Define the list of node IPs or hostnames (space-separated)
NODE_LIST := node1_ip node2_ip node3_ip node4_ip

# Define timeout values
DOWN_TIMEOUT := 300  # Time in seconds to wait for all nodes to go down
UP_TIMEOUT := 300    # Time in seconds to wait for all nodes to come back up

.PHONY: monitor-nodes-reboot

monitor-nodes-reboot:
	@echo "Monitoring node reboot process for nodes: $(NODE_LIST)..."
	@bash -c ' \
		NODES="$(NODE_LIST)"; \
		DOWN_TIMEOUT=$(DOWN_TIMEOUT); \
		UP_TIMEOUT=$(UP_TIMEOUT); \
		declare -A STATUS; \
		declare -A FAILURE_COUNT; \
		for node in $$NODES; do \
			STATUS[$$node]="up"; \
			FAILURE_COUNT[$$node]=0; \
		done; \
		function check_reboot_status { \
			local all_done=true; \
			for node in $$NODES; do \
				if [[ $${STATUS[$$node]} != "down-up" ]]; then \
					all_done=false; \
					break; \
				fi; \
			done; \
			$$all_done; \
		}; \
		function monitor_nodes { \
			for i in `seq 1 $$DOWN_TIMEOUT`; do \
				for node in $$NODES; do \
					if ping -c 1 $$node &> /dev/null; then \
						FAILURE_COUNT[$$node]=0; \
						if [[ $${STATUS[$$node]} == "down" ]]; then \
							STATUS[$$node]="down-up"; \
						fi; \
					else \
						FAILURE_COUNT[$$node]=$$((FAILURE_COUNT[$$node] + 1)); \
						if [[ $${FAILURE_COUNT[$$node]} -ge 3 ]]; then \
							if [[ $${STATUS[$$node]} == "up" ]]; then \
								STATUS[$$node]="down"; \
							fi; \
						fi; \
					fi; \
				done; \
				if check_reboot_status; then \
					echo "All nodes have rebooted successfully."; \
					return 0; \
				fi; \
				sleep 1; \
			done; \
			echo "Error: Timeout waiting for all nodes to reboot."; \
			return 1; \
		}; \
		monitor_nodes \
	'
