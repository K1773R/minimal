#!/bin/sh -e
exec tail -n +4 $0

## This yaboot.conf is for CD booting only, do not use as reference.
default=Linux

message=/boot/boot.msg

image=/boot/vmlinux
	label=Linux
	read-only
	initrd=/boot/rootfs.xz
	append="net.ifnames=0 biosdevname=0"
