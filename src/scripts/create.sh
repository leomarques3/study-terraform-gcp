#!/usr/bin/env bash

# Bash safeties: exit on error, no unset variables, pipelines can't hide errors
set -o errexit
set -o nounset
set -o pipefail

while getopts e: flag
do
  # shellcheck disable=SC2220
  case "${flag}" in
    e) environment=${OPTARG};;
  esac
done

# Locate the root directory
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

# shellcheck source=scripts/common.sh
source "$ROOT"/scripts/common.sh

# Initialize and run Terraform
(cd "${ROOT}"; terraform init -input=false)
(cd "${ROOT}"; terraform apply -var="project_id=study-327018" -var-file=../src/development/env.tfvars -input=false -auto-approve)

# Get cluster credentials
GET_CREDS=$(terraform output --raw --state=../terraform.tfstate get_credentials)
${GET_CREDS}

echo "Detecting SSH Bastion Tunnel/Proxy"
if [[ ! "$(pgrep -f L8888:127.0.0.1:8888)" ]]; then
  echo "Did not detect a running SSH tunnel. Opening a new one."
  BASTION_CMD=$(terraform output --raw --state=../terraform.tfstate bastion_ssh_background)
  ${BASTION_CMD}
  echo "SSH Tunnel/Proxy is now running."
else
  echo "Detected a running SSH tunnel."
fi

HTTPS_PROXY=localhost:8888 helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
HTTPS_PROXY=localhost:8888 helm repo add hashicorp https://helm.releases.hashicorp.com
HTTPS_PROXY=localhost:8888 helm repo update

# Install Ingress NGINX inside the cluster
if [[ $(HTTPS_PROXY=localhost:8888 helm ls | grep "ingress-nginx" | awk '{print $8}' | xargs) != "deployed" ]]; then
  echo "Installing latest version of Ingress NGINX"
  HTTPS_PROXY=localhost:8888 helm install ingress-nginx ingress-nginx/ingress-nginx
else
  echo "Ingress NGINX already installed"
fi

# Install Vault inside the cluster
if [[ $(HTTPS_PROXY=localhost:8888 helm ls | grep "vault" | awk '{print $8}' | xargs) != "deployed" ]]; then
  echo "Installing latest version of Vault"
  HTTPS_PROXY=localhost:8888 helm install vault hashicorp/vault --set='server.ha.enabled=true' --set='server.ha.raft.enabled=true'
  sleep 40
  HTTPS_PROXY=localhost:8888 kubectl exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json
  VAULT_UNSEAL_KEY=$(< cluster-keys.json jq -r ".unseal_keys_b64[]")
  sleep 20
  HTTPS_PROXY=localhost:8888 kubectl exec vault-0 -- vault operator unseal "${VAULT_UNSEAL_KEY}"
  CLUSTER_ROOT_TOKEN=$(< cluster-keys.json jq -r ".root_token")
  sleep 20
  HTTPS_PROXY=localhost:8888 kubectl exec vault-0 -- vault login "${CLUSTER_ROOT_TOKEN}"
  HTTPS_PROXY=localhost:8888 kubectl exec vault-1 -- vault operator raft join http://vault-0.vault-internal:8200
  HTTPS_PROXY=localhost:8888 kubectl exec vault-1 -- vault operator unseal "${VAULT_UNSEAL_KEY}"
  sleep 20
  HTTPS_PROXY=localhost:8888 kubectl exec vault-2 -- vault operator raft join http://vault-0.vault-internal:8200
  HTTPS_PROXY=localhost:8888 kubectl exec vault-2 -- vault operator unseal "${VAULT_UNSEAL_KEY}"
  sleep 20
  rm -rf cluster-keys.json
else
  echo "Vault already installed"
fi

# shellcheck disable=SC2046
kill $(pgrep -f L8888:127.0.0.1:8888)