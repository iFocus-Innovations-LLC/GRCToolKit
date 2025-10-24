# 🌐 GCP Demo Environment for GRC Toolkit

## **Why GCP for Conference Demo?**

Using GCP with ephemeral VMs provides several advantages for your conference demonstration:

### ✅ **Realistic Enterprise Environment**
- **Multi-Platform Testing**: Windows and Linux VMs for comprehensive compliance validation
- **Cloud-Native Deployment**: Demonstrates production-ready Kubernetes deployment
- **Scalable Architecture**: Shows enterprise-grade scalability
- **Real Network Security**: Actual firewall rules and network boundaries

### ✅ **Enhanced Demo Scenarios**
- **Cross-Platform Compliance**: Validate controls across Windows and Linux systems
- **Network Security Testing**: Real firewall and network boundary validation
- **Cloud Security**: Demonstrate cloud-specific compliance requirements
- **Audit Trail**: Complete evidence collection from real systems

### ✅ **Conference Impact**
- **Live Demo**: Real-time validation on actual systems
- **Professional Setup**: Enterprise-grade infrastructure
- **Cost-Effective**: Ephemeral VMs minimize costs (~$0.20/hour)
- **Easy Cleanup**: Automated cleanup prevents unexpected charges

---

## 🚀 **Quick Setup (5 minutes)**

### **Prerequisites**
```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Install Docker (if not already installed)
# Install kubectl (if not already installed)
```

### **One-Command Setup**
```bash
# Set your GCP project ID
export GCP_PROJECT_ID="your-project-id"

# Run the setup script
./scripts/setup-gcp-demo.sh
```

### **Manual Setup Steps**
```bash
# 1. Authenticate with GCP
gcloud auth login

# 2. Set project
gcloud config set project YOUR_PROJECT_ID

# 3. Enable APIs
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com

# 4. Create demo VMs
gcloud compute instances create grc-demo-windows \
    --zone=us-central1-a \
    --machine-type=e2-standard-2 \
    --image-family=windows-2019 \
    --image-project=windows-cloud \
    --preemptible

gcloud compute instances create grc-demo-linux \
    --zone=us-central1-a \
    --machine-type=e2-standard-2 \
    --image-family=ubuntu-2004-lts \
    --image-project=ubuntu-os-cloud \
    --preemptible

gcloud compute instances create grc-demo-toolkit \
    --zone=us-central1-a \
    --machine-type=e2-standard-4 \
    --image-family=ubuntu-2004-lts \
    --image-project=ubuntu-os-cloud \
    --preemptible
```

---

## 🎭 **Enhanced Demo Scenarios**

### **Scenario 1: Windows Enterprise Security**
**Target VM**: Windows Server 2019
**Scenario**: *"How do I secure access to our Windows domain controllers and ensure proper audit logging?"*

**Controls Validated**:
- **AC-3**: Access Enforcement (Windows authentication)
- **AC-6**: Least Privilege (Windows user permissions)
- **AU-2**: Audit Events (Windows Event Log)
- **SC-7**: Boundary Protection (Windows Firewall)

**Demo Highlights**:
- Real Windows authentication validation
- Active Directory integration testing
- Windows Event Log audit verification
- Windows Firewall rule validation

### **Scenario 2: Linux Infrastructure Security**
**Target VM**: Ubuntu 20.04 LTS
**Scenario**: *"What controls are needed for securing our Linux web servers and database systems?"*

**Controls Validated**:
- **AC-3**: Access Enforcement (SSH authentication)
- **AC-6**: Least Privilege (sudo permissions)
- **SC-7**: Boundary Protection (iptables/UFW)
- **AU-2**: Audit Events (auditd logging)

**Demo Highlights**:
- SSH security configuration validation
- Linux privilege escalation testing
- Network firewall rule verification
- System audit log analysis

### **Scenario 3: Multi-Platform Compliance**
**Target VMs**: Both Windows and Linux
**Scenario**: *"How do I ensure consistent security controls across our mixed Windows/Linux environment?"*

**Controls Validated**:
- **AC-6**: Least Privilege (cross-platform)
- **AU-2**: Audit Events (unified logging)
- **SC-7**: Boundary Protection (network security)
- **SC-8**: Transmission Confidentiality (encryption)

**Demo Highlights**:
- Cross-platform compliance validation
- Unified audit log collection
- Network security consistency
- Encryption verification

---

## 🛠️ **Technical Implementation**

### **VM Specifications**
```yaml
Windows VM:
  - OS: Windows Server 2019
  - CPU: 2 vCPUs
  - RAM: 8 GB
  - Disk: 50 GB SSD
  - Features: Windows Defender, Firewall, Audit Policy

Linux VM:
  - OS: Ubuntu 20.04 LTS
  - CPU: 2 vCPUs
  - RAM: 8 GB
  - Disk: 20 GB SSD
  - Features: auditd, iptables, UFW, Ansible

GRC Toolkit VM:
  - OS: Ubuntu 20.04 LTS
  - CPU: 4 vCPUs
  - RAM: 16 GB
  - Disk: 30 GB SSD
  - Features: Docker, Kubernetes, GRC Toolkit
```

### **Network Configuration**
```yaml
Firewall Rules:
  - HTTP/HTTPS: Ports 80, 443, 8080
  - SSH: Port 22
  - RDP: Port 3389 (Windows)
  - Source: 0.0.0.0/0 (demo purposes)

Network Security:
  - VPC with custom subnets
  - Firewall rules for demo access
  - NAT gateway for outbound access
  - Load balancer for GRC Toolkit
```

---

## 🎯 **Conference Demo Flow**

### **Opening (2 minutes)**
> *"Today I'll demonstrate GRC compliance validation across a realistic enterprise environment with Windows and Linux systems running in Google Cloud Platform."*

### **Live Demo (12-15 minutes)**

#### **Step 1: Environment Overview (2 minutes)**
- Show GCP console with running VMs
- Explain the multi-platform setup
- Highlight real enterprise infrastructure

#### **Step 2: Windows Security Validation (4 minutes)**
1. **Navigate to GRC Toolkit**: `http://[GRC-VM-IP]:8080`
2. **Enter scenario**: *"How do I secure our Windows domain controllers?"*
3. **Show AI analysis**: AC-3, AC-6, AU-2 controls
4. **Execute validation**: Ansible playbooks against Windows VM
5. **Show results**: Real Windows security validation

#### **Step 3: Linux Security Validation (4 minutes)**
1. **Enter scenario**: *"What controls are needed for our Linux web servers?"*
2. **Show AI analysis**: SC-7, AC-6, AU-2 controls
3. **Execute validation**: Ansible playbooks against Linux VM
4. **Show results**: Real Linux security validation

#### **Step 4: Cross-Platform Compliance (4 minutes)**
1. **Enter scenario**: *"How do I ensure consistent security across mixed environments?"*
2. **Show unified analysis**: Multi-platform control mapping
3. **Execute validation**: Both VMs simultaneously
4. **Show results**: Cross-platform compliance report

#### **Step 5: OSCAL Report Generation (2 minutes)**
1. **Generate audit report**: Professional OSCAL documentation
2. **Download reports**: Auditor-ready compliance documentation
3. **Show evidence**: Real system validation evidence

### **Technical Deep Dive (3-5 minutes)**
- **GCP Integration**: Cloud-native deployment
- **Multi-Platform Support**: Windows and Linux validation
- **Real Evidence**: Actual system configuration validation
- **Scalable Architecture**: Enterprise-grade deployment

---

## 💰 **Cost Management**

### **Cost Breakdown**
```
Windows VM (e2-standard-2): ~$0.10/hour
Linux VM (e2-standard-2):   ~$0.05/hour
GRC Toolkit VM (e2-standard-4): ~$0.10/hour
Total: ~$0.25/hour
```

### **Cost Optimization**
- **Preemptible Instances**: 60-80% cost savings
- **Automatic Cleanup**: Scripts to delete VMs after demo
- **Time Limits**: Maximum 4-hour demo sessions
- **Resource Monitoring**: GCP cost alerts

### **Cleanup Script**
```bash
#!/bin/bash
# Cleanup script to run after demo
gcloud compute instances delete grc-demo-windows grc-demo-linux grc-demo-toolkit \
    --zone=us-central1-a --quiet
gcloud compute firewall-rules delete grc-demo-web-access grc-demo-ssh-access --quiet
echo "Demo environment cleaned up. Total cost: ~$1.00"
```

---

## 🔒 **Security Considerations**

### **Demo Security**
- **Public Access**: Firewall rules allow public access (demo only)
- **Temporary VMs**: All VMs deleted after demo
- **No Sensitive Data**: No real production data used
- **Isolated Environment**: Separate from production systems

### **Production Security**
- **Private Networks**: VPC with private subnets
- **Access Controls**: IAM roles and permissions
- **Encryption**: Data encryption at rest and in transit
- **Monitoring**: Cloud Security Command Center integration

---

## 📊 **Demo Metrics**

### **Performance Metrics**
- **VM Startup**: 2-3 minutes
- **GRC Toolkit Deployment**: 1-2 minutes
- **Control Validation**: 30-60 seconds per control
- **Report Generation**: 10-15 seconds

### **Demo Impact Metrics**
- **Real Systems**: 2 different operating systems
- **Live Validation**: Real-time compliance checking
- **Professional Setup**: Enterprise-grade infrastructure
- **Audience Engagement**: Interactive multi-platform demo

---

## 🚀 **Getting Started**

### **Quick Start Commands**
```bash
# 1. Set up GCP environment
./scripts/setup-gcp-demo.sh

# 2. Deploy GRC Toolkit
gcloud compute ssh grc-demo-toolkit --zone=us-central1-a
cd GRCToolKit
docker run -d -p 8080:8080 -e GEMINI_API_KEY="your-key" --name grc-demo grc-toolkit-oscal

# 3. Access demo
open http://[GRC-VM-IP]:8080

# 4. Clean up after demo
./scripts/cleanup-gcp-demo.sh
```

### **Demo Checklist**
- [ ] GCP project configured
- [ ] VMs created and running
- [ ] GRC Toolkit deployed
- [ ] Demo scenarios prepared
- [ ] Cleanup scripts ready
- [ ] Cost monitoring enabled

---

## 🎉 **Conference Ready!**

Your GCP demo environment provides:
- **Realistic Enterprise Setup**: Multi-platform validation
- **Professional Infrastructure**: Cloud-native deployment
- **Interactive Demo**: Live system validation
- **Cost-Effective**: Ephemeral VMs with automatic cleanup
- **Audience Impact**: Real compliance validation on actual systems

**🌐 Ready for your Fall 2024 technical conference presentation!**

