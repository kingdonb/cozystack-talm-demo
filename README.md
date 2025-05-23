# Cozystack Demo

This is a test repo for Cozystack, we are using it in our home lab to prove the
integration of Cozystack and Flux-Operator as a process, and to be familiar
with tear-down stand-up workflow for our Disaster Recovery scenarios.

[Time trials][] are [on YouTube][] (some are linked at the bottom of the page!)

[Time trials]: #time-trials
[on YouTube]: https://youtube.com/@yebyen/streams

## tl;dr

```bash
make mrproper
make init
git stash
make apply
make monitor-nodes-reboot
make bootstrap
make kubeconfig
# kconf rm admin@cozystack
kconf add kubeconfig
make install

# ... (wait a while!)
flux get helmreleases -A

# and see that Cozystack is installed! 🤞
```

That's literally as short as I can make it 😅 you should probably read on if
you want to know how this works at all, in order to better follow my example.

## How to use

To use this repository:

* `make mrproper` - this WILL wipe out talosconfig and kubeconfig in `./`, as well as the "talm chart"
* `make clean-nodes` to wipe out the definition of nodes (my homelab nodes, you'll want your own!)
* `make init` for a default `talm init --preset cozystack` config (the "talm chart")
* `git diff` Nb. any differences eg. in the `cozy-config` - commit any important changes
* `git stash` (we don't want the default network, so we'll put those changes aside)

* Follow the instructions at [cozystack.io: Configuration - Talm][] eg. `talm template` to generate your own controlplane and/or worker nodes

You'll need to run `template` once for every node that you have. (I have `make template` shortcut)

* `make apply` and wait for both nodes to upgrade themselves, they will reboot, give a minute
* (if you have different nodes, you'll just use `talm apply -f nodes/foo.yaml -i` once for each node)

Now you are ready to bootstrap Kubernetes on Talos, and install Cozystack!

* `talm bootstrap -f nodes/hpworker01.yaml` - this is my one control-plane node, bootstrap once
* `make kubeconfig` or `talm kubeconfig kubeconfig -f nodes/hpworker01.yaml` - get the admin@cozystack Kubeconfig

Now follow Get Started guide starting from the [Install Cozystack][] section, to continue the installation.

(Congratulations, you just set up Talos Linux, btw!)

[cozystack.io: Configuration - Talm]: https://cozystack.io/docs/talos/configuration/talm/
[Install Cozystack]: https://cozystack.io/docs/get-started/#install-cozystack

### Time Trials

* [youtu.be/q43l_YerEy8][] - immediately before this README was written
* [youtu.be/bIgAeSfAEys][] - "Scaffolded speed-run" - recorded after the Makefile got `monitor-nodes-reboot`
* [youtu.be/S9fCdGaVAxU][] - "Test Cozystack @ 60c608c"
* [youtu.be/D6qR_jCoPMw][] - "Build, Test Cozystack 0.9-pre"
* [youtu.be/drUrHKAY2dk][] - "Cozystack 0.10"
* [youtu.be/8uutRKJo19k][] - First Speed Run of 2025
* [youtu.be/GBgUfvexnJI][] - What is Moonlander? Birthday speed-run in April 2025

[youtu.be/q43l_YerEy8]: https://youtube.com/watch?v=q43l_YerEy8
[youtu.be/bIgAeSfAEys]: https://youtube.com/watch?v=bIgAeSfAEys
[youtu.be/S9fCdGaVAxU]: https://youtu.be/S9fCdGaVAxU?t=1249
[youtu.be/D6qR_jCoPMw]: https://youtube.com/watch?v=D6qR_jCoPMw
[youtu.be/drUrHKAY2dk]: https://youtube.com/watch?v=drUrHKAY2dk
[youtu.be/8uutRKJo19k]: https://youtube.com/watch?v=8uutRKJo19k
[youtu.be/GBgUfvexnJI]: https://youtube.com/watch?v=GBgUfvexnJI
