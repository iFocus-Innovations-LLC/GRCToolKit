# Helm & Terraform (portable Kubernetes delivery)

This repo supports **vendor-neutral Kubernetes** installs via **Helm**, with an **optional Terraform** module for **GCP dev bootstrap** (Artifact Registry + APIs). Customers on AWS, Azure, or other clouds use the same chart with their own registry and ingress settings.

## Helm chart

Location: [`charts/grc-toolkit`](../charts/grc-toolkit/).

### Install (any cluster)

1. Build and push your image to **your** registry (ECR, ACR, GAR, Harbor, etc.).
2. Create the Gemini secret (or disable `gemini.enabled` for static-only demos):

   ```bash
   kubectl create namespace grc-toolkit
   kubectl create secret generic grc-toolkit-secrets \
     --namespace grc-toolkit \
     --from-literal=gemini-api-key='YOUR_KEY'
   ```

3. Install:

   ```bash
   helm upgrade --install grc ./charts/grc-toolkit \
     --namespace grc-toolkit \
     --set image.full=YOUR_REGISTRY/PATH/grc-toolkit:TAG
   ```

   Or use split fields (see `values.yaml`):

   ```bash
   helm upgrade --install grc ./charts/grc-toolkit \
     --namespace grc-toolkit \
     --set image.registry=us-central1-docker.pkg.dev/PROJECT/REPO_NAME \
     --set image.repository=grc-toolkit \
     --set image.tag=latest
   ```

### Ingress examples

- GKE: [`charts/grc-toolkit/examples/values-ingress-gke.yaml`](../charts/grc-toolkit/examples/values-ingress-gke.yaml)
- NGINX Ingress: [`charts/grc-toolkit/examples/values-ingress-nginx.yaml`](../charts/grc-toolkit/examples/values-ingress-nginx.yaml)

```bash
helm upgrade --install grc ./charts/grc-toolkit \
  -f charts/grc-toolkit/examples/values-ingress-nginx.yaml \
  --set image.full=...
```

### Relationship to `k8s/` manifests

The `k8s/` directory remains a **flat reference** for tutorials and scripts. **Helm is the recommended install path** for repeatable, configurable deployments.

---

## Terraform (GCP bootstrap only)

Location: [`terraform/gcp-bootstrap`](../terraform/gcp-bootstrap/).

Creates:

- **Artifact Registry** Docker repository
- Enables **APIs**: Artifact Registry, optional GKE/Secret Manager related services

It does **not** create a GKE cluster (keeps cost and lock-in optional). Add your own Terraform for EKS/AKS/GKE when needed.

### Usage

**Do not commit `project_id`.** Use `TF_VAR_project_id` from CI secrets, a gitignored `terraform.tfvars`, or Secret Manager — see [`terraform/gcp-bootstrap/README.md`](../terraform/gcp-bootstrap/README.md).

```bash
cd terraform/gcp-bootstrap
export TF_VAR_project_id="..."   # from your secret store in real deployments
terraform init
terraform plan
terraform apply
```

Use the output `helm_image_registry_hint` with Helm `image.registry` + your image name.

---

## Selling / multi-cloud positioning

- **Ship**: OCI image + Helm chart + install docs.
- **Customer**: Supplies registry, cluster, ingress class, and secrets (or External Secrets).
- **Your dev**: Terraform `gcp-bootstrap` + GKE (your choice) + Helm with GAR image.

---

## References

- [Secrets setup](SECRETS-SETUP.md)
- [GCP deployment checklist](GCP-DEPLOYMENT-CHECKLIST.md)
