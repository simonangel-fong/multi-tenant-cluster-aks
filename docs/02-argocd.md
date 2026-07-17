

```sh
k port-forward svc/argocd-server 8080:80 -n argocd

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```