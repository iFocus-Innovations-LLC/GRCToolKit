#!/bin/bash

# GCP Demo Environment Setup Script
# Creates ephemeral VMs for GRC Toolkit conference demonstration

set -e

# Configuration
PROJECT_ID=${GCP_PROJECT_ID:-"your-project-id"}
REGION=${GCP_REGION:-"us-central1"}
ZONE=${GCP_ZONE:-"us-central1-a"}
DEMO_PREFIX="grc-demo-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Setting up GCP Demo Environment for GRC Toolkit${NC}"
echo "=================================================="

# Check prerequisites
check_prerequisites() {
    echo -e "\n${BLUE}🔍 Checking prerequisites...${NC}"
    
    if ! command -v gcloud &> /dev/null; then
        echo -e "${RED}❌ gcloud CLI not found. Please install Google Cloud SDK${NC}"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker not found. Please install Docker${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Authenticate and set project
setup_gcp() {
    echo -e "\n${BLUE}🔐 Setting up GCP environment...${NC}"
    
    # Authenticate
    gcloud auth login --no-launch-browser
    
    # Set project
    gcloud config set project $PROJECT_ID
    
    # Enable required APIs
    gcloud services enable compute.googleapis.com
    gcloud services enable container.googleapis.com
    gcloud services enable artifactregistry.googleapis.com
    
    echo -e "${GREEN}✅ GCP environment configured${NC}"
}

# Create demo VMs
create_demo_vms() {
    echo -e "\n${BLUE}🖥️  Creating demo VMs...${NC}"
    
    # Windows VM for Windows compliance testing
    echo -e "${YELLOW}Creating Windows VM...${NC}"
    gcloud compute instances create ${DEMO_PREFIX}-windows \
        --zone=$ZONE \
        --machine-type=e2-standard-2 \
        --image-family=windows-2019 \
        --image-project=windows-cloud \
        --boot-disk-size=50GB \
        --boot-disk-type=pd-standard \
        --tags=demo-vm \
        --metadata=windows-startup-script='@echo off
echo Installing Windows features...
powershell -Command "Install-WindowsFeature -Name Windows-Defender, Windows-Firewall, Audit-Policy, Audit-Core"
echo Windows VM ready for GRC demo' \
        --preemptible
    
    # Linux VM for Linux compliance testing
    echo -e "${YELLOW}Creating Linux VM...${NC}"
    gcloud compute instances create ${DEMO_PREFIX}-linux \
        --zone=$ZONE \
        --machine-type=e2-standard-2 \
        --image-family=ubuntu-2004-lts \
        --image-project=ubuntu-os-cloud \
        --boot-disk-size=20GB \
        --boot-disk-type=pd-standard \
        --tags=demo-vm \
        --metadata=startup-script='#!/bin/bash
apt-get update
apt-get install -y auditd iptables-persistent ufw ansible
systemctl enable auditd
systemctl start auditd
echo "Linux VM ready for GRC demo"' \
        --preemptible
    
    # GRC Toolkit VM (main demo server)
    echo -e "${YELLOW}Creating GRC Toolkit VM...${NC}"
    gcloud compute instances create ${DEMO_PREFIX}-grc-toolkit \
        --zone=$ZONE \
        --machine-type=e2-standard-4 \
        --image-family=ubuntu-2004-lts \
        --image-project=ubuntu-os-cloud \
        --boot-disk-size=30GB \
        --boot-disk-type=pd-standard \
        --tags=demo-vm,grc-toolkit \
        --metadata=startup-script='#!/bin/bash
apt-get update
apt-get install -y docker.io kubectl
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu
echo "GRC Toolkit VM ready"' \
        --preemptible
    
    echo -e "${GREEN}✅ Demo VMs created${NC}"
}

# Deploy GRC Toolkit to GCP
deploy_grc_toolkit() {
    echo -e "\n${BLUE}🚀 Deploying GRC Toolkit to GCP...${NC}"
    
    # Get GRC Toolkit VM IP
    GRC_VM_IP=$(gcloud compute instances describe ${DEMO_PREFIX}-grc-toolkit \
        --zone=$ZONE \
        --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
    
    echo -e "${YELLOW}GRC Toolkit VM IP: $GRC_VM_IP${NC}"
    
    # Create deployment script for GRC VM
    cat > deploy-to-grc-vm.sh << 'EOF'
#!/bin/bash
# This script will be run on the GRC Toolkit VM

# Install Docker if not already installed
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Clone GRC Toolkit repository
git clone https://github.com/your-username/GRCToolKit.git
cd GRCToolKit

# Build and run GRC Toolkit
docker build -t grc-toolkit-oscal .
docker run -d -p 8080:8080 -e GEMINI_API_KEY="$GEMINI_API_KEY" --name grc-toolkit-demo grc-toolkit-oscal

echo "GRC Toolkit deployed and running on port 8080"
EOF
    
    # Copy deployment script to GRC VM
    gcloud compute scp deploy-to-grc-vm.sh ${DEMO_PREFIX}-grc-toolkit:~/ \
        --zone=$ZONE
    
    echo -e "${GREEN}✅ GRC Toolkit deployment prepared${NC}"
}

# Create firewall rules
setup_firewall() {
    echo -e "\n${BLUE}🔥 Setting up firewall rules...${NC}"
    
    # Allow HTTP/HTTPS traffic
    gcloud compute firewall-rules create ${DEMO_PREFIX}-web-access \
        --allow tcp:80,tcp:443,tcp:8080 \
        --source-ranges 0.0.0.0/0 \
        --target-tags demo-vm \
        --description "Allow web access for GRC demo"
    
    # Allow SSH access
    gcloud compute firewall-rules create ${DEMO_PREFIX}-ssh-access \
        --allow tcp:22 \
        --source-ranges 0.0.0.0/0 \
        --target-tags demo-vm \
        --description "Allow SSH access for GRC demo"
    
    echo -e "${GREEN}✅ Firewall rules created${NC}"
}

# Generate demo information
generate_demo_info() {
    echo -e "\n${BLUE}📋 Generating demo information...${NC}"
    
    # Get VM IPs
    WINDOWS_IP=$(gcloud compute instances describe ${DEMO_PREFIX}-windows \
        --zone=$ZONE \
        --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
    
    LINUX_IP=$(gcloud compute instances describe ${DEMO_PREFIX}-linux \
        --zone=$ZONE \
        --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
    
    GRC_IP=$(gcloud compute instances describe ${DEMO_PREFIX}-grc-toolkit \
        --zone=$ZONE \
        --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
    
    # Create demo info file
    cat > gcp-demo-info.md << EOF
# GCP Demo Environment Information

**Created**: $(date)
**Project**: $PROJECT_ID
**Region**: $REGION
**Zone**: $ZONE

## Demo VMs

### GRC Toolkit Server
- **Name**: ${DEMO_PREFIX}-grc-toolkit
- **IP**: $GRC_IP
- **URL**: http://$GRC_IP:8080
- **Purpose**: Main GRC Toolkit demo server
- **OS**: Ubuntu 20.04 LTS

### Windows Target VM
- **Name**: ${DEMO_PREFIX}-windows
- **IP**: $WINDOWS_IP
- **Purpose**: Windows compliance testing
- **OS**: Windows Server 2019
- **RDP Access**: mstsc /v:$WINDOWS_IP

### Linux Target VM
- **Name**: ${DEMO_PREFIX}-linux
- **IP**: $LINUX_IP
- **Purpose**: Linux compliance testing
- **OS**: Ubuntu 20.04 LTS
- **SSH Access**: ssh ubuntu@$LINUX_IP

## Demo Scenarios

### Scenario 1: Windows Security
- **Target**: $WINDOWS_IP
- **Controls**: AC-3, AC-6, AU-2
- **Focus**: Windows authentication and audit logging

### Scenario 2: Linux Security
- **Target**: $LINUX_IP
- **Controls**: AC-3, AC-6, SC-7
- **Focus**: Linux access control and network security

### Scenario 3: Cross-Platform Compliance
- **Targets**: Both VMs
- **Controls**: AU-2, SC-7, AC-6
- **Focus**: Multi-platform compliance validation

## Access Instructions

### GRC Toolkit Access
\`\`\`bash
# SSH to GRC Toolkit VM
gcloud compute ssh ${DEMO_PREFIX}-grc-toolkit --zone=$ZONE

# Deploy GRC Toolkit
cd GRCToolKit
docker run -d -p 8080:8080 -e GEMINI_API_KEY="$GEMINI_API_KEY" --name grc-toolkit-demo grc-toolkit-oscal
\`\`\`

### Windows VM Access
\`\`\`bash
# Get Windows password
gcloud compute reset-windows-password ${DEMO_PREFIX}-windows --zone=$ZONE --user=Administrator
\`\`\`

### Linux VM Access
\`\`\`bash
# SSH to Linux VM
gcloud compute ssh ${DEMO_PREFIX}-linux --zone=$ZONE
\`\`\`

## Cleanup Instructions

\`\`\`bash
# Delete all demo VMs
gcloud compute instances delete ${DEMO_PREFIX}-windows ${DEMO_PREFIX}-linux ${DEMO_PREFIX}-grc-toolkit --zone=$ZONE --quiet

# Delete firewall rules
gcloud compute firewall-rules delete ${DEMO_PREFIX}-web-access ${DEMO_PREFIX}-ssh-access --quiet
\`\`\`

## Cost Estimation

- **Windows VM**: ~$0.10/hour
- **Linux VMs**: ~$0.05/hour each
- **Total**: ~$0.20/hour for demo environment
- **Recommended**: Run for 2-4 hours maximum

## Security Notes

- VMs are created with preemptible instances (cost-effective)
- Firewall rules allow public access (demo purposes only)
- All VMs will be deleted after demo
- No persistent data storage
EOF
    
    echo -e "${GREEN}✅ Demo information generated: gcp-demo-info.md${NC}"
}

# Main execution
main() {
    check_prerequisites
    setup_gcp
    create_demo_vms
    setup_firewall
    deploy_grc_toolkit
    generate_demo_info
    
    echo -e "\n${GREEN}🎉 GCP Demo Environment Setup Complete!${NC}"
    echo "=================================="
    echo -e "${BLUE}📋 Next Steps:${NC}"
    echo "1. Review gcp-demo-info.md for VM details"
    echo "2. SSH to GRC Toolkit VM and deploy the application"
    echo "3. Test the demo scenarios with real VMs"
    echo "4. Prepare your conference presentation"
    echo ""
    echo -e "${YELLOW}💰 Cost: ~$0.20/hour for demo environment${NC}"
    echo -e "${YELLOW}⏰ Remember to delete VMs after demo to avoid charges${NC}"
}

# Run main function
main "$@"

