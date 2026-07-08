#!/usr/bin/env bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

IMAGE_PRETTY_NAME="Noctula"
IMAGE_LIKE="fedora"
HOME_URL="https://github.com/Domilopment/noctula"
DOCUMENTATION_URL="https://github.com/Domilopment/noctula"
SUPPORT_URL="https://github.com/Domilopment/noctula/issues"
BUG_SUPPORT_URL="https://github.com/Domilopment/noctula/issues"
CODE_NAME="Nightfall"
VERSION="${VERSION:-00.00000000}"

IMAGE_INFO="/usr/share/ublue-os/image-info.json"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/domilopment/noctula"

BASE_IMAGE_NAME="kinoite"

# Image Flavor
image_flavor="main"
if [[ "${IMAGE_NAME}" =~ nvidia ]]; then
    image_flavor="nvidia"
fi

cat >$IMAGE_INFO <<EOF
{
  "image-name": "$IMAGE_NAME",
  "image-flavor": "$image_flavor",
  "image-vendor": "$IMAGE_VENDOR",
  "image-ref": "$IMAGE_REF",
  "image-tag": "$IMAGE_TAG",
  "base-image-name": ""$BASE_IMAGE_NAME",
  "fedora-version": "$(rpm -E %fedora)"
}
EOF

# -----------------------------------------------------------------------------
# os-release branding
# -----------------------------------------------------------------------------

sed -i "s|^VARIANT_ID=.*|VARIANT_ID=$IMAGE_NAME|" /usr/lib/os-release
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"${IMAGE_PRETTY_NAME} (Version: ${VERSION})\"|" /usr/lib/os-release
sed -i "s|^NAME=.*|NAME=\"$IMAGE_PRETTY_NAME\"|" /usr/lib/os-release
sed -i "s|^HOME_URL=.*|HOME_URL=\"$HOME_URL\"|" /usr/lib/os-release
sed -i "s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL=\"$DOCUMENTATION_URL\"|" /usr/lib/os-release
sed -i "s|^SUPPORT_URL=.*|SUPPORT_URL=\"$SUPPORT_URL\"|" /usr/lib/os-release
sed -i "s|^BUG_REPORT_URL=.*|BUG_REPORT_URL=\"$BUG_SUPPORT_URL\"|" /usr/lib/os-release
sed -i "s|^CPE_NAME=.*|CPE_NAME=\"cpe:/o:domilopment:${IMAGE_PRETTY_NAME,}:${VERSION}\"|" /usr/lib/os-release
sed -i "s|^DEFAULT_HOSTNAME=.*|DEFAULT_HOSTNAME=\"${IMAGE_PRETTY_NAME,}\"|" /usr/lib/os-release
sed -i "s|^ID=fedora|ID=${IMAGE_PRETTY_NAME,}\nID_LIKE=\"${IMAGE_LIKE}\"|" /usr/lib/os-release
sed -i "/^REDHAT_BUGZILLA_PRODUCT=/d; /^REDHAT_BUGZILLA_PRODUCT_VERSION=/d; /^REDHAT_SUPPORT_PRODUCT=/d; /^REDHAT_SUPPORT_PRODUCT_VERSION=/d" /usr/lib/os-release
sed -i "s|^VERSION_CODENAME=.*|VERSION_CODENAME=\"$CODE_NAME\"|" /usr/lib/os-release
sed -i "s|^VERSION=.*|VERSION=\"${VERSION} (${BASE_IMAGE_NAME^})\"|" /usr/lib/os-release
sed -i "s|^OSTREE_VERSION=.*|OSTREE_VERSION=\'${VERSION}\'|" /usr/lib/os-release
sed -i "s|^IMAGE_ID=.*|IMAGE_ID=\"${IMAGE_NAME}\"|" /usr/lib/os-release
sed -i "s|^IMAGE_VERSION=.*|IMAGE_VERSION=\"${VERSION}\"|" /usr/lib/os-release

ln -sf /usr/lib/os-release /etc/os-release

# Debugging
cat /usr/lib/os-release

# Fix issues caused by changing ID from fedora
sed -i "s|^EFIDIR=.*|EFIDIR=\"fedora\"|" /usr/sbin/grub2-switch-to-blscfg

echo "::endgroup::"
