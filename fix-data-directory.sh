#!/bin/bash

# Fix Data Directory for Olym3 Testnet Season 3
# This script will ensure Erigon uses the correct data directory

set -e

echo "🔧 Fixing Data Directory for Olym3 Testnet Season 3..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
fi

print_status "Stopping Erigon service..."
systemctl stop erigon || true

print_status "Checking current data directories..."
echo "Default data directory: /root/.local/share/erigon/chaindata"
echo "Custom data directory: /root/erigon_data"

if [[ -d "/root/.local/share/erigon/chaindata" ]]; then
    print_warning "Found default data directory with old Chain ID"
    ls -la /root/.local/share/erigon/chaindata/
fi

if [[ -d "/root/erigon_data" ]]; then
    print_status "Found custom data directory"
    ls -la /root/erigon_data/
fi

print_status "Removing old data directories..."
rm -rf /root/.local/share/erigon/chaindata
rm -rf /root/erigon_data

print_status "Creating fresh data directory..."
mkdir -p /root/erigon_data

print_status "Re-initializing chain with correct genesis..."
cd /root/erigon
./erigon init /root/genesis.json --datadir /root/erigon_data

print_status "Updating systemd service file..."
cat > /etc/systemd/system/erigon.service << 'EOF'
[Unit]
Description=Olym3 Testnet Season 3 Erigon Node
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/root/erigon
ExecStart=/root/erigon/erigon \
    --datadir=/root/erigon_data \
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
    --authrpc.jwtsecret=/root/jwt.hex \
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

Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=erigon

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/root/erigon_data

[Install]
WantedBy=multi-user.target
EOF

print_status "Reloading systemd daemon..."
systemctl daemon-reload

print_status "Starting Erigon service..."
systemctl start erigon

print_status "Waiting for service to start..."
sleep 10

print_status "Verifying Chain ID..."
for i in {1..15}; do
    NEW_CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
      --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
      http://localhost:8545 2>/dev/null | jq -r '.result' || echo "Failed")
    
    if [[ "$NEW_CHAIN_ID" != "Failed" ]]; then
        NEW_DEC=$(printf "%d" "$NEW_CHAIN_ID")
        echo "Chain ID: $NEW_DEC (0x$NEW_CHAIN_ID)"
        
        if [[ "$NEW_DEC" == "256003" ]]; then
            print_status "✓ Chain ID is now correct: 256003"
            break
        else
            print_warning "Chain ID still wrong: $NEW_DEC (expected 256003)"
            if [[ $i -eq 15 ]]; then
                print_error "Failed to set correct Chain ID after 15 attempts"
                print_status "Checking service logs..."
                journalctl -u erigon -n 20 --no-pager
                exit 1
            fi
            sleep 3
        fi
    else
        print_warning "Service not responding, waiting... (attempt $i/15)"
        sleep 3
    fi
done

print_status "Testing APIs..."

# Test block number
BLOCK_NUMBER=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "Failed")

if [[ "$BLOCK_NUMBER" != "Failed" ]]; then
    BLOCK_DEC=$(printf "%d" "$BLOCK_NUMBER")
    echo "✓ Block Number: $BLOCK_DEC"
else
    echo "✗ Failed to get block number"
fi

# Test client version
CLIENT_VERSION=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "Failed")

if [[ "$CLIENT_VERSION" != "Failed" ]]; then
    echo "✓ Client Version: $CLIENT_VERSION"
else
    echo "✗ Failed to get client version"
fi

print_status "Checking service status..."
systemctl status erigon --no-pager -l

print_status "Checking data directory..."
if [[ -d "/root/erigon_data" ]]; then
    echo "✓ Data directory: /root/erigon_data"
    echo "  Size: $(du -sh /root/erigon_data 2>/dev/null | cut -f1)"
    echo "  Contents:"
    ls -la /root/erigon_data/ | head -5
else
    echo "✗ Data directory not found"
fi

print_status "✅ Data directory fix completed!"
echo ""
echo "🎉 Olym3 Testnet Season 3 is now running with:"
echo "   - Chain ID: 256003"
echo "   - Data Directory: /root/erigon_data"
echo "   - Genesis File: /root/genesis.json"
echo "   - Service: erigon (systemctl status erigon)"
echo ""
echo "Quick test:"
echo "  curl -X POST -H \"Content-Type: application/json\" \\"
echo "    --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_chainId\",\"params\":[],\"id\":1}' \\"
echo "    http://localhost:8545"
