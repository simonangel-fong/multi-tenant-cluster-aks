---
name: tf-module
description: Use when scaffolding a new Terraform module under infra/modules/, or adding a new resource that doesn't fit an existing module. Triggers on requests like "add a new terraform module for X", "scaffold the identity module".
---

# Terraform module scaffolding

Follow the layout and conventions in root `CLAUDE.md` before scaffolding anything.

## Steps

1. Confirm the module doesn't already exist or overlap with `infra/modules/{network,aks,identity,keyvault}`.
2. Create `infra/modules/<name>/` with:
   - `main.tf` — resources
   - `variables.tf` — all inputs, each with `description` and `type`; mark secrets `sensitive = true`
   - `outputs.tf` — only what downstream modules/root actually consume
   - `README.md` — one paragraph: purpose, inputs, outputs
3. Pin providers in the module's own `required_providers` block if it uses a provider not already pinned at root (usually it inherits from root — don't re-pin unless the module needs a different version).
4. Naming: every named Azure resource follows `mtc-aks-dev-<resource>` (see CLAUDE.md).
5. Respect the Terraform/ArgoCD boundary: this module provisions Azure infrastructure up to and including the AKS API server, identities, network, and Key Vault. It must NOT install anything running inside the cluster (no `helm_release`, no Kubernetes manifests) — that's ArgoCD's job.
6. Wire the module into root `infra/main.tf` with explicit `source = "./modules/<name>"` and pass only the variables it needs.
7. Run `terraform -chdir=infra fmt -recursive` and `terraform -chdir=infra validate` before considering it done (the PostToolUse hook does this automatically on save, but re-check after wiring into root).
8. Hand off to the `tf-reviewer` subagent for a review pass before merging.
