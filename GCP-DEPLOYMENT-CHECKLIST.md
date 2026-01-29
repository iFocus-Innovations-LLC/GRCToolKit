# GCP Development Deployment Checklist

## Version: 2.0.0-dev
## Target Environment: GCP Development/QA
## Date: 2025-01-XX

---

## Pre-Deployment Requirements

### GCP Account Setup
- [ ] GCP Project created with project ID: `_________________`
- [ ] Billing account linked and active
- [ ] Required APIs enabled (see below)
- [ ] Service account created with appropriate permissions
- [ ] IAM roles configured for deployment

### Required GCP APIs
- [ ] `compute.googleapis.com` - Compute Engine
- [ ] `container.googleapis.com` - Kubernetes Engine (GKE)
- [ ] `artifactregistry.googleapis.com` - Artifact Registry
- [ ] `logging.googleapis.com` - Cloud Logging
- [ ] `monitoring.googleapis.com` - Cloud Monitoring
- [ ] `storage.googleapis.com` - Cloud Storage (optional)
- [ ] `secretmanager.googleapis.com` - Secret Manager (optional)

### Local Development Tools
- [ ] Google Cloud SDK (gcloud CLI) installed and configured
- [ ] Docker Desktop installed and running
- [ ] kubectl installed (v1.28+)
- [ ] Git installed
- [ ] Authenticated with GCP: `gcloud auth login`
- [ ] Default project set: `gcloud config set project PROJECT_ID`

### External Dependencies
- [ ] Gemini API key obtained from [Google AI Studio](https://aistudio.google.com/)
- [ ] API key stored securely (will be added to Kubernetes secrets)

---

## Deployment Steps

### Step 1: GKE Cluster Creation
```bash
# Set variables
export PROJECT_ID="your-project-id"
export REGION="us-central1"
export ZONE="us-central1-a"
export CLUSTER_NAME="grc-toolkit-dev"

# Create GKE cluster
gcloud container clusters create $CLUSTER_NAME \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --num-nodes=2 \
    --machine-type=e2-standard-2 \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=5 \
    --enable-autorepair \
    --enable-autoupgrade \
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing

# Get cluster credentials
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE
```

- [ ] GKE cluster created successfully
- [ ] Cluster credentials configured
- [ ] Verified cluster access: `kubectl cluster-info`

### Step 2: Artifact Registry Setup
```bash
# Create Artifact Registry repository
gcloud artifacts repositories create grc-toolkit-repo \
    --repository-format=docker \
    --location=$REGION \
    --description="GRC Toolkit container images"

# Configure Docker authentication
gcloud auth configure-docker $REGION-docker.pkg.dev
```

- [ ] Artifact Registry repository created
- [ ] Docker authentication configured

### Step 3: Build and Push Container Image
```bash
# Set image path
export IMAGE_PATH="$REGION-docker.pkg.dev/$PROJECT_ID/grc-toolkit-repo/grc-toolkit:2.0.0-dev"

# Build Docker image
docker build -t $IMAGE_PATH .

# Push to Artifact Registry
docker push $IMAGE_PATH
```

- [ ] Docker image built successfully
- [ ] Image pushed to Artifact Registry
- [ ] Verified image exists: `gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/grc-toolkit-repo`

### Step 4: Update Kubernetes Manifests
```bash
# Update deployment.yaml with your PROJECT_ID
sed -i '' "s/PROJECT_ID/$PROJECT_ID/g" k8s/deployment.yaml

# Verify the image path is correct
grep -r "gcr.io\|docker.pkg.dev" k8s/deployment.yaml
```

- [ ] PROJECT_ID updated in deployment.yaml
- [ ] Image path verified

### Step 5: Create Kubernetes Namespace
```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Verify namespace created
kubectl get namespace grc-toolkit
```

- [ ] Namespace created successfully

### Step 6: Create ConfigMap
```bash
# Apply ConfigMap
kubectl apply -f k8s/configmap.yaml

# Verify ConfigMap
kubectl get configmap grc-toolkit-config -n grc-toolkit -o yaml
```

- [ ] ConfigMap created
- [ ] Version information verified (2.0.0-dev)

### Step 7: Create Secrets
```bash
# Create secret with Gemini API key
kubectl create secret generic grc-toolkit-secrets \
    --from-literal=gemini-api-key="YOUR_GEMINI_API_KEY" \
    --namespace=grc-toolkit

# Verify secret created (don't display value)
kubectl get secret grc-toolkit-secrets -n grc-toolkit
```

- [ ] Secret created successfully
- [ ] API key stored securely
- [ ] Secret verified (without displaying value)

### Step 8: Deploy Application
```bash
# Deploy all Kubernetes resources
kubectl apply -f k8s/

# Verify deployment
kubectl get all -n grc-toolkit
```

- [ ] Deployment created
- [ ] Service created
- [ ] Ingress created (if applicable)
- [ ] HPA created

### Step 9: Verify Deployment Status
```bash
# Check pod status
kubectl get pods -n grc-toolkit

# Check pod logs
kubectl logs -f deployment/grc-toolkit -n grc-toolkit

# Check service
kubectl get service grc-toolkit-service -n grc-toolkit

# Check ingress (if created)
kubectl get ingress -n grc-toolkit
```

- [ ] All pods running (3/3 ready)
- [ ] No errors in pod logs
- [ ] Service endpoint accessible
- [ ] Health checks passing

### Step 10: Configure Ingress (External Access)
```bash
# Apply ingress configuration
kubectl apply -f k8s/ingress.yaml

# Get external IP
kubectl get ingress grc-toolkit-ingress -n grc-toolkit

# Wait for IP assignment (may take a few minutes)
```

- [ ] Ingress created
- [ ] External IP assigned
- [ ] DNS configured (if using custom domain)

---

## Post-Deployment Verification

### Health Checks
- [ ] Application accessible via external IP/URL
- [ ] Health endpoint responding: `curl http://EXTERNAL_IP/health`
- [ ] Main interface loads: `curl http://EXTERNAL_IP/`
- [ ] No 5xx errors in logs

### Functional Testing
- [ ] Scenario analysis works (test with sample GRC scenario)
- [ ] AI API integration functional (Gemini API responding)
- [ ] OSCAL catalog loads correctly
- [ ] Control recommendations display properly
- [ ] Export functionality works

### PQC Features Testing
- [ ] PQC scenario detection works
- [ ] PQC playbooks referenced correctly
- [ ] PQC modules load without errors
- [ ] Quantum risk assessment logic functional

### Monitoring Setup
- [ ] Cloud Logging enabled and receiving logs
- [ ] Cloud Monitoring dashboards configured
- [ ] Alerting rules created (optional)
- [ ] Resource usage within expected ranges

### Security Verification
- [ ] Pods running as non-root user (UID 1001)
- [ ] Secrets not exposed in logs
- [ ] Network policies applied (if configured)
- [ ] TLS/SSL configured (if using HTTPS)

---

## Troubleshooting

### Common Issues

#### Pods Not Starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n grc-toolkit

# Check events
kubectl get events -n grc-toolkit --sort-by='.lastTimestamp'
```

#### API Key Issues
```bash
# Verify secret exists
kubectl get secret grc-toolkit-secrets -n grc-toolkit

# Check if key is accessible in pod
kubectl exec -it <pod-name> -n grc-toolkit -- env | grep GEMINI
```

#### Image Pull Errors
```bash
# Verify image exists
gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/grc-toolkit-repo

# Check image pull secrets
kubectl get secrets -n grc-toolkit
```

#### Network Connectivity
```bash
# Test service connectivity
kubectl run test-pod --image=busybox --rm -it -- wget -O- http://grc-toolkit-service:80

# Check ingress status
kubectl describe ingress grc-toolkit-ingress -n grc-toolkit
```

---

## Cost Monitoring

### Expected Monthly Costs (Development)
- GKE Cluster (2 nodes, e2-standard-2): ~$50/month
- Artifact Registry: ~$5/month
- Cloud Logging: ~$10/month
- Cloud Monitoring: ~$5/month
- Network Egress: ~$5/month
- **Total: ~$75/month**

### Cost Optimization Tips
- Use preemptible nodes for non-critical workloads (60-80% savings)
- Enable auto-scaling to scale down during low usage
- Set up billing alerts
- Review and optimize resource requests/limits

---

## Rollback Procedure

If deployment fails or issues are discovered:

```bash
# Rollback to previous deployment
kubectl rollout undo deployment/grc-toolkit -n grc-toolkit

# Or delete and redeploy
kubectl delete -f k8s/
kubectl apply -f k8s/
```

---

## Next Steps After Successful Deployment

1. **QA Testing**: Run through QA test suite (see QA-TESTING-GUIDE.md)
2. **Documentation**: Update deployment documentation with actual values
3. **Monitoring**: Set up additional monitoring and alerting
4. **Backup**: Configure backup procedures
5. **Team Access**: Grant team members appropriate GCP access

---

## Support Resources

- **GCP Documentation**: https://cloud.google.com/docs
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Project README**: [README.md](README.md)
- **Deployment Guide**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Troubleshooting**: Check logs and events first, then consult documentation

---

**Deployment Status**: ⏳ Pending  
**Deployed By**: _________________  
**Deployment Date**: _________________  
**Deployment Time**: _________________  
**External URL**: _________________  

