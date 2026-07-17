# platform

One Application per platform capability, added in this sync-wave order via `argocd.argoproj.io/sync-wave` annotations (see `CLAUDE.md`):

CRDs/Gateway API → Istio → cert-manager/ESO/Kyverno → external-dns → NodePools/StorageClasses

`compute/` (Phase 3, sync-wave 4) is the first capability to land — the earlier waves are still empty until Phases 4-6 add Istio, cert-manager/ESO/Kyverno, and external-dns. Wave numbers only affect ordering *among what's actually present*, so `compute` syncing alone right now is expected, not a gap.
