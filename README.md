# K3sUp Setup Guide

## Overview

This guide will help you set up a lightweight Kubernetes cluster using [k3sup](https://github.com/alexellis/k3sup). The script automates the installation of K3s on multiple nodes, setting up a primary server and joining additional nodes.

## Prerequisites

Before running the script, ensure you have the following:

- A set of Linux servers (e.g., cloud VMs or Raspberry Pis) with SSH access
- SSH key-based authentication set up for the user running the script
- `k3sup` installed on your local machine ([Installation Guide](https://github.com/alexellis/k3sup#download))

## Script Breakdown

### 1. Install the Primary Server

The script installs K3s on the primary server with TLS settings and saves the kubeconfig locally:

```sh
echo "Setting up primary server 1"
k3sup install --host <PRIMARY_SERVER_IP> \
--user <SSH_USER> \
--sudo \
--ssh-key ~/.ssh/id_rsa \
--cluster \
--local-path kubeconfig \
--context default \
--k3s-extra-args "--tls-san <ADDITIONAL_IPS>"
```

### 2. Retrieve the Node Token

The script fetches the `node-token`, which is required for adding worker nodes:

```sh
export NODE_TOKEN=$(k3sup node-token --host <PRIMARY_SERVER_IP> --user <SSH_USER>)
```

### 3. Join Additional Nodes

To add more nodes to the cluster, the script runs:

```sh
echo "Setting up additional server: 2"
k3sup join \
--host <NODE_IP> \
--server-host <PRIMARY_SERVER_IP> \
--server \
--user <SSH_USER> \
--ssh-key ~/.ssh/id_rsa \
--sudo \
--k3s-extra-args "--node-label node.kubernetes.io/worker=true"
```

Repeat this step for each additional node you want to add.

## Running the Script

1. Update the script with the correct server IPs and SSH user.
2. Ensure your SSH key is in place (`~/.ssh/id_rsa` by default).
3. Run the script:

   ```sh
   chmod +x k3sup.sh
   ./k3sup.sh
   ```

## Verifying the Cluster

Once the script completes, you can check the cluster status:

```sh
kubectl --kubeconfig kubeconfig get nodes
```

You should see all your nodes listed as `Ready`.

## Troubleshooting

- Ensure firewall rules allow traffic on required ports (e.g., 6443 for API server).
- Verify SSH access between the nodes.
- Check K3s logs for errors: `journalctl -u k3s -f` on each node.

## Next Steps

Now that your cluster is up and running, you can deploy applications using Kubernetes manifests or Helm charts. Happy clustering!