#!/bin/sh
qemu-system-x86_64 \
-cpu host,hv-time,hv-relaxed,hv-vapic,hv-spinlocks=0x1fff \
-bios /usr/share/ovmf/OVMF.fd \
-M q35,accel=kvm,kernel-irqchip=split \
-device intel-iommu,intremap=on \
-rtc base=localtime \
-smp 4,sockets=1,cores=2,threads=2 \
-m 8192 \
    -object memory-backend-file,id=mem0,mem-path=/dev/hugepages,size=4G -numa node,nodeid=0,memdev=mem0 \
    -object memory-backend-file,id=mem1,mem-path=/dev/hugepages,size=4G -numa node,nodeid=1,memdev=mem1 \
    -mem-prealloc \
-device virtio-net-pci,netdev=net0 -netdev user,id=net0,hostfwd=tcp::3389-:3389 \
-usb -device usb-kbd -device usb-mouse \
-device ich9-intel-hda -device hda-output \
-display egl-headless,rendernode=/dev/dri/card0 \
-device qxl-vga,id=video0,ram_size=134217728,vram_size=134217728,vgamem_mb=512 \
-device virtio-serial-pci \
-spice port=9000,disable-ticketing,image-compression=auto_glz,jpeg-wan-compression=always,playback-compression=off,zlib-glz-wan-compression=never,streaming-video=filter,agent-mouse=on \
-device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
-chardev spicevmc,id=spicechannel0,name=vdagent \
-drive file=mijksrv-vm-w10.img,if=virtio,cache.direct=on,aio=native,format=raw \
-boot c \
-monitor stdio
