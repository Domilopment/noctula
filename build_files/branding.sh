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
  "base-image-name": "$BASE_IMAGE_NAME",
  "fedora-version": "$FEDORA_MAJOR_VERSION"
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

if grep -q '^ID_LIKE=' /usr/lib/os-release; then
  sed -i "s|^ID=.*|ID=${IMAGE_PRETTY_NAME,}|" /usr/lib/os-release
  sed -i "s|^ID_LIKE=.*|ID_LIKE==\"${IMAGE_LIKE}\"|" /usr/lib/os-release
else
  sed -i "s|^ID=.*|ID=${IMAGE_PRETTY_NAME,}\nID_LIKE=\"${IMAGE_LIKE}\"|" /usr/lib/os-release
fi

sed -i "/^REDHAT_BUGZILLA_PRODUCT=/d; /^REDHAT_BUGZILLA_PRODUCT_VERSION=/d; /^REDHAT_SUPPORT_PRODUCT=/d; /^REDHAT_SUPPORT_PRODUCT_VERSION=/d" /usr/lib/os-release
sed -i "s|^VERSION_CODENAME=.*|VERSION_CODENAME=\"$CODE_NAME\"|" /usr/lib/os-release
sed -i "s|^VERSION=.*|VERSION=\"${VERSION} (${BASE_IMAGE_NAME^})\"|" /usr/lib/os-release
sed -i "s|^OSTREE_VERSION=.*|OSTREE_VERSION=\'${VERSION}\'|" /usr/lib/os-release

if grep -q '^BUILD_ID=' /usr/lib/os-release; then
  sed -i "s|^BUILD_ID=.*|BUILD_ID=\"$SHA_HEAD_SHORT\"|" /usr/lib/os-release
else
  echo "BUILD_ID=\"$SHA_HEAD_SHORT\"" >> /usr/lib/os-release
fi

if grep -q '^IMAGE_ID=' /usr/lib/os-release; then
  sed -i "s|^IMAGE_ID=.*|IMAGE_ID=\"${IMAGE_NAME}\"|" /usr/lib/os-release
else
  echo "IMAGE_ID=\"${IMAGE_NAME}\"" >> /usr/lib/os-release
fi

if grep -q '^IMAGE_VERSION=' /usr/lib/os-release; then
  sed -i "s|^IMAGE_VERSION=.*|IMAGE_VERSION=\"${VERSION}\"|" /usr/lib/os-release
else
  echo "IMAGE_VERSION=\"${VERSION}\"" >> /usr/lib/os-release
fi

ln -sf /usr/lib/os-release /etc/os-release

# Debugging
cat /usr/lib/os-release

# Fix issues caused by changing ID from fedora
sed -i "s|^EFIDIR=.*|EFIDIR=\"fedora\"|" /usr/sbin/grub2-switch-to-blscfg

echo "::endgroup::"
