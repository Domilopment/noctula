#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
# dnf5 install -y tmux # Example: already installed (aurora-dx image)

# Create the real target directory to fix broken symlink
mkdir -p /var/opt
mkdir -p /var/usrlocal/bin/

# this installs docker desktop from website
# download docker desktop rpm
curl -L -o "/tmp/docker-desktop-x86_64.rpm" "https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm?utm_source=docker"
# install docker desktop
dnf5 install -y "/tmp/docker-desktop-x86_64.rpm"
# copy installation files to usr/lib/opt/
mv /var/opt/docker-desktop /usr/lib/opt/docker-desktop
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

# cleanup stage
# Clean temporary files
rm -rf /tmp/*
