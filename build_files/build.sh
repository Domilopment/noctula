#!/bin/bash

set -ouex pipefail

FEDORA_VERSION=$(rpm -E %fedora)
KERNEL_VERSION=$(rpm -q kernel --qf "%{VERSION}-%{RELEASE}.%{ARCH}")


### Aurora package Overrides

# Copied from https://github.com/ublue-os/aurora/blob/stable/build_files/base/03-packages.sh

# use override to replace mesa and others with less crippled versions
OVERRIDES=(
    "intel-gmmlib"
    "intel-mediasdk"
    "intel-vpl-gpu-rt"
    "libheif"
    "libva"
    "libva-intel-media-driver"
    "mesa-dri-drivers"
    "mesa-filesystem"
    "mesa-libEGL"
    "mesa-libGL"
    "mesa-libgbm"
    "mesa-va-drivers"
    "mesa-vulkan-drivers"
)

dnf versionlock delete "${OVERRIDES[@]}"
dnf5 distro-sync --skip-unavailable -y --repo='fedora-multimedia' "${OVERRIDES[@]}"
dnf5 versionlock add "${OVERRIDES[@]}"

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
cp /ctx/nvidia-install.sh /tmp/nvidia-install.sh
chmod +x /tmp/nvidia-install.sh
#dnf5 -y copr enable ublue-os/staging
IMAGE_NAME="kinoite" RPMFUSION_MIRROR="" /tmp/nvidia-install.sh
#dnf5 -y copr disable ublue-os/staging
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<EOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF


### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
# dnf5 install -y tmux # Example: already installed (aurora-dx image)

# Create the real target directory to fix broken symlink
#mkdir -p /var/opt
#mkdir -p /var/usrlocal/bin/

# this installs docker desktop from website
# download docker desktop rpm
curl --retry 3 -Lo "/tmp/docker-desktop-x86_64.rpm" "https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm?utm_source=docker"
# install docker desktop
dnf5 install -y "/tmp/docker-desktop-x86_64.rpm"
# Register path symlink
cat >/usr/lib/tmpfiles.d/docker-desktop.conf <<EOF
d /var/usrlocal/bin 0755 root root - -
L /var/usrlocal/bin/compose-bridge - - - - /usr/lib/opt/docker-desktop/bin/compose-bridge
L /var/usrlocal/bin/docker - - - - /usr/bin/docker
EOF

# this adss unity repo installs unityhub
# add unity repo
#sh -c 'echo -e "[unityhub]\nname=Unity Hub\nbaseurl=https://hub.unity3d.com/linux/repos/rpm/stable\nenabled=1\ngpgcheck=1\ngpgkey=https://hub.unity3d.com/linux/repos/rpm/stable/repodata/repomd.xml.key\nrepo_gpgcheck=1" > /etc/yum.repos.d/unityhub.repo'
# install unityhub
#dnf5 install -y unityhub
# copy installation files to usr/lib/opt/
#mv /var/opt/unityhub /usr/lib/opt/unityhub
# Disable the repo afterwards (sets enabled=0)
#sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/unityhub.repo

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket


# Ensure Initramfs is generated
export DRACUT_NO_XATTR=1
/usr/bin/dracut --no-hostonly --kver "${KERNEL_VERSION}" --reproducible -v --add ostree -f "/lib/modules/${KERNEL_VERSION}/initramfs.img"
chmod 0600 "/lib/modules/${KERNEL_VERSION}/initramfs.img"


# cleanup stage
# Clean temporary files
rm -rf /tmp/*

if [ ! -L /var/run ]; then
  rm -rf /var/run
  ln -s /run /var/run
fi
