#!/bin/bash

set -e

if [[ "${XCODE_VERSION_MAJOR}" -ge "0460" ]]; then
    export TC_PATH="${DT_TOOLCHAIN_DIR}/usr/bin"
else
    export TC_PATH="${PLATFORM_DEVELOPER_BIN_DIR}"
fi

# Version info
NOWVER=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${PROJECT_DIR}/${INFOPLIST_FILE}")
NOWBUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PROJECT_DIR}/${INFOPLIST_FILE}")

# Clean old build
cd "${BUILT_PRODUCTS_DIR}"
rm -rf makedeb
rm -f *.deb
mkdir -p makedeb

# Fix permission
chmod 755 "${PROJECT_DIR}/extra/ldid"
chmod 755 "${PROJECT_DIR}/extra/dpkg-deb"
chmod 755 "${PROJECT_DIR}/extra/gnutar"

# Fake code sign
ldid -S"${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/${PROJECT_NAME}.entitlements" "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/${PROJECT_NAME}"
rm -f "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/${PROJECT_NAME}.entitlements"

# Copy app
mkdir -p makedeb/Applications
cp -r "${WRAPPER_NAME}" makedeb/Applications/

# Make package
find . -name .DS_Store -type f -delete

NOWSIZE="$(du -s -k makedeb | awk '{print $1}')"
CTRLFILE="Package: com.twotrees.PrettyTunnel\nSection: Networking\nInstalled-Size: $NOWSIZE\nAuthor: twotrees <twotrees.zf@gmail.com>\nArchitecture: iphoneos-arm\nVersion: $NOWVER-$NOWBUILD\nDescription: SOCKS5 proxy via SSH Tunnel client for iOS\nName: PrettyTunnel\nHomepage: https://github.com/twotreeszf/PrettyTunnel\nIcon: file:///Applications/PrettyTunnel.app/AppIcon60x60@2x.png\nTag: purpose::uikit\n"
DEBNAME="com.twotrees.PrettyTunnel_$NOWVER-$NOWBUILD"
mkdir -p makedeb/DEBIAN
echo -ne "${CTRLFILE}" > makedeb/DEBIAN/control
cp -f "${PROJECT_DIR}/extra/postinst.sh" makedeb/DEBIAN/postinst
cp -f "${PROJECT_DIR}/extra/prerm.sh" makedeb/DEBIAN/prerm
cp -f "${PROJECT_DIR}/extra/extrainst.sh" makedeb/DEBIAN/extrainst_
chmod 755 makedeb/DEBIAN/postinst
chmod 755 makedeb/DEBIAN/prerm
chmod 755 makedeb/DEBIAN/extrainst_

OLDPATH="${PATH}"
export PATH="${PROJECT_DIR}/extra:${PATH}"
"${PROJECT_DIR}/extra/fakeroot" "${PROJECT_DIR}/extra/dpkg-deb" -b makedeb t.deb
export PATH="${OLDPATH}"

mkdir -p "${PROJECT_DIR}/release"
mv -f t.deb "${PROJECT_DIR}/release/${DEBNAME}"_iphoneos-arm.deb

# Clean
rm -rf makedeb