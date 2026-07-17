# Plan: Multi-tenant Cluster with AKS

> Port of the EKS multi-tenant cluster (see README.md reference) to Azure AKS.
> One cluster, many tenants, GitOps-driven, with out-of-the-box Compute / Storage / Network / Security capabilities.

**AKS · Terraform · ArgoCD · Node Auto Provisioning (Karpenter) · Istio ambient · Gateway API · cert-manager · External Secrets · Kyverno**

---

## 1. EKS → AKS Service Mapping

| Concern            | EKS (reference)                       | AKS (this project)                                        |
| ------------------ | ------------------------------------- | --------------------------------------------------------- |
| Cluster            | EKS                                   | AKS Standard tier                                         |
| Network foundation | VPC + subnets + NAT                   | VNet + subnets + NAT Gateway, Azure CNI (overlay)         |
| Compute scaling    | Karpenter (self-managed)              | **Node Auto Provisioning (NAP)** — managed Karpenter, GA  |
| Workload classes   | Karpenter NodePools: general/database/gpu | NAP `NodePool` + `AKSNodeClass` CRDs, same class labels |
| Storage            | EBS CSI: `gp3`, `gp3-iops`            | Azure Disk CSI: `managed-premium-v2` (default), high-IOPS PremiumV2 class |
| Pod → cloud auth   | EKS Pod Identity                      | **Microsoft Entra Workload Identity** (OIDC federation)   |
| Secrets backend    | AWS Secrets Manager + ESO             | **Azure Key Vault** + External Secrets Operator           |
| L7 ingress         | AWS Load Balancer Controller (ALB)    | Istio ingress gateway → Azure `LoadBalancer` Service (Standard LB). No ALBC equivalent needed |
| Mesh               | Istio ambient (self-managed Helm)     | Istio ambient (self-managed Helm; AKS add-on does NOT support ambient) |
| DNS                | Route53? / Cloudflare + external-dns  | Cloudflare + external-dns (unchanged: `<team>.arguswatcher.net`) |
| TLS                | cert-manager DNS-01 wildcard          | cert-manager DNS-01 via Cloudflare (unchanged)            |
| Policy             | Kyverno                               | Kyverno (unchanged)                                       |
| GitOps             | ArgoCD app-of-apps                    | ArgoCD app-of-apps (unchanged)                            |
| TF state           | S3 backend                            | Same S3 backend (shared multi-cloud bucket, different `key` prefix) — no Azure-native backend |
| CLI auth           | awscli                                | Azure CLI + kubelogin                                     |

Key portability win: everything above the API server (ArgoCD tree, Kyverno policies, tenant JSON onboarding, Istio, ESO manifests) carries over nearly unchanged. Only Terraform and the identity/storage/compute integrations are rewritten.

---

## 2. Target Architecture

- **Terraform** provisions the Azure foundation: resource group, VNet, AKS (NAP enabled, Workload Identity + OIDC issuer enabled), Key Vault, user-assigned managed identities + federated credentials. State lives in the same shared S3 bucket used for other cloud projects (see `infra/backend.hcl.example`) — no Azure storage account bootstrapping needed.
- **ArgoCD** bootstraps everything above the API server via app-of-apps:
  1. Platform capabilities (Istio, gateway, cert-manager, ESO, Kyverno, external-dns, StorageClasses, NAP NodePools)
  2. Per-tenant AppProject + ApplicationSet from `tenants/<team>.json`

Shared responsibility model is identical to the EKS reference: platform owns guardrails, tenants own workloads.

### Capabilities delivered to tenants

| Capability | Tooling                                             | What tenants get                                          |
| ---------- | --------------------------------------------------- | --------------------------------------------------------- |
| Compute    | NAP NodePools by workload class                     | `nodeSelector: workload-class: general|database|gpu`      |
| Storage    | Azure Disk CSI StorageClasses                       | PVCs on default or high-IOPS class                        |
| Network    | Istio ambient + Gateway API + external-dns          | `https://<team>.arguswatcher.net`, TLS, DNS, mTLS         |
| Security   | ESO + Workload Identity + cert-manager + Kyverno    | Secret vending from Key Vault, Azure access, admission control |

---

## 3. Repository Structure

```
multi-tenant-cluster-aks/
├── CLAUDE.md                      # project conventions for Claude Code
├── .claude/
│   ├── skills/                    # custom skills (see §6)
│   ├── agents/                    # subagents (see §6)
│   └── settings.json              # hooks: terraform fmt/validate, kubeconform
├── infra/                         # Terraform (azurerm + azapi if needed)
│   ├── backend.hcl.example        # S3 backend template (shared multi-cloud bucket) — commit this
│   ├── backend.hcl                # real bucket/region — gitignored, copy from .example
│   ├── main.tf / variables.tf / outputs.tf
│   └── modules/
│       ├── network/               # VNet, subnets, NAT GW, NSGs (allow 15008 inter-node for ambient)
│       ├── aks/                   # cluster, NAP, OIDC, workload identity
│       ├── identity/              # UAMIs + federated credentials (ESO, cert-manager, external-dns if using Azure DNS later)
│       └── keyvault/              # Key Vault + RBAC for ESO identity
├── argocd/
│   └── bootstrap/                 # app-of-apps tree
│       ├── platform/              # istio, gateway, cert-manager, eso, kyverno, external-dns, storage, nodepools
│       └── tenants/               # ApplicationSet reading tenants/*.json
├── tenants/
│   └── team-a.json                # {name, sourceRepo, manifestPath} — same contract as EKS
├── demo-app/
│   ├── team-a/                    # stateless nginx (plain manifests)
│   └── team-b/                    # stateful to-do app (Helm)
├── docs/
│   ├── tenant/                    # onboarding, compute, network guides
│   ├── platform/                  # runbooks per capability
│   └── dev/                       # 01-infra, 02-argocd, 03-capabilities
├── app-of-apps.yaml
└── README.md
```

---

## 4. Implementation Phases

### Phase 0 — Bootstrap (repo + Claude Code scaffolding)
- Write `CLAUDE.md`, `.claude/skills/`, `.claude/agents/`, hooks (§6).
- Wire TF remote state to the existing shared S3 bucket: `infra/backend.hcl.example` (committed template) + `infra/backend.hcl` (gitignored, real bucket/region, copied from the example) + `backend "s3" {}` in `infra/versions.tf`. No Azure-side bootstrapping required — the bucket already exists.
- Acceptance: `cp infra/backend.hcl.example infra/backend.hcl` (fill in values) then `terraform -chdir=infra init -backend-config=backend.hcl` succeeds.

### Phase 1 — Terraform foundation
- Modules: network → aks → identity → keyvault.
- AKS config: Azure CNI overlay, Standard LB, OIDC issuer + Workload Identity enabled, NAP enabled (`node_provisioning_profile` in azurerm; fall back to `azapi` if provider version lacks it), system node pool only (tenant capacity comes from NAP).
- NSG rule: allow 15008 between nodes (Istio ambient HBONE).
- Outputs: cluster name, OIDC issuer URL, Key Vault URI, identity client IDs (consumed by ArgoCD manifests via Helm values or ConfigMap).
- Acceptance: `terraform apply` clean; `az aks get-credentials` + `kubectl get nodes` works.

### Phase 2 — GitOps bootstrap
- Install ArgoCD (Helm via TF null-step or one-time `kubectl apply`), then `app-of-apps.yaml` pointing at `argocd/bootstrap/`.
- Sync-wave ordering: CRDs/Gateway API → Istio → cert-manager/ESO/Kyverno → external-dns → NodePools/StorageClasses → tenants.
- Acceptance: ArgoCD UI shows platform tree healthy.

### Phase 3 — Compute capability
- NAP `AKSNodeClass` + `NodePool` per workload class: `general` (D-series), `database` (E-series, taint), `gpu` (N-series, taint) — same labels/taints contract as the EKS repo so tenant manifests port unchanged.
- Acceptance: pod with `workload-class: database` selector triggers a new E-series node in ~1–2 min.
- **Status: config verified, live scale-test blocked by subscription — see §7.** All three `NodePool`/`AKSNodeClass` pairs are correctly configured (validated against AKS's own auto-created defaults, server-side dry-run clean, synced healthy by ArgoCD) and the BYO-VNet RBAC gap that was blocking NAP entirely is fixed. But this Azure subscription can't actually provision the acceptance test on `canadacentral`: D, E, B, and F family VMs are all `NotAvailableForSubscription`, and the one family that is available (`DCSv3`, confidential computing — what the system pool itself uses) still fails via NAP with `NoCompatibleInstanceTypes`, most likely because `AKSNodeClass`'s standard `Ubuntu2404` image isn't confidential-computing-compatible (a Karpenter-side image/capability mismatch, separate from the subscription restriction). No family found so far is both subscription-available and Karpenter-provisionable in this region.

### Phase 4 — Storage capability
- StorageClasses: default (Premium SSD v2 or managed-premium), high-IOPS (PremiumV2 with provisioned IOPS). `volumeBindingMode: WaitForFirstConsumer`, `allowVolumeExpansion: true`.
- Acceptance: PVC binds; stateful pod on database node mounts disk.

### Phase 5 — Network capability
- Istio ambient via Helm (base, istiod, cni, ztunnel), Gateway API CRDs, shared ingress `Gateway` (namespace `istio-ingress`) → Azure Standard LB public IP.
- external-dns (Cloudflare provider) publishes `*.arguswatcher.net` records from HTTPRoutes/Gateway.
- Acceptance: `curl https://echo.arguswatcher.net` returns 200 with valid TLS.

### Phase 6 — Security capability
- cert-manager: ClusterIssuer with Cloudflare DNS-01, wildcard cert `*.arguswatcher.net` on the shared Gateway.
- ESO: `ClusterSecretStore` → Key Vault via Workload Identity; Cloudflare token itself vended from Key Vault (only bootstrap secret is the ESO identity — no static keys in-cluster).
- Kyverno: port EKS policies — enforce nodeSelector/workload-class defaults, deny privileged pods, restrict tenant namespaces, require resource limits.
- Namespaces labeled `istio.io/dataplane-mode: ambient` for mTLS.
- Acceptance: tenant ExternalSecret syncs from Key Vault; policy violations rejected.

### Phase 7 — Tenant onboarding + demos
- ApplicationSet git-file generator over `tenants/*.json` → namespace, AppProject (source repo restricted), Application, quotas/LimitRange, HTTPRoute subdomain.
- Port demo apps: team-a (stateless nginx), team-b (stateful to-do, database class + PVC).
- Acceptance: commit `team-a.json` → live `https://team-a.arguswatcher.net` in ~3 min.

### Phase 8 — Docs + verification
- Rewrite tenant guides + platform runbooks for AKS specifics.
- End-to-end teardown/rebuild test: `terraform destroy` → full re-apply → both demos live.

---

## 5. Terraform Design Notes

- Providers: `azurerm` (pin ≥ 4.x), `azapi` (fallback for NAP if `node_provisioning_profile` unavailable in pinned azurerm), `helm`/`kubectl` only for the ArgoCD bootstrap step.
- State backend: S3 (`backend "s3" {}`), same shared bucket as other cloud projects, keyed under `multi-tenant-aks/<env>/terraform.tfstate`. Locking via `use_lockfile = true` (S3-native, Terraform ≥ 1.10) — no DynamoDB table. Requires Terraform to authenticate to AWS (credentials/profile) in addition to Azure — two separate credential chains, unrelated to each other.
- One environment (`dev`) first; structure variables so envs can be added via tfvars, not copies.
- Workload Identity wiring (per identity): `azurerm_user_assigned_identity` + `azurerm_federated_identity_credential` bound to `system:serviceaccount:<ns>:<sa>` against the cluster OIDC issuer; RBAC role assignment (e.g. Key Vault Secrets User for ESO).
- Terraform stops at the API server: no Helm releases for platform capabilities in TF (ArgoCD owns those) — same boundary as the EKS repo.

---

## 6. Claude Code Scaffolding (Phase 0 detail)

**CLAUDE.md** — project conventions: TF module layout, naming (`mtc-aks-dev-*`), commands (`terraform -chdir=infra ...`), sync-wave rules, tenant JSON contract, "never commit secrets; Key Vault only".

**Skills** (`.claude/skills/`):
- `tenant-onboard` — given team name + repo + path, generate `tenants/<team>.json` and verify ApplicationSet renders (`argocd appset` dry-run / `helm template`).
- `tf-module` — scaffold a new infra module with variables/outputs/README following project conventions.
- `capability-check` — run the acceptance checks in §4 for a given capability (kubectl probes, curl TLS check, PVC bind test).

**Subagents** (`.claude/agents/`):
- `tf-reviewer` — read-only review of Terraform diffs: provider pinning, RBAC least-privilege, no inline secrets, naming.
- `security-reviewer` — reviews Kyverno policies, NSG rules, federated credentials, Key Vault RBAC before merge.
- `gitops-validator` — renders ArgoCD tree (`kustomize build`/`helm template` + kubeconform) to catch manifest errors pre-commit.

**Hooks** (`.claude/settings.json`):
- PostToolUse on `infra/**/*.tf` edits → `terraform fmt` + `terraform validate`.
- PostToolUse on `argocd/**`, `tenants/**` edits → kubeconform / JSON schema check of tenant files.

Suggested Claude Code workflow per phase: plan with the Plan agent → implement → hooks auto-validate → `tf-reviewer`/`security-reviewer` subagent pass → `capability-check` skill for acceptance.

---

## 7. Risks & Open Items

- ~~**NAP in azurerm**: `node_provisioning_profile` support landed via API 2025-05-01; verify pinned provider version, else use `azapi` (known-good pattern).~~ **Resolved in Phase 1**: confirmed via provider schema inspection that `node_provisioning_profile` is natively supported on the pinned `azurerm ~> 4.0` (installed 4.81.0) — no `azapi` fallback needed. NAP also requires Azure CNI Overlay + Cilium dataplane (`network_plugin_mode = "overlay"`, `network_data_plane = "cilium"`), now set in `infra/modules/aks`.
- **Istio ambient on AKS**: supported with self-managed install + Azure CNI; AKS managed add-on excluded (no ambient). Keep NSG port 15008 open inter-node.
- **PremiumV2 disks**: zone/region constraints — confirm availability in the chosen region before making it the high-IOPS class.
- **NAP + custom taints**: verify NAP honors startup taints per NodePool for database/gpu isolation as Karpenter does on EKS.
- **AKS overlay service CIDR**: AKS's default `service_cidr` (`10.0.0.0/16`) collides with any VNet also using `10.0.0.0/16`. `infra/modules/aks` now sets `service_cidr = "172.16.0.0/16"` / `dns_service_ip = "172.16.0.10"` explicitly — keep this in mind if the VNet address space ever changes.
- **Cost**: NAP consolidation should mirror Karpenter behavior; keep system pool minimal (2 × B/D-series).
- **BYO-VNet AKS identity grant**: Azure only auto-grants the cluster's own identity network access for AKS-*managed* VNets — on a bring-your-own VNet (ours), that grant is the deployer's job and was missed in Phase 1, surfacing in Phase 3 as NAP's `AKSNodeClass` objects stuck `SubnetsReady=False` (`AuthorizationFailed` on `subnets/read`). Fixed via `azurerm_role_assignment.subnet_network_contributor` in `infra/modules/aks`, scoped to the subnet only. Built-in `Network Contributor` is Microsoft's documented floor for this scenario but is broader than NAP strictly needs (also grants subnet delete/NSG-association/route-table changes) — and since it's the one shared subnet for every tenant, a compromised control-plane identity could affect all tenants' networking, not just its own. Acceptable for a single dev cluster; before prod, replace with a custom role limited to `Microsoft.Network/virtualNetworks/subnets/read` + `.../subnets/join/action`.
- **Free-tier subscription SKU restrictions block live NAP testing**: confirmed via `az vm list-skus --location canadacentral ... --query restrictions` that D, E, B, and F family VMs are all `NotAvailableForSubscription` on this subscription in `canadacentral` — unrelated to the `Total Regional vCPUs` quota (also low, at 4, and separately confirmed as a contributing factor before this deeper restriction was found). The only subscription-available family, `DCSv3` (confidential computing — what the system pool uses), still fails through NAP with `NoCompatibleInstanceTypes`, most likely because `AKSNodeClass`'s standard `Ubuntu2404` image isn't confidential-computing-compatible. Net effect: no VM family found so far is both subscription-available and Karpenter-provisionable in this region, so Phase 3's live acceptance test (a `workload-class: database` pod triggering a new node) can't be executed here. Fix requires either upgrading off the free tier or testing in a different region/subscription with broader SKU access — not a code or config defect in this repo.

---

## 8. Milestone Checklist

- [x] Phase 0: repo scaffolding + TF backend
- [x] Phase 1: `terraform apply` → cluster reachable
- [x] Phase 2: ArgoCD app-of-apps healthy
- [ ] Phase 3: workload-class node provisioning works — config verified (NodePool/AKSNodeClass correct, ArgoCD-synced, RBAC fixed); live scale-test blocked by subscription SKU restrictions, see §7
- [ ] Phase 4: PVC on both storage classes
- [ ] Phase 5: public URL + TLS via shared gateway
- [ ] Phase 6: ESO secret vending + Kyverno enforcement
- [ ] Phase 7: team-a & team-b demos live
- [ ] Phase 8: docs + destroy/rebuild verified
