# compute

Phase 3 (see `PLAN.md` §4): one `AKSNodeClass` + `NodePool` pair per workload class — `general` (D-series, untainted), `database` (E-series, tainted `workload-class=database:NoSchedule`), `gpu` (N-series, tainted `workload-class=gpu:NoSchedule`, GPU driver managed by AKS). Same `workload-class` label/taint contract as the EKS reference (see `CLAUDE.md`), so tenant manifests port unchanged — a pod requests a class via `nodeSelector: {workload-class: <class>}` plus a matching toleration for `database`/`gpu`.

These are Kubernetes custom resources for AKS's Node Auto Provisioning (managed Karpenter) — the CRDs themselves (`nodepools.karpenter.sh`, `aksnodeclasses.karpenter.azure.com`) are installed by AKS, not this repo, once NAP is enabled on the cluster (`infra/modules/aks`). All three NodePools include the `node.cilium.io/agent-not-ready` startup taint, required because this cluster uses the Cilium dataplane — without it, pods can schedule before Cilium is ready on a new node.

`limits` on each NodePool are a cost/safety cap on total provisioned capacity per class, not a workload sizing guarantee.
