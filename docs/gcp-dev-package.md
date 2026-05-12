# 🚀 GCP Development Environment Package

## **Complete GCP Development Environment for GRC Toolkit v1.1**

This package provides everything needed to deploy and run the GRC Toolkit in a Google Cloud Platform development environment.

---

## 📦 **Package Contents**

### **Core Application Files**
- `grctoolkit.html` - Main application interface
- `Dockerfile` - Container configuration
- `nginx.conf` - Web server configuration
- `startup.sh` - Application startup script
- `graceful-shutdown.sh` - Graceful shutdown handling

### **Kubernetes Manifests**
- `k8s/namespace.yaml` - Kubernetes namespace
- `k8s/configmap.yaml` - Application configuration
- `k8s/secret.yaml` - API key secrets
- `k8s/deployment.yaml` - Application deployment
- `k8s/service.yaml` - Service exposure
- `k8s/ingress.yaml` - External access
- `k8s/hpa.yaml` - Auto-scaling configuration

### **OSCAL Integration**
- `oscal/catalog/nist-800-53-r5-catalog.json` - NIST 800-53 R5 OSCAL catalog
- `ai-agent/grc-compliance-engine.js` - AI compliance engine
- `compliance-docs/auditor-report-generator.js` - Report generation

### **Automation & Infrastructure**
- `ansible/playbooks/` - Automated compliance controls
- `scripts/setup-gcp.sh` - GCP environment setup
- `scripts/deploy.sh` - Deployment automation
- `scripts/update-secret.sh` - Secret management

### **Documentation**
- `README.md` - Project overview
- `DEPLOYMENT.md` - Deployment guide
- `OSCAL-INTEGRATION.md` - OSCAL integration guide
- `SECURITY.md` - Security documentation
- `GCP-DEMO-GUIDE.md` - GCP demo guide
- `CONFERENCE-DEMO-GUIDE.md` - Conference presentation guide

---

## 🛠️ **System Requirements**

### **Minimum Requirements**
- **CPU**: 2 vCPUs
- **RAM**: 4 GB
- **Storage**: 20 GB SSD
- **Network**: Internet connectivity for API calls

### **Recommended Requirements**
- **CPU**: 4 vCPUs
- **RAM**: 8 GB
- **Storage**: 50 GB SSD
- **Network**: High-speed internet for optimal performance

### **GCP Service Requirements**
- **Compute Engine**: For VM instances
- **Kubernetes Engine (GKE)**: For container orchestration
- **Artifact Registry**: For container images
- **Cloud Storage**: For persistent data (optional)
- **Cloud Logging**: For application logs
- **Cloud Monitoring**: For metrics and alerts

---

## 🔧 **Prerequisites**

### **Local Development Tools**
```bash
# Required tools
- Google Cloud SDK (gcloud CLI)
- Docker Desktop
- kubectl
- Git
- curl/wget
```

### **GCP Account Setup**
```bash
# 1. Create GCP Project
gcloud projects create your-project-id

# 2. Set billing account
gcloud billing accounts list
gcloud billing projects link your-project-id --billing-account=BILLING_ACCOUNT_ID

# 3. Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable monitoring.googleapis.com
```

### **Authentication Setup**
```bash
# 1. Authenticate with GCP
gcloud auth login

# 2. Set default project
gcloud config set project your-project-id

# 3. Configure Docker authentication
gcloud auth configure-docker
```

---

## 🚀 **Quick Start (5 minutes)**

### **Option 1: Automated Setup**
```bash
# Clone repository
git clone https://github.com/iFocus-Innovations-LLC/GRCToolKit.git
cd GRCToolKit

# Set environment variables
export GCP_PROJECT_ID="your-project-id"
export GCP_REGION="us-central1"
export GEMINI_API_KEY="your-gemini-api-key"

# Run automated setup
./scripts/setup-gcp.sh
```

### **Option 2: Manual Setup**
```bash
# 1. Create GKE cluster
gcloud container clusters create grc-toolkit-cluster \
    --zone=us-central1-a \
    --num-nodes=2 \
    --machine-type=e2-standard-2 \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=5

# 2. Get cluster credentials
gcloud container clusters get-credentials grc-toolkit-cluster --zone=us-central1-a

# 3. Deploy application
kubectl apply -f k8s/

# 4. Check deployment
kubectl get pods -n grc-toolkit
```

---

## 🏗️ **Architecture Overview**

### **Development Environment**
```
┌─────────────────────────────────────────────────────────────┐
│                    GCP Development Environment              │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   GKE Cluster   │  │  Artifact Reg.  │  │   Cloud Logs │ │
│  │                 │  │                 │  │              │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌──────────┐ │ │
│  │ │ GRC Toolkit │ │  │ │ Container   │ │  │ │ App Logs  │ │ │
│  │ │ Pods        │ │  │ │ Images      │ │  │ │ Metrics   │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └──────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   Load Balancer │  │   Cloud Storage  │  │   Monitoring  │ │
│  │                 │  │                 │  │               │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌──────────┐ │ │
│  │ │ Ingress     │ │  │ │ Persistent  │ │  │ │ Alerts    │ │ │
│  │ │ SSL/TLS     │ │  │ │ Volumes     │ │  │ │ Dashboards│ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └──────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### **Component Details**
- **GKE Cluster**: Kubernetes orchestration
- **GRC Toolkit Pods**: Application containers
- **Artifact Registry**: Container image storage
- **Load Balancer**: External access and SSL termination
- **Cloud Storage**: Persistent data and backups
- **Cloud Logging**: Centralized log collection
- **Cloud Monitoring**: Metrics, alerts, and dashboards

---

## 🔐 **Security Configuration**

### **API Key Management**
```bash
# 1. Create Kubernetes secret
kubectl create secret generic grc-toolkit-secrets \
    --from-literal=gemini-api-key="your-gemini-api-key" \
    --namespace=grc-toolkit

# 2. Update secret (if needed)
./scripts/update-secret.sh "your-new-api-key"
```

### **Network Security**
```yaml
# Firewall rules (automatically created)
- HTTP/HTTPS: Ports 80, 443
- GRC Toolkit: Port 8080
- SSH: Port 22 (for debugging)
- Source: Restricted to authorized IPs
```

### **Container Security**
- **Non-root user**: Application runs as non-privileged user
- **Read-only filesystem**: Immutable container filesystem
- **Security scanning**: Trivy vulnerability scanning
- **Image signing**: Container image integrity verification

---

## 📊 **Monitoring & Observability**

### **Application Metrics**
- **Response time**: API response latency
- **Throughput**: Requests per second
- **Error rate**: Failed request percentage
- **Resource usage**: CPU, memory, disk utilization

### **Business Metrics**
- **Compliance assessments**: Number of assessments performed
- **Control validations**: Controls validated per session
- **Report generations**: Audit reports generated
- **User sessions**: Active user sessions

### **Alerting Rules**
```yaml
# High error rate
- Condition: Error rate > 5%
- Action: Send notification to team

# High resource usage
- Condition: CPU > 80% for 5 minutes
- Action: Scale up cluster

# API key issues
- Condition: API authentication failures
- Action: Alert security team
```

---

## 💰 **Cost Optimization**

### **Resource Sizing**
```yaml
# Development Environment
- GKE Cluster: 2 nodes, e2-standard-2
- Storage: 20 GB SSD
- Network: Standard tier
- Estimated Cost: ~$50-100/month

# Production Environment
- GKE Cluster: 3+ nodes, e2-standard-4
- Storage: 100+ GB SSD
- Network: Premium tier
- Estimated Cost: ~$200-500/month
```

### **Cost Management**
- **Preemptible nodes**: 60-80% cost savings for non-critical workloads
- **Auto-scaling**: Scale down during low usage
- **Resource quotas**: Prevent runaway costs
- **Billing alerts**: Monitor spending in real-time

---

## 🧪 **Testing & Validation**

### **Automated Testing**
```bash
# Run test suite
./scripts/test-mvp-demo.sh

# Security scanning
./scripts/test-graceful-shutdown.sh

# Performance testing
kubectl run load-test --image=busybox --rm -it -- /bin/sh
```

### **Manual Testing**
1. **Health Check**: `curl http://[EXTERNAL-IP]/health`
2. **Main Interface**: `curl http://[EXTERNAL-IP]/`
3. **API Functionality**: Test Gemini API integration
4. **OSCAL Integration**: Validate NIST catalog loading
5. **Report Generation**: Test audit report creation

---

## 🚨 **Troubleshooting**

### **Common Issues**

#### **Pod Not Starting**
```bash
# Check pod status
kubectl get pods -n grc-toolkit

# Check pod logs
kubectl logs -f deployment/grc-toolkit -n grc-toolkit

# Check events
kubectl get events -n grc-toolkit
```

#### **API Key Issues**
```bash
# Verify secret exists
kubectl get secret grc-toolkit-secrets -n grc-toolkit

# Check secret content
kubectl get secret grc-toolkit-secrets -n grc-toolkit -o yaml
```

#### **Network Connectivity**
```bash
# Check service
kubectl get service grc-toolkit-service -n grc-toolkit

# Check ingress
kubectl get ingress grc-toolkit-ingress -n grc-toolkit

# Test connectivity
kubectl run test-pod --image=busybox --rm -it -- /bin/sh
```

---

## 📚 **Documentation References**

### **Quick Links**
- [GCP Documentation](https://cloud.google.com/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [NIST 800-53 R5](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)

### **Project Documentation**
- `README.md` - Project overview and quick start
- `DEPLOYMENT.md` - Detailed deployment instructions
- `OSCAL-INTEGRATION.md` - OSCAL integration guide
- `SECURITY.md` - Security best practices
- `GCP-DEMO-GUIDE.md` - GCP demo environment setup

---

## 🎯 **Next Steps**

### **Development Workflow**
1. **Local Development**: Use Docker for local testing
2. **Staging Deployment**: Deploy to GCP staging environment
3. **Testing**: Run automated and manual tests
4. **Production Deployment**: Deploy to production GCP environment
5. **Monitoring**: Set up monitoring and alerting

### **Feature Development**
- **Enhanced AI Models**: Integrate additional AI capabilities
- **Multi-tenant Support**: Support multiple organizations
- **Advanced Reporting**: Enhanced audit report generation
- **Integration APIs**: REST APIs for third-party integration

---

## 🆘 **Support & Resources**

### **Getting Help**
- **GitHub Issues**: Report bugs and request features
- **Documentation**: Comprehensive guides and references
- **Community**: Join the GRC Toolkit community
- **Professional Support**: Enterprise support available

### **Useful Commands**
```bash
# Check cluster status
kubectl cluster-info

# View all resources
kubectl get all -n grc-toolkit

# Check logs
kubectl logs -f deployment/grc-toolkit -n grc-toolkit

# Scale deployment
kubectl scale deployment grc-toolkit --replicas=3 -n grc-toolkit
```

---

## 🎉 **Ready to Deploy!**

Your GCP development environment package is complete and ready for deployment. This package provides:

- ✅ **Complete Application**: GRC Toolkit v1.1 with OSCAL integration
- ✅ **Infrastructure as Code**: Kubernetes manifests and automation
- ✅ **Security**: Hardened containers and network security
- ✅ **Monitoring**: Comprehensive observability and alerting
- ✅ **Documentation**: Complete setup and troubleshooting guides
- ✅ **Cost Optimization**: Efficient resource utilization

**🚀 Start your GRC Toolkit development environment today!**
