#!/usr/bin/env bash

IP=$(hostname -I | awk '{print $1}')

cat > vault-server.hcl <<EOF
disable_mlock = true
ui            = true

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"
}

storage "raft" {
  path = "/opt/vault"
  node_id = "$1"

  retry_join {
     auto_join = "provider=aws region=$2 tag_key=vault tag_value=$3"
     auto_join_scheme = "http"
  }

}
license_path  = "/etc/vault.d/license.hclic"
api_addr =  "http://$IP:8200"


cluster_addr = "http://$IP:8201"
log_level = "trace"
EOF

sudo mkdir /etc/vault.d
sudo cp vault-server.hcl /etc/vault.d/vault.hcl

sudo mkdir -p /opt/vault

#Create Vault data directories
sudo mkdir -p /var/lib/vault/data

#create user named vault
sudo useradd --system --home /etc/vault.d --shell /bin/false vault
sudo chown -R vault:vault /etc/vault.d /var/lib/vault /opt/vault

sudo chmod 640 /etc/vault.d/vault.hcl
sudo chmod -R 744 /opt/vault

sudo cp license.hclic /etc/vault.d/license.hclic

sudo curl -o /etc/systemd/system/vault.service https://raw.githubusercontent.com/catalinaorg/vaultservice/main/vault.service

sudo systemctl enable vault.service
sudo systemctl start vault.service

