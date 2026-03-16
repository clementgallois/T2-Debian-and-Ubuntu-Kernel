#!/bin/bash

set -euxo pipefail

# echo "deb-src http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" >> /etc/apt/sources.list

# export DEBIAN_FRONTEND=noninteractive

# apt-get update
# apt-get install -y git dpkg-dev build-essential bc kmod cpio flex bison libssl-dev libelf-dev rsync wget curl fakeroot linux-image-amd64
echo "=========================="
echo "Number proc in docker: $(nproc)"
echo "=========================="


mkdir -p /workspace/build && cd /workspace/build

# Fake make

KVER="6.18.12"
ABI="+kali-t2-amd64"
PKG_VERSION="6.18.12-1kali1+t2"

# 1. IMAGE
mkdir -p deb/DEBIAN
cat <<EOF > deb/DEBIAN/control
Package: linux-image-${KVER}${ABI}
Version: ${PKG_VERSION}
Section: kernel
Priority: optional
Architecture: amd64
Maintainer: Root <root@kali>
Description: Fake Image
EOF
dpkg-deb --build deb "linux-image-${KVER}${ABI}_${PKG_VERSION}_amd64.deb"
rm -rf deb

# 2. HEADERS
mkdir -p deb/DEBIAN
cat <<EOF > deb/DEBIAN/control
Package: linux-headers-${KVER}${ABI}
Version: ${PKG_VERSION}
Section: kernel
Priority: optional
Architecture: amd64
Maintainer: Root <root@kali>
Description: Fake Headers
EOF
dpkg-deb --build deb "linux-headers-${KVER}${ABI}_${PKG_VERSION}_amd64.deb"
rm -rf deb

# 3. LIBC-DEV
mkdir -p deb/DEBIAN
cat <<EOF > deb/DEBIAN/control
Package: linux-libc-dev
Version: ${PKG_VERSION}
Section: devel
Priority: optional
Architecture: amd64
Maintainer: Root <root@kali>
Description: Fake Libc-dev
EOF
dpkg-deb --build deb "linux-libc-dev_${PKG_VERSION}_amd64.deb"
rm -rf deb
