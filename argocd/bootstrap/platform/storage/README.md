# storage

Phase 4 (see `PLAN.md` §4): two Azure Disk CSI (`disk.csi.azure.com`) `StorageClass` objects, both `PremiumV2_LRS`, `volumeBindingMode: WaitForFirstConsumer` (required — PremiumV2 disks are zonal, so binding must wait until the consuming pod is scheduled and its node's zone is known), `allowVolumeExpansion: true`.

- `managed-premium-v2` — default class, baseline PremiumV2 performance (scales with disk size).
- `managed-premium-v2-iops` — adds explicit `DiskIOPSReadWrite`/`DiskMBpsReadWrite` parameters for provisioned performance above the size-based baseline.

Neither is marked `storageclass.kubernetes.io/is-default-class` — AKS already ships its own default StorageClass, and tenants are expected to reference `storageClassName` explicitly (same explicit-contract pattern as the `workload-class` nodeSelector in `compute/`), avoiding ambiguity from two competing cluster-wide defaults.

**Known caveat**: PremiumV2 disks can only attach to VM sizes with PremiumV2 support, and require the disk and node to be in the same availability zone. Neither the system node pool nor NAP's `NodePool`/`AKSNodeClass` objects in this repo currently pin `zones` — if that becomes a problem in practice, revisit alongside the SKU-availability constraints already noted in `PLAN.md` §7.
