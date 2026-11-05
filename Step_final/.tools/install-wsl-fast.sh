#!/usr/bin/env bash
set -euo pipefail
if [[ "$(ps -p 403 -o comm= || true)" == 'unzip' ]]; then kill 403; fi
work_dir="$(mktemp -d /tmp/codex-awscli.XXXXXX)"
unzip -q /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools/wsl-downloads/awscliv2.zip -d "$work_dir"
"$work_dir/aws/install" --install-dir /home/gf/.local/aws-cli --bin-dir /home/gf/.local/bin --update
cd "$work_dir"
curl -fsSL --connect-timeout 15 --max-time 180 --retry 2 https://dl.k8s.io/release/v1.35.0/bin/linux/amd64/kubectl -o kubectl
curl -fsSL https://dl.k8s.io/release/v1.35.0/bin/linux/amd64/kubectl.sha256 -o kubectl.sha256
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
install -m 755 kubectl /home/gf/.local/bin/kubectl
curl -fsSL --connect-timeout 15 --max-time 180 --retry 2 https://get.helm.sh/helm-v3.19.0-linux-amd64.tar.gz -o helm.tar.gz
curl -fsSL https://get.helm.sh/helm-v3.19.0-linux-amd64.tar.gz.sha256sum -o helm.sha256sum
echo "$(awk '{print $1}' helm.sha256sum)  helm.tar.gz" | sha256sum --check
tar -xzf helm.tar.gz
install -m 755 linux-amd64/helm /home/gf/.local/bin/helm
/home/gf/.local/bin/aws --version
/home/gf/.local/bin/kubectl version --client
/home/gf/.local/bin/helm version --short
