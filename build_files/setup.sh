#!/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

### Aurora package Overrides

# Copied from https://github.com/ublue-os/aurora/blob/stable/build_files/base/03-packages.sh

# use negativo17 for 3rd party packages with higher priority than default
if ! grep -q fedora-multimedia <(dnf5 repolist); then
  # Enable or Install Repofile
  dnf5 config-manager setopt fedora-multimedia.enabled=1 ||
    dnf5 config-manager addrepo --from-repofile="https://negativo17.org/repos/fedora-multimedia.repo"
fi
# Set higher priority
dnf5 config-manager setopt fedora-multimedia.priority=90

#Setup terra extras repo
dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release-extras
dnf5 -y config-manager setopt "*terra*".priority=1

echo "::endgroup::"
