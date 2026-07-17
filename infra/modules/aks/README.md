# aks

Provisions the AKS cluster itself: Azure CNI Overlay with the Cilium dataplane, a Standard Load Balancer, egress via the NAT Gateway attached to the network module's subnet (`outbound_type = "userAssignedNATGateway"`), OIDC issuer + Workload Identity enabled, and Node Auto Provisioning (`node_provisioning_profile { mode = "Auto" }`, GA'd managed Karpenter) for tenant capacity. The `default_node_pool` is a small, tainted (`only_critical_addons_enabled`) system pool for cluster add-ons only — tenant workloads always land on NAP-provisioned nodes.

**Inputs**: `name_prefix`, `location`, `resource_group_name`, `subnet_id` (both from the `network` module output), `kubernetes_version` (optional), `sku_tier` (default `Free`), `system_node_vm_size`, `system_node_count`, `tags`.

**Outputs**: `cluster_name`, `cluster_id`, `oidc_issuer_url` (consumed by the `identity` module for federated credentials), `node_resource_group`, `kube_config` (sensitive; consumed by the root `helm` provider to bootstrap ArgoCD — not meant for human use, use `az aks get-credentials` instead).
