

```sh
k port-forward svc/argocd-server 8080:80 -n argocd

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

## Capabilities

### Compute

```sh
kubectl get nodepool,aksnodeclass -A
# NAME                                 NODECLASS      NODES   READY   AGE
# nodepool.karpenter.sh/database       database       0       True    4m26s
# nodepool.karpenter.sh/default        default        0       True    121m
# nodepool.karpenter.sh/general        general        0       True    4m26s
# nodepool.karpenter.sh/gpu            gpu            0       True    4m26s
# nodepool.karpenter.sh/system-surge   system-surge   0       True    121m

# NAME                                            READY   AGE
# aksnodeclass.karpenter.azure.com/database       True    4m26s
# aksnodeclass.karpenter.azure.com/default        True    121m
# aksnodeclass.karpenter.azure.com/general        True    4m26s
# aksnodeclass.karpenter.azure.com/gpu            True    4m26s
# aksnodeclass.karpenter.azure.com/system-surge   True    121m

kubectl get nodes -L workload-class
# NAME                             STATUS   ROLES    AGE    VERSION   WORKLOAD-CLASS
# aks-system-30112946-vmss000000   Ready    <none>   124m   v1.35.6
# aks-system-30112946-vmss000001   Ready    <none>   124m   v1.35.6

# test
kubectl run test-db --image=nginx --restart=Never --overrides='{
  "spec": {
    "nodeSelector": {"workload-class": "database"},
    "tolerations": [
      {"key": "workload-class", "operator": "Equal", "value": "database", "effect": "NoSchedule"}
    ]
  }
}'
# pod/test-db created

kubectl get pod test-db -o wide --watch
# NAME      READY   STATUS    RESTARTS   AGE   IP       NODE     NOMINATED NODE   READINESS GATES
# test-db   0/1     Pending   0          50s   <none>   <none>   <none>           <none>


kubectl get nodes -L workload-class
kubectl describe node <new-node-name> | grep -E "Taints|Labels|Instance"
kubectl get nodeclaims.karpenter.sh
```
