#!/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# Copied from https://github.com/ublue-os/aurora/blob/main/build_files/base/19-initramfs.sh

KERNEL_VERSION=$(rpm -q --queryformat="%{evr}.%{arch}" kernel-core)

export DRACUT_NO_XATTR=1
/usr/bin/dracut --no-hostonly --kver "${KERNEL_VERSION}" --reproducible -v -f "/usr/lib/modules/${KERNEL_VERSION}/initramfs.img"
chmod 0600 "/usr/lib/modules/${KERNEL_VERSION}/initramfs.img"

echo "::endgroup::"
