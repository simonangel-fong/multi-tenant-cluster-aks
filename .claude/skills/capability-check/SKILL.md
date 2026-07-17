---
name: capability-check
description: Use to verify a platform capability (compute, storage, network, security) meets its Phase acceptance criteria from PLAN.md, or to smoke-test the cluster after changes. Triggers on requests like "check if the compute capability works", "verify phase 5 is done", "smoke test the cluster".
---

# Capability acceptance checks

Reference: `PLAN.md` §4 (Implementation Phases) has the acceptance criterion per phase. Run the matching check(s) below and report pass/fail with the actual command output — don't assume success.

## Compute (Phase 3)

```sh
kubectl get nodepool,aksnodeclass -A
kubectl run test-db --image=nginx --overrides='{"spec":{"nodeSelector":{"workload-class":"database"}}}' --restart=Never
kubectl get pod test-db -o wide --watch  # expect a new database-class node within ~1-2 min
kubectl delete pod test-db
```

## Storage (Phase 4)

```sh
kubectl get storageclass
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: capability-check-pvc}
spec: {accessModes: [ReadWriteOnce], resources: {requests: {storage: 1Gi}}, storageClassName: <default-class-name>}
EOF
kubectl get pvc capability-check-pvc  # expect Bound after a consuming pod schedules
kubectl delete pvc capability-check-pvc
```

## Network (Phase 5)

```sh
curl -sSI https://team-a.arguswatcher.net | head -5   # expect HTTP/2 200 and valid cert
kubectl get gateway,httproute -A
```

## Security (Phase 6)

```sh
kubectl get externalsecret -A   # expect SecretSynced=True on each
kubectl get clusterpolicy       # Kyverno policies, expect enforce (not audit) on production rules
kubectl get ns -L istio.io/dataplane-mode   # tenant namespaces should show "ambient"
```

## Reporting

For each capability checked, state pass/fail per acceptance criterion, the exact command run, and the relevant output. If something fails, don't fix it silently — report it and suggest which subagent (`tf-reviewer`, `security-reviewer`, `gitops-validator`) is best suited to investigate.
