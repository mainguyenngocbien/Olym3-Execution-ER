#!/bin/bash

# Olym3 Testnet Season 3 - Quick Status Check
# Author: Olym3 Labs DevOps Team

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Olym3 Testnet Season 3 Quick Status ===${NC}"
echo "Chain ID: 256003"
echo "Chain Name: olym3-testnet-s3"
echo ""

# Check if Erigon is running
if systemctl is-active --quiet erigon; then
    echo -e "${GREEN}✓ Erigon service is running${NC}"
else
    echo -e "${RED}✗ Erigon service is not running${NC}"
fi

# Check if Erigon process exists
if pgrep -x "erigon" > /dev/null; then
    echo -e "${GREEN}✓ Erigon process is active${NC}"
else
    echo -e "${RED}✗ Erigon process not found${NC}"
fi

# Check ports
echo ""
echo -e "${BLUE}Port Status:${NC}"

# P2P Port
if netstat -tlnp 2>/dev/null | grep -q ":30303"; then
    echo -e "${GREEN}✓ P2P (30303): Listening${NC}"
else
    echo -e "${RED}✗ P2P (30303): Not listening${NC}"
fi

# HTTP RPC Port
if netstat -tlnp 2>/dev/null | grep -q ":8545"; then
    echo -e "${GREEN}✓ HTTP RPC (8545): Listening${NC}"
else
    echo -e "${RED}✗ HTTP RPC (8545): Not listening${NC}"
fi

# WebSocket Port
if netstat -tlnp 2>/dev/null | grep -q ":8546"; then
    echo -e "${GREEN}✓ WebSocket (8546): Listening${NC}"
else
    echo -e "${RED}✗ WebSocket (8546): Not listening${NC}"
fi

# Engine API Port
if netstat -tlnp 2>/dev/null | grep -q ":8551"; then
    echo -e "${GREEN}✓ Engine API (8551): Listening${NC}"
else
    echo -e "${RED}✗ Engine API (8551): Not listening${NC}"
fi

# Metrics Port
if netstat -tlnp 2>/dev/null | grep -q ":6060"; then
    echo -e "${GREEN}✓ Metrics (6060): Listening${NC}"
else
    echo -e "${RED}✗ Metrics (6060): Not listening${NC}"
fi

# Check data directory
echo ""
echo -e "${BLUE}Data Directory:${NC}"
if [ -d "$HOME/erigon_data" ]; then
    echo -e "${GREEN}✓ Data directory exists${NC}"
    echo "  Location: $HOME/erigon_data"
    echo "  Size: $(du -sh $HOME/erigon_data 2>/dev/null | cut -f1 || echo 'Unknown')"
else
    echo -e "${RED}✗ Data directory not found${NC}"
fi

# Check JWT file
echo ""
echo -e "${BLUE}JWT Secret:${NC}"
if [ -f "$HOME/jwt.hex" ]; then
    echo -e "${GREEN}✓ JWT secret exists${NC}"
    echo "  Location: $HOME/jwt.hex"
    echo "  Permissions: $(ls -la $HOME/jwt.hex | awk '{print $1}')"
else
    echo -e "${RED}✗ JWT secret not found${NC}"
fi

# Check genesis file
echo ""
echo -e "${BLUE}Genesis File:${NC}"
if [ -f "$HOME/genesis.json" ]; then
    echo -e "${GREEN}✓ Genesis file exists${NC}"
    echo "  Location: $HOME/genesis.json"
else
    echo -e "${RED}✗ Genesis file not found${NC}"
fi

# Quick API test
echo ""
echo -e "${BLUE}API Test:${NC}"
if curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' http://localhost:8545 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ HTTP RPC API responding${NC}"
else
    echo -e "${RED}✗ HTTP RPC API not responding${NC}"
fi

# System resources
echo ""
echo -e "${BLUE}System Resources:${NC}"
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Memory Usage: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
echo "Disk Usage: $(df -h / | awk 'NR==2 {print $5}')"

# Recent logs
echo ""
echo -e "${BLUE}Recent Logs (last 5 lines):${NC}"
if systemctl is-active --quiet erigon; then
    journalctl -u erigon -n 5 --no-pager 2>/dev/null | while IFS= read -r line; do
        echo "  $line"
    done
else
    echo "  No logs available (service not running)"
fi

echo ""
echo -e "${BLUE}Quick Commands:${NC}"
echo "  Start service: sudo systemctl start erigon"
echo "  Stop service:  sudo systemctl stop erigon"
echo "  View logs:     sudo journalctl -u erigon -f"
echo "  Full status:   ./check-erigon.sh"
echo "  Manual start:  ./start-erigon.sh"

echo ""
echo -e "${BLUE}API Endpoints:${NC}"
echo "  HTTP RPC:     http://$(hostname -I | awk '{print $1}'):8545"
echo "  WebSocket:    ws://$(hostname -I | awk '{print $1}'):8546"
echo "  Engine API:   http://$(hostname -I | awk '{print $1}'):8551"
echo "  Metrics:      http://$(hostname -I | awk '{print $1}'):6060"
