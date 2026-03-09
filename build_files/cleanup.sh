#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -oue pipefail

# Disable negativo17 multimedia again.
if [[ -f "/etc/yum.repos.d/fedora-multimedia.repo" ]]; then
  sed -i 's@enabled=1@enabled=0@g' "/etc/yum.repos.d/fedora-multimedia.repo"
fi

# cleanup stage
# Clean temporary files
rm -rf /tmp/*

if [ ! -L /var/run ]; then
  rm -rf /var/run
  ln -s /run /var/run
fi

echo "::endgroup::"
