#!/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

FEDORA_VERSION=$(rpm -E %fedora)
KERNEL_VERSION=$(rpm -q kernel --qf "%{VERSION}-%{RELEASE}.%{ARCH}")


### Nvidia AKMODS

# Copied from https://github.com/ublue-os/aurora/blob/main/build_files/base/03-install-kernel-akmods.sh

# Fetch Nvidia RPMs
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods-nvidia-lts:coreos-stable-"${FEDORA_VERSION}"-"${KERNEL_VERSION}" dir:/tmp/akmods-rpms
NVIDIA_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods-rpms/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods-rpms/"$NVIDIA_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods-rpms/

# Exclude the Golang Nvidia Container Toolkit in Fedora Repo
dnf5 config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit

# Install Nvidia RPMs
curl --retry 3 -sSL "https://raw.githubusercontent.com/ublue-os/main/main/build_files/nvidia-install.sh" -o /tmp/nvidia-install.sh
# enable nvidia lts repo
sed -i 's@fedora-nvidia.enabled=1@fedora-nvidia-lts.enabled=1@g' /tmp/nvidia-install.sh
chmod +x /tmp/nvidia-install.sh
IMAGE_NAME="kinoite" RPMFUSION_MIRROR="" /tmp/nvidia-install.sh
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<EOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF

echo "::endgroup::"
