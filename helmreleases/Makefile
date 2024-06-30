backup:
	kubectl get --all-namespaces helmreleases.helm.toolkit.fluxcd.io -oyaml | \
		yq '.items.[] | split_doc' | \
		kubectl slice --output-dir . \
		&& \
		for i in helmrelease-*.yaml; do \
			kubectl neat -f $$i > $$i.neat && mv $$i.neat $$i ;\
		done

clean:
	rm helmrelease-*.yaml
