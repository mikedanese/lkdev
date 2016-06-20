#!/bin/busybox sh

set -o errexit
set -o nounset
set -o pipefail

rescue_shell() {
  echo "Something went wrong. Dropping to a shell."
  exec sh
}

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev


mount -o rw /dev/sda1 /mnt/root || rescue_shell

for tarball in modules.tar headers.tar base.tar; do
  tar xfv "/opt/${tarball}" -C /mnt/root || rescue_shell
done

umount /proc
umount /sys

sed -i '/^root/ { s/:x:/::/ }' "/mnt/root/etc/passwd"

exec switch_root /mnt/root /sbin/init
