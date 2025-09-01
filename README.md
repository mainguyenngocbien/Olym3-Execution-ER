# Olym3 Testnet Season 3 - Erigon Deployment

## 🚀 Overview

This repository contains deployment scripts for Olym3 Testnet Season 3 using Erigon as the execution layer client.

### Chain Configuration
- **Chain ID**: 256003
- **Chain Name**: olym3-testnet-s3
- **Client**: Erigon (latest)
- **Genesis**: Custom genesis with 5 pre-funded addresses (1000 ETH each)

## 📁 Files

- `setup-erigon.sh` - Erigon setup script for Ubuntu 22.04
- `gcp-deploy.sh` - GCP deployment script with VM creation
- `README.md` - This documentation

## 🛠️ Prerequisites

### For Local Setup
- Ubuntu 22.04 LTS
- sudo privileges
- Internet connection

### For GCP Deployment
- Google Cloud Platform account
- gcloud CLI installed and authenticated
- Compute Engine API enabled
- Sufficient quota for VM creation

## 🚀 Quick Start

### Option 1: Local Setup

1. **Clone this repository:**
```bash
git clone <repository-url>
cd olym3-deployment
```

2. **Make scripts executable:**
```bash
chmod +x setup-erigon.sh
chmod +x gcp-deploy.sh
```

3. **Run the setup script:**
```bash
./setup-erigon.sh
```

4. **Start the Erigon service:**
```bash
sudo systemctl start erigon
```

5. **Check status:**
```bash
./check-erigon.sh
```

### Option 2: GCP Deployment

1. **Update configuration in `gcp-deploy.sh`:**
```bash
# Edit the PROJECT_ID variable
PROJECT_ID="your-gcp-project-id"
```

2. **Deploy to GCP:**
```bash
./gcp-deploy.sh deploy
```

3. **Monitor deployment:**
```bash
# Get instance info
./gcp-deploy.sh info

# SSH into instance to check progress
gcloud compute ssh olym3-erigon-node --zone=us-central1-a
```

## 📋 Configuration Details

### Genesis Configuration
```json
{
  "config": {
    "chainId": 256003,
    "terminalTotalDifficulty": 0,
    "terminalTotalDifficultyPassed": true
  },
  "gasLimit": "0x1c9c380",
  "baseFeePerGas": "0x3b9aca00",
  "extraData": "0x4f6c796d3320546573746e657420536561736f6e2033"
}
```

### Pre-funded Addresses
Each address starts with 1000 ETH (1000000000000000000000000000000000000000000000000000000000000000 wei):

- `0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6`
- `0x8ba1f109551bD432803012645Hac136c772c3e3`
- `0x147B8eb97fD247D06C4006D269c90C1908Fb5D54`
- `0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db`
- `0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB`

### Network Ports
- **P2P**: 30303 (TCP/UDP)
- **HTTP RPC**: 8545
- **WebSocket**: 8546
- **Engine API**: 8551
- **Metrics**: 6060
- **Torrent**: 42069
- **Private API**: 9090

### API Endpoints
- **HTTP RPC**: `http://YOUR_IP:8545`
- **WebSocket**: `ws://YOUR_IP:8546`
- **Engine API**: `http://YOUR_IP:8551`
- **Metrics**: `http://YOUR_IP:6060`

### Available APIs
- `engine` - Engine API for consensus layer communication
- `eth` - Ethereum JSON-RPC API
- `net` - Network information
- `web3` - Web3 client version
- `debug` - Debugging utilities
- `txpool` - Transaction pool information
- `admin` - Administrative functions

## 🔧 Management Commands

### Service Management
```bash
# Start Erigon
sudo systemctl start erigon

# Stop Erigon
sudo systemctl stop erigon

# Restart Erigon
sudo systemctl restart erigon

# Check status
sudo systemctl status erigon

# View logs
sudo journalctl -u erigon -f
```

### Manual Operations
```bash
# Manual start
./start-erigon.sh

# Status check
./check-erigon.sh

# View configuration
cat ~/erigon-config-summary.txt
```

## 🌐 GCP Deployment Details

### VM Specifications
- **Machine Type**: e2-standard-8 (8 vCPUs, 32 GB RAM)
- **Disk**: 1000 GB SSD
- **OS**: Ubuntu 22.04 LTS
- **Zone**: us-central1-a (configurable)

### Firewall Rules
- **olym3-p2p**: Allows P2P traffic on port 30303
- **olym3-rpc**: Allows RPC traffic on ports 8545, 8546, 8551, 6060

### Deployment Commands
```bash
# Deploy
./gcp-deploy.sh deploy

# Get instance info
./gcp-deploy.sh info

# Cleanup (removes VM and firewall rules)
./gcp-deploy.sh cleanup
```

## 🔍 Monitoring

### Check Node Status
```bash
# Service status
sudo systemctl status erigon

# Process status
ps aux | grep erigon

# Port status
netstat -tlnp | grep erigon

# Data directory
ls -la ~/erigon_data/
```

### View Logs
```bash
# Real-time logs
sudo journalctl -u erigon -f

# Last 100 lines
sudo journalctl -u erigon -n 100

# Logs since boot
sudo journalctl -u erigon -b
```

### Metrics
Access metrics at `http://YOUR_IP:6060` for detailed node metrics.

## 🔐 Security

### JWT Authentication
- JWT secret is automatically generated and stored in `~/jwt.hex`
- Used for Engine API authentication
- File permissions set to 600 (owner read/write only)

### Systemd Security
- `NoNewPrivileges=true` - Prevents privilege escalation
- `PrivateTmp=true` - Uses private /tmp directory
- `ProtectSystem=strict` - Protects system directories
- `ReadWritePaths=/home/$USER/erigon_data` - Only allows access to data directory

## 🐛 Troubleshooting

### Common Issues

1. **Build fails**
   - Ensure sufficient disk space (>10GB free)
   - Check Go installation: `go version`
   - Verify internet connection

2. **Service won't start**
   - Check logs: `sudo journalctl -u erigon -n 50`
   - Verify JWT file exists: `ls -la ~/jwt.hex`
   - Check data directory permissions

3. **Ports not accessible**
   - Verify firewall rules (GCP)
   - Check if service is running: `sudo systemctl status erigon`
   - Test local access: `curl http://localhost:8545`

4. **GCP deployment fails**
   - Verify gcloud authentication: `gcloud auth list`
   - Check project ID in script
   - Ensure Compute Engine API is enabled
   - Check quota limits

### Debug Commands
```bash
# Check system resources
free -h
df -h
top

# Check network connectivity
ping 8.8.8.8
nslookup google.com

# Check service dependencies
systemctl list-dependencies erigon

# Verify file integrity
sha256sum ~/jwt.hex
ls -la ~/erigon_data/
```

## 📞 Support

For issues and questions:
- Check the troubleshooting section above
- Review logs for error messages
- Ensure all prerequisites are met
- Verify network connectivity and firewall rules

## 📄 License

This project is part of Olym3 Labs infrastructure.

---

**Olym3 Labs DevOps Team**  
*Chain ID: 256003 | Testnet Season 3*
