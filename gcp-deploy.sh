#!/bin/bash

# Olym3 Testnet Season 3 - GCP Deployment Script
# Author: Olym3 Labs DevOps Team

set -e  # Exit on any error

# Configuration
PROJECT_ID="your-gcp-project-id"  # Change this to your GCP project ID
INSTANCE_NAME="olym3-erigon-node"
ZONE="us-central1-a"  # Change to your preferred zone
MACHINE_TYPE="e2-standard-8"
DISK_SIZE="1000GB"
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if gcloud is installed
check_gcloud() {
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first:"
        echo "https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
}

# Check if user is authenticated
check_auth() {
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "You are not authenticated with gcloud. Please run:"
        echo "gcloud auth login"
        exit 1
    fi
}

# Set project
set_project() {
    print_status "Setting GCP project to: $PROJECT_ID"
    gcloud config set project $PROJECT_ID
}

# Create startup script for VM
create_startup_script() {
    print_status "Creating startup script for VM..."
    
    cat > startup-script.sh << 'EOF'
#!/bin/bash

# Olym3 Testnet Season 3 - VM Startup Script
# This script runs when the VM starts up

set -e

# Update system
apt update && apt upgrade -y

# Install dependencies
apt install -y \
    build-essential \
    git \
    curl \
    wget \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    openssl

# Install Go 1.21
if ! command -v go &> /dev/null; then
    wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/ubuntu/.bashrc
    export PATH=$PATH:/usr/local/go/bin
    rm go1.21.5.linux-amd64.tar.gz
fi

# Create erigon data directory
mkdir -p /home/ubuntu/erigon_data

# Clone and build Erigon
cd /home/ubuntu
if [ ! -d "erigon" ]; then
    git clone https://github.com/ledgerwatch/erigon.git
    cd erigon
else
    cd erigon
    git pull origin main
fi

# Build Erigon
make erigon

# Create genesis.json for Olym3 Testnet Season 3
cat > /home/ubuntu/genesis.json << 'GENESIS_EOF'
{
  "config": {
    "chainId": 256003,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip150Hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "muirGlacierBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0,
    "arrowGlacierBlock": 0,
    "grayGlacierBlock": 0,
    "mergeForkBlock": 0,
    "terminalTotalDifficulty": 0,
    "shanghaiTime": 0,
    "cancunTime": 0,
    "pragueTime": 0,
    "terminalTotalDifficultyPassed": true
  },
  "difficulty": "0x1",
  "gasLimit": "0x1c9c380",
  "extraData": "0x4f6c796d3320546573746e657420536561736f6e2033",
  "alloc": {
    "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6": {
      "balance": "0x1000000000000000000000000000000000000000000000000000000000000000"
    },
    "0x8ba1f109551bD432803012645Hac136c772c3e3": {
      "balance": "0x1000000000000000000000000000000000000000000000000000000000000000"
    },
    "0x147B8eb97fD247D06C4006D269c90C1908Fb5D54": {
      "balance": "0x1000000000000000000000000000000000000000000000000000000000000000"
    },
    "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db": {
      "balance": "0x1000000000000000000000000000000000000000000000000000000000000000"
    },
    "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB": {
      "balance": "0x1000000000000000000000000000000000000000000000000000000000000000"
    }
  },
  "baseFeePerGas": "0x3b9aca00",
  "number": "0x0",
  "gasUsed": "0x0",
  "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "timestamp": "0x0"
}
GENESIS_EOF

# Initialize chain with genesis
/home/ubuntu/erigon/build/bin/erigon init /home/ubuntu/genesis.json --datadir /home/ubuntu/erigon_data

# Generate JWT secret for Engine API
openssl rand -hex 32 > /home/ubuntu/jwt.hex
chmod 600 /home/ubuntu/jwt.hex

# Create systemd service file
cat > /etc/systemd/system/erigon.service << 'SERVICE_EOF'
[Unit]
Description=Olym3 Testnet Season 3 Erigon Node
After=network.target
Wants=network.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/home/ubuntu/erigon/build/bin/erigon \\
    --datadir=/home/ubuntu/erigon_data \\
    --chain=olym3-testnet-s3 \\
    --http \\
    --http.addr=0.0.0.0 \\
    --http.port=8545 \\
    --http.api=engine,eth,net,web3,debug,txpool,admin \\
    --http.corsdomain=* \\
    --http.vhosts=* \\
    --ws \\
    --ws.addr=0.0.0.0 \\
    --ws.port=8546 \\
    --ws.api=engine,eth,net,web3,debug,txpool,admin \\
    --ws.origins=* \\
    --authrpc.addr=0.0.0.0 \\
    --authrpc.port=8551 \\
    --authrpc.jwtsecret=/home/ubuntu/jwt.hex \\
    --authrpc.vhosts=* \\
    --port=30303 \\
    --discovery.port=30303 \\
    --metrics \\
    --metrics.addr=0.0.0.0 \\
    --metrics.port=6060 \\
    --torrent.port=42069 \\
    --private.api.addr=localhost:9090 \\
    --log.console.verbosity=3 \\
    --log.file.verbosity=3 \\
    --log.console.json=false \\
    --log.file.json=false

Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=erigon

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/home/ubuntu/erigon_data

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable erigon.service

# Create startup script
cat > /home/ubuntu/start-erigon.sh << 'START_EOF'
#!/bin/bash
# Olym3 Testnet Season 3 - Manual Erigon Start Script

echo "Starting Olym3 Testnet Season 3 Erigon Node..."

/home/ubuntu/erigon/build/bin/erigon \
    --datadir=/home/ubuntu/erigon_data \
    --chain=olym3-testnet-s3 \
    --http \
    --http.addr=0.0.0.0 \
    --http.port=8545 \
    --http.api=engine,eth,net,web3,debug,txpool,admin \
    --http.corsdomain=* \
    --http.vhosts=* \
    --ws \
    --ws.addr=0.0.0.0 \
    --ws.port=8546 \
    --ws.api=engine,eth,net,web3,debug,txpool,admin \
    --ws.origins=* \
    --authrpc.addr=0.0.0.0 \
    --authrpc.port=8551 \
    --authrpc.jwtsecret=/home/ubuntu/jwt.hex \
    --authrpc.vhosts=* \
    --port=30303 \
    --discovery.port=30303 \
    --metrics \
    --metrics.addr=0.0.0.0 \
    --metrics.port=6060 \
    --torrent.port=42069 \
    --private.api.addr=localhost:9090 \
    --log.console.verbosity=3 \
    --log.file.verbosity=3 \
    --log.console.json=false \
    --log.file.json=false
START_EOF

chmod +x /home/ubuntu/start-erigon.sh

# Create status check script
cat > /home/ubuntu/check-erigon.sh << 'CHECK_EOF'
#!/bin/bash
# Olym3 Testnet Season 3 - Erigon Status Check Script

echo "=== Olym3 Testnet Season 3 Erigon Status ==="
echo "Chain ID: 256003"
echo "Chain Name: olym3-testnet-s3"
echo ""

echo "Service Status:"
systemctl status erigon.service --no-pager -l

echo ""
echo "Process Status:"
ps aux | grep erigon | grep -v grep

echo ""
echo "Port Status:"
echo "P2P (30303):"
netstat -tlnp | grep :30303 || echo "Not listening"
echo "HTTP RPC (8545):"
netstat -tlnp | grep :8545 || echo "Not listening"
echo "WebSocket (8546):"
netstat -tlnp | grep :8546 || echo "Not listening"
echo "Engine API (8551):"
netstat -tlnp | grep :8551 || echo "Not listening"
echo "Metrics (6060):"
netstat -tlnp | grep :6060 || echo "Not listening"

echo ""
echo "Data Directory:"
ls -la /home/ubuntu/erigon_data/

echo ""
echo "Logs (last 20 lines):"
journalctl -u erigon.service -n 20 --no-pager
CHECK_EOF

chmod +x /home/ubuntu/check-erigon.sh

# Create configuration summary
cat > /home/ubuntu/erigon-config-summary.txt << 'SUMMARY_EOF'
=== Olym3 Testnet Season 3 Erigon Configuration ===

Chain Configuration:
- Chain ID: 256003
- Chain Name: olym3-testnet-s3
- Genesis File: /home/ubuntu/genesis.json
- Data Directory: /home/ubuntu/erigon_data

Network Ports:
- P2P: 30303
- HTTP RPC: 8545
- WebSocket: 8546
- Engine API: 8551
- Metrics: 6060
- Torrent: 42069
- Private API: 9090

API Endpoints:
- HTTP RPC: http://EXTERNAL_IP:8545
- WebSocket: ws://EXTERNAL_IP:8546
- Engine API: http://EXTERNAL_IP:8551
- Metrics: http://EXTERNAL_IP:6060

Available APIs:
- engine, eth, net, web3, debug, txpool, admin

Service Management:
- Start: sudo systemctl start erigon
- Stop: sudo systemctl stop erigon
- Restart: sudo systemctl restart erigon
- Status: sudo systemctl status erigon
- Logs: sudo journalctl -u erigon -f

Manual Start:
- ./start-erigon.sh

Status Check:
- ./check-erigon.sh

JWT Secret: /home/ubuntu/jwt.hex (for Engine API authentication)

Pre-funded Addresses (1000 ETH each):
- 0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6
- 0x8ba1f109551bD432803012645Hac136c772c3e3
- 0x147B8eb97fD247D06C4006D269c90C1908Fb5D54
- 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
- 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
SUMMARY_EOF

# Start the Erigon service
systemctl start erigon.service

# Create completion marker
echo "Olym3 Testnet Season 3 Erigon setup completed at $(date)" > /home/ubuntu/setup-completed.txt
EOF

    chmod +x startup-script.sh
}

# Create firewall rules
create_firewall_rules() {
    print_status "Creating firewall rules..."
    
    # Create firewall rule for P2P traffic
    gcloud compute firewall-rules create olym3-p2p \
        --direction=INGRESS \
        --priority=1000 \
        --network=default \
        --action=ALLOW \
        --rules=tcp:30303,udp:30303 \
        --source-ranges=0.0.0.0/0 \
        --target-tags=olym3-node \
        --description="Olym3 Testnet Season 3 P2P ports" \
        --quiet || print_warning "Firewall rule olym3-p2p already exists"
    
    # Create firewall rule for RPC endpoints
    gcloud compute firewall-rules create olym3-rpc \
        --direction=INGRESS \
        --priority=1001 \
        --network=default \
        --action=ALLOW \
        --rules=tcp:8545,tcp:8546,tcp:8551,tcp:6060 \
        --source-ranges=0.0.0.0/0 \
        --target-tags=olym3-node \
        --description="Olym3 Testnet Season 3 RPC ports" \
        --quiet || print_warning "Firewall rule olym3-rpc already exists"
}

# Create VM instance
create_vm_instance() {
    print_status "Creating VM instance..."
    
    gcloud compute instances create $INSTANCE_NAME \
        --zone=$ZONE \
        --machine-type=$MACHINE_TYPE \
        --image-family=$IMAGE_FAMILY \
        --image-project=$IMAGE_PROJECT \
        --boot-disk-size=$DISK_SIZE \
        --boot-disk-type=pd-ssd \
        --tags=olym3-node \
        --metadata-from-file=startup-script=startup-script.sh \
        --metadata=enable-oslogin=TRUE \
        --maintenance-policy=MIGRATE \
        --provisioning-model=STANDARD \
        --service-account=default \
        --scopes=https://www.googleapis.com/auth/cloud-platform \
        --create-disk=auto-delete=yes,boot=yes,device-name=$INSTANCE_NAME,image=projects/$IMAGE_PROJECT/global/images/family/$IMAGE_FAMILY,mode=rw,size=$DISK_SIZE,type=projects/$PROJECT_ID/zones/$ZONE/diskTypes/pd-ssd \
        --no-shielded-secure-boot \
        --shielded-vtpm \
        --shielded-integrity-monitoring \
        --reservation-affinity=any
}

# Get instance information
get_instance_info() {
    print_status "Getting instance information..."
    
    EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
    
    print_header "Instance Information"
    echo "Instance Name: $INSTANCE_NAME"
    echo "Zone: $ZONE"
    echo "Machine Type: $MACHINE_TYPE"
    echo "External IP: $EXTERNAL_IP"
    echo ""
    echo "API Endpoints:"
    echo "HTTP RPC: http://$EXTERNAL_IP:8545"
    echo "WebSocket: ws://$EXTERNAL_IP:8546"
    echo "Engine API: http://$EXTERNAL_IP:8551"
    echo "Metrics: http://$EXTERNAL_IP:6060"
    echo ""
    echo "SSH Command:"
    echo "gcloud compute ssh $INSTANCE_NAME --zone=$ZONE"
}

# Main deployment function
deploy() {
    print_header "Olym3 Testnet Season 3 GCP Deployment"
    
    # Check prerequisites
    check_gcloud
    check_auth
    
    # Set project
    set_project
    
    # Create startup script
    create_startup_script
    
    # Create firewall rules
    create_firewall_rules
    
    # Create VM instance
    create_vm_instance
    
    # Get instance information
    get_instance_info
    
    print_status "Deployment completed successfully!"
    print_warning "The Erigon node will take some time to build and start. You can monitor the progress by SSHing into the instance."
    print_status "To check the setup progress: gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='tail -f /var/log/syslog'"
}

# Cleanup function
cleanup() {
    print_header "Cleaning up deployment resources"
    
    read -p "Are you sure you want to delete the VM instance and firewall rules? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deleting VM instance..."
        gcloud compute instances delete $INSTANCE_NAME --zone=$ZONE --quiet || true
        
        print_status "Deleting firewall rules..."
        gcloud compute firewall-rules delete olym3-p2p --quiet || true
        gcloud compute firewall-rules delete olym3-rpc --quiet || true
        
        print_status "Cleanup completed!"
    else
        print_status "Cleanup cancelled."
    fi
}

# Show usage
usage() {
    echo "Usage: $0 [deploy|cleanup|info]"
    echo ""
    echo "Commands:"
    echo "  deploy   - Deploy Olym3 Testnet Season 3 Erigon node on GCP"
    echo "  cleanup  - Clean up deployment resources"
    echo "  info     - Show instance information"
    echo ""
    echo "Configuration:"
    echo "  PROJECT_ID: $PROJECT_ID"
    echo "  INSTANCE_NAME: $INSTANCE_NAME"
    echo "  ZONE: $ZONE"
    echo "  MACHINE_TYPE: $MACHINE_TYPE"
    echo ""
    echo "Before running, please:"
    echo "1. Update PROJECT_ID in this script"
    echo "2. Ensure you have gcloud CLI installed and authenticated"
    echo "3. Enable Compute Engine API in your GCP project"
}

# Main script logic
case "${1:-}" in
    "deploy")
        deploy
        ;;
    "cleanup")
        cleanup
        ;;
    "info")
        get_instance_info
        ;;
    *)
        usage
        exit 1
        ;;
esac
