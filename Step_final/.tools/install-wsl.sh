#!/usr/bin/env bash
set -euo pipefail
cd /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools
mkdir -p wsl-downloads /home/gf/.local/bin
cd wsl-downloads
curl --fail --silent --show-error --location --retry 3 https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
unzip -q -o awscliv2.zip
./aws/install --install-dir /home/gf/.local/aws-cli --bin-dir /home/gf/.local/bin --update
curl -fsSL --retry 3 https://dl.k8s.io/release/v1.35.0/bin/linux/amd64/kubectl -o kubectl
curl -fsSL --retry 3 https://dl.k8s.io/release/v1.35.0/bin/linux/amd64/kubectl.sha256 -o kubectl.sha256
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
install -m 755 kubectl /home/gf/.local/bin/kubectl
curl -fsSL --retry 3 https://get.helm.sh/helm-v3.19.0-linux-amd64.tar.gz -o helm.tar.gz
curl -fsSL --retry 3 https://get.helm.sh/helm-v3.19.0-linux-amd64.tar.gz.sha256sum -o helm.sha256sum
expected="$(awk '{print $1}' helm.sha256sum)"
echo "$expected  helm.tar.gz" | sha256sum --check
tar -xzf helm.tar.gz
install -m 755 linux-amd64/helm /home/gf/.local/bin/helm
/home/gf/.local/bin/aws --version
/home/gf/.local/bin/kubectl version --client
/home/gf/.local/bin/helm version --short
