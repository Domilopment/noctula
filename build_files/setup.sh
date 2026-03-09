#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -oue pipefail

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

echo "::endgroup::"
