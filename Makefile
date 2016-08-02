
IMAGE_VERSION ?= 16.04
IMAGE = ubuntu-$(IMAGE_VERSION)-server-cloudimg-amd64-disk1.img
IMAGE_CDN_URL = https://uec-images.ubuntu.com/releases/${IMAGE_VERSION}/release/${IMAGE}
TMP = .tmp
VMLINUX = ../linux/build/vmlinux

default: boot
.PHONY += boot

$(VMLINUX):
	$(MAKE) -C ../linux

$(TMP)/ubuntu-$(IMAGE_VERSION).qcow2:
	curl -sSL --fail -o "$@" "${IMAGE_CDN_URL}"

$(TMP)/ubuntu.qcow2: $(TMP)/ubuntu-$(IMAGE_VERSION).qcow2
	cp "$<" "$@"

$(TMP)/initramfs.cpio.gz: initramfs/*
	$(MAKE) -C initramfs/

$(TMP)/modules: $(VMLINUX)
	rm -rf $@
	mkdir -p $@
	make -C ../linux/ modules_install INSTALL_MOD_PATH="$(PWD)/$(TMP)/modules/"

$(TMP)/modules.iso: $(TMP)/modules
	genisoimage -output $@ -volid kernel-modules -joliet -rock $<

$(TMP)/headers: $(VMLINUX)
	rm -rf $@
	mkdir -p $@
	make -C ../linux/ headers_install INSTALL_HDR_PATH="$(PWD)/$@"

$(TMP)/headers.iso: $(TMP)/headers
	genisoimage -output $@ -volid kernel-headers -joliet -rock -root usr/ $<

$(TMP)/ignition: ignition/**
	rm -rf $@
	mkdir -p $@
	jsonnet --multi $(TMP)/ignition ignition/all.jsonnet

$(TMP)/ignition.iso: $(TMP)/ignition
	genisoimage -output $@ -volid ignition -joliet -rock $</**

prepare: $(TMP)/ubuntu.qcow2 $(TMP)/initramfs.cpio.gz
.PHONY: prepare


boot: \
	$(TMP)/ubuntu.qcow2 \
	$(TMP)/initramfs.cpio.gz \
	$(TMP)/ignition.iso \
	$(TMP)/headers.iso \
	$(TMP)/modules.iso
	sudo ./boot.sh $(EXTRA_ARGS)
.PHONY += boot

clean:
	rm -rf \
		$(TMP)/modules \
		$(TMP)/modules.iso \
		$(TMP)/headers \
		$(TMP)/headers.iso \
		$(TMP)/ignition \
		$(TMP)/ignition.iso \
		$(TMP)/initramfs \
		$(TMP)/initramfs.cpio.gz
.PHONY += clean

deep-clean: clean
	rm -rf $(TMP)/ubuntu.qcow2
.PHONY += deep-clean
