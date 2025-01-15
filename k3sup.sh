
#!/bin/sh

echo "Setting up primary server 1"
k3sup install --host 192.168.0.48 \
--user tvl \
--cluster \
--local-path kubeconfig \
--context pi3s \
--k3s-extra-args "--disable=traefik --disable=servicelb --tls-san 192.168.0.48 --tls-san 192.168.191.177 --tls-san 192.168.191.42 --tls-san 192.168.191.82 --tls-san pi3s.pangarabbit.com" \
--no-extras "servicelb" "traefik"

echo "Fetching the server's node-token into memory"

export NODE_TOKEN=$(k3sup node-token --host 192.168.0.48 --user tvl)

echo "Setting up additional server: 2"
k3sup join \
--host 192.168.0.107 \
--server-host 192.168.0.48 \
--server \
--node-token "$NODE_TOKEN" \
--user tvl \
--k3s-extra-args "--disable traefik --disable=servicelb"

echo "Setting up additional server: 3"
k3sup join \
--host 192.168.0.141 \
--server-host 192.168.0.48 \
--server \
--node-token "$NODE_TOKEN" \
--user tvl \
--k3s-extra-args "--disable traefik --disable=servicelb"

echo "Setting up worker: 1"
k3sup join \
--host 192.168.0.149 \
--server-host 192.168.0.48 \
--node-token "$NODE_TOKEN" \
--user tvl

echo "Setting up worker: 2"
k3sup join \
--host 192.168.0.115 \
--server-host 192.168.0.48 \
--node-token "$NODE_TOKEN" \
--user tvl

echo "Setting up worker: 3"
k3sup join \
--host 192.168.0.23 \
--server-host 192.168.0.48 \
--node-token "$NODE_TOKEN" \
--user tvl
