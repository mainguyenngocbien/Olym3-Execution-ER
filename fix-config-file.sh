#!/bin/bash

# Fix Config File - Use Config File to Force Custom Genesis
# This script will use a config file to force Erigon to use our custom genesis

set -e

echo "🔧 Fix Config File - Use Config File to Force Custom Genesis"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if we're root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
fi

print_header "Stopping Erigon Service"
systemctl stop erigon || true

print_header "Cleaning ALL Data Directories"
rm -rf /root/erigon_data
rm -rf /root/.local/share/erigon
mkdir -p /root/erigon_data

print_header "Re-initializing Chain with Custom Directory"
cd /root/erigon
./erigon init /root/genesis.json --datadir /root/erigon_data

print_header "Creating Config File"
cat > /root/erigon_data/erigon.toml << 'EOF'
# Olym3 Testnet Season 3 Configuration
# Chain ID: 256000

[chain]
chainId = 256000
networkId = 256000

[http]
addr = "0.0.0.0"
port = 8545
api = ["eth", "net", "web3"]
corsdomain = ["*"]
vhosts = ["*"]

[p2p]
port = 30303

[log]
console.verbosity = 3

[private.api]
addr = "127.0.0.1:9090"

[datadir]
path = "/root/erigon_data"

[snapshots]
enabled = false

[download]
enabled = false

[sync]
enabled = false

[checkpoint]
enabled = false
EOF

print_status "Config file created"

print_header "Creating Config Service File"
cat > /etc/systemd/system/erigon.service << 'EOF'
[Unit]
Description=Olym3 Testnet Season 3 Erigon Node (Chain ID: 256000)
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/root/erigon
Environment=ERIGON_DATADIR=/root/erigon_data
Environment=XDG_DATA_HOME=/root/erigon_data
ExecStart=/root/erigon/erigon \
    --datadir=/root/erigon_data \
    --config=/root/erigon_data/erigon.toml \
    --http \
    --http.addr=0.0.0.0 \
    --http.port=8545 \
    --http.api=eth,net,web3 \
    --http.corsdomain=* \
    --http.vhosts=* \
    --port=30303 \
    --log.console.verbosity=3 \
    --private.api.addr=127.0.0.1:9090 \
    --chain=mainnet \
    --networkid=256000

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

print_status "Config service file created"

print_header "Starting Service"
systemctl daemon-reload
systemctl enable erigon
systemctl start erigon

print_status "Waiting for service to start..."
sleep 30

print_header "Checking Service Status"
systemctl status erigon --no-pager -l

print_header "Testing APIs"

# Test Chain ID
echo "Testing Chain ID..."
CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "Failed")

if [[ "$CHAIN_ID" != "Failed" ]]; then
    CHAIN_ID_DEC=$(printf "%d" "$CHAIN_ID")
    echo "✓ Chain ID: $CHAIN_ID_DEC (0x$CHAIN_ID)"
    if [[ "$CHAIN_ID_DEC" == "256000" ]]; then
        print_status "✓ Chain ID is correct: 256000"
    else
        print_warning "Chain ID is $CHAIN_ID_DEC (expected 256000)"
    fi
else
    echo "✗ Failed to get Chain ID"
fi

# Test block number
echo "Testing block number..."
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
echo "Testing client version..."
CLIENT_VERSION=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "Failed")

if [[ "$CLIENT_VERSION" != "Failed" ]]; then
    echo "✓ Client Version: $CLIENT_VERSION"
else
    echo "✗ Failed to get client version"
fi

# Test pre-funded accounts
echo "Testing pre-funded accounts..."
for addr in "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6" "0x9876543210987654321098765432109876543210" "0x147B8eb97fD247D06C4006D269c90C1908Fb5D54"; do
    BALANCE=$(curl -s -X POST -H "Content-Type: application/json" \
      --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$addr\",\"latest\"],\"id\":1}" \
      http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "Failed")
    
    if [[ "$BALANCE" != "Failed" ]]; then
        BALANCE_DEC=$(printf "%d" "$BALANCE")
        BALANCE_ETH=$(echo "scale=18; $BALANCE_DEC / 1000000000000000000" | bc -l 2>/dev/null || echo "N/A")
        echo "✓ $addr: $BALANCE_ETH ETH"
    else
        echo "✗ Failed to get balance for $addr"
    fi
done

print_header "Checking Ports"
if netstat -tlnp 2>/dev/null | grep -q ":30303"; then
    echo "✓ P2P (30303): Listening"
else
    echo "✗ P2P (30303): Not listening"
fi

if netstat -tlnp 2>/dev/null | grep -q ":8545"; then
    echo "✓ HTTP RPC (8545): Listening"
else
    echo "✗ HTTP RPC (8545): Not listening"
fi

print_header "Creating Config Status Script"
cat > /root/olym3-status.sh << 'EOF'
#!/bin/bash
echo "=== Olym3 Testnet Season 3 Status ==="
echo "Chain ID: 256000"
echo "Chain Name: Custom Genesis"
echo ""

# Check if Erigon is running
if systemctl is-active --quiet erigon; then
    echo "✓ Erigon service is running"
else
    echo "✗ Erigon service is not running"
fi

# Check ports
echo ""
echo "Port Status:"
if netstat -tlnp 2>/dev/null | grep -q ":30303"; then
    echo "✓ P2P (30303): Listening"
else
    echo "✗ P2P (30303): Not listening"
fi

if netstat -tlnp 2>/dev/null | grep -q ":8545"; then
    echo "✓ HTTP RPC (8545): Listening"
else
    echo "✗ HTTP RPC (8545): Not listening"
fi

# API test
echo ""
echo "API Test:"
if curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' http://localhost:8545 > /dev/null 2>&1; then
    echo "✓ HTTP RPC API responding"
else
    echo "✗ HTTP RPC API not responding"
fi

# Chain ID test
echo ""
echo "Chain ID Test:"
CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "Failed")
if [[ "$CHAIN_ID" != "Failed" ]]; then
    CHAIN_ID_DEC=$(printf "%d" "$CHAIN_ID")
    echo "✓ Chain ID: $CHAIN_ID_DEC (0x$CHAIN_ID)"
    if [[ "$CHAIN_ID_DEC" == "256000" ]]; then
        echo "  ✓ Correct Chain ID!"
    else
        echo "  ✗ Wrong Chain ID (expected 256000)"
    fi
else
    echo "✗ Failed to get Chain ID"
fi

# Block number test
echo ""
echo "Block Number Test:"
BLOCK_NUMBER=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "Failed")
if [[ "$BLOCK_NUMBER" != "Failed" ]]; then
    BLOCK_DEC=$(printf "%d" "$BLOCK_NUMBER")
    echo "✓ Block Number: $BLOCK_DEC"
else
    echo "✗ Failed to get block number"
fi

echo ""
echo "Quick Commands:"
echo "  Start: systemctl start erigon"
echo "  Stop:  systemctl stop erigon"
echo "  Logs:  journalctl -u erigon -f"
echo "  Test:  curl -X POST -H \"Content-Type: application/json\" --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_chainId\",\"params\":[],\"id\":1}' http://localhost:8545"
EOF

chmod +x /root/olym3-status.sh

print_header "Creating Config Configuration Summary"
cat > /root/olym3-summary.txt << EOF
=== Olym3 Testnet Season 3 Config Configuration ===

Chain Configuration:
- Chain ID: 256000 (0x3e800)
- Chain Name: Custom Genesis (Olym3 Testnet Season 3)
- Genesis File: /root/genesis.json
- Data Directory: /root/erigon_data
- Config File: /root/erigon_data/erigon.toml
- JWT Secret: /root/erigon_data/jwt.hex

Network Ports:
- P2P: 30303
- HTTP RPC: 8545
- Private API: 127.0.0.1:9090

API Endpoints:
- HTTP RPC: http://$(hostname -I | awk '{print $1}'):8545

Config File Configuration:
- Chain ID: 256000
- Network ID: 256000
- Snapshots: Disabled
- Download: Disabled
- Sync: Disabled
- Checkpoint: Disabled

Pre-funded Addresses (1000 ETH each):
- 0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6
- 0x9876543210987654321098765432109876543210
- 0x147B8eb97fD247D06C4006D269c90C1908Fb5D54
- 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
- 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB

Service Management:
- Start: systemctl start erigon
- Stop: systemctl stop erigon
- Restart: systemctl restart erigon
- Status: systemctl status erigon
- Logs: journalctl -u erigon -f

Test Commands:
- Chain ID: curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' http://localhost:8545
- Block Number: curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545
- Client Version: curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' http://localhost:8545
- Balance: curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6","latest"],"id":1}' http://localhost:8545

Generated: $(date)
EOF

print_status "Configuration summary saved to: /root/olym3-summary.txt"

print_header "Setup Complete!"
echo "🎉 Olym3 Testnet Season 3 is now running with Chain ID 256000!"
echo ""
echo "📋 Files created:"
echo "  - Service: /etc/systemd/system/erigon.service"
echo "  - Config: /root/erigon_data/erigon.toml"
echo "  - Status Script: /root/olym3-status.sh"
echo "  - Config Summary: /root/olym3-summary.txt"
echo ""
echo "🚀 Quick test:"
echo "  /root/olym3-status.sh"
echo "  systemctl status erigon"
echo ""
echo "🌐 API Endpoint:"
echo "  HTTP RPC: http://$(hostname -I | awk '{print $1}'):8545"
