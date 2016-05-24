#! /bin/bash
set -x

set -o errexit
set -o nounset
set -o pipefail

KERNEL="../linux/build/arch/x86_64/boot/bzImage"
INITRD="initramfs.cpio.gz"
ROOTFS="base.qcow2"

CMDLINE="root=/dev/sda console=ttyS0"

DEBUG_OPTS="-S -gdb tcp::27467"
MACADDR="52:54:00:$(dd if=/dev/urandom bs=512 count=1 2>/dev/null | md5sum | sed 's/^\(..\)\(..\)\(..\).*$/\1:\2:\3/')"

SHARED_VOLUME="${HOME}"

CPU_OPTS="-smp 2"
MEMORY_OPTS="-m 2048"
NET_OPTS="-netdev tap,id=net0 -device e1000,netdev=net0,mac=${MACADDR}"

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
  -hda    "${ROOTFS}" \
  -append "${CMDLINE}" \
  -fsdev "local,security_model=passthrough,id=fsdev0,path=${SHARED_VOLUME}" \
  -device "virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare" \
  ${NET_OPTS[@]} ${CPU_OPTS[@]} ${MEMORY_OPTS[@]} \
  -nographic ${EXTRA_OPTS[@]:-}
