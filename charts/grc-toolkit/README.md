# grc-toolkit Helm chart

Portable install for **any Kubernetes** (EKS, AKS, GKE, on-prem). Point `image.registry` / `image.repository` at **your** container registry.

## Quick install

```bash
# Create namespace secret first (recommended)
kubectl create namespace grc-toolkit
kubectl create secret generic grc-toolkit-secrets \
  --namespace grc-toolkit \
  --from-literal=gemini-api-key='YOUR_GEMINI_API_KEY'

helm install grc ./charts/grc-toolkit \
  --namespace grc-toolkit \
  --set image.registry=REGISTRY_HOST \
  --set image.repository=PATH_TO_IMAGE \
  --set image.tag=2.1.0-dev
```

## GCP Artifact Registry example

```bash
export REG=us-central1-docker.pkg.dev
export PROJECT=my-gcp-project
export REPO=grc-toolkit

helm upgrade --install grc ./charts/grc-toolkit \
  --namespace grc-toolkit --create-namespace \
  --set image.registry=${REG}/${PROJECT}/${REPO} \
  --set image.repository=grc-toolkit \
  --set image.tag=latest
```

## Ingress (optional)

Enable and set **cloud-specific** annotations in a values file — see `values-ingress-nginx.yaml` / `values-ingress-gke.yaml` patterns in [docs/HELM-TERRAFORM.md](../../docs/HELM-TERRAFORM.md).

## Values reference

See `values.yaml` for `ingress`, `hpa`, `resources`, `secret.create`, and `gemini.enabled`.
