local lkdev = {
  root_file(path, content, mode):: {
    filesystem: "root",
    path: path,
    mode: mode,
    contents: {
      source: "data:text/plain;base64," + std.base64(content),
    },
  },
  early_boot(scripts):: [
    lkdev.root_file("/var/lib/ignition/early-boot/" + script.name, script.content, 511)
    for script in scripts
  ],
  late_boot(scripts):: [
    lkdev.root_file("/var/lib/ignition/late-boot/" + script.name, script.content, 511)
    for script in scripts
  ],
};
{
  ignition: { version: "2.0.0" },
  systemd: {
    units: [{
      name: "early-boot.service",
      enable: true,
      contents: importstr "etc/systemd/system/early-boot.service",
    }, {
      name: "late-boot.service",
      enable: true,
      contents: importstr "etc/systemd/system/late-boot.service",
    }, {
      name: "open-iscsi.service",
      enabled: false,
    }],
  },
  passwd: {
    users: [{
      name: "mikedanese",
      passwordHash: "",
    }],
  },
  storage: {
    files: [{
      filesystem: "root",
      path: "/etc/cloud/cloud-init.disabled",
      contents: { source: "data:," },
    }, {
      filesystem: "root",
      path: "/etc/network/interfaces",
      contents: { source: "data:text/plain;base64," + std.base64(importstr "etc/network/interfaces") },
    }, {
      filesystem: "root",
      path: "/etc/network/interfaces.d/enp0s4.cfg",
      contents: { source: "data:text/plain;base64," + std.base64(importstr "etc/network/interfaces.d/enp0s4.cfg") },
    }, {
      filesystem: "root",
      path: "/root/.ssh/authorized_keys",
      mode: 384,
      contents: {
        source: "data:text/plain;base64," + std.base64(importstr "authorized_keys"),
      },
    }]
           + lkdev.early_boot([{
      name: "50_ssh_fingerprints",
      content: importstr "early-boot/50_ssh_fingerprints",
    }])
           + lkdev.late_boot([{
      name: "50_ipvlan",
      content: importstr "late-boot/50_ipvlan",
    }]),
    filesystems: [{
      name: "root",
      path: "/mnt/root",
    }],
  },
}
