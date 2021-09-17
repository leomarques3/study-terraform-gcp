#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

while getopts e: flag
do
  case "${flag}" in
    e) environment=${OPTARG};;
  esac
done

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

(cd "${ROOT}"; rm -rf ../src/terraform.*)
(cd "${ROOT}"; terraform init -input=false)
(cd "${ROOT}"; terraform apply -var-file=../src/"$environment"/env.tfvars -input=false -auto-approve)

terraform output --state=../src/terraform.tfstate get_credentials