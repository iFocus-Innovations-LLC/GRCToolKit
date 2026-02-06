# Secrets & API Keys Setup

This guide covers local, Kubernetes, and GitHub Actions secret setup.

## 1) Local environment

Set environment variables in your shell:

```bash
export GEMINI_API_KEY="YOUR_KEY"
export TEST_API_TOKEN="test-placeholder"
```

## 2) Local Docker container

Build and run with the Gemini key injected:

```bash
docker build -t grc-toolkit-oscal:2.0.0-dev .
docker rm -f grc-toolkit-mvp 2>/dev/null || true
docker run -d -p 8085:8080 -e GEMINI_API_KEY="$GEMINI_API_KEY" \
  --name grc-toolkit-mvp grc-toolkit-oscal:2.0.0-dev
```

Verify injection:

```bash
curl -s http://localhost:8085/ | grep -o 'window.GEMINI_API_KEY = "[^"]*"'
```

## 3) Kubernetes (dev cluster)

Create the secret and restart the deployment:

```bash
export GEMINI_API_KEY="YOUR_KEY"

kubectl create namespace grc-toolkit 2>/dev/null || true
kubectl create secret generic grc-toolkit-secrets \
  --from-literal=gemini-api-key="$GEMINI_API_KEY" \
  -n grc-toolkit --dry-run=client -o yaml | kubectl apply -f -

kubectl rollout restart deployment grc-toolkit -n grc-toolkit
```

Verify injection:

```bash
kubectl exec -it deploy/grc-toolkit -n grc-toolkit -- env | grep GEMINI_API_KEY
```

## 4) GitHub Actions secrets (CI/CD)

Set these in: **Repo → Settings → Secrets and variables → Actions**

- `GCP_PROJECT_ID`
- `GCP_SA_KEY` (service account JSON)
- `GKE_CLUSTER_NAME`
- `DOCKER_SCOUT_TOKEN` (optional; enables Docker Scout scan)
- `GEMINI_API_KEY` (if any workflow needs it)

After setting secrets, re-run the CI job.
