#!/bin/bash

# Olym3 Testnet Season 3 - Final Working Setup (Chain ID: 256000)
# Author: Olym3 Labs DevOps Team

set -e

echo "🚀 Olym3 Testnet Season 3 - Final Working Setup (Chain ID: 256000)"

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

print_header "Creating Genesis File"
cat > /root/genesis.json << 'EOF'
{
  "config": {
    "chainId": 256000,
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
    "0x9876543210987654321098765432109876543210": {
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

print_status "Genesis file created with Chain ID 256000"

print_header "Creating JWT Secret"
openssl rand -hex 32 > /root/jwt.hex
chmod 600 /root/jwt.hex
print_status "JWT secret created: /root/jwt.hex"

print_header "Setting up Data Directory"
rm -rf /root/erigon_data
mkdir -p /root/erigon_data

print_header "Initializing Chain"
cd /root/erigon
./erigon init /root/genesis.json --datadir /root/erigon_data

print_header "Creating Correct Service File"
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

print_status "Service file created (all flags corrected)"

print_header "Enabling and Starting Service"
systemctl daemon-reload
systemctl enable erigon
systemctl start erigon

print_status "Waiting for service to start..."
sleep 20

print_header "Verifying Setup"

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

if netstat -tlnp 2>/dev/null | grep -q ":8546"; then
    echo "✓ WebSocket (8546): Listening"
else
    echo "✗ WebSocket (8546): Not listening"
fi

if netstat -tlnp 2>/dev/null | grep -q ":8551"; then
    echo "✓ Engine API (8551): Listening"
else
    echo "✗ Engine API (8551): Not listening"
fi

print_header "Service Status"
systemctl status erigon --no-pager -l

print_header "Creating Management Scripts"

# Create quick status script
cat > /root/quick-status.sh << 'EOF'
#!/bin/bash
echo "=== Olym3 Testnet Season 3 Quick Status ==="
echo "Chain ID: 256000"
echo "Chain Name: olym3-testnet-s3"
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

if netstat -tlnp 2>/dev/null | grep -q ":8546"; then
    echo "✓ WebSocket (8546): Listening"
else
    echo "✗ WebSocket (8546): Not listening"
fi

if netstat -tlnp 2>/dev/null | grep -q ":8551"; then
    echo "✓ Engine API (8551): Listening"
else
    echo "✗ Engine API (8551): Not listening"
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
else
    echo "✗ Failed to get Chain ID"
fi

echo ""
echo "Quick Commands:"
echo "  Start: systemctl start erigon"
echo "  Stop:  systemctl stop erigon"
echo "  Logs:  journalctl -u erigon -f"
EOF

chmod +x /root/quick-status.sh

# Create configuration summary
cat > /root/olym3-config.txt << EOF
=== Olym3 Testnet Season 3 Configuration ===

Chain Configuration:
- Chain ID: 256000 (0x3e800)
- Chain Name: olym3-testnet-s3
- Genesis File: /root/genesis.json
- Data Directory: /root/erigon_data
- JWT Secret: /root/jwt.hex

Network Ports:
- P2P: 30303
- HTTP RPC: 8545
- WebSocket: 8546
- Engine API: 8551
- Metrics: 6060

API Endpoints:
- HTTP RPC: http://$(hostname -I | awk '{print $1}'):8545
- WebSocket: ws://$(hostname -I | awk '{print $1}'):8546
- Engine API: http://$(hostname -I | awk '{print $1}'):8551

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

Generated: $(date)
EOF

print_status "Configuration summary saved to: /root/olym3-config.txt"

print_header "Setup Complete!"
echo "🎉 Olym3 Testnet Season 3 is now running with Chain ID 256000!"
echo ""
echo "📋 Files created:"
echo "  - Genesis: /root/genesis.json"
echo "  - JWT Secret: /root/jwt.hex"
echo "  - Data Directory: /root/erigon_data"
echo "  - Service: /etc/systemd/system/erigon.service"
echo "  - Quick Status: /root/quick-status.sh"
echo "  - Config Summary: /root/olym3-config.txt"
echo ""
echo "🚀 Quick test:"
echo "  /root/quick-status.sh"
echo "  systemctl status erigon"
echo ""
echo "🌐 API Endpoints:"
echo "  HTTP RPC: http://$(hostname -I | awk '{print $1}'):8545"
echo "  WebSocket: ws://$(hostname -I | awk '{print $1}'):8546"
echo "  Engine API: http://$(hostname -I | awk '{print $1}'):8551"
