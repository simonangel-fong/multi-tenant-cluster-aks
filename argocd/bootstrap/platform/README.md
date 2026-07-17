# platform

Populated in Phases 3-6 (see `PLAN.md` §4) with one Application per platform capability, added in this sync-wave order via `argocd.argoproj.io/sync-wave` annotations (see `CLAUDE.md`):

CRDs/Gateway API → Istio → cert-manager/ESO/Kyverno → external-dns → NodePools/StorageClasses

Empty for now (Phase 2 only proves the GitOps bootstrap mechanism itself) — `kustomization.yaml`'s empty `resources: []` keeps this directory buildable and git-tracked until the first capability lands.
