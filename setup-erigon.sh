#!/bin/bash

# Olym3 Testnet Season 3 - Erigon Setup Script
# ChainID: 256003
# Author: Olym3 Labs DevOps Team

set -e  # Exit on any error

echo "🚀 Starting Olym3 Testnet Season 3 Erigon Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Update system packages
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
print_status "Installing dependencies..."
sudo apt install -y \
    build-essential \
    git \
    curl \
    wget \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Go 1.21
print_status "Installing Go 1.21..."
if ! command -v go &> /dev/null; then
    wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin
    rm go1.21.5.linux-amd64.tar.gz
else
    print_warning "Go is already installed"
fi

# Verify Go installation
print_status "Verifying Go installation..."
go version

# Create erigon data directory
print_status "Creating Erigon data directory..."
mkdir -p ~/erigon_data

# Clone Erigon repository
print_status "Cloning Erigon repository..."
cd ~
if [ ! -d "erigon" ]; then
    git clone https://github.com/ledgerwatch/erigon.git
    cd erigon
else
    cd erigon
    git pull origin main
fi

# Build Erigon
print_status "Building Erigon..."
make erigon

# Verify build
print_status "Verifying Erigon build..."
./build/bin/erigon --version

# Create genesis.json for Olym3 Testnet Season 3
print_status "Creating genesis.json for Olym3 Testnet Season 3..."
cat > ~/genesis.json << 'EOF'
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
EOF

# Initialize chain with genesis
print_status "Initializing chain with genesis..."
~/erigon/build/bin/erigon init ~/genesis.json --datadir ~/erigon_data

# Generate JWT secret for Engine API
print_status "Generating JWT secret for Engine API..."
openssl rand -hex 32 > ~/jwt.hex
chmod 600 ~/jwt.hex

# Create systemd service file
print_status "Creating systemd service file..."
sudo tee /etc/systemd/system/erigon.service > /dev/null << EOF
[Unit]
Description=Olym3 Testnet Season 3 Erigon Node
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=/home/$USER
ExecStart=/home/$USER/erigon/build/bin/erigon \\
    --datadir=/home/$USER/erigon_data \\
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
    --authrpc.jwtsecret=/home/$USER/jwt.hex \\
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
ReadWritePaths=/home/$USER/erigon_data

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
print_status "Enabling Erigon service..."
sudo systemctl daemon-reload
sudo systemctl enable erigon.service

# Create startup script
print_status "Creating startup script..."
cat > ~/start-erigon.sh << 'EOF'
#!/bin/bash
# Olym3 Testnet Season 3 - Manual Erigon Start Script

echo "Starting Olym3 Testnet Season 3 Erigon Node..."

~/erigon/build/bin/erigon \
    --datadir=~/erigon_data \
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
    --authrpc.jwtsecret=~/jwt.hex \
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
EOF

chmod +x ~/start-erigon.sh

# Create status check script
print_status "Creating status check script..."
cat > ~/check-erigon.sh << 'EOF'
#!/bin/bash
# Olym3 Testnet Season 3 - Erigon Status Check Script

echo "=== Olym3 Testnet Season 3 Erigon Status ==="
echo "Chain ID: 256003"
echo "Chain Name: olym3-testnet-s3"
echo ""

echo "Service Status:"
sudo systemctl status erigon.service --no-pager -l

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
ls -la ~/erigon_data/

echo ""
echo "Logs (last 20 lines):"
sudo journalctl -u erigon.service -n 20 --no-pager
EOF

chmod +x ~/check-erigon.sh

# Create configuration summary
print_status "Creating configuration summary..."
cat > ~/erigon-config-summary.txt << EOF
=== Olym3 Testnet Season 3 Erigon Configuration ===

Chain Configuration:
- Chain ID: 256003
- Chain Name: olym3-testnet-s3
- Genesis File: ~/genesis.json
- Data Directory: ~/erigon_data

Network Ports:
- P2P: 30303
- HTTP RPC: 8545
- WebSocket: 8546
- Engine API: 8551
- Metrics: 6060
- Torrent: 42069
- Private API: 9090

API Endpoints:
- HTTP RPC: http://YOUR_IP:8545
- WebSocket: ws://YOUR_IP:8546
- Engine API: http://YOUR_IP:8551
- Metrics: http://YOUR_IP:6060

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

JWT Secret: ~/jwt.hex (for Engine API authentication)

Pre-funded Addresses (1000 ETH each):
- 0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6
- 0x8ba1f109551bD432803012645Hac136c772c3e3
- 0x147B8eb97fD247D06C4006D269c90C1908Fb5D54
- 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
- 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB

EOF

print_status "Setup completed successfully!"
print_status "Configuration summary saved to: ~/erigon-config-summary.txt"
print_status "To start Erigon service: sudo systemctl start erigon"
print_status "To check status: ./check-erigon.sh"
print_status "To view logs: sudo journalctl -u erigon -f"

echo ""
echo "🎉 Olym3 Testnet Season 3 Erigon setup completed!"
echo "📋 Check ~/erigon-config-summary.txt for configuration details"
