#! /bin/bash

set -o errexit
set -o nounset
set -o pipefail

KERNEL="../linux/build/arch/x86_64/boot/bzImage"
INITRD=".tmp/initramfs.cpio.gz"
ROOTFS=".tmp/ubuntu.qcow2"
IGNITE=".tmp/ignition.iso"
HEADERS=".tmp/headers.iso"
MODULES=".tmp/modules.iso"

CMDLINE="root=/dev/sda console=ttyS0 coreos.config.url=oem:///ignition.json"

DEBUG_OPTS="-S -gdb tcp::27467"
MACADDR="52:54:00:$(dd if=/dev/urandom bs=512 count=1 2>/dev/null | md5sum | sed 's/^\(..\)\(..\)\(..\).*$/\1:\2:\3/')"

SHARED_VOLUME="${HOME}"

CPU_OPTS=(-smp 2)
MEMORY_OPTS=(-m 2048)

NET_OPTS=()
for idx in {00..02}; do
  MACADDR="52:54:00:$(dd if=/dev/urandom bs=512 count=1 2>/dev/null \
    | md5sum \
    | sed 's/^\(..\)\(..\)\(..\).*$/\1:\2:\3/')"
  NET_OPTS+=("-netdev")
  NET_OPTS+=("tap,id=net${idx},script=./net/qemu-ifup,downscript=./net/qemu-ifdown")
  NET_OPTS+=("-device")
  NET_OPTS+=("e1000,netdev=net${idx},mac=${MACADDR}")
done;

while getopts ":d" opt; do
  case $opt in
    d)
      EXTRA_OPTS="${EXTRA_OPTS:-} ${DEBUG_OPTS}"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

set -o xtrace
kvm \
  -kernel "${KERNEL}" \
  -initrd "${INITRD}" \
  -append "${CMDLINE}" \
  -drive "file=${ROOTFS},index=0,media=disk" \
  -drive "file=${IGNITE},index=1,media=disk" \
  -drive "file=${HEADERS},index=2,media=disk" \
  -drive "file=${MODULES},index=3,media=disk" \
  -fsdev "local,security_model=passthrough,id=fsdev0,path=${SHARED_VOLUME}" \
  -device "virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare" \
  "${NET_OPTS[@]}" "${CPU_OPTS[@]}" "${MEMORY_OPTS[@]}" \
  -nographic ${EXTRA_OPTS[@]:-}
