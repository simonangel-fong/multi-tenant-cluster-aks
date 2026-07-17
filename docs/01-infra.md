

```sh
terraform -chdir=infra init -backend-config=backend.hcl 
terraform -chdir=infra fmt && terraform -chdir=infra validate

terraform -chdir=infra plan -var-file=dev.tfvars

terraform -chdir=infra apply -auto-approve -var-file=dev.tfvars

az aks get-credentials --resource-group mtc-aks-dev-rg --name mtc-aks-dev --overwrite-existing -f ~/.kube/config
kubectl get nodes
```