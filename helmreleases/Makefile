none:
	@echo "try: make all (reset, backup, sort)"
all: reset backup sort

backup:
	kubectl get --all-namespaces helmreleases.helm.toolkit.fluxcd.io -oyaml | \
		yq '.items.[] | split_doc' | \
		kubectl slice --output-dir . \
		&& \
		for i in helmrelease-*.yaml; do \
			kubectl neat -f $$i > $$i.neat && mv $$i.neat $$i ;\
		done

TENANT_LIST := tenant-test tenant-root
reset:
	rm -f helmrelease-*.yaml
	@bash -c ' \
		TENANTS="system $(TENANT_LIST)"; \
		for tenant in $$TENANTS; do \
			rm -f $$tenant/helmrelease-*.yaml; rmdir $$tenant; \
		done; exit 0 \
	'

sort:
	@echo "Sorting $(TENANT_LIST) into directories"
	@bash -c ' \
		TENANTS="$(TENANT_LIST)"; \
		for tenant in $$TENANTS ; do \
			mkdir -p $$tenant/ ; \
			mv -i $$(egrep -ir $$tenant helmrelease-* | awk -F: "{print \$$1}" | sort -u) $$tenant/ ; \
		done ; \
		mkdir -p system/ ; \
		mv helmrelease-* system/ \
	'
