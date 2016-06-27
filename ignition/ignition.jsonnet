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
    },{
      filesystem: "root",
      path: "/etc/network/interfaces",
      contents: { source: "data:text/plain;base64," + std.base64(importstr "etc/network/interfaces") },
    },{
      filesystem: "root",
      path: "/etc/network/interfaces.d/enp0s4.cfg",
      contents: {  source: "data:text/plain;base64," + std.base64(importstr "etc/network/interfaces.d/enp0s4.cfg")},
    }],
    filesystems: [{
      name: "root",
      path: "/mnt/root",
    }],
  },
}
