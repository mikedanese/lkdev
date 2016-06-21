
IMAGE_VERSION ?= 16.04
IMAGE = ubuntu-$(IMAGE_VERSION)-server-cloudimg-amd64-disk1.img
IMAGE_CDN_URL = https://uec-images.ubuntu.com/releases/${IMAGE_VERSION}/release/${IMAGE}
TMP = .tmp

default: boot
.PHONY += boot

$(TMP)/ubuntu-$(IMAGE_VERSION).qcow2:
	curl -sSL --fail -o "$@" "${IMAGE_CDN_URL}"

$(TMP)/ubuntu.qcow2: $(TMP)/ubuntu-$(IMAGE_VERSION).qcow2
	cp "$<" "$@"

$(TMP)/initramfs.cpio.gz: mkinitrd init.sh $(TMP)/modules.tar $(TMP)/headers.tar $(TMP)/base.tar
	./mkinitrd

$(TMP)/modules.tar:
	mkdir -p $(TMP)/modules/
	make -C ../linux/ modules_install INSTALL_MOD_PATH="$(PWD)/$(TMP)/modules/"
	tar cvf $@ -C $(TMP)/modules/ .

$(TMP)/headers.tar:
	mkdir -p $(TMP)/headers/usr
	make -C ../linux/ headers_install INSTALL_HDR_PATH="$(PWD)/$(TMP)/headers/usr"
	tar cvf $@ -C $(TMP)/headers/ .

$(TMP)/base.tar: $(shell find base/)
	tar cvf $@ -C base/ .

prepare: $(TMP)/ubuntu.qcow2 $(TMP)/initramfs.cpio.gz
.PHONY: prepare


boot: $(TMP)/ubuntu.qcow2 $(TMP)/initramfs.cpio.gz
	sudo ./boot.sh $(EXTRA_ARGS)
.PHONY += boot

clean:
	rm -rf \
		$(TMP)/modules \
		$(TMP)/modules.tar \
		$(TMP)/headers.tar \
		$(TMP)/headers \
		$(TMP)/cloud-init.tar \
		$(TMP)/cloud-init \
		$(TMP)/initramfs.cpio.gz
.PHONY += clean

deep-clean: clean
	rm -rf $(TMP)/ubuntu.qcow2
.PHONY += deep-clean
