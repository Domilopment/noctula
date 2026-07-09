#!/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

### Nvidia AKMODS

# Copied from https://github.com/ublue-os/aurora/blob/main/build_files/base/03-install-kernel-akmods.sh

# Not available for Fedora 43 yet
dnf config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit

# Install Nvidia RPMs
IMAGE_NAME="kinoite" AKMODNV_PATH="/tmp/rpms/nvidia" MULTILIB=0 /tmp/akmods-rpms/ublue-os/nvidia-install.sh
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<EOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF

rsync -rvKl /ctx/system_files/nvidia/ /
systemctl enable ublue-nvidia-flatpak-runtime-sync.service

echo "::endgroup::"
