# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Repository Overview

This repository manages a K3s Kubernetes cluster deployment on Raspberry Pi nodes using k3sup. The cluster consists of 9 nodes (pi01-pi09) with a 3-node highly available control plane and 6 worker nodes. The setup is automated through shell scripts and configured for the domain `pi3s.pangarabbit.com`.

## Common Commands

### Initial Cluster Setup
```bash
# Run the complete cluster setup (creates control plane and joins all nodes)
./k3sup.sh
```

### Cluster Management
```bash
# Check cluster status
kubectl --kubeconfig kubeconfig get nodes

# Get detailed node information
kubectl --kubeconfig kubeconfig describe nodes

# View all pods across namespaces
kubectl --kubeconfig kubeconfig get pods -A

# Check K3s version on a specific node
ssh tvl@192.168.0.48 'k3s --version'

# Retrieve node token from primary server
k3sup node-token --host 192.168.0.48 --user tvl
```

### Adding New Nodes
```bash
# First, get the node token
export NODE_TOKEN="$(k3sup node-token --host 192.168.0.48 --user tvl)"

# Join a new worker node
k3sup join \
  --host <NEW_NODE_IP> \
  --server-host 192.168.0.48 \
  --node-token "$NODE_TOKEN" \
  --user tvl

# Join a new control plane node
k3sup join \
  --host <NEW_NODE_IP> \
  --server-host 192.168.0.48 \
  --server \
  --node-token "$NODE_TOKEN" \
  --user tvl \
  --k3s-extra-args "--disable traefik --disable=servicelb"
```

### Node Maintenance
```bash
# SSH into any node
ssh tvl@<NODE_IP>

# Check K3s service status on a node
ssh tvl@<NODE_IP> 'sudo systemctl status k3s'

# View K3s logs on a node
ssh tvl@<NODE_IP> 'sudo journalctl -u k3s -f'

# Restart K3s on a node
ssh tvl@<NODE_IP> 'sudo systemctl restart k3s'
```

## Cluster Architecture

### Node Layout
- **Control Plane (HA)**: pi01 (192.168.0.48), pi02 (192.168.0.107), pi03 (192.168.0.141)
  - Tainted with `node-role.kubernetes.io/master=true:NoSchedule`
  - Run with `--server` flag to form HA control plane
  - Disabled components: traefik, servicelb

- **Worker Nodes**: pi04-pi09
  - pi04: 192.168.0.149
  - pi05: 192.168.0.115
  - pi06: 192.168.0.23
  - pi07: 192.168.0.93
  - pi08: 192.168.0.114
  - pi09: 192.168.0.57
  - Note: Some worker IPs appear duplicated in k3sup.sh (likely needs cleanup)

### Network Configuration
- **Primary Server**: 192.168.0.48 (pi01)
- **API Server**: https://pi3s.pangarabbit.com:6443
- **Additional TLS SANs**: 
  - 192.168.0.48
  - 192.168.191.177
  - 192.168.191.42
  - 192.168.191.82
  - pi3s.pangarabbit.com
- **SSH User**: tvl (passwordless SSH key authentication required)
- **SSH Key Path**: ~/.ssh/id_rsa

### K3s Configuration
- **Disabled Components**: traefik, servicelb (custom ingress/load balancer expected)
- **Kubeconfig**: Stored locally as `kubeconfig` with context name `pi3s`
- **Write Mode**: 0644 for kubeconfig files
- **Debug Mode**: Enabled in config.yaml
- **Node Labels**: cluster=pi3s (defined in config.yaml but not applied in script)

## Key Files

- **k3sup.sh**: Main deployment script that sets up the entire cluster
- **config.yaml**: K3s server configuration (note: not directly used by k3sup.sh, may be for manual K3s configuration)
- **host.json**: Node inventory with taint definitions
- **kubeconfig**: Generated kubectl configuration file (mode 600, do not commit)

## Important Notes

1. **SSH Access**: Ensure passwordless SSH is configured for user `tvl` to all nodes before running setup
2. **Firewall**: Ports 6443 (API server) and 10250 (kubelet) must be open between nodes
3. **Node Token**: Automatically fetched during setup, required for joining additional nodes
4. **Duplicated IPs**: The k3sup.sh script has duplicate worker node entries (workers 1-3 and 4-6 have same IPs) - verify before running
5. **TLS Certificates**: Custom SANs configured for multiple IPs and domain name
6. **Missing User**: Worker 6 (line 74) is missing the --user flag in k3sup.sh

## Troubleshooting

If a node fails to join:
1. Check SSH connectivity: `ssh tvl@<NODE_IP>`
2. Verify K3s installation: `ssh tvl@<NODE_IP> 'which k3s'`
3. Check for existing K3s installation: `ssh tvl@<NODE_IP> 'sudo k3s-uninstall.sh'` (if reinstalling)
4. Ensure firewall allows required ports
5. Check system logs: `ssh tvl@<NODE_IP> 'sudo journalctl -xe'`

If the cluster is not accessible:
1. Verify kubeconfig exists and has correct permissions
2. Check API server is running: `curl -k https://192.168.0.48:6443`
3. Ensure TLS SANs include the domain/IP you're connecting from
4. Verify network connectivity to primary server
