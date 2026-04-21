#!/bin/bash
GFX_VER=$1
export DEBIAN_FRONTEND=noninteractive

apt-get update && apt-get install -y zstd curl wget gnupg2 pciutils lshw libnuma1 ca-certificates

# Repo ROCm 6.2
wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/rocm.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/rocm.gpg] https://repo.radeon.com/rocm/apt/6.2 noble main" > /etc/apt/sources.list.d/rocm.list

# Pinning
echo -e "Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600" > /etc/apt/preferences.d/rocm-pin

apt-get update
apt-get install -y -o Dpkg::Options::="--force-overwrite" rocminfo rocm-hip-runtime rocm-device-libs

# Ollama
command -v ollama || curl -fsSL https://ollama.com/install.sh | sh

# Config Systemd
mkdir -p /etc/systemd/system/ollama.service.d
echo -e "[Service]
Environment=\"HSA_OVERRIDE_GFX_VERSION=${GFX_VER}\"
Environment=\"HSA_ENABLE_SDMA=1\"
Environment=\"OLLAMA_HOST=0.0.0.0\"" > /etc/systemd/system/ollama.service.d/rocm.conf

usermod -a -G video,render root
usermod -a -G video,render ollama

systemctl daemon-reload
systemctl restart ollama