# network

Provisions the Azure network foundation the rest of the platform builds on: a resource group, a VNet with a single AKS node subnet sized for Azure CNI overlay (pod IPs don't consume subnet space), a Standard NAT Gateway for egress, and an NSG that allows Istio ambient's HBONE tunnel (TCP 15008) between nodes in the subnet — everything else stays default-deny.

**Inputs**: `name_prefix`, `location`, `vnet_address_space` (default `10.0.0.0/16`), `aks_subnet_address_prefixes` (default `10.0.0.0/22`), `tags`.

**Outputs**: `resource_group_name`, `location`, `vnet_id`, `aks_subnet_id` — consumed by the `aks`, `identity`, and `keyvault` modules, which all deploy into this resource group.
