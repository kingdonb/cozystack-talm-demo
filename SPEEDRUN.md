# Narrated Cozystack Speed Run

Here are all the things that go in a complete Cozystack speed-run

First - prepare the area (there should be machines running, we’re going to tear down and recreate a production environment)

This is in a way a dramatized reproduction of the apocryphal GitOps genesis story from Weaveworks - so the story goes, someone accidentally deleted a production environment and took down the entire product! But we used this method for deploying (now we call it “GitOps”) so we were able to bring everything back in like, 45 minutes.

In this instance, we’ve been practicing the destroy/recreate workflow and vetting our instance hardware, and figuring out pull-through caches and all the things that make it fast enough to put in a recorded demo without need for speeding up or post-processing!

So First: destroy your production cluster. We’ve got our clone of: https://github.com/kingdonb/cozystack-talm-demo and we can run `make nuke-all-nodes-fast` to print an incantation that we can copy-paste into the terminal to do this really fast. If you haven’t got a production environment yet, then you can skip this step.

We have 3 machines on a special DHCP network set to netboot a Cozystack-branded Talos Linux installer image from Matchbox server, and they are now in maintenance mode, with clean wiped disks, fully booted.

Next, follow the steps in the README beginning with `make mrproper` if necessary

In your clone, `head -30 README.md` for the tl;dr which you can read and understand later.

There is a configmap applied by `make install` which the Cozystack installer can turn into a running Cozystack system. This is our Kubernetes-on-bare-metal bootstrap process.

The artifacts of this process are saved in these locations:
* https://github.com/kingdon-ci/tenants
* and https://github.com/kingdonb/cozystack-talm-demo/tree/main/helmreleases
* and https://github.com/kingdon-ci/cozy-fleet

We’ll follow the Cozystack install guide, setting up Linstor+DRBD storage, MetalLB for LoadBalancers in ARP mode, then optionally OIDC - for the speed-run, we can skip OIDC - skip Monitoring - enable Ingress, and enable Etcd so we can host Kubernetes clusters in our environment. We can take some short-cuts, like for example our storage configuration “replicated” with just 1 replica. And etcd in tenant-root with one replica.

Do not set up isolated network in either tenant, this is also in contrast to the instructions. We need our tenant `tenant-test` to be able to access the redis instances that are hosted in the `tenant-root`. They are both expected to be fully open to the 12-net and 13-net local network as well as the in-cluster Pod network(s).

Stand up two Redis instances, test-redis and live-redis, which are part of the production. They don’t have any data and are not publicly accessible, but they are both open for read/write by any unauthenticated clients.

The order of these steps is important, because the above and below instructions will create 4 load balancers total - and they need to come up in order, or they will not match the DNS that has been pre-created for them.

Stand up a second tenant, `tenant-test` and enable a separate ingress for it - then stand up two Cluster-API clusters in it - “cluster” and “harvey” which are each already defined in a stored `HelmRelease`, and have their own GitOps config. The processes in `tenant-test` will all share a single Ingress IP address. They define hostnames and some wildcards in their `kubernetes-cluster` definition, this is another part of Cozystack.

On `cluster` is our first production workload. This “test” cluster serves a production workload for a live website. It’s not load-bearing, the impact is actually quite minimal, but there is some pain in the form of errors that a user might see while it’s down. So this service is monitored in turn by Uptime Kuma.

This is the water monitor service hosted at https://water.teamhephy.info/data - this utilizes redis-live and this URL will be down until the `cluster` is ready to serve traffic. The router NAT rules are configured to forward requests, so when Redis is live, the `tenant-test` ingress is live, `cluster`, GitOps are live, the service should be responsive and the status monitoring should reflect that it is alive.

On `harvey` is our development environment, and it stands up a second Cluster-API provider. This is a VCluster CAPI provider. It can create additional control planes and they can reuse the services provided on the parent cluster, so they can run isolated K8s or K3s control planes and will have minimal definitions.

Some services run on `harvey` directly - the GitOps will fail until the `water` namespace is created manually.

A `moo` cluster is (re-)created, via GitOps. In the future, this will also serve Dex which all the VClusters can consume to enable admin + other users via RBAC and enable an authn/authz source such as GitHub groups.

Cluster-API creates the cluster, then Crossplane installs Wordpress on the `moo` cluster, which signals that we are almost finished. Other vclusters may be created in parallel. But we will race to wait for this one.

The `ob-mirror` service has a Beeminder secret which needs to be loaded on the cluster so it can run. You will deploy this service by hand, and see it become ready on the `moo` VCluster in order to “ring the bell.” You will have to bless `ob-mirror` with a namespace, and a secret that gets applied by hand from the checked-out `ob-mirror` repo clone.

At any point after the first cluster is brought online, you can use Headlamp to monitor the progress and watch for any errors. Turn the “Warnings only” Events toggle on and off to see even more progress indicators. It should not need any more help to bring things back than what is described here in these notes.

Ringing the bell will “stop the timer” in post-production. We don’t really have post-production, but we could super-impose a timer over a recording of the speed-run one day when it’s a new record, or something.

When the water-monitor, wordpress, and ob-mirror services are all alive, the speed run is finished!

Check also https://podinfo.local on the local network to confirm that load balancer is hosting services for at least all 3 of the clusters under `tenant-test` - cluster, harvey, and moo. There is no dependency order here, so you may have to force retry the podinfo helmrelease on `harvey` - in order to get the surprise and delight!

Verify the downtime against the dashboard at https://status.nerdland.info/dashboard/29 to confirm public services are again running as normal!
