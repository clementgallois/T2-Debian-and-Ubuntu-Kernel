#!/bin/bash

set -euxo pipefail

echo "deb-src http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" >> /etc/apt/sources.list

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y git dpkg-dev build-essential bc kmod cpio flex bison libssl-dev libelf-dev rsync wget curl fakeroot linux-image-amd64
apt-get build-dep -y linux

#get t2 linux patchs
mkdir -p /workspace/t2_patches
cd /workspace/t2_patches
git init
git remote add origin https://github.com/t2linux/linux-t2-patches.git
# last commit in version 6.18
git fetch --depth 1 origin 547fa06ff16ae131f2ae1083b17946384ddeb755
git checkout FETCH_HEAD
echo "======================="
echo "last commit used:"
echo "======================="
git log -1 --format="%h - %ad : %s"


mkdir -p /workspace/build && cd /workspace/build

apt-get source linux
cd /workspace/build/linux-*/

for patch in /workspace/t2_patches/*.patch; do
    patch -Np1 < "$patch" || echo "possible conflict on $patch"
done

for rej_file in $(find . -type f -name "*.rej"); do
    echo "======================="
    echo "Reject file : $rej_file"
    echo "======================="
    cat "$rej_file"
    echo ""
done

cp /boot/config-* .config

# Make config friendly with vanilla kernel from t2 depo
# maybe need this
./scripts/config --set-str VERSION_SIGNATURE ""
./scripts/config --set-str SYSTEM_TRUSTED_KEYS ""
./scripts/config --set-str SYSTEM_REVOCATION_KEYS ""

#  # silent boot ?
# ./scripts/config --set-val CONSOLE_LOGLEVEL_DEFAULT 4
# ./scripts/config --set-val CONSOLE_LOGLEVEL_QUIET 1
# ./scripts/config --set-val MESSAGE_LOGLEVEL_DEFAULT 4
# sed -i 's/CONFIG_CONSOLE_LOGLEVEL_DEFAULT=.*/CONFIG_CONSOLE_LOGLEVEL_DEFAULT=4/g' "${WORKING_PATH}/templates/default-config-${CONFIG}"
# sed -i 's/CONFIG_CONSOLE_LOGLEVEL_QUIET=.*/CONFIG_CONSOLE_LOGLEVEL_QUIET=1/g' "${WORKING_PATH}/templates/default-config-${CONFIG}"
# sed -i 's/CONFIG_MESSAGE_LOGLEVEL_DEFAULT=.*/CONFIG_MESSAGE_LOGLEVEL_DEFAULT=4/g' "${WORKING_PATH}/templates/default-config-${CONFIG}"


# Disable debug info
./scripts/config --enable DEBUG_INFO_NONE
./scripts/config --disable DEBUG_INFO
./scripts/config --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
./scripts/config --disable DEBUG_INFO_DWARF4
./scripts/config --disable DEBUG_INFO_DWARF5
./scripts/config --disable DEBUG_INFO_BTF
./scripts/config --disable DEBUG_INFO_BTF_MODULES
./scripts/config --disable GDB_SCRIPTS
./scripts/config --disable DEBUG_INFO_SPLIT
./scripts/config --disable DEBUG_INFO_REDUCED
./scripts/config --disable DEBUG_INFO_COMPRESSED

# t2 config
./scripts/config --module CONFIG_BT_HCIBCM4377
./scripts/config --module CONFIG_HID_APPLETB_BL
./scripts/config --module CONFIG_HID_APPLETB_KBD
./scripts/config --module CONFIG_DRM_APPLETBDRM
./scripts/config --module CONFIG_APPLE_BCE
./scripts/config --module CONFIG_APFS_FS

./scripts/config --enable CONFIG_MODULE_FORCE_UNLOAD

###### from debian kernel depo


# Disable built in GMUX
./scripts/config --module CONFIG_APPLE_GMUX

# Required by APPLE_BCE. This should already be set.
./scripts/config --enable CONFIG_IRQ_REMAP
./scripts/config --module CONFIG_HID_APPLE

# Only support intel cpu
./scripts/config --disable CONFIG_GENERIC_CPU
./scripts/config --enable CONFIG_PROCESSOR_SELECT
./scripts/config --enable CONFIG_MCORE2
./scripts/config --enable CONFIG_CPU_SUP_INTEL
./scripts/config --disable CONFIG_X86_AMD_PLATFORM_DEVICE
./scripts/config --disable CONFIG_CPU_SUP_AMD
./scripts/config --disable CONFIG_CPU_SUP_HYGON
./scripts/config --disable CONFIG_CPU_SUP_CENTAUR
./scripts/config --disable CONFIG_CPU_SUP_ZHAOXIN
./scripts/config --disable CONFIG_X86_MCE_AMD
./scripts/config --disable CONFIG_PERF_EVENTS_AMD_POWER
./scripts/config --disable CONFIG_PERF_EVENTS_AMD_UNCORE
./scripts/config --disable CONFIG_MICROCODE_AMD
./scripts/config --disable CONFIG_AMD_MEM_ENCRYPT

#####


make olddefconfig

cd /workspace/build/linux-*/

ABI_NAME="kali"
FEATURESET="t2"
KERNEL_VERSION=$(dpkg-parsechangelog -S Version)
make -j$(nproc) bindeb-pkg LOCALVERSION=+${ABI_NAME}-${FEATURESET}-amd64 KDEB_PKGVERSION=${KERNEL_VERSION}+t2

cd /workspace/build

# remove source directory
rm -rf linux-*/
